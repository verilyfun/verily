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
}) => {
  'requestDetails': {
    'requestPackageName': packageName,
    'requestHash': 'expected-request-hash',
    'timestampMillis': now.millisecondsSinceEpoch.toString(),
  },
  'appIntegrity': {'appRecognitionVerdict': 'PLAY_RECOGNIZED'},
  'deviceIntegrity': {
    'deviceRecognitionVerdict': ['MEETS_DEVICE_INTEGRITY'],
  },
};
