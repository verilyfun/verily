import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/evidence_storage/backblaze_evidence_storage.dart';

void main() {
  group('BackblazeEvidenceStorageConfiguration', () {
    test('accepts a complete private Backblaze configuration', () {
      final values = _configurationValues();

      final configuration = BackblazeEvidenceStorageConfiguration.fromPasswords(
        values.call,
      );

      expect(configuration.endpoint.scheme, 'https');
      expect(configuration.endpoint.host, 's3.us-west-002.backblazeb2.com');
      expect(configuration.region, 'us-west-002');
      expect(configuration.bucket, 'verily-action-evidence-dev');
    });

    test('rejects a non-Backblaze endpoint', () {
      final values = _configurationValues()
        ..['evidenceB2S3Endpoint'] = 'https://storage.example.com';

      expect(
        () => BackblazeEvidenceStorageConfiguration.fromPasswords(values.call),
        throwsStateError,
      );
    });

    test('rejects missing credentials', () {
      final values = _configurationValues()..remove('evidenceB2ApplicationKey');

      expect(
        () => BackblazeEvidenceStorageConfiguration.fromPasswords(values.call),
        throwsStateError,
      );
    });
  });

  group('BackblazeEvidenceStorage', () {
    test('streams a digest and pins the returned object version', () async {
      const bytes = _mp4Bytes;
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.path,
          contains('/action-evidence/attempt/video.mp4'),
        );
        expect(request.headers, contains('authorization'));
        return http.Response.bytes(
          bytes,
          200,
          headers: {
            'content-length': '${bytes.length}',
            'content-type': 'video/mp4',
            'x-amz-version-id': 'immutable-version-id',
          },
        );
      });
      final storage = BackblazeEvidenceStorage(
        endpoint: Uri.https('s3.us-west-002.backblazeb2.com'),
        region: 'us-west-002',
        bucket: 'verily-action-evidence-dev',
        keyId: 'test-key-id',
        applicationKey: 'test-application-key',
        httpClient: client,
      );
      addTearDown(storage.close);

      final inspection = await storage.inspectAndHash(
        _session,
        'action-evidence/attempt/video.mp4',
      );

      expect(inspection, isNotNull);
      expect(inspection!.byteLength, bytes.length);
      expect(inspection.contentType, 'video/mp4');
      expect(inspection.compatibleContentTypes, {'video/mp4', 'audio/mp4'});
      expect(inspection.matchesContentType('video/mp4'), isTrue);
      expect(inspection.versionId, 'immutable-version-id');
      expect(inspection.sha256Digest, hasLength(64));
    });

    for (final testCase in <(String, List<int>)>[
      ('video/quicktime', _quickTimeBytes),
      ('video/webm', _webmBytes),
      ('image/jpeg', _jpegBytes),
      ('image/png', _pngBytes),
      ('audio/mp4', _m4aBytes),
      ('audio/webm', _webmBytes),
    ]) {
      test('detects a ${testCase.$1} proof container', () async {
        final storage = _storageReturning(
          bytes: testCase.$2,
          contentType: testCase.$1,
        );
        addTearDown(storage.close);

        final inspection = await storage.inspectAndHash(
          _session,
          'action-evidence/attempt/recording',
        );

        expect(inspection, isNotNull);
        expect(inspection!.compatibleContentTypes, contains(testCase.$1));
        expect(inspection.matchesContentType(testCase.$1), isTrue);
      });
    }

    test('rejects bytes disguised by a video content type', () async {
      final storage = _storageReturning(
        bytes: 'This is not a video.'.codeUnits,
        contentType: 'video/mp4',
      );
      addTearDown(storage.close);

      final inspection = await storage.inspectAndHash(
        _session,
        'action-evidence/attempt/video.mp4',
      );

      expect(inspection, isNotNull);
      expect(inspection!.compatibleContentTypes, isEmpty);
      expect(inspection.matchesContentType('video/mp4'), isFalse);
    });

    test('rejects a valid container with a mismatched content type', () async {
      final storage = _storageReturning(
        bytes: _mp4Bytes,
        contentType: 'video/quicktime',
      );
      addTearDown(storage.close);

      final inspection = await storage.inspectAndHash(
        _session,
        'action-evidence/attempt/video.mov',
      );

      expect(inspection, isNotNull);
      expect(inspection!.compatibleContentTypes, contains('video/mp4'));
      expect(inspection.matchesContentType('video/quicktime'), isFalse);
    });

    test('rejects an object response without a version id', () async {
      final storage = BackblazeEvidenceStorage(
        endpoint: Uri.https('s3.us-west-002.backblazeb2.com'),
        region: 'us-west-002',
        bucket: 'verily-action-evidence-dev',
        keyId: 'test-key-id',
        applicationKey: 'test-application-key',
        httpClient: MockClient(
          (_) async => http.Response(
            'bytes',
            200,
            headers: {'content-length': '5', 'content-type': 'video/mp4'},
          ),
        ),
      );
      addTearDown(storage.close);

      await expectLater(
        storage.inspectAndHash(_session, 'action-evidence/attempt/video.mp4'),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'creates a short-lived review URL without exposing the secret',
      () async {
        final storage = BackblazeEvidenceStorage(
          endpoint: Uri.https('s3.us-west-002.backblazeb2.com'),
          region: 'us-west-002',
          bucket: 'verily-action-evidence-dev',
          keyId: 'test-key-id',
          applicationKey: 'test-application-key',
        );
        addTearDown(storage.close);

        final url = await storage.createReviewUrl(
          _session,
          'action-evidence/attempt/video.mp4',
          versionId: 'immutable-version-id',
        );

        expect(url.scheme, 'https');
        expect(url.path, contains('/action-evidence/attempt/video.mp4'));
        expect(url.queryParameters['X-Amz-Expires'], '300');
        expect(url.queryParameters['versionId'], 'immutable-version-id');
        expect(url.queryParameters['X-Amz-Signature'], hasLength(64));
        expect(url.toString(), isNot(contains('test-application-key')));
      },
    );

    test('rejects review links longer than ten minutes', () async {
      final storage = BackblazeEvidenceStorage(
        endpoint: Uri.https('s3.us-west-002.backblazeb2.com'),
        region: 'us-west-002',
        bucket: 'verily-action-evidence-dev',
        keyId: 'test-key-id',
        applicationKey: 'test-application-key',
      );
      addTearDown(storage.close);

      await expectLater(
        storage.createReviewUrl(
          _session,
          'action-evidence/attempt/video.mp4',
          versionId: 'immutable-version-id',
          expiration: const Duration(minutes: 11),
        ),
        throwsArgumentError,
      );
    });

    test('rejects an empty object version', () async {
      final storage = BackblazeEvidenceStorage(
        endpoint: Uri.https('s3.us-west-002.backblazeb2.com'),
        region: 'us-west-002',
        bucket: 'verily-action-evidence-dev',
        keyId: 'test-key-id',
        applicationKey: 'test-application-key',
      );
      addTearDown(storage.close);

      await expectLater(
        storage.createReviewUrl(
          _session,
          'action-evidence/attempt/video.mp4',
          versionId: ' ',
        ),
        throwsArgumentError,
      );
    });
  });
}

