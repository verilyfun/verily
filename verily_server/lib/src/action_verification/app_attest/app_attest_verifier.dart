import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import 'package:verily_server/src/action_verification/app_attest/apple_app_attestation_root.dart';
import 'package:verily_server/src/action_verification/app_attest/authenticator_data.dart';
import 'package:verily_server/src/action_verification/app_attest/cbor.dart';
import 'package:verily_server/src/action_verification/key_attestation/der.dart';
import 'package:verily_server/src/action_verification/key_attestation/x509.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// The iOS bundle identifier Apple attests, unless configuration names
/// another.
const verilyIosBundleId = 'fun.verily.app';

/// The credential certificate extension holding the attestation nonce.
const appAttestNonceExtensionOid = '1.2.840.113635.100.8.2';

/// Reason codes App Attest verdicts carry. Every code starts with `capture_`,
/// so participants see the public `capture_not_verified`.
abstract final class AppAttestReason {
  static const valid = 'capture_app_attest_valid';
  static const malformed = 'capture_app_attest_malformed';
  static const chainInvalid = 'capture_app_attest_chain_invalid';
  static const untrustedRoot = 'capture_app_attest_untrusted_root';
  static const expired = 'capture_app_attest_expired';
  static const nonceMismatch = 'capture_app_attest_nonce_mismatch';
  static const keyInvalid = 'capture_app_attest_key_invalid';
  static const appMismatch = 'capture_app_attest_app_mismatch';
  static const counterInvalid = 'capture_app_attest_counter_invalid';
  static const environmentMismatch = 'capture_app_attest_environment';
  static const categoryRefused = 'capture_app_attest_category';
  static const signatureInvalid = 'capture_signature_invalid';
  static const replayed = 'capture_app_attest_replayed';
  static const keyUnknown = 'capture_app_attest_key_unknown';
  static const unconfigured = 'capture_app_attest_unconfigured';
}

/// Apple's `apple_validation_category_01` values that Verily can accept.
abstract final class AppleValidationCategory {
  static const testFlight = 2;
  static const development = 3;
  static const appStore = 4;

  /// Ad hoc, or an enterprise provisioning profile.
  static const adHoc = 5;
}

/// The app an App Attest key must belong to, and which builds may use it.
final class AppAttestPolicy {
  AppAttestPolicy({
    required this.teamId,
    this.bundleId = verilyIosBundleId,
    this.environment = AppAttestEnvironment.production,
    Set<int>? validationCategories,
  }) : validationCategories =
           validationCategories ??
           switch (environment) {
             AppAttestEnvironment.production => const {
               AppleValidationCategory.testFlight,
               AppleValidationCategory.appStore,
             },
             AppAttestEnvironment.development => const {
               AppleValidationCategory.development,
               AppleValidationCategory.adHoc,
             },
           };

  /// Reads `VERILY_APPLE_TEAM_ID`, `VERILY_IOS_BUNDLE_ID` (default
  /// `fun.verily.app`), and `VERILY_APP_ATTEST_ENVIRONMENT` (`production`,
  /// the default, or `development`). Without a team id App Attest is off and
  /// this returns null; a malformed value stops startup.
  static AppAttestPolicy? fromEnvironment([Map<String, String>? values]) {
    final environment = values ?? Platform.environment;
    final teamId = environment['VERILY_APPLE_TEAM_ID']?.trim() ?? '';
    final bundleId = environment['VERILY_IOS_BUNDLE_ID']?.trim() ?? '';
    final attestEnvironment =
        switch (environment['VERILY_APP_ATTEST_ENVIRONMENT']?.trim()) {
          null || '' || 'production' => AppAttestEnvironment.production,
          'development' => AppAttestEnvironment.development,
          final value => throw StateError(
            'VERILY_APP_ATTEST_ENVIRONMENT must be production or development, '
            'not $value.',
          ),
        };
    if (bundleId.isNotEmpty && !_bundleIdPattern.hasMatch(bundleId)) {
      throw StateError('VERILY_IOS_BUNDLE_ID must be a bundle identifier.');
    }
    if (teamId.isEmpty) return null;
    if (!_teamIdPattern.hasMatch(teamId)) {
      throw StateError(
        'VERILY_APPLE_TEAM_ID must be the ten-character Apple team id.',
      );
    }
    return AppAttestPolicy(
      teamId: teamId,
      bundleId: bundleId.isEmpty ? verilyIosBundleId : bundleId,
      environment: attestEnvironment,
    );
  }

