import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/app/widgets/verily_state_panel.dart';
import 'package:verily_flutter/core/token_amount.dart';
import 'package:verily_flutter/core/user_message.dart';
import 'package:verily_flutter/features/actions/action_labels.dart';
import 'package:verily_flutter/features/create/editor/widgets/editor_common.dart';
import 'package:verily_flutter/features/rewards/reward_funding_service.dart';
import 'package:verily_flutter/features/rewards/reward_repository.dart';
import 'package:verily_flutter/features/wallet/mobile_wallet.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// Whether this build may confirm the server's labelled local-development
/// escrow. Only debug builds can; a release build says rewards are not
/// available instead of pretending money moved.
final fundingDevelopmentEscrowAllowedProvider = Provider<bool>(
  (ref) => kDebugMode,
);

/// Walks the creator through locking [action]'s reward in escrow: link a
/// payout wallet if needed, sign the escrow transaction in their wallet, and
/// wait for the server to verify it from chain state. Returns the pool the
/// server reports afterwards, or null when the creator backed out.
Future<RewardPoolView?> showRewardFunding(
  BuildContext context, {
  required ActionOpportunity action,
}) async {
  // The latest pool the server reported, kept even when the sheet is swiped
  // away rather than closed with its button.
  final latest = ValueNotifier<RewardPoolView?>(null);
  try {
    final result = await showModalBottomSheet<RewardPoolView>(
      context: context,
      // Over the tab bar too: the sheet is the whole task until it closes.
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _RewardFundingSheet(action: action, latest: latest),
    );
    return result ?? latest.value;
  } finally {
    latest.dispose();
  }
}

enum _Stage {
  loadingWallet,
  needsWallet,
  preparing,
  ready,
  unavailable,
  funded,
  failed,
}

class _RewardFundingSheet extends HookConsumerWidget {
  const _RewardFundingSheet({required this.action, required this.latest});

  final ActionOpportunity action;
  final ValueNotifier<RewardPoolView?> latest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final funding = ref.watch(rewardFundingServiceProvider);
    final linking = ref.watch(payoutWalletLinkServiceProvider);
    final developmentAllowed = ref.watch(
      fundingDevelopmentEscrowAllowedProvider,
    );

    final stage = useState(_Stage.loadingWallet);
    final wallet = useState<PayoutWalletView?>(null);
    final step = useState<RewardFundingStep?>(null);
    final pool = useState<RewardPoolView?>(null);
    final busy = useState(false);
    final problem = useState<String?>(null);
    // The wallet already sent this escrow; only ask the server to look again.
    final sentSignature = useState<String?>(null);
    final retry = useRef<Future<void> Function()?>(null);

    String messageFor(Object error) => switch (error) {
      EscrowNotYetVisibleException() => l10n.fundingSentNotVisible,
      WalletException(:final failure) => walletFailureMessage(l10n, failure),
      RewardException(problem: RewardProblem.rewardsUnavailable) =>
        l10n.fundingUnavailable,
      _ => userMessageFor(l10n, error),
    };

    void fail(Object error, Future<void> Function() again, String what) {
      if (error is! WalletException && error is! RewardException) {
        debugPrint('$what failed: $error');
      }
      problem.value = messageFor(error);
      retry.value = again;
      stage.value = _Stage.failed;
    }

    Future<void> prepare() async {
      stage.value = _Stage.preparing;
      problem.value = null;
      try {
        final prepared = await funding.prepare(action.id);
        if (!context.mounted) return;
        step.value = prepared;
        stage.value = _Stage.ready;
      } on RewardException catch (error) {
        if (!context.mounted) return;
        if (error.problem == RewardProblem.rewardsUnavailable) {
          stage.value = _Stage.unavailable;
        } else {
          fail(error, prepare, 'Preparing reward funding');
        }
      } on Object catch (error) {
        if (context.mounted) fail(error, prepare, 'Preparing reward funding');
      }
    }

