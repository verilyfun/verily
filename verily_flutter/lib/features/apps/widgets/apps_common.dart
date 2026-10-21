import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon, WiredSvgIconData;

import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/l10n/l10n.dart';

/// The page gutter and the widest a reading column grows on large screens.
const appsPageGutter = 16.0;
const appsMaxContentWidth = 720.0;

/// Keys, codes, and request examples, set in the monospaced Skribble face so
/// every character lines up and reads unambiguously.
TextStyle? appsCodeStyle(BuildContext context, {TextStyle? base}) {
  final theme = Theme.of(context);
  return (base ?? theme.textTheme.bodySmall)?.copyWith(
    fontFamily: verilyNumeralFontFamily,
    color: theme.verily.ink,
    height: 1.5,
  );
}

/// A date and time in the person's locale, such as `Oct 21, 2026 2:30 PM`.
String appsDateTime(AppLocalizations l10n, DateTime value) =>
    DateFormat.yMMMd(l10n.localeName).add_jm().format(value.toLocal());

/// A paper card with the full ink pen, as DESIGN.md draws cards.
class AppsPanel extends StatelessWidget {
  const AppsPanel({
    required this.child,
    this.color,
    this.seed = 241,
    super.key,
  });

  final Widget child;
  final Color? color;

  /// Fixes the pen wobble so neighbouring panels draw different outlines.
  final int seed;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).verily;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: VerilyRoughDecoration(
        color: color ?? palette.surface,
        outline: palette.ink,
        seed: seed,
      ),
      child: child,
    );
  }
}

/// A level-two heading inside a page.
class AppsSectionHeading extends StatelessWidget {
  const AppsSectionHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      headingLevel: 2,
      child: Text(
        text,
        style: theme.textTheme.titleLarge?.copyWith(color: theme.verily.ink),
      ),
    );
  }
}

/// A short status word on the quiet highlight wash. Status is always a word,
/// never colour alone.
class AppsStatusPill extends StatelessWidget {
  const AppsStatusPill({
    required this.label,
    this.icon,
    this.muted = false,
    super.key,
  });

  final String label;
  final WiredSvgIconData? icon;

  /// A finished or revoked state sits on plain paper instead of the wash.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    return DecoratedBox(
      decoration: VerilyRoughDecoration(
        color: muted ? palette.surface : palette.highlight,
        outline: palette.quietPen,
        radius: VerilyRadius.chip,
        strokeWidth: 1.6,
        seed: label.hashCode & 0x7fffffff,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon case final data?) ...[
              SkribbleIcon(data: data, size: 16, color: palette.ink),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(color: palette.ink),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks before a step that cannot be undone. Returns true when confirmed.
Future<bool> confirmAppsDestructiveStep(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  Key? confirmKey,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      semanticLabel: title,
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.l10n.dialogCancel),
        ),
        VerilyActionButton(
          key: confirmKey,
          label: confirmLabel,
          tone: VerilyActionTone.destructive,
          expand: false,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Plain words for a confirmation receipt's reason code, so the log never
/// leads with a raw code.
String appsConfirmationReason(AppLocalizations l10n, String reasonCode) =>
    switch (reasonCode) {
      'app_confirmed' => l10n.appsReasonConfirmed,
      'attempt_already_complete' => l10n.appsReasonAlreadyComplete,
      'unknown_action' => l10n.appsReasonUnknownAction,
      'unknown_subject' => l10n.appsReasonUnknownSubject,
      'occurred_at_out_of_range' => l10n.appsReasonOutOfRange,
      'occurred_outside_window' => l10n.appsReasonOutsideWindow,
      'occurred_outside_period' => l10n.appsReasonOutsidePeriod,
      'action_unavailable' => l10n.appsReasonUnavailable,
      _ => l10n.appsReasonOther,
    };
