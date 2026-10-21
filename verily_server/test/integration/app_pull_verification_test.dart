import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/apps/app_confirmation_service.dart';
import 'package:verily_server/src/apps/app_pull_check_service.dart';
import 'package:verily_server/src/apps/platform_keys.dart';
import 'package:verily_server/src/apps/webhooks/webhook_sender.dart';
import 'package:verily_server/src/apps/webhooks/webhook_signing.dart';
import 'package:verily_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';
import 'test_tools/verily_fixtures.dart';

const _actionKey = 'daily-steps';
const _webhookUrl = 'https://hooks.example.org/verily';
// 40 public, test-only bytes.
final String _masterKey = base64.encode(
  utf8.encode('public-test-only-pull-webhook-master-key'),
);

/// One recorded outbound call.
typedef _Call = ({Uri url, Map<String, String> headers, String body});

/// Answers each call with the next scripted result (the last one repeats).
class _ScriptedSender implements WebhookSender {
  _ScriptedSender(this.results);

  final List<WebhookCallResult> results;
  final calls = <_Call>[];

  @override
  Future<WebhookCallResult> post({
    required Uri url,
    required Map<String, String> headers,
    required String body,
    required Duration timeout,
    int maxResponseBytes = 0,
  }) async {
    expect(timeout, appPullCallTimeout);
    expect(maxResponseBytes, appPullMaxResponseBytes);
    calls.add((url: url, headers: headers, body: body));
    return results[(calls.length - 1).clamp(0, results.length - 1)];
  }
}

WebhookCallResult _answer(Map<String, Object?> body, {int status = 200}) =>
    WebhookCallResult(
      duration: const Duration(milliseconds: 12),
      statusCode: status,
      responseBody: jsonEncode(body),
    );

const _timeout = WebhookCallResult(
  duration: Duration(seconds: 10),
  errorCode: 'timeout',
);

