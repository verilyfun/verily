import 'dart:convert';

/// Server-owned key material for the App platform, configured once at startup
/// from Monosecret-resolved secrets.
///
/// Features read raw values here and parse what they need, so a missing or
/// malformed key fails only the feature that depends on it, with a typed,
/// product-safe error rather than a process crash at request time. Startup
/// still validates every configured value (see [PlatformKeys.fromSecrets]).
final class PlatformKeys {
  const PlatformKeys({
    this.webhookSigningMasterKey,
    this.receiptSigningKey,
    this.retiredReceiptPublicKeys = const [],
  });

  /// Parses the configured secrets. A value that is present but malformed
  /// throws, so a typo stops startup instead of silently disabling webhooks
  /// or receipts.
  factory PlatformKeys.fromSecrets({
    String? webhookSigningMasterKey,
    String? receiptSigningKey,
    String? retiredReceiptPublicKeys,
  }) {
    final webhook = _optionalBytes(
      webhookSigningMasterKey,
      name: 'VERILY_WEBHOOK_SIGNING_MASTER_KEY',
      minimumLength: 32,
    );
    final receipt = _optionalBytes(
      receiptSigningKey,
      name: 'VERILY_RECEIPT_SIGNING_KEY',
      minimumLength: 32,
      maximumLength: 32,
    );
    final retired = [
      for (final value in (retiredReceiptPublicKeys ?? '').split(','))
        if (value.trim().isNotEmpty)
          _optionalBytes(
            value,
            name: 'VERILY_RECEIPT_RETIRED_PUBLIC_KEYS',
            minimumLength: 32,
            maximumLength: 32,
          )!,
    ];
    return PlatformKeys(
      webhookSigningMasterKey: webhook,
      receiptSigningKey: receipt,
      retiredReceiptPublicKeys: List.unmodifiable(retired),
    );
  }

  /// HMAC key every App's `whsec_` secret is derived from (at least 32 bytes).
  final List<int>? webhookSigningMasterKey;

  /// The active Ed25519 receipt signing seed (32 bytes).
  final List<int>? receiptSigningKey;

  /// Public keys of retired receipt signers, still published in the JWKS so
  /// receipts they signed keep verifying.
  final List<List<int>> retiredReceiptPublicKeys;

  /// Process-wide keys, set by startup before endpoints run.
  static PlatformKeys current = const PlatformKeys();
}

/// Decodes standard or URL-safe base64, padded or not.
List<int>? _optionalBytes(
  String? value, {
  required String name,
  required int minimumLength,
  int? maximumLength,
}) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  final List<int> bytes;
  try {
    final normalized = trimmed.replaceAll('-', '+').replaceAll('_', '/');
    bytes = base64.decode(
      normalized.padRight((normalized.length + 3) ~/ 4 * 4, '='),
    );
  } on FormatException {
    throw StateError('$name must be base64.');
  }
  if (bytes.length < minimumLength ||
      (maximumLength != null && bytes.length > maximumLength)) {
    throw StateError(
      maximumLength == minimumLength
          ? '$name must decode to exactly $minimumLength bytes.'
          : '$name must decode to at least $minimumLength bytes.',
    );
  }
  return List.unmodifiable(bytes);
}
