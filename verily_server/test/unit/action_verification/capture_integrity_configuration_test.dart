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

  test("Apple's sandbox is accepted only by development and test servers", () {
    const sandbox = {
      'VERILY_APPLE_TEAM_ID': 'TEAMID1234',
      'VERILY_APP_ATTEST_ENVIRONMENT': 'development',
    };

    expect(
      () => validateCaptureIntegrityConfiguration(
        sandbox,
        developmentRunMode: true,
      ),
      returnsNormally,
    );
    expect(
      () => validateCaptureIntegrityConfiguration(sandbox),
      throwsStateError,
    );
    expect(
      () => validateCaptureIntegrityConfiguration(const {
        'VERILY_APPLE_TEAM_ID': 'TEAMID1234',
      }),
      returnsNormally,
    );
  });

  test('a malformed mode, digest, or App Attest value stops startup', () {
    for (final environment in [
      {'VERILY_CAPTURE_SIGNATURE_MODE': 'sometimes'},
      {'VERILY_DEVICE_INTEGRITY_MODE': 'maybe'},
      {'VERILY_ANDROID_SIGNING_CERT_SHA256': 'not-a-digest'},
      {'VERILY_APPLE_TEAM_ID': 'not-a-team'},
      {'VERILY_APP_ATTEST_ENVIRONMENT': 'staging'},
    ]) {
      expect(
        () => validateCaptureIntegrityConfiguration(environment),
        throwsStateError,
        reason: '$environment',
      );
    }
  });
}
