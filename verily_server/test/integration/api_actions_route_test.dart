import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/action_authoring_service.dart';
import 'package:verily_server/src/apps/api/app_api_action_service.dart';
import 'package:verily_server/src/apps/app_confirmation_service.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/web/routes/api_actions_route.dart';

import 'test_tools/serverpod_test_tools.dart';
import 'test_tools/verily_fixtures.dart';

const _actionKey = 'daily-situps';

String _actionBody({
  String actionKey = _actionKey,
  String verification = 'push',
  Map<String, Object?> extra = const {},
}) => jsonEncode({
  'actionKey': actionKey,
  'title': 'Daily sit-ups',
  'description': 'Do your sit-ups and the app confirms them.',
  'recurrence': 'daily',
  'timeZone': 'Europe/London',
  'requirements': [
    {
      'requirementKey': 'situps',
      'title': 'Do the sit-ups',
      'instructions': 'Finish the set in the app.',
      'verification': verification,
    },
  ],
  ...extra,
});

String _lifecycleBody(int revision) =>
    jsonEncode({'expectedRevision': revision});

void main() {
  withServerpod('Given an App that manages its own actions over the API', (
    sessionBuilder,
    endpoints,
  ) {
    final creatorId = testId(0x301);
    final otherCreatorId = testId(0x302);
    final participantId = testId(0x303);
    late TestSessionBuilder creator;
    late TestSessionBuilder otherCreator;
    late TestSessionBuilder participant;
    late VerilyAppCredential app;
    late AppApiActionService service;

    setUp(() async {
      creator = signedIn(sessionBuilder, creatorId);
      otherCreator = signedIn(sessionBuilder, otherCreatorId);
      participant = signedIn(sessionBuilder, participantId);
      service = AppApiActionService();
      await insertAccounts(sessionBuilder.build(), {
        creatorId: 'Ada',
        otherCreatorId: 'Linus',
        participantId: 'Grace',
      });
      app = await endpoints.verilyApp.createApp(creator, name: 'Step Counter');
    });

    String now() => '${DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000}';

    Future<AppDeliveryResponse> create(
      String body, {
      String? credential,
      String? authorization,
      String? timestamp,
      AppApiActionService? using,
    }) => (using ?? service).create(
      sessionBuilder.build(),
      authorization: authorization ?? 'Bearer ${credential ?? app.secret}',
      timestamp: timestamp ?? now(),
      body: body,
    );

    Future<AppDeliveryResponse> publish(
      String actionId,
      int revision, {
      String? credential,
    }) => service.publish(
      sessionBuilder.build(),
      authorization: 'Bearer ${credential ?? app.secret}',
      timestamp: now(),
      actionId: actionId,
      body: _lifecycleBody(revision),
    );

    Future<AppDeliveryResponse> pause(
      String actionId,
      int revision, {
      String? credential,
    }) => service.pause(
      sessionBuilder.build(),
      authorization: 'Bearer ${credential ?? app.secret}',
      timestamp: now(),
      actionId: actionId,
      body: _lifecycleBody(revision),
    );

    Map<String, Object?> actionOf(AppDeliveryResponse response) =>
        response.body['action']! as Map<String, Object?>;

    Future<int> actionCount() =>
        ActionDefinition.db.count(sessionBuilder.build());

    group('when it creates an action', () {
      test(
        'then a draft owned by its creator is bound to the App',
        () async {
          final response = await create(_actionBody());

          expect(response.status, 201);
          final action = actionOf(response);
          expect(action['actionKey'], _actionKey);
          expect(action['revision'], 1);
          expect(action['status'], 'draft');
          expect(action['publishedAt'], isNull);
          final requirement =
              (action['requirements']! as List<Object?>).single!
                  as Map<String, Object?>;
          expect(requirement['requirementKey'], 'situps');
          expect(requirement['verification'], 'push');

          final stored = await ActionDefinition.db.findById(
            sessionBuilder.build(),
            UuidValue.withValidation(action['id']! as String),
          );
          expect(stored!.creatorAuthUserId, creatorId);
          final rule = await ActionExternalRule.db.findFirstRow(
            sessionBuilder.build(),
            where: (table) => table.requirementId.equals(
              UuidValue.withValidation(requirement['id']! as String),
            ),
          );
          expect(rule!.appId, app.app.id);
          expect(rule.verificationMode, AppVerificationMode.push);

          final owned = await endpoints.actionVerification.listOwnedActions(
            creator,
            limit: 10,
          );
          expect(owned.single.id.toString(), action['id']);
          expect(owned.single.requirements.single.appName, 'Step Counter');
        },
      );

      test('then a pull requirement keeps its verification mode', () async {
        final response = await create(_actionBody(verification: 'pull'));

        expect(response.status, 201);
        final preview = await endpoints.actionVerification.previewAction(
          creator,
          actionId: UuidValue.withValidation(
            actionOf(response)['id']! as String,
          ),
        );
        expect(
          preview.requirements.single.appVerificationMode,
          AppVerificationMode.pull,
        );
      });

      test(
        'then posting the same key again updates the draft in place',
        () async {
          final first = actionOf(await create(_actionBody()));

          final second = await create(
            _actionBody(extra: {'maxVerifiedCompletions': 5}),
          );

          expect(second.status, 200);
          expect(actionOf(second)['id'], first['id']);
          expect(actionOf(second)['revision'], 1);
          expect(actionOf(second)['maxVerifiedCompletions'], 5);
          expect(await actionCount(), 1);
        },
      );

      test(
        'then posting a published key drafts the next revision',
        () async {
          final first = actionOf(await create(_actionBody()));
          await publish(first['id']! as String, 1);

          final next = await create(_actionBody());

          expect(next.status, 201);
          expect(actionOf(next)['revision'], 2);
          expect(actionOf(next)['status'], 'draft');
        },
      );
    });

    group('when the key belongs to something the App does not own', () {
      test(
        "then the creator's own phone action keeps its key",
        () async {
          await endpoints.actionVerification.createAction(
            creator,
            actionRequest(
              actionKey: _actionKey,
              requirements: [locationRequirement()],
            ),
          );

          final response = await create(_actionBody());

          expect(response.status, 409);
          expect(response.body['error'], 'action_key_taken');
          expect(await actionCount(), 1);
        },
      );

      test(
        "then another of the creator's Apps cannot take over the key",
        () async {
          await create(_actionBody());
          final otherApp = await endpoints.verilyApp.createApp(
            creator,
            name: 'Rep Tracker',
          );

          final response = await create(
            _actionBody(),
            credential: otherApp.secret,
          );

          expect(response.status, 409);
          expect(response.body['error'], 'action_key_taken');
        },
      );

      test("then another creator's App may use the same key", () async {
        await create(_actionBody());
        final foreign = await endpoints.verilyApp.createApp(
          otherCreator,
          name: 'Other Counter',
        );

        final response = await create(
          _actionBody(),
          credential: foreign.secret,
        );

        expect(response.status, 201);
        final stored = await ActionDefinition.db.findById(
          sessionBuilder.build(),
          UuidValue.withValidation(actionOf(response)['id']! as String),
        );
        expect(stored!.creatorAuthUserId, otherCreatorId);
      });
    });

    group('when the request is not authenticated', () {
      test('then missing, forged, and stale credentials are refused', () async {
        final forged = '${app.secret.substring(0, app.secret.length - 4)}AAAA';
        for (final (authorization, timestamp, error) in [
          ('', now(), 'invalid_credentials'),
          ('Basic ${app.secret}', now(), 'invalid_credentials'),
          ('Bearer $forged', now(), 'invalid_credentials'),
          (
            'Bearer vly_0000000000000000.${'A' * 43}',
            now(),
            'invalid_credentials',
          ),
          (
            'Bearer ${app.secret}',
            '${DateTime.now().toUtc().subtract(const Duration(minutes: 6)).millisecondsSinceEpoch ~/ 1000}',
            'invalid_timestamp',
          ),
          (
            'Bearer ${app.secret}',
            '${DateTime.now().toUtc().add(const Duration(minutes: 6)).millisecondsSinceEpoch ~/ 1000}',
            'invalid_timestamp',
          ),
          ('Bearer ${app.secret}', 'soon', 'invalid_timestamp'),
        ]) {
          final response = await create(
            _actionBody(),
            authorization: authorization,
            timestamp: timestamp,
          );
          expect(response.status, 401, reason: authorization);
          expect(response.body['error'], error, reason: authorization);
        }
        expect(await actionCount(), 0);
      });

      test('then a revoked key or App is refused', () async {
        final rotated = await endpoints.verilyApp.createKey(
          creator,
          appId: app.app.id,
        );
        await endpoints.verilyApp.revokeKey(
          creator,
          appId: app.app.id,
          keyId: app.keyId,
        );
        expect((await create(_actionBody())).status, 401);
        expect(
          (await create(_actionBody(), credential: rotated.secret)).status,
          201,
        );

        await endpoints.verilyApp.revokeApp(creator, appId: app.app.id);

        final response = await create(
          _actionBody(actionKey: 'after-revoke'),
          credential: rotated.secret,
        );
        expect(response.status, 401);
        expect(response.body['error'], 'invalid_credentials');
      });

      test('then a closed creator account cannot create actions', () async {
        final session = sessionBuilder.build();
        final account = await AuthUser.db.findById(session, creatorId);
        await AuthUser.db.updateRow(session, account!.copyWith(blocked: true));

        final response = await create(_actionBody());

        expect(response.status, 403);
        expect(response.body['error'], 'creator_inactive');
        expect(await actionCount(), 0);
      });
    });

    group('when the body is not a valid action', () {
      test('then schema errors are typed and nothing is stored', () async {
        for (final (body, error) in [
          ('not json', 'invalid_json'),
          ('[]', 'invalid_json'),
          (_actionBody(extra: {'reward': 5}), 'unknown_field'),
          (_actionBody(extra: {'recurrence': 'hourly'}), 'invalid_field'),
          (_actionBody(extra: {'requirements': <Object?>[]}), 'invalid_field'),
          (
            jsonEncode(
              Map.of(
                jsonDecode(_actionBody()) as Map<String, Object?>,
              )..remove('requirements'),
            ),
            'missing_field',
          ),
        ]) {
          final response = await create(body);
          expect(response.status, 422, reason: body);
          expect(response.body['error'], error, reason: body);
        }
        expect(await actionCount(), 0);
      });

      test(
        'then designer validation refuses it without echoing input',
        () async {
          for (final (extra, rule) in [
            (
              {'timeZone': 'Mars/Olympus_Mons'},
              'timeZone must be an IANA time zone.',
            ),
            (
              {
                'opensAt': '2026-11-02T00:00:00Z',
                'closesAt': '2026-11-01T00:00:00Z',
              },
              'closesAt must be after opensAt.',
            ),
          ]) {
            final response = await create(_actionBody(extra: extra));
            expect(response.status, 422, reason: '$extra');
            expect(response.body['error'], 'invalid_request');
            expect(response.body['message'], rule);
            expect(
              jsonEncode(response.body),
              isNot(contains('Olympus')),
              reason: '$extra',
            );
          }
          final optional = await create(
            jsonEncode({
              ...jsonDecode(_actionBody()) as Map<String, Object?>,
              'requirements': [
                {
                  'requirementKey': 'situps',
                  'title': 'Do the sit-ups',
                  'instructions': 'Finish the set in the app.',
                  'isRequired': false,
                },
              ],
            }),
          );
          expect(optional.status, 422);
          expect(optional.body['error'], 'invalid_request');
          expect(
            optional.body['message'],
            'An action needs at least one required proof.',
          );
          expect(await actionCount(), 0);
        },
      );

      test(
        'then a bug inside the write is not reported as a refusal',
        () async {
          // Only typed refusals become 4xx answers; a programming error rolls
          // the whole request back and surfaces as one.
          final bug = StateError('A programming error inside the write.');
          final broken = AppApiActionService(
            authoring: ActionAuthoringService(
              rewardPools: FailingDraftTerms(bug),
            ),
          );

          await expectLater(
            create(_actionBody(), using: broken),
            throwsA(same(bug)),
          );
          expect(await actionCount(), 0);
        },
      );
    });

    group('when the App sends too many requests', () {
      test('then the window refuses the rest, counting invalid ones', () async {
        final limited = AppApiActionService(rateLimit: 2);
        expect((await create('not json', using: limited)).status, 422);
        expect((await create(_actionBody(), using: limited)).status, 201);

        final refused = await create(
          _actionBody(actionKey: 'third-action'),
          using: limited,
        );

        expect(refused.status, 429);
        expect(refused.body['error'], 'rate_limited');
        expect(refused.retryAfter, isNotNull);
        expect(refused.retryAfter!.inSeconds, inInclusiveRange(1, 61));
        expect(await actionCount(), 1);
      });

      test('then another App keeps its own window', () async {
        final limited = AppApiActionService(rateLimit: 1);
        await create(_actionBody(), using: limited);
        final otherApp = await endpoints.verilyApp.createApp(
          creator,
          name: 'Rep Tracker',
        );

        final response = await create(
          _actionBody(actionKey: 'other-app-action'),
          credential: otherApp.secret,
          using: limited,
        );

        expect(response.status, 201);
      });
    });

    group('when it publishes and pauses', () {
      Future<String> draftId() async =>
          actionOf(await create(_actionBody()))['id']! as String;

      test('then the action goes live and can be paused', () async {
        final id = await draftId();

        final published = await publish(id, 1);

        expect(published.status, 200);
        expect(actionOf(published)['status'], 'active');
        expect(actionOf(published)['publishedAt'], isNotNull);
        final available = await endpoints.actionVerification
            .listAvailableActions(participant, limit: 10);
        expect(available.map((action) => action.id.toString()), [id]);

        final paused = await pause(id, 1);

        expect(paused.status, 200);
        expect(actionOf(paused)['status'], 'paused');
        expect(
          await endpoints.actionVerification.listAvailableActions(
            participant,
            limit: 10,
          ),
          isEmpty,
        );
      });

      test('then a stale revision is a conflict', () async {
        final id = await draftId();

        final response = await publish(id, 2);

        expect(response.status, 409);
        expect(response.body['error'], 'revision_conflict');
        final stored = await ActionDefinition.db.findById(
          sessionBuilder.build(),
          UuidValue.withValidation(id),
        );
        expect(stored!.status, ActionDefinitionStatus.draft);
      });

      test('then impossible transitions are conflicts', () async {
        final id = await draftId();
        final notLive = await pause(id, 1);
        expect(notLive.status, 409);
        expect(notLive.body['error'], 'not_live');

        await publish(id, 1);
        final next = actionOf(await create(_actionBody()));
        expect((await publish(next['id']! as String, 2)).status, 200);

        final replaced = await publish(id, 1);
        expect(replaced.status, 409);
        expect(replaced.body['error'], 'revision_completed');
      });

      test('then an action held for safety review cannot go live', () async {
        final id = await draftId();
        await publish(id, 1);
        // A high-risk report holds every revision of the key at once.
        final hold = await endpoints.moderation.report(
          participant,
          actionDefinitionId: UuidValue.withValidation(id),
          category: 'dangerousActivity',
          details: 'The action asks people to climb an electricity pylon.',
          idempotencyKey: 'held-action',
        );
        expect(hold.pauseActive, isTrue);
        final next = actionOf(await create(_actionBody()));

        final refused = await publish(next['id']! as String, 2);

        expect(refused.status, 409);
        expect(refused.body['error'], 'invalid_state');
        final stored = await ActionDefinition.db.findById(
          sessionBuilder.build(),
          UuidValue.withValidation(next['id']! as String),
        );
        expect(stored!.status, ActionDefinitionStatus.draft);
      });

      test('then actions it does not own read as missing', () async {
        final phone = await endpoints.actionVerification.saveActionDraft(
          creator,
          actionRequest(
            actionKey: 'phone-action',
            requirements: [locationRequirement()],
          ),
        );
        final otherApp = await endpoints.verilyApp.createApp(
          creator,
          name: 'Rep Tracker',
        );
        final foreignApp = await endpoints.verilyApp.createApp(
          otherCreator,
          name: 'Other Counter',
        );
        final id = await draftId();

        for (final (actionId, credential) in [
          (phone.id.toString(), app.secret),
          (id, otherApp.secret),
          (id, foreignApp.secret),
          ('0198bc26-4be5-7ca0-94d2-00000000ffff', app.secret),
          ('not-a-uuid', app.secret),
        ]) {
          final response = await publish(actionId, 1, credential: credential);
          expect(response.status, 404, reason: actionId);
          expect(response.body['error'], 'not_found');
        }
        final stored = await ActionDefinition.db.findById(
          sessionBuilder.build(),
          UuidValue.withValidation(id),
        );
        expect(stored!.status, ActionDefinitionStatus.draft);
      });

      test('then a lifecycle body is validated strictly', () async {
        final id = await draftId();

        final response = await service.publish(
          sessionBuilder.build(),
          authorization: 'Bearer ${app.secret}',
          timestamp: now(),
          actionId: id,
          body: '{"expectedRevision": "1"}',
        );

        expect(response.status, 422);
        expect(response.body['error'], 'invalid_field');
      });
    });

    group('when the routes receive HTTP requests', () {
      late RelicServer server;
      late Uri base;

      setUp(() async {
        final router = RelicRouter()
          ..post(
            '/api/v1/actions',
            (request) => ApiActionsRoute().handleCall(
              sessionBuilder.build(),
              request,
            ),
          )
          ..post(
            '/api/v1/actions/:actionId/publish',
            (request) => ApiActionLifecycleRoute(
              ApiActionLifecycle.publish,
            ).handleCall(sessionBuilder.build(), request),
          )
          ..post(
            '/api/v1/actions/:actionId/pause',
            (request) => ApiActionLifecycleRoute(
              ApiActionLifecycle.pause,
            ).handleCall(sessionBuilder.build(), request),
          );
        server = RelicServer(
          () => IOAdapter.bind(InternetAddress.loopbackIPv4),
        );
        await server.mountAndStart(router.asHandler);
        base = Uri.parse('http://127.0.0.1:${server.port}');
      });

      tearDown(() => server.close(force: true));

      Future<http.Response> post(String path, String body) => http.post(
        base.resolve(path),
        headers: {
          'Authorization': 'Bearer ${app.secret}',
          'Verily-Timestamp': now(),
          'Content-Type': 'application/json',
        },
        body: body,
      );

      Map<String, Object?> json(http.Response response) =>
          jsonDecode(response.body) as Map<String, Object?>;

      test('then create, publish, and pause work end to end', () async {
        final created = await post('/api/v1/actions', _actionBody());
        expect(created.statusCode, 201);
        expect(created.headers['content-type'], contains('application/json'));
        expect(created.headers['cache-control'], contains('no-store'));
        final id =
            (json(created)['action']! as Map<String, Object?>)['id']! as String;

        final published = await post(
          '/api/v1/actions/$id/publish',
          _lifecycleBody(1),
        );
        expect(published.statusCode, 200);
        expect(
          (json(published)['action']! as Map<String, Object?>)['status'],
          'active',
        );

        final paused = await post(
          '/api/v1/actions/$id/pause',
          _lifecycleBody(1),
        );
        expect(paused.statusCode, 200);
        expect(
          (json(paused)['action']! as Map<String, Object?>)['status'],
          'paused',
        );
      });

      test('then unsigned and oversize requests are refused', () async {
        final unsigned = await http.post(
          base.resolve('/api/v1/actions'),
          body: _actionBody(),
        );
        expect(unsigned.statusCode, 401);
        expect(json(unsigned)['error'], 'invalid_credentials');

        final oversize = await post(
          '/api/v1/actions',
          'x' * (appApiActionMaxBytes + 1),
        );
        expect(oversize.statusCode, 413);
        expect(json(oversize)['error'], 'payload_too_large');
        expect(await actionCount(), 0);
      });
    });
  });
}