/// Backblaze inspection never reads the session; it is part of the shared
/// storage interface.
final Session _session = _UnusedSession();

class _UnusedSession extends Fake implements Session {}

BackblazeEvidenceStorage _storageReturning({
  required List<int> bytes,
  required String contentType,
}) {
  return BackblazeEvidenceStorage(
    endpoint: Uri.https('s3.us-west-002.backblazeb2.com'),
    region: 'us-west-002',
    bucket: 'verily-action-evidence-dev',
    keyId: 'test-key-id',
    applicationKey: 'test-application-key',
    httpClient: MockClient(
      (_) async => http.Response.bytes(
        bytes,
        200,
        headers: {
          'content-length': '${bytes.length}',
          'content-type': contentType,
          'x-amz-version-id': 'immutable-version-id',
        },
      ),
    ),
  );
}

const _mp4Bytes = <int>[
  0,
  0,
  0,
  24,
  0x66,
  0x74,
  0x79,
  0x70,
  0x69,
  0x73,
  0x6f,
  0x6d,
  0,
  0,
  0,
  0,
  0x69,
  0x73,
  0x6f,
  0x6d,
  0x6d,
  0x70,
  0x34,
  0x32,
];

const _quickTimeBytes = <int>[
  0,
  0,
  0,
  16,
  0x66,
  0x74,
  0x79,
  0x70,
  0x71,
  0x74,
  0x20,
  0x20,
  0,
  0,
  0,
  0,
];

const _webmBytes = <int>[
  0x1a,
  0x45,
  0xdf,
  0xa3,
  0x42,
  0x82,
  0x84,
  0x77,
  0x65,
  0x62,
  0x6d,
];

Map<String, String> _configurationValues() => {
  'evidenceB2S3Endpoint': 'https://s3.us-west-002.backblazeb2.com',
  'evidenceB2Region': 'us-west-002',
  'evidenceB2BucketName': 'verily-action-evidence-dev',
  'evidenceB2KeyId': 'test-key-id',
  'evidenceB2ApplicationKey': 'test-application-key',
};

extension on Map<String, String> {
  String? call(String key) => this[key];
}

const _jpegBytes = <int>[0xff, 0xd8, 0xff, 0xe0, 0, 16, 0x4a, 0x46];

const _pngBytes = <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0];

const _m4aBytes = <int>[
  0,
  0,
  0,
  20,
  0x66,
  0x74,
  0x79,
  0x70,
  0x4d,
  0x34,
  0x41,
  0x20,
  0,
  0,
  0,
  0,
  0x4d,
  0x34,
  0x41,
  0x20,
];
