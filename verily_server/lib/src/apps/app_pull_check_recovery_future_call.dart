import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/apps/app_pull_check_service.dart';
import 'package:verily_server/src/generated/protocol.dart';

const appPullCheckRecoveryIdentifier = 'app-pull-check-recovery';

/// Recurring sweep that retries due pull checks and expires checks that got
/// no answer within 24 hours. See [AppPullCheckService.recover].
class AppPullCheckRecoveryFutureCall
    extends FutureCall<AppPullCheckRecoveryTask> {
  Future<void> recover(Session session, AppPullCheckRecoveryTask task) {
    return AppPullCheckService().recover(session, batchSize: task.batchSize);
  }
}
