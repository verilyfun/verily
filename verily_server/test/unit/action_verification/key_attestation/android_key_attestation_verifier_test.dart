import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/key_attestation/android_key_attestation_verifier.dart';
import 'package:verily_server/src/action_verification/key_attestation/attestation_status_list.dart';
import 'package:verily_server/src/action_verification/key_attestation/key_description.dart';
import 'package:verily_server/src/action_verification/key_attestation/x509.dart';

import '../../../integration/test_tools/key_attestation_test_chain.dart';

/// Chains recorded from real devices by Google's `android/keyattestation`
/// (see `vectors/README.md`), checked against the production roots.
void main() {
  group('Given a real device chain', () {
    final trusted = {
      'caiman-sdk36_SB_EC_RKP': KeySecurityLevel.strongBox,
      'caiman-sdk36_TEE_EC_RKP': KeySecurityLevel.trustedEnvironment,
      'tegu-sdk36_SB_EC_2026_ROOT': KeySecurityLevel.strongBox,
      'frankel-sdk37_TEE_EC_2026': KeySecurityLevel.trustedEnvironment,
    };
    for (final MapEntry(key: name, value: level) in trusted.entries) {
      test('when $name meets the policy then it is trusted at '
          '${level.name}', () async {
        final vector = _Vector.load(name);

        final verdict = await vector.verify();

        expect(verdict.reasonCode, KeyAttestationReason.valid);
        expect(verdict.trusted, isTrue);
        expect(verdict.securityLevel, level);
        expect(verdict.publicKey, vector.leafPoint);
        // Remotely provisioned: the attestation key names the device.
        expect(
          verdict.deviceKeyId,
          sha256
              .convert(vector.certificates[1].subjectPublicKeyInfo)
              .toString(),
        );
      });
    }

    test('when a factory chain has expired intermediates then they are '
        'tolerated, because factory keys cannot rotate', () async {
      final vector = _Vector.load('sony-xperia10-iii-sdk33_TEE_EC');
      expect(
        vector.certificates[1].notAfter.isBefore(vector.createdAt),
        isTrue,
        reason: 'The vector should exercise an expired intermediate.',
      );

      // Its July 2023 patch is three years older than the key.
      final verdict = await vector.verify(maxPatchAgeMonths: 36);

      expect(verdict.trusted, isTrue);
      expect(verdict.securityLevel, KeySecurityLevel.trustedEnvironment);
      // A factory attestation key is shared by a batch of devices.
      expect(verdict.deviceKeyId, isNull);
    });

    test('when the OS patch is older than the policy allows then it is '
        'refused', () async {
      final vector = _Vector.load('sony-xperia10-iii-sdk33_TEE_EC');

      final verdict = await vector.verify();

      expect(verdict.reasonCode, KeyAttestationReason.patchOutdated);
      expect(verdict.publicKey, vector.leafPoint);
    });

    test('when the bootloader is unlocked then it is refused', () async {
      final verdict = await _Vector.load('akita-sdk34_TEE_EC_NONE').verify();

      expect(verdict.trusted, isFalse);
      expect(verdict.reasonCode, KeyAttestationReason.bootUntrusted);
    });

    test('when the capture key is RSA then no P-256 key is offered for the '
        'signature', () async {
      final verdict = await _Vector.load('akita-sdk34_TEE_RSA_NONE').verify();

      expect(verdict.trusted, isFalse);
      expect(verdict.publicKey, isNull);
    });

    test('when the capture key is ML-DSA then no P-256 key is offered for '
        'the signature', () async {
      final verdict = await _Vector.load('tokay-sdk37_TEE_MLDSA_RKP').verify();

      expect(verdict.trusted, isFalse);
      expect(verdict.publicKey, isNull);
    });

    test('when the chain ends in the software attestation root then it is '
        'untrusted', () async {
      final verdict = await _Vector.load('marlin-sdk29_TEE_EC_NONE').verify();

      expect(verdict.reasonCode, KeyAttestationReason.untrustedRoot);
    });

    test(
      'when the challenge is not the one issued then it is refused',
      () async {
        final verdict = await _Vector.load(
          'caiman-sdk36_SB_EC_RKP',
        ).verify(challenge: utf8.encode('another challenge'));

        expect(verdict.reasonCode, KeyAttestationReason.challengeMismatch);
      },
    );

    test('when the app package or signing certificate differ then it is '
        'refused', () async {
      final vector = _Vector.load('caiman-sdk36_TEE_EC_RKP');

      final otherPackage = await vector.verify(packageName: 'fun.verily.fake');
      final otherCertificate = await vector.verify(
        signingCertificateDigests: {'cd' * 32},
      );
      final unconfigured = await vector.verify(signingCertificateDigests: {});

      expect(otherPackage.reasonCode, KeyAttestationReason.appMismatch);
      expect(otherCertificate.reasonCode, KeyAttestationReason.appMismatch);
      expect(unconfigured.reasonCode, KeyAttestationReason.unconfigured);
    });

    test('when a serial in the chain is on the status list then it is '
        'refused', () async {
      final vector = _Vector.load('caiman-sdk36_SB_EC_RKP');

      final verdict = await vector.verify(
        status: _FixedStatus(
          AttestationStatusList([vector.certificates[1].serialHex]),
        ),
      );

      expect(verdict.reasonCode, KeyAttestationReason.revoked);
    });

    test('when no status list is available then it fails closed', () async {
      final verdict = await _Vector.load(
        'caiman-sdk36_SB_EC_RKP',
      ).verify(status: const _UnavailableStatus());

      expect(verdict.reasonCode, KeyAttestationReason.statusUnavailable);
    });

    test('when a remotely provisioned certificate has expired then it is '
        'refused', () async {
      final vector = _Vector.load('caiman-sdk36_SB_EC_RKP');

      final verdict = await vector.verify(
        now: vector.certificates[1].notAfter.add(const Duration(days: 1)),
      );

      expect(verdict.reasonCode, KeyAttestationReason.expired);
    });

    test('when an intermediate signature is tampered with then the chain is '
        'invalid', () async {
      final vector = _Vector.load('caiman-sdk36_SB_EC_RKP');
      final tampered = [...vector.chain];
      final attestation = Uint8List.fromList(tampered[1]);
      attestation[attestation.length - 4] ^= 0x01;
      tampered[1] = attestation;

      final verdict = await vector.verify(chain: tampered);

      expect(verdict.trusted, isFalse);
      expect(verdict.reasonCode, KeyAttestationReason.chainInvalid);
    });

    test('when the certificate the RSA root signed is tampered with then no '
        'root vouches for it', () async {
      final vector = _Vector.load('caiman-sdk36_SB_EC_RKP');
      final tampered = [...vector.chain];
      final top = Uint8List.fromList(tampered[tampered.length - 2]);
      top[top.length - 4] ^= 0x01;
      tampered[tampered.length - 2] = top;

      final verdict = await vector.verify(chain: tampered);

      expect(verdict.reasonCode, KeyAttestationReason.untrustedRoot);
    });

    test('when the chain is reordered, truncated, or garbage then it is '
        'refused', () async {
      final vector = _Vector.load('caiman-sdk36_SB_EC_RKP');
      final chain = vector.chain;

      final reordered = await vector.verify(
        chain: [chain[1], chain[0], ...chain.skip(2)],
      );
      final withoutRoot = await vector.verify(
        chain: chain.sublist(0, chain.length - 1),
      );
      final tooShort = await vector.verify(chain: [chain.first, chain.last]);
      final garbage = await vector.verify(
        chain: [
          utf8.encode('not a certificate'),
          ...chain.skip(1),
        ],
      );

      expect(reordered.trusted, isFalse);
      expect(withoutRoot.reasonCode, KeyAttestationReason.untrustedRoot);
      expect(tooShort.reasonCode, KeyAttestationReason.chainInvalid);
      expect(garbage.reasonCode, KeyAttestationReason.chainInvalid);
    });

    test('when parsed then every field the policy reads matches the '
        'recorded description', () {
      for (final name in [
        ...trusted.keys,
        'sony-xperia10-iii-sdk33_TEE_EC',
        'akita-sdk34_TEE_EC_NONE',
        'akita-sdk34_TEE_RSA_NONE',
        'tokay-sdk37_TEE_MLDSA_RKP',
        'marlin-sdk29_TEE_EC_NONE',
      ]) {
        final vector = _Vector.load(name);
        final description = vector.description;
        final json = vector.json;
        final hardware = json['hardwareEnforced']! as Map<String, Object?>;

        expect(
          description.attestationChallenge,
          base64.decode(json['attestationChallenge']! as String),
          reason: name,
        );
        expect(
          description.attestationSecurityLevel.name,
          _camel(json['attestationSecurityLevel']! as String),
          reason: name,
        );
        expect(
          description.hardwareEnforced.algorithm,
          int.parse(hardware['algorithms']! as String),
          reason: name,
        );
        expect(
          description.hardwareEnforced.purposes,
          {
            for (final purpose in hardware['purposes']! as List<Object?>)
              int.parse(purpose! as String),
          },
          reason: name,
        );
        expect(
          description.hardwareEnforced.osPatchLevel,
          switch (hardware['osPatchLevel']) {
            final String level => int.parse(level),
            _ => null,
          },
          reason: name,
        );
        final rootOfTrust = hardware['rootOfTrust'] as Map<String, Object?>?;
        expect(
          description.hardwareEnforced.rootOfTrust?.deviceLocked,
          rootOfTrust?['deviceLocked'],
          reason: name,
        );
        expect(
          description.attestationApplicationId?.signatureDigests,
          vector.signingDigests,
          reason: name,
        );
      }
    });

    test('when an old keystore writes a BER boolean for deviceLocked then it '
        'still parses as locked', () {
      final chain = _pemChain(
        File('${_vectors}invalid_malformed_rot_device_locked.pem'),
      );
      final leaf = X509Certificate.parse(chain.first);

      final description = KeyDescription.parse(
        leaf.extensions[keyAttestationExtensionOid]!,
      );

      expect(description.hardwareEnforced.rootOfTrust?.deviceLocked, isTrue);
    });
  });

  group('Given a synthetic chain from a test authority', () {
    final authority = TestAttestationAuthority();
    final challenge = sha256.convert(utf8.encode('challenge')).bytes;
    final now = DateTime.utc(2026, 10, 21);

    Future<KeyAttestationVerdict> verifyChain(List<List<int>> chain) =>
        AndroidKeyAttestationVerifier(
          policy: KeyAttestationPolicy(
            signingCertificateDigests: {testSigningCertificateDigest},
          ),
          trustAnchors: [authority.root],
          statusSource: _FixedStatus(AttestationStatusList(const [])),
        ).verify(chain: chain, challenge: challenge, now: now);

    Future<KeyAttestationVerdict> verify(TestAttestedKey key) =>
        verifyChain(key.chain);

    test('when everything holds then the key is trusted', () async {
      final key = authority.issue(challenge: challenge);

      final verdict = await verify(key);

      expect(verdict.trusted, isTrue);
      expect(verdict.publicKey, key.publicKey);
      expect(verdict.deviceKeyId, isNotNull);
    });

    test('when the production roots are the anchors then a test root is not '
        'trusted', () async {
      final key = authority.issue(challenge: challenge);

      final verdict = await AndroidKeyAttestationVerifier(
        policy: KeyAttestationPolicy(
          signingCertificateDigests: {testSigningCertificateDigest},
        ),
        statusSource: _FixedStatus(AttestationStatusList(const [])),
      ).verify(chain: key.chain, challenge: challenge, now: now);

      expect(verdict.reasonCode, KeyAttestationReason.untrustedRoot);
      expect(verdict.publicKey, key.publicKey);
    });

    final refusals = <String, (TestAttestedKey Function(), String)>{
      'the key was imported': (
        () => authority.issue(challenge: challenge, origin: 2),
        KeyAttestationReason.keyInvalid,
      ),
      'the key cannot sign': (
        () => authority.issue(challenge: challenge, purposes: const {3}),
        KeyAttestationReason.keyInvalid,
      ),
      'the curve is not P-256': (
        () => authority.issue(challenge: challenge, ecCurve: 2),
        KeyAttestationReason.keyInvalid,
      ),
      'the key lives in software': (
        () => authority.issue(
          challenge: challenge,
          securityLevel: KeySecurityLevel.software,
        ),
        KeyAttestationReason.securityLevel,
      ),
      'a TEE chain claims StrongBox': (
        () => authority.issue(
          challenge: challenge,
          securityLevel: KeySecurityLevel.strongBox,
        ),
        KeyAttestationReason.securityLevel,
      ),
      'the boot state is self-signed': (
        () => authority.issue(
          challenge: challenge,
          bootState: VerifiedBootState.selfSigned,
        ),
        KeyAttestationReason.bootUntrusted,
      ),
      'the device is unlocked': (
        () => authority.issue(challenge: challenge, deviceLocked: false),
        KeyAttestationReason.bootUntrusted,
      ),
      'the patch is over a year old': (
        () => authority.issue(challenge: challenge, osPatchLevel: 202509),
        KeyAttestationReason.patchOutdated,
      ),
      'the patch level is malformed': (
        () => authority.issue(challenge: challenge, osPatchLevel: 202613),
        KeyAttestationReason.patchOutdated,
      ),
      'an intermediate also carries the extension': (
        () => authority.issue(
          challenge: challenge,
          attestationExtensionOnAttestationKey: true,
        ),
        KeyAttestationReason.chainInvalid,
      ),
    };
    for (final MapEntry(key: condition, value: (issue, reason))
        in refusals.entries) {
      test('when $condition then it is refused with $reason', () async {
        final verdict = await verify(issue());

        expect(verdict.trusted, isFalse);
        expect(verdict.reasonCode, reason);
      });
    }

    test('when a StrongBox key comes from a StrongBox chain then it is '
        'trusted at StrongBox', () async {
      final verdict = await verify(
        authority.issue(
          challenge: challenge,
          securityLevel: KeySecurityLevel.strongBox,
          chainSecurityClaim: 'StrongBox',
        ),
      );

      expect(verdict.securityLevel, KeySecurityLevel.strongBox);
    });

    test('when the attested key certifies a key of its own then the '
        'extended chain is refused', () async {
      // An attacker holding an attested key signs a certificate for another
      // key, with a description it wrote itself.
      final key = authority.issue(challenge: challenge);

      final verdict = await verifyChain(key.extendedWithForgedLeaf(challenge));

      expect(verdict.trusted, isFalse);
      expect(verdict.reasonCode, KeyAttestationReason.chainInvalid);
    });
  });

  group('Given the signing certificate configuration', () {
    test('when digests are listed with colons and commas then they '
        'normalize', () {
      expect(
        parseSigningCertificateDigests(
          '${'AB:' * 31}AB, ${'cd' * 32}',
        ),
        {'ab' * 32, 'cd' * 32},
      );
      expect(parseSigningCertificateDigests(''), isEmpty);
      expect(parseSigningCertificateDigests('not-a-digest'), isNull);
    });

    test('when the environment value is invalid then startup stops', () {
      expect(
        () => KeyAttestationPolicy.fromEnvironment({
          'VERILY_ANDROID_SIGNING_CERT_SHA256': 'abc',
        }),
        throwsStateError,
      );
    });
  });
}

