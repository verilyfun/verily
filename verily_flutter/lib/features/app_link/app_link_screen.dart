import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon;

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/app/widgets/verily_state_panel.dart';
import 'package:verily_flutter/core/external_url_launcher.dart';
import 'package:verily_flutter/features/app_link/app_link_flow.dart';
import 'package:verily_flutter/features/app_link/app_link_repository.dart';
import 'package:verily_flutter/features/verify_request/widgets/deep_link_page.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// Links this Verily account to another App that opened
/// `/link?app=…&redirect_uri=…&state=…`.
///
/// Linking gives the App one private ID made only for it, so it can confirm
/// the actions people do there. The person sees that before agreeing, and
/// either answer returns them to the App.
class AppLinkScreen extends HookConsumerWidget {
  const AppLinkScreen({required this.query, super.key});

  /// The link's query, unchecked.
  final Map<String, String> query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    final flow = useMemoized(
      () => AppLinkFlow(
        request: AppLinkRequest.fromQuery(query),
        links: ref.read(appLinkRepositoryProvider),
        openExternal: ref.read(externalUrlLauncherProvider),
      ),
      [query.toString()],
    );
    useEffect(() {
      unawaited(flow.load());
      return flow.dispose;
    }, [flow]);
    useListenable(flow);
    final state = flow.state;

    return DeepLinkPage(
      title: l10n.appLinkHeaderTitle,
      subtitle: switch (state) {
        AppLinkConsent(:final view) => _from(
          l10n,
          view.appName,
          view.websiteUrl,
        ),
        _ => null,
      },
      children: switch (state) {
        AppLinkLoading() => [
          VerilyLoadingPanel(label: l10n.verifyRequestLoading),
        ],
        AppLinkUnavailable() => [
          _LinkUnavailablePanel(state: state, onRetry: flow.load),
        ],
        AppLinkConsent(:final view) => [
          Semantics(
            key: VerilyTestKeys.appLinkConsent,
            header: true,
            child: Text(
              l10n.appLinkAsks(view.appName),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: palette.ink,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            view.alreadyLinked
                ? l10n.appLinkAlreadyLinked(view.appName)
                : l10n.appLinkHow(view.appName),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.mutedInk,
            ),
          ),
          const SizedBox(height: 16),
          DeepLinkSection(
            heading: l10n.verifyRequestSharedHeading(view.appName),
            seed: 223,
            children: [
              DeepLinkLine(
                icon: VerilyIcons.user,
                text: l10n.appLinkSharesSubject(view.appName),
              ),
              DeepLinkLine(
                icon: VerilyIcons.lock,
                text: l10n.appLinkSharesNothingElse,
              ),
            ],
          ),
          if (state.failed) ...[
            const SizedBox(height: 16),
            DeepLinkNotice(text: l10n.errorGeneric),
          ],
          const SizedBox(height: 20),
          VerilyActionButton(
            key: VerilyTestKeys.appLinkApprove,
            label: l10n.appLinkApprove(view.appName),
            isLoading: state.answering ?? false,
            leading: const SkribbleIcon(data: VerilyIcons.link),
            onPressed: state.answering != null
                ? null
                : () => unawaited(flow.approve()),
          ),
          const SizedBox(height: 12),
          VerilyActionButton(
            key: VerilyTestKeys.appLinkDecline,
            label: l10n.appLinkDecline,
            tone: VerilyActionTone.secondary,
            isLoading: state.answering == false,
            onPressed: state.answering != null
                ? null
                : () => unawaited(flow.decline()),
          ),
        ],
        AppLinkReturning() => [
          ReturningPanel(
            title: state.linked
                ? l10n.verifyRequestReturningTitle(state.appName)
                : l10n.appLinkDeclinedTitle,
            message: state.linked
                ? l10n.appLinkLinkedBody(state.appName)
                : l10n.appLinkDeclinedBody(state.appName),
            appName: state.appName,
            opened: state.opened,
            onOpenApp: () => unawaited(flow.openApp()),
          ),
        ],
      },
    );
  }

  static String _from(AppLocalizations l10n, String app, String? website) {
    final host = Uri.tryParse(website ?? '')?.host ?? '';
    return host.isEmpty
        ? l10n.verifyRequestFrom(app)
        : l10n.verifyRequestFromWebsite(app, host);
  }
}

class _LinkUnavailablePanel extends StatelessWidget {
  const _LinkUnavailablePanel({required this.state, required this.onRetry});

  final AppLinkUnavailable state;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final app = state.appName ?? l10n.verifyRequestTheApp;
    final backToVerily = VerilyStateAction(
      label: l10n.verifyRequestBackToVerily,
      onPressed: () => context.goNamed(VerilyRouteNames.doTab),
    );
    final panel = switch (state.problem) {
      LinkProblem.invalid => VerilyStatePanel.empty(
        title: l10n.appLinkInvalidTitle,
        message: l10n.appLinkInvalidBody,
        action: backToVerily,
      ),
      LinkProblem.rateLimited => VerilyStatePanel.empty(
        title: l10n.verifyRequestRateLimitedTitle,
        message: l10n.appLinkRateLimitedBody(app),
        action: backToVerily,
      ),
      LinkProblem.appUnavailable => VerilyStatePanel.problem(
        title: l10n.verifyRequestAppUnavailableTitle(app),
        message: state.message,
        action: backToVerily,
      ),
      LinkProblem.generic => VerilyStatePanel.problem(
        title: l10n.appLinkLoadFailedTitle,
        message: l10n.errorGeneric,
        action: VerilyStateAction(
          label: l10n.verifyRequestTryAgain,
          onPressed: () => unawaited(onRetry()),
        ),
        secondaryAction: backToVerily,
      ),
    };
    return KeyedSubtree(key: VerilyTestKeys.deepLinkUnavailable, child: panel);
  }
}
