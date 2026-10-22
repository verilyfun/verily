import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';

/// Real-world motion patterns that can be evaluated without a model verdict.
enum MotionActionType { phoneToss, rotation, shake, stillness }

/// Device axes use Android sensor coordinates while the screen faces the user.
///
/// Pitch rotates around X, roll around Y, and yaw around Z. [any] is useful for
/// shaking and stillness but is deliberately invalid for counted rotations.
enum MotionAxis { yaw, pitch, roll, any }

/// One bounded, monotonic observation from the gyroscope and accelerometer.
final class MotionEvidenceSample {
  const MotionEvidenceSample({
    required this.elapsedMicroseconds,
    required this.gyroscopeX,
    required this.gyroscopeY,
    required this.gyroscopeZ,
    required this.accelerationX,
    required this.accelerationY,
    required this.accelerationZ,
  });

  final int elapsedMicroseconds;
  final double gyroscopeX;
  final double gyroscopeY;
  final double gyroscopeZ;
  final double accelerationX;
  final double accelerationY;
  final double accelerationZ;

  List<int> toCanonicalValues() => [
    elapsedMicroseconds,
    _quantize(gyroscopeX),
    _quantize(gyroscopeY),
    _quantize(gyroscopeZ),
    _quantize(accelerationX),
    _quantize(accelerationY),
    _quantize(accelerationZ),
  ];
}

/// Creator-owned thresholds after server validation.
final class MotionEvidenceRule {
  const MotionEvidenceRule({
    required this.type,
    required this.axis,
    required this.targetRepetitions,
    required this.minimumDurationSeconds,
    required this.maximumDurationSeconds,
    required this.minimumAngularSpeedRadiansPerSecond,
    required this.maximumAngularSpeedRadiansPerSecond,
    required this.minimumAxisDominance,
    required this.minimumFreeFallMilliseconds,
    required this.maximumFreeFallMilliseconds,
    required this.minimumPeakAccelerationMetersPerSecondSquared,
    required this.maximumPeakAccelerationMetersPerSecondSquared,
  });

  final MotionActionType type;
  final MotionAxis axis;
  final int targetRepetitions;
  final int minimumDurationSeconds;
  final int maximumDurationSeconds;
  final double minimumAngularSpeedRadiansPerSecond;
  final double maximumAngularSpeedRadiansPerSecond;
  final double minimumAxisDominance;
  final int minimumFreeFallMilliseconds;
  final int maximumFreeFallMilliseconds;
  final double minimumPeakAccelerationMetersPerSecondSquared;
  final double maximumPeakAccelerationMetersPerSecondSquared;
}

/// Privacy-safe deterministic result; the raw trace remains private evidence.
final class MotionEvidenceAnalysis {
  const MotionEvidenceAnalysis({
    required this.accepted,
    required this.reasonCode,
    required this.score,
    required this.sampleCount,
    required this.durationMilliseconds,
    required this.repetitionCount,
    required this.peakAngularSpeedRadiansPerSecond,
    required this.peakAccelerationMetersPerSecondSquared,
    required this.axisDominance,
    required this.freeFallMilliseconds,
  });

  final bool accepted;
  final String reasonCode;
  final double score;
  final int sampleCount;
  final int durationMilliseconds;
  final int repetitionCount;
  final double peakAngularSpeedRadiansPerSecond;
  final double peakAccelerationMetersPerSecondSquared;
  final double axisDominance;
  final int freeFallMilliseconds;

  Map<String, Object> toJson() => {
    'accepted': accepted,
    'reasonCode': reasonCode,
    'score': score,
    'sampleCount': sampleCount,
    'durationMilliseconds': durationMilliseconds,
    'repetitionCount': repetitionCount,
    'peakAngularSpeedRadiansPerSecond': peakAngularSpeedRadiansPerSecond,
    'peakAccelerationMetersPerSecondSquared':
        peakAccelerationMetersPerSecondSquared,
    'axisDominance': axisDominance,
    'freeFallMilliseconds': freeFallMilliseconds,
  };
}

/// Validates and evaluates signed device motion using server-reproducible math.
final class MotionEvidenceAnalyzer {
  const MotionEvidenceAnalyzer();

