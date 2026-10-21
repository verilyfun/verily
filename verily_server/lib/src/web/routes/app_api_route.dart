import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/apps/app_confirmation_service.dart';

/// Shared transport for the `/api/v1` routes Apps call with their key.
///
/// It only moves bytes and headers: it reads a bounded UTF-8 body, hands it
/// to [respond], and renders the typed JSON response with `no-store` and,
/// for 429s, `Retry-After`. Authentication, validation, and side effects
/// live in the services. The `Authorization` header is never logged, and an
/// unexpected failure becomes a generic 500 so no internals leak.
abstract class AppApiRoute extends Route {
  AppApiRoute({
    required this.maxBodyBytes,
    required this.tooLargeMessage,
    super.methods = const {Method.post},
  });

  final int maxBodyBytes;
  final String tooLargeMessage;

  /// Handles one request whose body is already read and bounded.
  Future<AppDeliveryResponse> respond(
    Session session,
    Request request,
    String body,
  );

  /// The response when [respond] throws.
  AppDeliveryResponse get internalError => const AppDeliveryResponse(500, {
    'error': 'internal_error',
    'message': 'The request was not completed. Retry it.',
  });

  @override
  Future<Result> handleCall(Session session, Request request) async {
    final String body;
    try {
      body = await request.readAsString(maxLength: maxBodyBytes);
    } on MaxBodySizeExceeded {
      return appApiJson(
        AppDeliveryResponse(413, {
          'error': 'payload_too_large',
          'message': tooLargeMessage,
        }),
      );
    } on FormatException {
      return appApiJson(
        const AppDeliveryResponse(422, {
          'error': 'invalid_json',
          'message': 'The body must be UTF-8 encoded JSON.',
        }),
      );
    }
    try {
      return appApiJson(await respond(session, request, body));
    } on Object catch (error, stackTrace) {
      session.log(
        '$runtimeType failed: ${error.runtimeType}',
        level: LogLevel.error,
        stackTrace: stackTrace,
      );
      return appApiJson(internalError);
    }
  }
}

/// The `Authorization` header value, if any.
String? appAuthorization(Request request) =>
    request.headers['authorization']?.firstOrNull;

/// The `Verily-Timestamp` header value, if any.
String? appTimestamp(Request request) =>
    request.headers['verily-timestamp']?.firstOrNull;

/// Renders a typed App API response as JSON.
Response appApiJson(AppDeliveryResponse response) {
  return Response(
    response.status,
    body: Body.fromString(jsonEncode(response.body), mimeType: MimeType.json),
    headers: Headers.build((headers) {
      headers.cacheControl = CacheControlHeader(noStore: true);
      if (response.retryAfter case final retryAfter?) {
        headers['retry-after'] = ['${retryAfter.inSeconds}'];
      }
    }),
  );
}
