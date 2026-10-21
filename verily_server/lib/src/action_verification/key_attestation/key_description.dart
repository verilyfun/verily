import 'dart:convert';
import 'dart:typed_data';

import 'package:verily_server/src/action_verification/key_attestation/der.dart';

/// The Android Key Attestation extension, `KeyDescription`.
const keyAttestationExtensionOid = '1.3.6.1.4.1.11129.2.1.17';

/// Where a key and its attestation live, from Android's `SecurityLevel`.
enum KeySecurityLevel {
  software(0),
  trustedEnvironment(1),
  strongBox(2);

  const KeySecurityLevel(this.value);

  final int value;

  static KeySecurityLevel from(int value) => values.firstWhere(
    (level) => level.value == value,
    orElse: () => throw DerFormatException('Unknown security level $value.'),
  );
}

/// `RootOfTrust.verifiedBootState`.
enum VerifiedBootState {
  verified(0),
  selfSigned(1),
  unverified(2),
  failed(3);

  const VerifiedBootState(this.value);

  final int value;

  static VerifiedBootState from(int value) => values.firstWhere(
    (state) => state.value == value,
    orElse: () => throw DerFormatException('Unknown boot state $value.'),
  );
}

/// KeyMint tag numbers and values this verifier reads.
abstract final class KeyMintTag {
  static const purpose = 1;
  static const algorithm = 2;
  static const keySize = 3;
  static const ecCurve = 10;
  static const origin = 702;
  static const rootOfTrust = 704;
  static const osVersion = 705;
  static const osPatchLevel = 706;
  static const attestationApplicationId = 709;

  static const purposeSign = 2;
  static const algorithmEc = 3;
  static const ecCurveP256 = 1;
  static const originGenerated = 0;
}

/// The parsed `KeyDescription` from an attestation certificate.
///
/// Only the fields Verily's policy reads are decoded. Unknown tags are
/// skipped, so newer KeyMint versions still parse; a repeated tag is refused,
/// because two values for one property are ambiguous.
final class KeyDescription {
  const KeyDescription({
    required this.attestationVersion,
    required this.attestationSecurityLevel,
    required this.keyMintVersion,
    required this.keyMintSecurityLevel,
    required this.attestationChallenge,
    required this.softwareEnforced,
    required this.hardwareEnforced,
  });

  /// Parses the extension's value: the DER `KeyDescription` SEQUENCE.
  factory KeyDescription.parse(List<int> extensionValue) {
    final fields = parseDer(extensionValue).sequence;
    if (fields.length != 8) {
      throw const DerFormatException('A KeyDescription has eight fields.');
    }
    return KeyDescription(
      attestationVersion: fields[0].smallInteger,
      attestationSecurityLevel: KeySecurityLevel.from(fields[1].smallInteger),
      keyMintVersion: fields[2].smallInteger,
      keyMintSecurityLevel: KeySecurityLevel.from(fields[3].smallInteger),
      attestationChallenge: Uint8List.fromList(fields[4].octets),
      // fields[5] is uniqueId, which apps cannot request.
      softwareEnforced: AuthorizationList.parse(fields[6]),
      hardwareEnforced: AuthorizationList.parse(fields[7]),
    );
  }

  final int attestationVersion;
  final KeySecurityLevel attestationSecurityLevel;
  final int keyMintVersion;
  final KeySecurityLevel keyMintSecurityLevel;
  final Uint8List attestationChallenge;
  final AuthorizationList softwareEnforced;
  final AuthorizationList hardwareEnforced;

  /// The app identity the keystore attested. KeyMint writes it in the
  /// software-enforced list; a value in both lists must agree.
  AttestationApplicationId? get attestationApplicationId {
    final software = softwareEnforced.attestationApplicationId;
    final hardware = hardwareEnforced.attestationApplicationId;
    if (software != null &&
        hardware != null &&
        !software.sameIdentityAs(hardware)) {
      throw const DerFormatException('Attestation application ids disagree.');
    }
    return hardware ?? software;
  }
}

/// The properties of one `AuthorizationList` that Verily's policy reads.
final class AuthorizationList {
  const AuthorizationList({
    this.purposes,
    this.algorithm,
    this.keySize,
    this.ecCurve,
    this.origin,
    this.rootOfTrust,
    this.osVersion,
    this.osPatchLevel,
    this.attestationApplicationId,
  });