  static const minimumSamples = 10;
  static const maximumSamples = 1000;
  static const maximumDuration = Duration(seconds: 30);
  static const maximumSampleGap = Duration(milliseconds: 250);
  static const maximumGyroscopeMagnitude = 100.0;
  static const maximumAccelerationMagnitude = 200.0;
  static const maximumRuleRepetitions = 20;
  static const maximumRuleAngularSpeed = 25.0;
  static const maximumRuleFreeFall = Duration(milliseconds: 700);
  static const maximumRulePeakAcceleration = 60.0;
  static const minimumPhoneTossPeakAcceleration = 8.0;
  static const maximumStillnessAngularSpeed = 2.0;
  static const rotationDeadband = 0.35;
  static const freeFallAcceleration = 3.0;
  static const tossImpulseWindow = Duration(milliseconds: 600);
  static const shakePeakSeparation = Duration(milliseconds: 120);

  /// Validates creator-authored thresholds without requiring a sensor trace.
  ///
  /// Both clients and servers may use this for early feedback. The server must
  /// still call [analyze], which repeats validation before trusting a result.
  /// Throws [ArgumentError] with the [ruleProblem].
  void validateRule(MotionEvidenceRule rule) {
    if (ruleProblem(rule) case final problem?) throw ArgumentError(problem);
  }

  MotionEvidenceAnalysis analyze({
    required List<MotionEvidenceSample> samples,
    required MotionEvidenceRule rule,
  }) {
    validateRule(rule);
    final trace = _validatedTrace(samples);
    final durationMilliseconds = (trace.last.elapsedMicroseconds / 1000)
        .round();
    final metrics = _TraceMetrics.from(trace, rule.axis);
    final base = (
      sampleCount: trace.length,
      durationMilliseconds: durationMilliseconds,
      peakAngularSpeed: metrics.peakAngularSpeed,
      peakAcceleration: metrics.peakAcceleration,
      axisDominance: metrics.axisDominance,
    );

    if (durationMilliseconds < rule.minimumDurationSeconds * 1000 ||
        durationMilliseconds > rule.maximumDurationSeconds * 1000) {
      return _result(
        base,
        accepted: false,
        reasonCode: 'motion_duration_out_of_range',
      );
    }

    return switch (rule.type) {
      MotionActionType.rotation => _rotation(trace, rule, metrics, base),
      MotionActionType.phoneToss => _phoneToss(trace, rule, metrics, base),
      MotionActionType.shake => _shake(trace, rule, metrics, base),
      MotionActionType.stillness => _stillness(rule, metrics, base),
    };
  }

  MotionEvidenceAnalysis _rotation(
    List<MotionEvidenceSample> samples,
    MotionEvidenceRule rule,
    _TraceMetrics metrics,
    _BaseMetrics base,
  ) {
    var segmentRadians = 0.0;
    var repetitions = 0;
    for (var index = 1; index < samples.length; index += 1) {
      final previous = _axisGyroscope(samples[index - 1], rule.axis);
      final current = _axisGyroscope(samples[index], rule.axis);
      final deltaSeconds =
          (samples[index].elapsedMicroseconds -
              samples[index - 1].elapsedMicroseconds) /
          Duration.microsecondsPerSecond;
      final filteredPrevious = previous.abs() < rotationDeadband
          ? 0.0
          : previous;
      final filteredCurrent = current.abs() < rotationDeadband ? 0.0 : current;
      final deltaRadians =
          (filteredPrevious + filteredCurrent) * 0.5 * deltaSeconds;
      if (deltaRadians != 0 &&
          segmentRadians != 0 &&
          deltaRadians.sign != segmentRadians.sign) {
        // Incomplete turns cannot be assembled from alternating half-turns.
        segmentRadians = 0;
      }
      segmentRadians += deltaRadians;
      while (segmentRadians.abs() + 0.000001 >= 2 * math.pi) {
        repetitions += 1;
        segmentRadians -= segmentRadians.sign * 2 * math.pi;
      }
    }
    final speed = metrics.peakAngularSpeed;
    final unsafeSpeed = speed > rule.maximumAngularSpeedRadiansPerSecond;
    final speedReached = speed >= rule.minimumAngularSpeedRadiansPerSecond;
    final axisDominant = metrics.axisDominance >= rule.minimumAxisDominance;
    final repetitionsReached = repetitions >= rule.targetRepetitions;
    final score = _minimum([
      repetitions / rule.targetRepetitions,
      speed / rule.minimumAngularSpeedRadiansPerSecond,
      metrics.axisDominance / rule.minimumAxisDominance,
    ]).clamp(0, 1).toDouble();
    final reasonCode = unsafeSpeed
        ? 'motion_rotation_too_fast'
        : !axisDominant
        ? 'motion_rotation_wrong_axis'
        : !speedReached
        ? 'motion_rotation_too_slow'
        : !repetitionsReached
        ? 'motion_rotation_count_not_met'
        : 'motion_verified';
    return _result(
      base,
      accepted:
          !unsafeSpeed && speedReached && axisDominant && repetitionsReached,
      reasonCode: reasonCode,
      score: score,
      repetitions: repetitions,
    );
  }

