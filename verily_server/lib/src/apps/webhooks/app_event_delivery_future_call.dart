import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/apps/webhooks/app_event_delivery_service.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// Durable entry point for one App event delivery attempt.
/// See [AppEventDeliveryService.deliver].
class AppEventDeliveryFutureCall extends FutureCall<AppEventDeliveryTask> {
  Future<void> deliver(Session session, AppEventDeliveryTask task) {
    return AppEventDeliveryService().deliver(session, task.eventId);
  }
}
