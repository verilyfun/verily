import 'package:flutter/material.dart';
import 'package:skribble/skribble.dart'
    show SkribbleIcon, WiredSvgIconData, WiredSwitch;

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/l10n/l10n.dart';

/// Space between related items, and between groups (DESIGN.md).
const editorStackGap = 12.0;
const editorSectionGap = 24.0;

/// A titled part of the editor page: a level-two heading, an optional line
/// of help, and its fields.
class EditorSection extends StatelessWidget {
  const EditorSection({
    required this.title,
    required this.children,
    this.help,
    this.trailing,
    super.key,
  });

  final String title;
  final String? help;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                headingLevel: 2,
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: palette.ink,
                  ),
                ),
              ),
            ),
            ?trailing,
          ],
        ),
        if (help case final line?) ...[
          const SizedBox(height: 4),
          Text(
            line,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.mutedInk,
            ),
          ),
        ],
        const SizedBox(height: editorStackGap),
        ...children,
      ],
    );
  }
}

/// A rough-outlined card on the page's paper, or on a wash.
class EditorPanel extends StatelessWidget {
  const EditorPanel({
    required this.child,
    required this.seed,
    this.fill,
    this.outline,
    this.padding = const EdgeInsets.all(12),
    super.key,
  });

  final Widget child;

  /// Keeps the pen wobble identical on every rebuild.
  final int seed;
  final Color? fill;
  final Color? outline;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).verily;
    return DecoratedBox(
      decoration: VerilyRoughDecoration(
        color: fill ?? palette.surface,
        outline: outline ?? palette.firmPen,
        seed: seed,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// A short explanation on a wash with a drawing beside it: the wash and the
/// icon set it apart, the words carry the meaning.
class EditorNote extends StatelessWidget {
  const EditorNote({
    required this.text,
    this.icon = VerilyIcons.info,
    this.tone = VerilyTone.neutral,
    super.key,
  });

  final String text;
  final WiredSvgIconData icon;
  final VerilyTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    return EditorPanel(
      seed: text.length + 401,
      fill: palette.wash(tone),
      outline: palette.hue(tone),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkribbleIcon(data: icon, size: 20, color: palette.hue(tone)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(color: palette.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// A labelled Skribble switch whose whole row is the 48-unit target.
class EditorSwitchRow extends StatelessWidget {
  const EditorSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.help,
    super.key,
  });

  final String label;
  final String? help;
  final bool value;

  /// Null disables the switch.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final enabled = onChanged != null;
    return MergeSemantics(
      child: InkWell(
        onTap: enabled ? () => onChanged!(!value) : null,
        borderRadius: BorderRadius.circular(VerilyRadius.control),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: enabled ? palette.ink : palette.mutedInk,
                        ),
                      ),
                      if (help case final line?) ...[
                        const SizedBox(height: 2),
                        Text(
                          line,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: palette.mutedInk,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                WiredSwitch(
                  value: value,
                  onChanged: onChanged,
                  semanticLabel: label,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One choice out of a few, as a row of chips that wraps on narrow screens.
/// The selected chip carries a check as well as a wash.
class EditorChoices<T> extends StatelessWidget {
  const EditorChoices({
    required this.label,
    required this.values,
    required this.selected,
    required this.nameOf,
    required this.onSelected,
    this.keyOf,
    super.key,
  });

  final String label;
  final List<T> values;

  /// Null when nothing is chosen yet.
  final T? selected;
  final String Function(T value) nameOf;
  final ValueChanged<T> onSelected;
  final Key Function(T value)? keyOf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.verily.ink,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in values)
              ChoiceChip(
                key: keyOf?.call(value),
                label: Text(nameOf(value)),
                selected: value == selected,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onSelected: (_) => onSelected(value),
              ),
          ],
        ),
      ],
    );
  }
}

/// A date the creator may set or clear, such as when an action opens.
class EditorDateRow extends StatelessWidget {
  const EditorDateRow({
    required this.label,
    required this.value,
    required this.onPick,
    this.onClear,
    this.errorText,
    super.key,
  });

  final String label;
  final DateTime? value;
  final VoidCallback? onPick;

  /// Null when the date cannot be cleared.
  final VoidCallback? onClear;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    final material = MaterialLocalizations.of(context);
    final shown = switch (value) {
      final date? => material.formatMediumDate(date),
      null => l10n.editorDateAnyTime,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                button: onPick != null,
                onTap: onPick,
                excludeSemantics: true,
                label: label,
                value: shown,
                child: InkWell(
                  onTap: onPick,
                  borderRadius: BorderRadius.circular(VerilyRadius.control),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Row(
                      children: [
                        SkribbleIcon(
                          data: VerilyIcons.calendar,
                          size: 20,
                          color: palette.ink,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                label,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: palette.mutedInk,
                                ),
                              ),
                              Text(
                                shown,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: palette.ink,
                                ),
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
            if (value != null && onClear != null)
              IconButton(
                tooltip: l10n.editorDateClear(label),
                onPressed: onClear,
                icon: const SkribbleIcon(data: VerilyIcons.close, size: 20),
              ),
          ],
        ),
        if (errorText case final message?)
          Padding(
            padding: const EdgeInsets.only(left: 30, top: 2),
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: palette.ink),
            ),
          ),
      ],
    );
  }
}
