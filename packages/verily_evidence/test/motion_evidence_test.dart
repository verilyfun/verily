import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:verily_evidence/verily_evidence.dart';

void main() {
  const analyzer = MotionEvidenceAnalyzer();

  group('MotionEvidenceAnalyzer', () {
    test('counts five dominant yaw rotations', () {
      final samples = _samples(
        seconds: 5,
        gyroscope: (time) => (
          x: 0.1,
          y: 0.1,
          z: 2 * math.pi,
        ),
      );

      final result = analyzer.analyze(
        samples: samples,
        rule: _rule(
          type: MotionActionType.rotation,
          axis: MotionAxis.yaw,
          repetitions: 5,
        ),
      );

      expect(result.accepted, isTrue);
      expect(result.reasonCode, 'motion_verified');
      expect(result.repetitionCount, 5);
      expect(result.axisDominance, greaterThan(0.95));
    });

    test('rejects rotations around the wrong axis', () {
      final samples = _samples(
        seconds: 5,
        gyroscope: (time) => (x: 2 * math.pi, y: 0.1, z: 0.1),
      );

      final result = analyzer.analyze(
        samples: samples,
        rule: _rule(
          type: MotionActionType.rotation,
          axis: MotionAxis.yaw,
          repetitions: 2,
        ),
      );

      expect(result.accepted, isFalse);
      expect(result.reasonCode, 'motion_rotation_wrong_axis');
    });

    test('does not assemble full rotations from alternating half-turns', () {
      final samples = _samples(
        seconds: 5,
        gyroscope: (time) => (
          x: 0.1,
          y: 0.1,
          z: (time * 2).floor().isEven ? math.pi : -math.pi,
        ),
      );

      final result = analyzer.analyze(
        samples: samples,
        rule: _rule(
          type: MotionActionType.rotation,
          axis: MotionAxis.yaw,
          repetitions: 2,
        ),
      );

      expect(result.accepted, isFalse);
      expect(result.reasonCode, 'motion_rotation_count_not_met');
      expect(result.repetitionCount, 0);
    });

    test('recognizes a gentle launch, free fall, and catch', () {
      final samples = _samples(
        seconds: 2,
        acceleration: (time) {
          if (time >= 0.55 && time < 0.65) return (x: 0, y: 0, z: 18);
          if (time >= 0.65 && time < 0.95) return (x: 0, y: 0, z: 0.5);
          if (time >= 0.95 && time < 1.05) return (x: 0, y: 0, z: 20);
          return (x: 0, y: 0, z: 9.81);
        },
      );

      final result = analyzer.analyze(
        samples: samples,
        rule: _rule(type: MotionActionType.phoneToss),
      );

      expect(result.accepted, isTrue);
      expect(result.freeFallMilliseconds, inInclusiveRange(280, 340));
      expect(result.repetitionCount, 1);
    });

    test('rejects an unsafe catch impact', () {
      final samples = _samples(
        seconds: 2,
        acceleration: (time) {
          if (time >= 0.55 && time < 0.65) return (x: 0, y: 0, z: 18);
          if (time >= 0.65 && time < 0.95) return (x: 0, y: 0, z: 0.5);
          if (time >= 0.95 && time < 1.05) return (x: 0, y: 0, z: 80);
          return (x: 0, y: 0, z: 9.81);
        },
      );

      final result = analyzer.analyze(
        samples: samples,
        rule: _rule(type: MotionActionType.phoneToss),
      );

      expect(result.accepted, isFalse);
      expect(result.reasonCode, 'motion_toss_impact_too_high');
    });

    test('counts alternating shake cycles', () {
      final samples = _samples(
        seconds: 3,
        acceleration: (time) => (
          x: math.sin(time * 2 * math.pi * 2) * 18,
          y: 0,
          z: 9.81,
        ),
      );

      final result = analyzer.analyze(
        samples: samples,
        rule: _rule(
          type: MotionActionType.shake,
          axis: MotionAxis.pitch,
          repetitions: 5,
        ),
      );

      expect(result.accepted, isTrue);
      expect(result.repetitionCount, greaterThanOrEqualTo(5));
    });

    test('accepts a steady hold and rejects a moving one', () {
      final steady = analyzer.analyze(
        samples: _samples(seconds: 3),
        rule: _rule(
          type: MotionActionType.stillness,
          maximumAngularSpeed: 0.5,
        ),
      );
      final moving = analyzer.analyze(
        samples: _samples(
          seconds: 3,
          gyroscope: (time) => (x: 0, y: 0, z: 1.5),
        ),
        rule: _rule(
          type: MotionActionType.stillness,
          maximumAngularSpeed: 0.5,
        ),
      );

      expect(steady.accepted, isTrue);
      expect(moving.accepted, isFalse);
      expect(moving.reasonCode, 'motion_not_steady');
    });

    test('canonical trace and binding change with one sample', () {
      final first = _samples(seconds: 1);
      final second = [...first];
      final changed = second.last;
      second[second.length - 1] = MotionEvidenceSample(
        elapsedMicroseconds: changed.elapsedMicroseconds,
        gyroscopeX: changed.gyroscopeX,
        gyroscopeY: changed.gyroscopeY,
        gyroscopeZ: changed.gyroscopeZ + 0.01,
        accelerationX: changed.accelerationX,
        accelerationY: changed.accelerationY,
        accelerationZ: changed.accelerationZ,
      );

      final firstDigest = motionTraceSha256(first);
      final secondDigest = motionTraceSha256(second);

      expect(firstDigest, hasLength(64));
      expect(secondDigest, isNot(firstDigest));
      expect(
        motionEvidenceBindingHash(
          capturedAt: DateTime.utc(2026, 9, 6),
          traceSha256: firstDigest,
          sampleCount: first.length,
          durationMilliseconds: 1000,
        ),
        hasLength(64),
      );
    });

    test('rejects malformed timing and non-finite sensor values', () {
      final valid = _samples(seconds: 1);
      final repeatedTime = [...valid];
      repeatedTime[1] = const MotionEvidenceSample(
        elapsedMicroseconds: 0,
        gyroscopeX: 0,
        gyroscopeY: 0,
        gyroscopeZ: 0,
        accelerationX: 0,
        accelerationY: 0,
        accelerationZ: 9.81,
      );
      final nonFinite = [...valid];
      nonFinite[1] = MotionEvidenceSample(
        elapsedMicroseconds: nonFinite[1].elapsedMicroseconds,
        gyroscopeX: double.nan,
        gyroscopeY: 0,
        gyroscopeZ: 0,
        accelerationX: 0,
        accelerationY: 0,
        accelerationZ: 9.81,
      );

      expect(
        () => analyzer.analyze(
          samples: repeatedTime,
          rule: _rule(type: MotionActionType.stillness),
        ),
        throwsArgumentError,
      );
      expect(
        () => analyzer.analyze(
          samples: nonFinite,
          rule: _rule(type: MotionActionType.stillness),
        ),
        throwsArgumentError,
      );
    });

    test('rejects unsafe creator thresholds before capture', () {
      expect(
        () => analyzer.validateRule(
          _rule(type: MotionActionType.phoneToss).copyWithForTest(
            axis: MotionAxis.yaw,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => analyzer.validateRule(
          _rule(type: MotionActionType.phoneToss).copyWithForTest(
            maximumPeakAcceleration: 80,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => analyzer.validateRule(
          _rule(
            type: MotionActionType.stillness,
            maximumAngularSpeed: 3,
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}

extension on MotionEvidenceRule {
  MotionEvidenceRule copyWithForTest({
    MotionAxis? axis,
    double? maximumPeakAcceleration,
  }) {
    return MotionEvidenceRule(
      type: type,
      axis: axis ?? this.axis,
      targetRepetitions: targetRepetitions,
      minimumDurationSeconds: minimumDurationSeconds,
      maximumDurationSeconds: maximumDurationSeconds,
      minimumAngularSpeedRadiansPerSecond: minimumAngularSpeedRadiansPerSecond,
      maximumAngularSpeedRadiansPerSecond: maximumAngularSpeedRadiansPerSecond,
      minimumAxisDominance: minimumAxisDominance,
      minimumFreeFallMilliseconds: minimumFreeFallMilliseconds,
      maximumFreeFallMilliseconds: maximumFreeFallMilliseconds,
      minimumPeakAccelerationMetersPerSecondSquared:
          minimumPeakAccelerationMetersPerSecondSquared,
      maximumPeakAccelerationMetersPerSecondSquared:
          maximumPeakAcceleration ??
          maximumPeakAccelerationMetersPerSecondSquared,
    );
  }
}

MotionEvidenceRule _rule({
  required MotionActionType type,
  MotionAxis axis = MotionAxis.any,
  int repetitions = 1,
  double maximumAngularSpeed = 20,
}) {
  return MotionEvidenceRule(
    type: type,
    axis: axis,
    targetRepetitions: repetitions,
    minimumDurationSeconds: 1,
    maximumDurationSeconds: 10,
    minimumAngularSpeedRadiansPerSecond: type == MotionActionType.stillness
        ? 0.1
        : 1,
    maximumAngularSpeedRadiansPerSecond: maximumAngularSpeed,
    minimumAxisDominance: 0.6,
    minimumFreeFallMilliseconds: 180,
    maximumFreeFallMilliseconds: 700,
    minimumPeakAccelerationMetersPerSecondSquared: 12,
    maximumPeakAccelerationMetersPerSecondSquared: 60,
  );
}

List<MotionEvidenceSample> _samples({
  required int seconds,
  ({double x, double y, double z}) Function(double time)? gyroscope,
  ({double x, double y, double z}) Function(double time)? acceleration,
}) {
  const intervalMicros = 20000;
  final count = seconds * 50 + 1;
  return [
    for (var index = 0; index < count; index += 1)
      () {
        final elapsed = index * intervalMicros;
        final time = elapsed / Duration.microsecondsPerSecond;
        final gyro = gyroscope?.call(time) ?? (x: 0.02, y: 0.02, z: 0.02);
        final accel = acceleration?.call(time) ?? (x: 0.0, y: 0.0, z: 9.81);
        return MotionEvidenceSample(
          elapsedMicroseconds: elapsed,
          gyroscopeX: gyro.x,
          gyroscopeY: gyro.y,
          gyroscopeZ: gyro.z,
          accelerationX: accel.x,
          accelerationY: accel.y,
          accelerationZ: accel.z,
        );
      }(),
  ];
}
