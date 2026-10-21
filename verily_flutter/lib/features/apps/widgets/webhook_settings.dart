import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon, WiredDivider;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/features/apps/app_platform_messages.dart';
import 'package:verily_flutter/features/apps/apps_providers.dart';
import 'package:verily_flutter/features/apps/apps_repository.dart';
import 'package:verily_flutter/features/apps/widgets/app_key_dialog.dart';
import 'package:verily_flutter/features/apps/widgets/apps_common.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// Where the App hears from Verily: its webhook address and the secret that
/// signs every call.
///
/// The server decides what address is acceptable (https on the standard
/// port, a public host); the field only catches what is plainly not an
/// https address before asking, and explains a refusal in the same words.
class AppWebhookSettings extends HookConsumerWidget {
  const AppWebhookSettings({required this.app, super.key});

  final VerilyAppView app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final saved = app.webhookUrl;
    final url = useTextEditingController(text: saved ?? '');
    useEffect(() {
      // A refreshed App replaces what was typed only once it was saved.
      if (url.text != (saved ?? '')) url.text = saved ?? '';
      return null;
    }, [saved]);
    final value = useValueListenable(url).text.trim();
    final busy = useState<_WebhookStep?>(null);
    final problem = useState<String?>(null);
    final hasSecret = app.webhookSecretVersion > 0;

    Future<void> run(_WebhookStep step, Future<void> Function() change) async {
      busy.value = step;
      problem.value = null;
      try {
        await change();
      } on Object catch (error) {
        debugPrint('Changing the webhook failed: $error');
        if (context.mounted) {
          problem.value = appPlatformMessage(l10n, error, appName: app.name);
        }
      } finally {
        if (context.mounted) busy.value = null;
        refreshApp(ref, app.id);
      }
    }

    Future<void> save() => run(_WebhookStep.save, () async {
      if (!_looksLikeHttps(value)) {
        problem.value = l10n.appsWebhookInvalid;
        return;
      }
      await ref
          .read(appsRepositoryProvider)
          .setWebhookUrl(appId: app.id, webhookUrl: value);
      if (context.mounted) _say(context, l10n.appsWebhookSaved);
    });

    Future<void> remove() => run(_WebhookStep.remove, () async {
      await ref
          .read(appsRepositoryProvider)
          .setWebhookUrl(appId: app.id, webhookUrl: null);
      if (context.mounted) _say(context, l10n.appsWebhookRemoved);
    });

    Future<void> rotate() async {
      VerilyAppWebhookSecret? issued;
      await run(_WebhookStep.rotate, () async {
        issued = await ref
            .read(appsRepositoryProvider)
            .rotateWebhookSecret(app.id);
      });
      // Shown after the button settles, so nothing behind the dialog spins.
      if (issued case final secret? when context.mounted) {
        await showWebhookSecretOnce(context, appName: app.name, secret: secret);
      }
    }

    final working = busy.value != null;
    final canSave = !working && value.isNotEmpty && value != saved;

    return AppsPanel(
      key: VerilyTestKeys.appsWebhookPanel,
      seed: 281,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppsSectionHeading(l10n.appsWebhookHeading),
          const SizedBox(height: 6),
          Text(
            l10n.appsWebhookBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.mutedInk,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: VerilyTestKeys.appsWebhookUrl,
            controller: url,
            enabled: !working,
            keyboardType: TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            // Long addresses wrap so the saved one can be read in full.
            minLines: 1,
            maxLines: 3,
            maxLength: 2048,
            buildCounter: _noCounter,
            onSubmitted: canSave ? (_) => unawaited(save()) : null,
            style: appsCodeStyle(context, base: theme.textTheme.bodyMedium),
            decoration: InputDecoration(
              labelText: l10n.appsWebhookLabel,
              hintText: l10n.appsWebhookHint,
            ),
          ),
          if (problem.value case final message?) ...[
            const SizedBox(height: 8),
            AppSettingsProblem(
              key: VerilyTestKeys.appsWebhookProblem,
              message: message,
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              VerilyActionButton(
                key: VerilyTestKeys.appsWebhookSave,
                label: l10n.appsWebhookSave,
                tone: VerilyActionTone.secondary,
                expand: false,
                isLoading: busy.value == _WebhookStep.save,
                leading: const SkribbleIcon(data: VerilyIcons.check),
                onPressed: canSave ? () => unawaited(save()) : null,
              ),
              if (saved != null)
                TextButton.icon(
                  key: VerilyTestKeys.appsWebhookRemove,
                  icon: const SkribbleIcon(data: VerilyIcons.delete, size: 20),
                  label: Text(l10n.appsWebhookRemove),
                  onPressed: working ? null : () => unawaited(remove()),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const ExcludeSemantics(child: WiredDivider()),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkribbleIcon(
                data: hasSecret ? VerilyIcons.lock : VerilyIcons.unlock,
                color: palette.ink,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasSecret
                          ? l10n.appsSecretVersion(app.webhookSecretVersion)
                          : l10n.appsSecretNone,
                      key: VerilyTestKeys.appsSecretStatus,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasSecret ? l10n.appsSecretHelp : l10n.appsSecretNoneHelp,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.mutedInk,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: VerilyActionButton(
              key: VerilyTestKeys.appsSecretRotate,
              label: hasSecret ? l10n.appsSecretRotate : l10n.appsSecretIssue,
              tone: VerilyActionTone.secondary,
              expand: false,
              isLoading: busy.value == _WebhookStep.rotate,
              leading: SkribbleIcon(
                data: hasSecret ? VerilyIcons.refresh : VerilyIcons.key,
              ),
              onPressed: working ? null : () => unawaited(rotate()),
            ),
          ),
          if (saved == null || !hasSecret) ...[
            const SizedBox(height: 12),
            Text(
              l10n.appsWebhookNotSending,
              key: VerilyTestKeys.appsWebhookNotSending,
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.mutedInk,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _WebhookStep { save, remove, rotate }

/// Whether [value] could be an https address with a host. The server's
/// check is the real one; this only saves a round trip for plain typos.
bool _looksLikeHttps(String value) {
  final uri = Uri.tryParse(value);
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
}

Widget? _noCounter(
  BuildContext context, {
  required int currentLength,
  required bool isFocused,
  required int? maxLength,
}) => null;

void _say(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// A refusal under a field, in words and with an icon, never colour alone.
class AppSettingsProblem extends StatelessWidget {
  const AppSettingsProblem({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkribbleIcon(data: VerilyIcons.warning, size: 18, color: palette.ink),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: palette.ink),
            ),
          ),
        ],
      ),
    );
  }
}
