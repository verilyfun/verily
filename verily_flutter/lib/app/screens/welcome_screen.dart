import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon, WiredSvgIconData;
import 'package:verily_brand/verily_brand.dart';

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// The front door: the lockup, one plain promise, what every action is made
/// of, and the way in.
///
/// Laid out as a notebook page: a display line at the top, the content as
/// the body, and one primary action at the bottom.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    void signIn({bool returning = false}) => context.go(
      VerilyLocations.signIn(
        from: VerilyRoutePaths.doTab,
        returning: returning,
      ),
    );

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 40).clamp(
                  0,
                  double.infinity,
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: VerilyLockup(
                              layout: VerilyLockupLayout.stacked,
                              height: 104,
                              accentColor: palette.accent,
                              inkColor: palette.ink,
                              semanticLabel: l10n.appTitle,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Semantics(
                            headingLevel: 1,
                            child: Text(
                              l10n.welcomeTitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.displaySmall?.copyWith(
                                color: palette.ink,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.welcomeBody,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: palette.mutedInk,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const _Promise(),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            VerilyActionButton(
                              key: VerilyTestKeys.welcomeGetStarted,
                              label: l10n.welcomeGetStarted,
                              onPressed: signIn,
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              key: VerilyTestKeys.welcomeHaveAccount,
                              onPressed: () => signIn(returning: true),
                              child: Text(l10n.welcomeHaveAccount),
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
        ),
      ),
    );
  }
}

/// The three parts of every action, as a short checklist.
class _Promise extends StatelessWidget {
  const _Promise();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: VerilyRoughDecoration(
        color: palette.surface,
        outline: palette.ink,
        seed: 251,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.welcomePromiseHeading,
              style: theme.textTheme.titleMedium?.copyWith(color: palette.ink),
            ),
          ),
          const SizedBox(height: 12),
          _PromisePart(
            tone: VerilyTone.place,
            icon: VerilyIcons.mapPin,
            title: l10n.welcomePromisePlaceTitle,
            body: l10n.welcomePromisePlaceBody,
            seed: 253,
          ),
          const SizedBox(height: 12),
          _PromisePart(
            tone: VerilyTone.neutral,
            icon: VerilyIcons.video,
            title: l10n.welcomePromiseProofTitle,
            body: l10n.welcomePromiseProofBody,
            seed: 255,
          ),
          const SizedBox(height: 12),
          _PromisePart(
            tone: VerilyTone.reward,
            icon: VerilyIcons.escrow,
            title: l10n.welcomePromiseRewardTitle,
            body: l10n.welcomePromiseRewardBody,
            seed: 257,
          ),
        ],
      ),
    );
  }
}

class _PromisePart extends StatelessWidget {
  const _PromisePart({
    required this.tone,
    required this.icon,
    required this.title,
    required this.body,
    required this.seed,
  });

  final VerilyTone tone;
  final WiredSvgIconData icon;
  final String title;
  final String body;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;

    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: VerilyRoughDecoration(
              color: palette.wash(tone),
              outline: palette.hue(tone),
              radius: 22,
              strokeWidth: 2,
              seed: seed,
            ),
            child: SkribbleIcon(data: icon, size: 22, color: palette.hue(tone)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.mutedInk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
