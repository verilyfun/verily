import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/action_verification_service.dart';
import 'package:verily_server/src/apps/app_confirmation_payload.dart';
import 'package:verily_server/src/apps/app_confirmation_service.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/web/routes/app_confirmations_route.dart';

import 'test_tools/serverpod_test_tools.dart';
import 'test_tools/verily_fixtures.dart';

const _actionKey = 'daily-steps';
const _unlinkedSubject = 'vls_ZZZZZZZZZZZZZZZZZZZZZZ';

/// The live setup most deliveries need: an App, a daily action it confirms,
/// and the participant's subject for that App.
typedef _LiveApp = ({
  VerilyAppCredential credential,
  ActionOpportunity action,
  VerilyAppLinkView link,
});

void main() {
  withServerpod('Given an App that confirms a daily action', (
    sessionBuilder,
    endpoints,
  ) {
    final creatorId = testId(0x201);
    final participantId = testId(0x202);
    final otherCreatorId = testId(0x203);
    late TestSessionBuilder creator;
    late TestSessionBuilder participant;
    late TestSessionBuilder otherCreator;
    late AppConfirmationService service;

    setUp(() async {
      creator = signedIn(sessionBuilder, creatorId);
      participant = signedIn(sessionBuilder, participantId);
      otherCreator = signedIn(sessionBuilder, otherCreatorId);
      service = AppConfirmationService();
      await insertAccounts(sessionBuilder.build(), {
        creatorId: 'Ada',
        participantId: 'Grace',
        otherCreatorId: 'Linus',
      });
    });

    Future<AppDeliveryResponse> deliver({
      required String body,
      String? credential,
      String? authorization,
      String? timestamp,
      DateTime? sentAt,
      AppConfirmationService? using,
    }) {
      final sent = (sentAt ?? DateTime.now()).toUtc();
      return (using ?? service).deliver(
        sessionBuilder.build(),
        authorization: authorization ?? 'Bearer $credential',
        timestamp: timestamp ?? '${sent.millisecondsSinceEpoch ~/ 1000}',
        body: body,
      );
    }

    Future<ActionOpportunity> createExternalAction(
      UuidValue appId, {
      TestSessionBuilder? as,
      String actionKey = _actionKey,
      DateTime? opensAt,
    }) => endpoints.actionVerification.createAction(
      as ?? creator,
      actionRequest(
        actionKey: actionKey,
        recurrence: ActionRecurrence.daily,
        requirements: [externalRequirement(appId: appId)],
      ).copyWith(opensAt: opensAt),
    );

    Future<_LiveApp> liveApp() async {
      final credential = await endpoints.verilyApp.createApp(
        creator,
        name: 'Step Counter',
      );
      final action = await createExternalAction(credential.app.id);
      final link = await endpoints.verilyApp.linkApp(
        participant,
        appId: credential.app.id,
      );
      return (credential: credential, action: action, link: link);
    }

    Future<int> receipts() => AppConfirmation.db.count(sessionBuilder.build());

    Future<int> attempts() => ActionAttempt.db.count(sessionBuilder.build());

    group('when a linked participant is confirmed', () {
      test(
        'then the attempt is verified without any participant call',
        () async {
          final live = await liveApp();
          final occurredAt = DateTime.now().toUtc();
          final body = _event(
            eventId: 'evt-1',
            subject: live.link.subject,
            occurredAt: occurredAt,
          );

          final response = await deliver(
            credential: live.credential.secret,
            body: body,
          );

          expect(response.status, 202);
          expect(response.body, {
            'status': 'accepted',
            'eventId': 'evt-1',
            'attemptStatus': 'verified',
          });
          final session = sessionBuilder.build();
          final attempt = await ActionAttempt.db.findFirstRow(
            session,
            where: (table) => table.participantAuthUserId.equals(participantId),
          );
          expect(attempt!.status, ActionAttemptStatus.verified);
          expect(attempt.verifiedRank, 1);
          expect(attempt.idempotencyKey, 'app:${live.credential.app.id}:evt-1');
          final decision = await EvidenceDecision.db.findFirstRow(session);
          expect(decision!.verifierType, appConfirmationVerifierType);
          expect(decision.status, EvidenceDecisionStatus.accepted);
          final receipt = await AppConfirmation.db.findFirstRow(session);
          expect(receipt!.keyId, live.credential.keyId);
          expect(receipt.outcome, AppConfirmationOutcome.accepted);
          expect(receipt.reasonCode, 'app_confirmed');
          expect(receipt.attemptId, attempt.id);
          expect(receipt.actionDefinitionId, live.action.id);
          expect(
            receipt.payloadDigest,
            appConfirmationDigest(
              eventId: 'evt-1',
              actionKey: _actionKey,
              subject: live.link.subject,
              occurredAt: occurredAt,
            ),
          );
          final key = await VerilyAppKey.db.findFirstRow(
            session,
            where: (table) => table.keyId.equals(live.credential.keyId),
          );
          expect(key!.lastUsedAt, isNotNull);
          final mine = await endpoints.actionVerification.listMyAttempts(
            participant,
            limit: 10,
          );
          expect(mine.single.status, ActionAttemptStatus.verified);
        },
      );

      test('then a retried event replays its first outcome', () async {
        final live = await liveApp();
        final occurredAt = DateTime.now().toUtc().subtract(
          const Duration(minutes: 2),
        );
        await deliver(
          credential: live.credential.secret,
          body: _event(
            eventId: 'evt-1',
            subject: live.link.subject,
            occurredAt: occurredAt,
          ),
        );

        // The same fields, reordered and with an equivalent offset.
        final reformatted = jsonEncode({
          'occurredAt': occurredAt
              .add(const Duration(hours: 1))
              .toIso8601String()
              .replaceFirst('Z', '+01:00'),
          'subject': live.link.subject,
          'action': _actionKey,
          'eventId': 'evt-1',
        });
        final duplicate = await deliver(
          credential: live.credential.secret,
          body: reformatted,
        );

        expect(duplicate.status, 202);
        expect(duplicate.body['status'], 'duplicate');
        expect(duplicate.body['attemptStatus'], 'verified');
        expect(await receipts(), 1);
        expect(await attempts(), 1);

        final sameDay = await deliver(
          credential: live.credential.secret,
          body: _event(
            eventId: 'evt-2',
            subject: live.link.subject,
            occurredAt: occurredAt,
          ),
        );
        expect(sameDay.status, 202);
        expect(sameDay.body['status'], 'accepted');
        final stored = await AppConfirmation.db.find(
          sessionBuilder.build(),
          orderBy: (table) => table.id,
        );
        expect(stored.map((receipt) => receipt.reasonCode), [
          'app_confirmed',
          'attempt_already_complete',
        ]);
        expect(await attempts(), 1);
      });

      test('then a reused event id with different fields conflicts', () async {
        final live = await liveApp();
        final occurredAt = DateTime.now().toUtc().subtract(
          const Duration(minutes: 3),
        );
        await deliver(
          credential: live.credential.secret,
          body: _event(
            eventId: 'evt-1',
            subject: live.link.subject,
            occurredAt: occurredAt,
          ),
        );

        final conflict = await deliver(
          credential: live.credential.secret,
          body: _event(
            eventId: 'evt-1',
            subject: live.link.subject,
            occurredAt: occurredAt.add(const Duration(seconds: 1)),
          ),
        );

        expect(conflict.status, 409);
        expect(conflict.body['error'], 'event_conflict');
        expect(await receipts(), 1);
      });
    });

    group('when a receipt has been recorded', () {
      test('then the database refuses to update it', () async {
        final live = await liveApp();
        await deliver(
          credential: live.credential.secret,
          body: _event(
            eventId: 'evt-1',
            subject: live.link.subject,
            occurredAt: DateTime.now().toUtc(),
          ),
        );
        final session = sessionBuilder.build();
        final receipt = await AppConfirmation.db.findFirstRow(session);

        await expectLater(
          AppConfirmation.db.updateRow(
            session,
            receipt!.copyWith(reasonCode: 'rewritten'),
          ),
          throwsA(_databaseRefusal('append-only')),
        );
      });

      test('then the database refuses to delete it', () async {
        final live = await liveApp();
        await deliver(
          credential: live.credential.secret,
          body: _event(
            eventId: 'evt-1',
            subject: live.link.subject,
            occurredAt: DateTime.now().toUtc(),
          ),
        );
        final session = sessionBuilder.build();
        final receipt = await AppConfirmation.db.findFirstRow(session);

        await expectLater(
          AppConfirmation.db.deleteRow(session, receipt!),
          throwsA(_databaseRefusal('append-only')),
        );
      });
    });

    group('when the credential is not a live App key', () {
      test('then it is refused without recording anything', () async {
        final live = await liveApp();
        final body = _event(
          eventId: 'evt-auth',
          subject: live.link.subject,
          occurredAt: DateTime.now().toUtc(),
        );
        final secret = live.credential.secret;
        final forged =
            '${secret.substring(0, secret.length - 1)}'
            '${secret.endsWith('A') ? 'B' : 'A'}';
        final unknownKey = 'vly_0000000000000000.${secret.split('.').last}';

        final refusals = [
          await deliver(credential: forged, body: body),
          await deliver(credential: unknownKey, body: body),
          await deliver(credential: 'not-a-key', body: body),
          await deliver(authorization: 'Basic $secret', body: body),
          await deliver(authorization: '', body: body),
        ];
        for (final refused in refusals) {
          expect(refused.status, 401);
          // The body names the problem only, never the key, App, or action.
          expect(refused.body, {
            'error': 'invalid_credentials',
            'message': 'Send a valid, active app key as a Bearer token.',
          });
        }

        await endpoints.verilyApp.revokeKey(
          creator,
          appId: live.credential.app.id,
          keyId: live.credential.keyId,
        );
        final revoked = await deliver(credential: secret, body: body);
        expect(revoked.status, 401);
        expect(revoked.body['error'], 'invalid_credentials');
        expect(await receipts(), 0);
        expect(await attempts(), 0);
      });

      test('then a key of a revoked App is refused', () async {
        final live = await liveApp();
        final rotated = await endpoints.verilyApp.createKey(
          creator,
          appId: live.credential.app.id,
        );
        await endpoints.verilyApp.revokeApp(
          creator,
          appId: live.credential.app.id,
        );

        for (final secret in [live.credential.secret, rotated.secret]) {
          final response = await deliver(
            credential: secret,
            body: _event(
              eventId: 'evt-after-revoke',
              subject: live.link.subject,
              occurredAt: DateTime.now().toUtc(),
            ),
          );
          expect(response.status, 401);
          expect(response.body['error'], 'invalid_credentials');
        }
        expect(await receipts(), 0);
      });

      test(
        'then a revoked App is refused even with an unrevoked key',
        () async {
          final live = await liveApp();
          final session = sessionBuilder.build();
          final app = await VerilyApp.db.findById(
            session,
            live.credential.app.id,
          );
          await VerilyApp.db.updateRow(
            session,
            app!.copyWith(
              status: VerilyAppStatus.revoked,
              revokedAt: DateTime.now().toUtc(),
            ),
          );

          final response = await deliver(
            credential: live.credential.secret,
            body: _event(
              eventId: 'evt-revoked-app',
              subject: live.link.subject,
              occurredAt: DateTime.now().toUtc(),
            ),
          );

          expect(response.status, 401);
          expect(await receipts(), 0);
        },
      );
    });

    group('when Verily-Timestamp is not current', () {
      test('then stale, future, and malformed values are refused', () async {
        final live = await liveApp();
        final body = _event(
          eventId: 'evt-skew',
          subject: live.link.subject,
          occurredAt: DateTime.now().toUtc(),
        );
        final now = DateTime.now().toUtc();

        for (final sentAt in [
          now.subtract(const Duration(minutes: 6)),
          now.add(const Duration(minutes: 6)),
        ]) {
          final response = await deliver(
            credential: live.credential.secret,
            body: body,
            sentAt: sentAt,
          );
          expect(response.status, 401);
          expect(response.body['error'], 'invalid_timestamp');
        }
        for (final timestamp in [
          '',
          'yesterday',
          '-1',
          now.toIso8601String(),
        ]) {
          final response = await deliver(
            credential: live.credential.secret,
            body: body,
            timestamp: timestamp,
          );
          expect(response.status, 401);
          expect(response.body['error'], 'invalid_timestamp');
        }
        expect(await receipts(), 0);

        final withinTolerance = await deliver(
          credential: live.credential.secret,
          body: body,
          sentAt: now.subtract(const Duration(minutes: 4)),
        );
        expect(withinTolerance.status, 202);
      });
    });

    group('when the body is malformed', () {
      test('then it is refused with a stable code and no receipt', () async {
        final live = await liveApp();
        final occurredAt = DateTime.now().toUtc().toIso8601String();
        Map<String, Object?> valid() => {
          'eventId': 'evt-bad',
          'action': _actionKey,
          'subject': live.link.subject,
          'occurredAt': occurredAt,
        };
        final cases = <String, String>{
          '{': 'invalid_json',
          '[]': 'invalid_json',
          jsonEncode({...valid(), 'latitude': 51.5}): 'unknown_field',
          jsonEncode(valid()..remove('subject')): 'missing_field',
          jsonEncode({...valid(), 'subject': 'participant-42'}):
              'invalid_field',
          jsonEncode({...valid(), 'eventId': 'has spaces'}): 'invalid_field',
          jsonEncode({...valid(), 'action': 'Daily Steps'}): 'invalid_field',
          jsonEncode({...valid(), 'occurredAt': 1760000000}): 'invalid_field',
          jsonEncode({...valid(), 'occurredAt': '2026-13-01T00:00:00Z'}):
              'invalid_field',
          jsonEncode({...valid(), 'occurredAt': '2026-10-01T00:00:00'}):
              'invalid_field',
        };

        for (final entry in cases.entries) {
          final response = await deliver(
            credential: live.credential.secret,
            body: entry.key,
          );
          expect(response.status, 422, reason: entry.key);
          expect(response.body['error'], entry.value, reason: entry.key);
          expect(response.body.keys, unorderedEquals(['error', 'message']));
        }
        expect(await receipts(), 0);
        expect(await attempts(), 0);
      });

      test(
        'then an oversize body fails strict parsing without a receipt',
        () async {
          final live = await liveApp();
          final oversize = jsonEncode({
            'eventId': 'evt-big',
            'action': _actionKey,
            'subject': live.link.subject,
            'occurredAt': DateTime.now().toUtc().toIso8601String(),
            'padding': 'x' * (appConfirmationMaxBytes + 1),
          });

          final response = await deliver(
            credential: live.credential.secret,
            body: oversize,
          );

          expect(response.status, 422);
          expect(response.body['error'], 'unknown_field');
          expect(await receipts(), 0);
        },
      );
    });

    group('when the subject or action does not resolve', () {
      test('then the rejection is recorded and replayed', () async {
        final live = await liveApp();
        final now = DateTime.now().toUtc();

        final unlinked = await deliver(
          credential: live.credential.secret,
          body: _event(
            eventId: 'evt-unlinked',
            subject: _unlinkedSubject,
            occurredAt: now,
          ),
        );
        expect(unlinked.status, 404);
        expect(unlinked.body['error'], 'unknown_subject');
        expect(unlinked.body['duplicate'], isFalse);

        final unknownAction = await deliver(
          credential: live.credential.secret,
          body: _event(
            eventId: 'evt-unknown-action',
            subject: live.link.subject,
            occurredAt: now,
            action: 'not-a-live-action',
          ),
        );
        expect(unknownAction.status, 404);
        expect(unknownAction.body['error'], 'unknown_action');

        final replayed = await deliver(
          credential: live.credential.secret,
          body: _event(
            eventId: 'evt-unlinked',
            subject: _unlinkedSubject,
            occurredAt: now,
          ),
        );
        expect(replayed.status, 404);
        expect(replayed.body['duplicate'], isTrue);
        final stored = await AppConfirmation.db.find(sessionBuilder.build());
        expect(stored, hasLength(2));
        expect(
          stored.every(
            (receipt) =>
                receipt.outcome == AppConfirmationOutcome.rejected &&
                receipt.attemptId == null,
          ),
          isTrue,
        );
        expect(await attempts(), 0);
      });

      test('then a subject linked to another App is unknown', () async {
        final live = await liveApp();
        final sleep = await endpoints.verilyApp.createApp(
          creator,
          name: 'Sleep Tracker',
        );
        await createExternalAction(sleep.app.id, actionKey: 'sleep-early');
        final sleepLink = await endpoints.verilyApp.linkApp(
          participant,
          appId: sleep.app.id,
        );

        final response = await deliver(
          credential: live.credential.secret,
          body: _event(
            eventId: 'evt-cross-app',
            subject: sleepLink.subject,
            occurredAt: DateTime.now().toUtc(),
          ),
        );

        expect(response.status, 404);
        expect(response.body['error'], 'unknown_subject');
        expect(await attempts(), 0);
      });

      test("then another creator's action cannot be confirmed", () async {
        final live = await liveApp();
        final foreign = await endpoints.verilyApp.createApp(
          otherCreator,
          name: 'Foreign',
        );
        await createExternalAction(
          foreign.app.id,
          as: otherCreator,
          actionKey: 'foreign-steps',
        );
        final response = await deliver(
          credential: live.credential.secret,
          body: _event(
            eventId: 'evt-foreign',
            subject: live.link.subject,
            occurredAt: DateTime.now().toUtc(),
            action: 'foreign-steps',
          ),
        );

        expect(response.status, 404);
        expect(response.body['error'], 'unknown_action');
        expect(await attempts(), 0);
      });

      test('then a paused action is not confirmable', () async {
        final live = await liveApp();
        await endpoints.actionVerification.pauseAction(
          creator,
          actionId: live.action.id,
          expectedRevision: live.action.revision,
        );

        final response = await deliver(
          credential: live.credential.secret,
          body: _event(
            eventId: 'evt-paused',
            subject: live.link.subject,
            occurredAt: DateTime.now().toUtc(),
          ),
        );

        expect(response.status, 404);
        expect(response.body['error'], 'unknown_action');
      });

      test('then a blocked participant is an unknown subject', () async {
        final live = await liveApp();
        final session = sessionBuilder.build();
        final account = await AuthUser.db.findById(session, participantId);
        await AuthUser.db.updateRow(session, account!.copyWith(blocked: true));

        final response = await deliver(
          credential: live.credential.secret,
          body: _event(
            eventId: 'evt-blocked',
            subject: live.link.subject,
            occurredAt: DateTime.now().toUtc(),
          ),
        );

        expect(response.status, 404);
        expect(response.body['error'], 'unknown_subject');
        expect(await attempts(), 0);
      });
    });

    group('when occurredAt is outside what the action accepts', () {
      test('then old, future, and pre-window events are refused', () async {
        final live = await liveApp();
        final now = DateTime.now().toUtc();

        final old = await deliver(
          credential: live.credential.secret,
          body: _event(
            eventId: 'evt-old',
            subject: live.link.subject,
            occurredAt: now.subtract(const Duration(hours: 25)),
          ),
        );
        expect(old.status, 422);
        expect(old.body['error'], 'occurred_at_out_of_range');

        final future = await deliver(
          credential: live.credential.secret,
          body: _event(
            eventId: 'evt-future',
            subject: live.link.subject,
            occurredAt: now.add(const Duration(minutes: 10)),
          ),
        );
        expect(future.status, 422);
        expect(future.body['error'], 'occurred_at_out_of_range');

        final sleep = await endpoints.verilyApp.createApp(
          creator,
          name: 'Windowed',
        );
        await createExternalAction(
          sleep.app.id,
          actionKey: 'windowed-steps',
          opensAt: now.subtract(const Duration(hours: 1)),
        );
        final link = await endpoints.verilyApp.linkApp(
          participant,
          appId: sleep.app.id,
        );
        final early = await deliver(
          credential: sleep.secret,
          body: _event(
            eventId: 'evt-early',
            subject: link.subject,
            occurredAt: now.subtract(const Duration(hours: 2)),
            action: 'windowed-steps',
          ),
        );
        expect(early.status, 422);
        expect(early.body['error'], 'occurred_outside_window');
        expect(await attempts(), 0);
      });

      test('then late deliveries count only shortly after the day', () async {
        final live = await liveApp();
        var now = DateTime.utc(2026, 10, 13, 1, 59);
        final clocked = AppConfirmationService(
          verificationService: ActionVerificationService(clock: () => now),
          clock: () => now,
        );
        Future<AppDeliveryResponse> send(String eventId, DateTime occurredAt) =>
            deliver(
              credential: live.credential.secret,
              using: clocked,
              sentAt: now,
              body: _event(
                eventId: eventId,
                subject: live.link.subject,
                occurredAt: occurredAt,
              ),
            );

        // 23:00 on the 12th, delivered 1h59m after that day ended.
        expect(
          (await send('evt-yesterday', DateTime.utc(2026, 10, 12, 23))).status,
          202,
        );
        final older = await send(
          'evt-two-days',
          DateTime.utc(2026, 10, 11, 23, 59),
        );
        expect(older.status, 422);
        expect(older.body['error'], 'occurred_at_out_of_range');

        now = DateTime.utc(2026, 10, 13, 2, 1);
        final pastGrace = await send(
          'evt-past-grace',
          DateTime.utc(2026, 10, 12, 22),
        );
        expect(pastGrace.status, 422);
        expect(pastGrace.body['error'], 'occurred_outside_period');
        expect(
          (await send('evt-today', DateTime.utc(2026, 10, 13, 0, 10))).status,
          202,
        );

        final stored = await ActionAttempt.db.find(
          sessionBuilder.build(),
          where: (table) => table.participantAuthUserId.equals(participantId),
          orderBy: (table) => table.periodKey,
        );
        expect(stored.map((attempt) => attempt.periodKey), [
          '2026-10-12',
          '2026-10-13',
        ]);
      });

      test('then a fast App clock never earns the next day', () async {
        final live = await liveApp();
        final now = DateTime.utc(2026, 10, 12, 23, 58);
        final clocked = AppConfirmationService(
          verificationService: ActionVerificationService(clock: () => now),
          clock: () => now,
        );

        final response = await deliver(
          credential: live.credential.secret,
          using: clocked,
          sentAt: now,
          body: _event(
            eventId: 'evt-fast-clock',
            subject: live.link.subject,
            occurredAt: DateTime.utc(2026, 10, 13, 0, 2),
          ),
        );

        expect(response.status, 202);
        final attempt = await ActionAttempt.db.findFirstRow(
          sessionBuilder.build(),
          where: (table) => table.participantAuthUserId.equals(participantId),
        );
        expect(attempt!.periodKey, '2026-10-12');
      });
    });

    group('when an App sends too many deliveries', () {
      test('then it is rate limited until the next window', () async {
        final live = await liveApp();
        var now = DateTime.now().toUtc();
        final limited = AppConfirmationService(rateLimit: 2, clock: () => now);
        Future<AppDeliveryResponse> send(String body) => deliver(
          credential: live.credential.secret,
          using: limited,
          sentAt: now,
          body: body,
        );
        String event(String eventId) => _event(
          eventId: eventId,
          subject: live.link.subject,
          occurredAt: now,
        );

        expect((await send(event('evt-a'))).status, 202);
        // Invalid bodies still spend the allowance.
        expect((await send('{')).status, 422);
        final blocked = await send(event('evt-c'));
        expect(blocked.status, 429);
        expect(blocked.body['error'], 'rate_limited');
        expect(blocked.retryAfter, isNotNull);
        expect(blocked.retryAfter! > Duration.zero, isTrue);
        expect(await receipts(), 1);

        // A wrong key never touches the App's allowance.
        final forged = await deliver(
          credential: 'not-a-key',
          using: limited,
          sentAt: now,
          body: event('evt-forged'),
        );
        expect(forged.status, 401);

        now = now.add(const Duration(minutes: 1));
        expect((await send(event('evt-c'))).status, 202);
        expect(await receipts(), 2);
      });
    });

    group('when rows bypass the authoring service', () {
      test('then the database refuses phone proof beside an App', () async {
        final live = await liveApp();

        await expectLater(
          ActionRequirement.db.insertRow(
            sessionBuilder.build(),
            ActionRequirement(
              actionDefinitionId: live.action.id,
              requirementKey: 'gym-check-in',
              kind: ActionRequirementKind.location,
              title: 'Gym check-in',
              instructions: 'Share your location from the gym.',
              position: 1,
            ),
          ),
          throwsA(_databaseRefusal('cannot be combined with phone proof')),
        );
      });

      test('then the database refuses an App beside phone proof', () async {
        final phone = await endpoints.actionVerification.createAction(
          creator,
          actionRequest(
            actionKey: 'visit-the-park',
            requirements: [locationRequirement()],
          ),
        );

        await expectLater(
          ActionRequirement.db.insertRow(
            sessionBuilder.build(),
            ActionRequirement(
              actionDefinitionId: phone.id,
              requirementKey: 'app-confirmed',
              kind: ActionRequirementKind.externalApp,
              title: 'Finish in the app',
              instructions: 'Complete the challenge in the partner app.',
              position: 1,
            ),
          ),
          throwsA(_databaseRefusal('cannot be combined with phone proof')),
        );
      });

      test(
        "then the database refuses binding another creator's requirement",
        () async {
          final live = await liveApp();
          final foreign = await endpoints.verilyApp.createApp(
            otherCreator,
            name: 'Foreign',
          );
          final foreignAction = await createExternalAction(
            foreign.app.id,
            as: otherCreator,
            actionKey: 'foreign-steps',
          );
          final session = sessionBuilder.build();
          final foreignRule = await ActionExternalRule.db.findFirstRow(
            session,
            where: (table) => table.requirementId.equals(
              foreignAction.requirements.single.id,
            ),
          );
          expect(foreignRule!.appId, foreign.app.id);

          await expectLater(
            ActionExternalRule.db.updateRow(
              session,
              foreignRule.copyWith(appId: live.credential.app.id),
            ),
            throwsA(_databaseRefusal('external rule must bind')),
          );
        },
      );
    });

    group('when the route receives HTTP requests', () {
      late RelicServer server;
      late Uri url;

      setUp(() async {
        final route = AppConfirmationsRoute();
        server = RelicServer(
          () => IOAdapter.bind(InternetAddress.loopbackIPv4),
        );
        await server.mountAndStart(
          (request) => route.handleCall(sessionBuilder.build(), request),
        );
        url = Uri.parse('http://127.0.0.1:${server.port}/api/v1/confirmations');
      });

      tearDown(() => server.close(force: true));

      Future<http.Response> post(
        String body, {
        required String credential,
        DateTime? sentAt,
      }) {
        final sent = (sentAt ?? DateTime.now()).toUtc();
        return http.post(
          url,
          headers: {
            'Authorization': 'Bearer $credential',
            'Verily-Timestamp': '${sent.millisecondsSinceEpoch ~/ 1000}',
            'Content-Type': 'application/json',
          },
          body: body,
        );
      }

      test('then a confirmation is accepted as uncached JSON', () async {
        final live = await liveApp();

        final response = await post(
          _event(
            eventId: 'evt-http',
            subject: live.link.subject,
            occurredAt: DateTime.now().toUtc(),
          ),
          credential: live.credential.secret,
        );

        expect(response.statusCode, 202);
        expect(response.headers['content-type'], contains('application/json'));
        expect(response.headers['cache-control'], contains('no-store'));
        expect(_json(response), {
          'status': 'accepted',
          'eventId': 'evt-http',
          'attemptStatus': 'verified',
        });
      });

      test('then headers and oversize bodies are enforced', () async {
        final live = await liveApp();
        final event = _event(
          eventId: 'evt-http',
          subject: live.link.subject,
          occurredAt: DateTime.now().toUtc(),
        );

        final unsigned = await http.post(url, body: event);
        expect(unsigned.statusCode, 401);
        expect(_json(unsigned), {
          'error': 'invalid_credentials',
          'message': 'Send a valid, active app key as a Bearer token.',
        });

        final stale = await post(
          event,
          credential: live.credential.secret,
          sentAt: DateTime.now().toUtc().subtract(const Duration(minutes: 10)),
        );
        expect(stale.statusCode, 401);
        expect(_json(stale)['error'], 'invalid_timestamp');

        final oversize = await post(
          'x' * (appConfirmationMaxBytes + 1),
          credential: live.credential.secret,
        );
        expect(oversize.statusCode, 413);
        expect(_json(oversize)['error'], 'payload_too_large');
        expect(await receipts(), 0);
      });
    });
  });

  withServerpod(
    'Given a delivery holding the App lock',
    (sessionBuilder, endpoints) {
      final creatorId = testId(0x211);
      final participantId = testId(0x212);

      setUpAll(() async {
        await insertAccounts(sessionBuilder.build(), {
          creatorId: 'Ada',
          participantId: 'Grace',
        });
      });

      test(
        'when a wrong secret arrives then it is refused without waiting',
        () async {
          final creator = signedIn(sessionBuilder, creatorId);
          final credential = await endpoints.verilyApp.createApp(
            creator,
            name: 'Step Counter',
          );
          await endpoints.actionVerification.createAction(
            creator,
            actionRequest(
              actionKey: _actionKey,
              recurrence: ActionRecurrence.daily,
              requirements: [externalRequirement(appId: credential.app.id)],
            ),
          );
          final link = await endpoints.verilyApp.linkApp(
            signedIn(sessionBuilder, participantId),
            appId: credential.app.id,
          );
          final service = AppConfirmationService();
          Future<AppDeliveryResponse> send(String secret) async {
            final session = sessionBuilder.build();
            final now = DateTime.now().toUtc();
            try {
              return await service.deliver(
                session,
                authorization: 'Bearer $secret',
                timestamp: '${now.millisecondsSinceEpoch ~/ 1000}',
                body: _event(
                  eventId: 'evt-contention',
                  subject: link.subject,
                  occurredAt: now,
                ),
              );
            } finally {
              await session.close();
            }
          }

          // Hold the App row lock, as a slow delivery would.
          final holder = sessionBuilder.build();
          final locked = Completer<void>();
          final release = Completer<void>();
          final holding = holder.db.transaction((transaction) async {
            await VerilyApp.db.findFirstRow(
              holder,
              where: (table) => table.id.equals(credential.app.id),
              transaction: transaction,
              lockMode: LockMode.forUpdate,
            );
            locked.complete();
            await release.future;
          });
          await locked.future;

          final secret = credential.secret;
          final forged =
              '${secret.substring(0, secret.length - 1)}'
              '${secret.endsWith('A') ? 'B' : 'A'}';
          final refused = await send(
            forged,
          ).timeout(const Duration(seconds: 5));
          expect(refused.status, 401);

          // A genuine delivery waits for the lock, then succeeds.
          var genuineFinished = false;
          final genuine = send(secret).then((response) {
            genuineFinished = true;
            return response;
          });
          await Future<void>.delayed(const Duration(milliseconds: 300));
          expect(genuineFinished, isFalse);
          release.complete();
          await holding;
          await holder.close();
          expect((await genuine).status, 202);

          final check = sessionBuilder.build();
          final stored = await AppConfirmation.db.find(
            check,
            where: (table) => table.appId.equals(credential.app.id),
          );
          await check.close();
          expect(stored, hasLength(1));
        },
      );
    },
    rollbackDatabase: RollbackDatabase.disabled,
  );
}

String _event({
  required String eventId,
  required String subject,
  required DateTime occurredAt,
  String action = _actionKey,
}) {
  return jsonEncode({
    'eventId': eventId,
    'action': action,
    'subject': subject,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
  });
}

Map<String, Object?> _json(http.Response response) =>
    jsonDecode(response.body) as Map<String, Object?>;

/// A database error raised by one of the reviewed schema contracts.
Matcher _databaseRefusal(String reason) => isA<DatabaseException>().having(
  (error) => error.message,
  'message',
  contains(reason),
);
