// Generated copyWith clears nullable fields with an explicit null.
// ignore_for_file: avoid_redundant_argument_values

import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/account/account_access.dart';
import 'package:verily_server/src/action_verification/action_verification_service.dart';
import 'package:verily_server/src/action_verification/action_views.dart';
import 'package:verily_server/src/action_verification/public_reasons.dart';
import 'package:verily_server/src/apps/app_confirmation_payload.dart';
import 'package:verily_server/src/apps/app_rate_limiter.dart';
import 'package:verily_server/src/apps/app_subjects.dart';
import 'package:verily_server/src/apps/external_confirmation.dart';
import 'package:verily_server/src/apps/webhooks/app_event_outbox.dart';
import 'package:verily_server/src/apps/webhooks/webhook_sender.dart';
import 'package:verily_server/src/apps/webhooks/webhook_signing.dart';
import 'package:verily_server/src/generated/future_calls.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/moderation/moderation_gate.dart';
import 'package:verily_server/src/rewards/reward_payout_service.dart';

/// Budget for one `attempt.verify` call, connection and response included.
const appPullCallTimeout = Duration(seconds: 10);

/// A check that gets no decisive answer within this window expires.
const appPullCheckLifetime = Duration(hours: 24);

/// Calls per check before it stops as `failed`; the participant may start
/// it again, while the 24-hour expiry still bounds the whole attempt.
const appPullMaxCalls = 12;

/// A call that has held its lease this long is presumed lost. It exceeds
/// the call budget, so a live call is never claimed twice.
const appPullCallLease = Duration(seconds: 30);

/// Largest App answer read, in bytes.
const appPullMaxResponseBytes = 4096;

/// Participant-initiated calls per App and pairwise subject per hour.
const appPullCallsPerSubjectPerHour = 20;

/// Decision recorded for pull verdicts.
const appPullVerifierType = 'verily-app-pull';

/// Backoff before the next call after [failedCalls] failures: 30 s doubling,
/// capped at one hour.
Duration appPullRetryDelay(int failedCalls) => Duration(
  seconds: math.min(30 * (1 << (failedCalls - 1).clamp(0, 20)), 3600),
);

final RegExp _referencePattern = RegExp(
  r'^[\p{L}\p{N} ._@#:/+\-]{1,120}$',
  unicode: true,
);
final RegExp _reasonPattern = RegExp(r'^[a-z0-9_]{1,64}$');

/// Validates the optional text a participant typed for the App (a username
/// or an order number). Surrounding whitespace is trimmed; an empty value
/// means none. Only letters, digits, spaces, and `._@#:/+-` are accepted, so
/// control, format, and bidirectional characters never reach an App.
String? validatePullReference(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  if (!_referencePattern.hasMatch(trimmed)) {
    throw AppPlatformException(
      problem: AppPlatformProblem.invalidReference,
      message:
          'Use up to 120 letters, numbers, spaces, or the characters . _ @ # '
          ': / + -.',
    );
  }
  return trimmed;
}

/// An App's decisive or pending answer to `attempt.verify`.
enum AppPullVerdict { accepted, rejected, pending }

/// One strictly parsed call result: a verdict, or a stable failure code.
final class AppPullAnswer {
  const AppPullAnswer.verdict(AppPullVerdict this.verdict, {this.reason})
    : errorCode = null;

  const AppPullAnswer.failed(String this.errorCode)
    : verdict = null,
      reason = null;

  final AppPullVerdict? verdict;
  final String? reason;
  final String? errorCode;

  bool get succeeded => verdict != null;
}

