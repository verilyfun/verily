import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_wired_scope.dart';
import 'package:verily_flutter/dev/development_overlay.dart';
import 'package:verily_flutter/dev/skribble_preview_screen.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

void main() {
  Future<void> pumpOverlay(
    WidgetTester tester, {
    List<DevelopmentTool> tools = const [],
    String? serverUrl,
    VoidCallback? onFullReload,
  }) async {
    tester.view.physicalSize = const Size(411, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        theme: buildVerilyTheme(useAppTypeface: false),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => VerilyWiredScope(
          child: DevelopmentOverlay(
            navigatorKey: navigatorKey,
            serverUrl: serverUrl,
            tools: tools,
            onFullReload: onFullReload,
            child: child!,
          ),
        ),
        home: const Scaffold(body: Text('Home')),
      ),
    );
  }

  Future<void> openMenuFromKeyboard(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
  }

  testWidgets('⇧ Ctrl D opens the menu without a server configured', (
    tester,
  ) async {
    await pumpOverlay(tester);
    // Focus a node so the shortcut reaches the overlay.
    await tester.tap(find.text('Home'));
    await openMenuFromKeyboard(tester);

    expect(find.text('Development menu'), findsOneWidget);
    expect(find.text('Not connected in this build'), findsOneWidget);
    expect(find.text('Full reload'), findsOneWidget);
  });

  testWidgets('lists the gallery first, then the app tools, and opens one', (
    tester,
  ) async {
    await pumpOverlay(
      tester,
      serverUrl: 'http://localhost:8180/',
      tools: [
        DevelopmentTool(
          key: const ValueKey('tool-movement'),
          icon: VerilyIcons.run,
          title: 'Movement tracking preview',
          subtitle: 'Try live pose tracking.',
          builder: (context) => const Scaffold(body: Text('Movement tool')),
        ),
      ],
    );
    await tester.tap(find.text('Home'));
    await openMenuFromKeyboard(tester);

    expect(find.text('http://localhost:8180/'), findsOneWidget);
    final gallery = tester.getTopLeft(
      find.byKey(VerilyTestKeys.developerSkribblePreview),
    );
    final movement = tester.getTopLeft(
      find.byKey(const ValueKey('tool-movement')),
    );
    expect(gallery.dy, lessThan(movement.dy));

    await tester.tap(find.byKey(const ValueKey('tool-movement')));
    await tester.pumpAndSettle();
    expect(find.text('Movement tool'), findsOneWidget);
  });

  testWidgets('opens the Skribble gallery and runs a full reload', (
    tester,
  ) async {
    var reloads = 0;
    await pumpOverlay(tester, onFullReload: () => reloads++);
    await tester.tap(find.text('Home'));
    await openMenuFromKeyboard(tester);

    await tester.tap(find.byKey(VerilyTestKeys.developerSkribblePreview));
    // The gallery's loading indicators never settle, so pump past the route
    // transition instead.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(SkribblePreviewScreen), findsOneWidget);

    // The gallery closes from its header.
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(SkribblePreviewScreen), findsNothing);
    await tester.tap(find.text('Full reload'));
    await tester.pumpAndSettle();
    expect(reloads, 1);
    expect(find.text('Development menu'), findsNothing);
  });

  testWidgets('the launcher appears on request and carries a label', (
    tester,
  ) async {
    await pumpOverlay(tester);
    await tester.tap(find.text('Home'));
    await openMenuFromKeyboard(tester);

    await tester.tap(find.text('Show developer icon'));
    await tester.pumpAndSettle();

    expect(find.byKey(VerilyTestKeys.developerMenuLauncher), findsOneWidget);
    expect(find.bySemanticsLabel('Open developer tools'), findsOneWidget);

    await tester.tap(find.byKey(VerilyTestKeys.developerMenuLauncher));
    await tester.pumpAndSettle();
    expect(find.text('Development menu'), findsOneWidget);
  });
}
