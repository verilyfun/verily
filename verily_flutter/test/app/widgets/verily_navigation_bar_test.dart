import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon;

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_navigation_bar.dart';

import '../../support/skribble_finders.dart';

void main() {
  testWidgets('names every destination and keeps each one tappable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final selections = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerilyTheme(useAppTypeface: false),
        home: Scaffold(
          bottomNavigationBar: VerilyNavigationBar(
            selectedIndex: 0,
            onDestinationSelected: selections.add,
            destinations: _destinations,
          ),
        ),
      ),
    );

    for (final destination in _destinations) {
      expect(find.text(destination.label), findsOneWidget);

      final finder = find.byKey(destination.semanticKey);
      expect(finder, findsOneWidget);
      expect(tester.getSize(finder).height, greaterThanOrEqualTo(44));

      final semantics = tester.widget<Semantics>(finder);
      expect(semantics.properties.label, destination.label);
      expect(semantics.properties.role, SemanticsRole.tab);
    }

    await tester.tap(find.byKey(_proofKey));
    expect(selections, [2]);
  });

  testWidgets('marks the selected destination with more than colour', (
    tester,
  ) async {
    final theme = buildVerilyTheme(useAppTypeface: false);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          bottomNavigationBar: VerilyNavigationBar(
            selectedIndex: 3,
            onDestinationSelected: (_) {},
            destinations: _destinations,
          ),
        ),
      ),
    );

    expect(
      tester.widget<Semantics>(find.byKey(_createKey)).properties.selected,
      isTrue,
    );
    expect(
      tester.widget<Semantics>(find.byKey(_findKey)).properties.selected,
      isFalse,
    );

    // The wash, its pen outline, and a heavier icon pen mark the selection.
    final pill = tester.widget<AnimatedContainer>(
      find.ancestor(
        of: findSkribbleIcon(VerilyIcons.plus),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final marker = pill.decoration! as VerilyRoughDecoration;
    expect(marker.color, theme.verily.highlight);
    expect(marker.outline, theme.verily.firmPen);
    expect(
      tester.widget<SkribbleIcon>(findSkribbleIcon(VerilyIcons.plus)).weight,
      600,
    );
    expect(
      tester.widget<SkribbleIcon>(findSkribbleIcon(VerilyIcons.explore)).weight,
      400,
    );
  });

  testWidgets('keeps every label on one line with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerilyTheme(useAppTypeface: false),
        home: Scaffold(
          bottomNavigationBar: VerilyNavigationBar(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            destinations: _destinations,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('the rail names each space beside its icon', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final selections = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerilyTheme(useAppTypeface: false),
        home: Scaffold(
          body: Row(
            children: [
              VerilyNavigationRail(
                heading: 'Your spaces',
                selectedIndex: 1,
                onDestinationSelected: selections.add,
                destinations: _destinations,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Your spaces'), findsOneWidget);
    final icon = tester.getRect(findSkribbleIcon(VerilyIcons.bolt));
    final label = tester.getRect(find.text('Do'));
    expect(label.left, greaterThan(icon.right));
    await tester.tap(find.byKey(_findKey));
    expect(selections, [0]);
  });
}

const _findKey = ValueKey<String>('navigation-find');
const _doKey = ValueKey<String>('navigation-do');
const _proofKey = ValueKey<String>('navigation-proof');
const _createKey = ValueKey<String>('navigation-create');

const _destinations = [
  VerilyNavigationItem(
    icon: VerilyIcons.explore,
    label: 'Find',
    semanticKey: _findKey,
  ),
  VerilyNavigationItem(
    icon: VerilyIcons.bolt,
    label: 'Do',
    semanticKey: _doKey,
  ),
  VerilyNavigationItem(
    icon: VerilyIcons.verified,
    label: 'Proof',
    semanticKey: _proofKey,
  ),
  VerilyNavigationItem(
    icon: VerilyIcons.plus,
    label: 'Create',
    semanticKey: _createKey,
  ),
];
