import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/action_verification/action_verification_service.dart';
import 'package:verily_server/src/apps/app_confirmation_payload.dart';
import 'package:verily_server/src/apps/app_credentials.dart';
import 'package:verily_server/src/apps/external_confirmation.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/rewards/reward_payout_service.dart';
import 'package:verily_server/src/security/secret_digest.dart';

/// Status and JSON body for one confirmation delivery.
final class AppDeliveryResponse {
  const AppDeliveryResponse(this.status, this.body, {this.retryAfter});

  final int status;
  final Map<String, Object?> body;

  /// Set on 429 responses; becomes the `Retry-After` header.
  final Duration? retryAfter;
}

/// Authenticates, rate-limits, deduplicates, and applies App confirmations
/// delivered to `POST /api/v1/confirmations`.
///
/// One database transaction covers the whole delivery. It locks the App row
/// first, which serializes deliveries per App (so the rate-limit window and
/// duplicate detection cannot race) and orders locks ahead of the account,
/// action-key, and attempt locks taken while the confirmation is applied.
/// Business-rule rejections are committed as receipts; unexpected failures
/// roll everything back so the App can retry the same event id.
class AppConfirmationService {
  AppConfirmationService({
    ActionVerificationService? verificationService,
    RewardPayoutService? payouts,
    DateTime Function()? clock,
    this.rateLimit = 120,
    this.rateWindow = const Duration(minutes: 1),
  }) : verificationService =
           verificationService ?? ActionVerificationService(clock: clock),
       payouts = payouts ?? RewardPayoutService(clock: clock),
       clock = clock ?? (() => DateTime.now().toUtc());

  final ActionVerificationService verificationService;
  final RewardPayoutService payouts;
  final DateTime Function() clock;

  /// Authenticated deliveries accepted per App in each [rateWindow].
  final int rateLimit;
  final Duration rateWindow;

