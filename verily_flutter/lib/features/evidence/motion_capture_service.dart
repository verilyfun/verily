import 'dart:async';

import 'package:verily_client/verily_client.dart';
import 'package:verily_evidence/verily_evidence.dart' as evidence;
import 'package:sensors_plus/sensors_plus.dart';

typedef MotionSensorStream<T> = Stream<T> Function(Duration samplingPeriod);
typedef MotionCaptureClock = DateTime Function();

enum MotionCaptureFailure { unavailable, interrupted, invalidRule, cancelled }

class MotionCaptureException implements Exception {
  const MotionCaptureException(this.failure);

  final MotionCaptureFailure failure;
}

class MotionCaptureCancellation {
  final Completer<void> _cancelled = Completer<void>();

  Future<void> get whenCancelled => _cancelled.future;

  bool get isCancelled => _cancelled.isCompleted;

  void cancel() {
    if (!_cancelled.isCompleted) _cancelled.complete();
  }
}

class CapturedMotion {
  const CapturedMotion({
    required this.capturedAt,
    required this.samples,
    required this.analysis,
  });

  final DateTime capturedAt;
  final List<evidence.MotionEvidenceSample> samples;
  final evidence.MotionEvidenceAnalysis analysis;

  String get traceSha256 => evidence.motionTraceSha256(samples);
}

typedef MotionCaptureCallback = Future<CapturedMotion> Function({
  required ActionRequirementView requirement,
  MotionCaptureCancellation? cancellation,
  void Function(double value)? onProgress,
});

class MotionCaptureService {
  MotionCaptureService({
    MotionSensorStream<AccelerometerEvent>? accelerometerEvents,
    MotionSensorStream<GyroscopeEvent>? gyroscopeEvents,
    MotionCaptureClock? clock,
    this.samplingPeriod = const Duration(milliseconds: 40),
    this.sensorStartupTimeout = const Duration(seconds: 2),
  }) : _accelerometerEvents =
           accelerometerEvents ??
           ((period) => accelerometerEventStream(samplingPeriod: period)),
       _gyroscopeEvents =
           gyroscopeEvents ??
           ((period) => gyroscopeEventStream(samplingPeriod: period)),
       _clock = clock ?? DateTime.now;

  static const _maximumPairingGap = Duration(milliseconds: 250);

  final MotionSensorStream<AccelerometerEvent> _accelerometerEvents;
  final MotionSensorStream<GyroscopeEvent> _gyroscopeEvents;
  final MotionCaptureClock _clock;
  final Duration samplingPeriod;
  final Duration sensorStartupTimeout;

  Future<CapturedMotion> capture({
    required ActionRequirementView requirement,
    MotionCaptureCancellation? cancellation,
    void Function(double value)? onProgress,
  }) {
    final completer = Completer<CapturedMotion>();
    final rule = motionRuleForRequirement(requirement);
    final duration = motionCaptureDuration(requirement);
    final samples = <evidence.MotionEvidenceSample>[];
    AccelerometerEvent? latestAcceleration;
    DateTime? firstSensorTimestamp;
    DateTime? capturedAt;
    StreamSubscription<AccelerometerEvent>? accelerometerSubscription;
    StreamSubscription<GyroscopeEvent>? gyroscopeSubscription;
    Timer? startupTimer;
    Timer? completionTimer;

    void cleanUp() {
      startupTimer?.cancel();
      completionTimer?.cancel();
      unawaited(accelerometerSubscription?.cancel());
      unawaited(gyroscopeSubscription?.cancel());
    }

    void fail(MotionCaptureFailure failure) {
      if (completer.isCompleted) return;
      cleanUp();
      completer.completeError(MotionCaptureException(failure));
    }

    void completeCapture() {
      if (completer.isCompleted) return;
      try {
        final analysis = const evidence.MotionEvidenceAnalyzer().analyze(
          samples: samples,
          rule: rule,
        );
        cleanUp();
        completer.complete(
          CapturedMotion(
            capturedAt: capturedAt!.toUtc(),
            samples: List.unmodifiable(samples),
            analysis: analysis,
          ),
        );
      } on Object {
        fail(MotionCaptureFailure.interrupted);
      }
    }

    void handleGyroscope(GyroscopeEvent gyroscope) {
      if (completer.isCompleted || cancellation?.isCancelled == true) return;
      final acceleration = latestAcceleration;
      if (acceleration == null) return;
      final pairingGap = gyroscope.timestamp.difference(acceleration.timestamp);
      if (pairingGap.abs() > _maximumPairingGap) return;

      firstSensorTimestamp ??= gyroscope.timestamp;
      capturedAt ??= _clock().toUtc();
      final rawElapsed = gyroscope.timestamp
          .difference(firstSensorTimestamp!)
          .inMicroseconds;
      if (rawElapsed < 0) {
        fail(MotionCaptureFailure.interrupted);
        return;
      }
      final reachedEnd = rawElapsed >= duration.inMicroseconds;
      final elapsed = reachedEnd ? duration.inMicroseconds : rawElapsed;
      if (samples.isNotEmpty &&
          elapsed - samples.last.elapsedMicroseconds <
              samplingPeriod.inMicroseconds) {
        if (!reachedEnd) return;
        if (elapsed == samples.last.elapsedMicroseconds) {
          completeCapture();
          return;
        }
      }
      if (samples.length >= evidence.MotionEvidenceAnalyzer.maximumSamples) {
        fail(MotionCaptureFailure.interrupted);
        return;
      }
      samples.add(
        evidence.MotionEvidenceSample(
          elapsedMicroseconds: elapsed,
          gyroscopeX: gyroscope.x,
          gyroscopeY: gyroscope.y,
          gyroscopeZ: gyroscope.z,
          accelerationX: acceleration.x,
          accelerationY: acceleration.y,
          accelerationZ: acceleration.z,
        ),
      );
      startupTimer?.cancel();
      onProgress?.call(
        (elapsed / duration.inMicroseconds).clamp(0, 1).toDouble(),
      );
      if (reachedEnd) completeCapture();
    }

    try {
      accelerometerSubscription = _accelerometerEvents(samplingPeriod).listen(
        (event) => latestAcceleration = event,
        onError: (_, _) => fail(MotionCaptureFailure.unavailable),
        onDone: () {
          if (!completer.isCompleted) fail(MotionCaptureFailure.interrupted);
        },
        cancelOnError: true,
      );
      gyroscopeSubscription = _gyroscopeEvents(samplingPeriod).listen(
        handleGyroscope,
        onError: (_, _) => fail(MotionCaptureFailure.unavailable),
        onDone: () {
          if (!completer.isCompleted) fail(MotionCaptureFailure.interrupted);
        },
        cancelOnError: true,
      );
    } on Object {
      fail(MotionCaptureFailure.unavailable);
      return completer.future;
    }

    startupTimer = Timer(
      sensorStartupTimeout,
      () => fail(MotionCaptureFailure.unavailable),
    );
    completionTimer = Timer(
      duration + sensorStartupTimeout,
      () => fail(MotionCaptureFailure.interrupted),
    );
    unawaited(
      cancellation?.whenCancelled.then(
        (_) => fail(MotionCaptureFailure.cancelled),
      ),
    );
    return completer.future;
  }
}

