import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/apps/app_pull_check_service.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// Durable retry of one pull verification call.
/// See [AppPullCheckService.callApp].
class AppPullCheckFutureCall extends FutureCall<AppPullCheckTask> {
  Future<void> check(Session session, AppPullCheckTask task) {
    return AppPullCheckService().callApp(session, task.checkId);
  }
}
