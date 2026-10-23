import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/action_verification/app_attest/app_attest_service.dart';
import 'package:verily_server/src/generated/protocol.dart';

const appAttestReceiptRefreshIdentifier = 'app-attest-receipt-refresh';

/// Maintains dormant installations' receipts; one bounded sweep per ten minutes.
class AppAttestReceiptRefreshFutureCall
    extends FutureCall<AppAttestReceiptRefreshTask> {
  Future<void> refresh(Session session, AppAttestReceiptRefreshTask task) =>
      AppAttestService.fromEnvironment().refreshDueReceipts(
        session,
        limit: task.batchSize,
      );
}
