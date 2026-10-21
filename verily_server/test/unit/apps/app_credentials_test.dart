import 'dart:math';

import 'package:test/test.dart';
import 'package:verily_server/src/apps/app_credentials.dart';
import 'package:verily_server/src/security/secret_digest.dart';

void main() {
  group('issueAppCredential', () {
    test('creates a vly_ credential whose hash is all that needs storing', () {
      final issued = issueAppCredential();

      expect(
        issued.credential,
        matches(RegExp(r'^vly_[0-9a-f]{16}\.[A-Za-z0-9_-]{43}$')),
      );
      expect(issued.credential, startsWith('vly_${issued.keyId}.'));
      expect(issued.credentialHash, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(issued.credentialHash, secretSha256Hex(issued.credential));
      expect(issued.credentialHash, isNot(contains(issued.credential)));
    });

    test('draws fresh key ids and secrets every time', () {
      final credentials = {
        for (var index = 0; index < 50; index += 1)
          issueAppCredential().credential,
      };

      expect(credentials, hasLength(50));
    });

    test('is deterministic for an injected random source', () {
      final first = issueAppCredential(random: Random(7));
      final second = issueAppCredential(random: Random(7));

      expect(first.credential, second.credential);
    });
  });

  group('parseAppAuthorization', () {
    final issued = issueAppCredential(random: Random(1));

    test('accepts a bearer credential and matches its stored hash', () {
      final presented = parseAppAuthorization(
        'Bearer ${issued.credential}',
      );

      expect(presented, isNotNull);
      expect(presented!.keyId, issued.keyId);
      expect(presented.matches(issued.credentialHash), isTrue);
    });

    test('treats the scheme case-insensitively', () {
      expect(
        parseAppAuthorization('bearer ${issued.credential}'),
        isNotNull,
      );
    });

    test('rejects a credential whose secret does not match the hash', () {
      final other = issueAppCredential(random: Random(2));
      final forged = 'vly_${issued.keyId}.${other.credential.split('.').last}';
      final presented = parseAppAuthorization('Bearer $forged');

      expect(presented, isNotNull);
      expect(presented!.matches(issued.credentialHash), isFalse);
    });

    test('rejects missing, malformed, and oversized values', () {
      for (final header in [
        null,
        '',
        issued.credential,
        'Basic ${issued.credential}',
        'Bearer vly_ABCDEF0123456789.${'a' * 43}',
        'Bearer vly_0123456789abcdef.${'a' * 42}',
        'Bearer vly_0123456789abcdef.${'a' * 43}!',
        'Bearer ${issued.credential} extra',
        'Bearer ${'a' * 300}',
      ]) {
        expect(parseAppAuthorization(header), isNull, reason: header);
      }
    });

    test('never prints the secret', () {
      final presented = parseAppAuthorization(
        'Bearer ${issued.credential}',
      )!;

      expect(presented.toString(), isNot(contains(issued.credential)));
      expect(presented.toString(), contains(issued.keyId));
    });
  });

  group('parseAppCredential', () {
    test('Given a raw issued credential when parsed then it matches only '
        'its own stored hash', () {
      final issued = issueAppCredential(random: Random(3));
      final other = issueAppCredential(random: Random(4));
      final presented = parseAppCredential(issued.credential)!;

      expect(presented.keyId, issued.keyId);
      expect(presented.matches(issued.credentialHash), isTrue);
      expect(presented.matches(other.credentialHash), isFalse);
      expect(presented.matches(''), isFalse);
    });

    test('Given a credential from another platform when parsed then it is '
        'refused', () {
      final secret = 'a' * 43;
      for (final value in [
        'kjp_0123456789abcdef.$secret',
        'VLY_0123456789abcdef.$secret',
        'vly_0123456789abcdef$secret',
        ' vly_0123456789abcdef.$secret',
      ]) {
        expect(parseAppCredential(value), isNull, reason: value);
      }
    });

    test('Given an issued credential when shown then the key id is public '
        'and the stored hash never reveals the secret', () {
      final issued = issueAppCredential(random: Random(5));
      final secret = issued.credential.split('.').last;

      expect(appCredentialPrefix, 'vly_');
      expect(issued.keyId, hasLength(16));
      expect(issued.credentialHash, isNot(contains(secret)));
      expect(issued.credentialHash, isNot(contains(issued.keyId)));
    });
  });

  group('constantTimeEquals', () {
    test('compares equal and unequal digests', () {
      expect(constantTimeEquals('abc', 'abc'), isTrue);
      expect(constantTimeEquals('abc', 'abd'), isFalse);
      expect(constantTimeEquals('abc', 'abcd'), isFalse);
    });
  });
}
