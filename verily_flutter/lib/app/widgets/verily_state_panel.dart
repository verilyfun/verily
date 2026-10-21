import 'package:flutter/material.dart';
import 'package:skribble/skribble.dart' show WiredLoadingIndicator;

import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/app/widgets/verily_copyable_error_text.dart';
import 'package:verily_flutter/app/widgets/verily_sketch_postcard.dart';

/// A next step offered by a [VerilyStatePanel].
@immutable
class VerilyStateAction {
  const VerilyStateAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

enum _VerilyStateKind { empty, problem }

/// What a screen shows in place of content: nothing yet, or a request that
/// did not work.
///
/// Both are a paper panel with a plain title, what is known, and the next
/// action. An empty state leads with a postcard because it is an invitation.
/// A problem stays on quiet paper because it concerns the person's work, and
/// its message stays copyable so it can be reported.
class VerilyStatePanel extends StatelessWidget {
  const VerilyStatePanel.empty({
    required this.title,
    this.message,
    this.action,
    this.secondaryAction,
    this.footer,
    this.tone = VerilyTone.neutral,
    super.key,
  }) : _kind = _VerilyStateKind.empty;

  const VerilyStatePanel.problem({
    required this.title,
    this.message,
    this.action,
    this.secondaryAction,
    this.footer,
    super.key,
  }) : _kind = _VerilyStateKind.problem,
       tone = VerilyTone.neutral;

  final _VerilyStateKind _kind;
  final String title;
  final String? message;
  final VerilyStateAction? action;
  final VerilyStateAction? secondaryAction;

  /// Supporting content below the actions, such as a reassurance line.
  final Widget? footer;

  /// The wash of an empty state's postcard.
  final VerilyTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final isProblem = _kind == _VerilyStateKind.problem;
    final actions = [?action, ?secondaryAction];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: VerilyRoughDecoration(
        color: palette.surface,
        outline: palette.ink,
        seed: 67,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isProblem) ...[
            Semantics(
              header: true,
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(color: palette.ink),
              ),
            ),
            if (message case final text?) ...[
              const SizedBox(height: 8),
              VerilyCopyableErrorText(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.mutedInk,
                ),
              ),
            ],
          ] else
            VerilySketchPostcard(
              title: title,
              subtitle: message,
              tone: tone,
              minHeight: 140,
            ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                for (final (index, item) in actions.indexed)
                  VerilyActionButton(
                    label: item.label,
                    onPressed: item.onPressed,
                    expand: false,
                    tone: index == 0
                        ? VerilyActionTone.primary
                        : VerilyActionTone.secondary,
                  ),
              ],
            ),
          ],
          if (footer case final content?) ...[
            const SizedBox(height: 16),
            content,
          ],
        ],
      ),
    );
  }
}

/// A labelled wait in place of content.
///
/// A bare spinner tells a screen reader nothing, so the label is both shown
/// and announced.
class VerilyLoadingPanel extends StatelessWidget {
  const VerilyLoadingPanel({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    return Semantics(
      label: label,
      liveRegion: true,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WiredLoadingIndicator(
              size: 28,
              color: palette.ink,
              strokeWidth: 2.4,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.mutedInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
