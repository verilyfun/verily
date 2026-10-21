import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/action_verification/action_key_lock.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// Transaction-bound safety checks shared by publication and participation.
///
/// Moderation writers take the same action-key lock. Keep the caller's
/// transaction open through the protected mutation so a concurrent pause
/// cannot race it.
class ModerationGate {
  const ModerationGate();

  /// An action hold applies to every revision of that creator's action key.
  Future<void> assertActionAllowed(
    Session session, {
    required UuidValue actionId,
    required Transaction transaction,
  }) async {
    if (await isActionPaused(
      session,
      actionId: actionId,
      transaction: transaction,
    )) {
      throw StateError('This action is paused for safety review.');
    }
  }

  /// Takes the action-key lock and reports whether a hold is active, without
  /// exposing the report. Missing actions fail closed.
  Future<bool> isActionPaused(
    Session session, {
    required UuidValue actionId,
    required Transaction transaction,
  }) async {
    final action = await ActionDefinition.db.findById(
      session,
      actionId,
      transaction: transaction,
    );

    if (action == null) throw StateError('Action was not found.');

    await ActionKeyLock.acquire(
      session,
      creatorAuthUserId: action.creatorAuthUserId,
      actionKey: action.actionKey,
      transaction: transaction,
    );
    final rows = await session.db.unsafeQuery(
      '''
SELECT c."id" FROM "verily_moderation_case" c
JOIN "verily_action_definition" a ON a."id" = c."actionDefinitionId"
WHERE c."creatorAuthUserId" = CAST(@creatorId AS uuid)
  AND c."pauseActive" = true
  AND a."actionKey" = @actionKey
LIMIT 1
''',
      transaction: transaction,
      parameters: QueryParameters.named({
        'creatorId': action.creatorAuthUserId.toString(),
        'actionKey': action.actionKey,
      }),
    );

    return rows.isNotEmpty;
  }

  /// Read-before-expensive-work check; callers must also gate the final write.
  Future<void> preflightAction(Session session, UuidValue actionId) =>
      DatabaseUtil.runInTransactionOrSavepoint(
        session.db,
        null,
        (transaction) => assertActionAllowed(
          session,
          actionId: actionId,
          transaction: transaction,
        ),
      );
}