  final String teamId;
  final String bundleId;
  final AppAttestEnvironment environment;

  /// The validation categories accepted when the authenticator data reports
  /// one: TestFlight and the App Store in production; development-signed and
  /// ad hoc builds in the sandbox.
  final Set<int> validationCategories;

  /// `TeamID.BundleID`, the relying party App Attest keys are bound to.
  String get appId => '$teamId.$bundleId';

  late final Uint8List rpIdHash = Uint8List.fromList(
    sha256.convert(utf8.encode(appId)).bytes,
  );

  /// The `aaguid` this policy's environment writes.
  Uint8List get aaguid => Uint8List.fromList(switch (environment) {
    AppAttestEnvironment.production => [
      ...ascii.encode('appattest'),
      ...List.filled(7, 0),
    ],
    AppAttestEnvironment.development => ascii.encode('appattestdevelop'),
  });
}

final _teamIdPattern = RegExp(r'^[A-Z0-9]{10}$');
final _bundleIdPattern = RegExp(r'^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$');

/// A key Apple attested, as the server stores it.
final class AppAttestedKey {
  const AppAttestedKey({
    required this.publicKey,
    required this.certificateChain,
    required this.receipt,
    required this.validationCategory,
    required this.bundleVersion,
  });

  /// `0x04 ‖ X ‖ Y`.
  final Uint8List publicKey;

  /// DER certificates, credential certificate first.
  final List<Uint8List> certificateChain;
  final Uint8List receipt;
  final int? validationCategory;
  final String? bundleVersion;
}

/// The outcome of verifying one App Attest attestation object.
final class AppAttestAttestationVerdict {
  const AppAttestAttestationVerdict.trusted(AppAttestedKey this.key)
    : reasonCode = AppAttestReason.valid;

  const AppAttestAttestationVerdict.untrusted(this.reasonCode) : key = null;

  final String reasonCode;

  /// Set only when the attestation is trusted.
  final AppAttestedKey? key;

  bool get trusted => key != null;
}

/// The outcome of verifying one App Attest assertion.
final class AppAssertionVerdict {
  const AppAssertionVerdict.trusted(int this.counter)
    : reasonCode = AppAttestReason.valid;

  const AppAssertionVerdict.untrusted(this.reasonCode) : counter = null;

  final String reasonCode;

  /// The assertion's counter; set only when the assertion is trusted.
  final int? counter;

  bool get trusted => counter != null;
}

/// Verifies App Attest attestation objects and assertions under [policy],
/// following Apple's "Validating apps that connect to your server".
final class AppAttestVerifier {
  AppAttestVerifier({
    required this.policy,
    List<X509Certificate>? trustAnchors,
  }) : trustAnchors = trustAnchors ?? appleAppAttestationRoots;

  final AppAttestPolicy policy;
  final List<X509Certificate> trustAnchors;

