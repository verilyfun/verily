import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skribble/skribble.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/app/widgets/verily_app_header.dart';
import 'package:verily_flutter/app/widgets/verily_sketch_postcard.dart';
import 'package:verily_flutter/app/widgets/verily_state_panel.dart';
import 'package:verily_flutter/l10n/l10n.dart';

/// Debug-only living specimen of the theme and the hand-drawn primitives,
/// drawn in the active palette. Reach it from the development menu.
///
/// Each section uses the primitive the app itself uses, so a change to the
/// pen, the theme, or Skribble shows up here first. The app-wide
/// `VerilyWiredScope` inks the Wired controls; the gallery installs none of
/// its own.
class SkribblePreviewScreen extends HookWidget {
  const SkribblePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    final palette = Theme.of(context).verily;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VerilyAppHeader(
            title: l10n.developerSkribblePreview,
            subtitle: l10n.developerSkribblePreviewSubtitle,
            trailing: Navigator.canPop(context)
                ? IconButton(
                    tooltip: l10n.developerClose,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const SkribbleIcon(data: VerilyIcons.close),
                  )
                : null,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _GallerySection(
                    heading: l10n.skribblePreviewColorsHeading,
                    outline: palette.quietPen,
                    seed: 209,
                    child: const _TonesSample(),
                  ),
                  const SizedBox(height: 24),
                  _GallerySection(
                    heading: l10n.skribblePreviewTypeHeading,
                    outline: palette.firmPen,
                    seed: 211,
                    child: const _TypeSample(),
                  ),
                  const SizedBox(height: 24),
                  _GallerySection(
                    heading: l10n.skribblePreviewActionsHeading,
                    outline: palette.quietPen,
                    seed: 201,
                    child: const _ActionsSample(),
                  ),
                  const SizedBox(height: 24),
                  _GallerySection(
                    heading: l10n.skribblePreviewStatesHeading,
                    outline: palette.firmPen,
                    seed: 213,
                    child: const _StatesSample(),
                  ),
                  const SizedBox(height: 24),
                  _GallerySection(
                    heading: l10n.skribblePreviewFieldsHeading,
                    outline: palette.quietPen,
                    seed: 203,
                    child: const _FieldsSample(),
                  ),
                  const SizedBox(height: 24),
                  _GallerySection(
                    heading: l10n.skribblePreviewSelectionHeading,
                    outline: palette.firmPen,
                    seed: 205,
                    child: const _SelectionSample(),
                  ),
                  const SizedBox(height: 24),
                  _GallerySection(
                    heading: l10n.skribblePreviewDoodlesHeading,
                    outline: palette.quietPen,
                    seed: 207,
                    child: const _DrawingsSample(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A headed paper panel. Sections alternate the quiet and firm pens so both
/// outline roles are on show.
class _GallerySection extends StatelessWidget {
  const _GallerySection({
    required this.heading,
    required this.outline,
    required this.seed,
    required this.child,
  });

  final String heading;
  final Color outline;
  final int seed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: VerilyRoughDecoration(
        color: palette.surface,
        outline: outline,
        seed: seed,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              heading,
              style: theme.textTheme.titleMedium?.copyWith(color: palette.ink),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Each tone's wash carrying ink with its hue on the icon, each hue as a
/// label on the page, and the stamp, which marks verified proof only.
class _TonesSample extends StatelessWidget {
  const _TonesSample();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    final tones = [
      (VerilyTone.neutral, VerilyIcons.check, l10n.skribblePreviewToneNeutral),
      (VerilyTone.place, VerilyIcons.mapPin, l10n.skribblePreviewTonePlace),
      (VerilyTone.reward, VerilyIcons.coins, l10n.skribblePreviewToneReward),
      (VerilyTone.review, VerilyIcons.review, l10n.skribblePreviewToneReview),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.4,
          children: [
            for (final (index, (tone, icon, name)) in tones.indexed)
              DecoratedBox(
                decoration: VerilyRoughDecoration(
                  color: palette.wash(tone),
                  outline: palette.hue(tone),
                  radius: VerilyRadius.chip,
                  strokeWidth: 2,
                  seed: 215 + index,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      SkribbleIcon(
                        data: icon,
                        size: 22,
                        color: palette.readableAccent(palette.hue(tone)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          name,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: palette.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SkribbleIcon(
                  data: VerilyIcons.verified,
                  size: 24,
                  color: palette.accent,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.skribblePreviewToneStamp,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: palette.accent,
                  ),
                ),
              ],
            ),
            for (final (tone, _, name) in tones.skip(1))
              Text(
                name,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: palette.hue(tone),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// The type scale, one line per anchor role.
class _TypeSample extends StatelessWidget {
  const _TypeSample();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    final text = theme.textTheme;
    final roles = [
      (l10n.skribblePreviewTypeDisplay, text.displayLarge, l10n.appTitle),
      (l10n.skribblePreviewTypeHeadline, text.headlineLarge, l10n.appTitle),
      (l10n.skribblePreviewTypeTitle, text.titleLarge, l10n.appTagline),
      (
        l10n.skribblePreviewTypeBody,
        text.bodyMedium,
        l10n.skribblePreviewBodySample,
      ),
      (l10n.skribblePreviewTypeLabel, text.labelLarge, l10n.appTagline),
      (l10n.skribblePreviewTypeCaption, text.labelSmall, l10n.appTagline),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (name, style, sample) in roles) ...[
          Text(
            l10n.skribblePreviewTypeRole(
              name,
              (style?.fontSize ?? 0).round(),
              ((style?.fontSize ?? 0) * (style?.height ?? 0)).round(),
            ),
            style: text.labelSmall?.copyWith(color: palette.mutedInk),
          ),
          Text(sample, style: style?.copyWith(color: palette.ink)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// A postcard, then every action tone.
class _ActionsSample extends StatelessWidget {
  const _ActionsSample();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VerilySketchPostcard(
          title: l10n.skribblePreviewPostcardTitle,
          subtitle: l10n.skribblePreviewPostcardBody,
          tone: VerilyTone.place,
          minHeight: 160,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            VerilyActionButton(
              expand: false,
              onPressed: () {},
              leading: const SkribbleIcon(data: VerilyIcons.rocket),
              label: l10n.skribblePreviewPrimaryAction,
            ),
            VerilyActionButton(
              expand: false,
              tone: VerilyActionTone.secondary,
              onPressed: () {},
              label: l10n.skribblePreviewSecondaryAction,
            ),
            VerilyActionButton(
              expand: false,
              tone: VerilyActionTone.destructive,
              onPressed: () {},
              leading: const SkribbleIcon(data: VerilyIcons.delete),
              label: l10n.skribblePreviewDestructiveAction,
            ),
            VerilyActionButton(
              expand: false,
              isLoading: true,
              onPressed: () {},
              label: l10n.skribblePreviewPrimaryAction,
            ),
            VerilyActionButton(
              expand: false,
              onPressed: null,
              label: l10n.skribblePreviewPrimaryAction,
            ),
          ],
        ),
      ],
    );
  }
}

/// An empty state, a problem, and a labelled wait.
class _StatesSample extends StatelessWidget {
  const _StatesSample();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VerilyStatePanel.empty(
          title: l10n.skribblePreviewEmptyTitle,
          message: l10n.skribblePreviewEmptyBody,
          tone: VerilyTone.place,
          action: VerilyStateAction(
            label: l10n.skribblePreviewEmptyAction,
            onPressed: () {},
          ),
        ),
        const SizedBox(height: 16),
        VerilyStatePanel.problem(
          title: l10n.skribblePreviewProblemTitle,
          message: l10n.skribblePreviewProblemBody,
          action: VerilyStateAction(
            label: l10n.dialogRetry,
            onPressed: () {},
          ),
        ),
        VerilyLoadingPanel(label: l10n.skribblePreviewLoading),
      ],
    );
  }
}

/// A themed field drawn by the rough input border.
class _FieldsSample extends HookWidget {
  const _FieldsSample();

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: context.l10n.skribblePreviewFieldLabel,
        hintText: context.l10n.skribblePreviewFieldHint,
        prefixIcon: const Center(
          widthFactor: 1,
          heightFactor: 1,
          child: SkribbleIcon(data: VerilyIcons.edit),
        ),
      ),
    );
  }
}

/// Every Wired control, plus progress that follows the slider.
class _SelectionSample extends HookWidget {
  const _SelectionSample();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = Theme.of(context).verily;
    final isChecked = useState(false);
    final isRough = useState(true);
    final brightness = useState(Brightness.light);
    final amount = useState(0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ControlRow(
          control: WiredCheckbox(
            value: isChecked.value,
            onChanged: (value) => isChecked.value = value ?? false,
          ),
          label: l10n.skribblePreviewNotifyCheckboxLabel,
        ),
        _ControlRow(
          control: WiredSwitch(
            value: isRough.value,
            onChanged: (value) => isRough.value = value,
          ),
          label: l10n.skribblePreviewRoughenSwitchLabel,
        ),
        for (final (value, label) in [
          (Brightness.light, l10n.appearanceLight),
          (Brightness.dark, l10n.appearanceDark),
        ])
          _ControlRow(
            control: WiredRadio<Brightness>(
              value: value,
              groupValue: brightness.value,
              onChanged: (selected) {
                if (selected != null) brightness.value = selected;
                return true;
              },
            ),
            label: label,
          ),
        const SizedBox(height: 8),
        const WiredDivider(),
        const SizedBox(height: 8),
        WiredSlider(
          value: amount.value,
          semanticLabel: l10n.skribblePreviewRoughenSwitchLabel,
          onChanged: isRough.value
              ? (value) {
                  amount.value = value;
                  return true;
                }
              : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            WiredCircularProgress(value: amount.value, size: 40),
            const SizedBox(width: 16),
            Expanded(child: WiredProgress(value: amount.value, height: 24)),
            const SizedBox(width: 16),
            WiredLoadingIndicator(size: 28, color: palette.ink),
          ],
        ),
      ],
    );
  }
}

class _ControlRow extends StatelessWidget {
  const _ControlRow({required this.control, required this.label});

