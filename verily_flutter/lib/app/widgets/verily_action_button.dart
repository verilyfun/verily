import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skribble/skribble.dart' show WiredLoadingIndicator;

import 'package:verily_flutter/app/theme/verily_pen.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_rough_surface.dart';

/// Visual weight for a Verily action.
enum VerilyActionTone {
  /// The one deliberate next step on a page. Inked: vermilion is kept for
  /// the verified stamp.
  primary,

  /// An available alternative that must not compete. Quiet paper.
  secondary,

  /// A reversible or destructive step. Paper with a heavier ink pen; its
  /// words and icon say what it removes.
  destructive,
}

/// Verily action control.
///
/// Every action is a 56-unit target with a stable double pen outline. The
/// outline seed is fixed per label so a rebuild never re-rolls the wobble,
/// and press feedback strengthens the ink without moving the label or the
/// paper, which keeps a long tap from shifting the tap target.
class VerilyActionButton extends HookWidget {
  const VerilyActionButton({
    required this.label,
    required this.onPressed,
    this.tone = VerilyActionTone.primary,
    this.isLoading = false,
    this.expand = true,
    this.leading,
    this.semanticHint,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final VerilyActionTone tone;

  /// Keeps the height and the outline while a request is outstanding.
  final bool isLoading;

  /// Fill the available width. Set false for inline and toolbar actions.
  final bool expand;

  final Widget? leading;
  final String? semanticHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final isEnabled = onPressed != null && !isLoading;
    final isPressed = useState(false);

    // An unavailable action keeps its place but drops to the highlight wash
    // with muted ink, so it still reads as a label rather than a faded
    // block; a loading one stays full. A pressed primary lifts its ink a
    // little, because its outline is already full ink.
    final isUnavailable = onPressed == null;
    final fill = switch (tone) {
      VerilyActionTone.primary when isUnavailable => palette.highlight,
      VerilyActionTone.primary when isEnabled && isPressed.value =>
        Color.alphaBlend(
          palette.onAction.withValues(alpha: 0.16),
          palette.action,
        ),
      VerilyActionTone.primary => palette.action,
      VerilyActionTone.secondary => palette.surface,
      VerilyActionTone.destructive => palette.surface,
    };
    final labelColor = switch (tone) {
      // Paper on ink by day, night on paper after dark.
      VerilyActionTone.primary => palette.onAction,
      VerilyActionTone.secondary => palette.ink,
      VerilyActionTone.destructive => palette.ink,
    };
    // The label while the action cannot be pressed. A loading primary keeps
    // its fill, so it keeps its own label colour too.
    final inactiveLabel = switch (tone) {
      VerilyActionTone.primary when !isUnavailable => labelColor,
      VerilyActionTone.primary => palette.mutedInk,
      VerilyActionTone.secondary ||
      VerilyActionTone.destructive => palette.mutedInk.withValues(alpha: 0.7),
    };
    // Press strengthens the outline rather than moving anything.
    final outlineColor = isEnabled && isPressed.value
        ? palette.ink
        : isUnavailable
        ? palette.quietPen
        : switch (tone) {
            VerilyActionTone.primary ||
            VerilyActionTone.destructive => palette.ink,
            VerilyActionTone.secondary => palette.ink.withValues(alpha: 0.56),
          };
    // A destructive step is set apart by a heavier pen, not by colour.
    final strokeWidth = tone == VerilyActionTone.destructive && !isUnavailable
        ? 3.4
        : VerilyPen.strokeWidth;

    // The button owns its whole semantics node: one label (not the label plus
    // the visible text) and its own tap action, so assistive technology and
    // Flutter web's accessibility tree can activate it directly. Without
    // `container`, an excluded subtree would merge the button into whichever
    // ancestor node happens to be nearest.
    return Semantics(
      container: true,
      button: true,
      enabled: isEnabled,
      label: label,
      hint: semanticHint,
      onTap: isEnabled ? onPressed : null,
      excludeSemantics: true,
      child: FocusableActionDetector(
        enabled: isEnabled,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onPressed?.call();
              return null;
            },
          ),
        },
        child: Builder(
          builder: (context) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: isEnabled ? (_) => isPressed.value = true : null,
            onTapCancel: () => isPressed.value = false,
            onTapUp: (_) => isPressed.value = false,
            onTap: isEnabled ? onPressed : null,
            child: _FocusRing(
              isFocused: Focus.of(context).hasFocus,
              palette: palette,
              // The drawn surface is the whole 56-unit target, so the label
              // has room inside the pen outline rather than a thin strip
              // inset within an invisible box.
              child: SizedBox(
                width: expand ? double.infinity : null,
                child: VerilyRoughSurface(
                  fill: fill,
                  outline: outlineColor,
                  radius: VerilyRadius.control,
                  strokeWidth: strokeWidth,
                  // A fixed seed per label keeps the pen wobble identical on
                  // every rebuild.
                  seed: label.hashCode & 0x7fffffff,
                  minHeight: 56,
                  // The pen outline already insets the label by its reach, so
                  // this padding only adds the breathing room inside the line.
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isLoading) ...[
                        WiredLoadingIndicator(size: 18, color: labelColor),
                        const SizedBox(width: 10),
                      ] else if (leading != null) ...[
                        IconTheme.merge(
                          data: IconThemeData(
                            color: isEnabled ? labelColor : inactiveLabel,
                            size: 20,
                          ),
                          child: leading!,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: isEnabled ? labelColor : inactiveLabel,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The brand's focus treatment: a 2-unit contrasting pen ring with a 2-unit
/// gap, drawn outside the control so it never crowds the label.
class _FocusRing extends StatelessWidget {
  const _FocusRing({
    required this.child,
    required this.isFocused,
    required this.palette,
  });

  final Widget child;
  final bool isFocused;
  final VerilyPalette palette;

  @override
  Widget build(BuildContext context) {
    if (!isFocused) {
      return child;
    }
    return Padding(
      padding: const EdgeInsets.all(4),
      child: DecoratedBox(
        decoration: VerilyRoughDecoration(
          outline: palette.ink,
          radius: VerilyRadius.control + 4,
          strokeWidth: 2,
          seed: 61,
        ),
        child: child,
      ),
    );
  }
}
