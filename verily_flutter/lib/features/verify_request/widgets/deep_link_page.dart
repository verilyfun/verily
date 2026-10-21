import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skribble/skribble.dart'
    show SkribbleIcon, WiredLoadingIndicator, WiredSvgIconData;

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/app/widgets/verily_app_header.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// The page another App opens Verily on: a request for proof or a link.
///
/// It is reached from outside, so there is usually nothing to go back to.
/// The close button leaves for the Do tab without answering; answering is
/// always an explicit choice on the page.
class DeepLinkPage extends StatelessWidget {
  const DeepLinkPage({
    required this.title,
    required this.children,
    this.subtitle,
    this.closeKey,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  /// Identifies the close button for tests.
  final Key? closeKey;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).verily;
    return Scaffold(
      backgroundColor: palette.canvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VerilyAppHeader(
            title: title,
            subtitle: subtitle,
            trailing: IconButton(
              key: closeKey,
              tooltip: context.l10n.verifyRequestClose,
              onPressed: () => leaveDeepLink(context),
              icon: const SkribbleIcon(data: VerilyIcons.close),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              // A short page: every part is built, so a screen reader and
              // the person's scroll both reach the answer buttons.
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Leaves a deep-link page: back where the person came from inside Verily,
/// or to the Do tab when the link opened the app.
void leaveDeepLink(BuildContext context) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
    return;
  }
  router.goNamed(VerilyRouteNames.doTab);
}

/// A titled group of lines on a paper card, such as "How it works".
class DeepLinkSection extends StatelessWidget {
  const DeepLinkSection({
    required this.heading,
    required this.children,
    this.seed = 41,
    super.key,
  });

  final String heading;
  final List<Widget> children;

  /// Keeps each card's pen wobble stable across rebuilds.
  final int seed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: VerilyRoughDecoration(
        color: palette.surface,
        outline: palette.firmPen,
        seed: seed,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              heading,
              style: theme.textTheme.titleMedium?.copyWith(color: palette.ink),
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

/// One plain statement with a drawing beside it. The words carry the
/// meaning; the drawing only helps scanning.
class DeepLinkLine extends StatelessWidget {
  const DeepLinkLine({
    required this.icon,
    required this.text,
    this.emphasized = false,
    super.key,
  });

  final WiredSvgIconData icon;
  final String text;

  /// Set for the line a person most needs to notice, such as the App
  /// downloading their capture.
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final style = emphasized
        ? theme.textTheme.titleSmall?.copyWith(color: palette.ink)
        : theme.textTheme.bodyMedium?.copyWith(color: palette.ink);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: SkribbleIcon(data: icon, size: 20, color: palette.ink),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}

/// Handing the person back to the App: what happened, and a way to open the
/// App again when it did not open by itself.
class ReturningPanel extends StatelessWidget {
  const ReturningPanel({
    required this.title,
    required this.message,
    required this.appName,
    required this.opened,
    required this.onOpenApp,
    super.key,
  });

  final String title;
  final String message;
  final String appName;

  /// Whether the App opened; null while it is being opened.
  final bool? opened;
  final VoidCallback onOpenApp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    return Container(
      key: VerilyTestKeys.deepLinkReturning,
      padding: const EdgeInsets.all(20),
      decoration: VerilyRoughDecoration(
        color: palette.surface,
        outline: palette.ink,
        seed: 233,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (opened == null)
                WiredLoadingIndicator(color: palette.ink)
              else
                SkribbleIcon(
                  data: VerilyIcons.externalLink,
                  size: 24,
                  color: palette.ink,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: palette.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(color: palette.ink),
          ),
          if (opened == false) ...[
            const SizedBox(height: 10),
            Text(
              l10n.verifyRequestOpenFailed(appName),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.mutedInk,
              ),
            ),
          ],
          const SizedBox(height: 20),
          VerilyActionButton(
            key: VerilyTestKeys.deepLinkOpenApp,
            label: l10n.verifyRequestOpenApp(appName),
            tone: opened == false
                ? VerilyActionTone.primary
                : VerilyActionTone.secondary,
            isLoading: opened == null,
            leading: const SkribbleIcon(data: VerilyIcons.externalLink),
            onPressed: onOpenApp,
          ),
          const SizedBox(height: 4),
          TextButton(
            key: VerilyTestKeys.deepLinkBackToVerily,
            onPressed: () => context.goNamed(VerilyRouteNames.doTab),
            child: Text(l10n.verifyRequestBackToVerily),
          ),
        ],
      ),
    );
  }
}

/// A short problem beside the step it concerns.
class DeepLinkNotice extends StatelessWidget {
  const DeepLinkNotice({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: VerilyTestKeys.verifyRequestNotice,
        padding: const EdgeInsets.all(12),
        decoration: VerilyRoughDecoration(
          color: palette.highlight,
          outline: palette.firmPen,
          radius: VerilyRadius.control,
          strokeWidth: 2,
          seed: 251,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: SkribbleIcon(
                data: VerilyIcons.warning,
                size: 20,
                color: palette.ink,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
