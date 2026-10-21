import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon;

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/features/apps/widgets/apps_common.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// The action key used in the example when the App confirms no action yet.
const appsExampleActionKey = 'your-action-key';

/// A runnable confirmation request for [confirmationsUrl].
///
/// The key and the participant's link code are shell variables set on the
/// first lines, so the copied example never contains a real secret and runs
/// once those two lines are filled in. The body matches docs/platform.md:
/// `eventId`, `action`, `subject`, `occurredAt`.
String appConfirmationCurlExample({
  required Uri confirmationsUrl,
  String actionKey = appsExampleActionKey,
}) {
  return [
    "VERILY_APP_KEY='vly_<your key>'",
    "VERILY_SUBJECT='vls_<participant link code>'",
    "curl -X POST '$confirmationsUrl' \\",
    r'''  -H "Authorization: Bearer $VERILY_APP_KEY" \''',
    r'''  -H "Verily-Timestamp: $(date +%s)" \''',
    r'''  -H "Content-Type: application/json" \''',
    '  -d "{\\"eventId\\":\\"evt_123\\",\\"action\\":\\"$actionKey\\",\\"subject\\":\\"\$VERILY_SUBJECT\\",\\"occurredAt\\":\\"\$(date -u +%Y-%m-%dT%H:%M:%SZ)\\"}"',
  ].join('\n');
}

/// How an App sends a confirmation, with a copyable example.
class AppIntegrationGuide extends StatelessWidget {
  const AppIntegrationGuide({
    required this.confirmationsUrl,
    this.actionKey,
    super.key,
  });

  final Uri confirmationsUrl;

  /// One of the App's own action keys, when it confirms any.
  final String? actionKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final snippet = appConfirmationCurlExample(
      confirmationsUrl: confirmationsUrl,
      actionKey: actionKey ?? appsExampleActionKey,
    );

    return AppsPanel(
      seed: 257,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppsSectionHeading(l10n.appsGuideHeading),
          const SizedBox(height: 6),
          Text(
            l10n.appsGuideBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.mutedInk,
            ),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: VerilyRoughDecoration(
              color: palette.canvas,
              outline: palette.quietPen,
              radius: VerilyRadius.control,
              strokeWidth: 2,
              seed: 263,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              child: Text(
                snippet,
                key: VerilyTestKeys.appsCurlExample,
                style: appsCodeStyle(context),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.appsGuideResponses,
            style: theme.textTheme.bodySmall?.copyWith(color: palette.mutedInk),
          ),
          const SizedBox(height: 12),
          VerilyActionButton(
            key: VerilyTestKeys.appsCurlCopy,
            label: l10n.appsGuideCopy,
            tone: VerilyActionTone.secondary,
            expand: false,
            leading: const SkribbleIcon(data: VerilyIcons.copy),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: snippet));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.appsGuideCopied)),
              );
            },
          ),
        ],
      ),
    );
  }
}
