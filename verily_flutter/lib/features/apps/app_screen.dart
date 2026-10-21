import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/app/widgets/verily_app_header.dart';
import 'package:verily_flutter/app/widgets/verily_state_panel.dart';
import 'package:verily_flutter/core/api_client.dart';
import 'package:verily_flutter/core/user_message.dart';
import 'package:verily_flutter/features/actions/action_repository.dart';
import 'package:verily_flutter/features/apps/apps_providers.dart';
import 'package:verily_flutter/features/apps/apps_repository.dart';
import 'package:verily_flutter/features/apps/widgets/app_key_dialog.dart';
import 'package:verily_flutter/features/apps/widgets/apps_common.dart';
import 'package:verily_flutter/features/apps/widgets/confirmations_log.dart';
import 'package:verily_flutter/features/apps/widgets/integration_guide.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// One of the creator's own action keys that the App confirms, for the
/// request example; null when the App confirms no action yet. Draws on the
/// creator's actions, since an App view carries only a count.
final FutureProviderFamily<String?, UuidValue> appExampleActionKeyProvider =
    FutureProvider.autoDispose.family<String?, UuidValue>((ref, appId) async {
      final actions = await ref.watch(actionRepositoryProvider).listOwned();
      for (final action in actions) {
        final confirmsThis = action.requirements.any(
          (requirement) =>
              requirement.kind == ActionRequirementKind.externalApp &&
              requirement.appId == appId,
        );
        if (confirmsThis) return action.actionKey;
      }
      return null;
    });

/// One Verily App: its keys, how to send confirmations, and the log of what
/// it sent.
class AppScreen extends ConsumerWidget {
  const AppScreen({required this.appId, super.key});

  /// The App's id, from `/apps/:appId`.
  final String appId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final palette = Theme.of(context).verily;
    final apps = ref.watch(verilyAppsProvider);
    // There is no single-App endpoint, so the App comes from the list.
    final app = apps.value?.where((item) => item.id.toString() == appId);

    return Scaffold(
      backgroundColor: palette.canvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VerilyAppHeader(
            title: app == null || app.isEmpty ? l10n.appsTitle : app.first.name,
            subtitle: app == null || app.isEmpty
                ? null
                : app.first.websiteUrl ?? l10n.appsSubtitle,
            leading: IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () {
                final router = GoRouter.of(context);
                if (router.canPop()) {
                  router.pop();
                } else {
                  router.goNamed(VerilyRouteNames.apps);
                }
              },
              icon: const SkribbleIcon(data: VerilyIcons.back),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final gutter = math.max(
                    appsPageGutter,
                    (constraints.maxWidth - appsMaxContentWidth) / 2,
                  );
                  return ListView(
                    padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
                    children: apps.when(
                      loading: () => [
                        VerilyLoadingPanel(label: l10n.appsLoading),
                      ],
                      error: (error, _) => [
                        VerilyStatePanel.problem(
                          title: l10n.appsLoadFailedTitle,
                          message: l10n.errorGeneric,
                          action: VerilyStateAction(
                            label: l10n.dialogRetry,
                            onPressed: () => ref.invalidate(verilyAppsProvider),
                          ),
                        ),
                      ],
                      data: (items) {
                        final match = items.where(
                          (item) => item.id.toString() == appId,
                        );
                        if (match.isEmpty) {
                          return [
                            VerilyStatePanel.problem(
                              title: l10n.errorNotFound,
                              action: VerilyStateAction(
                                label: l10n.appsBackToApps,
                                onPressed: () =>
                                    context.goNamed(VerilyRouteNames.apps),
                              ),
                            ),
                          ];
                        }
                        return _appDetails(context, ref, match.first);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The sections of one App's page, in reading order.
List<Widget> _appDetails(
  BuildContext context,
  WidgetRef ref,
  VerilyAppView app,
) {
  final l10n = context.l10n;
  final active = app.status == VerilyAppStatus.active;
  final exampleActionKey = ref.watch(appExampleActionKeyProvider(app.id));

  return [
    if (!active) ...[
      AppsPanel(
        seed: 271,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkribbleIcon(
              data: VerilyIcons.lock,
              color: Theme.of(context).verily.ink,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(l10n.appsRevokedNotice)),
          ],
        ),
      ),
      const SizedBox(height: 24),
    ],
    _KeysPanel(app: app),
    const SizedBox(height: 24),
    if (active) ...[
      AppIntegrationGuide(
        confirmationsUrl: ref.watch(serverConfigProvider).confirmationsUrl,
        actionKey: exampleActionKey.value,
      ),
      const SizedBox(height: 24),
    ],
    AppConfirmationsLog(appId: app.id),
    if (active) ...[
      const SizedBox(height: 32),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: _RevokeAppButton(app: app),
      ),
    ],
  ];
}

/// Runs one change to an App and refreshes the list; a failure is reported
/// in plain words and logged.
Future<void> _runAppChange(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function() change,
) async {
  try {
    await change();
  } on Object catch (error) {
    debugPrint('Changing an App failed: $error');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(userMessageFor(context.l10n, error))),
    );
  } finally {
    ref.invalidate(verilyAppsProvider);
  }
}

class _KeysPanel extends ConsumerWidget {
  const _KeysPanel({required this.app});

