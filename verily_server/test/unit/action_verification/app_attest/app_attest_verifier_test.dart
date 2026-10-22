import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/app_attest/app_attest_verifier.dart';
import 'package:verily_server/src/generated/protocol.dart';

import '../../../integration/test_tools/app_attest_test_authority.dart';
import '../../../integration/test_tools/cbor_writer.dart';

/// Apple's published samples and a recorded iPhone (see `vectors/README.md`)
/// against the pinned root, then the synthetic authority for every refusal.
void main() {
  group("Given Apple's documented sample attestation", () {
    final vector = _Vector.load('apple-sample-attestation');
    // The sample's app reports validation category 1, an OS executable,
    // which Verily never accepts; the sample policy allows it so every other
    // step can be checked.
    final policy = AppAttestPolicy(
      teamId: vector.string('appIdPrefix'),
      bundleId: vector.string('bundleId'),
      validationCategories: {1},
    );
    AppAttestAttestationVerdict verify({
      AppAttestPolicy? under,
      List<int>? keyId,
      List<int>? clientDataHash,
      DateTime? now,
    }) => AppAttestVerifier(policy: under ?? policy).verifyAttestation(
      attestationObject: vector.bytes('attestation'),
      keyId: keyId ?? vector.bytes('keyId'),
      // The sample's app passed the challenge text itself as the hash.
      clientDataHash:
          clientDataHash ?? utf8.encode(vector.string('clientDataHash')),
      now: now ?? vector.checkTime,
    );

    test('when checked at its time then it is trusted with what it '
        'reports', () {
      final verdict = verify();

      expect(verdict.reasonCode, AppAttestReason.valid);
      final key = verdict.key!;
      expect(sha256.convert(key.publicKey).bytes, vector.bytes('keyId'));
      expect(key.validationCategory, 1);
      expect(key.bundleVersion, '1');
      expect(key.certificateChain, hasLength(2));
      expect(
        base64Encode(key.certificateChain.first),
        (vector.json['expected']! as Map)['leafCertificate'],
      );
      expect(key.receipt, isNotEmpty);
    });

    test("when Verily's production policy reads it then the OS-executable "
        'category is refused', () {
      final verdict = verify(
        under: AppAttestPolicy(
          teamId: vector.string('appIdPrefix'),
          bundleId: vector.string('bundleId'),
        ),
      );

      expect(verdict.reasonCode, AppAttestReason.categoryRefused);
    });

    final refusals = <String, (AppAttestAttestationVerdict Function(), String)>{
      'the challenge was hashed differently': (
        () => verify(
          clientDataHash: sha256
              .convert(utf8.encode(vector.string('clientDataHash')))
              .bytes,
        ),
        AppAttestReason.nonceMismatch,
      ),
      'the app names another key': (
        () => verify(keyId: List.filled(32, 7)),
        AppAttestReason.keyInvalid,
      ),
      'the key belongs to another team': (
        () => verify(
          under: AppAttestPolicy(
            teamId: 'ABCDEFGHIJ',
            bundleId: vector.string('bundleId'),
            validationCategories: {1},
          ),
        ),
        AppAttestReason.appMismatch,
      ),
      'the server expects the sandbox': (
        () => verify(
          under: AppAttestPolicy(
            teamId: vector.string('appIdPrefix'),
            bundleId: vector.string('bundleId'),
            environment: AppAttestEnvironment.development,
            validationCategories: {1},
          ),
        ),
        AppAttestReason.environmentMismatch,
      ),
      'its three-day credential certificate has expired': (
        () => verify(now: DateTime.utc(2026, 4, 24)),
        AppAttestReason.expired,
      ),
    };
    for (final MapEntry(key: name, value: (run, reason)) in refusals.entries) {
      test('when $name then it is refused', () {
        expect(run().reasonCode, reason);
      });
    }

    test('when only a test root is trusted then it is refused', () {
      final verdict =
          AppAttestVerifier(
            policy: policy,
            trustAnchors: [TestAppAttestAuthority().root],
          ).verifyAttestation(
            attestationObject: vector.bytes('attestation'),
            keyId: vector.bytes('keyId'),
            clientDataHash: utf8.encode(vector.string('clientDataHash')),
            now: vector.checkTime,
          );

      expect(verdict.reasonCode, AppAttestReason.untrustedRoot);
    });

    test('when the object is truncated then it is refused', () {
      final attestation = vector.bytes('attestation');

      final verdict = AppAttestVerifier(policy: policy).verifyAttestation(
        attestationObject: attestation.sublist(0, attestation.length - 1),
        keyId: vector.bytes('keyId'),
        clientDataHash: utf8.encode(vector.string('clientDataHash')),
        now: vector.checkTime,
      );

      expect(verdict.reasonCode, AppAttestReason.malformed);
    });
  });

  test("Given Apple's 2024 sample from iOS 18 when it reports no category "
      'then the production policy trusts it', () {
    final vector = _Vector.load('apple-sample-attestation-2024');

    final verdict =
        AppAttestVerifier(
          policy: AppAttestPolicy(
            teamId: vector.string('appIdPrefix'),
            bundleId: vector.string('bundleId'),
          ),
        ).verifyAttestation(
          attestationObject: vector.bytes('attestation'),
          keyId: vector.bytes('keyId'),
          clientDataHash: utf8.encode(vector.string('clientDataHash')),
          now: vector.checkTime,
        );

    expect(verdict.reasonCode, AppAttestReason.valid);
    expect(verdict.key!.validationCategory, isNull);
    expect(verdict.key!.bundleVersion, isNull);
  });

  group('Given a recorded iPhone attestation and its two assertions', () {
    final vector = _Vector.load('termakan-ios27-attestation');
    final appId = vector.string('appId').split('.');
    // A development-signed build that used the production environment.
    final policy = AppAttestPolicy(
      teamId: appId.first,
      bundleId: appId.skip(1).join('.'),
      validationCategories: {AppleValidationCategory.development},
    );
    final verifier = AppAttestVerifier(policy: policy);
    final assertions = (vector.json['assertions']! as List)
        .cast<Map<String, Object?>>();
    late final Uint8List publicKey;

    setUpAll(() {
      expect(
        vector.bytes('clientDataHashBase64'),
        sha256.convert(utf8.encode(vector.string('challenge'))).bytes,
      );
      final verdict = verifier.verifyAttestation(
        attestationObject: vector.bytes('attestation'),
        keyId: vector.bytes('keyId'),
        clientDataHash: vector.bytes('clientDataHashBase64'),
        now: DateTime.parse(vector.string('captured')),
      );
      expect(verdict.reasonCode, AppAttestReason.valid);
      expect(verdict.key!.validationCategory, 3);
      expect(verdict.key!.bundleVersion, '1');
      publicKey = verdict.key!.publicKey;
    });

    AppAssertionVerdict check(
      int index, {
      int previousCounter = 0,
      String? clientData,
      AppAttestVerifier? under,
    }) => (under ?? verifier).verifyAssertion(
      assertion: base64Decode(assertions[index]['assertion']! as String),
      clientData: utf8.encode(
        clientData ?? assertions[index]['clientData']! as String,
      ),
      publicKey: publicKey,
      previousCounter: previousCounter,
    );

    test('when each assertion follows the last then both are trusted', () {
      expect(check(0).counter, 1);
      expect(check(1, previousCounter: 1).counter, 2);
    });

    test('when an assertion is replayed then it is refused', () {
      expect(check(0, previousCounter: 1).reasonCode, AppAttestReason.replayed);
      expect(check(1, previousCounter: 2).reasonCode, AppAttestReason.replayed);
    });

    test('when the client data differs then the signature is refused', () {
      expect(
        check(0, clientData: assertions[1]['clientData']! as String).reasonCode,
        AppAttestReason.signatureInvalid,
      );
    });

    test("when Verily's production policy reads it then the development "
        'binary is refused', () {
      final production = AppAttestVerifier(
        policy: AppAttestPolicy(
          teamId: policy.teamId,
          bundleId: policy.bundleId,
        ),
      );

      expect(
        production
            .verifyAttestation(
              attestationObject: vector.bytes('attestation'),
              keyId: vector.bytes('keyId'),
              clientDataHash: vector.bytes('clientDataHashBase64'),
              now: DateTime.parse(vector.string('captured')),
            )
            .reasonCode,
        AppAttestReason.categoryRefused,
      );
      expect(
        check(0, under: production).reasonCode,
        AppAttestReason.categoryRefused,
      );
    });

    test('when the assertion names another app then it is refused', () {
      final other = AppAttestVerifier(
        policy: AppAttestPolicy(
          teamId: policy.teamId,
          bundleId: 'com.example.other',
          validationCategories: {AppleValidationCategory.development},
        ),
      );

      expect(check(0, under: other).reasonCode, AppAttestReason.appMismatch);
    });
  });

  group('Given a synthetic App Attest authority', () {
    final authority = TestAppAttestAuthority();
    final clientDataHash = sha256.convert(utf8.encode('challenge')).bytes;
    final now = DateTime.utc(2026, 10, 22);

    AppAttestAttestationVerdict verify(
      TestAppAttestKey key, {
      AppAttestPolicy? policy,
    }) =>
        AppAttestVerifier(
          policy: policy ?? testAppAttestPolicy(),
          trustAnchors: [authority.root],
        ).verifyAttestation(
          attestationObject: key.attestationObject,
          keyId: base64Decode(key.keyId),
          clientDataHash: clientDataHash,
          now: now,
        );

    test('when the key meets the policy then it is trusted', () {
      final key = authority.attest(clientDataHash: clientDataHash);

      final verdict = verify(key);

      expect(verdict.reasonCode, AppAttestReason.valid);
      expect(verdict.key!.publicKey, key.publicKey);
      expect(verdict.key!.validationCategory, AppleValidationCategory.appStore);
      expect(verdict.key!.bundleVersion, '42');
    });

    test('when a sandbox key meets a development policy then it is '
        'trusted', () {
      final key = authority.attest(
        clientDataHash: clientDataHash,
        environment: AppAttestEnvironment.development,
        validationCategory: AppleValidationCategory.development,
      );

      expect(
        verify(
          key,
          policy: testAppAttestPolicy(
            environment: AppAttestEnvironment.development,
          ),
        ).reasonCode,
        AppAttestReason.valid,
      );
    });

    test('when the iOS version reports no extensions then it is trusted', () {
      final key = authority.attest(
        clientDataHash: clientDataHash,
        validationCategory: null,
        bundleVersion: null,
      );

      final verdict = verify(key);

      expect(verdict.reasonCode, AppAttestReason.valid);
      expect(verdict.key!.validationCategory, isNull);
    });

    final refusals = <String, (TestAppAttestKey Function(), String)>{
      'the counter is not zero': (
        () => authority.attest(clientDataHash: clientDataHash, counter: 1),
        AppAttestReason.counterInvalid,
      ),
      'the key comes from the sandbox': (
        () => authority.attest(
          clientDataHash: clientDataHash,
          environment: AppAttestEnvironment.development,
        ),
        AppAttestReason.environmentMismatch,
      ),
      'the key belongs to another app': (
        () => authority.attest(
          clientDataHash: clientDataHash,
          appId: '$testAppleTeamId.com.example.other',
        ),
        AppAttestReason.appMismatch,
      ),
      'a development binary made it': (
        () => authority.attest(
          clientDataHash: clientDataHash,
          validationCategory: AppleValidationCategory.development,
        ),
        AppAttestReason.categoryRefused,
      ),
      'the credential id names another key': (
        () => authority.attest(
          clientDataHash: clientDataHash,
          credentialId: List.filled(32, 1),
        ),
        AppAttestReason.keyInvalid,
      ),
      'the COSE key is not the certified key': (
        () => authority.attest(
          clientDataHash: clientDataHash,
          coseKeySeed: 'another-key',
        ),
        AppAttestReason.keyInvalid,
      ),
      'the certified nonce is for other data': (
        () => authority.attest(
          clientDataHash: clientDataHash,
          nonce: List.filled(32, 2),
        ),
        AppAttestReason.nonceMismatch,
      ),
      'the attestation was made for another challenge': (
        () => authority.attest(clientDataHash: List.filled(32, 3)),
        AppAttestReason.nonceMismatch,
      ),
      'a certificate authority certifies a nonce': (
        () => authority.attest(clientDataHash: clientDataHash, nonceOnCa: true),
        AppAttestReason.chainInvalid,
      ),
      'the credential certificate has expired': (
        () => authority.attest(
          clientDataHash: clientDataHash,
          notAfter: DateTime.utc(2026, 10, 21),
        ),
        AppAttestReason.expired,
      ),
    };
    for (final MapEntry(key: name, value: (issue, reason))
        in refusals.entries) {
      test('when $name then the attestation is refused', () {
        expect(verify(issue()).reasonCode, reason);
      });
    }

    test('when another authority made the attestation then it is refused', () {
      final key = TestAppAttestAuthority(
        name: 'impostor',
      ).attest(clientDataHash: clientDataHash);

      expect(verify(key).reasonCode, AppAttestReason.untrustedRoot);
    });

    test('when the statement carries an unexpected field then it is '
        'refused', () {
      final key = authority.attest(clientDataHash: clientDataHash);
      final object = {
        'fmt': 'apple-appattest',
        'attStmt': {
          'x5c': <Object>[],
          'receipt': Uint8List(1),
          'extra': 1,
        },
        'authData': Uint8List(37),
      };

      final verdict =
          AppAttestVerifier(
            policy: testAppAttestPolicy(),
            trustAnchors: [authority.root],
          ).verifyAttestation(
            attestationObject: encodeCbor(object),
            keyId: base64Decode(key.keyId),
            clientDataHash: clientDataHash,
            now: now,
          );

      expect(verdict.reasonCode, AppAttestReason.malformed);
    });

    group('and an attested key', () {
      final key = authority.attest(clientDataHash: clientDataHash);
      final manifest = utf8.encode('verily-capture-manifest-v1\nproof');
      final verifier = AppAttestVerifier(
        policy: testAppAttestPolicy(),
        trustAnchors: [authority.root],
      );

      AppAssertionVerdict check(
        Uint8List assertion, {
        int previousCounter = 0,
        Uint8List? publicKey,
      }) => verifier.verifyAssertion(
        assertion: assertion,
        clientData: manifest,
        publicKey: publicKey ?? key.publicKey,
        previousCounter: previousCounter,
      );

      test('when it asserts the manifest then the counter is read', () {
        expect(check(key.assertion(manifest, counter: 5)).counter, 5);
      });

      test('when the counter does not advance then it is refused', () {
        expect(
          check(
            key.assertion(manifest, counter: 5),
            previousCounter: 5,
          ).reasonCode,
          AppAttestReason.replayed,
        );
      });

      test('when another key signed then it is refused', () {
        final other = authority.attest(
          clientDataHash: clientDataHash,
          keySeed: 'another-install',
        );

        expect(
          check(
            key.assertion(manifest, counter: 1),
            publicKey: other.publicKey,
          ).reasonCode,
          AppAttestReason.signatureInvalid,
        );
      });

      test('when it names another app then it is refused', () {
        expect(
          check(
            key.assertion(
              manifest,
              counter: 1,
              appId: '$testAppleTeamId.com.example.other',
            ),
          ).reasonCode,
          AppAttestReason.appMismatch,
        );
      });

      test('when a development binary made it then it is refused', () {
        expect(
          check(
            key.assertion(
              manifest,
              counter: 1,
              validationCategory: AppleValidationCategory.development,
            ),
          ).reasonCode,
          AppAttestReason.categoryRefused,
        );
      });

      test('when the assertion is not the expected map then it is '
          'refused', () {
        expect(
          check(encodeCbor({'signature': Uint8List(8)})).reasonCode,
          AppAttestReason.malformed,
        );
        expect(
          check(Uint8List.fromList([0xff])).reasonCode,
          AppAttestReason.malformed,
        );
      });
    });
  });

  group('Given App Attest configuration', () {
    test('when no team id is set then App Attest is off', () {
      expect(AppAttestPolicy.fromEnvironment(const {}), isNull);
    });

    test('when a team id is set then the policy names Verily by default', () {
      final policy = AppAttestPolicy.fromEnvironment(const {
        'VERILY_APPLE_TEAM_ID': testAppleTeamId,
      })!;

      expect(policy.appId, testAppleAppId);
      expect(policy.environment, AppAttestEnvironment.production);
      expect(policy.validationCategories, {
        AppleValidationCategory.testFlight,
        AppleValidationCategory.appStore,
      });
    });

    test('when the sandbox is chosen then development builds are '
        'accepted', () {
      final policy = AppAttestPolicy.fromEnvironment(const {
        'VERILY_APPLE_TEAM_ID': testAppleTeamId,
        'VERILY_IOS_BUNDLE_ID': 'fun.verily.app.dev',
        'VERILY_APP_ATTEST_ENVIRONMENT': 'development',
      })!;

      expect(policy.appId, '$testAppleTeamId.fun.verily.app.dev');
      expect(policy.environment, AppAttestEnvironment.development);
      expect(policy.validationCategories, {
        AppleValidationCategory.development,
        AppleValidationCategory.adHoc,
      });
    });

    test('when a value is malformed then startup stops', () {
      for (final environment in [
        {'VERILY_APPLE_TEAM_ID': 'short'},
        {'VERILY_APPLE_TEAM_ID': 'teamid1234'},
        {
          'VERILY_APPLE_TEAM_ID': testAppleTeamId,
          'VERILY_IOS_BUNDLE_ID': 'not a bundle',
        },
        {'VERILY_APP_ATTEST_ENVIRONMENT': 'staging'},
      ]) {
        expect(
          () => AppAttestPolicy.fromEnvironment(environment),
          throwsStateError,
          reason: '$environment',
        );
      }
    });
  });
}

const _vectors = 'test/unit/action_verification/app_attest/vectors/';

final class _Vector {
  _Vector(this.json);

  factory _Vector.load(String name) => _Vector(
    jsonDecode(File('$_vectors$name.json').readAsStringSync())
        as Map<String, Object?>,
  );

  final Map<String, Object?> json;

  String string(String field) => json[field]! as String;

  Uint8List bytes(String field) => base64Decode(string(field));

  DateTime get checkTime => DateTime.parse(string('checkTime'));
}
