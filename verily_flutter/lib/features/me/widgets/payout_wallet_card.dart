import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/core/user_message.dart';
import 'package:verily_flutter/features/me/me_providers.dart';
import 'package:verily_flutter/features/me/wallet_failure_message.dart';
import 'package:verily_flutter/features/rewards/reward_funding_service.dart';
import 'package:verily_flutter/features/wallet/mobile_wallet.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// Where the person's rewards are sent, and the way to set or change it.
///
/// Linking proves ownership with a signature from the wallet itself, in one
/// wallet session. Payouts waiting for a wallet are sent once it is linked.
class PayoutWalletCard extends HookConsumerWidget {
  const PayoutWalletCard({required this.wallet, super.key});

  /// The linked wallet, or null when there is none yet.
  final PayoutWalletView? wallet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    final linkService = ref.watch(payoutWalletLinkServiceProvider);
    final isLinking = useState(false);
    final linked = wallet;

    void say(String message) => ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));

    Future<void> link() async {
      if (isLinking.value) return;
      isLinking.value = true;
      try {
        await linkService.linkWithMobileWallet();
        ref
          ..invalidate(myPayoutWalletProvider)
          ..invalidate(myPayoutsProvider);
        if (context.mounted) say(l10n.meWalletLinked);
      } on WalletException catch (error) {
        debugPrint('Payout wallet link failed: $error');
        if (context.mounted) say(walletFailureMessage(l10n, error.failure));
      } on Object catch (error) {
        debugPrint('Payout wallet link failed: $error');
        if (context.mounted) say(userMessageFor(l10n, error));
      } finally {
        if (context.mounted) isLinking.value = false;
      }
    }

    Future<void> copy(String address) async {
      await Clipboard.setData(ClipboardData(text: address));
      if (context.mounted) say(l10n.meWalletCopied);
    }

    final Widget action;
    if (!linkService.canLinkOnThisDevice) {
      action = Text(
        l10n.meWalletUnsupported,
        style: theme.textTheme.bodySmall?.copyWith(color: palette.mutedInk),
      );
    } else {
      action = VerilyActionButton(
        key: VerilyTestKeys.meWalletLink,
        label: linked == null ? l10n.meWalletLink : l10n.meWalletChange,
        tone: linked == null
            ? VerilyActionTone.primary
            : VerilyActionTone.secondary,
        isLoading: isLinking.value,
        semanticHint: isLinking.value ? l10n.meWalletLinking : null,
        leading: const SkribbleIcon(data: VerilyIcons.wallet),
        onPressed: () => unawaited(link()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: VerilyRoughDecoration(
        color: linked == null ? palette.rewardWash : palette.surface,
        outline: palette.ink,
        seed: 271,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SkribbleIcon(
                data: VerilyIcons.wallet,
                size: 22,
                color: palette.reward,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    linked == null
                        ? l10n.meWalletUnlinkedTitle
                        : l10n.meWalletTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: palette.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            linked == null
                ? l10n.meWalletUnlinkedBody
                : l10n.meWalletLinkedBody,
            style: theme.textTheme.bodySmall?.copyWith(color: palette.ink),
          ),
          if (linked != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  // Read in full as its own stop; shown short.
                  child: Semantics(
                    container: true,
                    label: l10n.meWalletAddressLabel(linked.walletAddress),
                    excludeSemantics: true,
                    child: Text(
                      shortWalletAddress(linked.walletAddress),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: palette.ink,
                        fontFamily: verilyNumeralFontFamily,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  key: VerilyTestKeys.meWalletCopy,
                  tooltip: l10n.meWalletCopy,
                  onPressed: () => unawaited(copy(linked.walletAddress)),
                  icon: const SkribbleIcon(data: VerilyIcons.copy),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          action,
        ],
      ),
    );
  }
}
