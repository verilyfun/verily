import 'package:flutter/material.dart';
import 'package:skribble/skribble.dart'
    show SkribbleIcon, WiredLoadingIndicator;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/features/do/proof_kind.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// Where one requirement's proof stands.
enum ProofState {
  /// Nothing sent yet.
  open,

  /// Being captured or sent right now.
  working,

  /// Sent and being checked by Verily.
  checking,

  /// A person is looking at it.
  withReviewer,

  /// Accepted.
  accepted,
}

/// One row per plain outcome (DESIGN.md's proof checklist): a Skribble box
/// that takes the brand check, drawn in vermilion, once the proof is
/// accepted; a violet review chip when a person decides; a quiet wait while
/// Verily checks.
class ProofRow extends StatelessWidget {
  const ProofRow({
    required this.requirement,
    required this.state,
    this.onTap,
    super.key,
  });

  final ActionRequirementView requirement;
  final ProofState state;

  /// Starts this proof. Null when it cannot be started now.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    final kind = ProofKind.of(requirement);
    final reps = requirement.targetRepetitions;

    return Semantics(
      button: onTap != null,
      label: requirement.title,
      value: _stateLabel(l10n),
      excludeSemantics: true,
      onTap: onTap,
      child: DecoratedBox(
        key: VerilyTestKeys.actionProof(requirement.requirementKey),
        decoration: VerilyRoughDecoration(
          color: palette.surface,
          outline: state == ProofState.accepted
              ? palette.firmPen
              : palette.quietPen,
          strokeWidth: 2,
          seed: 37 + requirement.position,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(VerilyRadius.card),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _Tick(accepted: state == ProofState.accepted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SkribbleIcon(
                                data: kind.icon,
                                size: 15,
                                color: palette.mutedInk,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  kind.label(l10n),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: palette.mutedInk,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            requirement.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: palette.ink,
                            ),
                          ),
                          if (requirement.instructions.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              requirement.instructions,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: palette.mutedInk,
                              ),
                            ),
                          ],
                          if (reps != null && reps > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              l10n.actionProofReps(reps),
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: palette.ink,
                              ),
                            ),
                          ],
                          if (!requirement.isRequired) ...[
                            const SizedBox(height: 4),
                            Text(
                              l10n.actionProofOptional,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: palette.mutedInk,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _Trailing(state: state, tappable: onTap != null),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _stateLabel(AppLocalizations l10n) => switch (state) {
    ProofState.open => l10n.actionProofStateOpen,
    ProofState.working => l10n.actionProofStateWorking,
    ProofState.checking => l10n.attemptStatusVerifying,
    ProofState.withReviewer => l10n.attemptStatusPendingReview,
    ProofState.accepted => l10n.actionProofStateAccepted,
  };
}

/// The checklist box; the brand check is drawn in vermilion only once the
/// proof is accepted.
class _Tick extends StatelessWidget {
  const _Tick({required this.accepted});

  final bool accepted;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).verily;
    return SizedBox.square(
      dimension: 32,
      child: DecoratedBox(
        decoration: VerilyRoughDecoration(
          outline: palette.ink,
          radius: VerilyRadius.control,
          strokeWidth: 2,
          seed: 251,
        ),
        child: accepted
            ? Center(
                child: SkribbleIcon(
                  key: VerilyTestKeys.actionProofAcceptedTick,
                  data: VerilyIcons.check,
                  size: 22,
                  weight: 600,
                  color: palette.accent,
                ),
              )
            : null,
      ),
    );
  }
}

class _Trailing extends StatelessWidget {
  const _Trailing({required this.state, required this.tappable});

  final ProofState state;
  final bool tappable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    return switch (state) {
      ProofState.working => WiredLoadingIndicator(size: 20, color: palette.ink),
      ProofState.checking => SkribbleIcon(
        data: VerilyIcons.hourglass,
        size: 20,
        color: palette.mutedInk,
      ),
      ProofState.withReviewer => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: VerilyRoughDecoration(
          color: palette.reviewWash,
          outline: palette.review,
          radius: VerilyRadius.chip,
          strokeWidth: 1.4,
          seed: 257,
        ),
        child: Text(
          l10n.attemptStatusPendingReview,
          style: theme.textTheme.labelMedium?.copyWith(color: palette.ink),
        ),
      ),
      ProofState.open when tappable => SkribbleIcon(
        data: VerilyIcons.chevronRight,
        size: 20,
        color: palette.mutedInk,
      ),
      ProofState.open || ProofState.accepted => const SizedBox.shrink(),
    };
  }
}