const _vectors = 'test/unit/action_verification/key_attestation/vectors/';

final class _Vector {
  _Vector(this.chain, this.json);

  factory _Vector.load(String name) => _Vector(
    _pemChain(File('$_vectors$name.pem')),
    jsonDecode(File('$_vectors$name.json').readAsStringSync())
        as Map<String, Object?>,
  );

  final List<Uint8List> chain;
  final Map<String, Object?> json;

  late final List<X509Certificate> certificates = [
    for (final der in chain) X509Certificate.parse(der),
  ];

  KeyDescription get description => KeyDescription.parse(
    certificates.first.extensions[keyAttestationExtensionOid]!,
  );

  Map<String, Object?> get _software =>
      json['softwareEnforced']! as Map<String, Object?>;

  Map<String, Object?> get _applicationId =>
      _software['attestationApplicationId']! as Map<String, Object?>;

  DateTime get createdAt => DateTime.fromMillisecondsSinceEpoch(
    int.parse(_software['creationDateTime']! as String),
    isUtc: true,
  );

  Set<String> get signingDigests => {
    for (final digest in _applicationId['signatures']! as List<Object?>)
      base64
          .decode(digest! as String)
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join(),
  };

  String get packageName =>
      ((_applicationId['packages']! as List<Object?>).first!
              as Map<String, Object?>)['name']!
          as String;

