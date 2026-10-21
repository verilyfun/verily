import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/apps/app_confirmation_service.dart';
import 'package:verily_server/src/apps/platform_keys.dart';
import 'package:verily_server/src/apps/webhooks/app_attempt_events.dart';
import 'package:verily_server/src/apps/webhooks/app_event_delivery_service.dart';
import 'package:verily_server/src/apps/webhooks/webhook_sender.dart';
import 'package:verily_server/src/apps/webhooks/webhook_signing.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/rewards/reward_configuration.dart';
import 'package:verily_server/src/rewards/reward_payout_service.dart';

import 'test_tools/fake_reward_escrow_gateway.dart';
import 'test_tools/serverpod_test_tools.dart';
import 'test_tools/verily_fixtures.dart';

const _actionKey = 'daily-steps';

/// A public IP literal, so saving it needs no DNS lookup.
const _webhookUrl = 'https://93.184.216.34/verily/events';
final List<int> _masterBytes = utf8.encode(
  'public-test-only-webhook-master-key-for-apps',
);

typedef _Call = ({Uri url, Map<String, String> headers, String body});

/// Answers every call with [result] and records what was sent.
class _RecordingSender implements WebhookSender {
  _RecordingSender([
    this.result = const WebhookCallResult(
      duration: Duration(milliseconds: 4),
      statusCode: 204,
    ),
  ]);

  WebhookCallResult result;
  final calls = <_Call>[];

  @override
  Future<WebhookCallResult> post({
    required Uri url,
    required Map<String, String> headers,
    required String body,
    required Duration timeout,
    int maxResponseBytes = 0,
  }) async {
    expect(timeout, appEventDeliveryTimeout);
    expect(maxResponseBytes, 0, reason: 'event bodies are never read');
    calls.add((url: url, headers: headers, body: body));
    return result;
  }
}

/// Recomputes the `v1` signatures an App would check.
bool _signatureVerifies(_Call call, String secret) {
  final header = call.headers['verily-signature']!;
  final parts = header.split(',');
  final timestamp = parts.first.substring(2);
  final expected = Hmac(
    sha256,
    utf8.encode(secret),
  ).convert(utf8.encode('$timestamp.${call.body}')).toString();
  return parts.skip(1).contains('v1=$expected');
}

