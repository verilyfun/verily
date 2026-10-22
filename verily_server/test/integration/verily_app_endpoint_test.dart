import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/apps/app_confirmation_service.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/security/secret_digest.dart';

import 'test_tools/serverpod_test_tools.dart';
import 'test_tools/verily_fixtures.dart';

const _actionKey = 'daily-steps';

void main() {
  withServerpod('Given a creator who registers Verily Apps', (
    sessionBuilder,
    endpoints,
  ) {
    final creatorId = testId(0x101);
    final participantId = testId(0x102);
    final otherCreatorId = testId(0x103);
    late TestSessionBuilder creator;
    late TestSessionBuilder participant;
    late TestSessionBuilder otherCreator;

    setUp(() async {
      creator = signedIn(sessionBuilder, creatorId);
      participant = signedIn(sessionBuilder, participantId);
      otherCreator = signedIn(sessionBuilder, otherCreatorId);
      await insertAccounts(sessionBuilder.build(), {
        creatorId: 'Ada',
        participantId: 'Grace',
        otherCreatorId: 'Linus',
      });
    });

    Future<VerilyAppCredential> createApp([String name = 'Step Counter']) =>
        endpoints.verilyApp.createApp(creator, name: name);

    Future<ActionOpportunity> createExternalAction(
      UuidValue appId, {
      TestSessionBuilder? as,
      String actionKey = _actionKey,
    }) => endpoints.actionVerification.createAction(
      as ?? creator,
      actionRequest(
        actionKey: actionKey,
        recurrence: ActionRecurrence.daily,
        requirements: [externalRequirement(appId: appId)],
      ),
    );

    group('when signed out', () {
      test('then every App method refuses the call', () async {
        await expectLater(
          endpoints.verilyApp.listApps(sessionBuilder),
          throwsA(isA<ServerpodUnauthenticatedException>()),
        );
        await expectLater(
          endpoints.verilyApp.createApp(sessionBuilder, name: 'Anonymous'),
          throwsA(isA<ServerpodUnauthenticatedException>()),
        );
      });
    });

    group('when the creator creates an App', () {
      test('then the key is shown once and only its hash is stored', () async {
        final created = await endpoints.verilyApp.createApp(
          creator,
          name: '  Step   Counter ',
          websiteUrl: 'https://steps.example.org',
        );

        expect(created.app.name, 'Step Counter');
        expect(created.app.status, VerilyAppStatus.active);
        expect(created.app.websiteUrl, 'https://steps.example.org');
        expect(created.keyId, matches(RegExp(r'^[0-9a-f]{16}$')));
        expect(
          created.secret,
          matches(
            RegExp(
              '^vly_${created.keyId}'
              r'\.[A-Za-z0-9_-]{43}$',
            ),
          ),
        );
        expect(created.app.keys.single.keyId, created.keyId);

        final listed = await endpoints.verilyApp.listApps(creator);
        expect(listed.single.id, created.app.id);
        expect(jsonEncode(listed), isNot(contains(created.secret)));

        final stored = await VerilyAppKey.db.findFirstRow(
          sessionBuilder.build(),
          where: (table) => table.keyId.equals(created.keyId),
        );
        expect(stored!.secretHash, matches(RegExp(r'^[0-9a-f]{64}$')));
        expect(stored.secretHash, secretSha256Hex(created.secret));
        expect(stored.secretHash, isNot(contains(created.secret)));
        expect(jsonEncode(listed), isNot(contains(stored.secretHash)));
      });

      test('then names are unique per creator and validated', () async {
        await createApp();

        await expectLater(
          createApp('step counter'),
          throwsA(isA<StateError>()),
        );
        await expectLater(createApp('   '), throwsA(isA<ArgumentError>()));
        await expectLater(createApp('x' * 81), throwsA(isA<ArgumentError>()));
        await expectLater(
          endpoints.verilyApp.createApp(
            creator,
            name: 'Insecure',
            websiteUrl: 'http://steps.example.org',
          ),
          throwsA(isA<ArgumentError>()),
        );
        // Another creator may reuse the name: Apps belong to one creator.
        final foreign = await endpoints.verilyApp.createApp(
          otherCreator,
          name: 'Step Counter',
        );
        expect(foreign.app.status, VerilyAppStatus.active);
      });
    });

    group('when another account targets the App', () {
      test('then it can neither read nor change it', () async {
        final created = await createApp();
        final appId = created.app.id;

        expect(await endpoints.verilyApp.listApps(otherCreator), isEmpty);
        await expectLater(
          endpoints.verilyApp.createKey(otherCreator, appId: appId),
          throwsA(isA<StateError>()),
        );
        await expectLater(
          endpoints.verilyApp.revokeKey(
            otherCreator,
            appId: appId,
            keyId: created.keyId,
          ),
          throwsA(isA<StateError>()),
        );
        await expectLater(
          endpoints.verilyApp.revokeApp(otherCreator, appId: appId),
          throwsA(isA<StateError>()),
        );
        await expectLater(
          endpoints.verilyApp.listConfirmations(
            otherCreator,
            appId: appId,
            limit: 25,
          ),
          throwsA(isA<StateError>()),
        );

        final unchanged = await endpoints.verilyApp.listApps(creator);
        expect(unchanged.single.status, VerilyAppStatus.active);
        expect(unchanged.single.keys.single.revokedAt, isNull);
      });
    });

    group('when the creator rotates keys', () {
      test('then at most two keys are active at once', () async {
        final created = await createApp();
        final appId = created.app.id;
        final rotated = await endpoints.verilyApp.createKey(
          creator,
          appId: appId,
        );

        expect(rotated.keyId, isNot(created.keyId));
        expect(rotated.secret, startsWith('vly_${rotated.keyId}.'));
        expect(rotated.app.keys, hasLength(2));
        await expectLater(
          endpoints.verilyApp.createKey(creator, appId: appId),
          throwsA(isA<StateError>()),
        );

        final revoked = await endpoints.verilyApp.revokeKey(
          creator,
          appId: appId,
          keyId: created.keyId,
        );
        final revokedKey = revoked.keys.singleWhere(
          (key) => key.keyId == created.keyId,
        );
        expect(revokedKey.revokedAt, isNotNull);
        // Revoking again keeps the first revocation time.
        final again = await endpoints.verilyApp.revokeKey(
          creator,
          appId: appId,
          keyId: created.keyId,
        );
        expect(
          again.keys.singleWhere((key) => key.keyId == created.keyId).revokedAt,
          revokedKey.revokedAt,
        );

        final third = await endpoints.verilyApp.createKey(
          creator,
          appId: appId,
        );
        expect(third.app.keys, hasLength(3));
        expect(
          third.app.keys.where((key) => key.revokedAt == null),
          hasLength(2),
        );
        await expectLater(
          endpoints.verilyApp.revokeKey(
            creator,
            appId: appId,
            keyId: '0000000000000000',
          ),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('when an action binds an App-confirmed requirement', () {
      test('then participants see which App confirms it', () async {
        final created = await createApp();
        final action = await createExternalAction(created.app.id);
        final requirement = action.requirements.single;

        expect(action.status, ActionDefinitionStatus.active);
        expect(requirement.kind, ActionRequirementKind.externalApp);
        expect(requirement.appId, created.app.id);
        expect(requirement.appName, 'Step Counter');
        expect(requirement.appAvailable, isTrue);
        final feed = await endpoints.actionVerification.listAvailableActions(
          participant,
          limit: 50,
        );
        expect(feed.single.requirements.single.appName, 'Step Counter');
        expect(feed.single.creatorDisplayName, 'Ada');
        final listed = await endpoints.verilyApp.listApps(creator);
        expect(listed.single.boundActionCount, 1);
      });

      test("then another creator's App or a revoked App is refused", () async {
        final foreign = await endpoints.verilyApp.createApp(
          otherCreator,
          name: 'Foreign',
        );
        await expectLater(
          createExternalAction(foreign.app.id),
          refusedAs(ActionAuthoringProblem.appUnavailable),
        );

        final retired = await createApp('Retired');
        await endpoints.verilyApp.revokeApp(creator, appId: retired.app.id);
        await expectLater(
          endpoints.actionVerification.saveActionDraft(
            creator,
            actionRequest(
              actionKey: _actionKey,
              requirements: [externalRequirement(appId: retired.app.id)],
            ),
          ),
          refusedAs(ActionAuthoringProblem.appUnavailable),
        );
      });

      test('then App confirmation cannot be mixed with phone proof', () async {
        final created = await createApp();

        await expectLater(
          endpoints.actionVerification.saveActionDraft(
            creator,
            actionRequest(
              actionKey: _actionKey,
              requirements: [
                externalRequirement(appId: created.app.id),
                locationRequirement(),
              ],
            ),
          ),
          refusedAs(ActionAuthoringProblem.externalProofMixed),
        );
      });

      test('then the App is required and may confirm one proof only', () async {
        final created = await createApp();
        final bound = externalRequirement(appId: created.app.id);

        await expectLater(
          endpoints.actionVerification.saveActionDraft(
            creator,
            actionRequest(
              actionKey: _actionKey,
              requirements: [
                ActionRequirementDraft(
                  requirementKey: bound.requirementKey,
                  kind: ActionRequirementKind.externalApp,
                  title: bound.title,
                  instructions: bound.instructions,
                  isRequired: true,
                ),
              ],
            ),
          ),
          refusedAs(ActionAuthoringProblem.invalidRequest),
        );
        await expectLater(
          endpoints.actionVerification.saveActionDraft(
            creator,
            actionRequest(
              actionKey: _actionKey,
              requirements: [
                bound,
                bound.copyWith(requirementKey: 'second-confirmation'),
              ],
            ),
          ),
          refusedAs(ActionAuthoringProblem.invalidRequest),
        );
        await expectLater(
          endpoints.actionVerification.saveActionDraft(
            creator,
            actionRequest(
              actionKey: _actionKey,
              requirements: [
                locationRequirement().copyWith(appId: created.app.id),
              ],
            ),
          ),
          refusedAs(ActionAuthoringProblem.invalidRequest),
        );
      });

      test('then a draft whose App was revoked cannot publish', () async {
        final created = await createApp();
        final draft = await endpoints.actionVerification.saveActionDraft(
          creator,
          actionRequest(
            actionKey: _actionKey,
            requirements: [externalRequirement(appId: created.app.id)],
          ),
        );
        await endpoints.verilyApp.revokeApp(creator, appId: created.app.id);

        await expectLater(
          endpoints.actionVerification.publishAction(
            creator,
            actionId: draft.id,
            expectedRevision: draft.revision,
          ),
          refusedAs(ActionAuthoringProblem.appUnavailable),
        );
      });

      test('then participants cannot submit that proof themselves', () async {
        final created = await createApp();
        final action = await createExternalAction(created.app.id);
        final attempt = await endpoints.actionVerification.beginAttempt(
          participant,
          actionId: action.id,
          idempotencyKey: 'self-confirm',
        );

        await expectLater(
          endpoints.actionVerification.submitEvidence(
            participant,
            ActionEvidenceInput(
              attemptId: attempt.id,
              requirementId: action.requirements.single.id,
              capturedAt: DateTime.now().toUtc(),
            ),
          ),
          throwsA(isA<StateError>()),
        );
        expect(
          await ActionEvidence.db.count(sessionBuilder.build()),
          0,
        );
      });
    });

    group('when the creator revokes the App', () {
      test('then every key is revoked and its live actions pause', () async {
        final created = await createApp();
        await endpoints.verilyApp.createKey(creator, appId: created.app.id);
        final action = await createExternalAction(created.app.id);
        final unrelated = await endpoints.actionVerification.createAction(
          creator,
          actionRequest(
            actionKey: 'visit-the-park',
            requirements: [locationRequirement()],
          ),
        );

        final revoked = await endpoints.verilyApp.revokeApp(
          creator,
          appId: created.app.id,
        );

        expect(revoked.status, VerilyAppStatus.revoked);
        expect(revoked.revokedAt, isNotNull);
        expect(revoked.keys, hasLength(2));
        expect(revoked.keys.every((key) => key.revokedAt != null), isTrue);
        final preview = await endpoints.actionVerification.previewAction(
          creator,
          actionId: action.id,
        );
        expect(preview.status, ActionDefinitionStatus.paused);
        expect(preview.requirements.single.appAvailable, isFalse);
        final untouched = await endpoints.actionVerification.previewAction(
          creator,
          actionId: unrelated.id,
        );
        expect(untouched.status, ActionDefinitionStatus.active);
        await expectLater(
          endpoints.actionVerification.beginAttempt(
            participant,
            actionId: action.id,
            idempotencyKey: 'after-revocation',
          ),
          throwsA(isA<StateError>()),
        );
        await expectLater(
          endpoints.verilyApp.createKey(creator, appId: created.app.id),
          throwsA(isA<StateError>()),
        );
        await expectLater(
          endpoints.verilyApp.linkApp(participant, appId: created.app.id),
          throwsA(
            isA<AppUnavailableException>().having(
              (error) => error.appName,
              'appName',
              'Step Counter',
            ),
          ),
        );
        // Revoking twice is a no-op that keeps the first revocation.
        final again = await endpoints.verilyApp.revokeApp(
          creator,
          appId: created.app.id,
        );
        expect(again.revokedAt, revoked.revokedAt);
      });

      test(
        'then an action still marked live refuses new attempts by App name',
        () async {
          final created = await createApp();
          final action = await createExternalAction(created.app.id);
          // A revocation that raced the pause: the App row is revoked while
          // the action is still active. The availability check still holds.
          final session = sessionBuilder.build();
          final app = await VerilyApp.db.findById(session, created.app.id);
          final now = DateTime.now().toUtc();
          await VerilyApp.db.updateRow(
            session,
            app!.copyWith(status: VerilyAppStatus.revoked, revokedAt: now),
          );

          await expectLater(
            endpoints.actionVerification.beginAttempt(
              participant,
              actionId: action.id,
              idempotencyKey: 'raced-revocation',
            ),
            throwsA(
              isA<AppUnavailableException>().having(
                (error) => error.appName,
                'appName',
                'Step Counter',
              ),
            ),
          );
          expect(await ActionAttempt.db.count(session), 0);
        },
      );
    });

    group('when a participant links an App', () {
      test('then they get one stable, App-scoped subject', () async {
        final steps = await createApp();
        final sleep = await createApp('Sleep Tracker');
        await createExternalAction(steps.app.id);
        await createExternalAction(sleep.app.id, actionKey: 'sleep-early');

        final link = await endpoints.verilyApp.linkApp(
          participant,
          appId: steps.app.id,
        );
        final again = await endpoints.verilyApp.linkApp(
          participant,
          appId: steps.app.id,
        );
        final otherApp = await endpoints.verilyApp.linkApp(
          participant,
          appId: sleep.app.id,
        );
        final otherAccount = await endpoints.verilyApp.linkApp(
          otherCreator,
          appId: steps.app.id,
        );

        expect(link.subject, matches(RegExp(r'^vls_[A-Za-z0-9_-]{22}$')));
        expect(link.appName, 'Step Counter');
        expect(again.subject, link.subject);
        expect(otherApp.subject, isNot(link.subject));
        expect(otherAccount.subject, isNot(link.subject));
        expect(await VerilyAppLink.db.count(sessionBuilder.build()), 3);
      });

      test('then an App without a live action cannot be linked', () async {
        final created = await createApp();

        await expectLater(
          endpoints.verilyApp.linkApp(participant, appId: created.app.id),
          throwsA(isA<StateError>()),
        );
        await expectLater(
          endpoints.verilyApp.linkApp(participant, appId: testId(0xdead)),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('when the App has delivered confirmations', () {
      test('then only its creator can page through the receipts', () async {
        final created = await createApp();
        await createExternalAction(created.app.id);
        final link = await endpoints.verilyApp.linkApp(
          participant,
          appId: created.app.id,
        );
        final service = AppConfirmationService();
        Future<AppDeliveryResponse> send(String eventId, String subject) {
          final now = DateTime.now().toUtc();
          return service.deliver(
            sessionBuilder.build(),
            authorization: 'Bearer ${created.secret}',
            timestamp: '${now.millisecondsSinceEpoch ~/ 1000}',
            body: jsonEncode({
              'eventId': eventId,
              'action': _actionKey,
              'subject': subject,
              'occurredAt': now.toIso8601String(),
            }),
          );
        }

        expect((await send('evt-1', link.subject)).status, 202);
        expect(
          (await send('evt-2', 'vls_ZZZZZZZZZZZZZZZZZZZZZZ')).status,
          404,
        );

        final newest = await endpoints.verilyApp.listConfirmations(
          creator,
          appId: created.app.id,
          limit: 1,
        );
        expect(newest.single.eventId, 'evt-2');
        expect(newest.single.outcome, AppConfirmationOutcome.rejected);
        expect(newest.single.reasonCode, 'unknown_subject');
        expect(newest.single.attemptStatus, isNull);
        final older = await endpoints.verilyApp.listConfirmations(
          creator,
          appId: created.app.id,
          limit: 1,
          beforeId: newest.single.id,
        );
        expect(older.single.eventId, 'evt-1');
        expect(older.single.outcome, AppConfirmationOutcome.accepted);
        expect(older.single.attemptStatus, ActionAttemptStatus.verified);
        expect(jsonEncode([...newest, ...older]), isNot(contains('vls_')));
        await expectLater(
          endpoints.verilyApp.listConfirmations(
            participant,
            appId: created.app.id,
            limit: 25,
          ),
          throwsA(isA<StateError>()),
        );
      });
    });
  });
}
