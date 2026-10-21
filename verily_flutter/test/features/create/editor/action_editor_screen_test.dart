import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skribble/skribble.dart' show WiredSwitch;
import 'package:skribble_maps/skribble_maps.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/features/create/editor/editor_form.dart';
import 'package:verily_flutter/features/evidence/location_service.dart';
import 'package:verily_flutter/l10n/generated/app_localizations_en.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import 'support/editor_harness.dart';
import 'support/fakes.dart';

final l10n = AppLocalizationsEn();

Future<void> startBlank(WidgetTester tester) =>
    scrollAndTap(tester, find.byKey(VerilyTestKeys.editorStartBlank));

Future<void> addProof(WidgetTester tester, ProofKind kind) async {
  await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorAddProof));
  await scrollAndTap(
    tester,
    find.byKey(VerilyTestKeys.editorAddProofKind(kind.name)),
  );
}

Future<void> closeAddProofSheet(WidgetTester tester) async {
  final row = find.byKey(
    VerilyTestKeys.editorAddProofKind(ProofKind.location.name),
  );
  Navigator.of(tester.element(row)).pop();
  await tester.pumpAndSettle();
}

Future<void> fillBasics(
  WidgetTester tester, {
  String title = 'Morning walk',
}) async {
  await scrollAndEnter(tester, find.byKey(VerilyTestKeys.editorTitle), title);
  await scrollAndEnter(
    tester,
    find.byKey(VerilyTestKeys.editorDescription),
    'Walk to the park before nine.',
  );
}

