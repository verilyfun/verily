import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/screens/sign_in_screen.dart';
import 'package:verily_flutter/features/account/account_session.dart';
import 'package:verily_flutter/features/do/do_screen.dart';
import 'package:verily_flutter/features/evidence/location_service.dart';
import 'package:verily_flutter/features/verify_request/verify_request_screen.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import '../../support/skribble_faces.dart';
import '../do/support/fakes.dart';
import 'support/fakes.dart';

final String _location = '/r/$requestId';

/// Answers the place check and the capture as the server would.
void _answerProof(
  DeepLinkFakes fakes, {
  EvidenceDecisionStatus? placeStatus = EvidenceDecisionStatus.accepted,
  EvidenceDecisionStatus? captureStatus,
}) {
  fakes.doing.evidence.onSubmit = (input) => EvidenceSubmissionResult(
    attempt: requestAttemptFixture(accepted: [input.requirementId]),
    requirementId: input.requirementId,
    status: placeStatus,
    reasonCode: placeStatus?.name ?? 'queued',
    summary: '',
  );
  fakes.doing.onCapture = (attempt, requirement) => EvidenceSubmissionResult(
    attempt: requestAttemptFixture(status: ActionAttemptStatus.verifying),
    requirementId: requirement.id,
    status: captureStatus,
    reasonCode: 'checking',
    summary: '',
  );
}

