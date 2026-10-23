import 'dart:convert';

import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/app_attest/device_check_endpoint.dart';
import 'package:verily_server/src/generated/protocol.dart';

import 'test_tools/apple_device_test_authority.dart';
import 'test_tools/serverpod_test_tools.dart';
import 'test_tools/verily_fixtures.dart';

void main() {
  withServerpod('DeviceCheck operator controls', (builder, endpoints) {
    final operatorId = testId(0xd01);
    final userId = testId(0xd02);
    final token = base64Encode(utf8.encode('device-token'));
    late TestSessionBuilder operator;
    late TestSessionBuilder participant;
    late TestAppleDeviceClient apple;
    late DeviceCheckEndpoint endpoint;

    setUp(() async {
      operator = signedIn(builder, operatorId, scopes: {'device-check.manage'});
      participant = signedIn(builder, userId);
      await insertAccounts(builder.build(), {
        operatorId: 'Operator',
        userId: 'Participant',
      });
      apple = TestAppleDeviceClient(TestReceiptAuthority());
      endpoint = DeviceCheckEndpoint(apple: apple);
    });

    test('unauthenticated callers, participants and evidence reviewers cannot query or update', () async {
      await expectLater(
        endpoints.deviceCheck.query(builder, deviceToken: token),
        throwsA(isA<ServerpodUnauthenticatedException>()),
      );
      for (final caller in [
        participant,
        signedIn(builder, userId, scopes: {'evidence.review'}),
      ]) {
        await expectLater(
          endpoints.deviceCheck.query(caller, deviceToken: token),
          throwsA(isA<ServerpodInsufficientAccessException>()),
        );
        await expectLater(
          endpoints.deviceCheck.update(
            caller,
            deviceToken: token,
            banned: false,
            reviewRequired: false,
            note: 'clear',
          ),
          throwsA(isA<ServerpodInsufficientAccessException>()),
        );
      }
    });

    test('operator updates both flags and records intent and completion without a token', () async {
      await endpoint.update(
        operator.build(),
        deviceToken: token,
        banned: true,
        reviewRequired: true,
        note: 'Confirmed abuse',
      );
      final state = await endpoint.query(operator.build(), deviceToken: token);
      expect(state.banned, isTrue);
      expect(state.reviewRequired, isTrue);
      final audit = (await DeviceCheckAudit.db.find(builder.build())).single;
      expect(audit.operatorAuthUserId, operatorId);
      expect(audit.note, 'Confirmed abuse');
      expect(audit.completedAt, isNotNull);
      expect(audit.tokenHash, isNot(token));
      await endpoint.update(
        operator.build(),
        deviceToken: token,
        banned: false,
        reviewRequired: true,
        note: 'Ban lifted; review remains',
      );
      expect(apple.bits.banned, isFalse);
      expect(apple.bits.reviewRequired, isTrue);
    });

    test(
      'Apple failure leaves an incomplete audit and never simulates an update',
      () async {
        apple.unavailable = true;
        await expectLater(
          endpoint.update(
            operator.build(),
            deviceToken: token,
            banned: true,
            reviewRequired: false,
            note: 'Confirmed abuse',
          ),
          throwsA(isA<AppAttestException>()),
        );
        expect(
          (await DeviceCheckAudit.db.find(builder.build())).single.completedAt,
          isNull,
        );
        expect(apple.bits.banned, isFalse);
        await expectLater(
          endpoint.query(operator.build(), deviceToken: token),
          throwsA(isA<AppAttestException>()),
        );
      },
    );

    test('invalid tokens and empty notes cannot call Apple or create update intent', () async {
      await expectLater(
        endpoint.update(
          operator.build(),
          deviceToken: token,
          banned: true,
          reviewRequired: false,
          note: ' ',
        ),
        throwsArgumentError,
      );
      await expectLater(
        endpoint.query(operator.build(), deviceToken: 'invalid\ntoken'),
        throwsArgumentError,
      );
      expect(await DeviceCheckAudit.db.count(builder.build()), 0);
    });
  });
}
