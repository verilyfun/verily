import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/apps/platform_keys.dart';
import 'package:verily_server/src/verification_requests/receipt_signing.dart';

List<int> _seed(int value) => List<int>.filled(32, value);

String _base64Url(List<int> bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');

Map<String, Object?> _segment(String token, int index) => jsonDecode(
  utf8.decode(
    base64Url.decode(
      token
          .split('.')[index]
          .padRight(
            (token.split('.')[index].length + 3) ~/ 4 * 4,
            '=',
          ),
    ),
  ),
) as Map<String, Object?>;

void main() {
  tearDown(() => PlatformKeys.current = const PlatformKeys());

  group('Given an Ed25519 receipt signer', () {
    final signer = ReceiptSigner.fromSeed(_seed(7));
    final claims = {
      'iss': receiptIssuer,
      'aud': 'app',
      'jti': 'request',
      'status': 'verified',
    };

    test(
      'when it signs then the header names EdDSA and the key thumbprint',
      () {
        final token = signer.sign(claims);
        final header = _segment(token, 0);

        expect(header, {'alg': 'EdDSA', 'typ': 'JWT', 'kid': signer.kid});
        expect(_segment(token, 1), claims);
        expect(token.contains('='), isFalse);
      },
    );

    test('when the kid is computed then it is the RFC 7638 thumbprint', () {
      final x = _base64Url(signer.publicKey);
      final expected = _base64Url(
        sha256
            .convert(utf8.encode('{"crv":"Ed25519","kty":"OKP","x":"$x"}'))
            .bytes,
      );

      expect(signer.kid, expected);
      expect(receiptKeyId(signer.publicKey), expected);
    });

    test('when verified against its JWKS then the claims come back', () {
      final jwks = {
        'keys': [receiptPublicJwk(signer.publicKey)],
      };

      expect(verifyReceipt(signer.sign(claims), jwks), claims);
    });

    test('when the payload is tampered then verification fails', () {
      final parts = signer.sign(claims).split('.');
      final forged = _base64Url(
        utf8.encode(jsonEncode({...claims, 'status': 'rejected'})),
      );
      final jwks = {
        'keys': [receiptPublicJwk(signer.publicKey)],
      };

      expect(verifyReceipt('${parts[0]}.$forged.${parts[2]}', jwks), isNull);
    });

    test('when the signature is truncated or the token is malformed then '
        'verification fails', () {
      final jwks = {
        'keys': [receiptPublicJwk(signer.publicKey)],
      };
      final parts = signer.sign(claims).split('.');

      expect(
        verifyReceipt('${parts[0]}.${parts[1]}.${parts[2].substring(4)}', jwks),
        isNull,
      );
      expect(verifyReceipt('not-a-token', jwks), isNull);
      expect(verifyReceipt('a.b.c', jwks), isNull);
      expect(verifyReceipt('${parts[0]}.${parts[1]}.!!', jwks), isNull);
    });

    test('when the kid names another key then verification fails', () {
      final other = ReceiptSigner.fromSeed(_seed(8));
      final jwks = {
        'keys': [receiptPublicJwk(other.publicKey)],
      };

      expect(verifyReceipt(signer.sign(claims), jwks), isNull);
    });

    test('when a JWK claims a kid that is not its thumbprint then '
        'verification fails', () {
      final other = ReceiptSigner.fromSeed(_seed(8));
      final jwks = {
        'keys': [
          {...receiptPublicJwk(other.publicKey), 'kid': signer.kid},
        ],
      };

      expect(verifyReceipt(signer.sign(claims), jwks), isNull);
    });

    test(
      'when the header asks for another algorithm then verification fails',
      () {
        final parts = signer.sign(claims).split('.');
        final none = _base64Url(
          utf8.encode(jsonEncode({'alg': 'none', 'kid': signer.kid})),
        );
        final jwks = {
          'keys': [receiptPublicJwk(signer.publicKey)],
        };

        expect(verifyReceipt('$none.${parts[1]}.${parts[2]}', jwks), isNull);
      },
    );

    test('when the seed is not 32 bytes then the signer refuses it', () {
      expect(
        () => ReceiptSigner.fromSeed(List<int>.filled(31, 1)),
        throwsArgumentError,
      );
    });
  });

  group('Given the configured receipt keys', () {
    test('when no key is configured then there is no signer and the JWKS is '
        'empty', () {
      expect(ReceiptSigning.signer, isNull);
      expect(ReceiptSigning.jwks(), {'keys': <Object?>[]});
    });

    test('when a key rotates then receipts signed by the retired key still '
        'verify against the published JWKS', () {
      final retired = ReceiptSigner.fromSeed(_seed(1));
      final oldReceipt = retired.sign({'jti': 'old'});
      PlatformKeys.current = PlatformKeys(
        receiptSigningKey: _seed(2),
        retiredReceiptPublicKeys: [retired.publicKey],
      );

      final jwks = ReceiptSigning.jwks();
      final keys = (jwks['keys']! as List).cast<Map<String, Object?>>();
      final active = ReceiptSigning.signer!;

      expect(keys.map((key) => key['kid']), [active.kid, retired.kid]);
      expect(keys.first, {
        'kty': 'OKP',
        'crv': 'Ed25519',
        'x': _base64Url(active.publicKey),
        'kid': active.kid,
        'use': 'sig',
        'alg': 'EdDSA',
      });
      expect(verifyReceipt(oldReceipt, jwks), {'jti': 'old'});
      expect(verifyReceipt(active.sign({'jti': 'new'}), jwks), {'jti': 'new'});
      expect(jsonEncode(jwks), isNot(contains('"d"')));
    });

    test('when a retired key repeats the active key then the JWKS lists it '
        'once', () {
      final active = ReceiptSigner.fromSeed(_seed(3));
      PlatformKeys.current = PlatformKeys(
        receiptSigningKey: _seed(3),
        retiredReceiptPublicKeys: [active.publicKey],
      );

      expect(ReceiptSigning.jwks()['keys']! as List, hasLength(1));
    });
  });
}
