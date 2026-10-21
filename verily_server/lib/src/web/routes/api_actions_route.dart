import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/apps/api/app_api_action_service.dart';
import 'package:verily_server/src/apps/app_confirmation_service.dart';
import 'package:verily_server/src/web/routes/app_api_route.dart';

/// Largest App action-creation body.
const int appApiActionMaxBytes = 32 * 1024;

/// `POST /api/v1/actions`: create a draft action owned by the App's creator.
class ApiActionsRoute extends AppApiRoute {
  ApiActionsRoute({AppApiActionService? service})
    : service = service ?? AppApiActionService(),
      super(
        maxBodyBytes: appApiActionMaxBytes,
        tooLargeMessage: 'Action bodies must be 32 KB or smaller.',
      );

  final AppApiActionService service;

  @override
  Future<AppDeliveryResponse> respond(
    Session session,
    Request request,
    String body,
  ) {
    return service.create(
      session,
      authorization: appAuthorization(request),
      timestamp: appTimestamp(request),
      body: body,
    );
  }
}

/// Which lifecycle change an [ApiActionLifecycleRoute] applies.
enum ApiActionLifecycle { publish, pause }

/// `POST /api/v1/actions/<actionId>/publish` and `/pause`.
class ApiActionLifecycleRoute extends AppApiRoute {
  ApiActionLifecycleRoute(this.lifecycle, {AppApiActionService? service})
    : service = service ?? AppApiActionService(),
      super(
        maxBodyBytes: 4 * 1024,
        tooLargeMessage: 'Lifecycle bodies must be 4 KB or smaller.',
      );

  final ApiActionLifecycle lifecycle;
  final AppApiActionService service;

  @override
  Future<AppDeliveryResponse> respond(
    Session session,
    Request request,
    String body,
  ) {
    final actionId = request.rawPathParameters[#actionId] ?? '';
    return switch (lifecycle) {
      ApiActionLifecycle.publish => service.publish(
        session,
        authorization: appAuthorization(request),
        timestamp: appTimestamp(request),
        actionId: actionId,
        body: body,
      ),
      ApiActionLifecycle.pause => service.pause(
        session,
        authorization: appAuthorization(request),
        timestamp: appTimestamp(request),
        actionId: actionId,
        body: body,
      ),
    };
  }
}
