import 'dart:convert';
import 'dart:math';

import 'package:verily_server/src/security/secret_digest.dart';

/// App API keys have the form `vly_<keyId>.<secret>`.
///
/// `keyId` is 16 lowercase hex characters (8 random bytes) and is safe to
/// show and log. `secret` is 32 random bytes in unpadded base64url (43
/// characters). Verily stores only the SHA-256 of the complete credential,
/// so a lost credential is replaced, never recovered.
const appCredentialPrefix = 'vly_';

final RegExp _credentialPattern = RegExp(
  r'^vly_([0-9a-f]{16})\.([A-Za-z0-9_-]{43})$',
);
final RegExp _bearerPattern = RegExp(r'^Bearer (\S+)$', caseSensitive: false);

/// A credential that has just been created. [credential] is returned to the
/// owner exactly once; only [credentialHash] is persisted.
final class IssuedAppCredential {
  const IssuedAppCredential({
    required this.keyId,
    required this.credential,
    required this.credentialHash,
  });

  final String keyId;
  final String credential;
  final String credentialHash;
}

/// A syntactically valid credential presented by a caller.
final class PresentedAppCredential {
  const PresentedAppCredential._(this.keyId, this._credential);

  final String keyId;
  final String _credential;

  /// Constant-time check against the stored SHA-256 hex digest.
  bool matches(String storedHash) {
    return constantTimeEquals(secretSha256Hex(_credential), storedHash);
  }

  // Never print the secret, even in debug output.
  @override
  String toString() => 'PresentedAppCredential($keyId)';
}

IssuedAppCredential issueAppCredential({Random? random}) {
  final source = random ?? Random.secure();
  final keyId = [
    for (var index = 0; index < 8; index += 1)
      source.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();
  final secret = base64Url
      .encode([for (var index = 0; index < 32; index += 1) source.nextInt(256)])
      .replaceAll('=', '');
  final credential = '$appCredentialPrefix$keyId.$secret';
  return IssuedAppCredential(
    keyId: keyId,
    credential: credential,
    credentialHash: secretSha256Hex(credential),
  );
}

/// Parses a raw credential; returns null for anything malformed.
PresentedAppCredential? parseAppCredential(String value) {
  final match = _credentialPattern.firstMatch(value);
  if (match == null) return null;
  return PresentedAppCredential._(match.group(1)!, value);
}

/// Parses an `Authorization: Bearer vly_…` header value.
PresentedAppCredential? parseAppAuthorization(String? header) {
  if (header == null || header.length > 256) return null;
  final match = _bearerPattern.firstMatch(header.trim());
  if (match == null) return null;
  return parseAppCredential(match.group(1)!);
}
