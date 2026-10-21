import 'package:test/test.dart';
import 'package:verily_server/src/abuse/action_abuse_gate.dart';

void main() {
  tearDown(() {
    ActionAbuseGateRegistry.configureFromEnvironment(const {});
  });

  test('development defaults to the explicit disabled gate', () {
    ActionAbuseGateRegistry.configureFromEnvironment(const {});

    expect(ActionAbuseGateRegistry.current.isEnforced, isFalse);
  });

  test('enforcement requires signed captures and a strong pseudonym key', () {
    expect(
      () => ActionAbuseGateRegistry.configureFromEnvironment(const {
        'VERILY_ABUSE_RUNTIME_MODE': 'enforced',
        'VERILY_CAPTURE_SIGNATURE_MODE': 'optional',
      }),
      throwsStateError,
    );
    expect(ActionAbuseGateRegistry.current.isEnforced, isFalse);

    expect(
      () => ActionAbuseGateRegistry.configureFromEnvironment(const {
        'VERILY_ABUSE_RUNTIME_MODE': 'enforced',
        'VERILY_CAPTURE_SIGNATURE_MODE': 'required',
        'VERILY_ABUSE_PSEUDONYM_SECRET': 'short',
        'VERILY_ABUSE_PSEUDONYM_KEY_EPOCH': 'pilot-2026-09',
      }),
      throwsArgumentError,
    );
    expect(ActionAbuseGateRegistry.current.isEnforced, isFalse);
  });

  test('an unknown or advisory mode fails closed instead of silently '
      'disabling', () {
    for (final mode in ['advisory', 'ENFORCED', 'on']) {
      expect(
        () => ActionAbuseGateRegistry.configureFromEnvironment({
          'VERILY_ABUSE_RUNTIME_MODE': mode,
          'VERILY_CAPTURE_SIGNATURE_MODE': 'required',
        }),
        throwsStateError,
        reason: mode,
      );
      expect(ActionAbuseGateRegistry.current.isEnforced, isFalse);
    }
  });

  test('a complete controlled-pilot policy activates enforcement', () {
    ActionAbuseGateRegistry.configureFromEnvironment(const {
      'VERILY_ABUSE_RUNTIME_MODE': 'enforced',
      'VERILY_CAPTURE_SIGNATURE_MODE': 'required',
      'VERILY_ABUSE_PSEUDONYM_SECRET':
          'test-only-abuse-pseudonym-secret-32-bytes',
      'VERILY_ABUSE_PSEUDONYM_KEY_EPOCH': 'pilot-2026-09',
    });

    expect(ActionAbuseGateRegistry.current.isEnforced, isTrue);
  });
}
