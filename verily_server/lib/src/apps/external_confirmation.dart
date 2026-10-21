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
  actionUnavailable('action_unavailable', 422);

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