void main() {
  withServerpod('Given an action its App verifies on request', (
    sessionBuilder,
    endpoints,
  ) {
    final creatorId = testId(0x301);
    final participantId = testId(0x302);
    late TestSessionBuilder creator;
    late TestSessionBuilder participant;
    late VerilyAppCredential credential;
    late ActionOpportunity action;
    late ActionAttemptView attempt;
    late DateTime now;
    late List<(UuidValue, Duration)> scheduled;

    DateTime clock() => now;

    AppPullCheckService service(_ScriptedSender sender) => AppPullCheckService(
      sender: sender,
      clock: clock,
      scheduler: (_, checkId, delay) async => scheduled.add((checkId, delay)),
    );

    Future<VerilyApp> configureWebhook({
      String? url = _webhookUrl,
      int version = 1,
    }) async {
      final session = sessionBuilder.build();
      final app = await VerilyApp.db.findById(session, credential.app.id);
      return VerilyApp.db.updateRow(
        session,
        app!.copyWith(
          webhookUrl: url,
          webhookSecretVersion: version,
          webhookSecretRotatedAt: version == 0 ? null : now,
        ),
      );
    }

    Future<ActionOpportunity> createAction({
      AppVerificationMode mode = AppVerificationMode.pull,
      String key = _actionKey,
    }) => endpoints.actionVerification.createAction(
      creator,
      actionRequest(
        actionKey: key,
        recurrence: ActionRecurrence.daily,
        requirements: [
          externalRequirement(
            appId: credential.app.id,
          ).copyWith(appVerificationMode: mode),
        ],
      ),
    );

    setUp(() async {
      PlatformKeys.current = PlatformKeys.fromSecrets(
        webhookSigningMasterKey: _masterKey,
      );
      now = DateTime.now().toUtc();
      scheduled = [];
      creator = signedIn(sessionBuilder, creatorId);
      participant = signedIn(sessionBuilder, participantId);
      await insertAccounts(sessionBuilder.build(), {
        creatorId: 'Ada',
        participantId: 'Grace',
      });
      credential = await endpoints.verilyApp.createApp(
        creator,
        name: 'Step Counter',
      );
      await configureWebhook();
      action = await createAction();
      attempt = await endpoints.actionVerification.beginAttempt(
        participant,
        actionId: action.id,
        idempotencyKey: 'attempt-1',
      );
    });

    tearDown(() => PlatformKeys.current = const PlatformKeys());

    UuidValue requirementId() => action.requirements.single.id;

    Future<EvidenceSubmissionResult> request(
      _ScriptedSender sender, {
      String? reference,
    }) => service(sender).requestVerification(
      sessionBuilder.build(),
      authUserId: participantId,
      attemptId: attempt.id,
      requirementId: requirementId(),
      reference: reference,
    );

    Future<AppPullCheck> check() async => (await AppPullCheck.db.findFirstRow(
      sessionBuilder.build(),
      where: (table) => table.attemptId.equals(attempt.id),
    ))!;

    Future<ActionAttempt> storedAttempt() async =>
        (await ActionAttempt.db.findById(sessionBuilder.build(), attempt.id))!;

    Future<List<AppWebhookDelivery>> deliveries() => AppWebhookDelivery.db.find(
      sessionBuilder.build(),
      orderBy: (table) => table.attemptNumber,
    );

    Future<String> subject() async => (await VerilyAppLink.db.findFirstRow(
      sessionBuilder.build(),
      where: (table) => table.authUserId.equals(participantId),
    ))!.subject;

    Future<AppDeliveryResponse> push({
      required String eventId,
      String? attemptId,
      String? subjectOverride,
      DateTime? occurredAt,
    }) async {
      final sent = DateTime.now().toUtc();
      return AppConfirmationService().deliver(
        sessionBuilder.build(),
        authorization: 'Bearer ${credential.secret}',
        timestamp: '${sent.millisecondsSinceEpoch ~/ 1000}',
        body: jsonEncode({
          'eventId': eventId,
          'action': _actionKey,
          'subject': subjectOverride ?? await subject(),
          'occurredAt': (occurredAt ?? sent).toIso8601String(),
          'attempt': ?attemptId,
        }),
      );
    }

    group('when the App accepts', () {
      test(
        'then the attempt is verified from one signed, logged call',
        () async {
          final sender = _ScriptedSender([
            _answer({'verdict': 'accepted'}),
          ]);

          final result = await request(sender, reference: ' order-1234 ');

          expect(result.status, EvidenceDecisionStatus.accepted);
          expect(result.attempt.status, ActionAttemptStatus.verified);
          expect(result.summary, 'Confirmed by Step Counter.');
          expect((await storedAttempt()).status, ActionAttemptStatus.verified);
          final stored = await check();
          expect(stored.status, AppPullCheckStatus.accepted);
          expect(stored.reference, 'order-1234');
          final decision = await EvidenceDecision.db.findFirstRow(
            sessionBuilder.build(),
          );
          expect(decision!.verifierType, appPullVerifierType);
          expect(decision.reasonCode, 'app_confirmed');

          final call = sender.calls.single;
          expect(call.url, Uri.parse(_webhookUrl));
          final body = jsonDecode(call.body) as Map<String, Object?>;
          expect(body.keys, [
            'id',
            'type',
            'attempt',
            'action',
            'subject',
            'reference',
            'requestedAt',
          ]);
          expect(body['id'], stored.eventId);
          expect(body['type'], 'attempt.verify');
          expect(body['attempt'], attempt.id.toString());
          expect(body['action'], _actionKey);
          expect(body['subject'], await subject());
          expect(body['reference'], 'order-1234');
          expect(call.body, isNot(contains(participantId.toString())));
          expect(call.headers['verily-event'], 'attempt.verify');
          expect(call.headers['verily-event-id'], stored.eventId);

          final signature = call.headers['verily-signature']!;
          final timestamp = int.parse(
            RegExp(r'^t=(\d+),').firstMatch(signature)!.group(1)!,
          );
          final secret = WebhookSecrets(
            base64.decode(_masterKey),
          ).secretFor(appId: credential.app.id, version: 1);
          expect(
            signature,
            webhookSignatureHeader(
              timestamp: timestamp,
              body: call.body,
              secrets: [secret],
            ),
          );

          final log = await deliveries();
          expect(log.single.eventId, stored.eventId);
          expect(log.single.eventType, 'attempt.verify');
          expect(log.single.succeeded, isTrue);
          expect(log.single.statusCode, 200);
          expect(log.single.attemptNumber, 1);
        },
      );

      test('then asking again never calls the App twice', () async {
        final sender = _ScriptedSender([
          _answer({'verdict': 'accepted'}),
        ]);
        await request(sender);

        await expectLater(request(sender), throwsStateError);
        expect(sender.calls, hasLength(1));
      });
    });

    group('when the App rejects', () {
      test('then the attempt is rejected with its reason', () async {
        final sender = _ScriptedSender([
          _answer({'verdict': 'rejected', 'reason': 'steps_not_found'}),
        ]);

        final result = await request(sender);

        expect(result.status, EvidenceDecisionStatus.rejected);
        // The App's own reason is kept for audit but never shown.
        expect(result.reasonCode, 'app_not_confirmed');
        final stored = await storedAttempt();
        expect(stored.status, ActionAttemptStatus.rejected);
        expect(stored.rejectionCode, 'steps_not_found');
        expect((await check()).status, AppPullCheckStatus.rejected);
      });
    });

    group('when the App answers pending', () {
      test(
        'then the attempt waits until a push names it, and only then verifies',
        () async {
          final sender = _ScriptedSender([
            _answer({'verdict': 'pending'}),
          ]);

          final waiting = await request(sender);

          expect(waiting.status, isNull);
          expect(waiting.reasonCode, 'app_checking');
          expect((await check()).status, AppPullCheckStatus.waiting);
          expect(scheduled, isEmpty);
          // Asking again while the App is deciding makes no call.
          await request(sender);
          expect(sender.calls, hasLength(1));

          final bare = await push(eventId: 'evt-bare');
          expect(bare.status, 422);
          expect(bare.body['error'], 'pull_requires_attempt');
          expect(
            (await storedAttempt()).status,
            ActionAttemptStatus.collectingEvidence,
          );

          final answeredAt = DateTime.now().toUtc();
          final accepted = await push(
            eventId: 'evt-answer',
            attemptId: attempt.id.toString(),
            occurredAt: answeredAt,
          );
          expect(accepted.status, 202);
          expect(accepted.body['attemptStatus'], 'verified');
          expect((await check()).status, AppPullCheckStatus.accepted);
          expect((await storedAttempt()).status, ActionAttemptStatus.verified);

          final replay = await push(
            eventId: 'evt-answer',
            attemptId: attempt.id.toString(),
            occurredAt: answeredAt,
          );
          expect(replay.status, 202);
          expect(replay.body['status'], 'duplicate');
          final receipts = await AppConfirmation.db.find(
            sessionBuilder.build(),
            where: (table) => table.eventId.equals('evt-answer'),
          );
          expect(receipts.single.attemptId, attempt.id);
        },
      );

      test(
        'then a push naming an unknown attempt or one without a check is '
        'refused',
        () async {
          await request(
            _ScriptedSender([
              _answer({'verdict': 'pending'}),
            ]),
          );

          final unknown = await push(
            eventId: 'evt-unknown',
            attemptId: testId(0x3ff).toString(),
          );
          expect(unknown.status, 404);
          expect(unknown.body['error'], 'unknown_attempt');

          final other = await createAction(key: 'weekly-steps');
          final unchecked = await endpoints.actionVerification.beginAttempt(
            participant,
            actionId: other.id,
            idempotencyKey: 'attempt-2',
          );
          final final_ = await AppConfirmationService().deliver(
            sessionBuilder.build(),
            authorization: 'Bearer ${credential.secret}',
            timestamp: '${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
            body: jsonEncode({
              'eventId': 'evt-unchecked',
              'action': 'weekly-steps',
              'subject': await subject(),
              'occurredAt': DateTime.now().toUtc().toIso8601String(),
              'attempt': unchecked.id.toString(),
            }),
          );
          expect(final_.status, 409);
          expect(final_.body['error'], 'no_open_pull_check');
        },
      );

      test(
        'then no answer within 24 hours expires the check and rejects the '
        'requirement',
        () async {
          final sender = _ScriptedSender([
            _answer({'verdict': 'pending'}),
          ]);
          await request(sender);

          now = now.add(const Duration(hours: 24, seconds: 1));
          final acted = await service(
            sender,
          ).recover(sessionBuilder.build(), batchSize: 10);

          expect(acted, 1);
          final stored = await check();
          expect(stored.status, AppPullCheckStatus.expired);
          final attemptRow = await storedAttempt();
          expect(attemptRow.status, ActionAttemptStatus.rejected);
          expect(attemptRow.rejectionCode, 'app_verification_expired');
          expect(sender.calls, hasLength(1));
        },
      );
    });

    group('when the App answers with anything but a strict verdict', () {
      for (final (label, answer) in [
        (
          'an extra field',
          _answer({'verdict': 'accepted', 'note': 'ok'}),
        ),
        ('a missing verdict', _answer({'reason': 'ok'})),
        ('an unknown verdict', _answer({'verdict': 'yes'})),
        (
          'a malformed reason',
          _answer({'verdict': 'accepted', 'reason': 'Looks Good'}),
        ),
        ('a server error', _answer({'verdict': 'accepted'}, status: 500)),
        (
          'a body that is not JSON',
          const WebhookCallResult(
            duration: Duration(milliseconds: 3),
            statusCode: 200,
            responseBody: 'accepted',
          ),
        ),
        ('a timeout', _timeout),
        (
          'a host that resolves privately',
          const WebhookCallResult(
            duration: Duration.zero,
            errorCode: 'host_not_public',
          ),
        ),
      ]) {
        test('when it is $label then the call failed and retries', () async {
          final result = await request(_ScriptedSender([answer]));

          expect(result.status, isNull);
          expect(result.reasonCode, 'app_checking');
          expect(
            (await storedAttempt()).status,
            ActionAttemptStatus.collectingEvidence,
          );
          expect(
            await EvidenceDecision.db.count(sessionBuilder.build()),
            0,
          );
          final stored = await check();
          expect(stored.status, AppPullCheckStatus.retrying);
          expect(stored.lastErrorCode, isNotNull);
          expect(stored.nextCallAt, now.add(const Duration(seconds: 30)));
          expect(scheduled.single, (stored.id, const Duration(seconds: 30)));
          final log = (await deliveries()).single;
          expect(log.succeeded, isFalse);
          expect(log.errorCode, stored.lastErrorCode);
        });
      }

      test(
        'then backoff doubles until the calls run out and the check fails, '
        'and the participant may start again',
        () async {
          final sender = _ScriptedSender([_timeout]);
          await request(sender);
          final checkId = (await check()).id!;

          for (var call = 2; call <= appPullMaxCalls; call += 1) {
            now = (await check()).nextCallAt!;
            await service(sender).callApp(sessionBuilder.build(), checkId);
          }

          expect(sender.calls, hasLength(appPullMaxCalls));
          expect(
            [for (final (_, delay) in scheduled) delay],
            [
              for (var calls = 1; calls < appPullMaxCalls; calls += 1)
                appPullRetryDelay(calls),
            ],
          );
          final failed = await check();
          expect(failed.status, AppPullCheckStatus.failed);
          expect(failed.nextCallAt, isNull);
          expect(await deliveries(), hasLength(appPullMaxCalls));
          expect(
            (await storedAttempt()).status,
            ActionAttemptStatus.collectingEvidence,
          );

          final restarted = await request(
            _ScriptedSender([
              _answer({'verdict': 'accepted'}),
            ]),
          );
          expect(restarted.status, EvidenceDecisionStatus.accepted);
          final fresh = await check();
          expect(fresh.eventId, isNot(failed.eventId));
          expect(fresh.callCount, 1);
        },
      );

      test('then a due retry that answers accepted verifies', () async {
        final sender = _ScriptedSender([
          _timeout,
          _answer({'verdict': 'accepted'}),
        ]);
        await request(sender);
        final stored = await check();

        // Not yet due: nothing happens.
        await service(sender).callApp(sessionBuilder.build(), stored.id!);
        expect(sender.calls, hasLength(1));

        now = stored.nextCallAt!;
        await service(sender).callApp(sessionBuilder.build(), stored.id!);

        expect(sender.calls, hasLength(2));
        expect((await check()).status, AppPullCheckStatus.accepted);
        expect((await storedAttempt()).status, ActionAttemptStatus.verified);
        final log = await deliveries();
        expect([for (final row in log) row.attemptNumber], [1, 2]);
        expect(log.first.eventId, log.last.eventId);
      });

      test('then recovery schedules due retries', () async {
        await request(_ScriptedSender([_timeout]));
        scheduled.clear();
        now = now.add(const Duration(minutes: 1));

        final acted = await service(
          _ScriptedSender([_timeout]),
        ).recover(sessionBuilder.build(), batchSize: 10);

        expect(acted, 1);
        expect(scheduled.single, ((await check()).id, Duration.zero));
      });
    });

    group('when a call holds its lease', () {
      test(
        'then neither a retry nor the participant calls again until it '
        'expires',
        () async {
          await request(_ScriptedSender([_timeout]));
          final session = sessionBuilder.build();
          final leased = await AppPullCheck.db.updateRow(
            session,
            (await check()).copyWith(
              status: AppPullCheckStatus.calling,
              leaseExpiresAt: now.add(appPullCallLease),
            ),
          );
          final sender = _ScriptedSender([
            _answer({'verdict': 'accepted'}),
          ]);

          await service(sender).callApp(session, leased.id!);
          final asked = await request(sender);

          expect(sender.calls, isEmpty);
          expect(asked.reasonCode, 'app_checking');

          now = now.add(appPullCallLease);
          await service(sender).callApp(session, leased.id!);
          expect(sender.calls, hasLength(1));
          expect((await check()).status, AppPullCheckStatus.accepted);
        },
      );
    });

    group('when the participant opens the page again', () {
      Future<EvidenceSubmissionResult?> reopen({UuidValue? as}) =>
          endpoints.actionVerification.getAppVerification(
            as == null ? participant : signedIn(sessionBuilder, as),
            attemptId: attempt.id,
            requirementId: requirementId(),
          );

      test('then nothing stands before they ask', () async {
        expect(await reopen(), isNull);
        expect(await AppPullCheck.db.count(sessionBuilder.build()), 0);
      });

      test('then a check the App is deciding reads as waiting, and reading '
          'calls nobody', () async {
        final sender = _ScriptedSender([
          _answer({'verdict': 'pending'}),
        ]);
        await request(sender);

        final waiting = (await reopen())!;

        expect(waiting.status, isNull);
        expect(waiting.reasonCode, 'app_checking');
        expect(waiting.requirementId, requirementId());
        expect(waiting.attempt.id, attempt.id);
        expect(waiting.attempt.status, ActionAttemptStatus.collectingEvidence);
        expect(sender.calls, hasLength(1));
        expect((await check()).callCount, 1);
      });

      test('then the App confirming reads back as confirmed', () async {
        await request(
          _ScriptedSender([
            _answer({'verdict': 'accepted'}),
          ]),
        );

        final confirmed = (await reopen())!;

        expect(confirmed.status, EvidenceDecisionStatus.accepted);
        expect(confirmed.reasonCode, 'app_confirmed');
        expect(confirmed.attempt.status, ActionAttemptStatus.verified);
      });

      test('then the App saying no reads back as rejected', () async {
        await request(
          _ScriptedSender([
            _answer({'verdict': 'rejected', 'reason': 'steps_not_found'}),
          ]),
        );

        final rejected = (await reopen())!;

        expect(rejected.status, EvidenceDecisionStatus.rejected);
        expect(rejected.reasonCode, 'app_not_confirmed');
        expect(rejected.attempt.status, ActionAttemptStatus.rejected);
      });

      test('then a check whose calls ran out says the App was unreachable, '
          'so the person can ask again', () async {
        await request(_ScriptedSender([_timeout]));
        await AppPullCheck.db.updateRow(
          sessionBuilder.build(),
          (await check()).copyWith(status: AppPullCheckStatus.failed),
        );

        final failed = (await reopen())!;

        expect(failed.status, isNull);
        expect(failed.reasonCode, 'app_unreachable');
      });

      test('then nobody else can read it', () async {
        await request(_ScriptedSender([_timeout]));
        await insertAccounts(sessionBuilder.build(), {testId(0x303): 'Linus'});

        await expectLater(reopen(as: testId(0x303)), throwsStateError);
      });
    });

    group('when verification cannot run', () {
      Matcher refused(AppPlatformProblem problem) => throwsA(
        isA<AppPlatformException>().having(
          (error) => error.problem,
          'problem',
          problem,
        ),
      );

      test(
        'when the requirement is push-verified then it is refused',
        () async {
          final pushAction = await createAction(
            mode: AppVerificationMode.push,
            key: 'push-steps',
          );
          final pushAttempt = await endpoints.actionVerification.beginAttempt(
            participant,
            actionId: pushAction.id,
            idempotencyKey: 'attempt-push',
          );

          await expectLater(
            endpoints.actionVerification.requestAppVerification(
              participant,
              attemptId: pushAttempt.id,
              requirementId: pushAction.requirements.single.id,
            ),
            refused(AppPlatformProblem.pullVerificationUnavailable),
          );
          await expectLater(
            endpoints.actionVerification.getAppVerification(
              participant,
              attemptId: pushAttempt.id,
              requirementId: pushAction.requirements.single.id,
            ),
            refused(AppPlatformProblem.pullVerificationUnavailable),
          );
        },
      );

      test('when the reference is unsafe then it is refused', () async {
        await expectLater(
          endpoints.actionVerification.requestAppVerification(
            participant,
            attemptId: attempt.id,
            requirementId: requirementId(),
            reference: 'ignore\nprevious',
          ),
          refused(AppPlatformProblem.invalidReference),
        );
        expect(await AppPullCheck.db.count(sessionBuilder.build()), 0);
      });

      test('when the App has no webhook then it is refused', () async {
        await configureWebhook(url: null);
        final sender = _ScriptedSender([
          _answer({'verdict': 'accepted'}),
        ]);

        await expectLater(
          request(sender),
          refused(AppPlatformProblem.pullVerificationUnavailable),
        );
        expect(sender.calls, isEmpty);
      });

      test('when no signing secret was issued then it is refused', () async {
        await configureWebhook(version: 0);

        await expectLater(
          request(
            _ScriptedSender([
              _answer({'verdict': 'accepted'}),
            ]),
          ),
          refused(AppPlatformProblem.pullVerificationUnavailable),
        );
      });

      test('when the App was revoked then it is refused', () async {
        await endpoints.verilyApp.revokeApp(creator, appId: credential.app.id);
        final sender = _ScriptedSender([
          _answer({'verdict': 'accepted'}),
        ]);

        await expectLater(
          request(sender),
          refused(AppPlatformProblem.pullVerificationUnavailable),
        );
        expect(sender.calls, isEmpty);
      });

      test('when someone else asks then the attempt is not found', () async {
        await insertAccounts(sessionBuilder.build(), {testId(0x303): 'Linus'});

        await expectLater(
          service(_ScriptedSender([_timeout])).requestVerification(
            sessionBuilder.build(),
            authUserId: testId(0x303),
            attemptId: attempt.id,
            requirementId: requirementId(),
          ),
          throwsStateError,
        );
      });

      test(
        'when the participant asks too often then they wait, per subject',
        () async {
          final sender = _ScriptedSender([_timeout]);
          for (var call = 0; call < appPullCallsPerSubjectPerHour; call += 1) {
            await request(sender);
          }

          await expectLater(
            request(sender),
            refused(AppPlatformProblem.rateLimited),
          );
          expect(sender.calls, hasLength(appPullCallsPerSubjectPerHour));
        },
      );
    });
  });
}
