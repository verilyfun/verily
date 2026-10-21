import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/generated/protocol.dart';

const actionCaptureChallengeCleanupIdentifier =
    'action-capture-challenge-cleanup-daily';
const actionCaptureChallengeRetention = Duration(days: 7);

class ActionCaptureChallengeCleanupFutureCall
    extends FutureCall<ActionCaptureChallengeCleanupTask> {
  Future<void> cleanup(
    Session session,
    ActionCaptureChallengeCleanupTask task,
  ) async {
    final cutoff = DateTime.now().toUtc().subtract(
      actionCaptureChallengeRetention,
    );
    final expired = await ActionCaptureChallenge.db.find(
      session,
      where: (table) => table.expiresAt <= cutoff,
      orderBy: (table) => table.expiresAt,
      limit: task.batchSize.clamp(1, 1000),
    );
    if (expired.isEmpty) return;
    await ActionCaptureChallenge.db.delete(session, expired);
  }
}
