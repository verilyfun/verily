import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:solana_kit/solana_kit.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/rewards/custody/kms_api_client.dart';
import 'package:verily_server/src/rewards/custody/kms_ed25519_public_key.dart';

import 'fake_kms_api_client.dart';

const _keyVersion =
    'projects/verily-dev/locations/europe-west2/keyRings/escrow/'
    'cryptoKeys/reward-arbiter/cryptoKeyVersions/1';

http.Response _json(Object body, {int status = 200}) => http.Response(
  jsonEncode(body),
  status,
);

void main() {
  // A single shared key: the case lists below capture its public material at
  // main() time, before any setUp callback could run.
  final key = FakeKmsKey();

  test('reads and parses an Ed25519 public key', () async {
    final client = GoogleCloudKmsClient(
      MockClient(
        (request) async => _json({
          'algorithm': 'EC_SIGN_ED25519',
          'pem': encodeEd25519PublicKeyPem(
            Uint8List.fromList(key.keyPair.publicKey),
          ),
          'protectionLevel': 'HSM',
        }),
      ),
    );
    final view = await client.readEd25519Key(_keyVersion);
    expect(view.keyVersionName, _keyVersion);
    expect(view.algorithm, 'EC_SIGN_ED25519');
    expect(view.protectionLevel, 'HSM');
    expect(view.publicKeyBytes, key.keyPair.publicKey);
    expect(
      getAddressDecoder().decode(view.publicKeyBytes).value,
      getAddressDecoder()
          .decode(
            Uint8List.fromList(key.keyPair.publicKey),
          )
          .value,
    );
  });

  test('requests the getPublicKey custom method route', () async {
    late Uri requested;
    final client = GoogleCloudKmsClient(
      MockClient(
        (request) async {
          requested = request.url;
          return _json({
            'algorithm': 'EC_SIGN_ED25519',
            'pem': encodeEd25519PublicKeyPem(
              Uint8List.fromList(key.keyPair.publicKey),
            ),
          });
        },
      ),
    );
    await client.readEd25519Key(_keyVersion);
    expect(
      requested.toString(),
      'https://cloudkms.googleapis.com/v1/$_keyVersion:getPublicKey',
    );
  });

  test('rejects a non-Ed25519 algorithm without echoing the body', () async {
    final client = GoogleCloudKmsClient(
      MockClient(
        (request) async => _json({
          'algorithm': 'EC_SIGN_P256_SHA256',
          'pem': encodeEd25519PublicKeyPem(
            Uint8List.fromList(key.keyPair.publicKey),
          ),
        }),
      ),
    );
    await expectLater(
      client.readEd25519Key(_keyVersion),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          isNot(contains('P256')),
        ),
      ),
    );
  });

  test('rejects a non-200 response without echoing the body', () async {
    final client = GoogleCloudKmsClient(
      MockClient(
        (request) async => _json({'error': 'PERMISSION_DENIED'}, status: 403),
      ),
    );
    await expectLater(
      client.readEd25519Key(_keyVersion),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          allOf(isNot(contains('PERMISSION')), isNot(contains('403'))),
        ),
      ),
    );
  });

  for (final (description, body) in [
    ('missing pem', <String, dynamic>{}),
    ('null pem', <String, dynamic>{'pem': null}),
    ('empty pem', <String, dynamic>{'pem': ''}),
    (
      'malformed pem',
      <String, dynamic>{
        'pem': '-----BEGIN PUBLIC KEY-----\n???\n-----END PUBLIC KEY-----',
      },
    ),
    (
      'missing algorithm',
      <String, dynamic>{
        'pem': encodeEd25519PublicKeyPem(
          Uint8List.fromList(key.keyPair.publicKey),
        ),
      },
    ),
  ]) {
    test('rejects a public key response with $description', () async {
      final client = GoogleCloudKmsClient(
        MockClient((request) async => _json(body)),
      );
      await expectLater(client.readEd25519Key(_keyVersion), throwsStateError);
    });
  }

  test('signs by posting base64 message data', () async {
    late Uri requested;
    late String sentBody;
    final message = Uint8List.fromList(List.filled(200, 7));
    final signature = Uint8List.fromList(
      List.generate(64, (index) => index),
    );
    final client = GoogleCloudKmsClient(
      MockClient(
        (request) async {
          requested = request.url;
          sentBody = request.body;
          return _json({'signature': base64Encode(signature)});
        },
      ),
    );
    final result = await client.sign(_keyVersion, message);
    expect(result, signature);
    expect(
      requested.toString(),
      'https://cloudkms.googleapis.com/v1/$_keyVersion:asymmetricSign',
    );
    expect(jsonDecode(sentBody), {'data': base64Encode(message)});
  });

  for (final (description, body) in [
    ('missing signature', <String, dynamic>{}),
    ('empty signature', <String, dynamic>{'signature': ''}),
    (
      'non-base64 signature',
      <String, dynamic>{'signature': '%%%not-base64%%%'},
    ),
  ]) {
    test('rejects a signing response with $description', () async {
      final client = GoogleCloudKmsClient(
        MockClient((request) async => _json(body)),
      );
      await expectLater(
        client.sign(_keyVersion, Uint8List(32)),
        throwsStateError,
      );
    });
  }

  test('rejects a non-200 signing response', () async {
    final client = GoogleCloudKmsClient(
      MockClient((request) async => _json({}, status: 500)),
    );
    await expectLater(
      client.sign(_keyVersion, Uint8List(32)),
      throwsStateError,
    );
  });

  test('fake client PEM helper round-trips through the parser', () {
    final bytes = Uint8List.fromList(key.keyPair.publicKey);
    expect(parseEd25519PublicKeyPem(encodeEd25519PublicKeyPem(bytes)), bytes);
  });

  group('service-account credentials', () {
    const secretMarker = 'do-not-echo-this-key-material';
    late Directory directory;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('kms-credentials-');
    });
    tearDown(() => directory.deleteSync(recursive: true));

    Future<File> ownerOnlyFile(String contents) async {
      final file = File('${directory.path}/sa.json')
        ..writeAsStringSync(contents);
      final result = await Process.run('chmod', ['600', file.path]);
      expect(result.exitCode, 0);
      return file;
    }

    Matcher rejectsWith(String message) => throwsA(
      isA<StateError>()
          .having((error) => error.message, 'message', message)
          .having(
            (error) => error.message,
            'message',
            isNot(contains(secretMarker)),
          ),
    );

    for (final (description, contents, message) in [
      (
        'malformed JSON',
        '{"private_key": "$secretMarker"',
        'The Cloud KMS credentials are not valid JSON.',
      ),
      (
        'a JSON array',
        '["$secretMarker"]',
        'The Cloud KMS credentials are not a JSON object.',
      ),
      (
        'an object that is not a service-account key',
        jsonEncode({'type': 'service_account', 'private_key': secretMarker}),
        'The Cloud KMS credentials are not a service-account key.',
      ),
    ]) {
      test('inline JSON rejects $description without echoing it', () {
        expect(
          GoogleCloudKmsClient.fromCredentialsJson(contents),
          rejectsWith(message),
        );
      });

      test('a credentials file rejects $description identically', () async {
        final file = await ownerOnlyFile(contents);
        expect(
          GoogleCloudKmsClient.fromCredentialsFile(file.path),
          rejectsWith(message),
        );
      });
    }

    test('the source dispatcher routes inline JSON to the same checks', () {
      expect(
        GoogleCloudKmsClient.fromCredentials(const KmsCredentialsJson('[]')),
        rejectsWith('The Cloud KMS credentials are not a JSON object.'),
      );
    });

    test('a credentials file readable by group or others is refused', () async {
      final file = await ownerOnlyFile('{}');
      final result = await Process.run('chmod', ['640', file.path]);
      expect(result.exitCode, 0);
      expect(
        GoogleCloudKmsClient.fromCredentials(KmsCredentialsFile(file.path)),
        rejectsWith(
          'Cloud KMS credentials must be readable only by their owner (0600).',
        ),
      );
    });

    test('a directory is not a credentials file', () {
      expect(
        GoogleCloudKmsClient.fromCredentialsFile(directory.path),
        rejectsWith('The Cloud KMS credentials path is not a file.'),
      );
    });
  });
}