  /// Verifies [attestationObject] for the key the app names [keyId] (the
  /// 32-byte digest, decoded from Apple's base64), made with
  /// [clientDataHash].
  ///
  /// Every certificate, the credential certificate included, must be within
  /// its validity at [now]: Apple writes three-day credential certificates.
  AppAttestAttestationVerdict verifyAttestation({
    required List<int> attestationObject,
    required List<int> keyId,
    required List<int> clientDataHash,
    required DateTime now,
  }) {
    final List<Uint8List> x5c;
    final Uint8List receipt;
    final Uint8List authData;
    try {
      final object = decodeCbor(attestationObject);
      if (object is! Map<Object, Object> ||
          object.length != 3 ||
          object['fmt'] != 'apple-appattest') {
        return const AppAttestAttestationVerdict.untrusted(
          AppAttestReason.malformed,
        );
      }
      final statement = object['attStmt'];
      final data = object['authData'];
      if (statement is! Map<Object, Object> ||
          statement.length != 2 ||
          data is! Uint8List) {
        return const AppAttestAttestationVerdict.untrusted(
          AppAttestReason.malformed,
        );
      }
      final chain = statement['x5c'];
      final statementReceipt = statement['receipt'];
      if (chain is! List<Object> ||
          chain.length < 2 ||
          chain.length > _maxChainLength ||
          chain.any((entry) => entry is! Uint8List) ||
          statementReceipt is! Uint8List ||
          statementReceipt.isEmpty) {
        return const AppAttestAttestationVerdict.untrusted(
          AppAttestReason.malformed,
        );
      }
      x5c = chain.cast<Uint8List>();
      receipt = statementReceipt;
      authData = data;
    } on FormatException {
      return const AppAttestAttestationVerdict.untrusted(
        AppAttestReason.malformed,
      );
    }

    final List<X509Certificate> certificates;
    try {
      certificates = [for (final der in x5c) X509Certificate.parse(der)];
    } on FormatException {
      return const AppAttestAttestationVerdict.untrusted(
        AppAttestReason.chainInvalid,
      );
    }
    final pathFailure = _validatePath(certificates, now);
    if (pathFailure != null) {
      return AppAttestAttestationVerdict.untrusted(pathFailure);
    }

    final AppAttestAuthenticatorData data;
    try {
      data = AppAttestAuthenticatorData.attested(authData);
    } on FormatException {
      return const AppAttestAttestationVerdict.untrusted(
        AppAttestReason.malformed,
      );
    }
    final credential = data.credential!;

    final credentialCertificate = certificates.first;
    final nonce = sha256.convert([...authData, ...clientDataHash]).bytes;
    final Uint8List? certifiedNonce;
    try {
      certifiedNonce = _certifiedNonce(credentialCertificate);
    } on FormatException {
      return const AppAttestAttestationVerdict.untrusted(
        AppAttestReason.nonceMismatch,
      );
    }
    if (certifiedNonce == null || !_constantTimeEquals(certifiedNonce, nonce)) {
      return const AppAttestAttestationVerdict.untrusted(
        AppAttestReason.nonceMismatch,
      );
    }

    final certificateKey = credentialCertificate.publicKey;
    if (certificateKey is! EcPublicKeyInfo ||
        !certificateKey.isP256 ||
        !_constantTimeEquals(
          sha256.convert(certificateKey.point).bytes,
          keyId,
        ) ||
        !_constantTimeEquals(credential.credentialId, keyId) ||
        !_constantTimeEquals(credential.publicKey, certificateKey.point)) {
      return const AppAttestAttestationVerdict.untrusted(
        AppAttestReason.keyInvalid,
      );
    }
    if (!_constantTimeEquals(data.rpIdHash, policy.rpIdHash)) {
      return const AppAttestAttestationVerdict.untrusted(
        AppAttestReason.appMismatch,
      );
    }
    if (data.counter != 0) {
      return const AppAttestAttestationVerdict.untrusted(
        AppAttestReason.counterInvalid,
      );
    }
    if (!_constantTimeEquals(credential.aaguid, policy.aaguid)) {
      return const AppAttestAttestationVerdict.untrusted(
        AppAttestReason.environmentMismatch,
      );
    }
    if (!_categoryAllowed(data.validationCategory)) {
      return const AppAttestAttestationVerdict.untrusted(
        AppAttestReason.categoryRefused,
      );
    }
    return AppAttestAttestationVerdict.trusted(
      AppAttestedKey(
        publicKey: certificateKey.point,
        certificateChain: List.unmodifiable(x5c),
        receipt: receipt,
        validationCategory: data.validationCategory,
        bundleVersion: data.bundleVersion,
      ),
    );
  }

