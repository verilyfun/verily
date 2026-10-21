import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/evidence_verification_worker.dart';
import 'package:verily_server/src/apps/app_confirmation_service.dart';
import 'package:verily_server/src/apps/app_subjects.dart';
import 'package:verily_server/src/apps/platform_keys.dart';
import 'package:verily_server/src/apps/webhooks/app_event_outbox.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/verification_requests/receipt_signing.dart';
import 'package:verily_server/src/verification_requests/verification_request_service.dart';
import 'package:verily_server/src/web/routes/jwks_route.dart';
import 'package:verily_server/src/web/routes/verification_requests_route.dart';

import 'test_tools/serverpod_test_tools.dart';
import 'test_tools/verily_fixtures.dart';

const _redirect = 'https://slopper.example.org/verily/return?from=verily';
final _receiptSeed = List<int>.generate(32, (index) => index + 1);
final _webhookKey = List<int>.filled(48, 9);

Map<String, Object?> _requestBody({
  String kind = 'photo',
  String check = 'content',
  String? instructions = 'Show your finished sourdough loaf.',
  bool shareEvidence = false,
  Map<String, Object?>? place,
  String? liveChallenge,
  String redirectUri = _redirect,
  String? state = 'slopper-state-42',
  int expiresInSeconds = 600,
}) => {
  'kind': kind,
  'check': check,
  'instructions': ?instructions,
  'shareEvidence': shareEvidence,
  'place': ?place,
  'liveChallenge': ?liveChallenge,
  'redirectUri': redirectUri,
  'state': ?state,
  'expiresInSeconds': expiresInSeconds,
};

String _unix(DateTime at) => '${at.toUtc().millisecondsSinceEpoch ~/ 1000}';

