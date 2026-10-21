import 'dart:convert';

import 'package:googleapis_auth/auth_io.dart';
import 'package:serverpod/serverpod.dart';

const _playIntegrityScope = 'https://www.googleapis.com/auth/playintegrity';
const _expectedPackageName = 'fun.verily.app';
const _maximumVerdictAge = Duration(minutes: 2);

class DeviceIntegrityVerdict {
  const DeviceIntegrityVerdict({
    required this.trusted,
    required this.reasonCode,
    required this.provider,
  });

  final bool trusted;
  final String reasonCode;
  final String provider;
}

abstract interface class DeviceIntegrityVerifier {
  String get providerName;

  Future<DeviceIntegrityVerdict> verify(
    Session session, {
    required String token,
    required String requestHash,
    required DateTime now,
  });
}

class GooglePlayIntegrityVerifier implements DeviceIntegrityVerifier {
  const GooglePlayIntegrityVerifier();

  @override
  String get providerName => 'google-play-integrity';

  @override
  Future<DeviceIntegrityVerdict> verify(
    Session session, {
    required String token,
    required String requestHash,
    required DateTime now,
  }) async {
    final credentialsJson = session.server.serverpod
        .getPassword('playIntegrityServiceAccountJson')
        ?.trim();
    if (credentialsJson == null || credentialsJson.isEmpty) {
      return const DeviceIntegrityVerdict(
        trusted: false,
        reasonCode: 'device_integrity_unavailable',
        provider: 'google-play-integrity',
      );
    }

    AutoRefreshingAuthClient? client;
    try {
      final credentials = ServiceAccountCredentials.fromJson(
        jsonDecode(credentialsJson) as Map<String, dynamic>,
      );
      client = await clientViaServiceAccount(
        credentials,
        const [_playIntegrityScope],
      );
      final response = await client.post(
        Uri.https(
          'playintegrity.googleapis.com',
          '/v1/$_expectedPackageName:decodeIntegrityToken',
        ),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode({'integrity_token': token}),
      );
      if (response.statusCode != 200) {
        return const DeviceIntegrityVerdict(
          trusted: false,
          reasonCode: 'device_integrity_unavailable',
          provider: 'google-play-integrity',
        );
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final payload = body['tokenPayloadExternal'] as Map<String, dynamic>?;
      if (payload == null) return _invalidVerdict;
      return evaluateGooglePlayIntegrityPayload(
        payload,
        requestHash: requestHash,
        now: now,
      );
    } on Object catch (error, stackTrace) {
      session.log(
        'Play Integrity verification failed.',
        level: LogLevel.warning,
        exception: error,
        stackTrace: stackTrace,
      );
      return const DeviceIntegrityVerdict(
        trusted: false,
        reasonCode: 'device_integrity_unavailable',
        provider: 'google-play-integrity',
      );
    } finally {
      client?.close();
    }
  }
}

/// Evaluates the already decrypted Google payload against Verily's policy.
DeviceIntegrityVerdict evaluateGooglePlayIntegrityPayload(
  Map<String, dynamic> payload, {
  required String requestHash,
  required DateTime now,
}) {
  final request = payload['requestDetails'] as Map<String, dynamic>?;
  final packageName = request?['requestPackageName'] as String?;
  final returnedHash = request?['requestHash'] as String?;
  final timestamp = int.tryParse(request?['timestampMillis'] as String? ?? '');
  if (packageName != _expectedPackageName ||
      returnedHash != requestHash ||
      timestamp == null) {
    return _invalidVerdict;
  }
  final requestedAt = DateTime.fromMillisecondsSinceEpoch(
    timestamp,
    isUtc: true,
  );
  final age = now.toUtc().difference(requestedAt);
  if (age.isNegative || age > _maximumVerdictAge) return _invalidVerdict;

  final appIntegrity = payload['appIntegrity'] as Map<String, dynamic>?;
  if (appIntegrity?['appRecognitionVerdict'] != 'PLAY_RECOGNIZED') {
    return const DeviceIntegrityVerdict(
      trusted: false,
      reasonCode: 'app_integrity_not_recognised',
      provider: 'google-play-integrity',
    );
  }
  final deviceIntegrity = payload['deviceIntegrity'] as Map<String, dynamic>?;
  final labels = (deviceIntegrity?['deviceRecognitionVerdict'] as List?)
      ?.whereType<String>();
  if (labels == null || !labels.contains('MEETS_DEVICE_INTEGRITY')) {
    return const DeviceIntegrityVerdict(
      trusted: false,
      reasonCode: 'device_integrity_not_met',
      provider: 'google-play-integrity',
    );
  }
  return const DeviceIntegrityVerdict(
    trusted: true,
    reasonCode: 'device_integrity_met',
    provider: 'google-play-integrity',
  );
}

const _invalidVerdict = DeviceIntegrityVerdict(
  trusted: false,
  reasonCode: 'device_integrity_invalid',
  provider: 'google-play-integrity',
);
