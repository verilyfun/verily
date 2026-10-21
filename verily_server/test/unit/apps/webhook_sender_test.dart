import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:verily_server/src/apps/webhooks/webhook_sender.dart';

/// A throwaway CA and a `localhost` leaf it signs, generated per run with
/// the system openssl, so no key material is ever committed. (macOS trust
/// evaluation refuses a bare self-signed leaf.)
Future<({SecurityContext server, SecurityContext client})?> _localhostTls(
  Directory directory,
) async {
  String path(String name) => '${directory.path}/$name';
  File(path('ext.cnf')).writeAsStringSync(
    'subjectAltName=DNS:localhost\nextendedKeyUsage=serverAuth\n'
    'basicConstraints=CA:FALSE\n',
  );
  final steps = [
    [
      'req',
      '-x509',
      '-newkey',
      'rsa:2048',
      '-nodes',
      '-keyout',
      path('ca.key'),
      '-out',
      path('ca.pem'),
      '-days',
      '2',
      '-subj',
      '/CN=Verily Test CA',
      '-addext',
      'basicConstraints=critical,CA:TRUE',
      '-addext',
      'keyUsage=critical,keyCertSign,cRLSign',
    ],
    [
      'req',
      '-newkey',
      'rsa:2048',
      '-nodes',
      '-keyout',
      path('key.pem'),
      '-out',
      path('leaf.csr'),
      '-subj',
      '/CN=localhost',
    ],
    [
      'x509',
      '-req',
      '-in',
      path('leaf.csr'),
      '-CA',
      path('ca.pem'),
      '-CAkey',
      path('ca.key'),
      '-CAcreateserial',
      '-out',
      path('cert.pem'),
      '-days',
      '1',
      '-extfile',
      path('ext.cnf'),
    ],
  ];
  for (final arguments in steps) {
    try {
      final result = await Process.run('openssl', arguments);
      if (result.exitCode != 0) return null;
    } on ProcessException {
      return null;
    }
  }
  return (
    server: SecurityContext()
      ..useCertificateChain(path('cert.pem'))
      ..usePrivateKey(path('key.pem')),
    client: SecurityContext()..setTrustedCertificates(path('ca.pem')),
  );
}

