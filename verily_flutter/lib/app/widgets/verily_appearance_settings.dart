import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon, WiredSvgIconData;

import 'package:verily_flutter/app/theme/theme_mode_provider.dart';
import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// Chooses between paper, night, or following the device.
///
/// Verily has one light and one dark theme, so the only choice is the mode.
/// The choice applies at once and is kept between launches.
class VerilyAppearanceSettings extends ConsumerWidget {
  const VerilyAppearanceSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final selection = ref.watch(verilyThemePreferenceProvider);
    final controller = ref.read(verilyThemePreferenceProvider.notifier);
    final l10n = context.l10n;

    void select(VerilyThemePreference preference) =>
        unawaited(controller.setPreference(preference));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: VerilyRoughDecoration(
        color: palette.surface,
        outline: palette.ink,
        seed: 71,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.appearanceTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: palette.ink,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.appearanceSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.mutedInk,
            ),
          ),
          const SizedBox(height: 20),
          // Equal heights keep the three choices level when one label wraps.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ModeChoice(
                    key: VerilyTestKeys.appearanceSystem,
                    seed: 131,
                    label: l10n.appearanceSystem,
                    icon: VerilyIcons.themeAuto,
                    selected: selection == VerilyThemePreference.system,
                    onTap: () => select(VerilyThemePreference.system),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModeChoice(
                    key: VerilyTestKeys.appearanceLight,
                    seed: 132,
                    label: l10n.appearanceLight,
                    icon: VerilyIcons.sun,
                    selected: selection == VerilyThemePreference.light,
                    onTap: () => select(VerilyThemePreference.light),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModeChoice(
                    key: VerilyTestKeys.appearanceDark,
                    seed: 133,
                    label: l10n.appearanceDark,
                    icon: VerilyIcons.moon,
                    selected: selection == VerilyThemePreference.dark,
                    onTap: () => select(VerilyThemePreference.dark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Semantics(
            liveRegion: true,
            child: Text(
              switch (selection) {
                VerilyThemePreference.system => l10n.appearanceSystemSubtitle,
                VerilyThemePreference.light => l10n.appearanceLightSubtitle,
                VerilyThemePreference.dark => l10n.appearanceDarkSubtitle,
              },
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.mutedInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One appearance mode.
///
/// The chosen mode takes the highlight wash, the firm pen, and a heavier icon
/// stroke together, so selection never rests on colour alone.
class _ModeChoice extends StatelessWidget {
  const _ModeChoice({
    required this.seed,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  /// Keeps each choice's outline distinct from its neighbours'.
  final int seed;
  final String label;
  final WiredSvgIconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VerilyRadius.chip),
          child: Ink(
            decoration: VerilyRoughDecoration(
              color: selected ? palette.highlight : palette.canvas,
              outline: selected ? palette.firmPen : palette.quietPen,
              radius: VerilyRadius.chip,
              strokeWidth: 2,
              seed: seed,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 76),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 8,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SkribbleIcon(
                      data: icon,
                      size: 21,
                      weight: selected ? 600 : null,
                      color: palette.ink,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: selected ? palette.ink : palette.mutedInk,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
