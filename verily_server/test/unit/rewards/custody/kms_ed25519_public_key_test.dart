import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:verily_server/src/rewards/custody/kms_ed25519_public_key.dart';

void main() {
  final keyBytes = Uint8List.fromList(List.generate(32, (i) => i * 3 % 256));
  final validPem = _pem(keyBytes);

  test('parses a well-formed Ed25519 public key PEM', () {
    expect(parseEd25519PublicKeyPem(validPem), keyBytes);
  });

  test('parses CRLF line endings and surrounding whitespace', () {
    final crlf =
        '  \r\n-----BEGIN PUBLIC KEY-----\r\n${_body(keyBytes)}'
        '\r\n-----END PUBLIC KEY-----\r\n  ';
    expect(parseEd25519PublicKeyPem(crlf), keyBytes);
  });

  for (final (description, pem) in [
    ('empty', ''),
    ('not a PEM', 'definitely not a pem block'),
    ('missing header', '-----END PUBLIC KEY-----'),
    ('missing footer', '-----BEGIN PUBLIC KEY-----\n${_body(keyBytes)}'),
    (
      'a second PEM block',
      '$validPem\n$validPem',
    ),
    (
      'body line with leading space',
      '-----BEGIN PUBLIC KEY-----\n ${_body(keyBytes)}\n-----END PUBLIC KEY-----',
    ),
    (
      'body line with dash runs',
      '-----BEGIN PUBLIC KEY-----\n--${_body(keyBytes)}--\n'
          '-----END PUBLIC KEY-----',
    ),
    (
      'invalid base64 body',
      '-----BEGIN PUBLIC KEY-----\n!!!!not-base64!!!!\n-----END PUBLIC KEY-----',
    ),
  ]) {
    test('rejects $description', () {
      expect(() => parseEd25519PublicKeyPem(pem), throwsFormatException);
    });
  }

  test('rejects a 31-byte key', () {
    expect(
      () => parseEd25519PublicKeyPem(
        _pem(Uint8List.sublistView(keyBytes, 0, 31)),
      ),
      throwsFormatException,
    );
  });

  test('rejects a 33-byte key', () {
    final longer = Uint8List.fromList([...keyBytes, 0]);
    expect(
      () => parseEd25519PublicKeyPem(_pem(longer)),
      throwsFormatException,
    );
  });

  test('rejects 44 bytes without the Ed25519 DER prefix', () {
    final wrong = Uint8List.fromList([
      ...List.filled(12, 0x11),
      ...keyBytes,
    ]);
    expect(() => parseEd25519PublicKeyPem(_pem(wrong)), throwsFormatException);
  });
}

String _body(Uint8List keyBytes) => base64Encode(
  Uint8List.fromList([...ed25519SubjectPublicKeyInfoPrefix, ...keyBytes]),
);

String _pem(Uint8List keyBytes) =>
    '-----BEGIN PUBLIC KEY-----\n${_body(keyBytes)}\n-----END PUBLIC KEY-----';
