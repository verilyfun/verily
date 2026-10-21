import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:skribble/skribble.dart';

import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_fitted_text.dart';

/// One destination in a [VerilyNavigationBar] or [VerilyNavigationRail].
@immutable
class VerilyNavigationItem {
  const VerilyNavigationItem({
    required this.icon,
    required this.label,
    required this.semanticKey,
  });

  final WiredSvgIconData icon;

  /// The visible name, which is also the destination's accessible label.
  final String label;

  /// Placed on the destination's semantics node so tests and assistive
  /// tooling can find it.
  final Key semanticKey;
}

/// The phone navigation bar.
///
/// Every destination keeps its label so each space is always named. The
/// selected destination sits on the highlight wash inside a firm pen outline,
/// and its icon is inked with a heavier pen, so selection never relies on
/// colour alone. The destinations are data: the shell decides what they are.
class VerilyNavigationBar extends StatelessWidget {
  const VerilyNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<VerilyNavigationItem> destinations;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).verily;

    return Material(
      color: palette.surface,
      child: SafeArea(
        top: false,
        child: Semantics(
          role: SemanticsRole.tabBar,
          explicitChildNodes: true,
          container: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ExcludeSemantics(child: WiredDivider()),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 68),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var index = 0; index < destinations.length; index++)
                        Expanded(
                          child: _BarDestination(
                            destination: destinations[index],
                            selected: selectedIndex == index,
                            onTap: () => onDestinationSelected(index),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The browser and tablet navigation rail.
///
/// The larger layouts name each space beside its icon under a quiet
/// heading. A [compact] rail stacks the label under the icon so it fits a
/// tablet's narrower column.
class VerilyNavigationRail extends StatelessWidget {
  const VerilyNavigationRail({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.heading,
    this.leading,
    this.compact = false,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<VerilyNavigationItem> destinations;

  /// A quiet label above the destinations, such as "Your spaces".
  final String heading;

  /// The brand mark at the top of the rail.
  final Widget? leading;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;

    return Material(
      color: palette.surface,
      child: SizedBox(
        width: compact ? 104 : 208,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            if (leading case final mark?) ...[
              Align(alignment: Alignment.centerLeft, child: mark),
              const SizedBox(height: 24),
            ],
            // The heading names the tab bar below, so it is read once, as
            // the bar's label, rather than as a stray node beside it.
            ExcludeSemantics(
              child: Text(
                heading,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: palette.mutedInk,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Only the destinations sit inside the tab bar: a tab bar may
            // hold nothing but tabs, and the list's own scroll node is not
            // one.
            Semantics(
              role: SemanticsRole.tabBar,
              label: heading,
              explicitChildNodes: true,
              container: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < destinations.length; index++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _RailDestination(
                        destination: destinations[index],
                        selected: selectedIndex == index,
                        compact: compact,
                        onTap: () => onDestinationSelected(index),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarDestination extends StatelessWidget {
  const _BarDestination({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final VerilyNavigationItem destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;

    return _DestinationSemantics(
      destination: destination,
      selected: selected,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SelectionMarker(
              selected: selected,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: _DestinationIcon(
                destination: destination,
                selected: selected,
              ),
            ),
            const SizedBox(height: 4),
            VerilyFittedText(
              destination.label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected ? palette.ink : palette.mutedInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailDestination extends StatelessWidget {
  const _RailDestination({
    required this.destination,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final VerilyNavigationItem destination;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final label = VerilyFittedText(
      destination.label,
      style: (compact ? theme.textTheme.labelMedium : theme.textTheme.bodyLarge)
          ?.copyWith(color: palette.ink),
    );
    final icon = _DestinationIcon(destination: destination, selected: selected);

    return _DestinationSemantics(
      destination: destination,
      selected: selected,
      onTap: onTap,
      child: _SelectionMarker(
        selected: selected,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: compact
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [icon, const SizedBox(height: 4), label],
              )
            : Row(
                children: [
                  icon,
                  const SizedBox(width: 12),
                  Expanded(child: label),
                ],
              ),
      ),
    );
  }
}

/// One named, selectable destination for assistive technology.
class _DestinationSemantics extends StatelessWidget {
  const _DestinationSemantics({
    required this.destination,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final VerilyNavigationItem destination;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    key: destination.semanticKey,
    label: destination.label,
    role: SemanticsRole.tab,
    selected: selected,
    onTap: onTap,
    excludeSemantics: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: child,
      ),
    ),
  );
}

/// The highlight wash with a pen outline under the selected destination.
class _SelectionMarker extends StatelessWidget {
  const _SelectionMarker({
    required this.selected,
    required this.padding,
    required this.child,
  });

  final bool selected;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).verily;
    final duration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 160);

    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOut,
      padding: padding,
      decoration: VerilyRoughDecoration(
        // Unselected keeps the same colours at zero alpha, so the marker
        // fades in rather than snapping from a different hue.
        color: palette.highlight.withValues(alpha: selected ? 1 : 0),
        outline: selected
            ? palette.firmPen
            : palette.firmPen.withValues(alpha: 0),
        radius: VerilyRadius.chip,
        seed: 59,
      ),
      child: child,
    );
  }
}

class _DestinationIcon extends StatelessWidget {
  const _DestinationIcon({required this.destination, required this.selected});

  final VerilyNavigationItem destination;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).verily;
    return SkribbleIcon(
      data: destination.icon,
      size: 22,
      // A heavier pen marks the selection alongside the marker.
      weight: selected ? 600 : 400,
      color: selected ? palette.ink : palette.mutedInk,
    );
  }
}
