import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon;
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
/// The dialog ignores taps outside it and the system Back gesture; only
/// "I've saved it" closes it.
Future<void> showAppKeyOnce(
  BuildContext context,
  VerilyAppCredential credential,
) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => PopScope(
    canPop: false,
    child: _AppKeyDialog(credential: credential),
  ),
);

class _AppKeyDialog extends HookWidget {
  const _AppKeyDialog({required this.credential});

  final VerilyAppCredential credential;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final copied = useState(false);
    final key = appBearerKey(credential);

    return AlertDialog(
      semanticLabel: l10n.appsKeyTitle,
      icon: SkribbleIcon(data: VerilyIcons.key, color: palette.ink),
      title: Text(l10n.appsKeyTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.appsKeyBody(credential.app.name),
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
                        child: Text(
                          l10n.appsKeyWarning,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: palette.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.appsKeyLabel,
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
                    key,
                    key: VerilyTestKeys.appsKeyValue,
                    style: appsCodeStyle(context),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              VerilyActionButton(
                key: VerilyTestKeys.appsKeyCopy,
                label: copied.value ? l10n.appsKeyCopied : l10n.appsKeyCopy,
                tone: VerilyActionTone.secondary,
                expand: false,
                leading: SkribbleIcon(
                  data: copied.value ? VerilyIcons.check : VerilyIcons.copy,
                ),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: key));
                  copied.value = true;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        VerilyActionButton(
          key: VerilyTestKeys.appsKeySaved,
          label: l10n.appsKeySaved,
          expand: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
