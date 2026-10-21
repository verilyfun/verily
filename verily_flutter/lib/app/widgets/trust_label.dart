import 'package:flutter/material.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/features/actions/action_labels.dart';
import 'package:verily_flutter/l10n/l10n.dart';

/// Who vouches for an action: "Verified on your phone" (Verily captured and
/// checked the proof) or "Confirmed by" and the App's name (the App said it happened;
/// Verily does not check the act itself).
///
/// The two read differently on purpose: the shield for Verily's own checks,
/// the link for an App's word.
class TrustLabel extends StatelessWidget {
  const TrustLabel({required this.action, super.key});

  final ActionOpportunity action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    final appName = confirmingAppName(action);
    final label = appName == null
        ? l10n.trustVerifiedOnPhone
        : l10n.trustConfirmedByApp(appName);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SkribbleIcon(
          data: appName == null ? VerilyIcons.shieldCheck : VerilyIcons.link,
          size: 18,
          color: palette.mutedInk,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: palette.mutedInk,
            ),
          ),
        ),
      ],
    );
  }
}
