import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:verily_server/src/apps/webhooks/webhook_url_policy.dart';

/// What one outbound webhook call produced. Response bodies are read only
/// when the caller asks for them (pull verification), and only up to a bound.
final class WebhookCallResult {
  const WebhookCallResult({
    required this.duration,
    this.statusCode,
    this.errorCode,
    this.responseBody,
  });

  final Duration duration;

  /// The HTTP status, when the App answered.
  final int? statusCode;

  /// Stable failure code when the call did not complete: `host_not_public`,
  /// `timeout`, `connection_failed`, `tls_failure`,
  /// `response_too_large`, or `invalid_url`.
  final String? errorCode;

  /// The bounded response body, when requested and received.
  final String? responseBody;

  bool get succeeded =>
      errorCode == null &&
      statusCode != null &&
      statusCode! >= 200 &&
      statusCode! < 300;
}

/// Sends one signed JSON POST to an App webhook. An interface so tests and
/// the pinned production sender are interchangeable.
// ignore: one_member_abstracts
abstract interface class WebhookSender {
  Future<WebhookCallResult> post({
    required Uri url,
    required Map<String, String> headers,
    required String body,
    required Duration timeout,
    int maxResponseBytes = 0,
  });
}

/// The production sender.
///
/// The host is resolved at send time and every address must be public; the
/// connection is then pinned to that checked address, with TLS still
/// verifying the original host name. A DNS answer that changes between the
/// check and the connection can therefore never redirect a call into a
/// private network (see `isPublicAddress`). Redirects are not followed,
/// proxies are not used, and the whole call, including reading the bounded
/// response, fits in the `timeout` passed to [post].
class PinnedAddressWebhookSender implements WebhookSender {
  PinnedAddressWebhookSender({
    this._resolve = systemHostResolver,
    this._securityContext,
    this.allowLoopbackForTests = false,
  });

  final HostResolver _resolve;
  final SecurityContext? _securityContext;

  /// Test-only escape hatch for an in-process HTTPS server on 127.0.0.1.
  /// Never set in production code.
  final bool allowLoopbackForTests;

  @override
  Future<WebhookCallResult> post({
    required Uri url,
    required Map<String, String> headers,
    required String body,
    required Duration timeout,
    int maxResponseBytes = 0,
  }) async {
    final stopwatch = Stopwatch()..start();
    WebhookCallResult failed(String code) =>
        WebhookCallResult(duration: stopwatch.elapsed, errorCode: code);

    final Uri checked;
    try {
      checked = allowLoopbackForTests ? url : parseWebhookUrl(url.toString());
    } on Object {
      return failed('invalid_url');
    }
    final InternetAddress address;
    if (allowLoopbackForTests) {
      address = InternetAddress.loopbackIPv4;
    } else {
      final List<InternetAddress>? addresses;
      try {
        addresses = await resolvePublicAddresses(
          checked.host,
          resolve: _resolve,
        ).timeout(timeout);
      } on TimeoutException {
        return failed('timeout');
      }
      if (addresses == null) {
        // Nothing resolved, or something private did. Addresses are never
        // echoed into the log.
        return failed('host_not_public');
      }
      address = addresses.first;
    }

    final client = HttpClient(context: _securityContext)
      ..findProxy = ((_) => 'DIRECT')
      ..connectionTimeout = timeout
      ..idleTimeout = const Duration(seconds: 1)
      ..userAgent = 'Verily-Webhooks/1'
      ..connectionFactory = (uri, proxyHost, proxyPort) async {
        final task = await Socket.startConnect(address, uri.port);
        return ConnectionTask.fromSocket(
          task.socket.then(
            (socket) => SecureSocket.secure(
              socket,
              host: uri.host,
              context: _securityContext,
            ),
          ),
          task.cancel,
        );
      };
    try {
      return await _send(
        client,
        checked,
        headers: headers,
        body: body,
        maxResponseBytes: maxResponseBytes,
        stopwatch: stopwatch,
      ).timeout(timeout);
    } on TimeoutException {
      return failed('timeout');
    } on HandshakeException {
      return failed('tls_failure');
    } on TlsException {
      return failed('tls_failure');
    } on _ResponseTooLarge {
      return failed('response_too_large');
    } on SocketException {
      return failed('connection_failed');
    } on HttpException {
      return failed('connection_failed');
    } finally {
      client.close(force: true);
    }
  }

  Future<WebhookCallResult> _send(
    HttpClient client,
    Uri url, {
    required Map<String, String> headers,
    required String body,
    required int maxResponseBytes,
    required Stopwatch stopwatch,
  }) async {
    final request = await client.postUrl(url);
    request
      ..followRedirects = false
      ..persistentConnection = false;
    headers.forEach(request.headers.set);
    request.headers.contentType = ContentType.json;
    final bytes = utf8.encode(body);
    request
      ..contentLength = bytes.length
      ..add(bytes);
    final response = await request.close();
    String? responseBody;
    if (maxResponseBytes > 0) {
      final collected = <int>[];
      await for (final chunk in response) {
        if (collected.length + chunk.length > maxResponseBytes) {
          throw const _ResponseTooLarge();
        }
        collected.addAll(chunk);
      }
      try {
        responseBody = utf8.decode(collected);
      } on FormatException {
        responseBody = null;
      }
    } else {
      // Only the status matters; never buffer what the App sends back.
      await response.drain<void>();
    }
    return WebhookCallResult(
      duration: stopwatch.elapsed,
      statusCode: response.statusCode,
      responseBody: responseBody,
    );
  }
}

final class _ResponseTooLarge implements Exception {
  const _ResponseTooLarge();
}
