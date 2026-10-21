import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';

/// Checks durable account state before a value-bearing operation.
///
/// A session can outlive closure until token revocation finishes. Checking the
/// blocked flag closes that interval for proof submission, reviews, and payouts.
abstract final class AccountAccess {
  static Future<void> requireActive(
    Session session,
    UuidValue authUserId, {
    Transaction? transaction,
  }) async {
    if (!await isActive(session, authUserId, transaction: transaction)) {
      throw StateError('An active account is required.');
    }
  }

  /// Non-throwing form of [requireActive] for server-to-server callers that
  /// record a typed rejection. Inside a transaction the account row stays
  /// locked, so the answer holds until commit.
  static Future<bool> isActive(
    Session session,
    UuidValue authUserId, {
    Transaction? transaction,
  }) async {
    final account = await AuthUser.db.findFirstRow(
      session,
      where: (table) => table.id.equals(authUserId),
      transaction: transaction,
      lockMode: transaction == null ? null : LockMode.forUpdate,
    );

    return account != null && !account.blocked;
  }
}
