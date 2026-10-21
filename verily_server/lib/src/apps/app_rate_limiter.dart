import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// Fixed-window counters per App and operation bucket.
///
/// Each consume locks its bucket row inside the caller's transaction, so
/// concurrent requests cannot both take the last slot. Buckets may carry a
/// pairwise subject (`verification-accept:vls_…`) for per-person limits.
class AppRateLimiter {
  const AppRateLimiter();

  /// Takes one slot. Returns null when allowed, or how long to wait.
  Future<Duration?> consume(
    Session session, {
    required UuidValue appId,
    required String bucket,
    required int limit,
    required Duration window,
    required DateTime now,
    required Transaction transaction,
  }) async {
    if (limit < 1) throw ArgumentError.value(limit, 'limit');
    // Create the row once; the lock below serializes everyone after that.
    await VerilyAppRateWindow.db.insert(
      session,
      [
        VerilyAppRateWindow(
          appId: appId,
          bucket: bucket,
          windowStartedAt: now,
          requestCount: 0,
        ),
      ],
      transaction: transaction,
      ignoreConflicts: true,
    );
    final row = await VerilyAppRateWindow.db.findFirstRow(
      session,
      where: (table) => table.appId.equals(appId) & table.bucket.equals(bucket),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (row == null) throw StateError('Rate window is missing.');
    // A clock read before the stored start stays in the current window.
    final inWindow = now.difference(row.windowStartedAt) < window;
    final count = inWindow ? row.requestCount : 0;
    if (count >= limit) {
      final remaining = row.windowStartedAt.add(window).difference(now);
      return remaining.inSeconds < 1
          ? const Duration(seconds: 1)
          : Duration(seconds: remaining.inSeconds + 1);
    }
    await VerilyAppRateWindow.db.updateRow(
      session,
      row.copyWith(
        windowStartedAt: inWindow ? row.windowStartedAt : now,
        requestCount: count + 1,
      ),
      transaction: transaction,
    );
    return null;
  }
}