void main() {
  group('Given the pinned-address sender and a hostile host', () {
    test(
      'when the host resolves to a private address then nothing connects',
      () async {
        final resolved = <String>[];
        final sender = PinnedAddressWebhookSender(
          resolve: (host) async {
            resolved.add(host);
            return [InternetAddress('127.0.0.1')];
          },
        );

        final result = await sender.post(
          url: Uri.parse('https://rebind.example.org/hook'),
          headers: const {},
          body: '{}',
          timeout: const Duration(seconds: 2),
        );

        expect(resolved, ['rebind.example.org']);
        expect(result.errorCode, 'host_not_public');
        expect(result.statusCode, isNull);
        expect(result.succeeded, isFalse);
      },
    );

    test(
      'when the URL is not an allowed webhook URL then it is refused',
      () async {
        final sender = PinnedAddressWebhookSender(
          resolve: (_) async => fail('must not resolve'),
        );

        for (final url in [
          'http://hooks.example.org/hook',
          'https://10.0.0.1/hook',
          'https://hooks.example.org:8443/hook',
        ]) {
          final result = await sender.post(
            url: Uri.parse(url),
            headers: const {},
            body: '{}',
            timeout: const Duration(seconds: 2),
          );
          expect(result.errorCode, 'invalid_url', reason: url);
        }
      },
    );

    test('when DNS hangs then the call times out', () async {
      final sender = PinnedAddressWebhookSender(
        resolve: (_) => Completer<List<InternetAddress>>().future,
      );

      final result = await sender.post(
        url: Uri.parse('https://slow.example.org/hook'),
        headers: const {},
        body: '{}',
        timeout: const Duration(milliseconds: 200),
      );

      expect(result.errorCode, 'timeout');
    });
  });

  group('Given a TLS webhook receiver on loopback', () {
    late Directory directory;
    late HttpServer server;
    late PinnedAddressWebhookSender sender;
    late Uri url;
    final received = <({Map<String, String> headers, String body})>[];
    var respond = (HttpRequest request) async {
      request.response.statusCode = 204;
      await request.response.close();
    };
    var skipReason = '';

    setUpAll(() async {
      directory = await Directory.systemTemp.createTemp('verily-webhook-tls');
      final tls = await _localhostTls(directory);
      if (tls == null) {
        skipReason = 'openssl is not available to make a test certificate';
        return;
      }
      server =
          (await HttpServer.bindSecure(
            InternetAddress.loopbackIPv4,
            0,
            tls.server,
          ))..listen((request) async {
            final body = await utf8.decodeStream(request);
            final headers = <String, String>{};
            request.headers.forEach((name, values) {
              headers[name] = values.join(',');
            });
            received.add((headers: headers, body: body));
            await respond(request);
          });
      url = Uri.parse('https://localhost:${server.port}/verily');
      sender = PinnedAddressWebhookSender(
        securityContext: tls.client,
        allowLoopbackForTests: true,
      );
    });

    tearDownAll(() async {
      if (skipReason.isEmpty) await server.close(force: true);
      await directory.delete(recursive: true);
    });

    setUp(() {
      received.clear();
      respond = (request) async {
        request.response.statusCode = 204;
        await request.response.close();
      };
    });

    test(
      'when an event is posted then TLS verifies and bytes arrive exactly',
      () async {
        if (skipReason.isNotEmpty) return markTestSkipped(skipReason);
        const body = '{"id":"vev_x","type":"attempt.verified","data":{}}';

        final result = await sender.post(
          url: url,
          headers: const {
            'verily-event': 'attempt.verified',
            'verily-signature': 't=1,v1=abc',
          },
          body: body,
          timeout: const Duration(seconds: 5),
        );

        expect(result.succeeded, isTrue);
        expect(result.statusCode, 204);
        expect(result.responseBody, isNull);
        expect(received.single.body, body);
        expect(received.single.headers['verily-event'], 'attempt.verified');
        expect(received.single.headers['verily-signature'], 't=1,v1=abc');
        expect(received.single.headers['content-type'], contains('json'));
        expect(received.single.headers['user-agent'], 'Verily-Webhooks/1');
      },
    );

    test(
      'when the receiver redirects then the redirect is not followed',
      () async {
        if (skipReason.isNotEmpty) return markTestSkipped(skipReason);
        respond = (request) async {
          request.response
            ..statusCode = 302
            ..headers.set('location', 'https://169.254.169.254/');
          await request.response.close();
        };

        final result = await sender.post(
          url: url,
          headers: const {},
          body: '{}',
          timeout: const Duration(seconds: 5),
        );

        expect(result.statusCode, 302);
        expect(result.succeeded, isFalse);
        expect(received, hasLength(1));
      },
    );

    test(
      'when a bounded body is requested then it is read up to the bound',
      () async {
        if (skipReason.isNotEmpty) return markTestSkipped(skipReason);
        respond = (request) async {
          request.response
            ..statusCode = 200
            ..write('{"verdict":"accepted"}');
          await request.response.close();
        };

        final small = await sender.post(
          url: url,
          headers: const {},
          body: '{}',
          timeout: const Duration(seconds: 5),
          maxResponseBytes: 64,
        );
        final tooSmall = await sender.post(
          url: url,
          headers: const {},
          body: '{}',
          timeout: const Duration(seconds: 5),
          maxResponseBytes: 8,
        );

        expect(small.responseBody, '{"verdict":"accepted"}');
        expect(tooSmall.errorCode, 'response_too_large');
      },
    );

    test('when the receiver stalls then the call times out', () async {
      if (skipReason.isNotEmpty) return markTestSkipped(skipReason);
      respond = (request) async {
        await Future<void>.delayed(const Duration(seconds: 2));
        request.response.statusCode = 200;
        await request.response.close();
      };

      final result = await sender.post(
        url: url,
        headers: const {},
        body: '{}',
        timeout: const Duration(milliseconds: 300),
      );

      expect(result.errorCode, 'timeout');
    });

    test('when the certificate is not trusted then TLS fails closed', () async {
      if (skipReason.isNotEmpty) return markTestSkipped(skipReason);
      final untrusting = PinnedAddressWebhookSender(
        securityContext: SecurityContext(),
        allowLoopbackForTests: true,
      );

      final result = await untrusting.post(
        url: url,
        headers: const {},
        body: '{}',
        timeout: const Duration(seconds: 5),
      );

      expect(result.errorCode, 'tls_failure');
    });
  });
}
