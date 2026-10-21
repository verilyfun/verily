import 'package:flutter/material.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/features/create/editor/editor_form.dart';
import 'package:verily_flutter/features/create/editor/widgets/editor_common.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// How the chosen App confirms an App-confirmed proof: it tells Verily on its
/// own (push), or Verily asks its webhook when the participant taps "I did
/// it" (pull).
///
/// Pull needs a webhook URL on the App, so the field says so when the chosen
/// App has none. The server refuses the check at that point; the warning
/// only saves the creator a confusing first attempt.
class AppVerificationModeField extends StatelessWidget {
  const AppVerificationModeField({
    required this.form,
    required this.requirement,
    required this.appName,
    this.app,
    super.key,
  });

  final EditorForm form;
  final RequirementForm requirement;
  final String appName;

  /// The chosen App as the server last described it, when loaded.
  final VerilyAppView? app;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final mode = requirement.appVerificationMode;
    final needsWebhook =
        mode == AppVerificationMode.pull &&
        app != null &&
        app!.webhookUrl == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorChoices<AppVerificationMode>(
          label: l10n.editorAppModeLabel(appName),
          values: AppVerificationMode.values,
          selected: mode,
          nameOf: (value) => switch (value) {
            AppVerificationMode.push => l10n.editorAppModePush,
            AppVerificationMode.pull => l10n.editorAppModePull,
          },
          keyOf: (value) => VerilyTestKeys.editorAppMode(
            requirement.requirementKey,
            value.name,
          ),
          onSelected: (value) {
            requirement.appVerificationMode = value;
            form.touch();
          },
        ),
        const SizedBox(height: 8),
        // Plain words under the choice, so the warning below is the only
        // note that stands out.
        Text(
          switch (mode) {
            AppVerificationMode.push => l10n.editorAppModePushBody(appName),
            AppVerificationMode.pull => l10n.editorAppModePullBody(appName),
          },
          style: theme.textTheme.bodySmall?.copyWith(color: palette.mutedInk),
        ),
        if (needsWebhook) ...[
          const SizedBox(height: editorStackGap),
          EditorNote(
            key: VerilyTestKeys.editorAppModeNeedsWebhook,
            text: l10n.editorAppModePullNeedsWebhook(appName),
            icon: VerilyIcons.warning,
          ),
        ],
      ],
    );
  }
}