    Future<void> loadWallet() async {
      stage.value = _Stage.loadingWallet;
      problem.value = null;
      try {
        final mine = await ref.read(payoutWalletRepositoryProvider).getMine();
        if (!context.mounted) return;
        wallet.value = mine;
        if (mine == null) {
          stage.value = _Stage.needsWallet;
        } else {
          await prepare();
        }
      } on Object catch (error) {
        if (context.mounted) fail(error, loadWallet, 'Loading the wallet');
      }
    }

    useEffect(() {
      unawaited(loadWallet());
      return null;
    }, const []);

    void record(RewardPoolView result) {
      pool.value = result;
      latest.value = result;
      if (result.status == RewardPoolStatus.funded) {
        stage.value = _Stage.funded;
      } else {
        problem.value = l10n.fundingNotYet;
      }
    }

    Future<void> act(
      Future<RewardPoolView> Function() task,
      String what,
    ) async {
      busy.value = true;
      problem.value = null;
      try {
        final result = await task();
        if (context.mounted) record(result);
      } on Object catch (error) {
        if (error is EscrowNotYetVisibleException && context.mounted) {
          sentSignature.value = error.signature;
        }
        if (error is! WalletException &&
            error is! RewardException &&
            error is! EscrowNotYetVisibleException) {
          debugPrint('$what failed: $error');
        }
        if (context.mounted) problem.value = messageFor(error);
      } finally {
        if (context.mounted) busy.value = false;
      }
    }

    Future<void> link() async {
      busy.value = true;
      problem.value = null;
      try {
        final linked = await linking.linkWithMobileWallet();
        if (!context.mounted) return;
        wallet.value = linked;
        busy.value = false;
        await prepare();
      } on Object catch (error) {
        if (error is! WalletException) {
          debugPrint('Linking a payout wallet failed: $error');
        }
        if (context.mounted) problem.value = messageFor(error);
      } finally {
        if (context.mounted) busy.value = false;
      }
    }

    final reward = action.reward;
    final plan = step.value?.plan;
    final total = switch ((plan, reward)) {
      (final plan?, _) => TokenAmount(
        atoms: plan.totalAtoms,
        decimals: plan.decimals,
        symbol: plan.tokenSymbol,
      ),
      (null, final reward?) => payoutAmountOf(reward) * reward.maxPayouts,
      (null, null) => null,
    };

