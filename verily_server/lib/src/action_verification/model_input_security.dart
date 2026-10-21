/// Central policy for untrusted values that cross an AI boundary.
///
/// Pattern matching is only one layer of the prompt-injection defense. Callers
/// must still keep system prompts, model IDs, schemas, tools, and authorization
/// decisions under server control.
abstract final class ModelInputSecurity {
  static String validateCreatorPrompt(String value) {
    return _validate(
      value,
      fieldName: 'action description',
      minimumLength: 20,
      maximumLength: 2000,
    );
  }

  /// Short creator or model copy that appears in a prompt or a draft: a
  /// title, key, safety note, or assumption.
  static String validateShortCopy(String value) {
    return _validate(
      value,
      fieldName: 'short text',
      minimumLength: 1,
      maximumLength: 128,
    );
  }

  static String validateVerificationPolicy(String value) {
    return _validate(
      value,
      fieldName: 'verification policy',
      minimumLength: 10,
      maximumLength: 2000,
    );
  }

  static bool isSafeVerificationPolicy(String value) {
    final normalized = value.trim();
    return normalized.length >= 10 &&
        normalized.length <= 2000 &&
        !_hasUnsafeContent(normalized);
  }

  static String _validate(
    String value, {
    required String fieldName,
    required int minimumLength,
    required int maximumLength,
  }) {
    final normalized = value.trim();
    if (normalized.length < minimumLength ||
        normalized.length > maximumLength) {
      throw ArgumentError(
        '$fieldName must be between $minimumLength and $maximumLength '
        'characters.',
      );
    }
    if (_hasUnsafeContent(normalized)) {
      throw const ModelInputSecurityException();
    }
    return normalized;
  }

  static bool _hasUnsafeContent(String value) {
    return _unsafeControlCharacters.hasMatch(value) ||
        _injectionPatterns.any((pattern) => pattern.hasMatch(value)) ||
        _hasCompactedInjectionPhrase(value) ||
        _containsEncodedInstruction(value);
  }

  static bool _hasCompactedInjectionPhrase(String value) {
    final compacted = value.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '');
    return _compactedInjectionPhrases.any(compacted.contains);
  }

  static bool _containsEncodedInstruction(String value) {
    return _encodedInstruction.hasMatch(value) ||
        _encodedHexInstruction.hasMatch(value);
  }

  static final RegExp _unsafeControlCharacters = RegExp(
    r'[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f\u202a-\u202e\u2066-\u2069]',
  );

  static final List<RegExp> _injectionPatterns = [
    RegExp(
      r'\b(?:ignore|disregard|forget)\s+(?:all\s+)?(?:previous|prior|above|earlier)\s+(?:(?:system|safety|security|original|given)\s+)?(?:instructions?|rules?|directives?|constraints?|prompts?)\b',
      caseSensitive: false,
    ),
    RegExp(
      r'\b(?:override|replace|bypass)\s+(?:your\s+|the\s+)?(?:system\s+)?(?:instructions?|rules?|directives?|constraints?|prompt)\b',
      caseSensitive: false,
    ),
    RegExp(
      r'\b(?:you\s+are\s+now|enter|activate)\s+(?:(?:a|the|in)\s+)?(?:developer|admin|debug|maintenance|jailbreak|unrestricted)\s+mode\b',
      caseSensitive: false,
    ),
    RegExp(
      r'\b(?:reveal|show|print|output|repeat)\s+(?:me\s+)?(?:your\s+|the\s+)?(?:hidden\s+|secret\s+|original\s+|system\s+)*(?:prompt|instructions?)\b',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:^|\n)\s*(?:system|developer|assistant|tool|function)\s*:',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:<\|(?:im_start|im_end|system|assistant|developer|tool)\|>|<<\s*sys\s*>>|\[/?\s*inst\s*\]|<\/?\s*(?:system|assistant|developer|tool|function)\s*>)',
      caseSensitive: false,
    ),
    RegExp(
      r'\b(?:call|invoke|execute)\s+(?:the\s+)?(?:tool|function|command)\b',
      caseSensitive: false,
    ),
  ];

  static const List<String> _compactedInjectionPhrases = [
    'ignorepreviousinstructions',
    'ignoreallpreviousinstructions',
    'ignorepriorinstructions',
    'systemoverride',
    'revealyoursystemprompt',
    'showyoursystemprompt',
    'youarenowdevelopermode',
    'enterjailbreakmode',
  ];

  static final RegExp _encodedInstruction = RegExp(
    r'\b(?:base64|decode|encoded?)\b.{0,40}\b[A-Za-z0-9+/]{48,}={0,2}\b',
    caseSensitive: false,
  );

  static final RegExp _encodedHexInstruction = RegExp(
    r'\b(?:hex|decode|encoded?)\b.{0,40}\b(?:[0-9a-fA-F]{2}){32,}\b',
    caseSensitive: false,
  );
}

class ModelInputSecurityException implements Exception {
  const ModelInputSecurityException();

  @override
  String toString() {
    return 'This content cannot be used for AI-assisted action creation or '
        'verification.';
  }
}
