import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:skribble/skribble.dart';

import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_fitted_text.dart';
import 'package:verily_flutter/l10n/l10n.dart';

/// The night-paper viewfinder, per DESIGN.md: the camera preview fills the
/// screen. There are no face boxes, grids, or scores; [ViewfinderBrackets]
/// marks the open frame between the controls.
class Viewfinder extends StatelessWidget {
  const Viewfinder({
    required this.preview,
    this.aspectRatio,
    this.overlay,
    super.key,
  });

  /// The live preview, or null while the camera opens.
  final Widget? preview;

  /// Upright preview width divided by height, when known.
  final double? aspectRatio;

  /// Drawn over the preview in the same coordinate space, such as a pose.
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final preview = this.preview;
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: VerilyColors.movementScrim),
        if (preview != null)
          ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: 1000 * (aspectRatio ?? 3 / 4),
                height: 1000,
                child: Stack(
                  fit: StackFit.expand,
                  children: [preview, ?overlay],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Four sketched corner brackets around the open part of the viewfinder,
/// between the controls at the top and bottom, so they never sit under a
/// label or the spoken word.
class ViewfinderBrackets extends StatelessWidget {
  const ViewfinderBrackets({super.key});

  @override
  Widget build(BuildContext context) => const IgnorePointer(
    child: Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: CustomPaint(painter: _BracketPainter(), size: Size.infinite),
    ),
  );
}

/// Four hand-drawn corners, inked in the HUD's paper colour.
class _BracketPainter extends CustomPainter {
  const _BracketPainter();

  static const _arm = 34.0;
  static const _capacity = 16;
  static final LinkedHashMap<Size, List<RoughDrawing>> _cache = LinkedHashMap();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final drawings = _cache.remove(size) ?? _prepare(size);
    _cache[size] = drawings;
    if (_cache.length > _capacity) _cache.remove(_cache.keys.first);
    for (final drawing in drawings) {
      drawing.paint(canvas);
    }
  }

  static List<RoughDrawing> _prepare(Size size) {
    final w = size.width;
    final h = size.height;
    // Each corner is two open strokes meeting at the corner point.
    final corners = [
      (0.0, 0.0, 1.0, 1.0),
      (w, 0.0, -1.0, 1.0),
      (w, h, -1.0, -1.0),
      (0.0, h, 1.0, -1.0),
    ];
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..color = VerilyColors.movementHudInk.withValues(alpha: 0.92);
    return [
      for (final (index, (x, y, dx, dy)) in corners.indexed) ...[
        RoughDrawing(
          Generator(
            DrawConfig.build(seed: 401 + index * 2),
            NoFiller(),
          ).line(x, y, x + dx * _arm, y),
          ink,
          ink,
        ),
        RoughDrawing(
          Generator(
            DrawConfig.build(seed: 402 + index * 2),
            NoFiller(),
          ).line(x, y, x, y + dy * _arm),
          ink,
          ink,
        ),
      ],
    ];
  }

  @override
  bool shouldRepaint(covariant _BracketPainter oldDelegate) => false;
}

/// Keeps light text readable over any camera background.
class ViewfinderScrims extends StatelessWidget {
  const ViewfinderScrims({super.key});

  @override
  Widget build(BuildContext context) {
    const scrim = VerilyColors.movementScrim;
    return IgnorePointer(
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  scrim.withValues(alpha: 0.75),
                  scrim.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          const Spacer(),
          Container(
            height: 300,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  scrim.withValues(alpha: 0.85),
                  scrim.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Live": proof is captured here, at the moment it happens. While
/// recording, the dot fills.
class LiveBadge extends StatelessWidget {
  const LiveBadge({required this.recording, super.key});

  final bool recording;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: VerilyColors.movementScrim.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(VerilyRadius.chip),
        border: Border.all(color: VerilyColors.movementHudInk, width: 1.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: recording
                  ? VerilyColors.movementHudAccent
                  : VerilyColors.transparent,
              border: Border.all(
                color: VerilyColors.movementHudAccent,
                width: 2,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            context.l10n.captureLive,
            style: theme.textTheme.labelMedium?.copyWith(
              color: VerilyColors.movementHudInk,
            ),
          ),
        ],
      ),
    );
  }
}

/// An icon button that reads over camera footage.
class HudIconButton extends StatelessWidget {
  const HudIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String tooltip;
  final WiredSvgIconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: 26,
      style: IconButton.styleFrom(
        minimumSize: const Size.square(48),
        backgroundColor: VerilyColors.movementScrim.withValues(alpha: 0.55),
        foregroundColor: VerilyColors.movementHudInk,
        disabledForegroundColor: VerilyColors.movementHudInk.withValues(
          alpha: 0.4,
        ),
      ),
      icon: SkribbleIcon(data: icon),
    );
  }
}

/// The row across the top of a viewfinder: close, the title, and an
/// optional trailing button.
class ViewfinderTopBar extends StatelessWidget {
  const ViewfinderTopBar({
    required this.title,
    required this.close,
    this.trailing,
    super.key,
  });

  final String title;
  final Widget close;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          close,
          const SizedBox(width: 8),
          Expanded(
            child: VerilyFittedText(
              title,
              textAlign: TextAlign.center,
              alignment: Alignment.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: VerilyColors.movementHudInk,
              ),
            ),
          ),
          const SizedBox(width: 8),
          trailing ?? const SizedBox.square(dimension: 48),
        ],
      ),
    );
  }
}

/// The big round-cornered button at the bottom of a viewfinder.
class ViewfinderButton extends StatelessWidget {
  const ViewfinderButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.emphasis = true,
    super.key,
  });

  final String label;
  final WiredSvgIconData icon;
  final VoidCallback? onPressed;

  /// The gold-on-night start button, or the paper stop button.
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final background = emphasis
        ? VerilyColors.movementHudAccent
        : VerilyColors.movementHudInk;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: background,
            foregroundColor: VerilyColors.movementOutline,
            disabledBackgroundColor: background.withValues(alpha: 0.4),
            disabledForegroundColor: VerilyColors.movementOutline.withValues(
              alpha: 0.7,
            ),
          ),
          icon: SkribbleIcon(data: icon),
          label: Text(label),
        ),
      ),
    );
  }
}

/// `m:ss`, for recording timers.
String clockLabel(Duration duration) {
  final seconds = duration.inSeconds;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
