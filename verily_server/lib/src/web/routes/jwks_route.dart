import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/verification_requests/receipt_signing.dart';

/// `GET /.well-known/jwks.json`: the public keys that verify receipts.
class JwksRoute extends Route {
  JwksRoute() : super(methods: {Method.get});

  @override
  Future<Result> handleCall(Session session, Request request) async {
    return Response.ok(
      body: Body.fromString(
        jsonEncode(ReceiptSigning.jwks()),
        mimeType: MimeType.json,
      ),
      headers: Headers.build((headers) {
        headers.cacheControl = CacheControlHeader(
          publicCache: true,
          maxAge: 300,
        );
      }),
    );
  }
}
