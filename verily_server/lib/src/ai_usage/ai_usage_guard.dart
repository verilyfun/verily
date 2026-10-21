import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// The one per-account AI task Verily runs on demand: drafting an action.
/// Proof verification is metered per attempt by the inference reservations.
const aiActionDraftOperation = 'action-draft';

/// A usage policy stopped an AI task before it ran: AI is paused, the daily
/// allowance is spent, or another task is still running.
class AiUsageLimitException implements Exception {
  const AiUsageLimitException(this.message);

  final String message;

  @override
  String toString() => 'AiUsageLimitException: $message';
}

class AiUsagePolicy {
  const AiUsagePolicy({
    required this.dailyUnits,
    required this.activeRequests,
  });

  final int dailyUnits;
  final int activeRequests;
}

class AiUsageConfiguration {
  AiUsageConfiguration({
    required this.enabled,
    required Map<String, AiUsagePolicy> policies,
    this.reservationLifetime = const Duration(minutes: 15),
  }) : policies = Map.unmodifiable(policies);

  factory AiUsageConfiguration.fromEnvironment([
    Map<String, String>? environment,
  ]) {
    final values = environment ?? Platform.environment;
    final isProduction =
        values['runmode']?.trim().toLowerCase() == 'production';
    final enabled = _readBoolean(
      values['VERILY_AI_ENABLED'],
      fallback: !isProduction,
    );
    return AiUsageConfiguration(
      enabled: enabled,
      policies: {
        aiActionDraftOperation: AiUsagePolicy(
          dailyUnits: _readPositiveInt(
            values['VERILY_AI_ACTION_DRAFT_DAILY_UNITS'],
            fallback: 20,
          ),
          activeRequests: 2,
        ),
      },
    );
  }

  final bool enabled;
  final Map<String, AiUsagePolicy> policies;
  final Duration reservationLifetime;
}

/// Reserves per-account AI work before any external call and records the
/// outcome afterwards, so a quota cannot be raced by parallel requests.
class AiUsageGuard {
  AiUsageGuard({
    AiUsageConfiguration? configuration,
    DateTime Function()? clock,
  }) : configuration = configuration ?? AiUsageConfiguration.fromEnvironment(),
       clock = clock ?? (() => DateTime.now().toUtc());

  final AiUsageConfiguration configuration;
  final DateTime Function() clock;

  void ensureEnabled() {
    if (!configuration.enabled) {
      throw const AiUsageLimitException(
        'AI drafting is paused right now. Start from a template instead.',
      );
    }
  }

  Future<T> run<T>(
    Session session, {
    required UuidValue authUserId,
    required String operation,
    required Future<T> Function() task,
    int costUnits = 1,
  }) async {
    final reservation = await reserve(
      session,
      authUserId: authUserId,
      operation: operation,
      costUnits: costUnits,
    );
    var succeeded = false;
    try {
      final result = await task();
      succeeded = true;
      return result;
    } finally {
      await finish(session, reservation, succeeded: succeeded);
    }
  }

  Future<AiUsageRequest> reserve(
    Session session, {
    required UuidValue authUserId,
    required String operation,
    int costUnits = 1,
  }) async {
    ensureEnabled();
    if (costUnits <= 0) {
      throw ArgumentError.value(costUnits, 'costUnits', 'Must be positive.');
    }
    final policy = configuration.policies[operation];
    if (policy == null) {
      throw ArgumentError.value(operation, 'operation', 'Unknown AI task.');
    }
    final now = clock().toUtc();
    final dayStart = DateTime.utc(now.year, now.month, now.day);
    final activeAfter = now.subtract(configuration.reservationLifetime);

    return DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        final authUser = await AuthUser.db.findFirstRow(
          session,
          where: (table) => table.id.equals(authUserId),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (authUser == null) throw StateError('Account was not found.');

        final today = await AiUsageRequest.db.find(
          session,
          where: (table) =>
              table.authUserId.equals(authUserId) &
              table.operation.equals(operation) &
              (table.createdAt >= dayStart),
          transaction: transaction,
        );
        final usedUnits = today.fold<int>(
          0,
          (total, request) => total + request.costUnits,
        );
        if (usedUnits + costUnits > policy.dailyUnits) {
          throw const AiUsageLimitException(
            'Today’s AI drafting allowance is used. Try again tomorrow or '
            'start from a template.',
          );
        }
        final activeCount = today
            .where(
              (request) =>
                  request.status == AiUsageStatus.reserved &&
                  request.createdAt.isAfter(activeAfter),
            )
            .length;
        if (activeCount >= policy.activeRequests) {
          throw const AiUsageLimitException(
            'Another draft is still being written. Let it finish first.',
          );
        }

        return AiUsageRequest.db.insertRow(
          session,
          AiUsageRequest(
            authUserId: authUserId,
            operation: operation,
            status: AiUsageStatus.reserved,
            costUnits: costUnits,
            createdAt: now,
          ),
          transaction: transaction,
        );
      },
    );
  }

  Future<void> finish(
    Session session,
    AiUsageRequest reservation, {
    required bool succeeded,
  }) async {
    final id = reservation.id;
    if (id == null) return;
    await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        final current = await AiUsageRequest.db.findFirstRow(
          session,
          where: (table) => table.id.equals(id),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (current == null || current.status != AiUsageStatus.reserved) {
          return;
        }
        await AiUsageRequest.db.updateRow(
          session,
          current.copyWith(
            status: succeeded ? AiUsageStatus.succeeded : AiUsageStatus.failed,
            completedAt: clock().toUtc(),
          ),
          transaction: transaction,
        );
      },
    );
  }
}

bool _readBoolean(String? value, {required bool fallback}) {
  return switch (value?.trim().toLowerCase()) {
    'true' || '1' || 'yes' => true,
    'false' || '0' || 'no' => false,
    _ => fallback,
  };
}

int _readPositiveInt(String? value, {required int fallback}) {
  final parsed = int.tryParse(value?.trim() ?? '');
  return parsed == null || parsed <= 0 ? fallback : parsed;
}
