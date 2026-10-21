import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/apps/app_confirmation_service.dart';
import 'package:verily_server/src/verification_requests/verification_request_service.dart';
import 'package:verily_server/src/web/routes/app_api_route.dart';

/// `POST /api/v1/verification-requests`: an App asks one person to prove
/// something with the Verily app.
class VerificationRequestsRoute extends AppApiRoute {
  VerificationRequestsRoute({VerificationRequestService? service})
    : service = service ?? VerificationRequestService(),
      super(
        maxBodyBytes: 8 * 1024,
        tooLargeMessage: 'Verification request bodies must be 8 KB or smaller.',
      );

  final VerificationRequestService service;

  @override
  Future<AppDeliveryResponse> respond(
    Session session,
    Request request,
    String body,
  ) {
    return service.createFromApi(
      session,
      authorization: appAuthorization(request),
      timestamp: appTimestamp(request),
      body: body,
    );
  }
}

/// `POST /api/v1/verification-requests/<requestId>/receipt`: the signed
/// receipt, with the one-time code or with the App key alone to refetch.
class VerificationReceiptRoute extends AppApiRoute {
  VerificationReceiptRoute({VerificationRequestService? service})
    : service = service ?? VerificationRequestService(),
      super(
        maxBodyBytes: 4 * 1024,
        tooLargeMessage: 'Receipt bodies must be 4 KB or smaller.',
      );

  final VerificationRequestService service;

  @override
  Future<AppDeliveryResponse> respond(
    Session session,
    Request request,
    String body,
  ) {
    return service.receipt(
      session,
      authorization: appAuthorization(request),
      timestamp: appTimestamp(request),
      requestId: request.rawPathParameters[#requestId] ?? '',
      body: body,
    );
  }
}
