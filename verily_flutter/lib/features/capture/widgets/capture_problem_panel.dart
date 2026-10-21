import 'package:flutter/material.dart';

import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/app/widgets/verily_state_panel.dart';

/// A next step offered by a [CaptureProblemPanel].
@immutable
class CaptureProblemAction {
  const CaptureProblemAction({
    required this.label,
    required this.onPressed,
    this.key,
  });

  final String label;
  final VoidCallback onPressed;

  /// Lets tests and automation find the step.
  final Key? key;
}

/// A problem during capture, on quiet paper.
///
/// It says what happened and the next step; nothing technical reaches it.
/// By default it fills the screen and centres itself; [CaptureProblemPanel.inline]
/// sits inside a scrolling page.
class CaptureProblemPanel extends StatelessWidget {
  const CaptureProblemPanel({
    required this.title,
    required this.message,
    this.action,
    this.secondaryAction,
    super.key,
  }) : _inline = false;

  const CaptureProblemPanel.inline({
    required this.title,
    required this.message,
    this.action,
    this.secondaryAction,
    super.key,
  }) : _inline = true;

  final String title;
  final String message;
  final CaptureProblemAction? action;
  final CaptureProblemAction? secondaryAction;
  final bool _inline;

  @override
  Widget build(BuildContext context) {
    final actions = [?action, ?secondaryAction];
    final panel = VerilyStatePanel.problem(
      title: title,
      message: message,
      footer: actions.isEmpty
          ? null
          : Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                for (final (index, item) in actions.indexed)
                  VerilyActionButton(
                    key: item.key,
                    label: item.label,
                    onPressed: item.onPressed,
                    expand: false,
                    tone: index == 0
                        ? VerilyActionTone.primary
                        : VerilyActionTone.secondary,
                  ),
              ],
            ),
    );
    if (_inline) return panel;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: panel,
        ),
      ),
    );
  }
}