void main() {
  group('starting a new action', () {
    testWidgets('lists the server templates and starts from one', (
      tester,
    ) async {
      final fakes = EditorFakes(
        actions: FakeActionRepository(templates: [walkTemplate()]),
      );
      await pumpEditor(tester, fakes);

      expect(find.text('Morning walk'), findsOneWidget);
      await scrollAndTap(
        tester,
        find.byKey(VerilyTestKeys.editorTemplate('morning-walk')),
      );

      final title = tester.widget<TextFormField>(
        find.byKey(VerilyTestKeys.editorTitle),
      );
      expect(title.controller!.text, 'Morning walk');
      expect(find.byKey(VerilyTestKeys.editorRequirement('park')), findsOne);
      expect(find.byKey(VerilyTestKeys.editorRequirement('view')), findsOne);
      expect(find.text(l10n.editorDraftReady), findsOneWidget);
    });

    testWidgets("a new action starts in the creator's own time zone", (
      tester,
    ) async {
      final fakes = EditorFakes(
        actions: FakeActionRepository(templates: [venueTemplate()]),
        deviceTimeZone: 'Africa/Lagos',
      );
      await pumpEditor(tester, fakes);
      await scrollAndTap(
        tester,
        find.byKey(VerilyTestKeys.editorTemplate('gig-check-in')),
      );

      await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorSave));

      expect(fakes.actions.savedRequests.single.timeZone, 'Africa/Lagos');
    });

    testWidgets('a template never supplies the venue secret', (tester) async {
      final fakes = EditorFakes(
        actions: FakeActionRepository(templates: [venueTemplate()]),
      );
      await pumpEditor(tester, fakes);
      await scrollAndTap(
        tester,
        find.byKey(VerilyTestKeys.editorTemplate('gig-check-in')),
      );
      expect(find.text(l10n.editorVenueCodeExplainer), findsOneWidget);

      await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorSave));

      final secret =
          fakes.actions.savedRequests.single.requirements.single.qrCode!;
      expect(secret, isNot('template-secret-do-not-use'));
      expect(secret, startsWith('verily-venue:'));
    });

    testWidgets('drafting off shows the server words and keeps templates', (
      tester,
    ) async {
      final fakes = EditorFakes(
        actions: FakeActionRepository(
          templates: [walkTemplate()],
          draftError: ActionDraftingUnavailableException(
            message: 'Drafting is resting for today. Templates still work.',
          ),
        ),
      );
      await pumpEditor(tester, fakes);

      await tester.enterText(
        find.byKey(VerilyTestKeys.editorPrompt),
        'Ten squats in the park before nine, filmed in one go.',
      );
      await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorDraftWithAi));

      expect(
        find.text('Drafting is resting for today. Templates still work.'),
        findsOneWidget,
      );
      expect(
        find.byKey(VerilyTestKeys.editorTemplate('morning-walk')),
        findsOneWidget,
      );
      expect(find.byKey(VerilyTestKeys.editorTitle), findsNothing);
    });

    testWidgets('a short description is not sent for drafting', (
      tester,
    ) async {
      final fakes = EditorFakes();
      await pumpEditor(tester, fakes);

      await tester.enterText(find.byKey(VerilyTestKeys.editorPrompt), 'Squats');
      await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorDraftWithAi));

      expect(find.text(l10n.editorPromptTooShort), findsOneWidget);
      expect(fakes.actions.draftPrompts, isEmpty);
    });

    testWidgets('an AI draft fills the editor with its safety notes', (
      tester,
    ) async {
      final template = walkTemplate();
      final fakes = EditorFakes(
        actions: FakeActionRepository(
          proposal: ActionDraftProposal(
            action: CreateActionDefinitionRequest(
              actionKey: 'model-key',
              title: 'Park squats',
              description: 'Ten squats by the fountain.',
              recurrence: ActionRecurrence.once,
              timeZone: 'Europe/London',
              requirements: template.requirements,
            ),
            safetyNotes: ['Pick a spot away from the path.'],
            assumptions: const [],
          ),
        ),
      );
      await pumpEditor(tester, fakes);

      await tester.enterText(
        find.byKey(VerilyTestKeys.editorPrompt),
        'Ten squats by the fountain in the park, filmed live.',
      );
      await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorDraftWithAi));

      expect(find.text(l10n.editorSafetyHeading), findsOneWidget);
      expect(find.text('Pick a spot away from the path.'), findsOneWidget);
      final title = tester.widget<TextFormField>(
        find.byKey(VerilyTestKeys.editorTitle),
      );
      expect(title.controller!.text, 'Park squats');

      // The model's key is never reused; the creator's title names it.
      await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorSave));
      expect(
        fakes.actions.savedRequests.single.actionKey,
        startsWith('park-squats-'),
      );
    });
  });

  group('proof', () {
    testWidgets('adds and removes every phone-verified kind', (tester) async {
      await pumpEditor(tester, EditorFakes());
      await startBlank(tester);

      final kinds = [
        ProofKind.location,
        ProofKind.venueCode,
        ProofKind.video,
        ProofKind.photo,
        ProofKind.audio,
      ];
      for (final kind in kinds) {
        await addProof(tester, kind);
      }
      for (final key in ['location', 'venue-code', 'video', 'photo', 'audio']) {
        expect(find.byKey(VerilyTestKeys.editorRequirement(key)), findsOne);
      }

      // Five is the most an action can ask for; the sheet says so.
      await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorAddProof));
      expect(find.text(l10n.editorProofMaxReached), findsWidgets);
      await tester.tap(
        find.byKey(VerilyTestKeys.editorAddProofKind(ProofKind.motion.name)),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(VerilyTestKeys.editorRequirement('motion')),
        findsNothing,
      );
      await closeAddProofSheet(tester);

      for (final key in ['location', 'venue-code', 'video', 'photo', 'audio']) {
        await scrollAndTap(
          tester,
          find.byKey(VerilyTestKeys.editorRemoveRequirement(key)),
        );
        expect(find.byKey(VerilyTestKeys.editorRequirement(key)), findsNothing);
      }

      await addProof(tester, ProofKind.movementReps);
      await addProof(tester, ProofKind.motion);
      expect(
        find.byKey(VerilyTestKeys.editorRequirement('movement-reps')),
        findsOne,
      );
      expect(find.byKey(VerilyTestKeys.editorRequirement('motion')), findsOne);
      expect(
        find.byKey(
          VerilyTestKeys.editorMovementKind('movement-reps', 'squats'),
        ),
        findsOne,
      );
    });

    testWidgets('the spoken word is on for recordings and absent for photos', (
      tester,
    ) async {
      await pumpEditor(tester, EditorFakes());
      await startBlank(tester);
      await addProof(tester, ProofKind.video);
      await addProof(tester, ProofKind.audio);
      await addProof(tester, ProofKind.photo);

      for (final key in ['video', 'audio']) {
        final row = find.byKey(VerilyTestKeys.editorSpokenChallenge(key));
        expect(row, findsOne);
        final toggle = tester.widget<WiredSwitch>(
          find.descendant(of: row, matching: find.byType(WiredSwitch)),
        );
        expect(toggle.value, isTrue);
      }
      expect(
        find.byKey(VerilyTestKeys.editorSpokenChallenge('photo')),
        findsNothing,
      );

      await scrollAndTap(
        tester,
        find.byKey(VerilyTestKeys.editorSpokenChallenge('video')),
      );
      final toggle = tester.widget<WiredSwitch>(
        find.descendant(
          of: find.byKey(VerilyTestKeys.editorSpokenChallenge('video')),
          matching: find.byType(WiredSwitch),
        ),
      );
      expect(toggle.value, isFalse);
    });

    testWidgets('App confirmation never mixes with phone proof', (
      tester,
    ) async {
      final fakes = EditorFakes(
        apps: FakeAppsRepository(
          apps: [
            appFixture(),
            appFixture(id: 901, name: 'Gone', status: VerilyAppStatus.revoked),
          ],
        ),
      );
      await pumpEditor(tester, fakes);
      await startBlank(tester);
      await addProof(tester, ProofKind.video);

      // With phone proof present, App confirmation says why it cannot join.
      await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorAddProof));
      expect(find.text(l10n.editorProofPhoneOnly), findsOneWidget);
      await tester.tap(
        find.byKey(
          VerilyTestKeys.editorAddProofKind(ProofKind.appConfirmation.name),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.editorProofPhoneOnly), findsOneWidget);
      await closeAddProofSheet(tester);

      await scrollAndTap(
        tester,
        find.byKey(VerilyTestKeys.editorRemoveRequirement('video')),
      );
      await addProof(tester, ProofKind.appConfirmation);

      // Only active Apps are offered.
      expect(find.text('Gone'), findsNothing);
      await scrollAndTap(
        tester,
        find.byKey(
          VerilyTestKeys.editorAppChoice(
            'app-confirmation',
            editorUuid(900).uuid,
          ),
        ),
      );
      expect(find.text(l10n.editorAppTrust('Slopper')), findsOneWidget);

      await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorAddProof));
      expect(find.text(l10n.editorProofAppOnly), findsWidgets);
      await closeAddProofSheet(tester);

      await fillBasics(tester);
      await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorSave));
      final requirement =
          fakes.actions.savedRequests.single.requirements.single;
      expect(requirement.kind, ActionRequirementKind.externalApp);
      expect(requirement.appId, editorUuid(900));
      expect(requirement.appVerificationMode, isNull);
    });

    testWidgets('a place comes from a map tap or the device position', (
      tester,
    ) async {
      final fakes = EditorFakes(
        location: FakeLocationService(
          fix: LocationFix(
            latitude: 51.5,
            longitude: -0.12,
            accuracyMeters: 8,
            capturedAt: DateTime.utc(2026, 10, 21),
          ),
        ),
      );
      await pumpEditor(tester, fakes);
      await startBlank(tester);
      await addProof(tester, ProofKind.location);

      final map = tester.widget<WiredMap>(
        find.byKey(VerilyTestKeys.editorPlaceMap('location')),
      );
      map.onTap!(const LatLng(48.8584, 2.2945));
      await tester.pumpAndSettle();
      await scrollAndTap(
        tester,
        find.byKey(VerilyTestKeys.editorPlaceCoordinates('location')),
      );
      String field(ValueKey<String> key) =>
          tester.widget<TextFormField>(find.byKey(key)).controller!.text;
      expect(
        field(VerilyTestKeys.editorPlaceLatitude('location')),
        '48.858400',
      );
      expect(
        field(VerilyTestKeys.editorPlaceLongitude('location')),
        '2.294500',
      );
      expect(find.byType(WiredMapPin), findsOneWidget);

      await scrollAndTap(
        tester,
        find.byKey(VerilyTestKeys.editorUseMyLocation('location')),
      );
      expect(
        field(VerilyTestKeys.editorPlaceLatitude('location')),
        '51.500000',
      );

      fakes.location
        ..fix = null
        ..failure = LocationFailure.deniedForever;
      await scrollAndTap(
        tester,
        find.byKey(VerilyTestKeys.editorUseMyLocation('location')),
      );
      expect(find.text(l10n.editorLocationOff), findsOneWidget);
    });

    testWidgets('saving with no place or no proof says what is missing', (
      tester,
    ) async {
      final fakes = EditorFakes();
      await pumpEditor(tester, fakes);
      await startBlank(tester);
      await fillBasics(tester);

      await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorSave));
      expect(find.text(l10n.editorProofNone), findsOneWidget);

      await addProof(tester, ProofKind.location);
      await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorSave));
      expect(find.text(l10n.editorPlaceMissing), findsOneWidget);
      expect(fakes.actions.savedRequests, isEmpty);
    });
  });

  group('reward', () {
    testWidgets('checks the terms and writes out the whole budget', (
      tester,
    ) async {
      await pumpEditor(tester, EditorFakes());
      await startBlank(tester);
      await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorRewardToggle));

      expect(find.text(l10n.editorRewardBudgetIncomplete), findsOneWidget);
      await scrollAndEnter(
        tester,
        find.byKey(VerilyTestKeys.editorRewardAmount),
        '2.5',
      );
      await scrollAndEnter(
        tester,
        find.byKey(VerilyTestKeys.editorRewardMaxPayouts),
        '20',
      );
      expect(find.text(l10n.editorRewardBudget('50 USDC')), findsOneWidget);

      await scrollAndEnter(
        tester,
        find.byKey(VerilyTestKeys.editorRewardAmount),
        '0.0000001',
      );
      expect(find.text(l10n.editorRewardBudgetIncomplete), findsOneWidget);
      await scrollAndEnter(
        tester,
        find.byKey(VerilyTestKeys.editorRewardMaxWins),
        '21',
      );
      await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorSave));

      expect(find.text(l10n.editorRewardAmountInvalid), findsOneWidget);
      expect(find.text(l10n.editorRewardMaxWinsInvalid(20)), findsOneWidget);

      await scrollAndEnter(
        tester,
        find.byKey(VerilyTestKeys.editorRewardMaxPayouts),
        '5000',
      );
      expect(find.text(l10n.editorRewardMaxPayoutsInvalid), findsOneWidget);
    });
  });

  group('saving and publishing', () {
    testWidgets('every save is a draft under one stable key', (tester) async {
      final fakes = EditorFakes();
      await pumpEditor(tester, fakes);
      await startBlank(tester);
      await fillBasics(tester);
      await addProof(tester, ProofKind.photo);
      await scrollAndEnter(
        tester,
        find.byKey(VerilyTestKeys.editorVerifierPrompt('photo')),
        'A cup of coffee on a table.',
      );

      await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorSave));
      expect(find.text(l10n.editorSaved), findsOneWidget);
      await scrollAndEnter(
        tester,
        find.byKey(VerilyTestKeys.editorTitle),
        'Evening walk',
      );
      await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorSave));

      final requests = fakes.actions.savedRequests;
      expect(requests, hasLength(2));
      expect(fakes.actions.createdRequests, isEmpty);
      expect(requests.first.actionKey, startsWith('morning-walk-'));
      expect(requests.last.actionKey, requests.first.actionKey);
      expect(requests.last.title, 'Evening walk');
      final photo = requests.last.requirements.single;
      expect(photo.spokenChallengeRequired, isFalse);
      expect(photo.minDurationSeconds, isNull);
      expect(photo.verificationPrompt, 'A cup of coffee on a table.');
    });

    testWidgets('preview saves and opens the participant view', (
      tester,
    ) async {
      final fakes = EditorFakes(
        actions: FakeActionRepository(templates: [walkTemplate()]),
      );
      await pumpEditor(tester, fakes);
      await scrollAndTap(
        tester,
        find.byKey(VerilyTestKeys.editorTemplate('morning-walk')),
      );

      await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorPreview));

      expect(fakes.actions.savedRequests, hasLength(1));
      expect(
        find.byKey(participantPageFor(editorActionId.uuid)),
        findsOneWidget,
      );
    });

    testWidgets('an unfunded reward is funded before it publishes', (
      tester,
    ) async {
      final fakes = EditorFakes(
        actions: FakeActionRepository(templates: [walkTemplate()]),
        wallets: FakePayoutWalletRepository(wallet: linkedWalletFixture()),
        rewards: FakeRewardRepository(
          plan: fundingPlanFixture(localDevelopment: true),
        ),
      );
      await pumpEditor(tester, fakes);
      await scrollAndTap(
        tester,
        find.byKey(VerilyTestKeys.editorTemplate('morning-walk')),
      );
      await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorRewardToggle));
      await scrollAndEnter(
        tester,
        find.byKey(VerilyTestKeys.editorRewardAmount),
        '2.5',
      );
      await scrollAndEnter(
        tester,
        find.byKey(VerilyTestKeys.editorRewardMaxPayouts),
        '20',
      );
      expect(find.text(l10n.editorFundAndPublish), findsOneWidget);

      // Backing out of funding publishes nothing.
      await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorPublish));
      await tester.tap(find.byKey(VerilyTestKeys.editorPublishConfirm));
      await tester.pumpAndSettle();
      expect(find.byKey(VerilyTestKeys.fundingSheet), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byKey(VerilyTestKeys.fundingSheet),
          matching: find.byTooltip(l10n.dialogClose),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.editorFundFirst), findsOneWidget);
      expect(fakes.actions.publishedActions, isEmpty);

      // Funding verified by the server lets it publish.
      await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorPublish));
      await tester.tap(find.byKey(VerilyTestKeys.editorPublishConfirm));
      await tester.pumpAndSettle();
      await scrollAndTap(tester, find.byKey(VerilyTestKeys.fundingDevConfirm));
      expect(find.byKey(VerilyTestKeys.fundingFunded), findsOneWidget);
      await scrollAndTap(tester, find.byKey(VerilyTestKeys.fundingDone));

      expect(fakes.actions.publishedActions, hasLength(1));
      final published = fakes.actions.savedRequests.last;
      expect(published.reward!.amountPerPayout, 2500000);
      expect(published.reward!.maxPayouts, 20);
      expect(
        find.byKey(participantPageFor(editorActionId.uuid)),
        findsOneWidget,
      );
    });

    testWidgets('a funded reward publishes without funding again', (
      tester,
    ) async {
      final saved = actionFixture(
        reward: rewardSummaryFixture(status: RewardPoolStatus.funded),
      );
      final fakes = EditorFakes(
        actions: FakeActionRepository(previews: {saved.id.uuid: saved})
          ..lastSaved = saved,
      );
      await pumpEditor(
        tester,
        fakes,
        initialLocation: VerilyLocations.actionEdit(saved.id.uuid),
      );

      expect(find.text(l10n.editorRewardStatusFunded), findsOneWidget);
      expect(find.text(l10n.editorRewardLocked), findsOneWidget);
      // The server does not hand a media prompt back; it is written again.
      expect(find.text(l10n.editorVerifierPromptRewrite), findsOneWidget);
      await scrollAndEnter(
        tester,
        find.byKey(VerilyTestKeys.editorVerifierPrompt('view')),
        'The video shows a park in daylight.',
      );

      await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorPublish));
      await tester.tap(find.byKey(VerilyTestKeys.editorPublishConfirm));
      await tester.pumpAndSettle();

      expect(find.byKey(VerilyTestKeys.fundingSheet), findsNothing);
      expect(fakes.actions.savedRequests.single.reward, isNull);
      expect(fakes.actions.publishedActions, hasLength(1));
    });

    testWidgets('a server refusal is shown in its own words', (tester) async {
      final fakes = EditorFakes(
        actions: FakeActionRepository(
          templates: [walkTemplate()],
          saveError: ActionAuthoringException(
            reason: ActionAuthoringProblem.externalProofMixed,
            message: 'An App confirmation is the only proof on its action.',
          ),
        ),
      );
      await pumpEditor(tester, fakes);
      await scrollAndTap(
        tester,
        find.byKey(VerilyTestKeys.editorTemplate('morning-walk')),
      );
      await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorSave));

      expect(
        find.text('An App confirmation is the only proof on its action.'),
        findsOneWidget,
      );
    });
  });
}
