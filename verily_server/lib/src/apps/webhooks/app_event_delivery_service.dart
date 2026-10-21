// Generated copyWith clears nullable fields with an explicit null.
// ignore_for_file: avoid_redundant_argument_values

import 'dart:math' as math;

import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/apps/webhooks/app_event_outbox.dart';
import 'package:verily_server/src/apps/webhooks/webhook_sender.dart';
import 'package:verily_server/src/apps/webhooks/webhook_signing.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// Delivery attempts per event before it is marked failed.
const appEventMaxAttempts = 12;

/// Budget for one delivery call, connection and response included.
const appEventDeliveryTimeout = Duration(seconds: 10);

/// A delivery that has held its lease this long is presumed lost.
const appEventDeliveryLease = Duration(minutes: 2);

/// Backoff before attempt `n + 1` after attempt `n` failed: 30 s doubling,
/// capped at two hours (about ten hours end to end).
Duration appEventRetryDelay(int failedAttempts) => Duration(
  seconds: math.min(30 * (1 << (failedAttempts - 1).clamp(0, 20)), 7200),
);

/// Delivers queued App events: one signed POST per attempt, logged
/// append-only, retried with exponential backoff.
///
/// A delivery claims its event under a row lock with a short lease, calls the
/// App outside any transaction, then records the attempt. Retries resend the
/// exact stored body with the same event id, so an App deduplicates on `id`.
/// Only the response status matters; bodies are never read.
class AppEventDeliveryService {
  AppEventDeliveryService({
    WebhookSender? sender,
    AppEventOutbox? outbox,
    WebhookSecrets? Function()? secrets,
    DateTime Function()? clock,
  }) : sender = sender ?? PinnedAddressWebhookSender(),
       outbox = outbox ?? const AppEventOutbox(),
       secrets = secrets ?? (() => WebhookSecrets.configured),
       clock = clock ?? (() => DateTime.now().toUtc());

  final WebhookSender sender;
  final AppEventOutbox outbox;
  final WebhookSecrets? Function() secrets;
  final DateTime Function() clock;