void main() {
  withServerpod('Given a creator configuring an App for webhooks', (
    sessionBuilder,
    endpoints,
  ) {
    final creatorId = testId(0x701);
    final otherCreatorId = testId(0x702);
    late TestSessionBuilder creator;
    late TestSessionBuilder otherCreator;
    late VerilyAppCredential credential;

    setUp(() async {
      PlatformKeys.current = PlatformKeys.fromSecrets(
        webhookSigningMasterKey: base64.encode(_masterBytes),
      );
      creator = signedIn(sessionBuilder, creatorId);
      otherCreator = signedIn(sessionBuilder, otherCreatorId);
      await insertAccounts(sessionBuilder.build(), {
        creatorId: 'Ada',
        otherCreatorId: 'Linus',
      });
      credential = await endpoints.verilyApp.createApp(
        creator,
        name: 'Step Counter',
      );
    });

    tearDown(() => PlatformKeys.current = const PlatformKeys());

    test('when a public https URL is set then the App shows it', () async {
      final view = await endpoints.verilyApp.setWebhookUrl(
        creator,
        appId: credential.app.id,
        webhookUrl: _webhookUrl,
      );
      final cleared = await endpoints.verilyApp.setWebhookUrl(
        creator,
        appId: credential.app.id,
      );

      expect(view.webhookUrl, _webhookUrl);
      expect(cleared.webhookUrl, isNull);
    });

    test(
      'when the URL points into a private network then it is refused',
      () async {
        for (final url in [
          'https://127.0.0.1/hook',
          'https://169.254.169.254/latest/meta-data',
          'https://[::1]/hook',
          'https://localhost/hook',
          'http://93.184.216.34/hook',
          'https://93.184.216.34:8443/hook',
        ]) {
          await expectLater(
            endpoints.verilyApp.setWebhookUrl(
              creator,
              appId: credential.app.id,
              webhookUrl: url,
            ),
            throwsA(
              isA<AppPlatformException>().having(
                (error) => error.problem,
                'problem',
                AppPlatformProblem.invalidWebhookUrl,
              ),
            ),
            reason: url,
          );
        }
        final app = await VerilyApp.db.findById(
          sessionBuilder.build(),
          credential.app.id,
        );
        expect(app!.webhookUrl, isNull);
      },
    );

    test(
      'when another creator configures the App then it is not found',
      () async {
        await expectLater(
          endpoints.verilyApp.setWebhookUrl(
            otherCreator,
            appId: credential.app.id,
            webhookUrl: _webhookUrl,
          ),
          throwsStateError,
        );
        await expectLater(
          endpoints.verilyApp.rotateWebhookSecret(
            otherCreator,
            appId: credential.app.id,
          ),
          throwsStateError,
        );
        await expectLater(
          endpoints.verilyApp.listWebhookDeliveries(
            otherCreator,
            appId: credential.app.id,
            limit: 25,
          ),
          throwsStateError,
        );
      },
    );

    test(
      'when the secret is rotated then it is shown once and overlaps',
      () async {
        final first = await endpoints.verilyApp.rotateWebhookSecret(
          creator,
          appId: credential.app.id,
        );
        final second = await endpoints.verilyApp.rotateWebhookSecret(
          creator,
          appId: credential.app.id,
        );
        final derived = WebhookSecrets(_masterBytes);
        final listed = await endpoints.verilyApp.listApps(creator);

        expect(first.version, 1);
        expect(first.previousSecretValidUntil, isNull);
        expect(
          first.secret,
          derived.secretFor(appId: credential.app.id, version: 1),
        );
        expect(second.version, 2);
        expect(second.secret, isNot(first.secret));
        expect(
          second.previousSecretValidUntil!
              .difference(DateTime.now().toUtc())
              .inSeconds,
          closeTo(const Duration(hours: 24).inSeconds, 60),
        );
        expect(listed.single.webhookSecretVersion, 2);
        expect(jsonEncode(listed.single.toJson()), isNot(contains('whsec_')));
        final row = await VerilyApp.db.findById(
          sessionBuilder.build(),
          credential.app.id,
        );
        expect(jsonEncode(row!.toJson()), isNot(contains('whsec_')));
        expect(row.previousWebhookSecretVersion, 1);
      },
    );

    test(
      'when the server has no master key then rotation is unavailable',
      () async {
        PlatformKeys.current = const PlatformKeys();

        await expectLater(
          endpoints.verilyApp.rotateWebhookSecret(
            creator,
            appId: credential.app.id,
          ),
          throwsA(
            isA<AppPlatformException>().having(
              (error) => error.problem,
              'problem',
              AppPlatformProblem.webhooksUnavailable,
            ),
          ),
        );
      },
    );

    test(
      'when redirect URIs are set then the list is replaced exactly',
      () async {
        await endpoints.verilyApp.setRedirectUris(
          creator,
          appId: credential.app.id,
          redirectUris: ['https://steps.example/old'],
        );
        final view = await endpoints.verilyApp.setRedirectUris(
          creator,
          appId: credential.app.id,
          redirectUris: [
            'com.example.steps://verily',
            'https://steps.example/verily/callback',
          ],
        );

        expect(view.redirectUris, [
          'com.example.steps://verily',
          'https://steps.example/verily/callback',
        ]);
        await expectLater(
          endpoints.verilyApp.setRedirectUris(
            creator,
            appId: credential.app.id,
            redirectUris: ['https://*.steps.example/cb'],
          ),
          throwsA(isA<AppPlatformException>()),
        );
        expect(
          (await endpoints.verilyApp.listApps(creator)).single.redirectUris,
          hasLength(2),
        );
      },
    );

    test('when the App is revoked then its configuration is frozen', () async {
      await endpoints.verilyApp.revokeApp(creator, appId: credential.app.id);

      await expectLater(
        endpoints.verilyApp.setWebhookUrl(
          creator,
          appId: credential.app.id,
          webhookUrl: _webhookUrl,
        ),
        throwsA(isA<AppUnavailableException>()),
      );
      await expectLater(
        endpoints.verilyApp.rotateWebhookSecret(
          creator,
          appId: credential.app.id,
        ),
        throwsA(isA<AppUnavailableException>()),
      );
    });
  });

  withServerpod('Given an App that receives signed events', (
    sessionBuilder,
    endpoints,
  ) {
    final creatorId = testId(0x711);
    final participantId = testId(0x712);
    final otherCreatorId = testId(0x713);
    late TestSessionBuilder creator;
    late TestSessionBuilder participant;
    late VerilyAppCredential credential;
    late VerilyAppLinkView link;
    late ActionOpportunity action;
    late String secret;

    final bodies = <String, String>{};

    /// Delivers event [eventId]; a repeat resends the identical body.
    Future<AppDeliveryResponse> confirm(String eventId) {
      final now = DateTime.now().toUtc();
      return AppConfirmationService().deliver(
        sessionBuilder.build(),
        authorization: 'Bearer ${credential.secret}',
        timestamp: '${now.millisecondsSinceEpoch ~/ 1000}',
        body: bodies.putIfAbsent(
          eventId,
          () => jsonEncode({
            'eventId': eventId,
            'action': _actionKey,
            'subject': link.subject,
            'occurredAt': now.toIso8601String(),
          }),
        ),
      );
    }

    Future<List<AppEvent>> events() => AppEvent.db.find(
      sessionBuilder.build(),
      where: (table) => table.appId.equals(credential.app.id),
      orderBy: (table) => table.createdAt,
    );

    setUp(() async {
      bodies.clear();
      PlatformKeys.current = PlatformKeys.fromSecrets(
        webhookSigningMasterKey: base64.encode(_masterBytes),
      );
      creator = signedIn(sessionBuilder, creatorId);
      participant = signedIn(sessionBuilder, participantId);
      await insertAccounts(sessionBuilder.build(), {
        creatorId: 'Ada',
        participantId: 'Grace',
        otherCreatorId: 'Linus',
      });
      credential = await endpoints.verilyApp.createApp(
        creator,
        name: 'Step Counter',
      );
      await endpoints.verilyApp.setWebhookUrl(
        creator,
        appId: credential.app.id,
        webhookUrl: _webhookUrl,
      );
      secret = (await endpoints.verilyApp.rotateWebhookSecret(
        creator,
        appId: credential.app.id,
      )).secret;
      action = await endpoints.actionVerification.createAction(
        creator,
        actionRequest(
          actionKey: _actionKey,
          recurrence: ActionRecurrence.daily,
          requirements: [externalRequirement(appId: credential.app.id)],
        ),
      );
      link = await endpoints.verilyApp.linkApp(
        participant,
        appId: credential.app.id,
      );
    });

    tearDown(() => PlatformKeys.current = const PlatformKeys());

    test(
      'when an attempt is verified then one attempt.verified is queued',
      () async {
        expect((await confirm('evt-1')).status, 202);
        expect((await confirm('evt-1')).status, 202);

        final queued = await events();
        expect(queued, hasLength(1));
        final event = queued.single;
        expect(event.type, 'attempt.verified');
        expect(event.status, AppEventStatus.pending);
        final body = jsonDecode(event.body) as Map<String, Object?>;
        expect(body['id'], event.eventId);
        expect(body['type'], 'attempt.verified');
        final data = body['data']! as Map<String, Object?>;
        expect(data['subject'], link.subject);
        expect(data['action'], _actionKey);
        expect(data['status'], 'verified');
        expect(data.keys, isNot(contains('participant')));
        expect(event.body, isNot(contains(participantId.toString())));
        expect(event.body, isNot(contains(creatorId.toString())));
      },
    );

    test('when the event is delivered then it is signed and logged', () async {
      await confirm('evt-1');
      final event = (await events()).single;
      final sender = _RecordingSender();

      await AppEventDeliveryService(
        sender: sender,
      ).deliver(sessionBuilder.build(), event.id!);

      final call = sender.calls.single;
      expect(call.url.toString(), _webhookUrl);
      expect(call.body, event.body);
      expect(call.headers['verily-event'], 'attempt.verified');
      expect(call.headers['verily-event-id'], event.eventId);
      expect(_signatureVerifies(call, secret), isTrue);
      final delivered = (await events()).single;
      expect(delivered.status, AppEventStatus.delivered);
      expect(delivered.deliveredAt, isNotNull);
      final log = await endpoints.verilyApp.listWebhookDeliveries(
        creator,
        appId: credential.app.id,
        limit: 25,
      );
      expect(log.single.succeeded, isTrue);
      expect(log.single.statusCode, 204);
      expect(log.single.eventStatus, AppEventStatus.delivered);
      expect(log.single.attemptNumber, 1);

      await AppEventDeliveryService(
        sender: sender,
      ).deliver(sessionBuilder.build(), event.id!);
      expect(sender.calls, hasLength(1), reason: 'delivered events stay done');
    });

    test(
      'when the App fails then delivery backs off and retries the same body',
      () async {
        await confirm('evt-1');
        final event = (await events()).single;
        final sender = _RecordingSender(
          const WebhookCallResult(
            duration: Duration(milliseconds: 9),
            statusCode: 500,
          ),
        );
        final start = DateTime.now().toUtc();

        await AppEventDeliveryService(
          sender: sender,
          clock: () => start,
        ).deliver(sessionBuilder.build(), event.id!);
        final pending = (await events()).single;
        await AppEventDeliveryService(
          sender: sender,
          clock: () => start.add(const Duration(seconds: 5)),
        ).deliver(sessionBuilder.build(), event.id!);
        sender.result = const WebhookCallResult(
          duration: Duration(milliseconds: 3),
          statusCode: 200,
        );
        await AppEventDeliveryService(
          sender: sender,
          clock: () => start.add(const Duration(seconds: 31)),
        ).deliver(sessionBuilder.build(), event.id!);

        expect(pending.status, AppEventStatus.pending);
        expect(pending.attemptCount, 1);
        expect(pending.lastStatusCode, 500);
        expect(pending.lastErrorCode, 'http_500');
        expect(pending.nextAttemptAt, start.add(const Duration(seconds: 30)));
        expect(
          sender.calls,
          hasLength(2),
          reason: 'not due before the backoff',
        );
        expect(sender.calls.last.body, sender.calls.first.body);
        expect(
          sender.calls.last.headers['verily-event-id'],
          sender.calls.first.headers['verily-event-id'],
        );
        expect(sender.calls.last.headers['verily-delivery-attempt'], '2');
        expect((await events()).single.status, AppEventStatus.delivered);
        final log = await AppWebhookDelivery.db.find(
          sessionBuilder.build(),
          where: (table) => table.appId.equals(credential.app.id),
          orderBy: (table) => table.attemptNumber,
        );
        expect([for (final row in log) row.succeeded], [false, true]);
        expect(log.first.errorCode, 'http_500');
      },
    );

    test('when attempts run out then the event is marked failed', () async {
      await confirm('evt-1');
      final session = sessionBuilder.build();
      final event = (await events()).single;
      await AppEvent.db.updateRow(
        session,
        event.copyWith(attemptCount: appEventMaxAttempts - 1),
      );
      final sender = _RecordingSender(
        const WebhookCallResult(
          duration: Duration(seconds: 10),
          errorCode: 'timeout',
        ),
      );

      await AppEventDeliveryService(
        sender: sender,
      ).deliver(session, event.id!);

      final failed = (await events()).single;
      expect(failed.status, AppEventStatus.failed);
      expect(failed.lastErrorCode, 'timeout');
      expect(failed.attemptCount, appEventMaxAttempts);
    });

    test('when backoff is computed then it doubles and caps at two hours', () {
      expect(appEventRetryDelay(1), const Duration(seconds: 30));
      expect(appEventRetryDelay(2), const Duration(minutes: 1));
      expect(appEventRetryDelay(5), const Duration(minutes: 8));
      expect(appEventRetryDelay(11), const Duration(hours: 2));
    });

    test(
      'when the App is revoked then queued events fail without a call',
      () async {
        await confirm('evt-1');
        final event = (await events()).single;
        await endpoints.verilyApp.revokeApp(creator, appId: credential.app.id);
        final sender = _RecordingSender();

        await AppEventDeliveryService(
          sender: sender,
        ).deliver(sessionBuilder.build(), event.id!);

        expect(sender.calls, isEmpty);
        final failed = (await events()).single;
        expect(failed.status, AppEventStatus.failed);
        expect(failed.lastErrorCode, 'app_revoked');
      },
    );

    test(
      'when the signing key goes away then the attempt fails and retries',
      () async {
        await confirm('evt-1');
        final event = (await events()).single;
        final sender = _RecordingSender();

        await AppEventDeliveryService(
          sender: sender,
          secrets: () => null,
        ).deliver(sessionBuilder.build(), event.id!);

        expect(sender.calls, isEmpty);
        final pending = (await events()).single;
        expect(pending.status, AppEventStatus.pending);
        expect(pending.lastErrorCode, 'signing_unavailable');
      },
    );

    test('when the App has no webhook then no event is queued', () async {
      await endpoints.verilyApp.setWebhookUrl(
        creator,
        appId: credential.app.id,
      );

      expect((await confirm('evt-1')).status, 202);

      expect(await events(), isEmpty);
    });

    test(
      'when an attempt is rejected then attempt.rejected carries the reason',
      () async {
        final session = sessionBuilder.build();
        final attempt = await endpoints.actionVerification.beginAttempt(
          participant,
          actionId: action.id,
          idempotencyKey: 'attempt-rejected',
        );
        final row = await ActionAttempt.db.findById(session, attempt.id);
        final rejected = await ActionAttempt.db.updateRow(
          session,
          row!.copyWith(
            status: ActionAttemptStatus.rejected,
            rejectionCode: 'app_not_confirmed',
          ),
        );

        final queued = await session.db.transaction(
          (transaction) => const AppAttemptEvents().onAttemptSettled(
            session,
            attempt: rejected,
            now: DateTime.now().toUtc(),
            transaction: transaction,
          ),
        );

        final event = (await events()).single;
        expect(queued, [event.id]);
        expect(event.type, 'attempt.rejected');
        final data =
            (jsonDecode(event.body) as Map<String, Object?>)['data']!
                as Map<String, Object?>;
        expect(data['reason'], 'app_not_confirmed');
        expect(data['subject'], link.subject);
      },
    );

    test('when the delivery log is edited then the database refuses', () async {
      await confirm('evt-1');
      final event = (await events()).single;
      await AppEventDeliveryService(
        sender: _RecordingSender(),
      ).deliver(sessionBuilder.build(), event.id!);
      final row = (await AppWebhookDelivery.db.find(
        sessionBuilder.build(),
      )).single;

      await expectLater(
        AppWebhookDelivery.db.updateRow(
          sessionBuilder.build(),
          row.copyWith(succeeded: false, errorCode: 'forged'),
        ),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        AppWebhookDelivery.db.deleteRow(sessionBuilder.build(), row),
        throwsA(isA<DatabaseException>()),
      );
    });

    test(
      'when recovery runs then due and stalled events are rescheduled',
      () async {
        await confirm('evt-1');
        final session = sessionBuilder.build();
        final now = DateTime.now().toUtc();
        final due = (await events()).single;
        await AppEvent.db.updateRow(
          session,
          due.copyWith(
            status: AppEventStatus.delivering,
            leaseExpiresAt: now.subtract(const Duration(minutes: 1)),
          ),
        );
        final service = AppEventDeliveryService(
          sender: _RecordingSender(),
          clock: () => now,
        );

        expect(await service.recover(session, batchSize: 10), 1);

        await AppEvent.db.updateRow(
          session,
          (await events()).single.copyWith(
            status: AppEventStatus.pending,
            nextAttemptAt: now.add(const Duration(minutes: 5)),
          ),
        );
        expect(await service.recover(session, batchSize: 10), 0);
        expect(
          () => service.recover(session, batchSize: 0),
          throwsArgumentError,
        );
      },
    );
  });

  withServerpod(
    'Given a rewarded action its App confirms',
    (sessionBuilder, endpoints) {
      final creatorId = testId(0x721);
      final participantId = testId(0x722);
      late TestSessionBuilder creator;
      late TestSessionBuilder participant;
      late FakeRewardEscrowGateway gateway;

      setUp(() async {
        PlatformKeys.current = PlatformKeys.fromSecrets(
          webhookSigningMasterKey: base64.encode(_masterBytes),
        );
        gateway = FakeRewardEscrowGateway();
        RewardRuntime.current = fakeRewardConfiguration(gateway);
        creator = signedIn(sessionBuilder, creatorId);
        participant = signedIn(sessionBuilder, participantId);
        await insertAccounts(sessionBuilder.build(), {
          creatorId: 'Ada',
          participantId: 'Grace',
        });
        await linkWallet(endpoints, creator, TestWallet.fromSeed(41));
        await linkWallet(endpoints, participant, TestWallet.fromSeed(42));
      });

      tearDown(() {
        PlatformKeys.current = const PlatformKeys();
        RewardRuntime.current = const RewardConfiguration.disabled();
      });

      test(
        'when its payout is released then payout.released omits the wallet',
        () async {
          final credential = await endpoints.verilyApp.createApp(
            creator,
            name: 'Step Counter',
          );
          await endpoints.verilyApp.setWebhookUrl(
            creator,
            appId: credential.app.id,
            webhookUrl: _webhookUrl,
          );
          await endpoints.verilyApp.rotateWebhookSecret(
            creator,
            appId: credential.app.id,
          );
          final draft = await endpoints.actionVerification.saveActionDraft(
            creator,
            actionRequest(
              actionKey: _actionKey,
              requirements: [externalRequirement(appId: credential.app.id)],
              reward: rewardTerms(),
            ),
          );
          await endpoints.rewards.prepareRewardFunding(
            creator,
            actionId: draft.id,
          );
          await endpoints.rewards.confirmRewardFunding(
            creator,
            actionId: draft.id,
            signature: fakeSignature('fund-app-action'),
          );
          await endpoints.actionVerification.publishAction(
            creator,
            actionId: draft.id,
            expectedRevision: draft.revision,
          );
          final link = await endpoints.verilyApp.linkApp(
            participant,
            appId: credential.app.id,
          );
          final now = DateTime.now().toUtc();
          final confirmed = await AppConfirmationService().deliver(
            sessionBuilder.build(),
            authorization: 'Bearer ${credential.secret}',
            timestamp: '${now.millisecondsSinceEpoch ~/ 1000}',
            body: jsonEncode({
              'eventId': 'evt-paid',
              'action': _actionKey,
              'subject': link.subject,
              'occurredAt': now.toIso8601String(),
            }),
          );
          expect(confirmed.status, 202);
          final session = sessionBuilder.build();
          final payout = await RewardPayout.db.findFirstRow(session);
          expect(payout, isNotNull);

          await RewardPayoutService(
            scheduler: RecordingRewardPayoutScheduler(),
          ).release(session, payout!.id!);

          final released = await AppEvent.db.findFirstRow(
            session,
            where: (table) => table.type.equals('payout.released'),
          );
          expect(released, isNotNull);
          final data =
              (jsonDecode(released!.body) as Map<String, Object?>)['data']!
                  as Map<String, Object?>;
          expect(data['subject'], link.subject);
          expect(data['payout'], payout.id.toString());
          expect(data['amountAtoms'], '${payout.amount}');
          expect(data['mint'], isNotEmpty);
          final stored = await RewardPayout.db.findById(session, payout.id!);
          expect(stored!.status, RewardPayoutStatus.released);
          final wallet = stored.recipientWallet;
          expect(wallet, isNotNull);
          expect(released.body, isNot(contains(wallet)));
          if (stored.releaseSignature case final signature?) {
            expect(released.body, isNot(contains(signature)));
          }
        },
      );
    },
  );
}
