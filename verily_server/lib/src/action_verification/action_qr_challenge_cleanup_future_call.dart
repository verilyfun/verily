import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/generated/protocol.dart';

const actionQrChallengeCleanupIdentifier = 'action-qr-challenge-cleanup-daily';
const actionQrChallengeRetention = Duration(days: 7);

class ActionQrChallengeCleanupFutureCall
    extends FutureCall<ActionQrChallengeCleanupTask> {
  Future<void> cleanup(
    Session session,
    ActionQrChallengeCleanupTask task,
  ) async {
    final cutoff = DateTime.now().toUtc().subtract(actionQrChallengeRetention);
    final expired = await ActionQrChallenge.db.find(
      session,
      where: (table) => table.expiresAt <= cutoff,
      orderBy: (table) => table.expiresAt,
      limit: task.batchSize.clamp(1, 1000),
    );
    if (expired.isEmpty) return;
    await ActionQrChallenge.db.delete(session, expired);
  }
}
