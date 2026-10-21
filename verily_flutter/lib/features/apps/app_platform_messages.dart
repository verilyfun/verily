import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/core/user_message.dart';
import 'package:verily_flutter/l10n/l10n.dart';

/// The words a person sees for a failed App platform call.
///
/// [AppPlatformException]s are explained in the app's own language from
/// their problem, so the rule behind a refusal (https only, public hosts,
/// exact return addresses) reads the same everywhere. [appName] names the
/// App in messages about it. Anything else falls back to [userMessageFor].
String appPlatformMessage(
  AppLocalizations l10n,
  Object error, {
  String? appName,
}) {
  if (error is! AppPlatformException) return userMessageFor(l10n, error);
  final app = appName ?? l10n.actionAppUnnamed;
  return switch (error.problem) {
    AppPlatformProblem.invalidWebhookUrl => l10n.appsWebhookInvalid,
    AppPlatformProblem.webhooksUnavailable => l10n.appsWebhooksUnavailable,
    AppPlatformProblem.invalidRedirectUri => l10n.appsRedirectInvalid,
    AppPlatformProblem.tooManyRedirectUris => l10n.appsRedirectTooMany(
      maxAppRedirectUris,
    ),
    AppPlatformProblem.invalidReference => l10n.actionPullReferenceInvalid,
    AppPlatformProblem.pullVerificationUnavailable =>
      l10n.actionPullUnavailable(app),
    AppPlatformProblem.rateLimited => l10n.appsRateLimited,
    // Linking and verification requests explain their own problems where
    // they happen.
    _ => l10n.errorGeneric,
  };
}

/// The most return addresses one App may register, as the server enforces.
const maxAppRedirectUris = 10;

/// The participant's optional note for a pull check: up to 120 letters,
/// digits, spaces, and `._@#:/+-`, the same rule the server applies.
final RegExp pullReferencePattern = RegExp(
  r'^[\p{L}\p{N} ._@#:/+\-]{1,120}$',
  unicode: true,
);

/// The reference to send, trimmed; null when empty. Throws [FormatException]
/// when it breaks [pullReferencePattern], so nothing the server would refuse
/// leaves the phone.
String? normalizePullReference(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  if (!pullReferencePattern.hasMatch(trimmed)) {
    throw const FormatException('Invalid pull reference.');
  }
  return trimmed;
}