  MotionEvidenceAnalysis _phoneToss(
    List<MotionEvidenceSample> samples,
    MotionEvidenceRule rule,
    _TraceMetrics metrics,
    _BaseMetrics base,
  ) {
    final freeFall = _longestFreeFall(samples);
    final freeFallMilliseconds = freeFall == null
        ? 0
        : ((freeFall.endMicroseconds - freeFall.startMicroseconds) / 1000)
              .round();
    final launchPeak = freeFall == null
        ? 0.0
        : _peakAcceleration(
            samples,
            fromMicroseconds:
                freeFall.startMicroseconds - tossImpulseWindow.inMicroseconds,
            toMicroseconds: freeFall.startMicroseconds,
          );
    final catchPeak = freeFall == null
        ? 0.0
        : _peakAcceleration(
            samples,
            fromMicroseconds: freeFall.endMicroseconds,
            toMicroseconds:
                freeFall.endMicroseconds + tossImpulseWindow.inMicroseconds,
          );
    final weakestImpulse = math.min(launchPeak, catchPeak);
    final impactSafe =
        metrics.peakAcceleration <=
        rule.maximumPeakAccelerationMetersPerSecondSquared;
    final impulsesPresent =
        weakestImpulse >= rule.minimumPeakAccelerationMetersPerSecondSquared;
    final airTimeValid =
        freeFallMilliseconds >= rule.minimumFreeFallMilliseconds &&
        freeFallMilliseconds <= rule.maximumFreeFallMilliseconds;
    final score = _minimum([
      freeFallMilliseconds / rule.minimumFreeFallMilliseconds,
      weakestImpulse / rule.minimumPeakAccelerationMetersPerSecondSquared,
    ]).clamp(0, 1).toDouble();
    final reasonCode = !impactSafe
        ? 'motion_toss_impact_too_high'
        : !airTimeValid
        ? 'motion_toss_air_time_not_met'
        : !impulsesPresent
        ? 'motion_toss_impulses_not_detected'
        : 'motion_verified';
    return _result(
      base,
      accepted: impactSafe && airTimeValid && impulsesPresent,
      reasonCode: reasonCode,
      score: score,
      repetitions: impactSafe && airTimeValid && impulsesPresent ? 1 : 0,
      freeFallMilliseconds: freeFallMilliseconds,
    );
  }

