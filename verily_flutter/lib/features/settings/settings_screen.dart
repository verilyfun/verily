import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon, WiredDivider;

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/app/widgets/verily_appearance_settings.dart';
import 'package:verily_flutter/features/account/account_repository.dart';
import 'package:verily_flutter/features/me/widgets/pushed_page.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// The word the server requires before it closes an account.
const closeAccountConfirmationWord = 'DELETE';

/// Appearance, signing out, and closing the account.
class SettingsScreen extends HookConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    final isSigningOut = useState(false);
    final isClosing = useState(false);

    void say(String message) => ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));

    Future<void> signOut() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.settingsSignOutDialogTitle),
          content: Text(l10n.settingsSignOutDialogBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.dialogCancel),
            ),
            FilledButton(
              key: VerilyTestKeys.settingsSignOutConfirm,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.settingsSignOut),
            ),
          ],
        ),
      );
      if (confirmed != true || isSigningOut.value || !context.mounted) return;

      isSigningOut.value = true;
      try {
        await ref.read(accountRepositoryProvider).signOut();
        if (context.mounted) context.goNamed(VerilyRouteNames.welcome);
      } on Object catch (error) {
        debugPrint('Sign out failed: $error');
        if (context.mounted) say(l10n.settingsSignOutFailed);
      } finally {
        if (context.mounted) isSigningOut.value = false;
      }
    }

    Future<void> closeAccount() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => const _CloseAccountDialog(),
      );
      if (confirmed != true || isClosing.value || !context.mounted) return;

      isClosing.value = true;
      final accounts = ref.read(accountRepositoryProvider);
      try {
        await accounts.closeAccount(confirmation: closeAccountConfirmationWord);
        // Closing revokes every session on the server; this ends the local
        // one so the device shows the front door at once.
        await accounts.signOut();
        if (context.mounted) context.goNamed(VerilyRouteNames.welcome);
      } on Object catch (error) {
        debugPrint('Closing the account failed: $error');
        if (context.mounted) say(l10n.settingsCloseAccountFailed);
      } finally {
        if (context.mounted) isClosing.value = false;
      }
    }

    return PushedPage(
      title: l10n.settingsTitle,
      fallbackRouteName: VerilyRouteNames.me,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            l10n.settingsSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.mutedInk,
            ),
          ),
          const SizedBox(height: 16),
          const VerilyAppearanceSettings(),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: VerilyRoughDecoration(
              color: palette.surface,
              outline: palette.ink,
              seed: 77,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeading(l10n.settingsAccountTitle),
                const SizedBox(height: 8),
                Text(
                  l10n.settingsSignOutSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.mutedInk,
                  ),
                ),
                const SizedBox(height: 12),
                // Signing out is reversible, so it sits on quiet paper.
                VerilyActionButton(
                  key: VerilyTestKeys.settingsSignOut,
                  label: l10n.settingsSignOut,
                  tone: VerilyActionTone.secondary,
                  isLoading: isSigningOut.value,
                  semanticHint: isSigningOut.value
                      ? l10n.settingsSigningOut
                      : null,
                  leading: const SkribbleIcon(data: VerilyIcons.logOut),
                  onPressed: () => unawaited(signOut()),
                ),
                const SizedBox(height: 16),
                const ExcludeSemantics(child: WiredDivider()),
                const SizedBox(height: 8),
                Text(
                  l10n.settingsCloseAccount,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.settingsCloseAccountSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.mutedInk,
                  ),
                ),
                const SizedBox(height: 12),
                VerilyActionButton(
                  key: VerilyTestKeys.settingsCloseAccount,
                  label: l10n.settingsCloseAccount,
                  tone: VerilyActionTone.destructive,
                  isLoading: isClosing.value,
                  semanticHint: isClosing.value
                      ? l10n.settingsClosingAccount
                      : null,
                  leading: const SkribbleIcon(data: VerilyIcons.delete),
                  onPressed: () => unawaited(closeAccount()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Says plainly what closing does, and only lets it through once the
/// confirmation word is typed exactly.
class _CloseAccountDialog extends HookWidget {
  const _CloseAccountDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = useTextEditingController();
    final typed = useValueListenable(controller).text.trim();

    return AlertDialog(
      title: Text(l10n.settingsCloseAccountDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.settingsCloseAccountDialogBody),
            const SizedBox(height: 16),
            TextField(
              key: VerilyTestKeys.settingsCloseAccountConfirmation,
              controller: controller,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: l10n.settingsCloseAccountConfirmationLabel,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.dialogCancel),
        ),
        FilledButton(
          key: VerilyTestKeys.settingsCloseAccountConfirm,
          onPressed: typed == closeAccountConfirmationWord
              ? () => Navigator.of(context).pop(true)
              : null,
          child: Text(l10n.settingsCloseAccountConfirm),
        ),
      ],
    );
  }
}