  Uint8List? get leafPoint => switch (certificates.first.publicKey) {
    final EcPublicKeyInfo key when key.isP256 => key.point,
    _ => null,
  };

  Future<KeyAttestationVerdict> verify({
    List<List<int>>? chain,
    List<int>? challenge,
    DateTime? now,
    String? packageName,
    Set<String>? signingCertificateDigests,
    int maxPatchAgeMonths = 12,
    AttestationStatusSource? status,
  }) =>
      AndroidKeyAttestationVerifier(
        policy: KeyAttestationPolicy(
          packageName: packageName ?? this.packageName,
          signingCertificateDigests:
              signingCertificateDigests ?? signingDigests,
          maxPatchAgeMonths: maxPatchAgeMonths,
        ),
        statusSource: status ?? _FixedStatus(AttestationStatusList(const [])),
      ).verify(
        chain: chain ?? this.chain,
        challenge:
            challenge ?? base64.decode(json['attestationChallenge']! as String),
        now: now ?? createdAt,
      );
}

List<Uint8List> _pemChain(File file) => [
  for (final match in RegExp(
    '-----BEGIN CERTIFICATE-----([^-]+)-----END CERTIFICATE-----',
  ).allMatches(file.readAsStringSync()))
    base64.decode(match.group(1)!.replaceAll(RegExp(r'\s+'), '')),
];

String _camel(String constant) {
  final words = constant.toLowerCase().split('_');
  return [
    words.first,
    for (final word in words.skip(1)) word[0].toUpperCase() + word.substring(1),
  ].join();
}

final class _FixedStatus implements AttestationStatusSource {
  _FixedStatus(this.list);

  final AttestationStatusList list;

  @override
  Future<AttestationStatusList> statusAt(DateTime now) async => list;
}

final class _UnavailableStatus implements AttestationStatusSource {
  const _UnavailableStatus();

  @override
  Future<AttestationStatusList> statusAt(DateTime now) async =>
      throw const AttestationStatusUnavailable('offline');
}
