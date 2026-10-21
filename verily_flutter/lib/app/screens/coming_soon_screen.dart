import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_app_header.dart';
import 'package:verily_flutter/app/widgets/verily_state_panel.dart';
import 'package:verily_flutter/l10n/l10n.dart';

/// What a deep link opened that the app cannot do yet.
enum ComingSoonKind {
  /// `/r/<requestId>`: another app asked for verified proof.
  verificationRequest,

  /// `/link`: another app asked to link with this account.
  appLink,
}

/// A friendly landing page for deep links whose server side is not built yet.
///
/// It says plainly what was asked, that nothing was captured or shared, and
/// offers the way back into the app.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({required this.kind, super.key});

  final ComingSoonKind kind;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).verily;
    final l10n = context.l10n;
    final (title, body) = switch (kind) {
      ComingSoonKind.verificationRequest => (
        l10n.comingSoonVerificationTitle,
        l10n.comingSoonVerificationBody,
      ),
      ComingSoonKind.appLink => (
        l10n.comingSoonLinkTitle,
        l10n.comingSoonLinkBody,
      ),
    };

    return Scaffold(
      backgroundColor: palette.canvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VerilyAppHeader(title: l10n.appTitle),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  VerilyStatePanel.empty(
                    title: title,
                    message: body,
                    action: VerilyStateAction(
                      label: l10n.comingSoonGoToDo,
                      onPressed: () => context.goNamed(VerilyRouteNames.doTab),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