  final Widget control;
  final String label;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          control,
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
        ],
      ),
    ),
  );
}

/// Skribble's decorative doodles and a sample of the app's icon set.
class _DrawingsSample extends StatelessWidget {
  const _DrawingsSample();

  static const List<WiredSvgIconData> _icons = [
    VerilyIcons.bolt,
    VerilyIcons.mapPin,
    VerilyIcons.video,
    VerilyIcons.photo,
    VerilyIcons.microphone,
    VerilyIcons.run,
    VerilyIcons.verified,
    VerilyIcons.escrow,
    VerilyIcons.coins,
    VerilyIcons.review,
    VerilyIcons.qrCode,
    VerilyIcons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).verily;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const WiredDoodle(
              kind: WiredDoodleKind.butterfly,
              seed: 8,
              size: 56,
            ),
            const WiredDoodle(kind: WiredDoodleKind.heart, seed: 3, size: 56),
            const WiredDoodle(kind: WiredDoodleKind.sun, seed: 5, size: 56),
            WiredDoodle(
              kind: WiredDoodleKind.rainbow,
              seed: 2,
              size: 56,
              fillColor: palette.highlight,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const WiredDivider(),
        const SizedBox(height: 16),
        Wrap(
          spacing: 20,
          runSpacing: 16,
          children: [
            for (final icon in _icons)
              SkribbleIcon(data: icon, size: 28, color: palette.ink),
          ],
        ),
      ],
    );
  }
}
