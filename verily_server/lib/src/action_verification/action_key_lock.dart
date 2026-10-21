import 'package:serverpod/serverpod.dart';

/// The mutex that serializes every write to one creator's action key.
///
/// Publication, revision drafts, moderation holds, participation, completion,
/// and reward funding for one action key all take this transaction-scoped
/// advisory lock. It replaces the project row lock of the system Verily was
/// ported from. A row cannot play this role: the latest revision row changes
/// identity whenever a new revision is inserted, and the creator's account
/// row is also locked by `AccountAccess` when that creator participates in
/// someone else's action, which would invert lock order across accounts.
///
/// Lock order, outermost first: the acting account's `AuthUser` row (through
/// `AccountAccess`), the attempt row, this key lock, action revision rows,
/// the reward pool row, then payout rows. Every transaction that locks an
/// attempt locks its participant's account first, so attempt and key locks
/// for one participant never interleave across transactions.
abstract final class ActionKeyLock {
  static Future<void> acquire(
    Session session, {
    required UuidValue creatorAuthUserId,
    required String actionKey,
    required Transaction transaction,
  }) async {
    await session.db.unsafeQuery(
      'SELECT pg_advisory_xact_lock(hashtextextended(@lockKey, 0));',
      parameters: QueryParameters.named({
        'lockKey': 'verily:action-key:$creatorAuthUserId:$actionKey',
      }),
      transaction: transaction,
    );
  }
}
