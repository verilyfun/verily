import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/apps/platform_keys.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// Prefix of every App webhook signing secret.
const webhookSecretPrefix = 'whsec_';

/// How long events are also signed with the secret a rotation replaced.
const webhookSecretOverlap = Duration(hours: 24);

/// Derives App webhook secrets from one server master key.
///
/// `whsec_<base64url(HMAC-SHA256(master, "verily-webhook-secret-v1|<appId>|<version>"))>`
///
/// Nothing secret is stored per App, only a version number: a database leak
/// reveals no secret, rotation is a version bump, and the server can always
/// re-derive the secret it needs to sign a retry. The trade-off is that the
/// master key protects every App at once, exactly as an encryption-at-rest
/// key would; rotating it changes every App's secret.
final class WebhookSecrets {
  const WebhookSecrets(this._masterKey);

  /// The configured keys, or null when this server cannot sign webhooks.
  static WebhookSecrets? get configured {
    final key = PlatformKeys.current.webhookSigningMasterKey;
    return key == null ? null : WebhookSecrets(key);
  }

  final List<int> _masterKey;

  String secretFor({required UuidValue appId, required int version}) {
    if (version < 1) throw ArgumentError.value(version, 'version');
    final digest = Hmac(sha256, _masterKey).convert(
      utf8.encode('verily-webhook-secret-v1|$appId|$version'),
    );
    return '$webhookSecretPrefix${_base64UrlNoPad(digest.bytes)}';
  }

  /// The secrets an outbound request is signed with: the current one, plus
  /// the previous one during the overlap after a rotation.
  List<String> signingSecretsFor(VerilyApp app, DateTime now) {
    final current = app.webhookSecretVersion;
    if (current < 1) return const [];
    final previous = app.previousWebhookSecretVersion;
    final rotatedAt = app.webhookSecretRotatedAt;
    return [
      secretFor(appId: app.id!, version: current),
      if (previous != null &&
          rotatedAt != null &&
          now.isBefore(rotatedAt.add(webhookSecretOverlap)))
        secretFor(appId: app.id!, version: previous),
    ];
  }
}

/// `Verily-Signature: t=<unix>,v1=<hex HMAC-SHA256(secret, t + "." + body)>`,
/// with one `v1` entry per secret. The HMAC key is the UTF-8 bytes of the
/// whole `whsec_…` string.
String webhookSignatureHeader({
  required int timestamp,
  required String body,
  required List<String> secrets,
}) {
  if (secrets.isEmpty) throw ArgumentError.value(secrets, 'secrets');
  final payload = utf8.encode('$timestamp.$body');
  return [
    't=$timestamp',
    for (final secret in secrets)
      'v1=${Hmac(sha256, utf8.encode(secret)).convert(payload)}',
  ].join(',');
}

/// A new public event id: `vev_` plus 22 base64url characters (128 bits).
String newWebhookEventId({Random? random}) {
  final source = random ?? Random.secure();
  return 'vev_${_base64UrlNoPad([for (var i = 0; i < 16; i += 1) source.nextInt(256)])}';
}

String _base64UrlNoPad(List<int> bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');
