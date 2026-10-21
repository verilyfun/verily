// Generated copyWith clears nullable fields with an explicit null.
// ignore_for_file: avoid_redundant_argument_values

import 'dart:convert';
import 'dart:math' as math;

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:verily_server/src/account/account_access.dart';
import 'package:verily_server/src/action_verification/action_period.dart';
import 'package:verily_server/src/action_verification/action_requirement_rules.dart';
import 'package:verily_server/src/action_verification/action_verification_service.dart';
import 'package:verily_server/src/action_verification/action_views.dart';
import 'package:verily_server/src/apps/app_api_auth.dart';
import 'package:verily_server/src/apps/app_confirmation_service.dart';
import 'package:verily_server/src/apps/app_rate_limiter.dart';
import 'package:verily_server/src/apps/app_subjects.dart';
import 'package:verily_server/src/apps/webhooks/app_event_outbox.dart';
import 'package:verily_server/src/evidence_storage/evidence_object_access.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/security/secret_digest.dart';
import 'package:verily_server/src/verification_requests/verification_receipts.dart';
import 'package:verily_server/src/verification_requests/verification_request_payload.dart';
import 'package:verily_server/src/verification_requests/verification_request_settlement.dart';

/// Requests one App may create per minute.
const verificationRequestsPerMinute = 60;

/// Requests one person may accept from one App per hour.
const verificationAcceptsPerHour = 20;

/// How long a receipt code from the App's redirect works.
const verificationReceiptCodeLifetime = Duration(minutes: 5);

/// How long a shared evidence download link works.
const sharedEvidenceLinkLifetime = Duration(minutes: 5);

/// Where people open a request.
const verificationRequestWebBase = 'https://verily.fun/r/';
const verificationRequestAppBase = 'verily://r/';

/// Verification requests: an App asks one person to prove something with the
/// Verily app and receives a signed receipt. See docs/platform.md.
///
/// Accepting a request creates a private, single-use action owned by the
/// App's creator, with one attempt, so capture, upload, provenance, and
/// verification run through exactly the same pipeline as every action. It
/// never appears in a feed and carries no reward.
///
/// Lock order: the acting account's row (or the App row for API calls), then
/// the request row. Completion reaches the request row last, after the
/// account, attempt, and action-key locks, through
/// [VerificationRequestSettlement].
class VerificationRequestService {
  VerificationRequestService({
    DateTime Function()? clock,
    AppEventOutbox? outbox,
    AppRateLimiter? rateLimiter,
    ActionViews? views,
    ActionVerificationService? actions,
    VerificationRequestSettlement? settlement,
    math.Random? random,
  }) : clock = clock ?? (() => DateTime.now().toUtc()),
       outbox = outbox ?? const AppEventOutbox(),
       rateLimiter = rateLimiter ?? const AppRateLimiter(),
       views = views ?? ActionViews(clock: clock),
       actions = actions ?? ActionVerificationService(clock: clock),
       settlement = settlement ?? const VerificationRequestSettlement(),
       _random = random ?? math.Random.secure();

  final DateTime Function() clock;
  final AppEventOutbox outbox;
  final AppRateLimiter rateLimiter;
  final ActionViews views;
  final ActionVerificationService actions;
  final VerificationRequestSettlement settlement;
  final math.Random _random;

  // ---------------------------------------------------------------------
  // App API

