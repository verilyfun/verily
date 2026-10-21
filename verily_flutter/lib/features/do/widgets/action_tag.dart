import 'package:flutter/material.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon, WiredSvgIconData;

import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';

/// A short label with an icon on a quiet wash, ringed by a light pen.
///
/// Tags sit inside an outlined card, so their line is thinner than the
/// card's to keep the nested outlines from competing.
class ActionTag extends StatelessWidget {
  const ActionTag({
    required this.label,
    required this.icon,
    required this.seed,
    this.tone = VerilyTone.neutral,
    super.key,
  });

  final String label;
  final WiredSvgIconData icon;
  final int seed;

  /// The wash behind the tag; its hue inks the icon.
  final VerilyTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: VerilyRoughDecoration(
        color: palette.wash(tone),
        outline: palette.quietPen,
        radius: VerilyRadius.chip,
        strokeWidth: 1.4,
        seed: seed,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SkribbleIcon(data: icon, size: 15, color: palette.hue(tone)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(color: palette.ink),
            ),
          ),
        ],
      ),
    );
  }
}
