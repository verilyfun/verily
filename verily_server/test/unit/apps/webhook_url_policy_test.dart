import 'dart:io';

import 'package:test/test.dart';
import 'package:verily_server/src/apps/webhooks/webhook_url_policy.dart';
import 'package:verily_server/src/generated/protocol.dart';

Matcher _refused() => throwsA(
  isA<AppPlatformException>().having(
    (error) => error.problem,
    'problem',
    AppPlatformProblem.invalidWebhookUrl,
  ),
);

HostResolver _resolvesTo(List<String> addresses) =>
    (host) async => [for (final value in addresses) InternetAddress(value)];

void main() {
  group('Given the public-address classifier', () {
    test('when an address is globally routable then it is public', () {
      for (final value in [
        '8.8.8.8',
        '1.1.1.1',
        '93.184.216.34',
        '2606:4700:4700::1111',
        '2001:4860:4860::8888',
      ]) {
        expect(isPublicAddress(InternetAddress(value)), isTrue, reason: value);
      }
    });

    test('when an address is private, local, or reserved then it is not', () {
      for (final value in [
        '0.0.0.0',
        '10.1.2.3',
        '100.64.0.1',
        '127.0.0.1',
        '169.254.169.254',
        '172.16.0.1',
        '172.31.255.255',
        '192.0.0.8',
        '192.0.2.1',
        '192.168.1.1',
        '198.18.0.1',
        '198.51.100.7',
        '203.0.113.9',
        '224.0.0.1',
        '240.0.0.1',
        '255.255.255.255',
        '::',
        '::1',
        '::ffff:127.0.0.1',
        '::ffff:10.0.0.1',
        '64:ff9b::7f00:1',
        '2002:7f00:1::',
        'fc00::1',
        'fd12:3456::1',
        'fe80::1',
        'fec0::1',
        'ff02::1',
        '2001:db8::1',
        '2001::1',
        '100::1',
      ]) {
        expect(isPublicAddress(InternetAddress(value)), isFalse, reason: value);
      }
    });

    test('when IPv4 is mapped into IPv6 then the IPv4 address decides', () {
      expect(isPublicAddress(InternetAddress('::ffff:8.8.8.8')), isTrue);
      expect(isPublicAddress(InternetAddress('64:ff9b::808:808')), isTrue);
    });
  });

  group('Given a webhook URL to save', () {
    test('when it is https on the standard port then its shape passes', () {
      expect(
        parseWebhookUrl('https://hooks.example.org/verily?x=1').host,
        'hooks.example.org',
      );
      expect(parseWebhookUrl('https://hooks.example.org:443/a').port, 443);
      expect(parseWebhookUrl('https://93.184.216.34/hook').host, isNotEmpty);
    });

    test('when it breaks a transport rule then it is refused', () {
      for (final value in [
        '',
        'http://hooks.example.org/verily',
        'ftp://hooks.example.org/verily',
        'https://user:pass@hooks.example.org/verily',
        'https://hooks.example.org/verily#fragment',
        'https://hooks.example.org:8443/verily',
        'https:///no-host',
        'https://hooks.example.org/${'a' * 2050}',
      ]) {
        expect(() => parseWebhookUrl(value), _refused(), reason: value);
      }
    });

    test('when it names a private host then it is refused', () {
      for (final value in [
        'https://localhost/hook',
        'https://api.localhost/hook',
        'https://printer.local/hook',
        'https://db.internal/hook',
        'https://router.lan/hook',
        'https://intranet/hook',
        'https://127.0.0.1/hook',
        'https://10.0.0.5/hook',
        'https://169.254.169.254/latest/meta-data',
        'https://[::1]/hook',
        'https://[fd00::1]/hook',
        'https://[::ffff:127.0.0.1]/hook',
      ]) {
        expect(() => parseWebhookUrl(value), _refused(), reason: value);
      }
    });

    test(
      'when the host resolves only to public addresses then it is saved',
      () async {
        final uri = await validateWebhookUrl(
          'https://hooks.example.org/verily',
          resolve: _resolvesTo(['93.184.216.34', '2606:2800:220:1::1']),
        );

        expect(uri.toString(), 'https://hooks.example.org/verily');
      },
    );

    test('when any resolved address is private then it is refused', () async {
      await expectLater(
        validateWebhookUrl(
          'https://hooks.example.org/verily',
          resolve: _resolvesTo(['93.184.216.34', '10.0.0.7']),
        ),
        _refused(),
      );
    });

    test('when the host does not resolve then it is refused', () async {
      await expectLater(
        validateWebhookUrl(
          'https://hooks.example.org/verily',
          resolve: (_) async => const [],
        ),
        _refused(),
      );
      await expectLater(
        validateWebhookUrl(
          'https://hooks.example.org/verily',
          resolve: (_) async => throw const SocketException('no such host'),
        ),
        _refused(),
      );
    });

    test('when the host is a public IP literal then no lookup runs', () async {
      var lookups = 0;
      await validateWebhookUrl(
        'https://93.184.216.34/hook',
        resolve: (host) async {
          lookups += 1;
          return const [];
        },
      );

      expect(lookups, 0);
    });
  });
}
