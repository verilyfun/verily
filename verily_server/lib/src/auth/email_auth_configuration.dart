enum EmailAuthMode { disabled, developmentLog, resend }

class EmailAuthConfiguration {
  const EmailAuthConfiguration._({
    required this.mode,
    this.resendApiKey,
    this.fromAddress,
  });

  factory EmailAuthConfiguration.fromEnvironment(
    Map<String, String> environment,
  ) {
    final runMode =
        environment['runmode']?.trim().toLowerCase() ?? 'development';
    final configuredMode = environment['VERILY_EMAIL_AUTH_MODE']
        ?.trim()
        .toLowerCase();
    final mode = switch (configuredMode) {
      null || '' when runMode == 'development' => EmailAuthMode.developmentLog,
      null || '' => EmailAuthMode.disabled,
      'disabled' => EmailAuthMode.disabled,
      'development-log' => EmailAuthMode.developmentLog,
      'resend' => EmailAuthMode.resend,
      _ => throw StateError(
        'VERILY_EMAIL_AUTH_MODE must be disabled, development-log, or resend.',
      ),
    };

    if (mode == EmailAuthMode.developmentLog && runMode != 'development') {
      throw StateError(
        'Development email-code logging is forbidden outside development mode.',
      );
    }

    if (mode != EmailAuthMode.resend) {
      return EmailAuthConfiguration._(mode: mode);
    }

    final apiKey = environment['VERILY_RESEND_API_KEY']?.trim() ?? '';
    final fromAddress = environment['VERILY_EMAIL_FROM']?.trim() ?? '';
    if (apiKey.isEmpty || fromAddress.isEmpty) {
      throw StateError(
        'Resend email authentication requires VERILY_RESEND_API_KEY and '
        'VERILY_EMAIL_FROM.',
      );
    }

    return EmailAuthConfiguration._(
      mode: mode,
      resendApiKey: apiKey,
      fromAddress: fromAddress,
    );
  }

  final EmailAuthMode mode;
  final String? resendApiKey;
  final String? fromAddress;

  bool get isEnabled => mode != EmailAuthMode.disabled;
}