  /// Verifies an [assertion] over [clientData] by the stored [publicKey],
  /// whose last accepted counter was [previousCounter].
  ///
  /// The key signed `SHA-256(authenticatorData ‖ SHA-256(clientData))` with
  /// ECDSA P-256 over SHA-256; its counter must exceed [previousCounter], so
  /// no assertion is accepted twice.
  AppAssertionVerdict verifyAssertion({
    required List<int> assertion,
    required List<int> clientData,
    required Uint8List publicKey,
    required int previousCounter,
  }) {
    final Uint8List signature;
    final Uint8List authenticatorData;
    final AppAttestAuthenticatorData data;
    try {
      final object = decodeCbor(assertion);
      if (object is! Map<Object, Object> || object.length != 2) {
        return const AppAssertionVerdict.untrusted(AppAttestReason.malformed);
      }
      final objectSignature = object['signature'];
      final objectData = object['authenticatorData'];
      if (objectSignature is! Uint8List || objectData is! Uint8List) {
        return const AppAssertionVerdict.untrusted(AppAttestReason.malformed);
      }
      signature = objectSignature;
      authenticatorData = objectData;
      data = AppAttestAuthenticatorData.asserted(authenticatorData);
    } on FormatException {
      return const AppAssertionVerdict.untrusted(AppAttestReason.malformed);
    }

    final nonce = sha256.convert([
      ...authenticatorData,
      ...sha256.convert(clientData).bytes,
    ]).bytes;
    if (!_verifiesDerSignature(publicKey, nonce, signature)) {
      return const AppAssertionVerdict.untrusted(
        AppAttestReason.signatureInvalid,
      );
    }
    if (!_constantTimeEquals(data.rpIdHash, policy.rpIdHash)) {
      return const AppAssertionVerdict.untrusted(AppAttestReason.appMismatch);
    }
    if (data.counter <= previousCounter) {
      return const AppAssertionVerdict.untrusted(AppAttestReason.replayed);
    }
    if (!_categoryAllowed(data.validationCategory)) {
      return const AppAssertionVerdict.untrusted(
        AppAttestReason.categoryRefused,
      );
    }
    return AppAssertionVerdict.trusted(data.counter);
  }

  /// iOS versions that predate Apple's extensions report no category; the
  /// team, bundle, and environment checks still apply to them.
  bool _categoryAllowed(int? category) =>
      category == null || policy.validationCategories.contains(category);

  /// Returns a reason code when the chain does not lead to a pinned root,
  /// else null.
  String? _validatePath(List<X509Certificate> certificates, DateTime now) {
    final top = certificates.last;
    final anchor = trustAnchors
        .where(
          (anchor) =>
              anchor.subject.matches(top.issuer) &&
              top.isSignedBy(anchor.publicKey),
        )
        .firstOrNull;
    if (anchor == null) return AppAttestReason.untrustedRoot;
    for (var index = certificates.length - 1; index >= 0; index -= 1) {
      final certificate = certificates[index];
      if (index != certificates.length - 1) {
        final issuer = certificates[index + 1];
        if (!certificate.issuer.matches(issuer.subject) ||
            !certificate.isSignedBy(issuer.publicKey)) {
          return AppAttestReason.chainInvalid;
        }
      }
      // Only the credential certificate may certify a nonce, so no key
      // below a certificate authority can vouch for itself.
      if (index > 0 &&
          certificate.extensions.containsKey(appAttestNonceExtensionOid)) {
        return AppAttestReason.chainInvalid;
      }
      if (!certificate.isValidAt(now)) return AppAttestReason.expired;
    }
    return null;
  }
}

/// The nonce in the credential certificate: a SEQUENCE holding one
/// `[1] EXPLICIT OCTET STRING`. Null when the extension is absent.
Uint8List? _certifiedNonce(X509Certificate certificate) {
  final extension = certificate.extensions[appAttestNonceExtensionOid];
  if (extension == null) return null;
  final fields = parseDer(extension).sequence;
  if (fields.length != 1 || !fields.single.isContext(1)) {
    throw const DerFormatException('Malformed App Attest nonce.');
  }
  return fields.single.explicit.octets;
}

/// Whether the ASN.1 DER ECDSA [signature] signs [message] under the P-256
/// [point] with SHA-256.
bool _verifiesDerSignature(
  Uint8List point,
  List<int> message,
  Uint8List signature,
) {
  if (signature.length > _maxDerSignature) return false;
  try {
    final values = parseDer(signature).sequence;
    if (values.length != 2) return false;
    return verifyEcdsa(
      curve: ECCurve_secp256r1(),
      point: point,
      digest: SHA256Digest(),
      message: Uint8List.fromList(message),
      r: values[0].integer,
      s: values[1].integer,
    );
  } on FormatException {
    return false;
  }
}

bool _constantTimeEquals(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  var difference = 0;
  for (var index = 0; index < left.length; index += 1) {
    difference |= left[index] ^ right[index];
  }
  return difference == 0;
}

// Apple sends the credential certificate and one intermediate.
const _maxChainLength = 3;

// A DER P-256 signature is at most 72 bytes.
const _maxDerSignature = 80;
