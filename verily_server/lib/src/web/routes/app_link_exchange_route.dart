import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/apps/app_confirmation_service.dart';
import 'package:verily_server/src/apps/linking/app_link_service.dart';
import 'package:verily_server/src/web/routes/app_api_route.dart';

/// `POST /api/v1/links/exchange`: an App's backend trades a one-time link
/// code for the participant's pairwise `vls_` subject.
class AppLinkExchangeRoute extends AppApiRoute {
  AppLinkExchangeRoute({AppLinkService? service})
    : service = service ?? AppLinkService(),
      super(
        maxBodyBytes: 4 * 1024,
        tooLargeMessage: 'Exchange bodies must be 4 KB or smaller.',
      );

  final AppLinkService service;

  @override
  Future<AppDeliveryResponse> respond(
    Session session,
    Request request,
    String body,
  ) {
    return service.exchange(
      session,
      authorization: appAuthorization(request),
      timestamp: appTimestamp(request),
      body: body,
    );
  }
}
