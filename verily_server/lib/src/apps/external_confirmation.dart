import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// Why an App confirmation cannot count toward an attempt.
///
/// Each reason is persisted on the confirmation receipt as [code] and
/// replayed with the same [httpStatus] when the App retries the event id.
enum ExternalConfirmationRejection {
  unknownAction('unknown_action', 404),
  unknownSubject('unknown_subject', 404),
  occurredAtOutOfRange('occurred_at_out_of_range', 422),
  occurredOutsideWindow('occurred_outside_window', 422),
  occurredOutsidePeriod('occurred_outside_period', 422),
  actionUnavailable('action_unavailable', 422),

  /// A pull requirement takes a push only when it names the attempt.
  pullRequiresAttempt('pull_requires_attempt', 422),

  /// The named attempt does not exist for this App, subject, and action.
  unknownAttempt('unknown_attempt', 404),

  /// The named attempt has no open pull verification check to settle.
  noOpenPullCheck('no_open_pull_check', 409);

  const ExternalConfirmationRejection(this.code, this.httpStatus);

  final String code;
  final int httpStatus;

  static ExternalConfirmationRejection? fromCode(String code) {
    for (final rejection in values) {
      if (rejection.code == code) return rejection;
    }
    return null;
  }
}

/// Result of applying one App confirmation inside the delivery transaction.
sealed class ExternalConfirmation {
  const ExternalConfirmation();
}

/// The confirmation was recorded against [attempt], or the attempt for that
/// period had already finished ([alreadyComplete]).
final class ExternalConfirmationAccepted extends ExternalConfirmation {
  const ExternalConfirmationAccepted({
    required this.actionDefinitionId,
    required this.attempt,
    required this.alreadyComplete,
  });

  final UuidValue actionDefinitionId;
  final ActionAttemptView attempt;
  final bool alreadyComplete;

  String get reasonCode =>
      alreadyComplete ? 'attempt_already_complete' : 'app_confirmed';
}

final class ExternalConfirmationRejected extends ExternalConfirmation {
  const ExternalConfirmationRejected(this.reason, {this.actionDefinitionId});

  final ExternalConfirmationRejection reason;
  final UuidValue? actionDefinitionId;
}

/// What applying an App's verdict to a known attempt did.
final class AppVerdictOutcome {
  const AppVerdictOutcome({
    required this.applied,
    required this.code,
    this.attempt,
    this.decisionStatus,
    this.summary,
  });

  /// Whether a decision was recorded and the attempt completed.
  final bool applied;

  /// The decision's reason code when applied, otherwise why not:
  /// `unknown_attempt`, `participant_unavailable`, `unknown_requirement`,
  /// `attempt_closed`, or `action_unavailable`.
  final String code;
  final ActionAttemptView? attempt;
  final EvidenceDecisionStatus? decisionStatus;
  final String? summary;
}