  final VerilyAppView app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final active = app.status == VerilyAppStatus.active;
    final canAddKey = canIssueKey(app);

    Future<void> newKey() => _runAppChange(context, ref, () async {
      final credential = await ref
          .read(appsRepositoryProvider)
          .createKey(app.id);
      if (context.mounted) await showAppKeyOnce(context, credential);
    });

    Future<void> revokeKey(VerilyAppKeyView key) async {
      final confirmed = await confirmAppsDestructiveStep(
        context,
        title: l10n.appsRevokeKeyTitle,
        body: l10n.appsRevokeKeyBody(appKeyLabel(key.keyId)),
        confirmLabel: l10n.appsRevokeConfirm,
        confirmKey: VerilyTestKeys.appsRevokeConfirm,
      );
      if (!confirmed || !context.mounted) return;
      await _runAppChange(
        context,
        ref,
        () => ref
            .read(appsRepositoryProvider)
            .revokeKey(appId: app.id, keyId: key.keyId),
      );
    }

    return AppsPanel(
      seed: 277,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppsSectionHeading(l10n.appsKeysHeading),
          const SizedBox(height: 8),
          if (app.keys.isEmpty)
            Text(
              l10n.appsActiveKeys(0),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.mutedInk,
              ),
            ),
          for (final key in app.keys.reversed)
            _KeyRow(
              appKey: key,
              onRevoke: active && key.revokedAt == null
                  ? () => unawaited(revokeKey(key))
                  : null,
            ),
          if (active) ...[
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: VerilyActionButton(
                key: VerilyTestKeys.appsNewKey,
                label: l10n.appsNewKey,
                tone: VerilyActionTone.secondary,
                expand: false,
                leading: const SkribbleIcon(data: VerilyIcons.key),
                onPressed: canAddKey ? () => unawaited(newKey()) : null,
              ),
            ),
            if (!canAddKey) ...[
              const SizedBox(height: 6),
              Text(
                l10n.appsKeyLimit,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.mutedInk,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({required this.appKey, required this.onRevoke});

  final VerilyAppKeyView appKey;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final revokedAt = appKey.revokedAt;
    final lastUsedAt = appKey.lastUsedAt;
    final usage = switch ((revokedAt, lastUsedAt)) {
      (final revoked?, _) => l10n.appsKeyRevokedOn(appsDateTime(l10n, revoked)),
      (null, final used?) => l10n.appsKeyLastUsed(appsDateTime(l10n, used)),
      (null, null) => l10n.appsKeyNeverUsed,
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Row(
        children: [
          SkribbleIcon(
            data: revokedAt == null ? VerilyIcons.key : VerilyIcons.lock,
            size: 20,
            color: revokedAt == null ? palette.ink : palette.mutedInk,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appKeyLabel(appKey.keyId),
                  style: appsCodeStyle(
                    context,
                    base: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  l10n.appsKeyCreated(appsDateTime(l10n, appKey.createdAt)),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.mutedInk,
                  ),
                ),
                Text(
                  usage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.mutedInk,
                  ),
                ),
              ],
            ),
          ),
          if (onRevoke != null)
            IconButton(
              key: VerilyTestKeys.appsRevokeKey(appKey.keyId),
              tooltip: l10n.appsRevokeKeyTooltip(appKeyLabel(appKey.keyId)),
              onPressed: onRevoke,
              icon: const SkribbleIcon(data: VerilyIcons.delete),
            ),
        ],
      ),
    );
  }
}

class _RevokeAppButton extends ConsumerWidget {
  const _RevokeAppButton({required this.app});

  final VerilyAppView app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    Future<void> revoke() async {
      final confirmed = await confirmAppsDestructiveStep(
        context,
        title: l10n.appsRevokeAppTitle(app.name),
        body: l10n.appsRevokeAppBody,
        confirmLabel: l10n.appsRevokeConfirm,
        confirmKey: VerilyTestKeys.appsRevokeConfirm,
      );
      if (!confirmed || !context.mounted) return;
      await _runAppChange(
        context,
        ref,
        () => ref.read(appsRepositoryProvider).revokeApp(app.id),
      );
    }

    return VerilyActionButton(
      key: VerilyTestKeys.appsRevokeApp,
      label: l10n.appsRevokeApp,
      tone: VerilyActionTone.destructive,
      expand: false,
      leading: const SkribbleIcon(data: VerilyIcons.lock),
      onPressed: () => unawaited(revoke()),
    );
  }
}
