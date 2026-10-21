import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/generated/protocol.dart';

const appLinkCodeCleanupIdentifier = 'app-link-code-cleanup';

/// Deletes deep-link codes a day after they expired, used or not. Codes are
/// one-time and live five minutes, so nothing valid is ever removed.
class AppLinkCodeCleanupFutureCall extends FutureCall<AppLinkCodeCleanupTask> {
  AppLinkCodeCleanupFutureCall({DateTime Function()? clock})
    : clock = clock ?? (() => DateTime.now().toUtc());

  final DateTime Function() clock;

  Future<void> cleanup(Session session, AppLinkCodeCleanupTask task) async {
    if (task.batchSize < 1 || task.batchSize > 1000) {
      throw ArgumentError.value(task.batchSize, 'batchSize');
    }
    final cutoff = clock().toUtc().subtract(const Duration(days: 1));
    final expired = await VerilyAppLinkCode.db.find(
      session,
      where: (table) => table.expiresAt < cutoff,
      orderBy: (table) => table.expiresAt,
      limit: task.batchSize,
    );
    if (expired.isEmpty) return;
    await VerilyAppLinkCode.db.delete(session, expired);
    session.log('Removed ${expired.length} expired app link codes.');
  }
}