Duration motionCaptureDuration(ActionRequirementView requirement) {
  final minimum = (requirement.minDurationSeconds ?? 1).clamp(1, 30);
  final maximum = (requirement.maxDurationSeconds ?? 10).clamp(minimum, 30);
  final ideal = switch (requirement.motionType) {
    ActionMotionType.phoneToss => 4,
    ActionMotionType.rotation => (requirement.targetRepetitions ?? 1) * 2,
    ActionMotionType.shake => 6,
    ActionMotionType.stillness => 5,
    null => throw const MotionCaptureException(
      MotionCaptureFailure.invalidRule,
    ),
  };
  return Duration(seconds: ideal.clamp(minimum, maximum));
}

evidence.MotionEvidenceRule motionRuleForRequirement(
  ActionRequirementView requirement,
) {
  final type = requirement.motionType;
  final axis = requirement.motionAxis;
  final repetitions = requirement.targetRepetitions;
  final minimumDuration = requirement.minDurationSeconds;
  final maximumDuration = requirement.maxDurationSeconds;
  final minimumAngularSpeed = requirement.minAngularSpeedRadiansPerSecond;
  final maximumAngularSpeed = requirement.maxAngularSpeedRadiansPerSecond;
  final minimumAxisDominance = requirement.minAxisDominance;
  final minimumFreeFall = requirement.minFreeFallMilliseconds;
  final maximumFreeFall = requirement.maxFreeFallMilliseconds;
  final minimumPeakAcceleration =
      requirement.minPeakAccelerationMetersPerSecondSquared;
  final maximumPeakAcceleration =
      requirement.maxPeakAccelerationMetersPerSecondSquared;
  if (requirement.kind != ActionRequirementKind.motion ||
      type == null ||
      axis == null ||
      repetitions == null ||
      minimumDuration == null ||
      maximumDuration == null ||
      minimumAngularSpeed == null ||
      maximumAngularSpeed == null ||
      minimumAxisDominance == null ||
      minimumFreeFall == null ||
      maximumFreeFall == null ||
      minimumPeakAcceleration == null ||
      maximumPeakAcceleration == null) {
    throw const MotionCaptureException(MotionCaptureFailure.invalidRule);
  }
  final rule = evidence.MotionEvidenceRule(
    type: switch (type) {
      ActionMotionType.phoneToss => evidence.MotionActionType.phoneToss,
      ActionMotionType.rotation => evidence.MotionActionType.rotation,
      ActionMotionType.shake => evidence.MotionActionType.shake,
      ActionMotionType.stillness => evidence.MotionActionType.stillness,
    },
    axis: switch (axis) {
      ActionMotionAxis.yaw => evidence.MotionAxis.yaw,
      ActionMotionAxis.pitch => evidence.MotionAxis.pitch,
      ActionMotionAxis.roll => evidence.MotionAxis.roll,
      ActionMotionAxis.any => evidence.MotionAxis.any,
    },
    targetRepetitions: repetitions,
    minimumDurationSeconds: minimumDuration,
    maximumDurationSeconds: maximumDuration,
    minimumAngularSpeedRadiansPerSecond: minimumAngularSpeed,
    maximumAngularSpeedRadiansPerSecond: maximumAngularSpeed,
    minimumAxisDominance: minimumAxisDominance,
    minimumFreeFallMilliseconds: minimumFreeFall,
    maximumFreeFallMilliseconds: maximumFreeFall,
    minimumPeakAccelerationMetersPerSecondSquared: minimumPeakAcceleration,
    maximumPeakAccelerationMetersPerSecondSquared: maximumPeakAcceleration,
  );
  try {
    const evidence.MotionEvidenceAnalyzer().validateRule(rule);
  } on Object {
    throw const MotionCaptureException(MotionCaptureFailure.invalidRule);
  }
  return rule;
}
