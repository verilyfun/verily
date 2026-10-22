import 'dart:typed_data';

import 'package:verily_server/src/action_verification/app_attest/cbor.dart';

/// The WebAuthn authenticator data App Attest signs, with Apple's fields.
///
/// An attestation's data carries the attested credential (environment,
/// key id, and public key); an assertion's carries only the relying party,
/// counter, and Apple's extensions. Apple's flag bits do not reliably
/// announce which parts follow (its own sample sets no extension flag yet
/// carries extensions), so both are read by position instead.
final class AppAttestAuthenticatorData {
  const AppAttestAuthenticatorData._({
    required this.rpIdHash,
    required this.counter,
    required this.credential,
    required this.validationCategory,
    required this.bundleVersion,
  });

  /// Parses an attestation's authenticator data: the fixed header, the
  /// attested credential with its COSE key, then optional extensions.
  factory AppAttestAuthenticatorData.attested(Uint8List bytes) {
    final reader = _Reader(bytes);
    final rpIdHash = reader.take(32);
    reader.take(1); // Flags; see the class comment.
    final counter = reader.uint32();
    final aaguid = reader.take(16);
    final credentialId = reader.take(reader.uint16());
    final (cose, coseEnd) = _item(bytes, reader.offset);
    reader.offset = coseEnd;
    final extensions = _AppleExtensions.parse(bytes, reader.offset);
    return AppAttestAuthenticatorData._(
      rpIdHash: rpIdHash,
      counter: counter,
      credential: AttestedCredential._(
        aaguid: aaguid,
        credentialId: credentialId,
        publicKey: _coseP256Point(cose),
      ),
      validationCategory: extensions.validationCategory,
      bundleVersion: extensions.bundleVersion,
    );
  }

  /// Parses an assertion's authenticator data: the fixed header, then
  /// optional extensions.
  factory AppAttestAuthenticatorData.asserted(Uint8List bytes) {
    final reader = _Reader(bytes);
    final rpIdHash = reader.take(32);
    reader.take(1); // Flags; see the class comment.
    final counter = reader.uint32();
    final extensions = _AppleExtensions.parse(bytes, reader.offset);
    return AppAttestAuthenticatorData._(
      rpIdHash: rpIdHash,
      counter: counter,
      credential: null,
      validationCategory: extensions.validationCategory,
      bundleVersion: extensions.bundleVersion,
    );
  }

  /// SHA-256 of the App ID (`TeamID.BundleID`) the key belongs to.
  final Uint8List rpIdHash;

  /// How many assertions the key has made: zero in an attestation.
  final int counter;

  /// Set only on an attestation's data.
  final AttestedCredential? credential;

  /// Apple's `apple_validation_category_01`: how the app binary was
  /// distributed. Absent on iOS versions that predate it (iOS 18 wrote none).
  final int? validationCategory;

  /// Apple's `apple_bundle_version_01`: the app's build number. Absent on iOS
  /// versions that predate it.
  final String? bundleVersion;
}

/// The key an attestation certifies.
final class AttestedCredential {
  const AttestedCredential._({
    required this.aaguid,
    required this.credentialId,
    required this.publicKey,
  });

  /// `appattest` and seven zero bytes in production, `appattestdevelop` in
  /// Apple's sandbox.
  final Uint8List aaguid;

  /// SHA-256 of [publicKey]: the key identifier the app was given.
  final Uint8List credentialId;

  /// The credential's P-256 key from its COSE encoding, `0x04 ‖ X ‖ Y`.
  final Uint8List publicKey;
}

/// The extension map recent iOS versions append to authenticator data.
final class _AppleExtensions {
  const _AppleExtensions(this.validationCategory, this.bundleVersion);

  /// Reads the extension map that fills everything from [offset], or none
  /// when nothing follows.
  factory _AppleExtensions.parse(Uint8List bytes, int offset) {
    if (offset == bytes.length) return const _AppleExtensions(null, null);
    final (map, end) = _item(bytes, offset);
    if (end != bytes.length || map is! Map<Object, Object>) {
      throw const CborFormatException('Malformed authenticator extensions.');
    }
    if (map.keys.any((key) => key is! String)) {
      throw const CborFormatException('Extension names are text.');
    }
    // Apple writes the category as four little-endian bytes.
    final validationCategory = switch (map[_validationCategoryKey]) {
      null => null,
      final Uint8List bytes when bytes.length == 4 => ByteData.sublistView(
        bytes,
      ).getUint32(0, Endian.little),
      _ => throw const CborFormatException(
        'The validation category is a UInt32.',
      ),
    };
    final bundleVersion = switch (map[_bundleVersionKey]) {
      null => null,
      final String text when text.isNotEmpty && text.length <= 64 => text,
      _ => throw const CborFormatException('The bundle version is short text.'),
    };
    return _AppleExtensions(validationCategory, bundleVersion);
  }

  final int? validationCategory;
  final String? bundleVersion;
}

const _validationCategoryKey = 'apple_validation_category_01';
const _bundleVersionKey = 'apple_bundle_version_01';

/// Decodes a COSE EC2 P-256 ES256 key (RFC 9053) into an uncompressed point,
/// refusing any other key type, algorithm, curve, or extra parameter.
Uint8List _coseP256Point(Object cose) {
  if (cose is! Map<Object, Object> || cose.length != 5) {
    throw const CborFormatException('Expected a COSE EC2 key.');
  }
  final x = cose[-2];
  final y = cose[-3];
  if (cose[1] != 2 ||
      cose[3] != -7 ||
      cose[-1] != 1 ||
      x is! Uint8List ||
      y is! Uint8List ||
      x.length != 32 ||
      y.length != 32) {
    throw const CborFormatException('Expected a P-256 ES256 COSE key.');
  }
  return Uint8List.fromList([0x04, ...x, ...y]);
}

(Object, int) _item(Uint8List bytes, int offset) {
  if (offset >= bytes.length) {
    throw const CborFormatException('Truncated authenticator data.');
  }
  return readCborItem(bytes, offset);
}

final class _Reader {
  _Reader(this._bytes);

  final Uint8List _bytes;
  int offset = 0;

  Uint8List take(int length) {
    if (length > _bytes.length - offset) {
      throw const CborFormatException('Truncated authenticator data.');
    }
    final value = Uint8List.fromList(
      Uint8List.sublistView(_bytes, offset, offset + length),
    );
    offset += length;
    return value;
  }

  int uint16() => ByteData.sublistView(take(2)).getUint16(0);

  int uint32() => ByteData.sublistView(take(4)).getUint32(0);
}
