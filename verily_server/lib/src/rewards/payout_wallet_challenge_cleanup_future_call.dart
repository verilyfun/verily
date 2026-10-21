import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/generated/protocol.dart';

const payoutWalletChallengeCleanupIdentifier =
    'payout-wallet-challenge-cleanup-daily';
const payoutWalletChallengeRetention = Duration(days: 1);

class PayoutWalletChallengeCleanupFutureCall
    extends FutureCall<PayoutWalletChallengeCleanupTask> {
  Future<void> cleanup(
    Session session,
    PayoutWalletChallengeCleanupTask task,
  ) async {
    final cutoff = DateTime.now().toUtc().subtract(
      payoutWalletChallengeRetention,
    );
    final expired = await PayoutWalletLinkChallenge.db.find(
      session,
      where: (table) => table.expiresAt <= cutoff,
      orderBy: (table) => table.expiresAt,
      limit: task.batchSize.clamp(1, 1000),
    );
    if (expired.isEmpty) return;
    await PayoutWalletLinkChallenge.db.delete(session, expired);
  }
}
