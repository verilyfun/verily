import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/features/apps/app_platform_messages.dart';
import 'package:verily_flutter/features/apps/apps_providers.dart';
import 'package:verily_flutter/features/apps/apps_repository.dart';
import 'package:verily_flutter/features/apps/widgets/apps_common.dart';
import 'package:verily_flutter/features/apps/widgets/webhook_settings.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// The exact addresses Verily may send people back to after they link their
/// account or finish a verification for this App.
///
/// Every change replaces the whole list on the server, which validates each
/// address; matching is exact, so the address is shown exactly as saved.
class AppRedirectUrisSettings extends HookConsumerWidget {
  const AppRedirectUrisSettings({required this.app, super.key});

  final VerilyAppView app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final input = useTextEditingController();
    final typed = useValueListenable(input).text.trim();
    final busy = useState(false);
    final problem = useState<String?>(null);
    final uris = app.redirectUris;
    final full = uris.length >= maxAppRedirectUris;

    Future<bool> replace(List<String> next) async {
      busy.value = true;
      problem.value = null;
      try {
        await ref
            .read(appsRepositoryProvider)
            .setRedirectUris(appId: app.id, redirectUris: next);
        return true;
      } on Object catch (error) {
        debugPrint('Changing return addresses failed: $error');
        if (context.mounted) {
          problem.value = appPlatformMessage(l10n, error, appName: app.name);
        }
        return false;
      } finally {
        if (context.mounted) busy.value = false;
        refreshApp(ref, app.id);
      }
    }

    Future<void> add() async {
      if (uris.contains(typed)) {
        problem.value = l10n.appsRedirectDuplicate;
        return;
      }
      if (await replace([...uris, typed]) && context.mounted) input.clear();
    }

    Future<void> remove(String uri) async {
      final confirmed = await confirmAppsDestructiveStep(
        context,
        title: l10n.appsRedirectRemoveTitle,
        body: l10n.appsRedirectRemoveBody(uri),
        confirmLabel: l10n.appsRedirectRemoveConfirm,
        confirmKey: VerilyTestKeys.appsRedirectRemoveConfirm,
      );
      if (!confirmed || !context.mounted) return;
      await replace([
        for (final kept in uris)
          if (kept != uri) kept,
      ]);
    }

    return AppsPanel(
      key: VerilyTestKeys.appsRedirectPanel,
      seed: 283,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppsSectionHeading(l10n.appsRedirectHeading),
          const SizedBox(height: 6),
          Text(
            l10n.appsRedirectBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.mutedInk,
            ),
          ),
          const SizedBox(height: 12),
          if (uris.isEmpty)
            Text(
              l10n.appsRedirectEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(color: palette.ink),
            ),
          for (final uri in uris)
            ConstrainedBox(
              key: VerilyTestKeys.appsRedirectRow(uri),
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  SkribbleIcon(
                    data: VerilyIcons.link,
                    size: 20,
                    color: palette.ink,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      uri,
                      style: appsCodeStyle(
                        context,
                        base: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  IconButton(
                    key: VerilyTestKeys.appsRedirectRemove(uri),
                    tooltip: l10n.appsRedirectRemoveTooltip(uri),
                    onPressed: busy.value ? null : () => unawaited(remove(uri)),
                    icon: const SkribbleIcon(data: VerilyIcons.delete),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            key: VerilyTestKeys.appsRedirectInput,
            controller: input,
            enabled: !busy.value && !full,
            keyboardType: TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            maxLength: 512,
            buildCounter: (
              context, {
              required currentLength,
              required isFocused,
              required maxLength,
            }) => null,
            onSubmitted: typed.isEmpty ? null : (_) => unawaited(add()),
            style: appsCodeStyle(context, base: theme.textTheme.bodyMedium),
            decoration: InputDecoration(
              labelText: l10n.appsRedirectLabel,
              hintText: l10n.appsRedirectHint,
            ),
          ),
          if (problem.value case final message?) ...[
            const SizedBox(height: 8),
            AppSettingsProblem(
              key: VerilyTestKeys.appsRedirectProblem,
              message: message,
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              VerilyActionButton(
                key: VerilyTestKeys.appsRedirectAdd,
                label: l10n.appsRedirectAdd,
                tone: VerilyActionTone.secondary,
                expand: false,
                isLoading: busy.value,
                leading: const SkribbleIcon(data: VerilyIcons.plus),
                onPressed: typed.isEmpty || full || busy.value
                    ? null
                    : () => unawaited(add()),
              ),
              Text(
                full
                    ? l10n.appsRedirectFull(maxAppRedirectUris)
                    : l10n.appsRedirectCount(uris.length, maxAppRedirectUris),
                key: VerilyTestKeys.appsRedirectCount,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.mutedInk,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