  factory AuthorizationList.parse(DerElement element) {
    final seen = <int>{};
    Set<int>? purposes;
    int? algorithm;
    int? keySize;
    int? ecCurve;
    int? origin;
    RootOfTrust? rootOfTrust;
    int? osVersion;
    int? osPatchLevel;
    AttestationApplicationId? applicationId;
    for (final entry in element.sequence) {
      if (entry.tagClass != DerTagClass.contextSpecific) {
        throw const DerFormatException('Authorization tags are explicit.');
      }
      if (!seen.add(entry.tagNumber)) {
        throw DerFormatException('Tag ${entry.tagNumber} is repeated.');
      }
      final value = entry.explicit;
      switch (entry.tagNumber) {
        case KeyMintTag.purpose:
          purposes = {for (final item in value.set) item.smallInteger};
        case KeyMintTag.algorithm:
          algorithm = value.smallInteger;
        case KeyMintTag.keySize:
          keySize = value.smallInteger;
        case KeyMintTag.ecCurve:
          ecCurve = value.smallInteger;
        case KeyMintTag.origin:
          origin = value.smallInteger;
        case KeyMintTag.rootOfTrust:
          rootOfTrust = RootOfTrust.parse(value);
        case KeyMintTag.osVersion:
          osVersion = value.smallInteger;
        case KeyMintTag.osPatchLevel:
          osPatchLevel = value.smallInteger;
        case KeyMintTag.attestationApplicationId:
          applicationId = AttestationApplicationId.parse(value.octets);
      }
    }
    return AuthorizationList(
      purposes: purposes,
      algorithm: algorithm,
      keySize: keySize,
      ecCurve: ecCurve,
      origin: origin,
      rootOfTrust: rootOfTrust,
      osVersion: osVersion,
      osPatchLevel: osPatchLevel,
      attestationApplicationId: applicationId,
    );
  }

  final Set<int>? purposes;
  final int? algorithm;
  final int? keySize;
  final int? ecCurve;
  final int? origin;
  final RootOfTrust? rootOfTrust;
  final int? osVersion;

  /// `YYYYMM`.
  final int? osPatchLevel;
  final AttestationApplicationId? attestationApplicationId;
}

/// The device's boot integrity as the secure hardware saw it.
final class RootOfTrust {
  const RootOfTrust({
    required this.verifiedBootKey,
    required this.deviceLocked,
    required this.verifiedBootState,
  });

  factory RootOfTrust.parse(DerElement element) {
    final fields = element.sequence;
    if (fields.length != 3 && fields.length != 4) {
      throw const DerFormatException('Malformed RootOfTrust.');
    }
    return RootOfTrust(
      verifiedBootKey: Uint8List.fromList(fields[0].octets),
      deviceLocked: fields[1].boolean,
      verifiedBootState: VerifiedBootState.from(fields[2].smallInteger),
    );
  }

  final Uint8List verifiedBootKey;
  final bool deviceLocked;
  final VerifiedBootState verifiedBootState;
}

/// The packages and signing certificates of the app that owns the key.
final class AttestationApplicationId {
  const AttestationApplicationId({
    required this.packageNames,
    required this.signatureDigests,
  });

  factory AttestationApplicationId.parse(List<int> bytes) {
    final fields = parseDer(bytes).sequence;
    if (fields.length != 2) {
      throw const DerFormatException('Malformed AttestationApplicationId.');
    }
    final packages = fields[0].set;
    final signatures = fields[1].set;
    // Upstream's limits: a shared-UID app lists its packages; APK signature
    // rotation lists a short history of certificates.
    if (packages.length > _maxPackages || signatures.length > _maxSignatures) {
      throw const DerFormatException('AttestationApplicationId is too large.');
    }
    return AttestationApplicationId(
      packageNames: {
        for (final package in packages)
          switch (package.sequence) {
            [final name, final version] when version.integer >= BigInt.zero =>
              utf8.decode(name.octets),
            _ => throw const DerFormatException('Malformed package info.'),
          },
      },
      signatureDigests: {
        for (final signature in signatures) _hex(signature.octets),
      },
    );
  }

  final Set<String> packageNames;

  /// Lowercase hex SHA-256 digests of the app's signing certificates.
  final Set<String> signatureDigests;

  bool sameIdentityAs(AttestationApplicationId other) =>
      _sameSet(other.packageNames, packageNames) &&
      _sameSet(other.signatureDigests, signatureDigests);
}

const _maxPackages = 32;
const _maxSignatures = 10;

bool _sameSet(Set<String> left, Set<String> right) =>
    left.length == right.length && left.containsAll(right);

String _hex(List<int> bytes) =>
    bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
