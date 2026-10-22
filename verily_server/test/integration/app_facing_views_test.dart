import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/public_reasons.dart';
import 'package:verily_server/src/apps/app_pull_check_service.dart';
import 'package:verily_server/src/apps/platform_keys.dart';
import 'package:verily_server/src/apps/webhooks/webhook_sender.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/rewards/reward_configuration.dart';

import 'test_tools/fake_reward_escrow_gateway.dart';
import 'test_tools/serverpod_test_tools.dart';
import 'test_tools/verily_fixtures.dart';

Matcher _notFound(MissingResource resource) => throwsA(
  isA<ResourceNotFoundException>().having(
    (error) => error.resource,
    'resource',
    resource,
  ),
);

/// What the creator's editor sends back after loading [view]: every field
/// the view exposes, and `qrCode: null` to keep a stored venue code.
ActionRequirementDraft _draftFromView(ActionRequirementView view) {
  final media = {
    ActionRequirementKind.video,
    ActionRequirementKind.photo,
    ActionRequirementKind.audio,
  }.contains(view.kind);
  return ActionRequirementDraft(
    requirementKey: view.requirementKey,
    kind: view.kind,
    title: view.title,
    instructions: view.instructions,
    isRequired: view.isRequired,
    latitude: view.latitude,
    longitude: view.longitude,
    radiusMeters: view.radiusMeters,
    maxAccuracyMeters: view.maxAccuracyMeters,
    verificationPrompt: view.verificationPrompt,
    minDurationSeconds: view.minDurationSeconds,
    maxDurationSeconds: view.maxDurationSeconds,
    minConfidence: view.minConfidence,
    verificationPolicy: view.verificationPolicy,
    spokenChallengeRequired: media ? view.spokenChallengeRequired : null,
    movementKind: view.movementKind,
    motionType: view.motionType,
    motionAxis: view.motionAxis,
    targetRepetitions: view.targetRepetitions,
    minAngularSpeedRadiansPerSecond: view.minAngularSpeedRadiansPerSecond,
    maxAngularSpeedRadiansPerSecond: view.maxAngularSpeedRadiansPerSecond,
    minAxisDominance: view.minAxisDominance,
    minFreeFallMilliseconds: view.minFreeFallMilliseconds,
    maxFreeFallMilliseconds: view.maxFreeFallMilliseconds,
    minPeakAccelerationMetersPerSecondSquared:
        view.minPeakAccelerationMetersPerSecondSquared,
    maxPeakAccelerationMetersPerSecondSquared:
        view.maxPeakAccelerationMetersPerSecondSquared,
    appId: view.appId,
    appVerificationMode: view.appVerificationMode,
    localCheck: view.localCheck,
  );
}

CreateActionDefinitionRequest _requestFromView(ActionOpportunity view) =>
    CreateActionDefinitionRequest(
      actionKey: view.actionKey,
      title: view.title,
      description: view.description,
      recurrence: view.recurrence,
      timeZone: view.timeZone,
      maxVerifiedCompletions: view.maxVerifiedCompletions,
      opensAt: view.opensAt,
      closesAt: view.closesAt,
      requirements: [for (final r in view.requirements) _draftFromView(r)],
      reward: switch (view.reward) {
        final reward? => RewardTermsDraft(
          amountPerPayout: reward.amountPerPayout,
          maxPayouts: reward.maxPayouts,
          maxWinsPerAccount: reward.maxWinsPerAccount,
          expiresAt: reward.expiresAt,
          refundDelayDays: reward.refundDelayDays,
        ),
        null => null,
      },
    );

/// Every stored rule of an action, without row ids, keyed by requirement.
Future<Map<String, Object?>> _storedRules(
  Session session,
  UuidValue actionId,
) async {
  final requirements = await ActionRequirement.db.find(
    session,
    where: (table) => table.actionDefinitionId.equals(actionId),
  );
  Map<String, Object?> strip(Map<String, dynamic> json) =>
      Map.of(json)..removeWhere(
        (key, _) => key == 'id' || key == 'requirementId' || key == 'createdAt',
      );
  Map<String, Object?>? row(SerializableModel? model) =>
      model == null ? null : strip(model.toJson() as Map<String, dynamic>);
  final rules = <String, Object?>{};
  for (final requirement in requirements) {
    final id = requirement.id!;
    rules[requirement.requirementKey] = {
      'requirement': strip(requirement.toJson())..remove('actionDefinitionId'),
      'location': row(
        await ActionLocationRule.db.findFirstRow(
          session,
          where: (table) => table.requirementId.equals(id),
        ),
      ),
      'media': row(
        await ActionMediaRule.db.findFirstRow(
          session,
          where: (table) => table.requirementId.equals(id),
        ),
      ),
      'motion': row(
        await ActionMotionRule.db.findFirstRow(
          session,
          where: (table) => table.requirementId.equals(id),
        ),
      ),
      'qr': row(
        await ActionQrRule.db.findFirstRow(
          session,
          where: (table) => table.requirementId.equals(id),
        ),
      ),
      'external': row(
        await ActionExternalRule.db.findFirstRow(
          session,
          where: (table) => table.requirementId.equals(id),
        ),
      ),
    };
  }
  return rules;
}

