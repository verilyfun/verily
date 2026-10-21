import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:verily_brand/verily_brand.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/widgets/reward_chip.dart';
import 'package:verily_flutter/features/do/do_providers.dart';
import 'package:verily_flutter/features/do/do_screen.dart';
import 'package:verily_flutter/features/evidence/location_service.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import 'support/clipboard.dart';
import 'support/do_harness.dart';
import 'support/fakes.dart';

const _actionId = 1;

Finder _row(ActionRequirementView requirement) =>
    find.byKey(VerilyTestKeys.actionProof(requirement.requirementKey));

Future<GoRouter> _pumpAction(
  WidgetTester tester,
  DoFakes fakes,
  ActionOpportunity action, {
  bool owned = false,
  Size physicalSize = const Size(800, 2400),
  double devicePixelRatio = 1,
  double textScale = 1,
  Brightness brightness = Brightness.light,
}) async {
  if (owned) {
    fakes.actions.owned[action.id] = action;
  } else {
    fakes.actions.available = [action];
  }
  final router = await pumpDoRoutes(
    tester,
    initialLocation: '/actions/${action.id}',
    overrides: fakes.overrides,
    physicalSize: physicalSize,
    devicePixelRatio: devicePixelRatio,
    textScale: textScale,
    brightness: brightness,
    useAppTypeface: textScale != 1,
  );
  await settle(tester);
  return router;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await settle(tester);
}

ActionAttemptView _attempt({
  ActionAttemptStatus status = ActionAttemptStatus.collectingEvidence,
  List<ActionRequirementView> accepted = const [],
  RewardPayoutStatus? payoutStatus,
  RewardOutcome? rewardOutcome,
  bool rewardValueReview = false,
  String? rejectionCode,
}) => attemptFixture(
  actionId: _actionId,
  status: status,
  rejectionCode: rejectionCode,
  accepted: [for (final requirement in accepted) requirement.id],
  payoutStatus: payoutStatus,
  rewardOutcome: rewardOutcome,
  rewardValueReview: rewardValueReview,
);