  Future<void> deliver(Session session, UuidValue eventRowId) async {
    final claim = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) => _claim(session, eventRowId, transaction),
    );
    if (claim == null) return;

    final now = clock().toUtc();
    final keys = secrets();
    final signingSecrets = keys?.signingSecretsFor(claim.app, now) ?? const [];
    final WebhookCallResult result;
    final webhookUrl = claim.app.webhookUrl;
    if (webhookUrl == null) {
      result = const WebhookCallResult(
        duration: Duration.zero,
        errorCode: 'webhook_not_configured',
      );
    } else if (signingSecrets.isEmpty) {
      result = const WebhookCallResult(
        duration: Duration.zero,
        errorCode: 'signing_unavailable',
      );
    } else {
      final timestamp = now.millisecondsSinceEpoch ~/ 1000;
      result = await sender.post(
        url: Uri.parse(webhookUrl),
        headers: {
          'verily-event': claim.event.type,
          'verily-event-id': claim.event.eventId,
          'verily-delivery-attempt': '${claim.event.attemptCount}',
          'verily-signature': webhookSignatureHeader(
            timestamp: timestamp,
            body: claim.event.body,
            secrets: signingSecrets,
          ),
        },
        body: claim.event.body,
        timeout: appEventDeliveryTimeout,
      );
    }

    final retryDelay = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) => _record(session, claim, result, transaction),
    );
    if (retryDelay != null) {
      await outbox.schedule(session, eventRowId, delay: retryDelay);
    }
  }

  /// Schedules every event that is due, or whose delivery lease expired.
  /// Returns how many were scheduled.
  Future<int> recover(Session session, {required int batchSize}) async {
    if (batchSize < 1 || batchSize > 500) {
      throw ArgumentError.value(batchSize, 'batchSize');
    }
    final now = clock().toUtc();
    final due = await AppEvent.db.find(
      session,
      where: (table) =>
          (table.status.equals(AppEventStatus.pending) &
              (table.nextAttemptAt <= now)) |
          (table.status.equals(AppEventStatus.delivering) &
              (table.leaseExpiresAt <= now)),
      orderBy: (table) => table.nextAttemptAt,
      limit: batchSize,
    );
    for (final event in due) {
      await outbox.schedule(session, event.id!);
    }
    return due.length;
  }

  /// The App's delivery log, newest first, for its creator only.
  Future<List<AppWebhookDeliveryView>> listDeliveries(
    Session session, {
    required UuidValue authUserId,
    required UuidValue appId,
    required int limit,
    UuidValue? beforeId,
  }) async {
    final app = await VerilyApp.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(appId) & table.creatorAuthUserId.equals(authUserId),
    );
    if (app == null) throw StateError('That app was not found.');
    final deliveries = await AppWebhookDelivery.db.find(
      session,
      where: (table) =>
          table.appId.equals(appId) &
          (beforeId == null ? Constant.bool(true) : table.id < beforeId),
      orderBy: (table) => table.id.desc(),
      limit: limit.clamp(1, 100),
    );
    final events = await AppEvent.db.find(
      session,
      where: (table) =>
          table.appId.equals(appId) &
          table.eventId.inSet({for (final row in deliveries) row.eventId}),
    );
    final statusByEvent = {
      for (final event in events) event.eventId: event.status,
    };
    return [
      for (final row in deliveries)
        AppWebhookDeliveryView(
          id: row.id!,
          eventId: row.eventId,
          eventType: row.eventType,
          attemptNumber: row.attemptNumber,
          requestedAt: row.requestedAt,
          durationMilliseconds: row.durationMilliseconds,
          statusCode: row.statusCode,
          errorCode: row.errorCode,
          succeeded: row.succeeded,
          eventStatus: statusByEvent[row.eventId],
        ),
    ];
  }

  Future<_Claim?> _claim(
    Session session,
    UuidValue eventRowId,
    Transaction transaction,
  ) async {
    final event = await AppEvent.db.findById(
      session,
      eventRowId,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (event == null) return null;
    final now = clock().toUtc();
    final due = switch (event.status) {
      AppEventStatus.pending => !event.nextAttemptAt.isAfter(
        now.add(const Duration(seconds: 1)),
      ),
      AppEventStatus.delivering =>
        event.leaseExpiresAt == null || !event.leaseExpiresAt!.isAfter(now),
      AppEventStatus.delivered || AppEventStatus.failed => false,
    };
    if (!due) return null;
    final app = await VerilyApp.db.findById(
      session,
      event.appId,
      transaction: transaction,
    );
    if (app == null) return null;
    if (app.status != VerilyAppStatus.active) {
      // A revoked App receives nothing more.
      await AppEvent.db.updateRow(
        session,
        event.copyWith(
          status: AppEventStatus.failed,
          lastErrorCode: 'app_revoked',
          leaseExpiresAt: null,
          updatedAt: now,
        ),
        transaction: transaction,
      );
      return null;
    }
    final claimed = await AppEvent.db.updateRow(
      session,
      event.copyWith(
        status: AppEventStatus.delivering,
        attemptCount: event.attemptCount + 1,
        leaseExpiresAt: now.add(appEventDeliveryLease),
        updatedAt: now,
      ),
      transaction: transaction,
    );
    return _Claim(event: claimed, app: app, requestedAt: now);
  }

  /// Logs the attempt and settles the event. Returns the retry delay, or
  /// null when the event is finished.
  Future<Duration?> _record(
    Session session,
    _Claim claim,
    WebhookCallResult result,
    Transaction transaction,
  ) async {
    final now = clock().toUtc();
    final succeeded = result.succeeded;
    final errorCode = succeeded
        ? null
        : result.errorCode ?? 'http_${result.statusCode ?? 0}';
    await AppWebhookDelivery.db.insertRow(
      session,
      AppWebhookDelivery(
        appId: claim.app.id!,
        eventId: claim.event.eventId,
        eventType: claim.event.type,
        attemptNumber: claim.event.attemptCount,
        requestedAt: claim.requestedAt,
        durationMilliseconds: result.duration.inMilliseconds,
        statusCode: result.statusCode,
        errorCode: errorCode,
        succeeded: succeeded,
      ),
      transaction: transaction,
    );
    final current = await AppEvent.db.findById(
      session,
      claim.event.id!,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    // Another worker reclaimed an expired lease and finished first.
    if (current == null ||
        current.status != AppEventStatus.delivering ||
        current.attemptCount != claim.event.attemptCount) {
      return null;
    }
    if (succeeded) {
      await AppEvent.db.updateRow(
        session,
        current.copyWith(
          status: AppEventStatus.delivered,
          deliveredAt: now,
          leaseExpiresAt: null,
          lastStatusCode: result.statusCode,
          lastErrorCode: null,
          updatedAt: now,
        ),
        transaction: transaction,
      );
      return null;
    }
    final exhausted = current.attemptCount >= appEventMaxAttempts;
    final delay = appEventRetryDelay(current.attemptCount);
    await AppEvent.db.updateRow(
      session,
      current.copyWith(
        status: exhausted ? AppEventStatus.failed : AppEventStatus.pending,
        nextAttemptAt: exhausted ? current.nextAttemptAt : now.add(delay),
        leaseExpiresAt: null,
        lastStatusCode: result.statusCode,
        lastErrorCode: errorCode,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    return exhausted ? null : delay;
  }
}

final class _Claim {
  const _Claim({
    required this.event,
    required this.app,
    required this.requestedAt,
  });

  final AppEvent event;
  final VerilyApp app;
  final DateTime requestedAt;
}