Map<String, Object?> _comparableView(ActionOpportunity view) {
  final json = (jsonDecode(jsonEncode(view.toJson())) as Map<String, Object?>)
    ..remove('id')
    ..remove('updatedAt');
  final requirements = json['requirements']! as List<Object?>;
  for (final requirement in requirements.cast<Map<String, Object?>>()) {
    requirement.remove('id');
  }
  return json;
}

void main() {
  withServerpod('Given creators and participants using the app', (
    sessionBuilder,
    endpoints,
  ) {
    final creatorId = testId(0x801);
    final participantId = testId(0x802);
    final otherCreatorId = testId(0x803);
    late TestSessionBuilder creator;
    late TestSessionBuilder participant;
    late TestSessionBuilder otherCreator;

    setUp(() async {
      RewardRuntime.current = fakeRewardConfiguration(
        FakeRewardEscrowGateway(),
      );
      creator = signedIn(sessionBuilder, creatorId);
      participant = signedIn(sessionBuilder, participantId);
      otherCreator = signedIn(sessionBuilder, otherCreatorId);
      final session = sessionBuilder.build();
      registerLocalEvidenceStorage(session);
      await insertAccounts(session, {
        creatorId: 'Ada',
        participantId: 'Grace',
        otherCreatorId: 'Linus',
      });
    });

    tearDown(() {
      RewardRuntime.current = const RewardConfiguration.disabled();
      PlatformKeys.current = const PlatformKeys();
    });

    group('when a deep link opens one action', () {
      test('then a published action is visible to anyone', () async {
        final action = await publishedAction(
          endpoints,
          creator,
          actionRequest(
            actionKey: 'be-there',
            requirements: [locationRequirement()],
          ),
        );

        final seen = await endpoints.actionVerification.getAction(
          participant,
          actionId: action.id,
        );
        final paused = await endpoints.actionVerification.pauseAction(
          creator,
          actionId: action.id,
          expectedRevision: action.revision,
        );
        final seenPaused = await endpoints.actionVerification.getAction(
          participant,
          actionId: action.id,
        );

        expect(seen.id, action.id);
        expect(seen.viewerIsCreator, isFalse);
        expect(seen.creatorDisplayName, 'Ada');
        expect(seen.requirements.single.verificationPrompt, isNull);
        expect(paused.status, ActionDefinitionStatus.paused);
        expect(seenPaused.status, ActionDefinitionStatus.paused);
      });

      test(
        'then drafts, private, held, and unknown actions are not found',
        () async {
          final draft = await endpoints.actionVerification.saveActionDraft(
            creator,
            actionRequest(
              actionKey: 'secret-draft',
              requirements: [locationRequirement()],
            ),
          );
          final held = await publishedAction(
            endpoints,
            creator,
            actionRequest(
              actionKey: 'held-action',
              requirements: [locationRequirement()],
            ),
          );
          await endpoints.moderation.report(
            participant,
            actionDefinitionId: held.id,
            category: 'dangerousActivity',
            details: 'The action asks people to climb an electricity pylon.',
            idempotencyKey: 'report-held',
          );
          final private = await publishedAction(
            endpoints,
            creator,
            actionRequest(
              actionKey: 'private-request',
              requirements: [locationRequirement()],
              maxVerifiedCompletions: 1,
            ),
          );
          final session = sessionBuilder.build();
          final row = await ActionDefinition.db.findById(session, private.id);
          await ActionDefinition.db.updateRow(
            session,
            row!.copyWith(visibility: ActionVisibility.verificationRequest),
          );

          for (final id in [draft.id, held.id, private.id, testId(0x8ff)]) {
            await expectLater(
              endpoints.actionVerification.getAction(participant, actionId: id),
              _notFound(MissingResource.action),
            );
          }
          expect(
            (await endpoints.actionVerification.getAction(
              creator,
              actionId: draft.id,
            )).viewerIsCreator,
            isTrue,
          );
          expect(
            (await endpoints.actionVerification.getAction(
              creator,
              actionId: held.id,
            )).id,
            held.id,
          );
        },
      );

      test(
        "then previewing someone else's action is a typed not-found",
        () async {
          final draft = await endpoints.actionVerification.saveActionDraft(
            creator,
            actionRequest(
              actionKey: 'mine',
              requirements: [locationRequirement()],
            ),
          );

          await expectLater(
            endpoints.actionVerification.previewAction(
              otherCreator,
              actionId: draft.id,
            ),
            _notFound(MissingResource.action),
          );
          await expectLater(
            endpoints.actionVerification.previewAction(
              creator,
              actionId: testId(0x8fe),
            ),
            _notFound(MissingResource.action),
          );
        },
      );
    });

    group('when attempts are listed', () {
      test('then each carries its action title and key', () async {
        final action = await publishedAction(
          endpoints,
          creator,
          actionRequest(
            actionKey: 'be-there',
            title: 'Be at the bridge',
            requirements: [locationRequirement()],
          ),
        );

        final begun = await endpoints.actionVerification.beginAttempt(
          participant,
          actionId: action.id,
          idempotencyKey: 'attempt-1',
        );
        final submitted = await endpoints.actionVerification.submitEvidence(
          participant,
          ActionEvidenceInput(
            attemptId: begun.id,
            requirementId: action.requirements.single.id,
            capturedAt: DateTime.now().toUtc(),
            latitude: 51.5007,
            longitude: -0.1246,
            accuracyMeters: 10,
          ),
        );
        final completed = await endpoints.actionVerification.completeAttempt(
          participant,
          begun.id,
        );
        final listed = await endpoints.actionVerification.listMyAttempts(
          participant,
          limit: 10,
        );

        for (final view in [
          begun,
          submitted.attempt,
          completed,
          listed.single,
        ]) {
          expect(view.actionTitle, 'Be at the bridge');
          expect(view.actionKey, 'be-there');
          expect(view.actionDefinitionId, action.id);
        }
        expect(submitted.reasonCode, PublicReason.proofAccepted);
        expect(completed.status, ActionAttemptStatus.verified);
      });

      test(
        'then a rejection reads as a public code, never an internal one',
        () async {
          final action = await publishedAction(
            endpoints,
            creator,
            actionRequest(
              actionKey: 'be-there',
              requirements: [locationRequirement()],
            ),
          );
          final attempt = await endpoints.actionVerification.beginAttempt(
            participant,
            actionId: action.id,
            idempotencyKey: 'attempt-far',
          );

          final far = await endpoints.actionVerification.submitEvidence(
            participant,
            ActionEvidenceInput(
              attemptId: attempt.id,
              requirementId: action.requirements.single.id,
              capturedAt: DateTime.now().toUtc(),
              latitude: 48.8584,
              longitude: 2.2945,
              accuracyMeters: 10,
            ),
          );
          final completed = await endpoints.actionVerification.completeAttempt(
            participant,
            attempt.id,
          );

          expect(far.status, EvidenceDecisionStatus.rejected);
          expect(far.reasonCode, PublicReason.outsideArea);
          expect(completed.status, ActionAttemptStatus.rejected);
          expect(completed.rejectionCode, PublicReason.outsideArea);
          final stored = await ActionAttempt.db.findById(
            sessionBuilder.build(),
            attempt.id,
          );
          expect(stored!.rejectionCode, 'outside_geofence', reason: 'audit');
        },
      );

      test("then an App's own reason never reaches the participant", () async {
        PlatformKeys.current = PlatformKeys.fromSecrets(
          webhookSigningMasterKey: base64.encode(
            utf8.encode('public-test-only-gaps-webhook-master-key'),
          ),
        );
        final app = await endpoints.verilyApp.createApp(
          creator,
          name: 'Step Counter',
        );
        await endpoints.verilyApp.setWebhookUrl(
          creator,
          appId: app.app.id,
          webhookUrl: 'https://93.184.216.34/verily',
        );
        await endpoints.verilyApp.rotateWebhookSecret(
          creator,
          appId: app.app.id,
        );
        final action = await publishedAction(
          endpoints,
          creator,
          actionRequest(
            actionKey: 'daily-steps',
            requirements: [
              externalRequirement(
                appId: app.app.id,
              ).copyWith(appVerificationMode: AppVerificationMode.pull),
            ],
          ),
        );
        final attempt = await endpoints.actionVerification.beginAttempt(
          participant,
          actionId: action.id,
          idempotencyKey: 'attempt-pull',
        );

        final result =
            await AppPullCheckService(
              sender: _Answering(
                '{"verdict":"rejected","reason":"partner_secret_reason"}',
              ),
              scheduler: (_, _, _) async {},
            ).requestVerification(
              sessionBuilder.build(),
              authUserId: participantId,
              attemptId: attempt.id,
              requirementId: action.requirements.single.id,
            );
        final listed = await endpoints.actionVerification.listMyAttempts(
          participant,
          limit: 10,
        );

        expect(result.status, EvidenceDecisionStatus.rejected);
        expect(result.reasonCode, PublicReason.appNotConfirmed);
        expect(jsonEncode(result.toJson()), isNot(contains('partner_secret')));
        expect(
          jsonEncode([for (final view in listed) view.toJson()]),
          isNot(contains('partner_secret')),
        );
        final decision = await EvidenceDecision.db.findFirstRow(
          sessionBuilder.build(),
          where: (table) => table.reasonCode.equals('partner_secret_reason'),
        );
        expect(decision, isNotNull, reason: 'kept for audit');
      });
    });

    group('when a creator edits a saved draft', () {
      test('then every rule field round-trips exactly', () async {
        final templates = await endpoints.actionVerification.listTemplates(
          creator,
        );
        final squats = templates
            .firstWhere((template) => template.templateKey == 'exercise-reps')
            .requirements
            .single;
        final spins = templates
            .firstWhere((template) => template.templateKey == 'yaw-five')
            .requirements
            .single;
        final draft = await endpoints.actionVerification.saveActionDraft(
          creator,
          actionRequest(
            actionKey: 'everything',
            recurrence: ActionRecurrence.daily,
            maxVerifiedCompletions: 40,
            reward: rewardTerms(maxPayouts: 2, refundDelayDays: 9),
            requirements: [
              locationRequirement(),
              qrRequirement(qrCode: 'venue-secret-2026'),
              mediaRequirement(
                kind: ActionRequirementKind.photo,
                key: 'show-plant',
                policy: ActionVerificationPolicy.modelCouncil,
                minConfidence: 0.73,
              ).copyWith(isRequired: false),
              squats,
              ActionRequirementDraft(
                requirementKey: 'thumbs-up',
                kind: ActionRequirementKind.photo,
                title: 'Thumbs up',
                instructions: 'Show a thumbs up to the camera.',
                isRequired: false,
                minConfidence: 0.8,
                localCheck: ActionLocalCheck(
                  task: LocalCheckTask.gesture,
                  label: 'Thumb_Up',
                  minScore: 0.6,
                  minFrames: 1,
                ),
              ),
            ],
          ),
        );
        final motionDraft = await endpoints.actionVerification.saveActionDraft(
          creator,
          actionRequest(actionKey: 'spin-it', requirements: [spins]),
        );
        final session = sessionBuilder.build();

        for (final saved in [draft, motionDraft]) {
          final before = await _storedRules(session, saved.id);
          final view = await endpoints.actionVerification.previewAction(
            creator,
            actionId: saved.id,
          );
          final again = await endpoints.actionVerification.saveActionDraft(
            creator,
            _requestFromView(view),
          );
          final after = await _storedRules(session, again.id);
          final viewAgain = await endpoints.actionVerification.previewAction(
            creator,
            actionId: again.id,
          );

          expect(again.id, saved.id, reason: 'the draft is updated in place');
          expect(after, before);
          expect(_comparableView(viewAgain), _comparableView(view));
        }
        final view = await endpoints.actionVerification.previewAction(
          creator,
          actionId: draft.id,
        );
        final byKey = {
          for (final requirement in view.requirements)
            requirement.requirementKey: requirement,
        };
        expect(
          byKey['show-plant']!.verificationPrompt,
          'Verify that the person waters a plant.',
        );
        expect(byKey['show-plant']!.minConfidence, 0.73);
        expect(byKey['exercise-reps']!.verificationPrompt, isNull);
        expect(byKey['thumbs-up']!.verificationPrompt, isNull);
        expect(byKey['scan-code']!.venueCodeConfigured, isTrue);
        expect(view.reward!.refundDelayDays, 9);
        final participantView = await endpoints.actionVerification.getAction(
          creator,
          actionId: draft.id,
        );
        expect(participantView.viewerIsCreator, isTrue);
      });

      test(
        'then a creator-only field stays hidden from participants',
        () async {
          final action = await publishedAction(
            endpoints,
            creator,
            actionRequest(
              actionKey: 'show-plant',
              requirements: [
                mediaRequirement(
                  kind: ActionRequirementKind.photo,
                  minConfidence: 0.73,
                ),
                qrRequirement(qrCode: 'venue-secret-2026'),
              ],
            ),
          );

          final seen = await endpoints.actionVerification.getAction(
            participant,
            actionId: action.id,
          );

          for (final requirement in seen.requirements) {
            expect(requirement.verificationPrompt, isNull);
            expect(requirement.minConfidence, isNull);
            expect(requirement.venueCodeConfigured, isNull);
          }
          expect(jsonEncode(seen.toJson()), isNot(contains('venue-secret')));
        },
      );
    });

    group('when a venue code is saved as null', () {
      Future<String> storedHash(UuidValue actionId) async {
        final session = sessionBuilder.build();
        final requirement = await ActionRequirement.db.findFirstRow(
          session,
          where: (table) =>
              table.actionDefinitionId.equals(actionId) &
              table.kind.equals(ActionRequirementKind.qrCode),
        );
        final rule = await ActionQrRule.db.findFirstRow(
          session,
          where: (table) => table.requirementId.equals(requirement!.id),
        );
        return rule!.secretHash;
      }

      test(
        'then the stored secret is kept, and a new code replaces it',
        () async {
          final first = await endpoints.actionVerification.saveActionDraft(
            creator,
            actionRequest(
              actionKey: 'venue',
              requirements: [qrRequirement(qrCode: 'venue-secret-2026')],
            ),
          );
          final original = await storedHash(first.id);

          await endpoints.actionVerification.saveActionDraft(
            creator,
            actionRequest(actionKey: 'venue', requirements: [qrRequirement()]),
          );
          final kept = await storedHash(first.id);
          await endpoints.actionVerification.saveActionDraft(
            creator,
            actionRequest(
              actionKey: 'venue',
              requirements: [qrRequirement(qrCode: 'rotated-secret-2027')],
            ),
          );
          final rotated = await storedHash(first.id);

          expect(kept, original);
          expect(rotated, isNot(original));
        },
      );

      test(
        'then the next revision of a live action inherits the secret',
        () async {
          final live = await publishedAction(
            endpoints,
            creator,
            actionRequest(
              actionKey: 'venue',
              requirements: [qrRequirement(qrCode: 'venue-secret-2026')],
            ),
          );

          final next = await endpoints.actionVerification.saveActionDraft(
            creator,
            actionRequest(
              actionKey: 'venue',
              title: 'Visit the venue again',
              requirements: [qrRequirement()],
            ),
          );

          expect(next.revision, live.revision + 1);
          expect(await storedHash(next.id), await storedHash(live.id));
        },
      );

      test('then a new action without a stored secret is refused', () async {
        await expectLater(
          endpoints.actionVerification.saveActionDraft(
            creator,
            actionRequest(actionKey: 'venue', requirements: [qrRequirement()]),
          ),
          refusedAs(ActionAuthoringProblem.invalidRequest),
        );
        await expectLater(
          endpoints.actionVerification.saveActionDraft(
            creator,
            actionRequest(
              actionKey: 'venue',
              requirements: [qrRequirement(qrCode: 'short')],
            ),
          ),
          refusedAs(ActionAuthoringProblem.invalidRequest),
        );
      });
    });

    group('when an App detail page loads', () {
      test(
        'then the owner gets the App and others get a typed not-found',
        () async {
          final created = await endpoints.verilyApp.createApp(
            creator,
            name: 'Step Counter',
          );

          final app = await endpoints.verilyApp.getApp(
            creator,
            appId: created.app.id,
          );

          expect(app.id, created.app.id);
          expect(app.name, 'Step Counter');
          expect(app.keys, hasLength(1));
          expect(jsonEncode(app.toJson()), isNot(contains(created.secret)));
          await expectLater(
            endpoints.verilyApp.getApp(otherCreator, appId: created.app.id),
            _notFound(MissingResource.app),
          );
          await expectLater(
            endpoints.verilyApp.getApp(creator, appId: testId(0x8fd)),
            _notFound(MissingResource.app),
          );
        },
      );
    });
  });
}

/// Answers every pull call with one fixed body.
class _Answering implements WebhookSender {
  _Answering(this.body);

  final String body;

  @override
  Future<WebhookCallResult> post({
    required Uri url,
    required Map<String, String> headers,
    required String body,
    required Duration timeout,
    int maxResponseBytes = 0,
  }) async => WebhookCallResult(
    duration: const Duration(milliseconds: 5),
    statusCode: 200,
    responseBody: this.body,
  );
}
