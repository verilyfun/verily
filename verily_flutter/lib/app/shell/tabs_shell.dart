import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:verily_brand/verily_brand.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_navigation_bar.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// The three spaces: Do, Create, and Me.
///
/// A bottom bar on phones and a rail with the mark on wide screens. Each tab
/// keeps its own navigation stack.
class TabsShell extends StatelessWidget {
  const TabsShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// The width from which the rail replaces the bottom bar.
  static const railBreakpoint = 840.0;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).verily;
    final l10n = context.l10n;
    final destinations = [
      VerilyNavigationItem(
        icon: VerilyIcons.bolt,
        label: l10n.tabDo,
        semanticKey: VerilyTestKeys.navigationDo,
      ),
      VerilyNavigationItem(
        icon: VerilyIcons.plus,
        label: l10n.tabCreate,
        semanticKey: VerilyTestKeys.navigationCreate,
      ),
      VerilyNavigationItem(
        icon: VerilyIcons.user,
        label: l10n.tabMe,
        semanticKey: VerilyTestKeys.navigationMe,
      ),
    ];

    void select(int index) => navigationShell.goBranch(
      index,
      // A second tap on the current tab returns to its first page.
      initialLocation: index == navigationShell.currentIndex,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= railBreakpoint;
        return Scaffold(
          backgroundColor: palette.canvas,
          body: useRail
              ? Row(
                  children: [
                    Semantics(
                      container: true,
                      explicitChildNodes: true,
                      role: SemanticsRole.navigation,
                      label: l10n.navigationPrimaryLabel,
                      child: SafeArea(
                        right: false,
                        child: VerilyNavigationRail(
                          selectedIndex: navigationShell.currentIndex,
                          onDestinationSelected: select,
                          destinations: destinations,
                          heading: l10n.navigationRailHeading,
                          compact: constraints.maxWidth < 1180,
                          leading: VerilyMark(
                            size: 40,
                            color: palette.accent,
                            semanticLabel: l10n.appTitle,
                          ),
                        ),
                      ),
                    ),
                    Expanded(child: navigationShell),
                  ],
                )
              : navigationShell,
          bottomNavigationBar: useRail
              ? null
              : VerilyNavigationBar(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: select,
                  destinations: destinations,
                ),
        );
      },
    );
  }
}
