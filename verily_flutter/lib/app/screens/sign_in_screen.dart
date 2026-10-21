import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:skribble/skribble.dart' show WiredDivider;
import 'package:verily_brand/verily_brand.dart';

import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/core/api_client.dart';
import 'package:verily_flutter/core/auth_configuration.dart';
import 'package:verily_flutter/features/account/account_session.dart';
import 'package:verily_flutter/features/account/auth_intent.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// Email and Google sign-in, worded for why an account is needed.
///
/// Serverpod's sign-in kit draws the provider controls; this page frames them
/// on paper, says why the account is asked for, and offers a way out that
/// keeps the person's place.
class SignInScreen extends HookConsumerWidget {
  const SignInScreen({
    required this.onSignedIn,
    this.onCancel,
    this.reason,
    this.startWithSignIn = false,
    this.emailEnabled = emailAuthEnabled,
    this.googleEnabled = googleAuthEnabled,
    super.key,
  });

  /// Called once the session has an account.
  final VoidCallback onSignedIn;

  /// Leaves without an account. The pending intent is kept.
  final VoidCallback? onCancel;

  /// Why the account is needed; null for a plain sign-in.
  final AccountRequestReason? reason;

  /// Opens the email form on signing in, for someone who said they already
  /// have an account, instead of on signing up.
  final bool startWithSignIn;

  /// Which sign-in methods to offer. Builds decide with dart-defines; tests
  /// turn them off so no provider reaches a network.
  final bool emailEnabled;
  final bool googleEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    final client = ref.watch(verilyClientProvider);
    final signedIn = ref.watch(
      accountSessionProvider.select((session) => session.isSignedIn),
    );

    // The kit reports success, and the session also changes; whichever comes
    // first finishes sign-in, exactly once.
    final finished = useRef(false);
    void finish() {
      if (finished.value) return;
      finished.value = true;
      onSignedIn();
    }

    useEffect(() {
      if (signedIn) {
        WidgetsBinding.instance.addPostFrameCallback((_) => finish());
      }
      return null;
    }, [signedIn]);

    void handleError(Object error) {
      debugPrint('Sign-in failed: $error');
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.signInFailed)));
    }

    final title = switch (reason) {
      null => l10n.signInTitle,
      AccountRequestReason.doAction => l10n.signInTitleDoAction,
      AccountRequestReason.createAction => l10n.signInTitleCreateAction,
      AccountRequestReason.privateHistory => l10n.signInTitlePrivateHistory,
      AccountRequestReason.manageApps => l10n.signInTitleManageApps,
    };
    final providersOff = !emailEnabled && !googleEnabled;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 48).clamp(
                  0,
                  double.infinity,
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: Container(
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: VerilyRoughDecoration(
                      color: palette.surface,
                      outline: palette.ink,
                      radius: VerilyRadius.sheet,
                      seed: 83,
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: VerilyLockup(
                                    height: 40,
                                    accentColor: palette.accent,
                                    inkColor: palette.ink,
                                    semanticLabel: l10n.appTitle,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Semantics(
                                  headingLevel: 1,
                                  child: Text(
                                    title,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: palette.ink,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.signInSubtitle,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: palette.mutedInk,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (providersOff)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                              child: Text(
                                l10n.signInUnavailable,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: palette.ink,
                                ),
                              ),
                            )
                          else
                            // The kit lays each email step out in a fixed
                            // 330-point box, and with Verily's faces even a
                            // 1.1x scale clips its fields. Its forms stay at
                            // the base size until they can grow; Verily's own
                            // words around them follow the person's setting.
                            MediaQuery.withNoTextScaling(
                              child: SignInLocalizationProvider(
                                // The kit sets each prompt and its link in a
                                // row that cannot wrap, so the prompts stay
                                // short enough for a narrow phone.
                                email: EmailSignInTexts.defaults.copyWith(
                                  title: l10n.signInEmailTitle,
                                  signUpTitle: l10n.signInEmailSignUpTitle,
                                  verificationMessage:
                                      l10n.signInVerificationPrompt,
                                  // The kit puts the link right after the
                                  // prompt with no gap, so the prompt ends
                                  // in a space that cannot collapse.
                                  alreadyHaveAnAccount:
                                      '${l10n.signInHaveAccountPrompt}$_noBreakSpace',
                                  dontHaveAnAccount:
                                      '${l10n.signInNewHerePrompt}$_noBreakSpace',
                                ),
                                passwordRequirementTexts:
                                    PasswordRequirementTexts(
                                      // The kit fills `{length}` in itself.
                                      minLengthTemplate: l10n
                                          .signInPasswordMinLength('{length}'),
                                      maxLengthTemplate: l10n
                                          .signInPasswordMaxLength('{length}'),
                                      containsLowercase:
                                          l10n.signInPasswordLowercase,
                                      containsUppercase:
                                          l10n.signInPasswordUppercase,
                                      containsNumber: l10n.signInPasswordNumber,
                                      containsSpecialCharacter:
                                          l10n.signInPasswordSymbol,
                                    ),
                                child: SignInWidget(
                                  client: client,
                                  emailSignInWidget: startWithSignIn
                                      ? EmailSignInWidget(
                                          client: client,
                                          startScreen: EmailFlowScreen.login,
                                          onAuthenticated: finish,
                                          onError: handleError,
                                        )
                                      : null,
                                  disableEmailSignInWidget: !emailEnabled,
                                  disableGoogleSignInWidget: !googleEnabled,
                                  onAuthenticated: finish,
                                  onError: handleError,
                                ),
                              ),
                            ),
                          if (onCancel case final cancel?)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const ExcludeSemantics(child: WiredDivider()),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.signInIntentKept,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: palette.mutedInk,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    key: VerilyTestKeys.signInCancel,
                                    onPressed: cancel,
                                    child: Text(l10n.signInNotNow),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _noBreakSpace = '\u00A0';
