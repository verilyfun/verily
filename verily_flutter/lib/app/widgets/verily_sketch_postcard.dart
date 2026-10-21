import 'package:flutter/material.dart';

import 'package:verily_flutter/app/theme/verily_pen.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_rough_surface.dart';

/// A washed field with a job.
///
/// Postcards carry one short statement, one supporting line, a hand-drawn
/// hatch, and the stable pen outline every card shares. They are for
/// invitations and introductions such as an empty state; forms, amounts, and
/// evidence never use them.
class VerilySketchPostcard extends StatelessWidget {
  const VerilySketchPostcard({
    required this.title,
    this.subtitle,
    this.tone = VerilyTone.neutral,
    this.trailing,
    this.padding = const EdgeInsets.all(24),
    this.minHeight = 224,
    super.key,
  });

  final String title;
  final String? subtitle;

  /// Which wash the card is printed on. Text is always the page ink, which
  /// every wash carries in both modes.
  final VerilyTone tone;

  /// Optional content below the statement, such as an action button.
  final Widget? trailing;

  final EdgeInsetsGeometry padding;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;

    return VerilyRoughSurface(
      fill: palette.wash(tone),
      outline: palette.ink,
      // The postcard is a fixed fixture, so its outline is always the same.
      seed: 5,
      minHeight: minHeight,
      padding: padding,
      // A narrow postcard, such as one in a side panel, draws a smaller hatch
      // and title so its supporting line keeps a readable measure.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 320;
          final hatch = compact ? 56.0 : 96.0;
          return Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: SizedBox.square(
                      dimension: hatch,
                      child: CustomPaint(
                        painter: _PostcardHatchPainter(
                          color: palette.hue(tone).withValues(alpha: 0.42),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // A container keeps the web semantics text merger from
                  // folding the statement into its supporting line, so both
                  // stay readable as separate text.
                  Semantics(
                    container: true,
                    header: true,
                    child: Text(
                      title,
                      style:
                          (compact
                                  ? theme.textTheme.headlineSmall
                                  : theme.textTheme.headlineMedium)
                              ?.copyWith(color: palette.ink),
                    ),
                  ),
                  if (subtitle case final line?) ...[
                    const SizedBox(height: 8),
                    // The hatch sits in the bottom-right corner, so the
                    // supporting line wraps before it rather than over it.
                    Padding(
                      padding: EdgeInsets.only(right: hatch),
                      child: Text(
                        line,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.ink,
                        ),
                      ),
                    ),
                  ],
                  if (trailing case final action?) ...[
                    const SizedBox(height: 16),
                    action,
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A hatched oval inked by the shared pen. Drawn once per postcard so the
/// flourish keeps its proportions instead of scaling with text.
class _PostcardHatchPainter extends CustomPainter {
  const _PostcardHatchPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) =>
      VerilyPen.hatchedOval(canvas, size, color: color);

  @override
  bool shouldRepaint(covariant _PostcardHatchPainter oldDelegate) =>
      oldDelegate.color != color;
}
