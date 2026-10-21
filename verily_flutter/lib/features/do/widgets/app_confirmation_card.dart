import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skribble/skribble.dart'
    show SkribbleIcon, WiredLoadingIndicator;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/core/user_message.dart';
import 'package:verily_flutter/features/apps/apps_repository.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// An App-confirmed step: who confirms it, the participant's link code for
/// that App, and whether the App has confirmed yet.
///
/// Verily does not check the act itself here; the App said it happened. The
/// copy says so plainly.
class AppConfirmationCard extends StatelessWidget {
  const AppConfirmationCard({
    required this.requirement,
    required this.confirmed,
    this.pullCheck,
    this.showLinkCode = true,
    super.key,
  });

  final ActionRequirementView requirement;
  final bool confirmed;

  /// "I did it" and its state, when Verily asks this App rather than
  /// waiting for it to confirm on its own.
  final Widget? pullCheck;

  /// Whether to offer the participant's link code. A pull check hides it
  /// once the App has been asked, so the state of the check leads.
  final bool showLinkCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    final appName = requirement.appName ?? l10n.actionAppUnnamed;
    final appId = requirement.appId;
    final available = requirement.appAvailable ?? true;

    return Container(
      key: VerilyTestKeys.actionAppCard(requirement.requirementKey),
      padding: const EdgeInsets.all(16),
      decoration: VerilyRoughDecoration(
        color: palette.surface,
        outline: palette.ink,
        seed: 271,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SkribbleIcon(
                data: confirmed ? VerilyIcons.circleCheck : VerilyIcons.link,
                color: palette.ink,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  confirmed
                      ? l10n.actionAppConfirmed(appName)
                      : l10n.trustConfirmedByApp(appName),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: palette.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            switch ((available, pullCheck)) {
              (false, _) => l10n.actionAppUnavailable(appName),
              (true, null) => l10n.actionAppBody(appName),
              (true, _) => l10n.actionAppPullBody(appName),
            },
            style: theme.textTheme.bodySmall?.copyWith(color: palette.mutedInk),
          ),
          if (pullCheck case final check? when !confirmed) ...[
            const SizedBox(height: 16),
            check,
          ],
          if (available && appId != null && !confirmed && showLinkCode) ...[
            const SizedBox(height: 12),
            VerilyActionButton(
              key: VerilyTestKeys.actionLinkCodeOpen,
              label: l10n.actionLinkCodeShow,
              tone: VerilyActionTone.secondary,
              leading: const SkribbleIcon(data: VerilyIcons.key),
              onPressed: () => unawaited(
                showDialog<void>(
                  context: context,
                  builder: (_) =>
                      _LinkCodeDialog(appId: appId, appName: appName),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LinkCodeDialog extends HookConsumerWidget {
  const _LinkCodeDialog({required this.appId, required this.appName});

  final UuidValue appId;
  final String appName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    final attempts = useState(0);
    final link = useFuture(
      useMemoized(
        () => ref.read(appsRepositoryProvider).linkApp(appId),
        [attempts.value],
      ),
    );
    final copied = useState(false);
    final code = link.data?.subject;
    final error = link.error;
    if (error != null) debugPrint('Link code unavailable: $error');

    return AlertDialog(
      icon: const SkribbleIcon(data: VerilyIcons.key),
      title: Text(l10n.actionLinkCodeTitle(appName)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (error != null)
              Text(userMessageFor(l10n, error))
            else if (code == null)
              Center(child: WiredLoadingIndicator(color: palette.ink))
            else ...[
              Text(l10n.actionLinkCodeBody(appName)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: VerilyRoughDecoration(
                  color: palette.highlight,
                  outline: palette.quietPen,
                  radius: VerilyRadius.control,
                  strokeWidth: 2,
                  seed: 277,
                ),
                child: Text(
                  code,
                  key: VerilyTestKeys.actionLinkCode,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: palette.ink,
                    fontFamily: verilyNumeralFontFamily,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              VerilyActionButton(
                key: VerilyTestKeys.actionLinkCodeCopy,
                label: copied.value
                    ? l10n.actionLinkCodeCopied
                    : l10n.actionLinkCodeCopy,
                tone: VerilyActionTone.secondary,
                leading: SkribbleIcon(
                  data: copied.value ? VerilyIcons.check : VerilyIcons.copy,
                ),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (context.mounted) copied.value = true;
                },
              ),
              const SizedBox(height: 12),
              Text(
                l10n.actionLinkCodePrivacy(appName),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.mutedInk,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (error != null)
          TextButton(
            onPressed: () => attempts.value++,
            child: Text(l10n.dialogRetry),
          ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.dialogDone),
        ),
      ],
    );
  }
}
