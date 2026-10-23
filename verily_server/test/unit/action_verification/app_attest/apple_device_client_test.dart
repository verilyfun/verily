import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/app_attest/apple_device_client.dart';
import 'package:verily_server/src/action_verification/key_attestation/x509.dart';
import 'package:verily_server/src/generated/protocol.dart';

import '../../../integration/test_tools/app_attest_test_authority.dart';
import '../../../integration/test_tools/der_writer.dart';

// Public test-only key: scalar 1, never used by any real service.
final _pem =
    '-----BEGIN PRIVATE KEY-----\n${base64Encode(derSequence([
      derInteger(BigInt.zero),
      derSequence([derOid(X509Oid.ecPublicKey), derOid(X509Oid.secp256r1)]),
      derOctets(derSequence([derInteger(BigInt.one), derOctets(fixedWidth32(BigInt.one))])),
    ]))}\n-----END PRIVATE KEY-----';
final _now = DateTime.utc(2026, 10, 23);
final Session _session = _UnusedSession();
final String _token = base64Encode(utf8.encode('device-token'));

void main() {
  test('DeviceCheck JWT has APNs claims and a valid JOSE P-256 signature', () {
    final jwt = deviceCheckJwt(
      pem: _pem,
      keyId: 'KEYID12345',
      teamId: testAppleTeamId,
      now: _now,
    );
    final parts = jwt.split('.');
    Object decode(String s) =>
        jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(s))))
            as Object;
    expect(decode(parts[0]), {
      'alg': 'ES256',
      'kid': 'KEYID12345',
      'typ': 'JWT',
    });
    expect(decode(parts[1]), {
      'iss': testAppleTeamId,
      'iat': _now.millisecondsSinceEpoch ~/ 1000,
    });
    final signature = base64Url.decode(base64Url.normalize(parts[2]));
    expect(signature, hasLength(64));
    final point = base64Decode(
      'BGsX0fLhLEJH+Lzm5WOkQPJ3A32BLeszoPShOUXYmMKWT+NC4v4af5uO5+tKfA+eFivOM1drMV7Oy7ZAaDe/UfU=',
    );
    expect(
      EcPublicKeyInfo(X509Oid.secp256r1, point).verifies(
        Uint8List.fromList(ascii.encode('${parts[0]}.${parts[1]}')),
        X509Oid.ecdsaWithSha256,
        Uint8List.fromList(
          derSequence([
            derInteger(unsignedBigInt(signature.sublist(0, 32))),
            derInteger(unsignedBigInt(signature.sublist(32))),
          ]),
        ),
      ),
      isTrue,
    );
    expect(
      () => deviceCheckJwt(
        pem: 'invalid',
        keyId: 'KEYID12345',
        teamId: testAppleTeamId,
        now: _now,
      ),
      throwsA(isA<AppleDeviceUnavailable>()),
    );
  });

  for (final environment in AppAttestEnvironment.values) {
    test(
      '$environment uses fixed hosts, receipt auth and DeviceCheck Bearer JSON',
      () async {
        final requests = <http.Request>[];
        final client = HttpAppleDeviceClient(
          policy: testAppAttestPolicy(environment: environment),
          keyId: 'KEYID12345',
          privateKeyReader: (_) => _pem,
          clock: () => _now,
          client: MockClient((request) async {
            requests.add(request);
            return http.Response(
              request.url.path.endsWith('attestationData')
                  ? 'new-receipt'
                  : request.url.path.endsWith('query_two_bits')
                  ? '{"bit0":true,"bit1":false}'
                  : '',
              200,
            );
          }),
        );
        expect(
          await client.refreshReceipt(_session, 'previous-receipt'),
          'new-receipt',
        );
        final bits = await client.queryBits(_session, _token);
        expect(bits.banned, isTrue);
        expect(bits.reviewRequired, isFalse);
        await client.updateBits(
          _session,
          _token,
          const AppleDeviceBits(banned: true, reviewRequired: true),
        );
        final sandbox = environment == AppAttestEnvironment.development;
        expect(
          requests[0].url.toString(),
          'https://${sandbox ? 'data-development' : 'data'}.appattest.apple.com/v1/attestationData',
        );
        expect(requests[0].body, 'previous-receipt');
        expect(
          requests[0].headers['authorization'],
          isNot(startsWith('Bearer ')),
        );
        expect(
          requests[1].url.host,
          sandbox
              ? 'api.development.devicecheck.apple.com'
              : 'api.devicecheck.apple.com',
        );
        expect(requests[1].headers['authorization'], startsWith('Bearer '));
        expect(requests.every((r) => !r.followRedirects), isTrue);
        final query = jsonDecode(requests[1].body) as Map<String, dynamic>;
        final update = jsonDecode(requests[2].body) as Map<String, dynamic>;
        expect(query['device_token'], _token);
        expect(query['timestamp'], _now.millisecondsSinceEpoch);
        expect(query['transaction_id'], isNot(update['transaction_id']));
        expect(update['bit0'], isTrue);
        expect(update['bit1'], isTrue);
      },
    );
  }

  test('missing configuration never makes HTTP requests', () async {
    final client = HttpAppleDeviceClient(
      policy: testAppAttestPolicy(),
      keyId: '',
      privateKeyReader: (_) => null,
      client: MockClient((_) async => throw StateError('HTTP forbidden')),
    );
    await expectLater(
      client.refreshReceipt(_session, 'receipt'),
      throwsA(isA<AppleDeviceUnavailable>()),
    );
  });

  test(
    "first-seen devices are clean only on Apple's exact success response",
    () async {
      final client = HttpAppleDeviceClient(
        policy: testAppAttestPolicy(),
        keyId: 'KEYID12345',
        privateKeyReader: (_) => _pem,
        client: MockClient(
          (_) async => http.Response('Bit State Not Found', 200),
        ),
      );
      final bits = await client.queryBits(_session, _token);
      expect(bits.banned || bits.reviewRequired, isFalse);
    },
  );

  test(
    'non-200, malformed and oversized responses fail closed with no retry',
    () async {
      for (final (status, body) in [
        (304, ''),
        (401, ''),
        (429, ''),
        (503, ''),
        (302, ''),
        (200, '{}'),
        (200, '{"bit0":0,"bit1":false}'),
        (200, 'not json'),
        (200, 'x' * 50000),
      ]) {
        var requests = 0;
        final client = HttpAppleDeviceClient(
          policy: testAppAttestPolicy(),
          keyId: 'KEYID12345',
          privateKeyReader: (_) => _pem,
          client: MockClient((_) async {
            requests++;
            return http.Response(body, status);
          }),
        );
        await expectLater(
          client.queryBits(_session, _token),
          throwsA(isA<AppleDeviceUnavailable>()),
        );
        expect(requests, 1);
      }
      for (final token in ['', 'abc\ndef', 'x' * 9000, '@@@']) {
        expect(validDeviceCheckToken(token), isFalse);
      }
    },
  );
}

class _UnusedSession implements Session {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
