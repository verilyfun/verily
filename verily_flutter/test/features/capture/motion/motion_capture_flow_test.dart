import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/evidence/motion_capture_service.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import '../../../support/test_app.dart';
import '../support/fakes.dart';

void main() {
  testWidgets('measures a steady hand from the sensors and sends the trace', (
    tester,
  ) async {
    final sensors = _FakeSensors(rotation: 0);
    final harness = CaptureHarness(motion: sensors.service.capture);
    final results = await _open(tester, harness, _stillnessRequirement());

    expect(find.text('Hold the phone steady for 5 seconds'), findsOneWidget);
    expect(find.byKey(VerilyTestKeys.captureMotionSafetyWarning), findsNothing);

    await tester.tap(find.byKey(VerilyTestKeys.captureMotionBegin));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(sensors.listening, isTrue);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(find.text('Movement matched'), findsOneWidget);
    expect(sensors.listening, isFalse);

    await tester.tap(find.byKey(VerilyTestKeys.captureMotionUse));
    await tester.pumpAndSettle();

    final submitted = harness.gateway.submitted.single;
    expect(submitted.requirementId, testRequirementId);
    expect(submitted.motionSamples, isNotEmpty);
    expect(
      submitted.motionSamples!.every((sample) => sample.gyroscopeZ == 0),
      isTrue,
    );
    expect(results.single, same(harness.gateway.result));
  });

  testWidgets('measures only inside a capture window, and binds the trace '
      'to it', (tester) async {
    final sensors = _FakeSensors(rotation: 0);
    final harness = CaptureHarness(
      motion: sensors.service.capture,
      gateway: FakeEvidenceGateway(windowFailures: 1),
    );
    await _open(tester, harness, _stillnessRequirement());

    await tester.tap(find.byKey(VerilyTestKeys.captureMotionBegin));
    await tester.pumpAndSettle();

    expect(find.text("We couldn't start the capture"), findsOneWidget);
    expect(sensors.listening, isFalse);
    expect(find.byKey(VerilyTestKeys.captureMotionBegin), findsOneWidget);

    await tester.tap(find.byKey(VerilyTestKeys.captureMotionBegin));
    await tester.pump();
    await tester.pump(const Duration(seconds: 9));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(VerilyTestKeys.captureMotionUse));
    await tester.pumpAndSettle();

    expect(harness.gateway.windowsOpened, 1);
    expect(
      harness.gateway.submitted.single.captureChallengeId,
      FakeEvidenceGateway.windowId,
    );
  });

  testWidgets('a shaky hand does not match and can try again', (tester) async {
    final sensors = _FakeSensors(rotation: 3);
    final harness = CaptureHarness(motion: sensors.service.capture);
    final results = await _open(tester, harness, _stillnessRequirement());

    await tester.tap(find.byKey(VerilyTestKeys.captureMotionBegin));
    await tester.pump();
    await tester.pump(const Duration(seconds: 9));
    await tester.pumpAndSettle();

    expect(find.text('Not quite'), findsOneWidget);
    expect(find.byKey(VerilyTestKeys.captureMotionUse), findsNothing);
    expect(find.byKey(VerilyTestKeys.captureMotionRetry), findsOneWidget);
    expect(harness.gateway.submitted, isEmpty);
    expect(results, isEmpty);

    await tester.tap(find.byKey(VerilyTestKeys.captureMotionRetry));
    await tester.pump();
    await tester.pump(const Duration(seconds: 9));
    await tester.pumpAndSettle();

    // Nothing was sent, so the second try measures in the same window.
    expect(harness.gateway.windowsOpened, 1);
  });

  testWidgets('warns before a toss and explains missing sensors', (
    tester,
  ) async {
    final harness = CaptureHarness(
      motion: ({required requirement, cancellation, onProgress}) =>
          throw const MotionCaptureException(
            MotionCaptureFailure.unavailable,
          ),
    );
    await _open(
      tester,
      harness,
      testRequirement(
        ActionRequirementKind.motion,
        motionType: ActionMotionType.phoneToss,
      ),
    );

    expect(
      find.byKey(VerilyTestKeys.captureMotionSafetyWarning),
      findsOneWidget,
    );
    await tester.tap(find.byKey(VerilyTestKeys.captureMotionBegin));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Motion sensors unavailable'), findsOneWidget);
    expect(find.byKey(VerilyTestKeys.captureMotionRetry), findsOneWidget);
  });

  testWidgets('a trace this phone cannot vouch for is kept to send again', (
    tester,
  ) async {
    final sensors = _FakeSensors(rotation: 0);
    final harness = CaptureHarness(
      motion: sensors.service.capture,
      gateway: FakeEvidenceGateway(integrityRequired: true),
    );
    final results = await _open(tester, harness, _stillnessRequirement());

    await tester.tap(find.byKey(VerilyTestKeys.captureMotionBegin));
    await tester.pump();
    await tester.pump(const Duration(seconds: 9));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(VerilyTestKeys.captureMotionUse));
    await tester.pumpAndSettle();

    expect(
      find.text("This phone couldn't vouch for the capture"),
      findsOneWidget,
    );
    expect(find.text('Send again'), findsOneWidget);
    expect(harness.gateway.submitted, isEmpty);
    expect(results, isEmpty);
  });

  testWidgets('closing returns nothing', (tester) async {
    final harness = CaptureHarness(
      motion: _FakeSensors(rotation: 0).service.capture,
    );
    final results = await _open(tester, harness, _stillnessRequirement());

    await tester.tap(find.byKey(VerilyTestKeys.captureMotionCancel));
    await tester.pumpAndSettle();

    expect(results, [null]);
  });
}

