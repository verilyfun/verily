import 'package:flutter/material.dart';

import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_fitted_text.dart';

/// The header that names a workspace by its task.
///
/// Each page is titled with what the person is doing there, such as "Choose
/// an action" or "Your proof", with a quiet breadcrumb beneath it. The Verily
/// mark belongs to entry and brand moments, so it is not repeated in every
/// header.
class VerilyAppHeader extends StatelessWidget {
  const VerilyAppHeader({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.bottom,
    super.key,
  });

  final String title;

  /// A short breadcrumb such as "Your actions · Drafts".
  final String? subtitle;

  /// The way back from a page pushed over the tabs, before the title where
  /// people look for it.
  final Widget? leading;

  /// One action for the page, such as closing a flow or opening settings.
  final Widget? trailing;

  /// Content that belongs to the header, such as step progress.
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final wide = MediaQuery.sizeOf(context).width >= 600;
    // The 16dp page gutter, wider on tablets and browsers.
    final gutter = wide ? 24.0 : 16.0;

    return Material(
      color: palette.canvas,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (leading case final back?) ...[
                    // Pulls the 48dp button's padding into the gutter so its
                    // glyph lines up with the content below.
                    Transform.translate(
                      offset: const Offset(-8, 0),
                      child: back,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // The page's one level-one heading; sections and
                        // steps inside the page start at level two.
                        // One line that shrinks to fit, so a long title on a
                        // small phone is never wrapped mid-phrase or cut off.
                        Semantics(
                          headingLevel: 1,
                          child: VerilyFittedText(
                            title,
                            style:
                                (wide
                                        ? theme.textTheme.headlineMedium
                                        : theme.textTheme.headlineSmall)
                                    ?.copyWith(color: palette.ink),
                          ),
                        ),
                        if (subtitle case final line?) ...[
                          const SizedBox(height: 2),
                          Text(
                            line,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: palette.mutedInk,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing case final action?) ...[
                    const SizedBox(width: 12),
                    action,
                  ],
                ],
              ),
              if (bottom case final footer?) ...[
                const SizedBox(height: 16),
                footer,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
