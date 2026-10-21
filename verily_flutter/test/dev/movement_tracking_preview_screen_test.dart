import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/dev/movement_tracking_preview_screen.dart';
import 'package:verily_flutter/features/capture/movement/movement_capture_controller.dart';
import 'package:verily_flutter/features/capture/movement/movement_tracking_providers.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import '../features/capture/support/fakes.dart';
import '../support/test_app.dart';

void main() {
  testWidgets('lists every movement and reports what was counted', (
    tester,
  ) async {
    final requested = <ActionMovementKind>[];
    late FakeMovementCaptureController controller;
    await pumpVerilyPage(
      tester,
      MovementTrackingPreviewScreen(delay: (_) async {}),
      physicalSize: const Size(1080, 2400),
      devicePixelRatio: 2.625,
      overrides: [
        movementCaptureControllerFactoryProvider.overrideWithValue((
          kind, {
          required recordAudio,
        }) {
          requested.add(kind);
          return controller = FakeMovementCaptureController(
            recordAudio: recordAudio,
          );
        }),
      ],
    );

    await tester.tap(find.text('Squats'));
    await tester.pumpAndSettle();
    expect(requested, [ActionMovementKind.squats]);
    expect(controller.recordAudio, isFalse);

    controller.emit(
      const MovementCaptureState(
        phase: MovementCapturePhase.ready,
        liveCounting: MovementLiveCounting.active,
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(VerilyTestKeys.movementCaptureStart));
    await tester.pumpAndSettle();
    expect(controller.started, 1);

    await tester.pump(const Duration(seconds: 4));
    controller.emit(recordingState(count: 10));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Counted 10 · pose-lite-v1.squats-v1'), findsOneWidget);
    expect(find.byType(MovementTrackingPreviewScreen), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Table tennis bounces'), 200);
    expect(find.text('Table tennis bounces'), findsOneWidget);
  });
}