/// Gyroscope and accelerometer streams that tick every 40 ms of test time.
final class _FakeSensors {
  _FakeSensors({required this.rotation});

  /// Angular speed around the z axis, in rad/s.
  final double rotation;
  int _listeners = 0;

  bool get listening => _listeners > 0;

  late final service = MotionCaptureService(
    accelerometerEvents: (period) => _ticks(
      period,
      (timestamp) => AccelerometerEvent(0, 0, 9.81, timestamp),
    ),
    gyroscopeEvents: (period) => _ticks(
      period,
      (timestamp) => GyroscopeEvent(0, 0, rotation, timestamp),
    ),
    clock: () => DateTime.utc(2026, 10, 21, 9, 30),
  );

  Stream<T> _ticks<T>(Duration period, T Function(DateTime) event) {
    final start = DateTime.utc(2026, 10, 21, 9, 30);
    late final StreamController<T> controller;
    Timer? timer;
    controller = StreamController<T>(
      onListen: () {
        _listeners++;
        var tick = 0;
        timer = Timer.periodic(period, (_) {
          tick++;
          controller.add(event(start.add(period * tick)));
        });
      },
      onCancel: () {
        _listeners--;
        timer?.cancel();
      },
    );
    return controller.stream;
  }
}

ActionRequirementView _stillnessRequirement() =>
    testRequirement(
      ActionRequirementKind.motion,
      motionType: ActionMotionType.stillness,
    ).copyWith(
      title: 'Hold steady',
      minDurationSeconds: 1,
      maxDurationSeconds: 8,
      motionAxis: ActionMotionAxis.any,
      targetRepetitions: 1,
      minAngularSpeedRadiansPerSecond: 0.1,
      maxAngularSpeedRadiansPerSecond: 1.5,
      minAxisDominance: 0.6,
      minFreeFallMilliseconds: 180,
      maxFreeFallMilliseconds: 700,
      minPeakAccelerationMetersPerSecondSquared: 12,
      maxPeakAccelerationMetersPerSecondSquared: 60,
    );

Future<List<EvidenceSubmissionResult?>> _open(
  WidgetTester tester,
  CaptureHarness harness,
  ActionRequirementView requirement,
) async {
  final results = <EvidenceSubmissionResult?>[];
  await pumpVerilyPage(
    tester,
    CaptureLauncher(requirement: requirement, onResult: results.add),
    overrides: harness.overrides,
    physicalSize: const Size(1080, 2400),
    devicePixelRatio: 2.625,
  );
  await openCapture(tester);
  return results;
}
