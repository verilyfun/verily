import 'dart:convert';

import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/device_integrity_verifier.dart';

void main() {
  final now = DateTime.utc(2026, 8, 23, 19);

  test('accepts a fresh request-bound recognized physical device', () {
    final verdict = evaluateGooglePlayIntegrityPayload(
      _payload(now: now),
      requestHash: 'expected-request-hash',
      now: now,
    );

    expect(verdict.trusted, isTrue);
    expect(verdict.reasonCode, 'device_integrity_met');
  });

  test('rejects a verdict replayed for another request', () {
    final verdict = evaluateGooglePlayIntegrityPayload(
      _payload(now: now),
      requestHash: 'different-request-hash',
      now: now,
    );

    expect(verdict.trusted, isFalse);
    expect(verdict.reasonCode, 'device_integrity_invalid');
  });

  test('rejects an unrecognized app even on a healthy device', () {
    final payload = _payload(now: now);
    payload['appIntegrity'] = {
      'appRecognitionVerdict': 'UNRECOGNIZED_VERSION',
    };
    final verdict = evaluateGooglePlayIntegrityPayload(
      payload,
      requestHash: 'expected-request-hash',
      now: now,
    );

    expect(verdict.trusted, isFalse);
    expect(verdict.reasonCode, 'app_integrity_not_recognised');
  });

  group('Given a reward above the review threshold', () {
    test('when the device meets only basic device integrity then it is '
        'refused', () {
      final verdict = evaluateGooglePlayIntegrityPayload(
        _payload(now: now),
        requestHash: 'expected-request-hash',
        now: now,
        requireStrongIntegrity: true,
      );

      expect(verdict.trusted, isFalse);
      expect(verdict.reasonCode, 'device_integrity_not_strong');
    });

    test('when the device meets strong integrity then it is trusted', () {
      final verdict = evaluateGooglePlayIntegrityPayload(
        _payload(
          now: now,
          labels: ['MEETS_DEVICE_INTEGRITY', 'MEETS_STRONG_INTEGRITY'],
        ),
        requestHash: 'expected-request-hash',
        now: now,
        requireStrongIntegrity: true,
      );

      expect(verdict.trusted, isTrue);
      expect(verdict.reasonCode, 'device_integrity_strong');
    });
  });

  group('Given environment risk signals', () {
    for (final app in [
      'UNKNOWN_CAPTURING',
      'UNKNOWN_CONTROLLING',
      'UNKNOWN_OVERLAYS',
    ]) {
      test('when Play saw $app then a person reviews the proof', () {
        final payload = _payload(now: now)
          ..['environmentDetails'] = {
            'appAccessRiskVerdict': {
              'appsDetected': ['KNOWN_INSTALLED', app],
            },
          };

        final verdict = evaluateGooglePlayIntegrityPayload(
          payload,
          requestHash: 'expected-request-hash',
          now: now,
        );

        expect(verdict.trusted, isTrue);
        expect(verdict.reviewReasonCode, deviceCaptureRiskReviewCode);
      });
    }

    test('when only Play-installed apps have those abilities then nothing is '
        'flagged', () {
      final payload = _payload(now: now)
        ..['environmentDetails'] = {
          'appAccessRiskVerdict': {
            'appsDetected': [
              'KNOWN_INSTALLED',
              'KNOWN_CAPTURING',
              'KNOWN_CONTROLLING',
              'KNOWN_OVERLAYS',
              'UNKNOWN_INSTALLED',
            ],
          },
        };

      final verdict = evaluateGooglePlayIntegrityPayload(
        payload,
        requestHash: 'expected-request-hash',
        now: now,
      );

      expect(verdict.reviewReasonCode, isNull);
    });

    for (final level in ['LEVEL_3', 'LEVEL_4']) {
      test('when recent device activity is $level then a person reviews '
          'the proof', () {
        final verdict = evaluateGooglePlayIntegrityPayload(
          _payload(now: now, activityLevel: level),
          requestHash: 'expected-request-hash',
          now: now,
        );

        expect(verdict.trusted, isTrue);
        expect(verdict.reviewReasonCode, deviceActivityRiskReviewCode);
      });
    }

    for (final level in ['LEVEL_1', 'LEVEL_2', 'UNEVALUATED']) {
      test('when recent device activity is $level then nothing is '
          'flagged', () {
        final verdict = evaluateGooglePlayIntegrityPayload(
          _payload(now: now, activityLevel: level),
          requestHash: 'expected-request-hash',
          now: now,
        );

        expect(verdict.reviewReasonCode, isNull);
      });
    }
  });

  group('Given a configured release signing certificate', () {
    final release = 'ab' * 32;
    final releaseDigest = base64Url
        .encode(List<int>.filled(32, 0xab))
        .replaceAll('=', '');

    test('when Play reports it then the app is recognised', () {
      final verdict = evaluateGooglePlayIntegrityPayload(
        _payload(now: now, certificateDigests: [releaseDigest]),
        requestHash: 'expected-request-hash',
        now: now,
        signingCertificateDigests: {release},
      );

      expect(verdict.trusted, isTrue);
    });

    test('when Play reports another certificate then the app is refused', () {
      final verdict = evaluateGooglePlayIntegrityPayload(
        _payload(
          now: now,
          certificateDigests: [
            base64Url.encode(List<int>.filled(32, 1)).replaceAll('=', ''),
          ],
        ),
        requestHash: 'expected-request-hash',
        now: now,
        signingCertificateDigests: {release},
      );

      expect(verdict.trusted, isFalse);
      expect(verdict.reasonCode, 'app_integrity_not_recognised');
    });
  });

  for (final packageName in [
    'com.ifiokjr.nifty',
    'app.verily',
    'com.example.other',
  ]) {
    test('rejects an otherwise valid verdict for $packageName', () {
      final verdict = evaluateGooglePlayIntegrityPayload(
        _payload(now: now, packageName: packageName),
        requestHash: 'expected-request-hash',
        now: now,
      );

      expect(verdict.trusted, isFalse);
      expect(verdict.reasonCode, 'device_integrity_invalid');
    });
  }
}

Map<String, dynamic> _payload({
  required DateTime now,
  String packageName = 'fun.verily.app',
  List<String> labels = const ['MEETS_DEVICE_INTEGRITY'],
  String? activityLevel,
  List<String>? certificateDigests,
}) => {
  'requestDetails': {
    'requestPackageName': packageName,
    'requestHash': 'expected-request-hash',
    'timestampMillis': now.millisecondsSinceEpoch.toString(),
  },
  'appIntegrity': {
    'appRecognitionVerdict': 'PLAY_RECOGNIZED',
    'certificateSha256Digest': ?certificateDigests,
  },
  'deviceIntegrity': {
    'deviceRecognitionVerdict': labels,
    if (activityLevel != null)
      'recentDeviceActivity': {'deviceActivityLevel': activityLevel},
  },
};