void main() {
  setUpAll(loadSkribbleFaces);

  group('consent', () {
    testWidgets('says who asks, for what, and exactly what they get', (
      tester,
    ) async {
      final fakes = DeepLinkFakes();
      await pumpDeepLink(tester, fakes, location: _location);

      expect(find.text('Verify with Verily'), findsOneWidget);
      expect(find.text('From Slopper · slopper.app'), findsOneWidget);
      expect(find.text('Slopper wants a live video'), findsOneWidget);
      expect(find.text('“Show your finished sourdough.”'), findsOneWidget);
      expect(
        find.text(
          'You record it live in Verily, in one take. Nothing from your '
          'gallery.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Verily gives you a word to say while you record.'),
        findsOneWidget,
      );
      expect(
        find.text(
          "Verily checks your location once, to see if you're at their place.",
        ),
        findsOneWidget,
      );
      expect(
        find.text('Verily checks it shows what they asked for.'),
        findsOneWidget,
      );
      expect(find.text('What Slopper gets'), findsOneWidget);
      expect(
        find.text('Whether it passed, and when it was captured.'),
        findsOneWidget,
      );
      expect(
        find.text('Whether you were inside their place. Never where you were.'),
        findsOneWidget,
      );
      expect(find.text('A copy of your video to download.'), findsOneWidget);
      expect(
        find.text(
          'A private ID made only for Slopper. Never your name, email, or '
          'account.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Answer by '), findsOneWidget);
      // Nothing is captured or sent until the person agrees.
      expect(fakes.requests.calls, ['get']);
      expect(fakes.doing.captured, isEmpty);
    });

    testWidgets('a capture-only photo says the photo stays with Verily', (
      tester,
    ) async {
      final fakes = DeepLinkFakes(
        requests: FakeVerificationRequestRepository(
          view: requestViewFixture(
            kind: VerificationRequestKind.photo,
            check: VerificationRequestCheck.captureOnly,
            checksPlace: false,
            spokenChallenge: false,
            shareEvidence: false,
            instructions: null,
            website: null,
          ),
        ),
      );
      await pumpDeepLink(tester, fakes, location: _location);

      expect(find.text('From Slopper'), findsOneWidget);
      expect(find.text('Slopper wants a live photo'), findsOneWidget);
      expect(find.text('What they asked for'), findsNothing);
      expect(
        find.text("Verily checks it's a genuine live capture."),
        findsOneWidget,
      );
      expect(
        find.text('Not your photo. It stays with Verily.'),
        findsOneWidget,
      );
      expect(find.textContaining('word to say'), findsNothing);
      expect(find.textContaining('their place'), findsNothing);
    });

    testWidgets('declining hands the person back with status=declined', (
      tester,
    ) async {
      final fakes = DeepLinkFakes();
      await pumpDeepLink(tester, fakes, location: _location);

      await tapDeepLink(
        tester,
        find.byKey(VerilyTestKeys.verifyRequestDecline),
      );

      expect(fakes.requests.calls, ['get', 'decline']);
      final opened = fakes.launcher.launched.single;
      expect(opened.queryParameters['status'], 'declined');
      expect(opened.queryParameters['state'], 's1');
      expect(find.text('Request declined'), findsOneWidget);
      expect(
        find.text('Returning you to Slopper. Nothing was captured or shared.'),
        findsOneWidget,
      );
      expect(fakes.doing.captured, isEmpty);
    });
  });

  group('proof', () {
    testWidgets('checks the place, captures live, then returns with a code', (
      tester,
    ) async {
      final fakes = DeepLinkFakes();
      _answerProof(fakes);
      await pumpDeepLink(tester, fakes, location: _location);

      await tapDeepLink(tester, find.byKey(VerilyTestKeys.verifyRequestAccept));
      expect(find.text('Your proof for Slopper'), findsOneWidget);
      expect(find.text('Check in at their place'), findsOneWidget);
      // The capture waits for the place, so the receipt can say where.
      expect(find.text('Check in first, then capture.'), findsOneWidget);

      await tapDeepLink(
        tester,
        find.byKey(VerilyTestKeys.verifyRequestSharePlace),
      );
      expect(fakes.doing.location.preciseCalls, 1);
      final place = fakes.doing.evidence.submitted.single;
      expect(place.requirementId, doUuid(0x901));
      expect(place.latitude, fakes.doing.location.fix.latitude);
      expect(find.text('Location sent'), findsOneWidget);
      expect(fakes.doing.captured, isEmpty);

      await tapDeepLink(
        tester,
        find.byKey(VerilyTestKeys.verifyRequestCapture),
      );

      expect(fakes.doing.captured.single.requirementKey, 'capture');
      expect(fakes.requests.calls, ['get', 'accept', 'finish']);
      final opened = fakes.launcher.launched.single;
      expect(opened.toString(), startsWith(requestRedirect));
      expect(opened.queryParameters['code'], 'receipt-1');
      expect(find.text('Returning you to Slopper'), findsOneWidget);
      expect(
        find.text(
          'Verily is still checking your proof. Slopper will get the result.',
        ),
        findsOneWidget,
      );
      // The code is opened, never shown.
      expect(find.textContaining('receipt-1'), findsNothing);
    });

    testWidgets('a location-only request returns once the place is sent', (
      tester,
    ) async {
      final fakes = DeepLinkFakes(
        requests: FakeVerificationRequestRepository(
          view: requestViewFixture(
            kind: VerificationRequestKind.location,
            check: VerificationRequestCheck.captureOnly,
            spokenChallenge: false,
            shareEvidence: false,
            instructions: null,
          ),
        ),
      );
      _answerProof(fakes);
      await pumpDeepLink(tester, fakes, location: _location);
      expect(
        find.text("Slopper wants to check you're at their place"),
        findsOneWidget,
      );

      await tapDeepLink(tester, find.byKey(VerilyTestKeys.verifyRequestAccept));
      expect(find.byKey(VerilyTestKeys.verifyRequestCapture), findsNothing);
      await tapDeepLink(
        tester,
        find.byKey(VerilyTestKeys.verifyRequestSharePlace),
      );

      expect(fakes.doing.captured, isEmpty);
      expect(fakes.requests.calls.last, 'finish');
      expect(fakes.launcher.launched.single.queryParameters['code'], isNotNull);
      expect(
        find.text('Verily checked your proof and it passed.'),
        findsOneWidget,
      );
    });

    testWidgets('a blocked location can be skipped when the place is extra', (
      tester,
    ) async {
      final fakes = DeepLinkFakes(
        doing: DoFakes(
          location: FakeLocationService(
            preciseFailure: LocationFailure.denied,
          ),
        ),
      );
      _answerProof(fakes);
      await pumpDeepLink(tester, fakes, location: _location);
      await tapDeepLink(tester, find.byKey(VerilyTestKeys.verifyRequestAccept));

      await tapDeepLink(
        tester,
        find.byKey(VerilyTestKeys.verifyRequestSharePlace),
      );
      expect(find.byKey(VerilyTestKeys.verifyRequestNotice), findsOneWidget);
      expect(fakes.doing.evidence.submitted, isEmpty);

      await tapDeepLink(
        tester,
        find.byKey(VerilyTestKeys.verifyRequestSkipPlace),
      );
      expect(
        find.text("Skipped. Slopper will see your place wasn't checked."),
        findsOneWidget,
      );

      await tapDeepLink(
        tester,
        find.byKey(VerilyTestKeys.verifyRequestCapture),
      );
      expect(fakes.doing.captured.single.requirementKey, 'capture');
      expect(fakes.launcher.launched, hasLength(1));
    });

    testWidgets('a place that did not match is said plainly', (tester) async {
      final fakes = DeepLinkFakes();
      _answerProof(fakes, placeStatus: EvidenceDecisionStatus.rejected);
      await pumpDeepLink(tester, fakes, location: _location);
      await tapDeepLink(tester, find.byKey(VerilyTestKeys.verifyRequestAccept));

      await tapDeepLink(
        tester,
        find.byKey(VerilyTestKeys.verifyRequestSharePlace),
      );

      expect(
        find.text(
          "Verily couldn't confirm you're inside their place. Slopper will "
          'see that.',
        ),
        findsOneWidget,
      );
      // The place is a side check: the capture still goes ahead.
      expect(find.byKey(VerilyTestKeys.verifyRequestCapture), findsOneWidget);
    });

    testWidgets('backing out of the capture keeps the step', (tester) async {
      final fakes = DeepLinkFakes(
        requests: FakeVerificationRequestRepository(
          view: requestViewFixture(checksPlace: false),
        ),
      );
      _answerProof(fakes);
      fakes.doing.onCapture = (_, _) => null;
      await pumpDeepLink(tester, fakes, location: _location);
      await tapDeepLink(tester, find.byKey(VerilyTestKeys.verifyRequestAccept));

      await tapDeepLink(
        tester,
        find.byKey(VerilyTestKeys.verifyRequestCapture),
      );

      expect(fakes.doing.captured, hasLength(1));
      expect(fakes.requests.calls, isNot(contains('finish')));
      expect(fakes.launcher.launched, isEmpty);
      expect(find.byKey(VerilyTestKeys.verifyRequestCapture), findsOneWidget);
    });

    testWidgets('a failed capture says so and can be tried again', (
      tester,
    ) async {
      final fakes = DeepLinkFakes(
        requests: FakeVerificationRequestRepository(
          view: requestViewFixture(checksPlace: false),
        ),
      );
      fakes.doing.onCapture = (_, _) => throw Exception('upload');
      await pumpDeepLink(tester, fakes, location: _location);
      await tapDeepLink(tester, find.byKey(VerilyTestKeys.verifyRequestAccept));

      await tapDeepLink(
        tester,
        find.byKey(VerilyTestKeys.verifyRequestCapture),
      );

      expect(find.byKey(VerilyTestKeys.verifyRequestNotice), findsOneWidget);
      expect(find.byKey(VerilyTestKeys.verifyRequestCapture), findsOneWidget);
      expect(fakes.launcher.launched, isEmpty);
    });

    testWidgets('changing their mind before any proof declines', (
      tester,
    ) async {
      final fakes = DeepLinkFakes();
      await pumpDeepLink(tester, fakes, location: _location);
      await tapDeepLink(tester, find.byKey(VerilyTestKeys.verifyRequestAccept));

      await tapDeepLink(
        tester,
        find.byKey(VerilyTestKeys.verifyRequestDeclineInstead),
      );

      expect(fakes.requests.calls, ['get', 'accept', 'decline']);
      expect(
        fakes.launcher.launched.single.queryParameters['status'],
        'declined',
      );
    });

    testWidgets('an App that did not open can be opened again', (
      tester,
    ) async {
      final fakes = DeepLinkFakes(
        requests: FakeVerificationRequestRepository(
          view: requestViewFixture(checksPlace: false),
        ),
        launcher: FakeExternalUrlLauncher(opens: false),
      );
      _answerProof(fakes, captureStatus: EvidenceDecisionStatus.accepted);
      await pumpDeepLink(tester, fakes, location: _location);
      await tapDeepLink(tester, find.byKey(VerilyTestKeys.verifyRequestAccept));
      await tapDeepLink(
        tester,
        find.byKey(VerilyTestKeys.verifyRequestCapture),
      );

      expect(
        find.text(
          "Slopper didn't open. Switch back to it yourself to carry on.",
        ),
        findsOneWidget,
      );
      expect(
        find.text('Verily checked your proof and it passed.'),
        findsOneWidget,
      );

      fakes.launcher.opens = true;
      await tapDeepLink(tester, find.byKey(VerilyTestKeys.deepLinkOpenApp));
      expect(fakes.launcher.launched, hasLength(2));
      expect(fakes.launcher.launched.last, fakes.launcher.launched.first);
      expect(find.textContaining("didn't open"), findsNothing);

      await tapDeepLink(
        tester,
        find.byKey(VerilyTestKeys.deepLinkBackToVerily),
      );
      expect(find.byType(DoScreen), findsOneWidget);
    });

    testWidgets('a rejected capture still returns and says it failed', (
      tester,
    ) async {
      final fakes = DeepLinkFakes(
        requests: FakeVerificationRequestRepository(
          view: requestViewFixture(checksPlace: false),
        ),
      );
      _answerProof(fakes, captureStatus: EvidenceDecisionStatus.rejected);
      await pumpDeepLink(tester, fakes, location: _location);
      await tapDeepLink(tester, find.byKey(VerilyTestKeys.verifyRequestAccept));
      await tapDeepLink(
        tester,
        find.byKey(VerilyTestKeys.verifyRequestCapture),
      );

      expect(
        find.text("Your proof didn't pass. Slopper will be told."),
        findsOneWidget,
      );
      expect(fakes.launcher.launched, hasLength(1));
    });
  });

  group('resuming', () {
    testWidgets('an accepted request picks up at the next step', (
      tester,
    ) async {
      final action = requestActionFixture(
        attempt: requestAttemptFixture(accepted: [doUuid(0x901)]),
      );
      final fakes = DeepLinkFakes(
        requests: FakeVerificationRequestRepository(
          view: requestViewFixture(
            status: VerificationRequestStatus.accepted,
            action: action,
          ),
        ),
      );
      _answerProof(fakes);
      await pumpDeepLink(tester, fakes, location: _location);

      expect(find.byKey(VerilyTestKeys.verifyRequestAccept), findsNothing);
      expect(find.text('Location sent'), findsOneWidget);
      await tapDeepLink(
        tester,
        find.byKey(VerilyTestKeys.verifyRequestCapture),
      );
      expect(fakes.requests.calls, ['get', 'finish']);
    });

    testWidgets('proof already in leaves only the way back', (tester) async {
      final fakes = DeepLinkFakes(
        requests: FakeVerificationRequestRepository(
          view: requestViewFixture(
            status: VerificationRequestStatus.completed,
            action: requestActionFixture(
              attempt: requestAttemptFixture(
                status: ActionAttemptStatus.verifying,
              ),
            ),
          ),
        ),
      );
      await pumpDeepLink(tester, fakes, location: _location);

      expect(find.text('Your proof is in'), findsOneWidget);
      expect(fakes.launcher.launched, isEmpty);
      await tapDeepLink(tester, find.byKey(VerilyTestKeys.verifyRequestReturn));
      expect(fakes.launcher.launched.single.queryParameters['code'], isNotNull);
    });

    testWidgets('a failed return can be tried again', (tester) async {
      final fakes = DeepLinkFakes(
        requests: FakeVerificationRequestRepository(
          view: requestViewFixture(
            status: VerificationRequestStatus.completed,
            action: requestActionFixture(
              attempt: requestAttemptFixture(
                status: ActionAttemptStatus.verifying,
              ),
            ),
          ),
        ),
      );
      fakes.requests.finishError = Exception('offline');
      await pumpDeepLink(tester, fakes, location: _location);

      await tapDeepLink(tester, find.byKey(VerilyTestKeys.verifyRequestReturn));
      expect(find.byKey(VerilyTestKeys.verifyRequestNotice), findsOneWidget);
      expect(fakes.launcher.launched, isEmpty);

      fakes.requests.finishError = null;
      await tapDeepLink(tester, find.byKey(VerilyTestKeys.verifyRequestReturn));
      expect(fakes.launcher.launched, hasLength(1));
    });

    testWidgets('proof the server never got reopens the steps it needs', (
      tester,
    ) async {
      final fakes = DeepLinkFakes(
        requests: FakeVerificationRequestRepository(
          view: requestViewFixture(
            status: VerificationRequestStatus.accepted,
            action: requestActionFixture(
              attempt: requestAttemptFixture(
                status: ActionAttemptStatus.verifying,
              ),
            ),
          ),
        ),
      );
      await pumpDeepLink(tester, fakes, location: _location);
      expect(find.text('Your proof is in'), findsOneWidget);

      // The server has only the place; the capture never reached it.
      fakes.requests
        ..finishError = AppPlatformException(
          problem: AppPlatformProblem.verificationRequestProofMissing,
          message: 'server words',
        )
        ..view = requestViewFixture(
          status: VerificationRequestStatus.accepted,
          action: requestActionFixture(
            attempt: requestAttemptFixture(accepted: [doUuid(0x901)]),
          ),
        );
      await tapDeepLink(tester, find.byKey(VerilyTestKeys.verifyRequestReturn));

      expect(fakes.requests.calls, ['get', 'finish', 'get']);
      expect(fakes.launcher.launched, isEmpty);
      expect(find.text('Your proof is in'), findsNothing);
      expect(find.text('Location sent'), findsOneWidget);
      expect(find.byKey(VerilyTestKeys.verifyRequestCapture), findsOneWidget);
      expect(
        find.text(
          "Verily hasn't got your proof yet, so there's nothing to send "
          'Slopper. Finish the steps above, then try again.',
        ),
        findsOneWidget,
      );
      expect(find.text('server words'), findsNothing);
    });

    testWidgets('signing in shows the request where the link opened it', (
      tester,
    ) async {
      final fakes = DeepLinkFakes(
        session: TestSession(const AccountSession.signedOut()),
      );
      // The sign-in kit's forms are measured for Verily's faces.
      final router = await pumpDeepLink(
        tester,
        fakes,
        location: _location,
        useAppTypeface: true,
      );

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.text('Sign in to answer this request'), findsOneWidget);
      expect(fakes.requests.calls, isEmpty);

      fakes.session.signIn();
      await settleDeepLink(tester);

      expect(find.byType(SignInScreen), findsNothing);
      expect(find.byType(VerifyRequestScreen), findsOneWidget);
      expect(find.text('Slopper wants a live video'), findsOneWidget);
      expect(router.state.uri.toString(), _location);
    });
  });

  group('unavailable', () {
    for (final (problem, title) in [
      (
        AppPlatformProblem.verificationRequestNotFound,
        "We couldn't find this request",
      ),
      (
        AppPlatformProblem.verificationRequestExpired,
        'This request has expired',
      ),
      (
        AppPlatformProblem.verificationRequestTaken,
        'Someone else answered this request',
      ),
      (AppPlatformProblem.verificationRequestClosed, 'This request is closed'),
      (AppPlatformProblem.rateLimited, "That's a lot of requests for now"),
    ]) {
      testWidgets('${problem.name} is said plainly', (tester) async {
        final fakes = DeepLinkFakes(
          requests: FakeVerificationRequestRepository(
            loadError: AppPlatformException(problem: problem, message: 'x'),
          ),
        );
        await pumpDeepLink(tester, fakes, location: _location);

        expect(find.text(title), findsOneWidget);
        expect(find.byKey(VerilyTestKeys.verifyRequestAccept), findsNothing);
        expect(find.text('Back to Verily'), findsOneWidget);
      });
    }

    for (final (status, title) in [
      (VerificationRequestStatus.expired, 'This request has expired'),
      // Declined by someone else: it was answered, not by this person.
      (
        VerificationRequestStatus.declined,
        'Someone else answered this request',
      ),
      // Accepted by someone else: only their view carries the action.
      (
        VerificationRequestStatus.accepted,
        'Someone else answered this request',
      ),
    ]) {
      testWidgets('a ${status.name} request names the App', (tester) async {
        final fakes = DeepLinkFakes(
          requests: FakeVerificationRequestRepository(
            view: requestViewFixture(status: status),
          ),
        );
        await pumpDeepLink(tester, fakes, location: _location);

        expect(find.text(title), findsOneWidget);
        expect(find.textContaining('Slopper'), findsWidgets);
      });
    }

    testWidgets('a request this person declined says they did', (
      tester,
    ) async {
      final fakes = DeepLinkFakes(
        requests: FakeVerificationRequestRepository(
          view: requestViewFixture(
            status: VerificationRequestStatus.declined,
            declinedByViewer: true,
          ),
        ),
      );
      await pumpDeepLink(tester, fakes, location: _location);

      expect(find.text('You declined this request'), findsOneWidget);
      expect(
        find.text(
          'Nothing was captured or shared with Slopper. Ask Slopper for a '
          'new request if you change your mind.',
        ),
        findsOneWidget,
      );
      expect(find.text('This request is closed'), findsNothing);
      expect(find.byKey(VerilyTestKeys.verifyRequestAccept), findsNothing);
      expect(find.text('Back to Verily'), findsOneWidget);
    });

    testWidgets('a malformed link is not found without a server call', (
      tester,
    ) async {
      final fakes = DeepLinkFakes();
      await pumpDeepLink(tester, fakes, location: '/r/not-a-request');

      expect(find.text("We couldn't find this request"), findsOneWidget);
      expect(fakes.requests.calls, isEmpty);
    });

    testWidgets('a revoked App says so in the server’s words', (tester) async {
      final fakes = DeepLinkFakes(
        requests: FakeVerificationRequestRepository(),
      );
      fakes.requests.acceptError = AppUnavailableException(
        appName: 'Slopper',
        message: 'This app was revoked by its creator.',
      );
      await pumpDeepLink(tester, fakes, location: _location);
      await tapDeepLink(tester, find.byKey(VerilyTestKeys.verifyRequestAccept));

      expect(find.text("Slopper isn't available"), findsOneWidget);
      expect(find.text('This app was revoked by its creator.'), findsOneWidget);
    });

    testWidgets('accepting an expired request says it expired', (
      tester,
    ) async {
      final fakes = DeepLinkFakes();
      fakes.requests.acceptError = AppPlatformException(
        problem: AppPlatformProblem.verificationRequestExpired,
        message: 'x',
      );
      await pumpDeepLink(tester, fakes, location: _location);
      await tapDeepLink(tester, find.byKey(VerilyTestKeys.verifyRequestAccept));

      expect(find.text('This request has expired'), findsOneWidget);
      expect(
        find.text(
          'Requests only last a short while. Ask Slopper for a new one.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a failed accept stays on consent and can be sent again', (
      tester,
    ) async {
      final fakes = DeepLinkFakes();
      fakes.requests.acceptError = Exception('offline');
      await pumpDeepLink(tester, fakes, location: _location);
      await tapDeepLink(tester, find.byKey(VerilyTestKeys.verifyRequestAccept));

      expect(find.byKey(VerilyTestKeys.verifyRequestNotice), findsOneWidget);
      fakes.requests.acceptError = null;
      await tapDeepLink(tester, find.byKey(VerilyTestKeys.verifyRequestAccept));
      expect(find.text('Your proof for Slopper'), findsOneWidget);
    });

    testWidgets('a failed load can be retried', (tester) async {
      final fakes = DeepLinkFakes(
        requests: FakeVerificationRequestRepository(
          loadError: Exception('offline'),
        ),
      );
      await pumpDeepLink(tester, fakes, location: _location);
      expect(find.text("We couldn't load this request"), findsOneWidget);

      fakes.requests.loadError = null;
      await tapDeepLink(tester, find.text('Try again'));
      expect(find.text('Slopper wants a live video'), findsOneWidget);
    });
  });

  group('fit', () {
    for (final (label, size) in [
      ('Seeker', const Size(1080, 2400)),
      ('compact', const Size(840, 1800)),
    ]) {
      for (final brightness in Brightness.values) {
        testWidgets(
          'consent fits a $label phone at 1.3x (${brightness.name})',
          (
            tester,
          ) async {
            tester.platformDispatcher.textScaleFactorTestValue = 1.3;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            await pumpDeepLink(
              tester,
              DeepLinkFakes(),
              location: _location,
              physicalSize: size,
              brightness: brightness,
              useAppTypeface: true,
            );

            expect(tester.takeException(), isNull);
            final accept = tester.getRect(
              find.byKey(VerilyTestKeys.verifyRequestAccept),
            );
            expect(accept.height, greaterThanOrEqualTo(44));
          },
        );
      }
    }
  });
}