  /// `POST /api/v1/verification-requests` with an App key.
  Future<AppDeliveryResponse> createFromApi(
    Session session, {
    required String? authorization,
    required String? timestamp,
    required String body,
  }) async {
    final authentication = await authenticateAppRequest(
      session,
      authorization: authorization,
      timestamp: timestamp,
      now: clock().toUtc(),
    );
    final VerilyAppKey key;
    switch (authentication) {
      case AppApiAuthenticated(key: final authenticated):
        key = authenticated;
      case AppApiRefused(:final response):
        return response;
    }
    return DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        final now = clock().toUtc();
        final app = await lockAuthenticatedApp(
          session,
          key: key,
          now: now,
          transaction: transaction,
        );
        if (app == null) return appApiUnauthorized;
        // Every authenticated request counts, valid or not.
        final wait = await rateLimiter.consume(
          session,
          appId: app.id!,
          bucket: 'verification-requests',
          limit: verificationRequestsPerMinute,
          window: const Duration(minutes: 1),
          now: now,
          transaction: transaction,
        );
        if (wait != null) return appApiRateLimited(wait);

        final VerificationRequestPayload payload;
        try {
          payload = parseVerificationRequestPayload(body);
        } on VerificationRequestPayloadException catch (error) {
          return AppDeliveryResponse(422, {
            'error': error.code,
            'message': error.message,
            'field': ?error.field,
          });
        }
        final registered = await VerilyAppRedirectUri.db.findFirstRow(
          session,
          where: (table) =>
              table.appId.equals(app.id) &
              table.uri.equals(payload.redirectUri),
          transaction: transaction,
        );
        if (registered == null) {
          return appApiInvalid(
            'redirect_uri_not_registered',
            "redirectUri must exactly match one of the app's registered "
                'redirect URIs.',
          );
        }
        final request = await VerificationRequest.db.insertRow(
          session,
          VerificationRequest(
            appId: app.id!,
            kind: payload.kind,
            instructions: payload.instructions,
            check: payload.check,
            placeLatitude: payload.place?.latitude,
            placeLongitude: payload.place?.longitude,
            placeRadiusMeters: payload.place?.radiusMeters,
            spokenChallenge: payload.spokenChallenge,
            shareEvidence: payload.shareEvidence,
            redirectUri: payload.redirectUri,
            state: payload.state,
            status: VerificationRequestStatus.open,
            expiresAt: now.add(payload.expiresIn),
            createdAt: now,
            updatedAt: now,
          ),
          transaction: transaction,
        );
        return AppDeliveryResponse(201, {
          'requestId': request.id.toString(),
          'url': '$verificationRequestWebBase${request.id}',
          'appUrl': '$verificationRequestAppBase${request.id}',
          'status': request.status.name,
          'expiresAt': receiptTimestamp(request.expiresAt),
        });
      },
    );
  }

  /// `POST /api/v1/verification-requests/<id>/receipt` with an App key and
  /// the one-time code, or with the key alone to fetch the receipt again.
  Future<AppDeliveryResponse> receipt(
    Session session, {
    required String? authorization,
    required String? timestamp,
    required String requestId,
    required String body,
  }) async {
    final authentication = await authenticateAppRequest(
      session,
      authorization: authorization,
      timestamp: timestamp,
      now: clock().toUtc(),
    );
    final VerilyAppKey key;
    switch (authentication) {
      case AppApiAuthenticated(key: final authenticated):
        key = authenticated;
      case AppApiRefused(:final response):
        return response;
    }
    final UuidValue id;
    try {
      id = UuidValue.withValidation(requestId);
    } on FormatException {
      return appApiNotFound;
    }
    final String? code;
    try {
      code = _receiptCode(body);
    } on FormatException {
      return appApiInvalid(
        'invalid_request',
        'Send {} or {"code": "<one-time code>"}.',
      );
    }

    final outcome = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        final now = clock().toUtc();
        final app = await lockAuthenticatedApp(
          session,
          key: key,
          now: now,
          transaction: transaction,
        );
        if (app == null) {
          return (response: appApiUnauthorized, events: <UuidValue>[]);
        }
        var request = await VerificationRequest.db.findFirstRow(
          session,
          where: (table) => table.id.equals(id) & table.appId.equals(app.id),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (request == null) {
          return (response: appApiNotFound, events: <UuidValue>[]);
        }
        final events = <UuidValue>[];
        final expired = await _expireIfDue(
          session,
          request: request,
          app: app,
          now: now,
          transaction: transaction,
        );
        if (expired != null) {
          request = expired.request;
          events.addAll(expired.events);
        }
        if (code != null) {
          final valid =
              request.codeHash != null &&
              request.codeUsedAt == null &&
              request.codeExpiresAt != null &&
              request.codeExpiresAt!.isAfter(now) &&
              constantTimeEquals(request.codeHash!, secretSha256Hex(code));
          if (!valid) {
            return (
              response: const AppDeliveryResponse(400, {
                'error': 'invalid_grant',
                'message': 'The code is invalid, expired, or already used.',
              }),
              events: events,
            );
          }
          request = await VerificationRequest.db.updateRow(
            session,
            request.copyWith(codeUsedAt: now, updatedAt: now),
            transaction: transaction,
          );
        }
        if (request.status == VerificationRequestStatus.open) {
          return (
            response: const AppDeliveryResponse(409, {
              'error': 'not_ready',
              'status': 'open',
              'message': 'Nobody has accepted this request yet.',
            }),
            events: events,
          );
        }
        final attempt = request.attemptId == null
            ? null
            : await ActionAttempt.db.findById(
                session,
                request.attemptId!,
                transaction: transaction,
              );
        final issued = await issueReceipt(
          session,
          request: request,
          attempt: attempt,
          now: now,
          transaction: transaction,
        );
        final token = issued.token;
        if (token == null) {
          return (
            response: const AppDeliveryResponse(503, {
              'error': 'receipts_unavailable',
              'message': 'Receipts are not available on this server yet.',
            }),
            events: events,
          );
        }
        final link = await _sharedEvidenceLink(
          session,
          request: request,
          transaction: transaction,
        );
        return (
          response: AppDeliveryResponse(200, {
            'requestId': request.id.toString(),
            'status': issued.status,
            'receipt': token,
            if (link != null)
              'evidence': {
                'url': link.toString(),
                'expiresAt': receiptTimestamp(
                  now.add(sharedEvidenceLinkLifetime),
                ),
              },
          }),
          events: events,
        );
      },
    );
    await _schedule(session, outcome.events);
    return outcome.response;
  }

  // ---------------------------------------------------------------------
  // Verily app

  /// Who is asking, for what, and exactly what will be shared.
  Future<VerificationRequestView> getRequest(
    Session session, {
    required UuidValue authUserId,
    required UuidValue requestId,
  }) async {
    final request = await VerificationRequest.db.findById(session, requestId);
    if (request == null) throw _notFound();
    final app = await VerilyApp.db.findById(session, request.appId);
    if (app == null) throw _notFound();
    return _view(session, request: request, app: app, viewer: authUserId);
  }

  /// Accepts the request for the signed-in account. Idempotent for that
  /// account; any other account is refused.
  Future<VerificationRequestView> accept(
    Session session, {
    required UuidValue authUserId,
    required UuidValue requestId,
  }) async {
    final accepted = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        await AccountAccess.requireActive(
          session,
          authUserId,
          transaction: transaction,
        );
        final now = clock().toUtc();
        final request = await _lockedRequest(session, requestId, transaction);
        final app = await VerilyApp.db.findById(
          session,
          request.appId,
          transaction: transaction,
        );
        if (app == null) throw _notFound();
        if (request.status == VerificationRequestStatus.accepted ||
            request.status == VerificationRequestStatus.completed) {
          if (request.participantAuthUserId == authUserId) {
            return (request: request, app: app);
          }
          throw _taken();
        }
        if (request.status != VerificationRequestStatus.open) {
          throw _closed(request.status);
        }
        if (!request.expiresAt.isAfter(now)) throw _expired();
        if (app.status != VerilyAppStatus.active) {
          throw AppUnavailableException(
            appName: app.name,
            message: 'This app was revoked by its creator.',
          );
        }
        final creator = await AuthUser.db.findById(
          session,
          app.creatorAuthUserId,
          transaction: transaction,
        );
        if (creator == null || creator.blocked) {
          throw AppUnavailableException(
            appName: app.name,
            message: 'This app is not available right now.',
          );
        }
        final link = await appLinkFor(
          session,
          appId: app.id!,
          authUserId: authUserId,
          now: now,
          transaction: transaction,
        );
        final wait = await rateLimiter.consume(
          session,
          appId: app.id!,
          bucket: 'verification-accept:${link.subject}',
          limit: verificationAcceptsPerHour,
          window: const Duration(hours: 1),
          now: now,
          transaction: transaction,
        );
        if (wait != null) {
          throw AppPlatformException(
            problem: AppPlatformProblem.rateLimited,
            message:
                'You have accepted many requests from this app. Try '
                'again later.',
          );
        }
        final action = await _createPrivateAction(
          session,
          request: request,
          app: app,
          now: now,
          transaction: transaction,
        );
        final attempt = await ActionAttempt.db.insertRow(
          session,
          ActionAttempt(
            actionDefinitionId: action.id!,
            participantAuthUserId: authUserId,
            periodKey: actionPeriodKey(
              action.recurrence,
              action.timeZone,
              now,
            ),
            idempotencyKey: 'verification-request:${request.id}',
            status: ActionAttemptStatus.collectingEvidence,
            startedAt: now,
            updatedAt: now,
          ),
          transaction: transaction,
        );
        final updated = await VerificationRequest.db.updateRow(
          session,
          request.copyWith(
            status: VerificationRequestStatus.accepted,
            participantAuthUserId: authUserId,
            subject: link.subject,
            actionDefinitionId: action.id,
            attemptId: attempt.id,
            acceptedAt: now,
            evidenceShared: request.shareEvidence,
            updatedAt: now,
          ),
          transaction: transaction,
        );
        return (request: updated, app: app);
      },
    );
    return _view(
      session,
      request: accepted.request,
      app: accepted.app,
      viewer: authUserId,
    );
  }

  /// Declines the request. The App receives `status=declined` and a final
  /// `verification_request.completed` event; the person is never named.
  Future<VerificationRequestRedirect> decline(
    Session session, {
    required UuidValue authUserId,
    required UuidValue requestId,
  }) async {
    final outcome = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        await AccountAccess.requireActive(
          session,
          authUserId,
          transaction: transaction,
        );
        final now = clock().toUtc();
        final request = await _lockedRequest(session, requestId, transaction);
        final events = <UuidValue>[];
        switch (request.status) {
          case VerificationRequestStatus.declined
              when request.participantAuthUserId == authUserId:
            return (request: request, events: events);
          case VerificationRequestStatus.open:
            if (!request.expiresAt.isAfter(now)) throw _expired();
          case VerificationRequestStatus.accepted
              when request.participantAuthUserId == authUserId:
            // The person changed their mind before submitting proof.
            final attempt = await ActionAttempt.db.findById(
              session,
              request.attemptId!,
              transaction: transaction,
            );
            if (attempt?.status != ActionAttemptStatus.collectingEvidence) {
              throw _closed(request.status);
            }
            await _closePrivateAction(session, request, now, transaction);
          case VerificationRequestStatus.accepted ||
              VerificationRequestStatus.completed:
            throw request.participantAuthUserId == authUserId
                ? _closed(request.status)
                : _taken();
          case VerificationRequestStatus.declined ||
              VerificationRequestStatus.expired:
            throw _closed(request.status);
        }
        final declined = await VerificationRequest.db.updateRow(
          session,
          request.copyWith(
            status: VerificationRequestStatus.declined,
            // Recorded so nobody else can act on it; never sent to the App.
            participantAuthUserId: authUserId,
            completedAt: now,
            updatedAt: now,
          ),
          transaction: transaction,
        );
        events.addAll(
          await settlement.queueCompletion(
            session,
            request: declined,
            attempt: null,
            now: now,
            transaction: transaction,
          ),
        );
        return (request: declined, events: events);
      },
    );
    await _schedule(session, outcome.events);
    return VerificationRequestRedirect(
      redirectUrl: _redirectUrl(outcome.request, {'status': 'declined'}),
    );
  }

  /// After the proof is submitted: the App's redirect with a one-time,
  /// five-minute receipt code. Calling it again issues a fresh code and
  /// invalidates the previous one. Before the proof arrives it is refused
  /// with `verificationRequestProofMissing`.
  Future<VerificationRequestRedirect> finish(
    Session session, {
    required UuidValue authUserId,
    required UuidValue requestId,
  }) async {
    final existing = await VerificationRequest.db.findById(session, requestId);
    if (existing == null || existing.participantAuthUserId != authUserId) {
      throw _notFound();
    }
    // Deterministic proof (a place check-in) is complete once submitted;
    // finish it here so the receipt is final when the App asks.
    if (existing.attemptId case final attemptId?) {
      await actions.completeIfReady(session, attemptId: attemptId);
    }
    final code = _newCode();
    final finished = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        await AccountAccess.requireActive(
          session,
          authUserId,
          transaction: transaction,
        );
        final now = clock().toUtc();
        final request = await _lockedRequest(session, requestId, transaction);
        if (request.participantAuthUserId != authUserId ||
            (request.status != VerificationRequestStatus.accepted &&
                request.status != VerificationRequestStatus.completed)) {
          throw _closed(request.status);
        }
        final attempt = await ActionAttempt.db.findById(
          session,
          request.attemptId!,
          transaction: transaction,
        );
        if (attempt == null ||
            attempt.status == ActionAttemptStatus.collectingEvidence) {
          throw _proofMissing();
        }
        return VerificationRequest.db.updateRow(
          session,
          request.copyWith(
            codeHash: secretSha256Hex(code),
            codeExpiresAt: now.add(verificationReceiptCodeLifetime),
            codeUsedAt: null,
            updatedAt: now,
          ),
          transaction: transaction,
        );
      },
    );
    return VerificationRequestRedirect(
      redirectUrl: _redirectUrl(finished, {'code': code}),
      codeExpiresAt: finished.codeExpiresAt,
    );
  }

  // ---------------------------------------------------------------------
  // Expiry

  /// Expires open requests, and accepted ones whose proof never arrived, once
  /// they pass their deadline. Accepted requests with proof submitted settle
  /// through verification instead. Returns how many expired.
  Future<int> expireDue(Session session, {required int batchSize}) async {
    if (batchSize < 1 || batchSize > 500) {
      throw ArgumentError.value(batchSize, 'batchSize');
    }
    final now = clock().toUtc();
    final rows = await session.db.unsafeQuery(
      '''
SELECT r."id"::text
FROM "verily_verification_request" AS r
LEFT JOIN "verily_action_attempt" AS a ON a."id" = r."attemptId"
WHERE r."expiresAt" <= @now
  AND (r."status" = 'open'
    OR (r."status" = 'accepted' AND a."status" = 'collectingEvidence'))
ORDER BY r."expiresAt"
LIMIT @limit;
''',
      parameters: QueryParameters.named({'now': now, 'limit': batchSize}),
    );
    var expired = 0;
    for (final row in rows) {
      final id = UuidValue.withValidation(row[0]! as String);
      final outcome = await DatabaseUtil.runInTransactionOrSavepoint(
        session.db,
        null,
        (transaction) async {
          final request = await VerificationRequest.db.findById(
            session,
            id,
            transaction: transaction,
            lockMode: LockMode.forUpdate,
          );
          if (request == null) return null;
          final app = await VerilyApp.db.findById(
            session,
            request.appId,
            transaction: transaction,
          );
          if (app == null) return null;
          return _expireIfDue(
            session,
            request: request,
            app: app,
            now: clock().toUtc(),
            transaction: transaction,
          );
        },
      );
      if (outcome != null) {
        expired += 1;
        await _schedule(session, outcome.events);
      }
    }
    return expired;
  }

  // ---------------------------------------------------------------------
  // Helpers

  /// Expires [request] inside [transaction] when it is past its deadline
  /// and no proof arrived. Returns the expired row and queued events, or
  /// null when it is not due.
  Future<({VerificationRequest request, List<UuidValue> events})?> _expireIfDue(
    Session session, {
    required VerificationRequest request,
    required VerilyApp app,
    required DateTime now,
    required Transaction transaction,
  }) async {
    if (request.expiresAt.isAfter(now)) return null;
    if (request.status == VerificationRequestStatus.accepted) {
      final attempt = await ActionAttempt.db.findById(
        session,
        request.attemptId!,
        transaction: transaction,
      );
      if (attempt?.status != ActionAttemptStatus.collectingEvidence) {
        return null;
      }
      await _closePrivateAction(session, request, now, transaction);
    } else if (request.status != VerificationRequestStatus.open) {
      return null;
    }
    final expired = await VerificationRequest.db.updateRow(
      session,
      request.copyWith(
        status: VerificationRequestStatus.expired,
        completedAt: now,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    final events = await settlement.queueCompletion(
      session,
      request: expired,
      attempt: null,
      now: now,
      transaction: transaction,
      app: app,
    );
    return (request: expired, events: events);
  }

  Future<ActionDefinition> _createPrivateAction(
    Session session, {
    required VerificationRequest request,
    required VerilyApp app,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final drafts = [
      _primaryRequirement(request),
      if (request.kind != VerificationRequestKind.location &&
          request.placeLatitude != null)
        _placeRequirement(request, isRequired: false),
    ];
    final validated = [
      for (var index = 0; index < drafts.length; index += 1)
        validateRequirementDraft(drafts[index], index),
    ];
    final title = 'Verification for ${app.name}';
    final action = await ActionDefinition.db.insertRow(
      session,
      ActionDefinition(
        creatorAuthUserId: app.creatorAuthUserId,
        actionKey: _privateActionKey(),
        revision: 1,
        title: title.length > 120 ? title.substring(0, 120) : title,
        description:
            request.instructions ??
            'A one-time check requested by ${app.name}.',
        status: ActionDefinitionStatus.active,
        recurrence: ActionRecurrence.once,
        timeZone: 'UTC',
        maxVerifiedCompletions: 1,
        closesAt: request.expiresAt,
        publishedAt: now,
        visibility: ActionVisibility.verificationRequest,
        createdAt: now,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    for (final item in validated) {
      final requirement = await ActionRequirement.db.insertRow(
        session,
        ActionRequirement(
          actionDefinitionId: action.id!,
          requirementKey: item.key,
          kind: item.draft.kind,
          title: item.title,
          instructions: item.instructions,
          position: item.position,
          isRequired: item.draft.isRequired,
        ),
        transaction: transaction,
      );
      await insertRequirementRule(
        session,
        requirement.id!,
        item,
        transaction,
      );
    }
    return action;
  }

  ActionRequirementDraft _primaryRequirement(VerificationRequest request) {
    final instructions =
        request.instructions ?? 'Capture it live in Verily, in one take.';
    final prompt = request.check == VerificationRequestCheck.content
        ? verificationRequestPrompt(request.instructions!)
        : captureOnlyVerificationPrompt;
    return switch (request.kind) {
      VerificationRequestKind.location => _placeRequirement(
        request,
        isRequired: true,
      ),
      VerificationRequestKind.photo => ActionRequirementDraft(
        requirementKey: 'capture',
        kind: ActionRequirementKind.photo,
        title: 'Take a photo',
        instructions: instructions,
        isRequired: true,
        verificationPrompt: prompt,
        minConfidence: 0.8,
        verificationPolicy: ActionVerificationPolicy.singleModel,
        spokenChallengeRequired: false,
      ),
      VerificationRequestKind.video ||
      VerificationRequestKind.audio => ActionRequirementDraft(
        requirementKey: 'capture',
        kind: request.kind == VerificationRequestKind.video
            ? ActionRequirementKind.video
            : ActionRequirementKind.audio,
        title: request.kind == VerificationRequestKind.video
            ? 'Record a video'
            : 'Record audio',
        instructions: instructions,
        isRequired: true,
        verificationPrompt: prompt,
        minDurationSeconds: minRecordingSeconds,
        maxDurationSeconds: 120,
        minConfidence: 0.8,
        verificationPolicy: ActionVerificationPolicy.singleModel,
        spokenChallengeRequired: request.spokenChallenge,
      ),
    };
  }

  ActionRequirementDraft _placeRequirement(
    VerificationRequest request, {
    required bool isRequired,
  }) {
    final radius = request.placeRadiusMeters!;
    return ActionRequirementDraft(
      requirementKey: 'place',
      kind: ActionRequirementKind.location,
      title: 'Check in at the place',
      instructions: 'Share your location where you were asked to be.',
      isRequired: isRequired,
      latitude: request.placeLatitude,
      longitude: request.placeLongitude,
      radiusMeters: radius,
      maxAccuracyMeters: math.min(100, math.max(25, radius)).toDouble(),
    );
  }

  Future<void> _closePrivateAction(
    Session session,
    VerificationRequest request,
    DateTime now,
    Transaction transaction,
  ) async {
    final actionId = request.actionDefinitionId;
    if (actionId == null) return;
    await ActionDefinition.db.updateWhere(
      session,
      columnValues: (table) => [
        table.status(ActionDefinitionStatus.paused),
        table.pausedAt(now),
        table.updatedAt(now),
      ],
      where: (table) =>
          table.id.equals(actionId) &
          table.status.equals(ActionDefinitionStatus.active),
      transaction: transaction,
      noReturn: true,
    );
  }

  Future<VerificationRequestView> _view(
    Session session, {
    required VerificationRequest request,
    required VerilyApp app,
    required UuidValue viewer,
  }) async {
    final now = clock().toUtc();
    final effectiveStatus =
        !request.expiresAt.isAfter(now) &&
            request.status == VerificationRequestStatus.open
        ? VerificationRequestStatus.expired
        : request.status;
    final ownAction =
        request.participantAuthUserId == viewer &&
        request.actionDefinitionId != null &&
        (request.status == VerificationRequestStatus.accepted ||
            request.status == VerificationRequestStatus.completed);
    final action = ownAction
        ? await ActionDefinition.db.findById(
            session,
            request.actionDefinitionId!,
          )
        : null;
    return VerificationRequestView(
      id: request.id!,
      appId: app.id!,
      appName: app.name,
      appWebsiteUrl: app.websiteUrl,
      kind: request.kind,
      instructions: request.instructions,
      check: request.check,
      checksPlace: request.placeLatitude != null,
      spokenChallenge: request.spokenChallenge,
      shareEvidence: request.shareEvidence,
      status: effectiveStatus,
      declinedByViewer:
          request.status == VerificationRequestStatus.declined &&
          request.participantAuthUserId == viewer,
      expiresAt: request.expiresAt,
      action: action == null
          ? null
          : await views.opportunity(
              session,
              action: action,
              viewerAuthUserId: viewer,
            ),
    );
  }

  Future<VerificationRequest> _lockedRequest(
    Session session,
    UuidValue requestId,
    Transaction transaction,
  ) async {
    final request = await VerificationRequest.db.findById(
      session,
      requestId,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (request == null) throw _notFound();
    return request;
  }

  Future<Uri?> _sharedEvidenceLink(
    Session session, {
    required VerificationRequest request,
    required Transaction transaction,
  }) async {
    if (!request.shareEvidence || !request.evidenceShared) return null;
    final proofs = await loadReceiptProofs(
      session,
      request: request,
      transaction: transaction,
    );
    final evidence = proofs.primary?.evidence;
    final path = evidence?.storagePath;
    final version = evidence?.storageVersionId;
    if (path == null || version == null) return null;
    final storage = session.serverpod.storage[evidenceStorageId];
    if (storage is! EvidenceObjectAccess) return null;
    return (storage! as EvidenceObjectAccess).createReviewUrl(
      session,
      path,
      versionId: version,
      expiration: sharedEvidenceLinkLifetime,
    );
  }

  Future<void> _schedule(Session session, List<UuidValue> events) async {
    for (final event in events) {
      await outbox.schedule(session, event);
    }
  }

  String _privateActionKey() {
    final hex = [
      for (var index = 0; index < 10; index += 1)
        _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
    return 'vr-$hex';
  }

  String _newCode() => base64Url
      .encode([
        for (var index = 0; index < 32; index += 1) _random.nextInt(256),
      ])
      .replaceAll('=', '');

  /// The App's exact redirect URI with `request_id`, `state`, and [extra].
  String _redirectUrl(
    VerificationRequest request,
    Map<String, String> extra,
  ) {
    final parameters = {
      'request_id': request.id.toString(),
      'state': ?request.state,
      ...extra,
    };
    final query = [
      for (final entry in parameters.entries)
        '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
    ].join('&');
    final separator = request.redirectUri.contains('?') ? '&' : '?';
    return '${request.redirectUri}$separator$query';
  }
}

/// `{}` or `{"code": "<code>"}`; anything else is a [FormatException].
String? _receiptCode(String body) {
  final decoded = body.trim().isEmpty ? <String, Object?>{} : jsonDecode(body);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('Receipt bodies are objects.');
  }
  if (decoded.isEmpty) return null;
  final code = decoded['code'];
  if (decoded.length != 1 ||
      code is! String ||
      !RegExp(r'^[A-Za-z0-9_-]{16,128}$').hasMatch(code)) {
    throw const FormatException('Receipt bodies carry only a code.');
  }
  return code;
}

AppPlatformException _notFound() => AppPlatformException(
  problem: AppPlatformProblem.verificationRequestNotFound,
  message: 'This verification request was not found.',
);

AppPlatformException _taken() => AppPlatformException(
  problem: AppPlatformProblem.verificationRequestTaken,
  message: 'Someone else already accepted this verification request.',
);

AppPlatformException _expired() => AppPlatformException(
  problem: AppPlatformProblem.verificationRequestExpired,
  message: 'This verification request has expired. Ask the app for a new one.',
);

AppPlatformException _proofMissing() => AppPlatformException(
  problem: AppPlatformProblem.verificationRequestProofMissing,
  message: 'Send your proof before returning to the app.',
);

AppPlatformException _closed(VerificationRequestStatus status) =>
    AppPlatformException(
      problem: AppPlatformProblem.verificationRequestClosed,
      message: switch (status) {
        VerificationRequestStatus.declined => 'This request was declined.',
        VerificationRequestStatus.expired => 'This request has expired.',
        _ => 'This request can no longer change.',
      },
    );
