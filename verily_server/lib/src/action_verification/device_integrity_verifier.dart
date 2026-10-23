import 'dart:convert';

import 'package:googleapis_auth/auth_io.dart';
import 'package:serverpod/serverpod.dart';

const _playIntegrityScope = 'https://www.googleapis.com/auth/playintegrity';
const _expectedPackageName = 'fun.verily.app';
const _maximumVerdictAge = Duration(minutes: 2);

/// Review reason: Play saw an app that may capture the screen, control the
/// device, or draw over Verily while the proof was made.
const deviceCaptureRiskReviewCode = 'device_capture_risk';

/// Review reason: the device made an unusual number of integrity requests
/// recently, which is how farms of accounts show up.
const deviceActivityRiskReviewCode = 'device_activity_risk';

/// Apple risk checks could not complete; no automatic acceptance.
const appleDeviceRiskUnavailableReviewCode = 'apple_device_risk_unavailable';

/// A scoped operator set the device's durable review bit.
const appleDeviceReviewCode = 'apple_device_review';

class DeviceIntegrityVerdict {
  const DeviceIntegrityVerdict({
    required this.trusted,
    required this.reasonCode,
    required this.provider,
    this.reviewReasonCode,
  });

  final bool trusted;
  final String reasonCode;
  final String provider;

  /// Set on a trusted verdict that carries a risk a person should weigh
  /// before the proof is decided: [deviceCaptureRiskReviewCode] or
  /// [deviceActivityRiskReviewCode].
  final String? reviewReasonCode;
}

abstract interface class DeviceIntegrityVerifier {
  String get providerName;

  /// [requireStrongIntegrity] raises the bar to `MEETS_STRONG_INTEGRITY`,
  /// for proof whose reward is above the review threshold.
  Future<DeviceIntegrityVerdict> verify(
    Session session, {
    required String token,
    required String requestHash,
    required DateTime now,
    required bool requireStrongIntegrity,
  });
}

class GooglePlayIntegrityVerifier implements DeviceIntegrityVerifier {
  const GooglePlayIntegrityVerifier({
    this.signingCertificateDigests = const {},
  });

  /// Lowercase hex SHA-256 digests of the release signing certificates
  /// (`VERILY_ANDROID_SIGNING_CERT_SHA256`). When set, Play must report one
  /// of them for the app that asked.
  final Set<String> signingCertificateDigests;

  @override
  String get providerName => 'google-play-integrity';

  @override
  Future<DeviceIntegrityVerdict> verify(
    Session session, {
    required String token,
    required String requestHash,
    required DateTime now,
    required bool requireStrongIntegrity,
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
        requireStrongIntegrity: requireStrongIntegrity,
        signingCertificateDigests: signingCertificateDigests,
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
///
/// - The verdict must answer this exact request, for this package, within
///   two minutes, from a Play-recognised build (signed with one of
///   [signingCertificateDigests] when any are configured).
/// - `MEETS_DEVICE_INTEGRITY` is required, and `MEETS_STRONG_INTEGRITY`
///   (a security patch from the last year on Android 13+) when
///   [requireStrongIntegrity].
/// - A trusted verdict goes to a person first when Play saw an unknown app
///   capturing the screen, controlling the device, or drawing overlays, or
///   when recent device activity is at `LEVEL_3` or `LEVEL_4`. Both signals
///   appear only when enabled in the Play Console; their absence is not a
///   risk.
DeviceIntegrityVerdict evaluateGooglePlayIntegrityPayload(
  Map<String, dynamic> payload, {
  required String requestHash,
  required DateTime now,
  bool requireStrongIntegrity = false,
  Set<String> signingCertificateDigests = const {},
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
  if (appIntegrity?['appRecognitionVerdict'] != 'PLAY_RECOGNIZED' ||
      (signingCertificateDigests.isNotEmpty &&
          !_signedWithReleaseCertificate(
            appIntegrity?['certificateSha256Digest'],
            signingCertificateDigests,
          ))) {
    return const DeviceIntegrityVerdict(
      trusted: false,
      reasonCode: 'app_integrity_not_recognised',
      provider: 'google-play-integrity',
    );
  }
  final deviceIntegrity = payload['deviceIntegrity'] as Map<String, dynamic>?;
  final labels = (deviceIntegrity?['deviceRecognitionVerdict'] as List?)
      ?.whereType<String>()
      .toSet();
  if (labels == null || !labels.contains('MEETS_DEVICE_INTEGRITY')) {
    return const DeviceIntegrityVerdict(
      trusted: false,
      reasonCode: 'device_integrity_not_met',
      provider: 'google-play-integrity',
    );
  }
  final strong = labels.contains('MEETS_STRONG_INTEGRITY');
  if (requireStrongIntegrity && !strong) {
    return const DeviceIntegrityVerdict(
      trusted: false,
      reasonCode: 'device_integrity_not_strong',
      provider: 'google-play-integrity',
    );
  }

  final environment = payload['environmentDetails'] as Map<String, dynamic>?;
  final appAccess =
      environment?['appAccessRiskVerdict'] as Map<String, dynamic>?;
  final appsDetected = (appAccess?['appsDetected'] as List?)
      ?.whereType<String>();
  final activity =
      deviceIntegrity?['recentDeviceActivity'] as Map<String, dynamic>?;
  final reviewReasonCode =
      appsDetected?.any(_riskyAppsDuringCapture.contains) ?? false
      ? deviceCaptureRiskReviewCode
      : _farmingActivityLevels.contains(activity?['deviceActivityLevel'])
      ? deviceActivityRiskReviewCode
      : null;
  return DeviceIntegrityVerdict(
    trusted: true,
    reasonCode: strong ? 'device_integrity_strong' : 'device_integrity_met',
    provider: 'google-play-integrity',
    reviewReasonCode: reviewReasonCode,
  );
}

/// Apps Play did not install (or the system) that could feed or steer a
/// capture. Known apps with these abilities (accessibility tools, Play's
/// screen recorders) are left alone, as Google recommends.
const _riskyAppsDuringCapture = {
  'UNKNOWN_CAPTURING',
  'UNKNOWN_CONTROLLING',
  'UNKNOWN_OVERLAYS',
};

const _farmingActivityLevels = {'LEVEL_3', 'LEVEL_4'};

/// Play lists the installed app's signing certificates as unpadded
/// base64url SHA-256 digests.
bool _signedWithReleaseCertificate(
  Object? reported,
  Set<String> signingCertificateDigests,
) {
  if (reported is! List) return false;
  for (final digest in reported.whereType<String>()) {
    final List<int> bytes;
    try {
      bytes = base64Url.decode(base64Url.normalize(digest));
    } on FormatException {
      return false;
    }
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    if (signingCertificateDigests.contains(hex)) return true;
  }
  return false;
}

const _invalidVerdict = DeviceIntegrityVerdict(
  trusted: false,
  reasonCode: 'device_integrity_invalid',
  provider: 'google-play-integrity',
);
