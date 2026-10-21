// Renders the pages other Apps open Verily on (a verification request and an
// App link) through the real router at the Solana Seeker's portrait size,
// with the real Skribble faces, in light and dark.
//
// Every run asserts the pages lay out without errors. To also write PNGs for
// review into `.screenshots/phase-c/` (ignored by git):
//
//   flutter test --dart-define=VERILY_SCREENSHOTS=true \
//     test/screenshots/phase_c_deep_links_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/testing/verily_test_keys.dart';

import '../features/verify_request/support/fakes.dart';
import '../support/skribble_faces.dart';

const _writeScreenshots = bool.fromEnvironment('VERILY_SCREENSHOTS');
const _outputDirectory = '.screenshots/phase-c';

void main() {
  setUpAll(loadSkribbleFaces);

  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    testWidgets('a request: consent, proof, and the way back ($theme)', (
      tester,
    ) async {
      final fakes = DeepLinkFakes();
      fakes.doing.evidence.onSubmit = (input) => EvidenceSubmissionResult(
        attempt: requestAttemptFixture(accepted: [input.requirementId]),
        requirementId: input.requirementId,
        status: EvidenceDecisionStatus.accepted,
        reasonCode: 'proof_accepted',
        summary: '',
      );
      fakes.doing.onCapture = (attempt, requirement) =>
          EvidenceSubmissionResult(
            attempt: requestAttemptFixture(
              status: ActionAttemptStatus.verifying,
            ),
            requirementId: requirement.id,
            reasonCode: 'checking',
            summary: '',
          );
      await _pump(tester, fakes, '/r/$requestId', brightness);
      await _capture(tester, 'request-consent-$theme');

      await tapDeepLink(tester, find.byKey(VerilyTestKeys.verifyRequestAccept));
      await _capture(tester, 'request-proof-$theme');

      await tapDeepLink(
        tester,
        find.byKey(VerilyTestKeys.verifyRequestSharePlace),
      );
      await tapDeepLink(
        tester,
        find.byKey(VerilyTestKeys.verifyRequestCapture),
      );
      await _capture(tester, 'request-returning-$theme');
    });

    testWidgets('an expired request ($theme)', (tester) async {
      final fakes = DeepLinkFakes(
        requests: FakeVerificationRequestRepository(
          view: requestViewFixture(status: VerificationRequestStatus.expired),
        ),
      );
      await _pump(tester, fakes, '/r/$requestId', brightness);
      await _capture(tester, 'request-expired-$theme');
    });

    testWidgets('an App link ($theme)', (tester) async {
      final fakes = DeepLinkFakes();
      final location = Uri(
        path: '/link',
        queryParameters: {
          'app': requestAppId.toString(),
          'redirect_uri': 'com.slopper.app://verily',
          'state': 'abc',
        },
      ).toString();
      await _pump(tester, fakes, location, brightness);
      await _capture(tester, 'link-consent-$theme');

      await tapDeepLink(tester, find.byKey(VerilyTestKeys.appLinkApprove));
      await _capture(tester, 'link-returning-$theme');
    });
  }
}

Future<void> _pump(
  WidgetTester tester,
  DeepLinkFakes fakes,
  String location,
  Brightness brightness,
) async {
  await pumpDeepLink(
    tester,
    fakes,
    location: location,
    brightness: brightness,
    useAppTypeface: true,
  );
  // Lets ink and any entrance motion finish.
  for (var step = 0; step < 4; step++) {
    await tester.pump(const Duration(milliseconds: 600));
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  for (var step = 0; step < 3; step++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
  expect(tester.takeException(), isNull, reason: name);
  if (!_writeScreenshots) return;

  final view = tester.binding.renderViews.first;
  final layer = view.debugLayer! as OffsetLayer;
  await tester.runAsync(() async {
    // The root layer already scales by the device pixel ratio.
    final image = await layer.toImage(Offset.zero & tester.view.physicalSize);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('$_outputDirectory/deep-links-$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(png!.buffer.asUint8List());
  });
}