void main() {
  withServerpod('Given an App that asks people to prove things', (
    sessionBuilder,
    endpoints,
  ) {
    final creatorId = testId(0x401);
    final participantId = testId(0x402);
    final otherId = testId(0x403);
    late TestSessionBuilder creator;
    late TestSessionBuilder participant;
    late TestSessionBuilder other;
    late VerilyAppCredential credential;
    late VerificationRequestService service;

    setUp(() async {
      creator = signedIn(sessionBuilder, creatorId);
      participant = signedIn(sessionBuilder, participantId);
      other = signedIn(sessionBuilder, otherId);
      service = VerificationRequestService();
      PlatformKeys.current = PlatformKeys(
        receiptSigningKey: _receiptSeed,
        webhookSigningMasterKey: _webhookKey,
      );
      final session = sessionBuilder.build();
      registerLocalEvidenceStorage(session);
      await insertAccounts(session, {
        creatorId: 'Ada',
        participantId: 'Grace',
        otherId: 'Linus',
      });
      credential = await endpoints.verilyApp.createApp(
        creator,
        name: 'Slopper',
        websiteUrl: 'https://slopper.example.org',
      );
      await endpoints.verilyApp.setRedirectUris(
        creator,
        appId: credential.app.id,
        redirectUris: [_redirect],
      );
      final app = await VerilyApp.db.findById(session, credential.app.id);
      await VerilyApp.db.updateRow(
        session,
        app!.copyWith(
          webhookUrl: 'https://hooks.slopper.example.org/verily',
          webhookSecretVersion: 1,
          webhookSecretRotatedAt: DateTime.now().toUtc(),
        ),
      );
    });

    tearDown(() => PlatformKeys.current = const PlatformKeys());

    Future<AppDeliveryResponse> create(
      Map<String, Object?> body, {
      String? secret,
      DateTime? sentAt,
      VerificationRequestService? using,
    }) => (using ?? service).createFromApi(
      sessionBuilder.build(),
      authorization: 'Bearer ${secret ?? credential.secret}',
      timestamp: _unix(sentAt ?? DateTime.now()),
      body: jsonEncode(body),
    );

    Future<UuidValue> createId(Map<String, Object?> body) async {
      final response = await create(body);
      expect(response.status, 201, reason: '${response.body}');
      return UuidValue.withValidation(response.body['requestId']! as String);
    }

    Future<AppDeliveryResponse> receipt(
      UuidValue requestId, {
      String? code,
      String? secret,
    }) => service.receipt(
      sessionBuilder.build(),
      authorization: 'Bearer ${secret ?? credential.secret}',
      timestamp: _unix(DateTime.now()),
      requestId: requestId.toString(),
      body: code == null ? '{}' : jsonEncode({'code': code}),
    );

    Future<VerificationRequest> stored(UuidValue id) async =>
        (await VerificationRequest.db.findById(sessionBuilder.build(), id))!;

    Future<List<AppEvent>> completionEvents() => AppEvent.db.find(
      sessionBuilder.build(),
      where: (table) =>
          table.type.equals(AppEventType.verificationRequestCompleted),
      orderBy: (table) => table.createdAt,
    );

    Matcher refused(AppPlatformProblem problem) => throwsA(
      isA<AppPlatformException>().having(
        (error) => error.problem,
        'problem',
        problem,
      ),
    );

    /// Accepts a photo request, uploads a JPEG, and lets the worker decide.
    Future<VerificationRequestView> capturePhoto(
      UuidValue requestId, {
      bool accept = true,
    }) async {
      final view = await endpoints.verificationRequest.accept(
        participant,
        requestId: requestId,
      );
      final action = view.action!;
      final requirement = action.requirements.firstWhere(
        (item) => item.kind == ActionRequirementKind.photo,
      );
      final submitted = await uploadMediaProof(
        endpoints,
        participant,
        participantId: participantId,
        attemptId: action.myAttempt!.id,
        requirementId: requirement.id,
        contentType: 'image/jpeg',
        bytes: MediaFixtures.jpeg(),
      );
      expect(submitted.attempt.status, ActionAttemptStatus.verifying);
      if (accept) {
        final session = sessionBuilder.build();
        final evidence = await ActionEvidence.db.findFirstRow(
          session,
          where: (table) => table.attemptId.equals(action.myAttempt!.id),
        );
        await EvidenceVerificationWorker(
          verifierFactory: (_, _, _) => ScriptedMediaVerifier(),
        ).verify(session, evidence!.id!);
      }
      return view;
    }

    group('when an App creates a request', () {
      test('then it gets a link that carries only the request id', () async {
        final before = DateTime.now().toUtc();
        final response = await create(_requestBody());

        expect(response.status, 201);
        final id = response.body['requestId']! as String;
        expect(response.body['url'], 'https://verily.fun/r/$id');
        expect(response.body['appUrl'], 'verily://r/$id');
        expect(response.body['status'], 'open');
        final request = await stored(UuidValue.withValidation(id));
        expect(request.status, VerificationRequestStatus.open);
        expect(request.kind, VerificationRequestKind.photo);
        expect(request.spokenChallenge, isFalse);
        expect(
          request.expiresAt.difference(before).inSeconds,
          inInclusiveRange(599, 601),
        );
      });

      test('then a bad key or a stale timestamp is refused', () async {
        final forged = await create(
          _requestBody(),
          secret: 'vly_0123456789abcdef.${'A' * 43}',
        );
        expect(forged.status, 401);
        expect(forged.body['error'], 'invalid_credentials');

        final stale = await create(
          _requestBody(),
          sentAt: DateTime.now().subtract(const Duration(minutes: 6)),
        );
        expect(stale.status, 401);
        expect(stale.body['error'], 'invalid_timestamp');
        expect(await VerificationRequest.db.count(sessionBuilder.build()), 0);
      });

      test(
        'then a redirect that is not exactly registered is refused',
        () async {
          for (final uri in [
            'https://slopper.example.org/verily/return',
            '$_redirect&extra=1',
            'https://evil.example.org/verily/return?from=verily',
          ]) {
            final response = await create(_requestBody(redirectUri: uri));
            expect(response.status, 422, reason: uri);
            expect(response.body['error'], 'redirect_uri_not_registered');
          }
        },
      );

      test('then an invalid body is refused without echoing it', () async {
        final response = await create({
          ..._requestBody(),
          'expiresInSeconds': 30,
        });

        expect(response.status, 422);
        expect(response.body['error'], 'invalid_field');
        expect(response.body['field'], 'expiresInSeconds');
        expect(jsonEncode(response.body), isNot(contains('30')));
      });

      test('then a revoked App is refused', () async {
        await endpoints.verilyApp.revokeApp(creator, appId: credential.app.id);

        final response = await create(_requestBody());

        expect(response.status, 401);
      });

      test('then the per-App rate limit answers 429', () async {
        await VerilyAppRateWindow.db.insertRow(
          sessionBuilder.build(),
          VerilyAppRateWindow(
            appId: credential.app.id,
            bucket: 'verification-requests',
            windowStartedAt: DateTime.now().toUtc(),
            requestCount: verificationRequestsPerMinute,
          ),
        );

        final response = await create(_requestBody());

        expect(response.status, 429);
        expect(response.retryAfter, isNotNull);
      });
    });

    group('when a person opens the request', () {
      test(
        'then the app shows who asks, for what, and what is shared',
        () async {
          final id = await createId(
            _requestBody(
              kind: 'video',
              shareEvidence: true,
              place: {
                'latitude': 51.5,
                'longitude': -0.12,
                'radiusMeters': 150,
              },
            ),
          );

          final view = await endpoints.verificationRequest.getRequest(
            participant,
            requestId: id,
          );

          expect(view.appName, 'Slopper');
          expect(view.appWebsiteUrl, 'https://slopper.example.org');
          expect(view.kind, VerificationRequestKind.video);
          expect(view.instructions, 'Show your finished sourdough loaf.');
          expect(view.checksPlace, isTrue);
          expect(view.spokenChallenge, isTrue);
          expect(view.shareEvidence, isTrue);
          expect(view.status, VerificationRequestStatus.open);
          expect(view.action, isNull);
        },
      );

      test('then an unknown request is not found', () async {
        await expectLater(
          endpoints.verificationRequest.getRequest(
            participant,
            requestId: testId(0x4ff),
          ),
          refused(AppPlatformProblem.verificationRequestNotFound),
        );
      });
    });

    group('when a person accepts', () {
      test(
        'then a private single-use action is opened for them alone',
        () async {
          final id = await createId(
            _requestBody(
              kind: 'video',
              place: {
                'latitude': 51.5,
                'longitude': -0.12,
                'radiusMeters': 150,
              },
            ),
          );

          final view = await endpoints.verificationRequest.accept(
            participant,
            requestId: id,
          );

          final action = view.action!;
          expect(view.status, VerificationRequestStatus.accepted);
          expect(action.maxVerifiedCompletions, 1);
          expect(action.recurrence, ActionRecurrence.once);
          expect(action.reward, isNull);
          expect(action.viewerIsCreator, isFalse);
          expect(action.creatorDisplayName, 'Ada');
          expect(
            action.myAttempt?.status,
            ActionAttemptStatus.collectingEvidence,
          );
          expect(action.requirements.map((item) => item.kind), [
            ActionRequirementKind.video,
            ActionRequirementKind.location,
          ]);
          expect(action.requirements.first.isRequired, isTrue);
          expect(action.requirements.first.spokenChallengeRequired, isTrue);
          expect(action.requirements.last.isRequired, isFalse);
          final session = sessionBuilder.build();
          final definition = await ActionDefinition.db.findById(
            session,
            action.id,
          );
          expect(definition!.visibility, ActionVisibility.verificationRequest);
          expect(definition.creatorAuthUserId, creatorId);
          expect(await RewardPool.db.count(session), 0);
          final request = await stored(id);
          expect(request.participantAuthUserId, participantId);
          expect(request.subject, matches(RegExp(r'^vls_[A-Za-z0-9_-]{22}$')));
          expect(request.attemptId, action.myAttempt!.id);

          final again = await endpoints.verificationRequest.accept(
            participant,
            requestId: id,
          );
          expect(again.action!.id, action.id);

          await expectLater(
            endpoints.verificationRequest.accept(other, requestId: id),
            refused(AppPlatformProblem.verificationRequestTaken),
          );
          await expectLater(
            endpoints.actionVerification.beginAttempt(
              other,
              actionId: action.id,
              idempotencyKey: 'steal-it',
            ),
            throwsStateError,
          );
        },
      );

      test('then the private action never appears in any feed', () async {
        final id = await createId(
          _requestBody(
            kind: 'location',
            check: 'captureOnly',
            instructions: null,
            place: {'latitude': 51.5, 'longitude': -0.12, 'radiusMeters': 150},
          ),
        );
        final view = await endpoints.verificationRequest.accept(
          participant,
          requestId: id,
        );
        final actionId = view.action!.id;

        for (final viewer in [participant, other, creator]) {
          final available = await endpoints.actionVerification
              .listAvailableActions(viewer, limit: 50);
          final nearby = await endpoints.actionVerification.listNearbyActions(
            viewer,
            latitude: 51.5,
            longitude: -0.12,
            radiusKm: 5,
            limit: 50,
          );
          expect(available.map((item) => item.id), isNot(contains(actionId)));
          expect(nearby.map((item) => item.id), isNot(contains(actionId)));
        }
        final owned = await endpoints.actionVerification.listOwnedActions(
          creator,
          limit: 50,
        );
        expect(owned.map((item) => item.id), isNot(contains(actionId)));
      });

      test('then an expired request cannot be accepted', () async {
        final id = await createId(_requestBody(expiresInSeconds: 60));
        final later = VerificationRequestService(
          clock: () => DateTime.now().toUtc().add(const Duration(minutes: 2)),
        );

        await expectLater(
          later.accept(
            sessionBuilder.build(),
            authUserId: participantId,
            requestId: id,
          ),
          refused(AppPlatformProblem.verificationRequestExpired),
        );
        expect((await stored(id)).status, VerificationRequestStatus.open);
      });

      test(
        'then one person accepting too often from one App is limited',
        () async {
          final id = await createId(_requestBody());
          final session = sessionBuilder.build();
          final link = await appLinkFor(
            session,
            appId: credential.app.id,
            authUserId: participantId,
            now: DateTime.now().toUtc(),
          );
          await VerilyAppRateWindow.db.insertRow(
            session,
            VerilyAppRateWindow(
              appId: credential.app.id,
              bucket: 'verification-accept:${link.subject}',
              windowStartedAt: DateTime.now().toUtc(),
              requestCount: verificationAcceptsPerHour,
            ),
          );

          await expectLater(
            endpoints.verificationRequest.accept(participant, requestId: id),
            refused(AppPlatformProblem.rateLimited),
          );
          expect((await stored(id)).status, VerificationRequestStatus.open);
        },
      );

      test('then a revoked App cannot be accepted', () async {
        final id = await createId(_requestBody());
        await endpoints.verilyApp.revokeApp(creator, appId: credential.app.id);

        await expectLater(
          endpoints.verificationRequest.accept(participant, requestId: id),
          throwsA(isA<AppUnavailableException>()),
        );
      });
    });

    group('when the proof is captured and verified', () {
      test('then the App receives a signed receipt once through its code, '
          'and again with its key', () async {
        final id = await createId(_requestBody(shareEvidence: true));
        await capturePhoto(id);

        final request = await stored(id);
        expect(request.status, VerificationRequestStatus.completed);
        final events = await completionEvents();
        expect(events, hasLength(1));
        final eventBody =
            jsonDecode(events.single.body) as Map<String, Object?>;
        final eventData = eventBody['data']! as Map<String, Object?>;
        expect(eventData['status'], 'verified');
        expect(
          verifyReceipt(eventData['receipt']! as String, ReceiptSigning.jwks()),
          isNotNull,
        );

        final redirect = await endpoints.verificationRequest.finish(
          participant,
          requestId: id,
        );
        final returned = Uri.parse(redirect.redirectUrl);
        expect(
          redirect.redirectUrl,
          startsWith('$_redirect&request_id=$id&state=slopper-state-42&code='),
        );
        final code = returned.queryParameters['code']!;
        expect((await stored(id)).codeHash, isNot(contains(code)));

        final redeemed = await receipt(id, code: code);
        expect(redeemed.status, 200, reason: '${redeemed.body}');
        expect(redeemed.body['status'], 'verified');
        final claims = verifyReceipt(
          redeemed.body['receipt']! as String,
          ReceiptSigning.jwks(),
        )!;
        expect(claims['iss'], 'https://verily.fun');
        expect(claims['aud'], credential.app.id.toString());
        expect(claims['sub'], request.subject);
        expect(claims['jti'], id.toString());
        expect(claims['kind'], 'photo');
        expect(claims['status'], 'verified');
        expect(claims['checks'], {
          'liveCapture': 'notChecked',
          'deviceIntegrity': 'notChecked',
          'captureSignature': 'notChecked',
          'place': 'notChecked',
          'liveChallenge': 'notChecked',
          'content': 'passed',
        });
        expect((claims['evidence']! as Map)['mimeType'], 'image/jpeg');
        expect((claims['evidence']! as Map)['durationSeconds'], isNull);
        expect(jsonEncode(claims), isNot(contains('action-evidence')));
        final evidence = redeemed.body['evidence']! as Map<String, Object?>;
        expect(evidence['url'], isA<String>());
        expect(evidence['expiresAt'], isA<String>());

        final reused = await receipt(id, code: code);
        expect(reused.status, 400);
        expect(reused.body['error'], 'invalid_grant');

        final refetched = await receipt(id);
        expect(refetched.status, 200);
        expect(refetched.body['status'], 'verified');
      });

      test(
        'then no evidence link is offered unless sharing was asked for',
        () async {
          final id = await createId(_requestBody());
          await capturePhoto(id);

          final response = await receipt(id);

          expect(response.status, 200);
          expect(response.body.containsKey('evidence'), isFalse);
        },
      );

      test('then a wrong or expired code is refused', () async {
        final id = await createId(_requestBody());
        await capturePhoto(id);
        final redirect = await endpoints.verificationRequest.finish(
          participant,
          requestId: id,
        );
        final code = Uri.parse(redirect.redirectUrl).queryParameters['code']!;

        final wrong = await receipt(id, code: 'A' * 43);
        expect(wrong.status, 400);

        final late = VerificationRequestService(
          clock: () => DateTime.now().toUtc().add(const Duration(minutes: 6)),
        );
        final expired = await late.receipt(
          sessionBuilder.build(),
          authorization: 'Bearer ${credential.secret}',
          timestamp: _unix(DateTime.now().add(const Duration(minutes: 6))),
          requestId: id.toString(),
          body: jsonEncode({'code': code}),
        );
        expect(expired.status, 400);
        expect(expired.body['error'], 'invalid_grant');
      });

      test(
        'then a pending proof gives a pending receipt and no event yet',
        () async {
          final id = await createId(_requestBody());
          await capturePhoto(id, accept: false);

          final redirect = await endpoints.verificationRequest.finish(
            participant,
            requestId: id,
          );
          final response = await receipt(
            id,
            code: Uri.parse(redirect.redirectUrl).queryParameters['code'],
          );

          expect(response.status, 200);
          expect(response.body['status'], 'pendingReview');
          expect(await completionEvents(), isEmpty);
        },
      );

      test('then another App cannot read the receipt', () async {
        final id = await createId(_requestBody());
        await capturePhoto(id);
        final otherApp = await endpoints.verilyApp.createApp(
          other,
          name: 'Elsewhere',
        );

        final response = await receipt(id, secret: otherApp.secret);

        expect(response.status, 404);
      });

      test('then an unaccepted request has no receipt yet', () async {
        final id = await createId(_requestBody());

        final response = await receipt(id);

        expect(response.status, 409);
        expect(response.body['error'], 'not_ready');
      });

      test(
        'then receipts refuse with 503 when no signing key is set',
        () async {
          final id = await createId(_requestBody());
          await capturePhoto(id);
          PlatformKeys.current = PlatformKeys(
            webhookSigningMasterKey: _webhookKey,
          );

          final response = await receipt(id);

          expect(response.status, 503);
          expect(response.body['error'], 'receipts_unavailable');
        },
      );

      test('then finishing before the proof is submitted is refused', () async {
        final id = await createId(_requestBody());
        await endpoints.verificationRequest.accept(participant, requestId: id);

        await expectLater(
          endpoints.verificationRequest.finish(participant, requestId: id),
          throwsStateError,
        );
        await expectLater(
          endpoints.verificationRequest.finish(other, requestId: id),
          refused(AppPlatformProblem.verificationRequestNotFound),
        );
      });

      test('then a location request is finished by checking in', () async {
        final id = await createId(
          _requestBody(
            kind: 'location',
            check: 'captureOnly',
            instructions: null,
            place: {'latitude': 51.5, 'longitude': -0.12, 'radiusMeters': 150},
          ),
        );
        final view = await endpoints.verificationRequest.accept(
          participant,
          requestId: id,
        );
        final action = view.action!;
        await endpoints.actionVerification.submitEvidence(
          participant,
          ActionEvidenceInput(
            attemptId: action.myAttempt!.id,
            requirementId: action.requirements.single.id,
            capturedAt: DateTime.now().toUtc(),
            latitude: 51.5001,
            longitude: -0.1201,
            accuracyMeters: 10,
          ),
        );

        final redirect = await endpoints.verificationRequest.finish(
          participant,
          requestId: id,
        );
        final response = await receipt(
          id,
          code: Uri.parse(redirect.redirectUrl).queryParameters['code'],
        );

        expect(response.status, 200);
        final claims = verifyReceipt(
          response.body['receipt']! as String,
          ReceiptSigning.jwks(),
        )!;
        expect(claims['status'], 'verified');
        expect((claims['checks']! as Map)['place'], 'inside');
        expect(claims.containsKey('evidence'), isFalse);
        expect(jsonEncode(claims), isNot(contains('51.5')));
        expect((await stored(id)).status, VerificationRequestStatus.completed);
      });
    });

    group('when the person declines', () {
      test('then the App is told declined and never learns who', () async {
        final id = await createId(_requestBody());

        final redirect = await endpoints.verificationRequest.decline(
          participant,
          requestId: id,
        );

        expect(
          redirect.redirectUrl,
          '$_redirect&request_id=$id&state=slopper-state-42&status=declined',
        );
        expect(redirect.codeExpiresAt, isNull);
        expect((await stored(id)).status, VerificationRequestStatus.declined);
        final events = await completionEvents();
        expect(events, hasLength(1));
        expect(events.single.body, contains('"status":"declined"'));

        final response = await receipt(id);
        expect(response.status, 200);
        final claims = verifyReceipt(
          response.body['receipt']! as String,
          ReceiptSigning.jwks(),
        )!;
        expect(claims['status'], 'declined');
        expect(claims.containsKey('sub'), isFalse);

        await expectLater(
          endpoints.verificationRequest.accept(other, requestId: id),
          refused(AppPlatformProblem.verificationRequestClosed),
        );
        final again = await endpoints.verificationRequest.decline(
          participant,
          requestId: id,
        );
        expect(again.redirectUrl, redirect.redirectUrl);
      });

      test(
        'then a person who accepted can still decline before capturing',
        () async {
          final id = await createId(_requestBody());
          final view = await endpoints.verificationRequest.accept(
            participant,
            requestId: id,
          );

          await endpoints.verificationRequest.decline(
            participant,
            requestId: id,
          );

          final action = await ActionDefinition.db.findById(
            sessionBuilder.build(),
            view.action!.id,
          );
          expect(action!.status, ActionDefinitionStatus.paused);
          await expectLater(
            endpoints.verificationRequest.decline(other, requestId: id),
            refused(AppPlatformProblem.verificationRequestClosed),
          );
        },
      );
    });

    group('when a request runs out of time', () {
      VerificationRequestService later() => VerificationRequestService(
        clock: () => DateTime.now().toUtc().add(const Duration(minutes: 2)),
      );

      test('then the sweep expires it and tells the App', () async {
        final open = await createId(_requestBody(expiresInSeconds: 60));
        final acceptedId = await createId(_requestBody(expiresInSeconds: 60));
        final fresh = await createId(_requestBody());
        await endpoints.verificationRequest.accept(
          participant,
          requestId: acceptedId,
        );

        final expired = await later().expireDue(
          sessionBuilder.build(),
          batchSize: 50,
        );

        expect(expired, 2);
        expect((await stored(open)).status, VerificationRequestStatus.expired);
        expect(
          (await stored(acceptedId)).status,
          VerificationRequestStatus.expired,
        );
        expect((await stored(fresh)).status, VerificationRequestStatus.open);
        final events = await completionEvents();
        expect(events, hasLength(2));
        expect(
          events.every((event) => event.body.contains('"expired"')),
          isTrue,
        );
        final response = await receipt(open);
        expect(response.body['status'], 'expired');
      });

      test('then a proof already submitted is left to settle', () async {
        final id = await createId(_requestBody(expiresInSeconds: 60));
        await capturePhoto(id, accept: false);

        final expired = await later().expireDue(
          sessionBuilder.build(),
          batchSize: 50,
        );

        expect(expired, 0);
        expect((await stored(id)).status, VerificationRequestStatus.accepted);
      });

      test('then the sweep refuses an unbounded batch', () async {
        await expectLater(
          service.expireDue(sessionBuilder.build(), batchSize: 0),
          throwsArgumentError,
        );
      });
    });

    group('when the routes receive HTTP requests', () {
      late RelicApp app;
      late Uri base;

      setUp(() async {
        final session = sessionBuilder.build();
        final create = VerificationRequestsRoute();
        final receipts = VerificationReceiptRoute();
        final jwks = JwksRoute();
        app = RelicApp()
          ..post(
            '/api/v1/verification-requests',
            (request) => create.handleCall(session, request),
          )
          ..post(
            '/api/v1/verification-requests/:requestId/receipt',
            (request) => receipts.handleCall(session, request),
          )
          ..get(
            '/.well-known/jwks.json',
            (request) => jwks.handleCall(session, request),
          );
        final server = await app.run(
          () => IOAdapter.bind(InternetAddress.loopbackIPv4),
        );
        base = Uri.parse('http://127.0.0.1:${server.port}');
      });

      tearDown(() => app.close());

      Map<String, String> headers() => {
        'Authorization': 'Bearer ${credential.secret}',
        'Verily-Timestamp': _unix(DateTime.now()),
        'Content-Type': 'application/json',
      };

      test('then the JWKS publishes the receipt key', () async {
        final response = await http.get(base.resolve('/.well-known/jwks.json'));

        expect(response.statusCode, 200);
        expect(response.headers['content-type'], contains('application/json'));
        final jwks = jsonDecode(response.body) as Map<String, Object?>;
        expect(jwks, ReceiptSigning.jwks());
        expect((jwks['keys']! as List).single, containsPair('alg', 'EdDSA'));
        expect(response.body, isNot(contains('"d"')));
      });

      test(
        'then a request is created and its receipt route resolves the id',
        () async {
          final created = await http.post(
            base.resolve('/api/v1/verification-requests'),
            headers: headers(),
            body: jsonEncode(_requestBody()),
          );
          expect(created.statusCode, 201);
          expect(created.headers['cache-control'], contains('no-store'));
          final id = (jsonDecode(created.body) as Map)['requestId'] as String;

          final pending = await http.post(
            base.resolve('/api/v1/verification-requests/$id/receipt'),
            headers: headers(),
            body: '{}',
          );
          expect(pending.statusCode, 409);

          final unknown = await http.post(
            base.resolve('/api/v1/verification-requests/not-a-uuid/receipt'),
            headers: headers(),
            body: '{}',
          );
          expect(unknown.statusCode, 404);

          final oversize = await http.post(
            base.resolve('/api/v1/verification-requests'),
            headers: headers(),
            body: jsonEncode({..._requestBody(), 'padding': 'x' * 9000}),
          );
          expect(oversize.statusCode, 413);
        },
      );
    });
  });
}
