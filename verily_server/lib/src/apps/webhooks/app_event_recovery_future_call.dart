import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/apps/webhooks/app_event_delivery_service.dart';
import 'package:verily_server/src/generated/protocol.dart';

const appEventRecoveryIdentifier = 'app-event-recovery';

/// Recurring sweep that delivers App events whose schedule was missed or
/// whose delivery lease expired. See [AppEventDeliveryService.recover].
class AppEventRecoveryFutureCall extends FutureCall<AppEventRecoveryTask> {
  Future<void> recover(Session session, AppEventRecoveryTask task) {
    return AppEventDeliveryService().recover(
      session,
      batchSize: task.batchSize,
    );
  }
}
