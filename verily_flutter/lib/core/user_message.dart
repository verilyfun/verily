import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/l10n/l10n.dart';

/// The words a person sees for [error].
///
/// The server sends typed, product-safe exceptions whose message is written
/// for people (`ActionAuthoringException`, `ActionDraftingUnavailableException`,
/// `AppUnavailableException`, `RewardException`); those are shown as they are.
/// The exception is an action the server refused as invalid or unsafe. That
/// message names the broken rule for developers, so people see the app's own
/// words instead.
/// Anything else, including transport errors and stack traces, becomes the
/// generic message, so no provider name, route, or diagnostic reaches the
/// screen. A missing action or App reads as "not found". Log the error itself
/// where it is caught.
String userMessageFor(AppLocalizations l10n, Object error) => switch (error) {
  ActionAuthoringException(reason: ActionAuthoringProblem.invalidRequest) =>
    l10n.errorActionInvalid,
  ActionAuthoringException(reason: ActionAuthoringProblem.unsafeText) =>
    l10n.errorActionUnsafeText,
  ActionAuthoringException(:final message) ||
  ActionDraftingUnavailableException(:final message) ||
  AppUnavailableException(:final message) ||
  RewardException(:final message) when message.trim().isNotEmpty => message,
  ResourceNotFoundException() => l10n.errorNotFound,
  _ => l10n.errorGeneric,
};
