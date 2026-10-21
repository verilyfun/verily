import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/capture_integrity.dart';

void main() {
  final digest = 'ab' * 32;

  test('development defaults need no capture configuration', () {
    expect(
      () => validateCaptureIntegrityConfiguration(const {}),
      returnsNormally,
    );
  });

  test('required signatures with a signing certificate start', () {
    expect(
      () => validateCaptureIntegrityConfiguration({
        'VERILY_CAPTURE_SIGNATURE_MODE': 'required',
        'VERILY_DEVICE_INTEGRITY_MODE': 'required',
        'VERILY_ANDROID_SIGNING_CERT_SHA256': digest,
      }),
      returnsNormally,
    );
  });

  test('required signatures without a signing certificate stop startup', () {
    expect(
      () => validateCaptureIntegrityConfiguration(const {
        'VERILY_CAPTURE_SIGNATURE_MODE': 'required',
      }),
      throwsStateError,
    );
  });

  test('a malformed mode or digest stops startup', () {
    for (final environment in [
      {'VERILY_CAPTURE_SIGNATURE_MODE': 'sometimes'},
      {'VERILY_DEVICE_INTEGRITY_MODE': 'maybe'},
      {'VERILY_ANDROID_SIGNING_CERT_SHA256': 'not-a-digest'},
    ]) {
      expect(
        () => validateCaptureIntegrityConfiguration(environment),
        throwsStateError,
        reason: '$environment',
      );
    }
  });
}
