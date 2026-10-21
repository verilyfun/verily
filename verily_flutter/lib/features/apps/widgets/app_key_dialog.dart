import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon, WiredSvgIconData;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/features/apps/apps_providers.dart';
import 'package:verily_flutter/features/apps/widgets/apps_common.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// Shows a newly issued App key exactly once.
///
/// Verily keeps only the key's hash, so this is the one chance to save it.
Future<void> showAppKeyOnce(
  BuildContext context,
  VerilyAppCredential credential,
) {
  final l10n = context.l10n;
  return _showSecretOnce(
    context,
    _SecretDialog(
      icon: VerilyIcons.key,
      title: l10n.appsKeyTitle,
      body: l10n.appsKeyBody(credential.app.name),
      warning: l10n.appsKeyWarning,
      label: l10n.appsKeyLabel,
      secret: appBearerKey(credential),
      copyLabel: l10n.appsKeyCopy,
      valueKey: VerilyTestKeys.appsKeyValue,
      copyKey: VerilyTestKeys.appsKeyCopy,
      savedKey: VerilyTestKeys.appsKeySaved,
    ),
  );
}

/// Shows a newly issued webhook signing secret exactly once.
///
/// The server derives secrets rather than storing them and never shows one
/// again, so this is the one chance to save it. When an older secret is still
/// signing, the dialog says until when, so the App can switch over without
/// missing a delivery.
Future<void> showWebhookSecretOnce(
  BuildContext context, {
  required String appName,
  required VerilyAppWebhookSecret secret,
}) {
  final l10n = context.l10n;
  final previousUntil = secret.previousSecretValidUntil;
  return _showSecretOnce(
    context,
    _SecretDialog(
      icon: VerilyIcons.lock,
      title: l10n.appsSecretTitle,
      body: l10n.appsSecretBody(appName),
      warning: l10n.appsSecretWarning,
      note: previousUntil == null
          ? null
          : l10n.appsSecretOverlap(appsDateTime(l10n, previousUntil)),
      label: l10n.appsSecretLabel(secret.version),
      secret: secret.secret,
      copyLabel: l10n.appsSecretCopy,
      valueKey: VerilyTestKeys.appsSecretValue,
      copyKey: VerilyTestKeys.appsSecretCopy,
      savedKey: VerilyTestKeys.appsSecretSaved,
    ),
  );
}

/// The dialog ignores taps outside it and the system Back gesture; only
/// "I've saved it" closes it.
Future<void> _showSecretOnce(BuildContext context, Widget dialog) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(canPop: false, child: dialog),
    );

class _SecretDialog extends HookWidget {
  const _SecretDialog({
    required this.icon,
    required this.title,
    required this.body,
    required this.warning,
    required this.label,
    required this.secret,
    required this.copyLabel,
    required this.valueKey,
    required this.copyKey,
    required this.savedKey,
    this.note,
  });

  final WiredSvgIconData icon;
  final String title;
  final String body;
  final String warning;

  /// A further line under the warning, such as how long an old secret lasts.
  final String? note;
  final String label;
  final String secret;
  final String copyLabel;
  final Key valueKey;
  final Key copyKey;
  final Key savedKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final copied = useState(false);

    return AlertDialog(
      semanticLabel: title,
      icon: SkribbleIcon(data: icon, color: palette.ink),
      title: Text(title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: VerilyRoughDecoration(
                  color: palette.highlight,
                  outline: palette.ink,
                  radius: VerilyRadius.control,
                  strokeWidth: 2,
                  seed: 251,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkribbleIcon(
                        data: VerilyIcons.warning,
                        color: palette.ink,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              warning,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: palette.ink,
                              ),
                            ),
                            if (note case final line?) ...[
                              const SizedBox(height: 6),
                              Text(
                                line,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: palette.ink,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 6),
              DecoratedBox(
                decoration: VerilyRoughDecoration(
                  color: palette.surface,
                  outline: palette.quietPen,
                  radius: VerilyRadius.control,
                  strokeWidth: 2,
                  seed: 253,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    secret,
                    key: valueKey,
                    style: appsCodeStyle(context),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              VerilyActionButton(
                key: copyKey,
                label: copied.value ? l10n.appsKeyCopied : copyLabel,
                tone: VerilyActionTone.secondary,
                expand: false,
                leading: SkribbleIcon(
                  data: copied.value ? VerilyIcons.check : VerilyIcons.copy,
                ),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: secret));
                  copied.value = true;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        VerilyActionButton(
          key: savedKey,
          label: l10n.appsKeySaved,
          expand: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
