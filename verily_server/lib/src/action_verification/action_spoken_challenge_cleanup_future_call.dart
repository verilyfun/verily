import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/generated/protocol.dart';

const actionSpokenChallengeCleanupIdentifier =
    'action-spoken-challenge-cleanup-daily';
const actionSpokenChallengeRetention = Duration(days: 7);

/// Removes challenge words that expired without being bound to a recording.
/// Bound words stay with their evidence for verifiers and reviewers.
class ActionSpokenChallengeCleanupFutureCall
    extends FutureCall<ActionSpokenChallengeCleanupTask> {
  Future<void> cleanup(
    Session session,
    ActionSpokenChallengeCleanupTask task,
  ) async {
    final cutoff = DateTime.now().toUtc().subtract(
      actionSpokenChallengeRetention,
    );
    final expired = await ActionSpokenChallenge.db.find(
      session,
      where: (table) =>
          (table.expiresAt <= cutoff) & table.boundAt.equals(null),
      orderBy: (table) => table.expiresAt,
      limit: task.batchSize.clamp(1, 1000),
    );
    if (expired.isEmpty) return;
    await ActionSpokenChallenge.db.delete(session, expired);
  }
}
