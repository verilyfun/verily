import 'dart:convert';

import 'package:serverpod/serverpod.dart';

/// Readiness probe for the public edge and container orchestrator.
///
/// A successful response proves that both the Dart process and its PostgreSQL
/// connection are usable. It deliberately exposes no deployment details.
class HealthRoute extends Route {
  HealthRoute() : super(methods: {Method.get, Method.head});

  @override
  Future<Result> handleCall(Session session, Request request) async {
    try {
      await session.db.unsafeQuery('SELECT 1;');
      return _jsonResponse(200, const {'status': 'ok'});
    } on Object catch (error, stackTrace) {
      session.log(
        'Readiness check failed: $error',
        level: LogLevel.error,
        stackTrace: stackTrace,
      );
      return _jsonResponse(503, const {'status': 'unavailable'});
    }
  }
}

Response _jsonResponse(int statusCode, Map<String, String> body) {
  return Response(
    statusCode,
    body: Body.fromString(jsonEncode(body), mimeType: MimeType.json),
    headers: Headers.build(
      (headers) => headers.cacheControl = CacheControlHeader(noStore: true),
    ),
  );
}
