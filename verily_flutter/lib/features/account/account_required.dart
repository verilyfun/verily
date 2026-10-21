import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/app/screens/sign_in_screen.dart';
import 'package:verily_flutter/features/account/account_session.dart';
import 'package:verily_flutter/features/account/auth_intent.dart';

/// Shows a destination only when the session has an account.
///
/// Applied per destination rather than to the whole app, so the destination
/// stays in the URL while an account is missing: signing in shows the same
/// page, and a reload or Back restores it. The server refuses every
/// unauthorized call regardless; this is a navigation affordance, not a
/// security boundary.
class AccountRequired extends ConsumerWidget {
  const AccountRequired({
    required this.child,
    this.reason = AccountRequestReason.doAction,
    super.key,
  });

  final Widget child;

  /// Why the account is needed, for the prompt's wording.
  final AccountRequestReason reason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only the signed-in flag rebuilds this; a token refresh mid-entry must
    // not tear down the page (or a web text field) under the person.
    final signedIn = ref.watch(
      accountSessionProvider.select((session) => session.isSignedIn),
    );
    if (signedIn) return child;

    return SignInScreen(
      reason: reason,
      onSignedIn: () {},
      onCancel: () => _leaveWithoutAccount(context),
    );
  }

  void _leaveWithoutAccount(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    router.goNamed(VerilyRouteNames.welcome);
  }
}

/// Records the pending action and sends the person to sign in. Returns true
/// when an account is already present and the caller may go ahead.
bool requireAccount(
  BuildContext context,
  WidgetRef ref, {
  required AccountRequestReason reason,
  required String action,
  String? targetId,
}) {
  if (ref.read(accountSessionProvider).isSignedIn) return true;
  ref.read(authIntentProvider.notifier).pendingIntent = AuthIntent(
    action: action,
    reason: reason,
    targetId: targetId,
  );
  final router = GoRouter.of(context);
  router.go(VerilyLocations.signIn(from: router.state.uri.toString()));
  return false;
}
