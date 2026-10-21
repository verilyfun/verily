import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon;

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_fitted_text.dart';

/// A page opened on top of the tabs: a title with a way back.
///
/// When the page was opened from a link and has nothing beneath it, the back
/// button goes to [fallbackRouteName] instead of leaving the app.
class PushedPage extends StatelessWidget {
  const PushedPage({
    required this.title,
    required this.body,
    required this.fallbackRouteName,
    super.key,
  });

  final String title;
  final Widget body;
  final String fallbackRouteName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        leading: canPop
            ? null
            : IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => context.goNamed(fallbackRouteName),
                icon: const SkribbleIcon(data: VerilyIcons.back),
              ),
        title: VerilyFittedText(
          title,
          style: theme.textTheme.titleLarge?.copyWith(color: palette.ink),
        ),
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}

/// A section heading inside a page, announced as a heading.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.verily.ink,
        ),
      ),
    );
  }
}
