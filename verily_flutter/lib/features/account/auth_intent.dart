import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Why an account is being requested.
///
/// The wording matters: a person who asked to save a draft should not be told
/// they need an account to "continue", and a person who opened a link should
/// be told what is waiting rather than that they are unauthorised.
enum AccountRequestReason {
  /// Start or continue an action.
  doAction,

  /// Create, save, or fund an action.
  createAction,

  /// Read private history: attempts, payouts, appeals.
  privateHistory,

  /// Manage Verily Apps and their keys.
  manageApps,

  /// Answer a verification request another App opened Verily with.
  answerRequest,

  /// Link this account to another App that asked.
  linkApp,
}

/// Stable identifier for a plain sign-in with no work behind it.
const signInIntentAction = 'sign-in';

/// The exact thing someone was doing when an account became necessary.
///
/// The destination is carried by the URL; this record keeps the action and
/// the object it belongs to, so it survives sign-in, cancellation, and an
/// expired session.
@immutable
class AuthIntent {
  const AuthIntent({required this.action, required this.reason, this.targetId});

  /// Stable identifier for the pending action, such as `begin-attempt`.
  final String action;

  /// Why the account is needed, used for the prompt copy.
  final AccountRequestReason reason;

  /// The object the action belongs to, such as an action id, so a resumed
  /// action cannot drift onto a different one after the detour.
  final String? targetId;

  @override
  bool operator ==(Object other) =>
      other is AuthIntent &&
      other.action == action &&
      other.reason == reason &&
      other.targetId == targetId;

  @override
  int get hashCode => Object.hash(action, reason, targetId);

  @override
  String toString() => 'AuthIntent($action, ${reason.name}, $targetId)';
}

/// Holds the pending intent across the sign-in detour.
///
/// The intent is deliberately kept on cancellation or an expired session:
/// someone who dismissed the prompt and later signs in still lands back on
/// the action they started.
class AuthIntentController extends Notifier<AuthIntent?> {
  @override
  AuthIntent? build() => null;

  /// The action waiting for an account, or null when nothing is pending.
  AuthIntent? get pendingIntent => state;

  set pendingIntent(AuthIntent? intent) => state = intent;

  /// Consumes the intent once its action has been accepted for execution.
  AuthIntent? take() {
    final intent = state;
    state = null;
    return intent;
  }
}

final authIntentProvider = NotifierProvider<AuthIntentController, AuthIntent?>(
  AuthIntentController.new,
);
