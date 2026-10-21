import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/apps/platform_keys.dart';
import 'package:verily_server/src/apps/webhooks/webhook_signing.dart';
import 'package:verily_server/src/generated/protocol.dart';

final _masterKey = List<int>.generate(32, (index) => index);
final _appId = UuidValue.withValidation('0198bc26-4be5-7ca0-94d2-000000000a01');
final _otherAppId = UuidValue.withValidation(
  '0198bc26-4be5-7ca0-94d2-000000000a02',
);

VerilyApp _app({
  int version = 1,
  int? previous,
  DateTime? rotatedAt,
}) => VerilyApp(
  id: _appId,
  creatorAuthUserId: _otherAppId,
  name: 'Step Counter',
  status: VerilyAppStatus.active,
  webhookUrl: 'https://hooks.example.org/verily',
  webhookSecretVersion: version,
  previousWebhookSecretVersion: previous,
  webhookSecretRotatedAt: rotatedAt,
);

void main() {
  group('Given derived webhook secrets', () {
    final keys = WebhookSecrets(_masterKey);

    test('when derived twice then the same App and version match', () {
      final first = keys.secretFor(appId: _appId, version: 1);

      expect(first, keys.secretFor(appId: _appId, version: 1));
      expect(first, startsWith('whsec_'));
      expect(first.substring('whsec_'.length), hasLength(43));
      expect(
        RegExp(r'^whsec_[A-Za-z0-9_-]{43}$').hasMatch(first),
        isTrue,
      );
    });

    test('when the App, version, or master key differs then so does it', () {
      final base = keys.secretFor(appId: _appId, version: 1);

      expect(keys.secretFor(appId: _appId, version: 2), isNot(base));
      expect(keys.secretFor(appId: _otherAppId, version: 1), isNot(base));
      expect(
        WebhookSecrets(
          List<int>.generate(32, (index) => 255 - index),
        ).secretFor(appId: _appId, version: 1),
        isNot(base),
      );
    });

    test('when no secret was issued then the version is refused', () {
      expect(
        () => keys.secretFor(appId: _appId, version: 0),
        throwsArgumentError,
      );
      expect(keys.signingSecretsFor(_app(version: 0), DateTime.now()), isEmpty);
    });

    test('when a rotation is recent then both secrets sign, newest first', () {
      final rotatedAt = DateTime.utc(2026, 10, 21, 12);
      final app = _app(version: 3, previous: 2, rotatedAt: rotatedAt);

      expect(
        keys.signingSecretsFor(app, rotatedAt.add(const Duration(hours: 23))),
        [
          keys.secretFor(appId: _appId, version: 3),
          keys.secretFor(appId: _appId, version: 2),
        ],
      );
      expect(
        keys.signingSecretsFor(app, rotatedAt.add(const Duration(hours: 24))),
        [keys.secretFor(appId: _appId, version: 3)],
      );
    });

    test('when the platform has no master key then nothing can sign', () {
      final saved = PlatformKeys.current;
      addTearDown(() => PlatformKeys.current = saved);
      PlatformKeys.current = const PlatformKeys();

      expect(WebhookSecrets.configured, isNull);
    });
  });

  group('Given a webhook signature header', () {
    test('when signed then each v1 is the HMAC of "t.body"', () {
      const body = '{"id":"vev_x","type":"attempt.verified"}';
      final header = webhookSignatureHeader(
        timestamp: 1791820800,
        body: body,
        secrets: ['whsec_new', 'whsec_old'],
      );
      String hmac(String secret) => Hmac(
        sha256,
        utf8.encode(secret),
      ).convert(utf8.encode('1791820800.$body')).toString();

      expect(
        header,
        't=1791820800,v1=${hmac('whsec_new')},v1=${hmac('whsec_old')}',
      );
    });

    test('when the body changes by one byte then the signature differs', () {
      String sign(String body) => webhookSignatureHeader(
        timestamp: 1,
        body: body,
        secrets: ['whsec_a'],
      );

      expect(sign('{"a":1}'), isNot(sign('{"a":2}')));
    });

    test('when there is no secret then signing is refused', () {
      expect(
        () => webhookSignatureHeader(timestamp: 1, body: '{}', secrets: []),
        throwsArgumentError,
      );
    });

    test('when an event id is minted then it is vev_ and 128 bits', () {
      final ids = {
        for (var index = 0; index < 50; index += 1) newWebhookEventId(),
      };

      expect(ids, hasLength(50));
      expect(
        ids.every(RegExp(r'^vev_[A-Za-z0-9_-]{22}$').hasMatch),
        isTrue,
      );
    });
  });

  group('Given platform key configuration', () {
    test('when values are valid base64 then they parse in either alphabet', () {
      final webhook = base64Url.encode(List<int>.filled(40, 7));
      final receipt = base64
          .encode(List<int>.filled(32, 9))
          .replaceAll('=', '');

      final keys = PlatformKeys.fromSecrets(
        webhookSigningMasterKey: webhook,
        receiptSigningKey: receipt,
        retiredReceiptPublicKeys:
            '${base64.encode(List<int>.filled(32, 1))}, '
            '${base64Url.encode(List<int>.filled(32, 2))}',
      );

      expect(keys.webhookSigningMasterKey, hasLength(40));
      expect(keys.receiptSigningKey, hasLength(32));
      expect(keys.retiredReceiptPublicKeys, hasLength(2));
    });

    test('when nothing is configured then every key is absent', () {
      final keys = PlatformKeys.fromSecrets();

      expect(keys.webhookSigningMasterKey, isNull);
      expect(keys.receiptSigningKey, isNull);
      expect(keys.retiredReceiptPublicKeys, isEmpty);
    });

    test('when a value is malformed or the wrong size then startup stops', () {
      expect(
        () => PlatformKeys.fromSecrets(webhookSigningMasterKey: 'not base64!'),
        throwsStateError,
      );
      expect(
        () => PlatformKeys.fromSecrets(
          webhookSigningMasterKey: base64.encode(List<int>.filled(16, 1)),
        ),
        throwsStateError,
      );
      expect(
        () => PlatformKeys.fromSecrets(
          receiptSigningKey: base64.encode(List<int>.filled(33, 1)),
        ),
        throwsStateError,
      );
      expect(
        () => PlatformKeys.fromSecrets(
          retiredReceiptPublicKeys: base64.encode(List<int>.filled(31, 1)),
        ),
        throwsStateError,
      );
    });
  });
}
