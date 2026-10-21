import 'dart:convert';

import 'package:http/http.dart' as http;

enum EmailVerificationPurpose { registration, passwordReset }

typedef SendVerificationEmail = Future<void> Function({
  required String email,
  required String verificationCode,
  required EmailVerificationPurpose purpose,
});

class ResendEmailDeliveryService {
  ResendEmailDeliveryService({
    required this.apiKey,
    required this.fromAddress,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String fromAddress;
  final http.Client _client;

  static final Uri _emailsUri = Uri.https('api.resend.com', '/emails');

  Future<void> sendVerificationCode({
    required String email,
    required String verificationCode,
    required EmailVerificationPurpose purpose,
  }) async {
    final action = switch (purpose) {
      EmailVerificationPurpose.registration => 'finish signing up',
      EmailVerificationPurpose.passwordReset => 'reset your password',
    };
    final response = await _client.post(
      _emailsUri,
      headers: {
        'authorization': 'Bearer $apiKey',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'from': fromAddress,
        'to': [email],
        'subject': 'Your Verily verification code',
        'text':
            'Use $verificationCode to $action. This code expires soon. '
            'If you did not request it, you can ignore this email.',
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EmailDeliveryException(statusCode: response.statusCode);
    }
  }
}

class EmailDeliveryException implements Exception {
  const EmailDeliveryException({required this.statusCode});

  final int statusCode;

  @override
  String toString() => 'Email delivery failed with status $statusCode.';
}
