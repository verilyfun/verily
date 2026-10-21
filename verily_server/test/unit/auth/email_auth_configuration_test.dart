import 'package:test/test.dart';
import 'package:verily_server/src/auth/email_auth_configuration.dart';

void main() {
  group('EmailAuthConfiguration', () {
    test('uses development-only logging for local development', () {
      final configuration = EmailAuthConfiguration.fromEnvironment(const {
        'runmode': 'development',
      });

      expect(configuration.mode, EmailAuthMode.developmentLog);
      expect(configuration.isEnabled, isTrue);
    });

    test('disables email auth by default outside development', () {
      final configuration = EmailAuthConfiguration.fromEnvironment(const {
        'runmode': 'production',
      });

      expect(configuration.mode, EmailAuthMode.disabled);
      expect(configuration.isEnabled, isFalse);
    });

    test('rejects code logging in production', () {
      expect(
        () => EmailAuthConfiguration.fromEnvironment(const {
          'runmode': 'production',
          'VERILY_EMAIL_AUTH_MODE': 'development-log',
        }),
        throwsStateError,
      );
    });

    test('requires complete Resend configuration', () {
      expect(
        () => EmailAuthConfiguration.fromEnvironment(const {
          'runmode': 'production',
          'VERILY_EMAIL_AUTH_MODE': 'resend',
          'VERILY_RESEND_API_KEY': 'configured',
        }),
        throwsStateError,
      );
    });

    test('accepts complete Resend configuration', () {
      final configuration = EmailAuthConfiguration.fromEnvironment(const {
        'runmode': 'production',
        'VERILY_EMAIL_AUTH_MODE': 'resend',
        'VERILY_RESEND_API_KEY': 'configured',
        'VERILY_EMAIL_FROM': 'Verily <hello@verily.example>',
      });

      expect(configuration.mode, EmailAuthMode.resend);
      expect(configuration.resendApiKey, 'configured');
      expect(configuration.fromAddress, 'Verily <hello@verily.example>');
    });
  });
}
