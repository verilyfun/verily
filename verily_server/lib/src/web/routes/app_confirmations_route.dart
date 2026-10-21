import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/apps/app_confirmation_payload.dart';
import 'package:verily_server/src/apps/app_confirmation_service.dart';

/// `POST /api/v1/confirmations`: server-to-server confirmations from a
/// creator's Verily Apps.
///
/// This adapter only moves bytes and headers. Authentication, validation,
/// idempotency, and attempt processing live in [AppConfirmationService]. The
/// `Authorization` header is never logged.
class AppConfirmationsRoute extends Route {
  AppConfirmationsRoute({AppConfirmationService? service})
    : service = service ?? AppConfirmationService(),
      super(methods: {Method.post});

  final AppConfirmationService service;

  @override
  Future<Result> handleCall(Session session, Request request) async {
    final String body;
    try {
      body = await request.readAsString(maxLength: appConfirmationMaxBytes);
    } on MaxBodySizeExceeded {
      return _json(
        const AppDeliveryResponse(413, {
          'error': 'payload_too_large',
          'message': 'Confirmation bodies must be 16 KB or smaller.',
        }),
      );
    } on FormatException {
      return _json(
        const AppDeliveryResponse(422, {
          'error': 'invalid_json',
          'message': 'The body must be UTF-8 encoded JSON.',
        }),
      );
    }

    try {
      final response = await service.deliver(
        session,
        authorization: request.headers['authorization']?.firstOrNull,
        timestamp: request.headers['verily-timestamp']?.firstOrNull,
        body: body,
      );
      return _json(response);
    } on Object catch (error, stackTrace) {
      session.log(
        'App confirmation failed: ${error.runtimeType}',
        level: LogLevel.error,
        stackTrace: stackTrace,
      );
      return _json(
        const AppDeliveryResponse(500, {
          'error': 'internal_error',
          'message':
              'The confirmation was not recorded. Retry with the same id.',
        }),
      );
    }
  }
}

Response _json(AppDeliveryResponse response) {
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
