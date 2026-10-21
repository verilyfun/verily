import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/evidence_storage/backblaze_evidence_storage.dart';
import 'package:verily_server/src/evidence_storage/evidence_object_access.dart';
import 'package:verily_server/src/evidence_storage/evidence_storage_configuration.dart';
import 'package:verily_server/src/evidence_storage/local_evidence_storage.dart';

void main() {
  EvidenceStorageMode resolve(
    String runMode, {
    String? configured,
    PasswordReader readPassword = _none,
  }) => EvidenceStorageSelection.resolveMode(
    runMode: runMode,
    environment: {'VERILY_EVIDENCE_STORAGE': ?configured},
    readPassword: readPassword,
  );

  group('Given development and test run modes', () {
    for (final runMode in [
      ServerpodRunMode.development,
      ServerpodRunMode.test,
    ]) {
      test('when $runMode has no Backblaze values then local storage is '
          'selected', () {
        expect(resolve(runMode), EvidenceStorageMode.local);
      });

      test('when $runMode has Backblaze values then B2 is selected', () {
        expect(
          resolve(runMode, readPassword: _complete),
          EvidenceStorageMode.b2,
        );
      });

      test('when $runMode has a partial Backblaze configuration then B2 is '
          'selected so the gap fails loudly', () {
        expect(
          resolve(runMode, readPassword: _partial),
          EvidenceStorageMode.b2,
        );
        expect(
          () => EvidenceStorageSelection.create(
            mode: EvidenceStorageMode.b2,
            readPassword: _partial,
          ),
          throwsStateError,
        );
      });

      test('when $runMode explicitly asks for local then local is used even '
          'with Backblaze values', () {
        expect(
          resolve(runMode, configured: 'local', readPassword: _complete),
          EvidenceStorageMode.local,
        );
      });
    }
  });

  group('Given staging and production run modes', () {
    for (final runMode in [
      ServerpodRunMode.staging,
      ServerpodRunMode.production,
    ]) {
      test('when $runMode asks for local storage then startup is refused', () {
        expect(
          () => resolve(runMode, configured: 'local', readPassword: _complete),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('only available in development and test'),
            ),
          ),
        );
      });

      test('when $runMode has no Backblaze values then B2 is still required '
          'and building it fails', () {
        expect(resolve(runMode), EvidenceStorageMode.b2);
        expect(
          () => EvidenceStorageSelection.create(
            mode: EvidenceStorageMode.b2,
            readPassword: _none,
          ),
          throwsStateError,
        );
      });
    }
  });

  group('Given an unknown storage mode', () {
    test('when resolved then startup is refused', () {
      expect(
        () => resolve(ServerpodRunMode.development, configured: 'database'),
        throwsStateError,
      );
    });

    test('when the mode differs only in case and padding then it is '
        'accepted', () {
      expect(
        resolve(ServerpodRunMode.development, configured: ' LOCAL '),
        EvidenceStorageMode.local,
      );
    });
  });

  group('Given a resolved mode', () {
    test('when local is built then evidence storage is the database-backed '
        'local store under the evidence id', () {
      final storage = EvidenceStorageSelection.create(
        mode: EvidenceStorageMode.local,
        readPassword: _none,
      );

      expect(storage, isA<LocalEvidenceStorage>());
      expect(storage, isA<EvidenceObjectAccess>());
      expect(storage.storageId, evidenceStorageId);
    });

    test('when B2 is built from a complete configuration then the private '
        'Backblaze store is used', () {
      final storage = EvidenceStorageSelection.create(
        mode: EvidenceStorageMode.b2,
        readPassword: _complete,
      );
      expect(storage, isA<BackblazeEvidenceStorage>());
      addTearDown((storage as BackblazeEvidenceStorage).close);
      expect(storage.storageId, evidenceStorageId);
    });
  });

  test('Given local evidence when a version id is derived then it is the '
      'labelled content digest', () {
    expect(
      localEvidenceVersionId('a' * 64),
      'local-sha256-${'a' * 64}',
    );
  });
}

const _b2 = {
  'evidenceB2S3Endpoint': 'https://s3.us-west-004.backblazeb2.com',
  'evidenceB2Region': 'us-west-004',
  'evidenceB2BucketName': 'verily-private-evidence',
  'evidenceB2KeyId': 'test-key-id',
  'evidenceB2ApplicationKey': 'test-application-key',
};

String? _none(String _) => null;

String? _complete(String alias) => _b2[alias];

String? _partial(String alias) =>
    alias == 'evidenceB2BucketName' ? 'verily-private-evidence' : null;