/// Parses an App's answer. Only HTTP 200 with a JSON object holding exactly
/// `verdict` (accepted, rejected, or pending) and an optional short `reason`
/// code counts. Anything else is a failed call, never an acceptance.
AppPullAnswer parsePullAnswer(WebhookCallResult result) {
  if (result.errorCode case final code?) return AppPullAnswer.failed(code);
  final status = result.statusCode;
  if (status != 200) return AppPullAnswer.failed('http_${status ?? 0}');
  final body = result.responseBody;
  if (body == null) return const AppPullAnswer.failed('invalid_response');
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    return const AppPullAnswer.failed('invalid_response');
  }
  if (decoded is! Map<String, Object?> ||
      !decoded.containsKey('verdict') ||
      decoded.keys.any((key) => key != 'verdict' && key != 'reason')) {
    return const AppPullAnswer.failed('invalid_response');
  }
  final verdict = switch (decoded['verdict']) {
    'accepted' => AppPullVerdict.accepted,
    'rejected' => AppPullVerdict.rejected,
    'pending' => AppPullVerdict.pending,
    _ => null,
  };
  if (verdict == null) return const AppPullAnswer.failed('invalid_response');
  final reason = decoded['reason'];
  if (decoded.containsKey('reason') &&
      (reason is! String || !_reasonPattern.hasMatch(reason))) {
    return const AppPullAnswer.failed('invalid_response');
  }
  return AppPullAnswer.verdict(verdict, reason: reason as String?);
}

/// Schedules a retry call for a check. Injectable for tests.
typedef AppPullCheckScheduler = Future<void> Function(
  Session session,
  UuidValue checkId,
  Duration delay,
);

Future<void> _futureCallScheduler(
  Session session,
  UuidValue checkId,
  Duration delay,
) async {
  try {
    await session.serverpod.futureCalls
        .callWithDelay(delay)
        .appPullCheck
        .check(AppPullCheckTask(checkId: checkId));
  } on Object catch (error, stackTrace) {
    // Recovery calls any due check whose schedule was missed.
    session.log(
      'Failed to schedule pull check $checkId.',
      level: LogLevel.warning,
      exception: error,
      stackTrace: stackTrace,
    );
  }
}

/// Pull verification of `externalApp` requirements: when a participant says
/// they are done, Verily asks the App's webhook (`attempt.verify`).
///
/// Each call is claimed under the App row lock with a short lease, made
/// outside every transaction within a 10-second budget, logged append-only,
/// and settled in a second transaction. `accepted` and `rejected` record a
/// decision and complete the attempt; `pending` waits for a push that names
/// the attempt; anything else is a failed call, retried with backoff and
/// never treated as acceptance. A check with no decisive answer after 24
/// hours expires and rejects the requirement.
///
/// Lock order: App row, check row, participant account, attempt, action key.
class AppPullCheckService {
  AppPullCheckService({
    ActionVerificationService? actions,
    RewardPayoutService? payouts,
    WebhookSender? sender,
    WebhookSecrets? Function()? secrets,
    AppPullCheckScheduler? scheduler,
    this.rateLimiter = const AppRateLimiter(),
    this.moderationGate = const ModerationGate(),
    DateTime Function()? clock,
  }) : clock = clock ?? (() => DateTime.now().toUtc()),
       actions = actions ?? ActionVerificationService(clock: clock),
       payouts = payouts ?? RewardPayoutService(clock: clock),
       sender = sender ?? PinnedAddressWebhookSender(),
       secrets = secrets ?? (() => WebhookSecrets.configured),
       scheduler = scheduler ?? _futureCallScheduler;

  final DateTime Function() clock;
  final ActionVerificationService actions;
  final RewardPayoutService payouts;
  final WebhookSender sender;
  final WebhookSecrets? Function() secrets;
  final AppPullCheckScheduler scheduler;
  final AppRateLimiter rateLimiter;
  final ModerationGate moderationGate;

