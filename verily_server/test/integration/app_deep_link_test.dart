import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/apps/app_confirmation_service.dart';
import 'package:verily_server/src/apps/linking/app_link_service.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/security/secret_digest.dart';
import 'package:verily_server/src/web/routes/app_link_exchange_route.dart';

import 'test_tools/serverpod_test_tools.dart';
import 'test_tools/verily_fixtures.dart';

const _callback = 'https://slopper.app/verily/callback';
const _nativeCallback = 'com.slopper.app://verily';

Matcher _platformRefusal(AppPlatformProblem problem) => throwsA(
  isA<AppPlatformException>().having(
    (error) => error.problem,
    'problem',
    problem,
  ),
);

void main() {
  withServerpod('Given an App that links accounts with deep links', (
    sessionBuilder,
    endpoints,
  ) {
    final creatorId = testId(0x401);
    final participantId = testId(0x402);
    final otherCreatorId = testId(0x403);
    late TestSessionBuilder creator;
    late TestSessionBuilder participant;
    late TestSessionBuilder otherCreator;
    late VerilyAppCredential app;

    setUp(() async {
      creator = signedIn(sessionBuilder, creatorId);
      participant = signedIn(sessionBuilder, participantId);
      otherCreator = signedIn(sessionBuilder, otherCreatorId);
      await insertAccounts(sessionBuilder.build(), {
        creatorId: 'Ada',
        participantId: 'Grace',
        otherCreatorId: 'Linus',
      });
      app = await endpoints.verilyApp.createApp(creator, name: 'Slopper');
      await endpoints.verilyApp.setRedirectUris(
        creator,
        appId: app.app.id,
        redirectUris: [_callback, _nativeCallback],
      );
    });

    String timestamp([DateTime? at]) =>
        '${(at ?? DateTime.now()).toUtc().millisecondsSinceEpoch ~/ 1000}';

    Future<AppDeliveryResponse> exchange(
      String code, {
      String redirectUri = _callback,
      String? credential,
      AppLinkService? using,
      DateTime? at,
      String? body,
    }) => (using ?? AppLinkService()).exchange(
      sessionBuilder.build(),
      authorization: 'Bearer ${credential ?? app.secret}',
      timestamp: timestamp(at),
      body: body ?? jsonEncode({'code': code, 'redirectUri': redirectUri}),
    );

    Future<AppLinkRedirect> approve({
      String redirectUri = _callback,
      String? state = 'opaque-state-1',
      TestSessionBuilder? as,
    }) => endpoints.verilyApp.approveLink(
      as ?? participant,
      appId: app.app.id,
      redirectUri: redirectUri,
      state: state,
    );

    String codeOf(AppLinkRedirect redirect) =>
        Uri.parse(redirect.redirectUrl).queryParameters['code']!;

    Future<VerilyAppLink?> linkOf(UuidValue authUserId) =>
        VerilyAppLink.db.findFirstRow(
          sessionBuilder.build(),
          where: (table) =>
              table.appId.equals(app.app.id) &
              table.authUserId.equals(authUserId),
        );

    group('when a person opens a valid link request', () {
      test('then Verily shows who is asking', () async {
        final view = await endpoints.verilyApp.describeLinkRequest(
          participant,
          appId: app.app.id,
          redirectUri: _callback,
          state: 'opaque-state-1',
        );

        expect(view.appId, app.app.id);
        expect(view.appName, 'Slopper');
        expect(view.redirectUri, _callback);
        expect(view.alreadyLinked, isFalse);
      });

      test('then approving returns the exact redirect with a code', () async {
        final before = DateTime.now().toUtc();

        final redirect = await approve();

        expect(redirect.redirectUrl, startsWith('$_callback?code='));
        final query = Uri.parse(redirect.redirectUrl).queryParameters;
        expect(query.keys, unorderedEquals(['code', 'state']));
        expect(query['state'], 'opaque-state-1');
        expect(query['code'], matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
        expect(
          redirect.codeExpiresAt!.difference(before).inSeconds,
          inInclusiveRange(295, 305),
        );
        final stored = await VerilyAppLinkCode.db.findFirstRow(
          sessionBuilder.build(),
          where: (table) => table.appId.equals(app.app.id),
        );
        expect(stored!.codeHash, secretSha256Hex(query['code']!));
        expect(stored.codeHash, isNot(query['code']));
        expect(stored.redirectUri, _callback);
        expect(stored.state, 'opaque-state-1');
        expect(stored.authUserId, participantId);
      });

      test('then a custom scheme and an absent state work too', () async {
        final redirect = await approve(
          redirectUri: _nativeCallback,
          state: null,
        );

        expect(redirect.redirectUrl, startsWith('$_nativeCallback?code='));
        expect(
          Uri.parse(redirect.redirectUrl).queryParameters.keys,
          ['code'],
        );
      });

      test('then declining returns access_denied and no code', () async {
        final redirect = await endpoints.verilyApp.declineLink(
          participant,
          appId: app.app.id,
          redirectUri: _callback,
          state: 'opaque-state-1',
        );

        expect(
          redirect.redirectUrl,
          '$_callback?error=access_denied&state=opaque-state-1',
        );
        expect(redirect.codeExpiresAt, isNull);
        expect(await VerilyAppLinkCode.db.count(sessionBuilder.build()), 0);
        expect(await linkOf(participantId), isNull);
      });

      test('then signed-out callers are refused', () async {
        await expectLater(
          endpoints.verilyApp.describeLinkRequest(
            sessionBuilder,
            appId: app.app.id,
            redirectUri: _callback,
          ),
          throwsA(isA<ServerpodUnauthenticatedException>()),
        );
      });
    });

    group('when the redirect URI is not exactly registered', () {
      test('then every near miss is refused', () async {
        for (final candidate in [
          'https://slopper.app/verily',
          '$_callback/',
          'https://Slopper.app/verily/callback',
          'HTTPS://slopper.app/verily/callback',
          '$_callback?next=1',
          '$_callback#fragment',
          'https://slopper.app/verily/*',
          'http://slopper.app/verily/callback',
          ' $_callback',
          'com.slopper.app://verily/',
          '',
          'x' * 600,
        ]) {
          for (final call in [
            () => endpoints.verilyApp.describeLinkRequest(
              participant,
              appId: app.app.id,
              redirectUri: candidate,
            ),
            () => endpoints.verilyApp.approveLink(
              participant,
              appId: app.app.id,
              redirectUri: candidate,
            ),
            () => endpoints.verilyApp.declineLink(
              participant,
              appId: app.app.id,
              redirectUri: candidate,
            ),
          ]) {
            await expectLater(
              call(),
              _platformRefusal(AppPlatformProblem.linkRequestInvalid),
              reason: candidate,
            );
          }
        }
        expect(await VerilyAppLinkCode.db.count(sessionBuilder.build()), 0);
      });

      test("then another App's registered URI does not count", () async {
        final other = await endpoints.verilyApp.createApp(
          otherCreator,
          name: 'Other',
        );
        await endpoints.verilyApp.setRedirectUris(
          otherCreator,
          appId: other.app.id,
          redirectUris: ['https://other.app/cb'],
        );

        await expectLater(
          approve(redirectUri: 'https://other.app/cb'),
          _platformRefusal(AppPlatformProblem.linkRequestInvalid),
        );
      });

      test('then an unknown App reads like an invalid request', () async {
        await expectLater(
          endpoints.verilyApp.describeLinkRequest(
            participant,
            appId: testId(0x4ff),
            redirectUri: _callback,
          ),
          _platformRefusal(AppPlatformProblem.linkRequestInvalid),
        );
      });

      test('then a malformed state is refused', () async {
        for (final state in ['line\nbreak', 'x' * 257, 'tab\tstop', 'é']) {
          await expectLater(
            approve(state: state),
            _platformRefusal(AppPlatformProblem.linkRequestInvalid),
            reason: state,
          );
        }
      });
    });

    group('when the App exchanges the code', () {
      test('then it receives the pairwise subject once', () async {
        final code = codeOf(await approve());

        final response = await exchange(code);

        expect(response.status, 200);
        final link = await linkOf(participantId);
        expect(response.body, {'subject': link!.subject});
        expect(link.subject, matches(RegExp(r'^vls_[A-Za-z0-9_-]{22}$')));
        final view = await endpoints.verilyApp.describeLinkRequest(
          participant,
          appId: app.app.id,
          redirectUri: _callback,
        );
        expect(view.alreadyLinked, isTrue);

        final replay = await exchange(code);
        expect(replay.status, 400);
        expect(replay.body['error'], 'invalid_grant');
      });

      test('then the subject is stable across approvals', () async {
        final first = await exchange(codeOf(await approve()));
        final second = await exchange(codeOf(await approve(state: 'two')));

        expect(second.body['subject'], first.body['subject']);
      });

      test('then a mismatched redirect or App key is refused', () async {
        final code = codeOf(await approve());
        final other = await endpoints.verilyApp.createApp(
          otherCreator,
          name: 'Other',
        );

        for (final response in [
          await exchange(code, redirectUri: _nativeCallback),
          await exchange(code, redirectUri: '$_callback/'),
          await exchange(code, credential: other.secret),
        ]) {
          expect(response.status, 400);
          expect(response.body, {
            'error': 'invalid_grant',
            'message': 'The code is invalid, expired, or already used.',
          });
        }
        // Failed attempts never consume the code.
        expect((await exchange(code)).status, 200);
      });

      test('then an expired or unknown code is refused', () async {
        final code = codeOf(await approve());
        final late = DateTime.now().toUtc().add(const Duration(minutes: 6));

        final expired = await exchange(
          code,
          using: AppLinkService(clock: () => late),
          at: late,
        );
        expect(expired.status, 400);
        expect(expired.body['error'], 'invalid_grant');

        for (final unknown in ['A' * 43, 'short', '${'A' * 42}!']) {
          final response = await exchange(unknown);
          expect(response.status, 400, reason: unknown);
          expect(response.body['error'], 'invalid_grant');
        }
      });

      test('then the body is validated strictly', () async {
        for (final (body, error) in [
          ('nope', 'invalid_json'),
          (jsonEncode({'code': 'A' * 43}), 'missing_field'),
          (
            jsonEncode({
              'code': 'A' * 43,
              'redirectUri': _callback,
              'subject': 'vls_x',
            }),
            'unknown_field',
          ),
          (jsonEncode({'code': 43, 'redirectUri': _callback}), 'invalid_field'),
        ]) {
          final response = await exchange('', body: body);
          expect(response.status, 422, reason: body);
          expect(response.body['error'], error, reason: body);
        }
      });

      test('then unauthenticated exchanges are refused', () async {
        final code = codeOf(await approve());

        final stale = await exchange(
          code,
          at: DateTime.now().toUtc().subtract(const Duration(minutes: 10)),
        );
        expect(stale.status, 401);
        expect(stale.body['error'], 'invalid_timestamp');

        final forged = await exchange(
          code,
          credential: '${app.secret.substring(0, app.secret.length - 4)}AAAA',
        );
        expect(forged.status, 401);
        expect(forged.body['error'], 'invalid_credentials');
        expect((await exchange(code)).status, 200);
      });

      test('then too many exchanges are rate limited', () async {
        final service = AppLinkService();
        for (var index = 0; index < appLinkExchangeLimit; index += 1) {
          final response = await exchange('A' * 43, using: service);
          expect(response.status, 400);
        }

        final limited = await exchange(
          codeOf(await approve()),
          using: service,
        );

        expect(limited.status, 429);
        expect(limited.body['error'], 'rate_limited');
        expect(limited.retryAfter, isNotNull);
      });
    });

    group('when the App or the account changes after approval', () {
      test('then a revoked App can neither link nor exchange', () async {
        final code = codeOf(await approve());

        await endpoints.verilyApp.revokeApp(creator, appId: app.app.id);

        final response = await exchange(code);
        expect(response.status, 401);
        await expectLater(
          approve(),
          throwsA(
            isA<AppUnavailableException>().having(
              (error) => error.appName,
              'appName',
              'Slopper',
            ),
          ),
        );
      });

      test('then a closed account cannot approve or be exchanged', () async {
        final code = codeOf(await approve());
        final session = sessionBuilder.build();
        final account = await AuthUser.db.findById(session, participantId);
        await AuthUser.db.updateRow(session, account!.copyWith(blocked: true));

        final response = await exchange(code);
        expect(response.status, 400);
        expect(response.body['error'], 'invalid_grant');
        await expectLater(approve(), throwsStateError);
      });
    });

    group('when one account approves too often', () {
      test('then further approvals are rate limited', () async {
        for (var index = 0; index < appLinkApprovalLimit; index += 1) {
          await approve(state: 'attempt-$index');
        }

        await expectLater(
          approve(state: 'one-too-many'),
          _platformRefusal(AppPlatformProblem.rateLimited),
        );
        // Another person's approvals are counted separately.
        await expectLater(approve(as: otherCreator), completes);
      });
    });

    group('when the exchange route receives HTTP requests', () {
      late RelicServer server;
      late Uri url;

      setUp(() async {
        final route = AppLinkExchangeRoute();
        server = RelicServer(
          () => IOAdapter.bind(InternetAddress.loopbackIPv4),
        );
        await server.mountAndStart(
          (request) => route.handleCall(sessionBuilder.build(), request),
        );
        url = Uri.parse(
          'http://127.0.0.1:${server.port}/api/v1/links/exchange',
        );
      });

      tearDown(() => server.close(force: true));

      Future<http.Response> post(String body) => http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${app.secret}',
          'Verily-Timestamp': timestamp(),
          'Content-Type': 'application/json',
        },
        body: body,
      );

      test('then a code is exchanged as uncached JSON', () async {
        final code = codeOf(await approve());

        final response = await post(
          jsonEncode({'code': code, 'redirectUri': _callback}),
        );

        expect(response.statusCode, 200);
        expect(response.headers['cache-control'], contains('no-store'));
        final link = await linkOf(participantId);
        expect(jsonDecode(response.body), {'subject': link!.subject});
      });

      test('then unsigned and oversize requests are refused', () async {
        final unsigned = await http.post(url, body: '{}');
        expect(unsigned.statusCode, 401);

        final oversize = await post('x' * (4 * 1024 + 1));
        expect(oversize.statusCode, 413);
      });
    });
  });
}