  Future<AppDeliveryResponse> deliver(
    Session session, {
    required String? authorization,
    required String? timestamp,
    required String body,
  }) async {
    final credential = parseAppAuthorization(authorization);
    if (credential == null) return _unauthorized;
    if (!appTimestampIsFresh(timestamp, clock().toUtc())) {
      return const AppDeliveryResponse(401, {
        'error': 'invalid_timestamp',
        'message': 'Verily-Timestamp must be the current unix time in seconds.',
      });
    }
    // Authenticate on an unlocked read. The key id is public, so a caller
    // without the secret must never queue behind real deliveries for the
    // App row lock.
    final key = await VerilyAppKey.db.findFirstRow(
      session,
      where: (table) => table.keyId.equals(credential.keyId),
    );
    if (key == null ||
        key.revokedAt != null ||
        !credential.matches(key.secretHash)) {
      return _unauthorized;
    }

    final delivery = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) => _deliverAuthenticated(
        session,
        key: key,
        body: body,
        transaction: transaction,
      ),
    );
    // A payout is scheduled only after the delivery commits, so its release
    // job always finds it.
    if (delivery.verifiedAttemptId case final attemptId?) {
      await payouts.scheduleForAttempt(session, attemptId: attemptId);
    }
    return delivery.response;
  }

  Future<_Delivery> _deliverAuthenticated(
    Session session, {
    required VerilyAppKey key,
    required String body,
    required Transaction transaction,
  }) async {
    final app = await VerilyApp.db.findFirstRow(
      session,
      where: (table) => table.id.equals(key.appId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    // Re-check revocation under the App lock, which revocation takes.
    final lockedKey = await VerilyAppKey.db.findById(
      session,
      key.id!,
      transaction: transaction,
    );
    if (app == null ||
        lockedKey == null ||
        app.status != VerilyAppStatus.active ||
        lockedKey.revokedAt != null) {
      return const _Delivery(_unauthorized);
    }
    // Read the clock under the lock so the rate window, which every delivery
    // advances under this same lock, never moves backwards.
    final now = clock().toUtc();

    final limited = await _consumeRateLimit(
      session,
      app: app,
      key: lockedKey,
      now: now,
      transaction: transaction,
    );
    if (limited != null) return _Delivery(limited);

    final AppConfirmationPayload payload;
    try {
      payload = parseAppConfirmationPayload(body);
    } on AppConfirmationPayloadException catch (error) {
      return _Delivery(
        AppDeliveryResponse(422, {
          'error': error.code,
          'message': error.message,
        }),
      );
    }

    final previous = await AppConfirmation.db.findFirstRow(
      session,
      where: (table) =>
          table.appId.equals(app.id) & table.eventId.equals(payload.eventId),
      transaction: transaction,
    );
    if (previous != null) {
      if (!constantTimeEquals(previous.payloadDigest, payload.digest)) {
        return _Delivery(
          AppDeliveryResponse(409, {
            'error': 'event_conflict',
            'message': 'This eventId was already used with different fields.',
            'eventId': payload.eventId,
          }),
        );
      }
      return _Delivery(await _replay(session, previous, transaction));
    }

    final confirmation = await _confirm(
      session,
      app: app,
      payload: payload,
      now: now,
      transaction: transaction,
    );
    final receipt = await AppConfirmation.db.insertRow(
      session,
      AppConfirmation(
        appId: app.id!,
        keyId: lockedKey.keyId,
        eventId: payload.eventId,
        payloadDigest: payload.digest,
        actionKey: payload.actionKey,
        subject: payload.subject,
        actionDefinitionId: switch (confirmation) {
          ExternalConfirmationAccepted(:final actionDefinitionId) =>
            actionDefinitionId,
          ExternalConfirmationRejected(:final actionDefinitionId) =>
            actionDefinitionId,
        },
        attemptId: switch (confirmation) {
          ExternalConfirmationAccepted(:final attempt) => attempt.id,
          ExternalConfirmationRejected() => null,
        },
        occurredAt: payload.occurredAt,
        receivedAt: now,
        outcome: switch (confirmation) {
          ExternalConfirmationAccepted() => AppConfirmationOutcome.accepted,
          ExternalConfirmationRejected() => AppConfirmationOutcome.rejected,
        },
        reasonCode: switch (confirmation) {
          ExternalConfirmationAccepted() => confirmation.reasonCode,
          ExternalConfirmationRejected(:final reason) => reason.code,
        },
      ),
      transaction: transaction,
    );
    return switch (confirmation) {
      ExternalConfirmationAccepted(:final attempt, :final alreadyComplete) =>
        _Delivery(
          _accepted(receipt, attempt.status, duplicate: false),
          verifiedAttemptId:
              !alreadyComplete && attempt.status == ActionAttemptStatus.verified
              ? attempt.id
              : null,
        ),
      ExternalConfirmationRejected(:final reason) => _Delivery(
        _rejected(receipt, reason, duplicate: false),
      ),
    };
  }

  Future<ExternalConfirmation> _confirm(
    Session session, {
    required VerilyApp app,
    required AppConfirmationPayload payload,
    required DateTime now,
    required Transaction transaction,
  }) async {
    if (!appConfirmationTimeIsAcceptable(payload.occurredAt, now)) {
      return const ExternalConfirmationRejected(
        ExternalConfirmationRejection.occurredAtOutOfRange,
      );
    }
    final link = await VerilyAppLink.db.findFirstRow(
      session,
      where: (table) =>
          table.appId.equals(app.id) & table.subject.equals(payload.subject),
      transaction: transaction,
    );
    if (link == null) {
      return const ExternalConfirmationRejected(
        ExternalConfirmationRejection.unknownSubject,
      );
    }
    return verificationService.confirmExternalRequirement(
      session,
      transaction: transaction,
      app: app,
      actionKey: payload.actionKey,
      authUserId: link.authUserId,
      eventId: payload.eventId,
      eventDigest: payload.digest,
      occurredAt: payload.occurredAt,
    );
  }

  /// Fixed-window counter on the locked App row. Every authenticated request
  /// counts, including ones later rejected for their body, so a misbehaving
  /// integration cannot bypass the limit with invalid payloads.
  Future<AppDeliveryResponse?> _consumeRateLimit(
    Session session, {
    required VerilyApp app,
    required VerilyAppKey key,
    required DateTime now,
    required Transaction transaction,
  }) async {
    final windowStart = app.rateWindowStartedAt;
    // A clock read that lands before the stored start (another server's
    // clock, or a step back) stays in the current window.
    final inWindow =
        windowStart != null && now.difference(windowStart) < rateWindow;
    final count = inWindow ? app.rateWindowCount : 0;
    if (count >= rateLimit) {
      final remaining = windowStart!.add(rateWindow).difference(now);
      return AppDeliveryResponse(
        429,
        const {
          'error': 'rate_limited',
          'message': 'Too many confirmations for this app. Retry later.',
        },
        retryAfter: remaining.inSeconds < 1
            ? const Duration(seconds: 1)
            : Duration(seconds: remaining.inSeconds + 1),
      );
    }
    await VerilyApp.db.updateRow(
      session,
      app.copyWith(
        rateWindowStartedAt: inWindow ? windowStart : now,
        rateWindowCount: count + 1,
      ),
      transaction: transaction,
    );
    await VerilyAppKey.db.updateRow(
      session,
      key.copyWith(lastUsedAt: now),
      transaction: transaction,
    );
    return null;
  }

  /// Replays the first decision for a retried event id.
  Future<AppDeliveryResponse> _replay(
    Session session,
    AppConfirmation receipt,
    Transaction transaction,
  ) async {
    switch (receipt.outcome) {
      case AppConfirmationOutcome.accepted:
        final attempt = receipt.attemptId == null
            ? null
            : await ActionAttempt.db.findById(
                session,
                receipt.attemptId!,
                transaction: transaction,
              );
        return _accepted(receipt, attempt?.status, duplicate: true);
      case AppConfirmationOutcome.rejected:
        final reason = ExternalConfirmationRejection.fromCode(
          receipt.reasonCode,
        );
        if (reason == null) {
          throw StateError('Unknown confirmation rejection code on a receipt.');
        }
        return _rejected(receipt, reason, duplicate: true);
    }
  }
}

/// A delivery's response plus the attempt it verified, whose payout is
/// scheduled after the delivery transaction commits.
final class _Delivery {
  const _Delivery(this.response, {this.verifiedAttemptId});

  final AppDeliveryResponse response;
  final UuidValue? verifiedAttemptId;
}

const _unauthorized = AppDeliveryResponse(401, {
  'error': 'invalid_credentials',
  'message': 'Send a valid, active app key as a Bearer token.',
});

AppDeliveryResponse _accepted(
  AppConfirmation receipt,
  ActionAttemptStatus? attemptStatus, {
  required bool duplicate,
}) {
  return AppDeliveryResponse(202, {
    'status': duplicate ? 'duplicate' : 'accepted',
    'eventId': receipt.eventId,
    'attemptStatus': attemptStatus?.name,
  });
}

AppDeliveryResponse _rejected(
  AppConfirmation receipt,
  ExternalConfirmationRejection reason, {
  required bool duplicate,
}) {
  return AppDeliveryResponse(reason.httpStatus, {
    'status': 'rejected',
    'eventId': receipt.eventId,
    'error': reason.code,
    'message': _rejectionMessage(reason),
    'duplicate': duplicate,
  });
}

String _rejectionMessage(ExternalConfirmationRejection reason) =>
    switch (reason) {
      ExternalConfirmationRejection.unknownAction =>
        'No live action with that key accepts confirmations from this app.',
      ExternalConfirmationRejection.unknownSubject =>
        'That subject is not linked to an active participant.',
      ExternalConfirmationRejection.occurredAtOutOfRange =>
        'occurredAt must be within the last 24 hours and not in the future.',
      ExternalConfirmationRejection.occurredOutsideWindow =>
        'occurredAt is outside the action availability window.',
      ExternalConfirmationRejection.occurredOutsidePeriod =>
        'occurredAt belongs to a period that ended more than two hours ago.',
      ExternalConfirmationRejection.actionUnavailable =>
        'The action is not accepting new completions right now.',
    };