void main() {
  group('ActionScreen loading', () {
    testWidgets('an action nobody can open is not found', (tester) async {
      final fakes = DoFakes();
      await pumpDoRoutes(
        tester,
        initialLocation: '/actions/${doUuid(99)}',
        overrides: fakes.overrides,
      );
      await settle(tester);

      expect(find.byKey(VerilyTestKeys.actionNotFound), findsOneWidget);
      expect(find.text("This action isn't here"), findsOneWidget);
      expect(find.textContaining('Internal server error'), findsNothing);

      await tester.tap(find.text('Find actions'));
      await settle(tester);
      expect(find.byType(DoScreen), findsOneWidget);
    });

    testWidgets('a malformed link is not found without a server call', (
      tester,
    ) async {
      final fakes = DoFakes();
      await pumpDoRoutes(
        tester,
        initialLocation: '/actions/not-an-id',
        overrides: fakes.overrides,
      );
      await settle(tester);

      expect(find.byKey(VerilyTestKeys.actionNotFound), findsOneWidget);
      expect(fakes.actions.getActionCalls, 0);
    });

    testWidgets('a failed load can be retried', (tester) async {
      final action = actionFixture(id: _actionId);
      final fakes = DoFakes()..actions.getActionError = Exception('offline');
      await _pumpAction(tester, fakes, action);

      expect(find.text("We couldn't open this action"), findsOneWidget);
      fakes.actions.getActionError = null;
      await tester.tap(find.text('Try again'));
      await settle(tester);
      expect(find.text(action.title), findsOneWidget);
    });

    testWidgets('shows what the action asks and the funded reward', (
      tester,
    ) async {
      final action = actionFixture(
        id: _actionId,
        requirements: [placeRequirement(), videoRequirement()],
        reward: rewardFixture(),
      );
      await _pumpAction(tester, DoFakes(), action);

      expect(find.text('by Café Lumen'), findsOneWidget);
      expect(find.text(action.title), findsOneWidget);
      expect(find.text(action.description), findsOneWidget);
      expect(find.text('Verified on your phone'), findsOneWidget);
      expect(find.byType(RewardChip), findsOneWidget);
      expect(find.text('12 rewards left'), findsOneWidget);
      expect(find.text('One reward per person'), findsOneWidget);
      expect(find.text('Be within 150 m of the pin'), findsOneWidget);
      expect(find.text("What you'll prove"), findsOneWidget);
      expect(_row(placeRequirement()), findsOneWidget);
      expect(_row(videoRequirement()), findsOneWidget);
      expect(find.byKey(VerilyTestKeys.actionStart), findsOneWidget);
    });

    testWidgets('an unfunded reward is not shown', (tester) async {
      final action = actionFixture(
        id: _actionId,
        reward: rewardFixture(status: RewardPoolStatus.awaitingFunding),
      );
      await _pumpAction(tester, DoFakes(), action);

      expect(find.byType(RewardChip), findsNothing);
      expect(find.textContaining('rewards left'), findsNothing);
    });
  });

  group('ActionScreen proof', () {
    testWidgets('start opens an attempt', (tester) async {
      final place = placeRequirement();
      final action = actionFixture(id: _actionId, requirements: [place]);
      final fakes = DoFakes();
      fakes.actions.onBegin = (_) => _attempt();
      await _pumpAction(tester, fakes, action);

      await _tap(tester, find.byKey(VerilyTestKeys.actionStart));

      expect(fakes.actions.begun, [action.id]);
      expect(find.byKey(VerilyTestKeys.actionStart), findsNothing);
      expect(find.text('Your proof'), findsOneWidget);
      expect(find.text('Tap a step to do it.'), findsOneWidget);
    });

    testWidgets('a place check sends a precise fix and finishes', (
      tester,
    ) async {
      final place = placeRequirement();
      final action = actionFixture(
        id: _actionId,
        requirements: [place],
        reward: rewardFixture(),
        myAttempt: _attempt(),
      );
      final fakes = DoFakes();
      fakes.evidence.onSubmit = (_) => resultFixture(
        attempt: _attempt(accepted: [place]),
        requirement: place,
      );
      fakes.actions.onComplete = (_) => _attempt(
        status: ActionAttemptStatus.verified,
        accepted: [place],
        payoutStatus: RewardPayoutStatus.reserved,
        rewardOutcome: RewardOutcome.won,
      );
      await _pumpAction(tester, fakes, action);

      await _tap(tester, _row(place));

      expect(fakes.location.preciseCalls, 1);
      expect(fakes.location.approximateCalls, 0);
      final input = fakes.evidence.submitted.single;
      expect(input.requirementId, place.id);
      expect(input.latitude, fakes.location.fix.latitude);
      expect(input.longitude, fakes.location.fix.longitude);
      expect(input.accuracyMeters, fakes.location.fix.accuracyMeters);
      expect(input.captureChallengeId, isNotNull);
      // Every required step accepted, so the attempt finishes by itself.
      expect(fakes.actions.completed, [doUuid(500)]);
      expect(find.byKey(VerilyTestKeys.actionVerifiedOutcome), findsOneWidget);
      expect(find.text('5 USDC on its way'), findsOneWidget);
    });

    testWidgets('a blocked location points to settings', (tester) async {
      final place = placeRequirement();
      final action = actionFixture(
        id: _actionId,
        requirements: [place],
        myAttempt: _attempt(),
      );
      final fakes = DoFakes(
        location: FakeLocationService(
          preciseFailure: LocationFailure.deniedForever,
        ),
      );
      await _pumpAction(tester, fakes, action);

      await _tap(tester, _row(place));

      expect(
        find.text(
          'Location is off for Verily. Turn it on in Settings to do this step.',
        ),
        findsOneWidget,
      );
      expect(fakes.evidence.submitted, isEmpty);
      await _tap(tester, find.text('Open settings'));
      expect(fakes.location.openSettingsCalls, 1);
    });

    testWidgets('a phone that cannot vouch for a capture is told so', (
      tester,
    ) async {
      final place = placeRequirement();
      final action = actionFixture(
        id: _actionId,
        requirements: [place],
        myAttempt: _attempt(),
      );
      final fakes = DoFakes(
        evidence: FakeEvidenceGateway(integrityRequired: true),
      );
      await _pumpAction(tester, fakes, action);

      await _tap(tester, _row(place));

      expect(
        find.text(
          "This phone couldn't vouch for the capture. Check your phone is up "
          'to date, then try again.',
        ),
        findsOneWidget,
      );
      expect(fakes.evidence.submitted, isEmpty);
    });

    testWidgets('a scanned venue code is submitted and ticked', (
      tester,
    ) async {
      final venue = venueCodeRequirement();
      final video = videoRequirement();
      final action = actionFixture(
        id: _actionId,
        requirements: [venue, video],
        myAttempt: _attempt(),
      );
      final fakes = DoFakes();
      fakes.evidence.onSubmit = (_) => resultFixture(
        attempt: _attempt(accepted: [venue]),
        requirement: venue,
      );
      await _pumpAction(tester, fakes, action);

      await _tap(tester, _row(venue));

      expect(fakes.scans, 1);
      final input = fakes.evidence.submitted.single;
      expect(input.requirementId, venue.id);
      expect(input.qrCode, 'venue-code-1');
      expect(
        find.descendant(
          of: _row(venue),
          matching: find.byKey(VerilyTestKeys.actionProofAcceptedTick),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _row(video),
          matching: find.byKey(VerilyTestKeys.actionProofAcceptedTick),
        ),
        findsNothing,
      );
      expect(find.text('Got it. That step is done.'), findsOneWidget);
      // The video is still to do, so nothing finishes yet.
      expect(fakes.actions.completed, isEmpty);
      expect(find.byKey(VerilyTestKeys.actionFinish), findsNothing);
    });

    testWidgets('a cancelled scan sends nothing', (tester) async {
      final venue = venueCodeRequirement();
      final action = actionFixture(
        id: _actionId,
        requirements: [venue],
        myAttempt: _attempt(),
      );
      final fakes = DoFakes()..scannedCode = null;
      await _pumpAction(tester, fakes, action);

      await _tap(tester, _row(venue));

      expect(fakes.scans, 1);
      expect(fakes.evidence.submitted, isEmpty);
      expect(find.byKey(VerilyTestKeys.actionNotice), findsNothing);
    });

    testWidgets('media proof goes to the capture flow and is checked', (
      tester,
    ) async {
      final video = videoRequirement();
      final action = actionFixture(
        id: _actionId,
        requirements: [video],
        myAttempt: _attempt(),
      );
      final fakes = DoFakes()
        ..onCapture = (attempt, requirement) => resultFixture(
          attempt: _attempt(status: ActionAttemptStatus.verifying),
          requirement: requirement,
          status: null,
        );
      fakes.actions.myAttempts = [
        _attempt(status: ActionAttemptStatus.verifying),
      ];
      await _pumpAction(tester, fakes, action);

      await _tap(tester, _row(video));

      expect(fakes.captured, [video]);
      expect(find.byKey(VerilyTestKeys.actionCheckingOutcome), findsOneWidget);
      expect(find.text('Checking your proof'), findsWidgets);
      expect(find.text('Sent. Verily is checking it now.'), findsOneWidget);
    });

    testWidgets('a full action says so plainly', (tester) async {
      final action = actionFixture(
        id: _actionId,
        myAttempt: _attempt(status: ActionAttemptStatus.capacityReached),
      );
      await _pumpAction(tester, DoFakes(), action);

      expect(find.byKey(VerilyTestKeys.actionCapacityOutcome), findsOneWidget);
      expect(
        find.text('Everyone this action could take has already finished it.'),
        findsOneWidget,
      );
    });

    testWidgets('a value review says a person will look', (tester) async {
      final action = actionFixture(
        id: _actionId,
        myAttempt: _attempt(
          status: ActionAttemptStatus.pendingReview,
          rewardValueReview: true,
        ),
      );
      await _pumpAction(tester, DoFakes(), action);

      final outcome = find.byKey(VerilyTestKeys.actionReviewOutcome);
      expect(outcome, findsOneWidget);
      expect(
        find.descendant(of: outcome, matching: find.text('With a reviewer')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Bigger rewards get a quick look from a person.'),
        findsOneWidget,
      );
    });
  });

  group('ActionScreen checking', () {
    testWidgets('polls while checking, pauses away, and stamps the result', (
      tester,
    ) async {
      final video = videoRequirement();
      final action = actionFixture(
        id: _actionId,
        requirements: [video],
        reward: rewardFixture(),
        myAttempt: _attempt(status: ActionAttemptStatus.verifying),
      );
      final fakes = DoFakes();
      fakes.actions.myAttempts = [
        _attempt(status: ActionAttemptStatus.verifying),
      ];
      addTearDown(
        () => tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        ),
      );
      await _pumpAction(tester, fakes, action);
      expect(fakes.actions.listMyAttemptsCalls, 0);

      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      expect(fakes.actions.listMyAttemptsCalls, 1);
      expect(find.byKey(VerilyTestKeys.actionCheckingOutcome), findsOneWidget);

      // In the background the ticks do nothing.
      [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ].forEach(tester.binding.handleAppLifecycleStateChanged);
      await tester.pump(const Duration(seconds: 10));
      await tester.pump();
      expect(fakes.actions.listMyAttemptsCalls, 1);

      // Coming back checks straight away.
      [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ].forEach(tester.binding.handleAppLifecycleStateChanged);
      await tester.pump();
      expect(fakes.actions.listMyAttemptsCalls, 2);

      fakes.actions.myAttempts = [
        _attempt(
          status: ActionAttemptStatus.verified,
          accepted: [video],
          payoutStatus: RewardPayoutStatus.released,
          rewardOutcome: RewardOutcome.won,
        ),
      ];
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      expect(fakes.actions.listMyAttemptsCalls, 3);

      // The verification arrived on this page, so the stamp slams.
      final stamp = find.byType(VerifiedStamp);
      expect(stamp, findsOneWidget);
      expect(tester.widget<VerifiedStamp>(stamp).pressed, lessThan(1));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.widget<VerifiedStamp>(stamp).pressed, 1);
      expect(find.text('5 USDC paid'), findsOneWidget);

      // Done checking: no more calls.
      await tester.pump(const Duration(minutes: 1));
      expect(fakes.actions.listMyAttemptsCalls, 3);
    });

    testWidgets('stops polling while another page covers it', (tester) async {
      final action = actionFixture(
        id: _actionId,
        requirements: [videoRequirement()],
        myAttempt: _attempt(status: ActionAttemptStatus.verifying),
      );
      final fakes = DoFakes();
      fakes.actions.myAttempts = [
        _attempt(status: ActionAttemptStatus.verifying),
      ];
      final router = await _pumpAction(tester, fakes, action);

      unawaited(router.push('/me'));
      await settle(tester);
      expect(find.text('me'), findsOneWidget);

      await tester.pump(const Duration(seconds: 15));
      await tester.pump();
      expect(fakes.actions.listMyAttemptsCalls, 0);

      router.pop();
      await settle(tester);
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      expect(fakes.actions.listMyAttemptsCalls, 1);
    });

    test('checks every 5 seconds for two minutes, then every 30', () {
      expect(
        attemptPollInterval(Duration.zero),
        const Duration(seconds: 5),
      );
      expect(
        attemptPollInterval(const Duration(seconds: 115)),
        const Duration(seconds: 5),
      );
      expect(
        attemptPollInterval(const Duration(minutes: 2)),
        const Duration(seconds: 30),
      );
    });
  });

  group('ActionScreen verified', () {
    Future<void> pumpVerified(
      WidgetTester tester,
      RewardPayoutStatus payoutStatus,
    ) async {
      final action = actionFixture(
        id: _actionId,
        reward: rewardFixture(),
        myAttempt: _attempt(
          status: ActionAttemptStatus.verified,
          accepted: [placeRequirement()],
          payoutStatus: payoutStatus,
          rewardOutcome: RewardOutcome.won,
        ),
      );
      await _pumpAction(tester, DoFakes(), action);
    }

    testWidgets('a restored result shows the stamp settled', (tester) async {
      await pumpVerified(tester, RewardPayoutStatus.released);

      expect(find.byKey(VerilyTestKeys.actionVerifiedOutcome), findsOneWidget);
      expect(
        tester.widget<VerifiedStamp>(find.byType(VerifiedStamp)).pressed,
        1,
      );
      expect(
        find.text('Verily checked your proof and it passed.'),
        findsOneWidget,
      );
      expect(find.text('5 USDC paid'), findsOneWidget);
      expect(find.byKey(VerilyTestKeys.actionAddWallet), findsNothing);
    });

    testWidgets('a finished attempt leads with its outcome', (tester) async {
      await pumpVerified(tester, RewardPayoutStatus.released);

      final outcomeTop = tester
          .getTopLeft(find.byKey(VerilyTestKeys.actionVerifiedOutcome))
          .dy;
      final proofTop = tester.getTopLeft(find.text('Your proof')).dy;
      expect(outcomeTop, lessThan(proofTop));
    });

    testWidgets('finishing at the bottom brings the outcome into view', (
      tester,
    ) async {
      // The place is the last step, so the person is scrolled down to it.
      final requirements = [
        venueCodeRequirement(position: 0),
        videoRequirement(isRequired: false, position: 1),
        placeRequirement(position: 2),
      ];
      final place = requirements.last;
      final action = actionFixture(
        id: _actionId,
        requirements: requirements,
        myAttempt: _attempt(accepted: [requirements.first]),
      );
      final fakes = DoFakes();
      fakes.evidence.onSubmit = (_) => resultFixture(
        attempt: _attempt(accepted: [requirements.first, place]),
        requirement: place,
      );
      fakes.actions.onComplete = (_) => _attempt(
        status: ActionAttemptStatus.verified,
        accepted: [requirements.first, place],
      );
      // Short enough that the proof list scrolls.
      await _pumpAction(
        tester,
        fakes,
        action,
        physicalSize: const Size(400, 600),
      );

      final scroll = tester.widget<ListView>(find.byType(ListView)).controller!;
      await tester.scrollUntilVisible(
        _row(place),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(scroll.offset, greaterThan(0));

      // The last required step finishes the attempt by itself.
      await _tap(tester, _row(place));

      expect(fakes.actions.completed, [doUuid(500)]);
      // Lets the scroll back to the top finish.
      await tester.pump(const Duration(milliseconds: 500));
      expect(scroll.offset, 0);
      expect(
        tester.getTopLeft(find.byKey(VerilyTestKeys.actionVerifiedOutcome)).dy,
        lessThan(600),
      );
    });

    testWidgets('a payout waiting for a wallet leads to Me', (tester) async {
      await pumpVerified(tester, RewardPayoutStatus.awaitingWallet);

      expect(find.text('Add a wallet to receive 5 USDC'), findsOneWidget);
      await _tap(tester, find.byKey(VerilyTestKeys.actionAddWallet));
      expect(find.text('me'), findsOneWidget);
    });

    testWidgets('a held payout explains the check', (tester) async {
      await pumpVerified(tester, RewardPayoutStatus.heldForReview);

      expect(find.text('5 USDC held for a quick check'), findsOneWidget);
      expect(
        find.text(
          "Bigger rewards get a quick look from a person before they're sent.",
        ),
        findsOneWidget,
      );
      expect(find.byKey(VerilyTestKeys.actionAddWallet), findsNothing);
    });

    testWidgets('a verified attempt that won nothing says why', (
      tester,
    ) async {
      final action = actionFixture(
        id: _actionId,
        reward: rewardFixture(payoutsRemaining: 0),
        myAttempt: _attempt(
          status: ActionAttemptStatus.verified,
          rewardOutcome: RewardOutcome.poolEmpty,
        ),
      );
      await _pumpAction(tester, DoFakes(), action);

      expect(find.byKey(VerilyTestKeys.actionPayoutStatus), findsNothing);
      expect(
        find.text('Every reward for this action has been claimed'),
        findsOneWidget,
      );
    });
  });

  group('ActionScreen rejected', () {
    testWidgets('a rejected proof says why in plain words', (tester) async {
      final place = placeRequirement();
      final action = actionFixture(
        id: _actionId,
        requirements: [place],
        myAttempt: _attempt(),
      );
      final fakes = DoFakes();
      fakes.evidence.onSubmit = (_) => resultFixture(
        attempt: _attempt(),
        requirement: place,
        status: EvidenceDecisionStatus.rejected,
        reasonCode: 'outside_area',
        // The server's own copy is not what the page shows.
        summary: 'Server summary',
      );
      await _pumpAction(tester, fakes, action);

      await _tap(tester, _row(place));

      expect(
        find.text(
          "You weren't inside the area for this action. Go to the pin and "
          'try again.',
        ),
        findsOneWidget,
      );
      expect(find.text('Server summary'), findsNothing);
    });

    testWidgets("a restored rejection explains the attempt's reason", (
      tester,
    ) async {
      final action = actionFixture(
        id: _actionId,
        myAttempt: _attempt(
          status: ActionAttemptStatus.rejected,
          rejectionCode: 'challenge_word_not_heard',
        ),
      );
      await _pumpAction(tester, DoFakes(), action);

      expect(
        find.text(
          "We couldn't hear your word. Say it clearly and record again.",
        ),
        findsOneWidget,
      );
    });

    testWidgets('allows one appeal', (tester) async {
      final action = actionFixture(
        id: _actionId,
        myAttempt: _attempt(status: ActionAttemptStatus.rejected),
      );
      final fakes = DoFakes();
      await _pumpAction(tester, fakes, action);

      expect(find.byKey(VerilyTestKeys.actionRejectedOutcome), findsOneWidget);
      expect(find.text("This proof wasn't accepted."), findsOneWidget);

      await _tap(tester, find.byKey(VerilyTestKeys.actionAppealOpen));
      final submit = find.byKey(VerilyTestKeys.actionAppealSubmit);
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);

      await tester.enterText(
        find.byKey(VerilyTestKeys.actionAppealReason),
        'too short',
      );
      await tester.pump();
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);

      await tester.enterText(
        find.byKey(VerilyTestKeys.actionAppealReason),
        'I was on the bridge; the light was poor.',
      );
      await tester.pump();
      await tester.tap(submit);
      await settle(tester);

      expect(fakes.appeals.submissions, [
        (
          attemptId: doUuid(500),
          reason: 'I was on the bridge; the light was poor.',
        ),
      ]);
      expect(
        find.text('You asked for a second look. A person will read it.'),
        findsOneWidget,
      );
      expect(find.byKey(VerilyTestKeys.actionAppealOpen), findsNothing);
    });

    testWidgets('shows an appeal already made instead of the button', (
      tester,
    ) async {
      final action = actionFixture(
        id: _actionId,
        myAttempt: _attempt(status: ActionAttemptStatus.rejected),
      );
      final fakes = DoFakes();
      await fakes.appeals.submit(
        attemptId: doUuid(500),
        reason: 'The code was on the screen.',
      );
      await _pumpAction(tester, fakes, action);

      expect(find.byKey(VerilyTestKeys.actionAppealStatus), findsOneWidget);
      expect(find.byKey(VerilyTestKeys.actionAppealOpen), findsNothing);
      expect(fakes.appeals.submissions, hasLength(1));
    });
  });

  group('ActionScreen App-confirmed', () {
    testWidgets('shows the link code and copies it', (tester) async {
      final clipboard = ClipboardRecorder()..install(tester);
      final app = appRequirement();
      final action = actionFixture(id: _actionId, requirements: [app]);
      final fakes = DoFakes();
      await _pumpAction(tester, fakes, action);

      expect(find.text('Confirmed by Slopper'), findsWidgets);
      expect(find.text('Verified on your phone'), findsNothing);
      expect(find.byKey(VerilyTestKeys.actionStart), findsNothing);
      expect(_row(app), findsNothing);

      await _tap(tester, find.byKey(VerilyTestKeys.actionLinkCodeOpen));

      expect(fakes.apps.linked, [app.appId]);
      expect(find.text('Your code for Slopper'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(VerilyTestKeys.actionLinkCode)).data,
        'vls_ABCDEFGHIJKLMNOPQRSTUV',
      );

      await tester.tap(find.byKey(VerilyTestKeys.actionLinkCodeCopy));
      await settle(tester);
      expect(clipboard.text, 'vls_ABCDEFGHIJKLMNOPQRSTUV');
      expect(find.text('Copied'), findsOneWidget);
    });

    testWidgets('says when the App has confirmed', (tester) async {
      final app = appRequirement();
      final action = actionFixture(
        id: _actionId,
        requirements: [app],
        myAttempt: _attempt(
          status: ActionAttemptStatus.verified,
          accepted: [app],
        ),
      );
      await _pumpAction(tester, DoFakes(), action);

      expect(find.text('Slopper confirmed this'), findsOneWidget);
      expect(find.byKey(VerilyTestKeys.actionLinkCodeOpen), findsNothing);
      expect(find.byKey(VerilyTestKeys.actionVerifiedOutcome), findsOneWidget);
    });

    testWidgets('a revoked App cannot be linked', (tester) async {
      final app = appRequirement(available: false);
      final action = actionFixture(id: _actionId, requirements: [app]);
      await _pumpAction(tester, DoFakes(), action);

      expect(
        find.text(
          "Slopper isn't confirming actions any more, so this one can't be "
          'done right now.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(VerilyTestKeys.actionLinkCodeOpen), findsNothing);
    });
  });

  group('ActionScreen creator', () {
    testWidgets('the creator edits and shows the venue code instead', (
      tester,
    ) async {
      final venue = venueCodeRequirement();
      final action = actionFixture(
        id: _actionId,
        viewerIsCreator: true,
        status: ActionDefinitionStatus.draft,
        requirements: [placeRequirement(), venue],
      );
      final fakes = DoFakes();
      await _pumpAction(tester, fakes, action, owned: true);

      expect(find.byKey(VerilyTestKeys.actionCreatorPanel), findsOneWidget);
      expect(find.text('This is your action'), findsOneWidget);
      expect(
        find.text("It's a draft, so nobody can see it yet."),
        findsOneWidget,
      );
      expect(find.byKey(VerilyTestKeys.actionStart), findsNothing);
      expect(
        find.byKey(VerilyTestKeys.actionShowVenueCode(venue.requirementKey)),
        findsOneWidget,
      );
      expect(find.text('Show venue code'), findsOneWidget);

      await _tap(tester, find.byKey(VerilyTestKeys.actionEdit));
      expect(find.text('editor: ${action.id}'), findsOneWidget);
    });
  });

  group('ActionScreen fit', () {
    final place = placeRequirement();
    final venue = venueCodeRequirement();
    final squats = videoRequirement(
      key: 'squats',
      title: 'Twenty squats on camera, counted live by your phone',
      movementKind: ActionMovementKind.squats,
      targetRepetitions: 20,
    );

    final states = <String, ActionAttemptView?>{
      'not started': null,
      'collecting': _attempt(accepted: [place]),
      'verified': _attempt(
        status: ActionAttemptStatus.verified,
        accepted: [place, venue, squats],
        payoutStatus: RewardPayoutStatus.awaitingWallet,
        rewardOutcome: RewardOutcome.won,
      ),
      'rejected': _attempt(status: ActionAttemptStatus.rejected),
    };

    for (final MapEntry(key: name, value: attempt) in states.entries) {
      testWidgets('fits a Seeker at 1.3x text ($name)', (tester) async {
        final action = actionFixture(
          id: _actionId,
          title: 'Watch the sunrise from Westminster Bridge with a friend',
          requirements: [place, venue, squats],
          reward: rewardFixture(maxWinsPerAccount: 3),
          myAttempt: attempt,
        );
        await _pumpAction(
          tester,
          DoFakes(),
          action,
          physicalSize: seekerPhysicalSize,
          devicePixelRatio: seekerPixelRatio,
          textScale: 1.3,
        );
        expect(tester.takeException(), isNull);

        final list = find.byType(ListView).first;
        for (var i = 0; i < 8; i++) {
          await tester.drag(list, const Offset(0, -300));
          await settle(tester);
          expect(tester.takeException(), isNull);
        }
      });
    }

    testWidgets('fits a Seeker at 1.3x text (creator, dark)', (tester) async {
      final action = actionFixture(
        id: _actionId,
        viewerIsCreator: true,
        requirements: [place, venue],
      );
      await _pumpAction(
        tester,
        DoFakes(),
        action,
        owned: true,
        physicalSize: seekerPhysicalSize,
        devicePixelRatio: seekerPixelRatio,
        textScale: 1.3,
        brightness: Brightness.dark,
      );
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView).first, const Offset(0, -600));
      await settle(tester);
      expect(tester.takeException(), isNull);
    });
  });
}