  MotionEvidenceAnalysis _shake(
    List<MotionEvidenceSample> samples,
    MotionEvidenceRule rule,
    _TraceMetrics metrics,
    _BaseMetrics base,
  ) {
    // Capture starts at rest. Using a longer opening window would absorb the
    // first deliberate shake into the baseline and under-count short dares.
    final baseline = _axisAcceleration(samples.first, rule.axis);
    var lastPeakMicros = -shakePeakSeparation.inMicroseconds;
    var lastSign = 0;
    var alternatingPeaks = 0;
    for (final sample in samples) {
      final value = _axisAcceleration(sample, rule.axis) - baseline;
      if (value.abs() < rule.minimumPeakAccelerationMetersPerSecondSquared) {
        continue;
      }
      final sign = value.isNegative ? -1 : 1;
      if (sign == lastSign ||
          sample.elapsedMicroseconds - lastPeakMicros <
              shakePeakSeparation.inMicroseconds) {
        continue;
      }
      alternatingPeaks += 1;
      lastPeakMicros = sample.elapsedMicroseconds;
      lastSign = sign;
    }
    final repetitions = alternatingPeaks ~/ 2;
    final impactSafe =
        metrics.peakAcceleration <=
        rule.maximumPeakAccelerationMetersPerSecondSquared;
    final repetitionsReached = repetitions >= rule.targetRepetitions;
    final score = (repetitions / rule.targetRepetitions).clamp(0, 1).toDouble();
    return _result(
      base,
      accepted: impactSafe && repetitionsReached,
      reasonCode: !impactSafe
          ? 'motion_shake_force_too_high'
          : repetitionsReached
          ? 'motion_verified'
          : 'motion_shake_count_not_met',
      score: score,
      repetitions: repetitions,
    );
  }

  MotionEvidenceAnalysis _stillness(
    MotionEvidenceRule rule,
    _TraceMetrics metrics,
    _BaseMetrics base,
  ) {
    final accepted =
        metrics.peakAngularSpeed <= rule.maximumAngularSpeedRadiansPerSecond;
    final score = accepted
        ? 1.0
        : (rule.maximumAngularSpeedRadiansPerSecond / metrics.peakAngularSpeed)
              .clamp(0, 1)
              .toDouble();
    return _result(
      base,
      accepted: accepted,
      reasonCode: accepted ? 'motion_verified' : 'motion_not_steady',
      score: score,
      repetitions: accepted ? 1 : 0,
    );
  }

  List<MotionEvidenceSample> _validatedTrace(
    List<MotionEvidenceSample> samples,
  ) {
    if (samples.length < minimumSamples || samples.length > maximumSamples) {
      throw ArgumentError(
        'Motion evidence needs $minimumSamples-$maximumSamples samples.',
      );
    }
    if (samples.first.elapsedMicroseconds != 0) {
      throw ArgumentError('Motion evidence must begin at zero microseconds.');
    }
    var previousMicros = -1;
    for (final sample in samples) {
      if (sample.elapsedMicroseconds <= previousMicros) {
        throw ArgumentError('Motion sample times must be strictly increasing.');
      }
      if (previousMicros >= 0 &&
          sample.elapsedMicroseconds - previousMicros >
              maximumSampleGap.inMicroseconds) {
        throw ArgumentError('Motion evidence contains a sampling gap.');
      }
      final gyroscope = [
        sample.gyroscopeX,
        sample.gyroscopeY,
        sample.gyroscopeZ,
      ];
      final acceleration = [
        sample.accelerationX,
        sample.accelerationY,
        sample.accelerationZ,
      ];
      if ([...gyroscope, ...acceleration].any((value) => !value.isFinite) ||
          gyroscope.any(
            (value) => value.abs() > maximumGyroscopeMagnitude,
          ) ||
          acceleration.any(
            (value) => value.abs() > maximumAccelerationMagnitude,
          )) {
        throw ArgumentError(
          'Motion evidence contains an invalid sensor value.',
        );
      }
      previousMicros = sample.elapsedMicroseconds;
    }
    if (samples.last.elapsedMicroseconds > maximumDuration.inMicroseconds) {
      throw ArgumentError('Motion evidence exceeds 30 seconds.');
    }
    return samples;
  }

