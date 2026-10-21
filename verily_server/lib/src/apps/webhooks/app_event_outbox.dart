import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/apps/webhooks/webhook_signing.dart';
import 'package:verily_server/src/generated/future_calls.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// Wire names of the events Verily sends to App webhooks.
abstract final class AppEventType {
  static const attemptVerified = 'attempt.verified';
  static const attemptRejected = 'attempt.rejected';
  static const payoutReleased = 'payout.released';
  static const verificationRequestCompleted = 'verification_request.completed';

  /// The synchronous pull-verification call; logged, never queued.
  static const attemptVerify = 'attempt.verify';

  static const Set<String> queued = {
    attemptVerified,
    attemptRejected,
    payoutReleased,
    verificationRequestCompleted,
  };
}

/// The durable outbox for App events.
///
/// [enqueue] runs inside the transaction that records the fact, so an event
/// exists exactly when its fact commits, and `(appId, dedupeKey)` makes
/// recording the same fact twice a no-op. Delivery is scheduled after commit
/// with [schedule]; the recovery sweep delivers anything whose schedule was
/// missed. Event bodies never carry evidence bytes, storage paths, precise
/// coordinates, or account ids: only pairwise subjects and public ids.
class AppEventOutbox {
  const AppEventOutbox();

  /// Records one event for [app] if it can receive events: an active App
  /// with a webhook URL and an issued signing secret. Returns the new row, or
  /// null when the App cannot receive events or the fact was already queued.
  Future<AppEvent?> enqueue(
    Session session, {
    required VerilyApp app,
    required String type,
    required String dedupeKey,
    required Map<String, Object?> data,
    required DateTime now,
    required Transaction transaction,
  }) async {
    if (!AppEventType.queued.contains(type)) {
      throw ArgumentError.value(type, 'type', 'Unknown App event type.');
    }
    if (app.status != VerilyAppStatus.active ||
        app.webhookUrl == null ||
        app.webhookSecretVersion < 1) {
      return null;
    }
    final eventId = newWebhookEventId();
    final body = jsonEncode({
      'id': eventId,
      'type': type,
      'createdAt': now.toUtc().toIso8601String(),
      'data': data,
    });
    final inserted = await AppEvent.db.insert(
      session,
      [
        AppEvent(
          appId: app.id!,
          eventId: eventId,
          type: type,
          dedupeKey: dedupeKey,
          body: body,
          status: AppEventStatus.pending,
          nextAttemptAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      transaction: transaction,
      ignoreConflicts: true,
    );
    return inserted.firstOrNull;
  }

  /// Schedules the first delivery attempt of a committed event. A failure to
  /// schedule is logged; recovery picks the event up.
  Future<void> schedule(
    Session session,
    UuidValue eventRowId, {
    Duration delay = Duration.zero,
  }) async {
    try {
      await session.serverpod.futureCalls
          .callWithDelay(delay)
          .appEventDelivery
          .deliver(AppEventDeliveryTask(eventId: eventRowId));
    } on Object catch (error, stackTrace) {
      session.log(
        'Failed to schedule App event $eventRowId.',
        level: LogLevel.warning,
        exception: error,
        stackTrace: stackTrace,
      );
    }
  }
}