  /// The participant's "I did it" for one pull requirement.
  Future<EvidenceSubmissionResult> requestVerification(
    Session session, {
    required UuidValue authUserId,
    required UuidValue attemptId,
    required UuidValue requirementId,
    String? reference,
  }) async {
    final normalizedReference = validatePullReference(reference);
    final target = await _pullTarget(
      session,
      authUserId: authUserId,
      attemptId: attemptId,
      requirementId: requirementId,
    );
    final claim = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) => _claimForParticipant(
        session,
        target: target,
        authUserId: authUserId,
        reference: normalizedReference,
        transaction: transaction,
      ),
    );
    if (claim != null) await _callAndSettle(session, claim);
    return _result(session, target);
  }

  /// Runs one due `attempt.verify` call for [checkId]; a no-op unless the
  /// check is due and unclaimed.
  Future<void> callApp(Session session, UuidValue checkId) async {
    final claim = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) => _claimDue(session, checkId, transaction),
    );
    if (claim != null) await _callAndSettle(session, claim);
  }

  /// Schedules due retries and abandoned calls, and expires checks past
  /// their deadline. Returns how many checks it acted on.
  Future<int> recover(Session session, {required int batchSize}) async {
    if (batchSize < 1 || batchSize > 500) {
      throw ArgumentError.value(batchSize, 'batchSize');
    }
    final now = clock().toUtc();
    const open = {
      AppPullCheckStatus.calling,
      AppPullCheckStatus.waiting,
      AppPullCheckStatus.retrying,
    };
    final expired = await AppPullCheck.db.find(
      session,
      where: (table) => table.status.inSet(open) & (table.expiresAt <= now),
      orderBy: (table) => table.expiresAt,
      limit: batchSize,
    );
    for (final check in expired) {
      await DatabaseUtil.runInTransactionOrSavepoint(
        session.db,
        null,
        (transaction) => _expireIfDue(session, check.id!, transaction),
      );
    }
    final due = await AppPullCheck.db.find(
      session,
      where: (table) =>
          (table.status.equals(AppPullCheckStatus.retrying) &
              (table.nextCallAt <= now)) |
          (table.status.equals(AppPullCheckStatus.calling) &
              (table.leaseExpiresAt <= now)),
      orderBy: (table) => table.nextCallAt,
      limit: batchSize,
    );
    for (final check in due) {
      await scheduler(session, check.id!, Duration.zero);
    }
    return expired.length + due.length;
  }

  /// Settles an open check from a push confirmation that names its attempt.
  /// Runs inside the confirmation transaction, which holds the App row lock.
  Future<ExternalConfirmation> confirmFromPush(
    Session session, {
    required Transaction transaction,
    required VerilyApp app,
    required VerilyAppLink link,
    required AppConfirmationPayload payload,
  }) async {
    final attemptId = UuidValue.withValidation(payload.attemptId!);
    final attempt = await ActionAttempt.db.findById(
      session,
      attemptId,
      transaction: transaction,
    );
    final action = attempt == null
        ? null
        : await ActionDefinition.db.findById(
            session,
            attempt.actionDefinitionId,
            transaction: transaction,
          );
    if (attempt == null ||
        action == null ||
        attempt.participantAuthUserId != link.authUserId ||
        action.creatorAuthUserId != app.creatorAuthUserId ||
        action.actionKey != payload.actionKey) {
      return const ExternalConfirmationRejected(
        ExternalConfirmationRejection.unknownAttempt,
      );
    }
    final check = await AppPullCheck.db.findFirstRow(
      session,
      where: (table) =>
          table.attemptId.equals(attemptId) & table.appId.equals(app.id),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (check != null && check.status == AppPullCheckStatus.accepted) {
      return ExternalConfirmationAccepted(
        actionDefinitionId: action.id!,
        attempt: attemptView(attempt),
        alreadyComplete: true,
      );
    }
    if (check == null ||
        !{
          AppPullCheckStatus.calling,
          AppPullCheckStatus.waiting,
          AppPullCheckStatus.retrying,
        }.contains(check.status)) {
      return ExternalConfirmationRejected(
        ExternalConfirmationRejection.noOpenPullCheck,
        actionDefinitionId: action.id,
      );
    }
    final outcome = await actions.applyAppVerdict(
      session,
      transaction: transaction,
      app: app,
      attemptId: attemptId,
      requirementId: check.requirementId,
      accepted: true,
      verifierType: appConfirmationVerifierType,
      reasonCode: 'app_confirmed',
      eventDigest: payload.digest,
      occurredAt: payload.occurredAt,
    );
    final now = clock().toUtc();
    if (!outcome.applied) {
      if (outcome.attempt?.status == ActionAttemptStatus.verified) {
        return ExternalConfirmationAccepted(
          actionDefinitionId: action.id!,
          attempt: outcome.attempt!,
          alreadyComplete: true,
        );
      }
      return ExternalConfirmationRejected(
        ExternalConfirmationRejection.actionUnavailable,
        actionDefinitionId: action.id,
      );
    }
    await AppPullCheck.db.updateRow(
      session,
      check.copyWith(
        status: AppPullCheckStatus.accepted,
        reasonCode: 'app_confirmed',
        nextCallAt: null,
        leaseExpiresAt: null,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    return ExternalConfirmationAccepted(
      actionDefinitionId: action.id!,
      attempt: outcome.attempt!,
      alreadyComplete: false,
    );
  }

  Future<_PullTarget> _pullTarget(
    Session session, {
    required UuidValue authUserId,
    required UuidValue attemptId,
    required UuidValue requirementId,
  }) async {
    final attempt = await ActionAttempt.db.findById(session, attemptId);
    if (attempt == null || attempt.participantAuthUserId != authUserId) {
      throw StateError('The action attempt was not found.');
    }
    final requirement = await ActionRequirement.db.findById(
      session,
      requirementId,
    );
    if (requirement == null ||
        requirement.actionDefinitionId != attempt.actionDefinitionId) {
      throw StateError('The requirement does not belong to this attempt.');
    }
    final rule = requirement.kind == ActionRequirementKind.externalApp
        ? await ActionExternalRule.db.findFirstRow(
            session,
            where: (table) => table.requirementId.equals(requirementId),
          )
        : null;
    if (rule == null || rule.verificationMode != AppVerificationMode.pull) {
      throw AppPlatformException(
        problem: AppPlatformProblem.pullVerificationUnavailable,
        message: 'This proof is confirmed by the app on its own.',
      );
    }
    return _PullTarget(
      attemptId: attemptId,
      requirementId: requirementId,
      appId: rule.appId,
    );
  }

  Future<_CallClaim?> _claimForParticipant(
    Session session, {
    required _PullTarget target,
    required UuidValue authUserId,
    required String? reference,
    required Transaction transaction,
  }) async {
    final app = await VerilyApp.db.findById(
      session,
      target.appId,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (app == null ||
        app.status != VerilyAppStatus.active ||
        app.webhookUrl == null ||
        app.webhookSecretVersion < 1) {
      throw AppPlatformException(
        problem: AppPlatformProblem.pullVerificationUnavailable,
        message: 'This app cannot confirm proof right now.',
      );
    }
    final now = clock().toUtc();
    final existing = await AppPullCheck.db.findFirstRow(
      session,
      where: (table) =>
          table.attemptId.equals(target.attemptId) &
          table.requirementId.equals(target.requirementId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    await AccountAccess.requireActive(
      session,
      authUserId,
      transaction: transaction,
    );
    final attempt = await ActionAttempt.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(target.attemptId) &
          table.participantAuthUserId.equals(authUserId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (attempt == null) throw StateError('The action attempt was not found.');
    if (attempt.status != ActionAttemptStatus.collectingEvidence) {
      throw StateError('This action attempt no longer accepts proof.');
    }
    await moderationGate.assertActionAllowed(
      session,
      actionId: attempt.actionDefinitionId,
      transaction: transaction,
    );
    if (existing != null) {
      switch (existing.status) {
        // Final, or the App is already deciding: never call twice.
        case AppPullCheckStatus.accepted ||
            AppPullCheckStatus.rejected ||
            AppPullCheckStatus.waiting:
          return null;
        case AppPullCheckStatus.calling
            when existing.leaseExpiresAt != null &&
                existing.leaseExpiresAt!.isAfter(now):
          return null;
        case AppPullCheckStatus.calling ||
            AppPullCheckStatus.retrying ||
            AppPullCheckStatus.failed ||
            AppPullCheckStatus.expired:
          break;
      }
    }
    final link = await appLinkFor(
      session,
      appId: app.id!,
      authUserId: authUserId,
      now: now,
      transaction: transaction,
    );
    final retryAfter = await rateLimiter.consume(
      session,
      appId: app.id!,
      bucket: 'pull-verify:${link.subject}',
      limit: appPullCallsPerSubjectPerHour,
      window: const Duration(hours: 1),
      now: now,
      transaction: transaction,
    );
    if (retryAfter != null) {
      throw AppPlatformException(
        problem: AppPlatformProblem.rateLimited,
        message: 'Please wait a little before asking the app again.',
      );
    }
    final restart =
        existing == null ||
        existing.status == AppPullCheckStatus.failed ||
        existing.status == AppPullCheckStatus.expired;
    final AppPullCheck check;
    if (existing == null) {
      check = await AppPullCheck.db.insertRow(
        session,
        AppPullCheck(
          attemptId: target.attemptId,
          requirementId: target.requirementId,
          appId: app.id!,
          eventId: newWebhookEventId(),
          reference: reference,
          status: AppPullCheckStatus.calling,
          callCount: 1,
          leaseExpiresAt: now.add(appPullCallLease),
          expiresAt: now.add(appPullCheckLifetime),
          createdAt: now,
          updatedAt: now,
        ),
        transaction: transaction,
      );
    } else {
      check = await AppPullCheck.db.updateRow(
        session,
        existing.copyWith(
          eventId: restart ? newWebhookEventId() : existing.eventId,
          reference: reference,
          status: AppPullCheckStatus.calling,
          callCount: restart ? 1 : existing.callCount + 1,
          nextCallAt: null,
          leaseExpiresAt: now.add(appPullCallLease),
          lastErrorCode: restart ? null : existing.lastErrorCode,
          reasonCode: null,
          expiresAt: restart
              ? now.add(appPullCheckLifetime)
              : existing.expiresAt,
          createdAt: restart ? now : existing.createdAt,
          updatedAt: now,
        ),
        transaction: transaction,
      );
    }
    return _claimFor(session, app, check, link, transaction, now);
  }

  Future<_CallClaim?> _claimDue(
    Session session,
    UuidValue checkId,
    Transaction transaction,
  ) async {
    final unlocked = await AppPullCheck.db.findById(
      session,
      checkId,
      transaction: transaction,
    );
    if (unlocked == null) return null;
    final app = await VerilyApp.db.findById(
      session,
      unlocked.appId,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    final check = await AppPullCheck.db.findById(
      session,
      checkId,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (app == null || check == null) return null;
    final now = clock().toUtc();
    final due = switch (check.status) {
      AppPullCheckStatus.retrying =>
        check.nextCallAt == null ||
            !check.nextCallAt!.isAfter(now.add(const Duration(seconds: 1))),
      AppPullCheckStatus.calling =>
        check.leaseExpiresAt == null || !check.leaseExpiresAt!.isAfter(now),
      _ => false,
    };
    if (!due) return null;
    if (!now.isBefore(check.expiresAt)) {
      await _expire(session, app, check, now, transaction);
      return null;
    }
    final attempt = await ActionAttempt.db.findById(
      session,
      check.attemptId,
      transaction: transaction,
    );
    if (attempt == null ||
        app.status != VerilyAppStatus.active ||
        app.webhookUrl == null ||
        app.webhookSecretVersion < 1) {
      await AppPullCheck.db.updateRow(
        session,
        check.copyWith(
          status: AppPullCheckStatus.failed,
          nextCallAt: null,
          leaseExpiresAt: null,
          lastErrorCode: 'app_unavailable',
          updatedAt: now,
        ),
        transaction: transaction,
      );
      return null;
    }
    final link = await appLinkFor(
      session,
      appId: app.id!,
      authUserId: attempt.participantAuthUserId,
      now: now,
      transaction: transaction,
    );
    final claimed = await AppPullCheck.db.updateRow(
      session,
      check.copyWith(
        status: AppPullCheckStatus.calling,
        callCount: check.callCount + 1,
        nextCallAt: null,
        leaseExpiresAt: now.add(appPullCallLease),
        updatedAt: now,
      ),
      transaction: transaction,
    );
    return _claimFor(session, app, claimed, link, transaction, now);
  }

  Future<_CallClaim?> _claimFor(
    Session session,
    VerilyApp app,
    AppPullCheck check,
    VerilyAppLink link,
    Transaction transaction,
    DateTime now,
  ) async {
    final attempt = await ActionAttempt.db.findById(
      session,
      check.attemptId,
      transaction: transaction,
    );
    final action = attempt == null
        ? null
        : await ActionDefinition.db.findById(
            session,
            attempt.actionDefinitionId,
            transaction: transaction,
          );
    if (attempt == null || action == null) return null;
    return _CallClaim(
      app: app,
      check: check,
      body: jsonEncode({
        'id': check.eventId,
        'type': AppEventType.attemptVerify,
        'attempt': attempt.id.toString(),
        'action': action.actionKey,
        'subject': link.subject,
        'reference': check.reference,
        'requestedAt': now.toIso8601String(),
      }),
      requestedAt: now,
    );
  }

  Future<void> _callAndSettle(Session session, _CallClaim claim) async {
    final now = clock().toUtc();
    final signing =
        secrets()?.signingSecretsFor(claim.app, now) ?? const <String>[];
    final webhookUrl = claim.app.webhookUrl;
    final WebhookCallResult result;
    if (webhookUrl == null) {
      result = const WebhookCallResult(
        duration: Duration.zero,
        errorCode: 'webhook_not_configured',
      );
    } else if (signing.isEmpty) {
      result = const WebhookCallResult(
        duration: Duration.zero,
        errorCode: 'signing_unavailable',
      );
    } else {
      result = await sender.post(
        url: Uri.parse(webhookUrl),
        headers: {
          'verily-event': AppEventType.attemptVerify,
          'verily-event-id': claim.check.eventId,
          'verily-signature': webhookSignatureHeader(
            timestamp: now.millisecondsSinceEpoch ~/ 1000,
            body: claim.body,
            secrets: signing,
          ),
        },
        body: claim.body,
        timeout: appPullCallTimeout,
        maxResponseBytes: appPullMaxResponseBytes,
      );
    }
    final answer = parsePullAnswer(result);
    final settled = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) => _settle(session, claim, result, answer, transaction),
    );
    if (settled.retryDelay case final delay?) {
      await scheduler(session, claim.check.id!, delay);
    }
    if (settled.completed) {
      await payouts.scheduleForAttempt(
        session,
        attemptId: claim.check.attemptId,
      );
    }
  }

  Future<({Duration? retryDelay, bool completed})> _settle(
    Session session,
    _CallClaim claim,
    WebhookCallResult result,
    AppPullAnswer answer,
    Transaction transaction,
  ) async {
    const finished = (retryDelay: null, completed: false);
    await AppWebhookDelivery.db.insertRow(
      session,
      AppWebhookDelivery(
        appId: claim.app.id!,
        eventId: claim.check.eventId,
        eventType: AppEventType.attemptVerify,
        attemptNumber: claim.check.callCount,
        requestedAt: claim.requestedAt,
        durationMilliseconds: result.duration.inMilliseconds,
        statusCode: result.statusCode,
        errorCode: answer.errorCode,
        succeeded: answer.succeeded,
      ),
      transaction: transaction,
    );
    final app = await VerilyApp.db.findById(
      session,
      claim.app.id!,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    final check = await AppPullCheck.db.findById(
      session,
      claim.check.id!,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    // A push settled the check meanwhile, or another worker reclaimed it.
    if (app == null ||
        check == null ||
        check.status != AppPullCheckStatus.calling ||
        check.callCount != claim.check.callCount ||
        check.eventId != claim.check.eventId) {
      return finished;
    }
    final now = clock().toUtc();
    switch (answer.verdict) {
      case AppPullVerdict.accepted || AppPullVerdict.rejected:
        final accepted = answer.verdict == AppPullVerdict.accepted;
        final reason =
            answer.reason ?? (accepted ? 'app_confirmed' : 'app_not_confirmed');
        final outcome = await actions.applyAppVerdict(
          session,
          transaction: transaction,
          app: app,
          attemptId: check.attemptId,
          requirementId: check.requirementId,
          accepted: accepted,
          verifierType: appPullVerifierType,
          reasonCode: reason,
          eventDigest: _verdictDigest(check.eventId, answer),
          occurredAt: now,
        );
        await AppPullCheck.db.updateRow(
          session,
          check.copyWith(
            status: outcome.applied
                ? (accepted
                      ? AppPullCheckStatus.accepted
                      : AppPullCheckStatus.rejected)
                : AppPullCheckStatus.failed,
            reasonCode: reason,
            lastErrorCode: outcome.applied ? null : outcome.code,
            nextCallAt: null,
            leaseExpiresAt: null,
            updatedAt: now,
          ),
          transaction: transaction,
        );
        return (retryDelay: null, completed: outcome.applied && accepted);
      case AppPullVerdict.pending:
        await AppPullCheck.db.updateRow(
          session,
          check.copyWith(
            status: AppPullCheckStatus.waiting,
            reasonCode: answer.reason,
            lastErrorCode: null,
            nextCallAt: null,
            leaseExpiresAt: null,
            updatedAt: now,
          ),
          transaction: transaction,
        );
        return finished;
      case null:
        if (!now.isBefore(check.expiresAt)) {
          await _expire(session, app, check, now, transaction);
          return finished;
        }
        final exhausted = check.callCount >= appPullMaxCalls;
        // The last retry never lands after the deadline: at the deadline the
        // due call expires the check instead.
        final backoff = now.add(appPullRetryDelay(check.callCount));
        final nextCallAt = backoff.isBefore(check.expiresAt)
            ? backoff
            : check.expiresAt;
        await AppPullCheck.db.updateRow(
          session,
          check.copyWith(
            status: exhausted
                ? AppPullCheckStatus.failed
                : AppPullCheckStatus.retrying,
            lastErrorCode: answer.errorCode,
            nextCallAt: exhausted ? null : nextCallAt,
            leaseExpiresAt: null,
            updatedAt: now,
          ),
          transaction: transaction,
        );
        return exhausted
            ? finished
            : (retryDelay: nextCallAt.difference(now), completed: false);
    }
  }

  Future<void> _expireIfDue(
    Session session,
    UuidValue checkId,
    Transaction transaction,
  ) async {
    final unlocked = await AppPullCheck.db.findById(
      session,
      checkId,
      transaction: transaction,
    );
    if (unlocked == null) return;
    final app = await VerilyApp.db.findById(
      session,
      unlocked.appId,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    final check = await AppPullCheck.db.findById(
      session,
      checkId,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    final now = clock().toUtc();
    if (app == null ||
        check == null ||
        now.isBefore(check.expiresAt) ||
        !{
          AppPullCheckStatus.calling,
          AppPullCheckStatus.waiting,
          AppPullCheckStatus.retrying,
        }.contains(check.status)) {
      return;
    }
    await _expire(session, app, check, now, transaction);
  }

  /// Rejects the requirement: the App gave no decisive answer in 24 hours.
  Future<void> _expire(
    Session session,
    VerilyApp app,
    AppPullCheck check,
    DateTime now,
    Transaction transaction,
  ) async {
    await actions.applyAppVerdict(
      session,
      transaction: transaction,
      app: app,
      attemptId: check.attemptId,
      requirementId: check.requirementId,
      accepted: false,
      verifierType: appPullVerifierType,
      reasonCode: 'app_verification_expired',
      eventDigest: _digest('${check.eventId}|expired'),
      occurredAt: now,
    );
    await AppPullCheck.db.updateRow(
      session,
      check.copyWith(
        status: AppPullCheckStatus.expired,
        reasonCode: 'app_verification_expired',
        nextCallAt: null,
        leaseExpiresAt: null,
        updatedAt: now,
      ),
      transaction: transaction,
    );
  }

  Future<EvidenceSubmissionResult> _result(
    Session session,
    _PullTarget target,
  ) async {
    final attempt = await ActionAttempt.db.findById(session, target.attemptId);
    final check = await AppPullCheck.db.findFirstRow(
      session,
      where: (table) =>
          table.attemptId.equals(target.attemptId) &
          table.requirementId.equals(target.requirementId),
    );
    final app = await VerilyApp.db.findById(session, target.appId);
    if (attempt == null || check == null || app == null) {
      throw StateError('The action attempt was not found.');
    }
    final (status, reason, summary) = switch (check.status) {
      // The App's own reason stays on the decision for audit; the app sees
      // only Verily's public codes.
      AppPullCheckStatus.accepted => (
        EvidenceDecisionStatus.accepted,
        PublicReason.appConfirmed,
        'Confirmed by ${app.name}.',
      ),
      AppPullCheckStatus.rejected || AppPullCheckStatus.expired => (
        EvidenceDecisionStatus.rejected,
        check.status == AppPullCheckStatus.expired
            ? PublicReason.appNoAnswer
            : PublicReason.appNotConfirmed,
        check.status == AppPullCheckStatus.expired
            ? '${app.name} did not answer in time.'
            : '${app.name} did not confirm this.',
      ),
      AppPullCheckStatus.waiting => (
        null,
        PublicReason.appChecking,
        'Waiting for ${app.name} to confirm.',
      ),
      AppPullCheckStatus.calling => (
        null,
        PublicReason.appChecking,
        'Checking with ${app.name}.',
      ),
      AppPullCheckStatus.retrying => (
        null,
        PublicReason.appChecking,
        'We could not reach ${app.name} yet. We will keep trying.',
      ),
      AppPullCheckStatus.failed => (
        null,
        PublicReason.appUnreachable,
        '${app.name} did not answer. Try again later.',
      ),
    };
    return EvidenceSubmissionResult(
      attempt: await attemptViewWithAction(session, attempt),
      requirementId: target.requirementId,
      status: status,
      confidence: status == null ? null : 1,
      reasonCode: reason,
      summary: summary,
    );
  }
}

String _verdictDigest(String eventId, AppPullAnswer answer) =>
    _digest('$eventId|${answer.verdict?.name}|${answer.reason ?? ''}');

String _digest(String value) => sha256.convert(utf8.encode(value)).toString();

final class _PullTarget {
  const _PullTarget({
    required this.attemptId,
    required this.requirementId,
    required this.appId,
  });

  final UuidValue attemptId;
  final UuidValue requirementId;
  final UuidValue appId;
}

final class _CallClaim {
  const _CallClaim({
    required this.app,
    required this.check,
    required this.body,
    required this.requestedAt,
  });

  final VerilyApp app;
  final AppPullCheck check;
  final String body;
  final DateTime requestedAt;
}