  /// Why creator-authored thresholds are invalid, in product-safe words, or
  /// null when they are valid.
  ///
  /// For a caller that refuses a creator's draft with its own typed error.
  /// [validateRule] throws the same reason instead.
  String? ruleProblem(MotionEvidenceRule rule) {
    if (rule.minimumDurationSeconds < 1 ||
        rule.maximumDurationSeconds > maximumDuration.inSeconds ||
        rule.maximumDurationSeconds < rule.minimumDurationSeconds) {
      return 'Motion duration bounds are invalid.';
    }
    if (rule.targetRepetitions < 1 ||
        rule.targetRepetitions > maximumRuleRepetitions) {
      return 'Motion repetitions must be between 1 and $maximumRuleRepetitions.';
    }
    if (rule.type == MotionActionType.rotation && rule.axis == MotionAxis.any) {
      return 'Counted rotations require a specific axis.';
    }
    if ((rule.type == MotionActionType.phoneToss ||
            rule.type == MotionActionType.stillness) &&
        (rule.axis != MotionAxis.any || rule.targetRepetitions != 1)) {
      return 'Phone toss and stillness rules use any axis and one repetition.';
    }
    if (!rule.minimumAngularSpeedRadiansPerSecond.isFinite ||
        !rule.maximumAngularSpeedRadiansPerSecond.isFinite ||
        rule.minimumAngularSpeedRadiansPerSecond <= 0 ||
        rule.maximumAngularSpeedRadiansPerSecond <
            rule.minimumAngularSpeedRadiansPerSecond ||
        rule.maximumAngularSpeedRadiansPerSecond > maximumRuleAngularSpeed) {
      return 'Motion angular speed bounds are invalid.';
    }
    if (!rule.minimumAxisDominance.isFinite ||
        rule.minimumAxisDominance < 0.5 ||
        rule.minimumAxisDominance > 1) {
      return 'Motion axis dominance is invalid.';
    }
    if (rule.minimumFreeFallMilliseconds < 100 ||
        rule.maximumFreeFallMilliseconds > maximumRuleFreeFall.inMilliseconds ||
        rule.maximumFreeFallMilliseconds < rule.minimumFreeFallMilliseconds) {
      return 'Motion free-fall bounds are invalid.';
    }
    if (!rule.minimumPeakAccelerationMetersPerSecondSquared.isFinite ||
        !rule.maximumPeakAccelerationMetersPerSecondSquared.isFinite ||
        rule.minimumPeakAccelerationMetersPerSecondSquared <= 0 ||
        rule.maximumPeakAccelerationMetersPerSecondSquared <
            rule.minimumPeakAccelerationMetersPerSecondSquared ||
        rule.maximumPeakAccelerationMetersPerSecondSquared >
            maximumRulePeakAcceleration) {
      return 'Motion acceleration bounds are invalid.';
    }
    if (rule.type == MotionActionType.phoneToss &&
        rule.minimumPeakAccelerationMetersPerSecondSquared <
            minimumPhoneTossPeakAcceleration) {
      return 'Phone toss impulse threshold is unsafe.';
    }
    if (rule.type == MotionActionType.stillness &&
        rule.maximumAngularSpeedRadiansPerSecond >
            maximumStillnessAngularSpeed) {
      return 'Stillness threshold is too permissive.';
    }
    return null;
  }
}

/// Compact stable representation used for signatures, replay checks, and DBs.
String canonicalMotionTraceJson(List<MotionEvidenceSample> samples) {
  return jsonEncode({
    'version': 1,
    'samples': [for (final sample in samples) sample.toCanonicalValues()],
  });
}

String motionTraceSha256(List<MotionEvidenceSample> samples) {
  return sha256
      .convert(utf8.encode(canonicalMotionTraceJson(samples)))
      .toString();
}

typedef _BaseMetrics = ({
  int sampleCount,
  int durationMilliseconds,
  double peakAngularSpeed,
  double peakAcceleration,
  double axisDominance,
});

MotionEvidenceAnalysis _result(
  _BaseMetrics base, {
  required bool accepted,
  required String reasonCode,
  double score = 0,
  int repetitions = 0,
  int freeFallMilliseconds = 0,
}) {
  return MotionEvidenceAnalysis(
    accepted: accepted,
    reasonCode: reasonCode,
    score: score,
    sampleCount: base.sampleCount,
    durationMilliseconds: base.durationMilliseconds,
    repetitionCount: repetitions,
    peakAngularSpeedRadiansPerSecond: base.peakAngularSpeed,
    peakAccelerationMetersPerSecondSquared: base.peakAcceleration,
    axisDominance: base.axisDominance,
    freeFallMilliseconds: freeFallMilliseconds,
  );
}

final class _TraceMetrics {
  const _TraceMetrics({
    required this.peakAngularSpeed,
    required this.peakAcceleration,
    required this.axisDominance,
  });

