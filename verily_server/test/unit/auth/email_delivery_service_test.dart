import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/auth/email_delivery_service.dart';

void main() {
  test(
    'sends a registration code without exposing the API key in the body',
    () async {
      late http.Request capturedRequest;
      final service = ResendEmailDeliveryService(
        apiKey: 'secret-api-key',
        fromAddress: 'Verily <hello@verily.example>',
        client: MockClient((request) async {
          capturedRequest = request;
          return http.Response('{"id":"email-id"}', 200);
        }),
      );

      await service.sendVerificationCode(
        email: 'person@example.com',
        verificationCode: '1234abcd',
        purpose: EmailVerificationPurpose.registration,
      );

      final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
      expect(capturedRequest.url, Uri.https('api.resend.com', '/emails'));
      expect(capturedRequest.headers['authorization'], 'Bearer secret-api-key');
      expect(body['to'], ['person@example.com']);
      expect(body['text'], contains('1234abcd'));
      expect(capturedRequest.body, isNot(contains('secret-api-key')));
    },
  );

  test(
    'reports provider failures without including the response body',
    () async {
      final service = ResendEmailDeliveryService(
        apiKey: 'secret-api-key',
        fromAddress: 'Verily <hello@verily.example>',
        client: MockClient(
          (_) async => http.Response('sensitive provider diagnostic', 403),
        ),
      );

      await expectLater(
        service.sendVerificationCode(
          email: 'person@example.com',
          verificationCode: '1234abcd',
          purpose: EmailVerificationPurpose.passwordReset,
        ),
        throwsA(
          isA<EmailDeliveryException>()
              .having((error) => error.statusCode, 'statusCode', 403)
              .having(
                (error) => error.toString(),
                'message',
                isNot(contains('sensitive provider diagnostic')),
              ),
        ),
      );
    },
  );
}
