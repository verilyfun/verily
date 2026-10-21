import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/create/editor/editor_form.dart';

import 'support/fakes.dart';

RequirementForm blank(ProofKind kind) => RequirementForm.blank(
  kind,
  requirementKey: kind.name,
  title: 'Title',
  instructions: 'Instructions',
);

void main() {
  group('actionKeyFor', () {
    test('slugs the title and adds a short random suffix', () {
      final key = actionKeyFor('  Morning Walk: the Park!  ', math.Random(1));
      expect(key, matches(RegExp(r'^morning-walk-the-park-[a-z0-9]{5}$')));
    });

    test('falls back for titles with no usable letters', () {
      expect(actionKeyFor('!!', math.Random(1)), startsWith('action-'));
    });

    test('keeps the server key pattern for long titles', () {
      final key = actionKeyFor('a' * 200, math.Random(1));
      expect(key.length, lessThanOrEqualTo(64));
      expect(key, matches(RegExp(r'^[a-z0-9][a-z0-9-]{1,62}[a-z0-9]$')));
    });
  });

  group('RequirementForm.toDraft', () {
    test('photos never carry a duration or a spoken word', () {
      final draft = (blank(
        ProofKind.photo,
      )..prompt.text = 'A red cup.').toDraft();
      expect(draft.kind, ActionRequirementKind.photo);
      expect(draft.spokenChallengeRequired, isFalse);
      expect(draft.minDurationSeconds, isNull);
      expect(draft.maxDurationSeconds, isNull);
      expect(draft.verificationPrompt, 'A red cup.');
    });

    test('recordings ask for the spoken word by default', () {
      for (final kind in [
        ProofKind.video,
        ProofKind.audio,
        ProofKind.movementReps,
      ]) {
        expect(blank(kind).toDraft().spokenChallengeRequired, isTrue);
      }
    });

    test('movement reps are a video with a movement and no prompt', () {
      final form = blank(ProofKind.movementReps)
        ..movementKind = ActionMovementKind.footballKickUps
        ..prompt.text = 'never sent'
        ..targetRepetitions.text = '25';
      final draft = form.toDraft();
      expect(draft.kind, ActionRequirementKind.video);
      expect(draft.movementKind, ActionMovementKind.footballKickUps);
      expect(draft.targetRepetitions, 25);
      expect(draft.verificationPrompt, isNull);
    });

    test('non-media proof carries no media settings', () {
      for (final kind in [
        ProofKind.location,
        ProofKind.venueCode,
        ProofKind.motion,
        ProofKind.appConfirmation,
      ]) {
        final draft = blank(kind).toDraft();
        expect(draft.verificationPrompt, isNull, reason: '$kind');
        expect(draft.verificationPolicy, isNull, reason: '$kind');
        expect(draft.minConfidence, isNull, reason: '$kind');
        expect(draft.spokenChallengeRequired, isNull, reason: '$kind');
        expect(draft.appVerificationMode, isNull, reason: '$kind');
      }
    });

    test('a venue code carries a fresh secret and nothing else', () {
      final draft = blank(ProofKind.venueCode).toDraft();
      expect(draft.kind, ActionRequirementKind.qrCode);
      expect(draft.qrCode, startsWith('verily-venue:'));
      expect(draft.qrCode!.length, greaterThan(32));
      expect(blank(ProofKind.venueCode).toDraft().qrCode, isNot(draft.qrCode));
    });

    test('motion types keep the axis and target the analyzer expects', () {
      final form = blank(ProofKind.motion)
        ..setMotionType(ActionMotionType.phoneToss);
      var draft = form.toDraft();
      expect(draft.motionAxis, ActionMotionAxis.any);
      expect(draft.targetRepetitions, 1);

      form.setMotionType(ActionMotionType.rotation);
      draft = form.toDraft();
      expect(draft.motionAxis, isNot(ActionMotionAxis.any));

      form.setMotionType(ActionMotionType.stillness);
      expect(form.toDraft().maxAngularSpeedRadiansPerSecond, lessThan(2));
      form.setMotionType(ActionMotionType.shake);
      expect(form.toDraft().maxAngularSpeedRadiansPerSecond, 25);
    });

    test('drafts never decide the App or the venue secret', () {
      final draft = RequirementForm.fromDraft(
        ActionRequirementDraft(
          requirementKey: 'door',
          kind: ActionRequirementKind.qrCode,
          title: 'Door',
          instructions: 'Scan.',
          isRequired: true,
          qrCode: 'known-secret',
        ),
      ).toDraft();
      expect(draft.qrCode, isNot('known-secret'));

      final app = RequirementForm.fromDraft(
        ActionRequirementDraft(
          requirementKey: 'app',
          kind: ActionRequirementKind.externalApp,
          title: 'App',
          instructions: 'Do it.',
          isRequired: true,
          appId: editorUuid(1),
        ),
      );
      expect(app.appId, isNull);
    });
  });

  group('EditorForm', () {
    test('App confirmation and phone proof never mix', () {
      final form = EditorForm(title: 'T', description: 'D');
      addTearDown(form.dispose);
      expect(form.canAdd(ProofKind.appConfirmation), isTrue);
      form.add(blank(ProofKind.video));
      expect(form.canAdd(ProofKind.appConfirmation), isFalse);
      expect(form.canAdd(ProofKind.photo), isTrue);

      final appOnly = EditorForm(
        title: 'T',
        description: 'D',
        requirements: [blank(ProofKind.appConfirmation)],
      );
      addTearDown(appOnly.dispose);
      for (final kind in ProofKind.values) {
        expect(appOnly.canAdd(kind), isFalse, reason: '$kind');
      }
    });

    test('an action asks for five proofs at most', () {
      final form = EditorForm(
        title: 'T',
        description: 'D',
        requirements: [for (var i = 0; i < 5; i++) blank(ProofKind.photo)],
      );
      addTearDown(form.dispose);
      expect(form.canAdd(ProofKind.location), isFalse);
    });

    test('keys stay unique per kind', () {
      final form = EditorForm(title: 'T', description: 'D');
      addTearDown(form.dispose);
      form.add(
        RequirementForm.blank(
          ProofKind.photo,
          requirementKey: form.keyFor(ProofKind.photo),
          title: 't',
          instructions: 'i',
        ),
      );
      expect(form.keyFor(ProofKind.photo), 'photo-2');
    });

    test('the action key is fixed at the first request', () {
      final form = EditorForm(title: 'Park run', description: 'D');
      addTearDown(form.dispose);
      final first = form.toRequest(math.Random(3)).actionKey;
      form.title.text = 'Renamed';
      expect(form.toRequest(math.Random(4)).actionKey, first);
    });

    test('a reward past draft is locked and left out of the request', () {
      final form = EditorForm.fromAction(
        actionFixture(
          reward: rewardSummaryFixture(
            status: RewardPoolStatus.awaitingFunding,
          ),
        ),
      );
      addTearDown(form.dispose);
      expect(form.reward.isLocked, isTrue);
      expect(form.toRequest().reward, isNull);

      form.lockReward(RewardPoolStatus.draft);
      expect(form.reward.isLocked, isFalse);
      expect(form.toRequest().reward!.amountPerPayout, 2500000);
    });
  });

  group('RewardForm', () {
    final now = DateTime(2026, 10, 21, 12);

    RewardForm terms({
      String amount = '2.5',
      int payouts = 20,
      int wins = 1,
      DateTime? expiresAt,
    }) => RewardForm(
      enabled: true,
      amount: amount,
      maxPayouts: payouts,
      maxWinsPerAccount: wins,
      expiresAt: expiresAt ?? now.add(const Duration(days: 30)),
    );

    test('the budget is the payout times the number of payouts', () {
      final reward = terms();
      addTearDown(reward.dispose);
      expect(reward.budget!.atoms, 50000000);
      expect(reward.problems(now), isEmpty);
      expect(reward.toDraft()!.refundDelayDays, 7);
    });

    test('names every problem with the terms', () {
      final cases = {
        RewardInputProblem.amountInvalid: terms(amount: '0'),
        RewardInputProblem.amountTooLarge: terms(amount: '1000000.000001'),
        RewardInputProblem.maxPayoutsInvalid: terms(payouts: 2049),
        RewardInputProblem.maxWinsInvalid: terms(payouts: 3, wins: 4),
        RewardInputProblem.endTooSoon: terms(
          expiresAt: now.add(const Duration(minutes: 30)),
        ),
        RewardInputProblem.endTooLate: terms(
          expiresAt: now.add(const Duration(days: 366)),
        ),
      };
      for (final MapEntry(key: problem, value: reward) in cases.entries) {
        addTearDown(reward.dispose);
        expect(reward.problems(now), contains(problem), reason: '$problem');
      }
    });
  });
}