  factory _TraceMetrics.from(
    List<MotionEvidenceSample> samples,
    MotionAxis axis,
  ) {
    var peakAngularSpeed = 0.0;
    var peakAcceleration = 0.0;
    var targetEnergy = 0.0;
    var totalEnergy = 0.0;
    for (final sample in samples) {
      final gx = sample.gyroscopeX;
      final gy = sample.gyroscopeY;
      final gz = sample.gyroscopeZ;
      final angularMagnitude = math.sqrt(gx * gx + gy * gy + gz * gz);
      final accelerationMagnitude = _accelerationMagnitude(sample);
      peakAngularSpeed = math.max(peakAngularSpeed, angularMagnitude);
      peakAcceleration = math.max(peakAcceleration, accelerationMagnitude);
      final target = _axisGyroscope(sample, axis).abs();
      targetEnergy += target;
      totalEnergy += angularMagnitude;
    }
    return _TraceMetrics(
      peakAngularSpeed: peakAngularSpeed,
      peakAcceleration: peakAcceleration,
      axisDominance: totalEnergy == 0 ? 1 : targetEnergy / totalEnergy,
    );
  }

  final double peakAngularSpeed;
  final double peakAcceleration;
  final double axisDominance;
}

({int startMicroseconds, int endMicroseconds})? _longestFreeFall(
  List<MotionEvidenceSample> samples,
) {
  int? currentStart;
  ({int startMicroseconds, int endMicroseconds})? longest;
  for (final sample in samples) {
    if (_accelerationMagnitude(sample) <
        MotionEvidenceAnalyzer.freeFallAcceleration) {
      currentStart ??= sample.elapsedMicroseconds;
      continue;
    }
    if (currentStart == null) continue;
    final candidate = (
      startMicroseconds: currentStart,
      endMicroseconds: sample.elapsedMicroseconds,
    );
    if (longest == null ||
        candidate.endMicroseconds - candidate.startMicroseconds >
            longest.endMicroseconds - longest.startMicroseconds) {
      longest = candidate;
    }
    currentStart = null;
  }
  if (currentStart != null) {
    final candidate = (
      startMicroseconds: currentStart,
      endMicroseconds: samples.last.elapsedMicroseconds,
    );
    if (longest == null ||
        candidate.endMicroseconds - candidate.startMicroseconds >
            longest.endMicroseconds - longest.startMicroseconds) {
      longest = candidate;
    }
  }
  return longest;
}

double _peakAcceleration(
  List<MotionEvidenceSample> samples, {
  required int fromMicroseconds,
  required int toMicroseconds,
}) {
  var peak = 0.0;
  for (final sample in samples) {
    if (sample.elapsedMicroseconds < fromMicroseconds ||
        sample.elapsedMicroseconds > toMicroseconds) {
      continue;
    }
    peak = math.max(peak, _accelerationMagnitude(sample));
  }
  return peak;
}

double _axisGyroscope(MotionEvidenceSample sample, MotionAxis axis) {
  return switch (axis) {
    MotionAxis.pitch => sample.gyroscopeX,
    MotionAxis.roll => sample.gyroscopeY,
    MotionAxis.yaw => sample.gyroscopeZ,
    MotionAxis.any => math.sqrt(
      sample.gyroscopeX * sample.gyroscopeX +
          sample.gyroscopeY * sample.gyroscopeY +
          sample.gyroscopeZ * sample.gyroscopeZ,
    ),
  };
}

double _axisAcceleration(MotionEvidenceSample sample, MotionAxis axis) {
  return switch (axis) {
    MotionAxis.pitch => sample.accelerationX,
    MotionAxis.roll => sample.accelerationY,
    MotionAxis.yaw => sample.accelerationZ,
    MotionAxis.any => _accelerationMagnitude(sample),
  };
}

double _accelerationMagnitude(MotionEvidenceSample sample) {
  return math.sqrt(
    sample.accelerationX * sample.accelerationX +
        sample.accelerationY * sample.accelerationY +
        sample.accelerationZ * sample.accelerationZ,
  );
}

double _minimum(List<double> values) {
  return values.reduce(math.min);
}

int _quantize(double value) {
  if (!value.isFinite) {
    throw ArgumentError.value(value, 'value', 'Must be finite.');
  }
  return (value * 1000000).round();
}
