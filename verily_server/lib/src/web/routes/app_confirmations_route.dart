import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/apps/app_confirmation_payload.dart';
import 'package:verily_server/src/apps/app_confirmation_service.dart';
import 'package:verily_server/src/web/routes/app_api_route.dart';

/// `POST /api/v1/confirmations`: server-to-server confirmations from a
/// creator's Verily Apps.
///
/// This adapter only moves bytes and headers. Authentication, validation,
/// idempotency, and attempt processing live in [AppConfirmationService]. The
/// `Authorization` header is never logged.
class AppConfirmationsRoute extends AppApiRoute {
  AppConfirmationsRoute({AppConfirmationService? service})
    : service = service ?? AppConfirmationService(),
      super(
        maxBodyBytes: appConfirmationMaxBytes,
        tooLargeMessage: 'Confirmation bodies must be 16 KB or smaller.',
      );

  final AppConfirmationService service;

  @override
  AppDeliveryResponse get internalError => const AppDeliveryResponse(500, {
    'error': 'internal_error',
    'message': 'The confirmation was not recorded. Retry with the same id.',
  });

  @override
  Future<AppDeliveryResponse> respond(
    Session session,
    Request request,
    String body,
  ) {
    return service.deliver(
      session,
      authorization: appAuthorization(request),
      timestamp: appTimestamp(request),
      body: body,
    );
  }
}