    return SingleChildScrollView(
      key: VerilyTestKeys.fundingSheet,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  headingLevel: 2,
                  child: Text(
                    l10n.fundingTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: palette.ink,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.dialogClose,
                onPressed: () => Navigator.of(context).pop(pool.value),
                icon: const SkribbleIcon(data: VerilyIcons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.fundingIntro,
            style: theme.textTheme.bodyMedium?.copyWith(color: palette.ink),
          ),
          const SizedBox(height: 16),
          _EscrowSummary(reward: reward, plan: plan, total: total),
          const SizedBox(height: 16),
          ..._stageContent(
            context,
            stage: stage.value,
            wallet: wallet.value,
            step: step.value,
            busy: busy.value,
            problem: problem.value,
            total: total,
            canLink: linking.canLinkOnThisDevice,
            canSign: funding.canSignOnThisDevice,
            developmentAllowed: developmentAllowed,
            onLink: link,
            alreadySent: sentSignature.value != null,
            onApprove: (walletStep) => act(() async {
              // Sign once. Every later tap only asks the server to look again
              // for the escrow this signature opened.
              final signature =
                  sentSignature.value ??
                  await funding.sendFundingTransaction(walletStep);
              if (context.mounted) sentSignature.value = signature;
              return funding.confirmSentFunding(action.id, signature);
            }, 'Funding with the wallet'),
            onConfirmDevelopment: (developmentStep) => act(
              () => funding.confirmLocalDevelopment(action.id, developmentStep),
              'Confirming the development escrow',
            ),
            onRetry: () => retry.value?.call(),
            onDone: () => Navigator.of(context).pop(pool.value),
          ),
          if (stage.value != _Stage.failed && problem.value != null) ...[
            const SizedBox(height: 12),
            Text(
              problem.value!,
              key: VerilyTestKeys.fundingProblem,
              style: theme.textTheme.bodyMedium?.copyWith(color: palette.ink),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _stageContent(
    BuildContext context, {
    required _Stage stage,
    required PayoutWalletView? wallet,
    required RewardFundingStep? step,
    required bool busy,
    required String? problem,
    required TokenAmount? total,
    required bool canLink,
    required bool canSign,
    required bool developmentAllowed,
    required VoidCallback onLink,
    required bool alreadySent,
    required ValueChanged<WalletFundingStep> onApprove,
    required ValueChanged<LocalDevelopmentFundingStep> onConfirmDevelopment,
    required VoidCallback onRetry,
    required VoidCallback onDone,
  }) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;

    final linkedWallet = [
      if (wallet != null) ...[
        Row(
          children: [
            SkribbleIcon(
              data: VerilyIcons.wallet,
              size: 20,
              color: palette.ink,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.fundingWalletLinked(
                  shortWalletAddress(wallet.walletAddress),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(color: palette.ink),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    ];

    return switch (stage) {
      _Stage.loadingWallet => [VerilyLoadingPanel(label: l10n.fundingLoading)],
      _Stage.needsWallet => [
        Semantics(
          headingLevel: 3,
          child: Text(
            l10n.fundingWalletHeading,
            style: theme.textTheme.titleMedium?.copyWith(color: palette.ink),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.fundingWalletNeeded,
          style: theme.textTheme.bodyMedium?.copyWith(color: palette.ink),
        ),
        const SizedBox(height: 12),
        if (canLink)
          VerilyActionButton(
            key: VerilyTestKeys.fundingLinkWallet,
            label: l10n.fundingLinkWallet,
            isLoading: busy,
            leading: const SkribbleIcon(data: VerilyIcons.wallet),
            onPressed: onLink,
          )
        else
          EditorNote(text: l10n.fundingNeedsAndroid, icon: VerilyIcons.wallet),
      ],
      _Stage.preparing => [
        ...linkedWallet,
        VerilyLoadingPanel(label: l10n.fundingPreparing),
      ],
      _Stage.ready => [
        ...linkedWallet,
        ...switch (step) {
          WalletFundingStep() when !canSign => [
            EditorNote(
              text: l10n.fundingNeedsAndroid,
              icon: VerilyIcons.wallet,
            ),
          ],
          final WalletFundingStep walletStep => [
            VerilyActionButton(
              key: VerilyTestKeys.fundingApprove,
              label: busy
                  ? l10n.fundingConfirming
                  : alreadySent
                  ? l10n.fundingCheckAgain
                  : l10n.fundingApprove,
              isLoading: busy,
              leading: const SkribbleIcon(data: VerilyIcons.escrow),
              onPressed: () => onApprove(walletStep),
            ),
          ],
          final LocalDevelopmentFundingStep developmentStep
              when developmentAllowed =>
            [
              _DevelopmentEscrow(
                busy: busy,
                onConfirm: () => onConfirmDevelopment(developmentStep),
              ),
            ],
          LocalDevelopmentFundingStep() || null => [
            EditorNote(text: l10n.fundingUnavailable),
          ],
        },
      ],
      _Stage.unavailable => [
        EditorNote(
          key: VerilyTestKeys.fundingUnavailable,
          text: l10n.fundingUnavailable,
        ),
      ],
      _Stage.funded => [
        EditorPanel(
          key: VerilyTestKeys.fundingFunded,
          seed: 431,
          fill: palette.rewardWash,
          outline: palette.reward,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkribbleIcon(
                data: VerilyIcons.lock,
                size: 24,
                color: palette.reward,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.fundingFunded,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: palette.ink,
                      ),
                    ),
                    if (total != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.fundingFundedBody(total.format(l10n.localeName)),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: palette.ink,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        VerilyActionButton(
          key: VerilyTestKeys.fundingDone,
          label: l10n.dialogDone,
          onPressed: onDone,
        ),
      ],
      _Stage.failed => [
        ...linkedWallet,
        VerilyStatePanel.problem(
          key: VerilyTestKeys.fundingFailed,
          title: problem ?? l10n.errorGeneric,
          action: VerilyStateAction(
            label: l10n.dialogRetry,
            onPressed: onRetry,
          ),
        ),
      ],
    };
  }
}

/// Plain words for a wallet request that did not finish.
String walletFailureMessage(AppLocalizations l10n, WalletFailure failure) =>
    switch (failure) {
      WalletFailure.unavailable => l10n.fundingWalletUnavailable,
      WalletFailure.cancelled => l10n.fundingWalletCancelled,
      WalletFailure.timedOut => l10n.fundingWalletTimedOut,
      WalletFailure.wrongAccount => l10n.fundingWalletWrongAccount,
      WalletFailure.invalidResponse => l10n.fundingWalletInvalid,
      WalletFailure.failed => l10n.fundingWalletFailed,
    };

/// `7xKX…sAsU`: enough of a wallet address to recognise it.
String shortWalletAddress(String address) => address.length <= 10
    ? address
    : '${address.substring(0, 4)}…${address.substring(address.length - 4)}';

/// The escrow at a glance: what one completion pays, how many payouts, the
/// whole amount locked, and when unused funds can come back.
class _EscrowSummary extends StatelessWidget {
  const _EscrowSummary({
    required this.reward,
    required this.plan,
    required this.total,
  });

  final RewardSummary? reward;
  final RewardFundingPlan? plan;
  final TokenAmount? total;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final material = MaterialLocalizations.of(context);
    final reward = this.reward;
    final plan = this.plan;
    final total = this.total;
    final ends = plan?.expiresAt ?? reward?.expiresAt;

    Widget row(String label, String value, {bool emphasised = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style:
                      (emphasised
                              ? theme.textTheme.titleMedium
                              : theme.textTheme.titleSmall)
                          ?.copyWith(
                            color: palette.ink,
                            fontFamily: verilyNumeralFontFamily,
                          ),
                ),
              ),
            ],
          ),
        );

    return EditorPanel(
      seed: 433,
      fill: palette.rewardWash,
      outline: palette.reward,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (reward != null) ...[
            row(
              l10n.fundingPerCompletion,
              payoutAmountOf(reward).format(l10n.localeName),
            ),
            row(l10n.fundingPayouts, '${reward.maxPayouts}'),
          ],
          if (total != null)
            row(
              l10n.fundingTotal,
              total.format(l10n.localeName),
              emphasised: true,
            ),
          if (ends != null)
            row(l10n.fundingEnds, material.formatMediumDate(ends.toLocal())),
          if (plan != null)
            row(
              l10n.fundingRefundFrom,
              material.formatMediumDate(plan.refundAfter.toLocal()),
            ),
        ],
      ),
    );
  }
}

/// The server's local-development escrow, clearly labelled as a developer
/// tool. Confirming it records a development signature; no money moves.
class _DevelopmentEscrow extends StatelessWidget {
  const _DevelopmentEscrow({required this.busy, required this.onConfirm});

  final bool busy;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    return EditorPanel(
      key: VerilyTestKeys.fundingDevelopment,
      seed: 439,
      fill: palette.highlight,
      outline: palette.ink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SkribbleIcon(
                data: VerilyIcons.developer,
                size: 20,
                color: palette.ink,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.fundingDevHeading,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: palette.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.fundingDevBody,
            style: theme.textTheme.bodySmall?.copyWith(color: palette.ink),
          ),
          const SizedBox(height: 12),
          VerilyActionButton(
            key: VerilyTestKeys.fundingDevConfirm,
            label: l10n.fundingDevConfirm,
            tone: VerilyActionTone.secondary,
            isLoading: busy,
            onPressed: onConfirm,
          ),
        ],
      ),
    );
  }
}
