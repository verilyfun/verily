import 'dart:async';

import 'package:flutter/material.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon;

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/app/widgets/verily_app_header.dart';
import 'package:verily_flutter/app/widgets/verily_appearance_settings.dart';
import 'package:verily_flutter/app/widgets/verily_sketch_postcard.dart';
import 'package:verily_flutter/l10n/l10n.dart';

/// The home screen until actions exist: the promise, and the one setting the
/// app has so far.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).verily;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VerilyAppHeader(
            title: l10n.appTitle,
            subtitle: l10n.appTagline,
            trailing: IconButton(
              tooltip: l10n.settingsOpenTooltip,
              onPressed: () => unawaited(_showSettings(context)),
              icon: const SkribbleIcon(data: VerilyIcons.settings),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  VerilySketchPostcard(
                    title: l10n.placeholderTitle,
                    subtitle: l10n.placeholderBody,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSettings(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => const _SettingsSheet(),
      );
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.settingsTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.verily.ink,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const VerilyAppearanceSettings(),
            const SizedBox(height: 16),
            VerilyActionButton(
              tone: VerilyActionTone.secondary,
              label: l10n.dialogDone,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
