import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_wired_scope.dart';
import 'package:verily_flutter/features/create/editor/action_editor_screen.dart';
import 'package:verily_flutter/l10n/l10n.dart';

import '../../../../support/test_app.dart';
import 'fakes.dart';

/// The key of the stand-in participant page the editor opens.
ValueKey<String> participantPageFor(String actionId) =>
    ValueKey<String>('participant-page-$actionId');

/// Pumps the editor under a real [GoRouter] with the editor's routes, so
/// preview and publish navigation can be asserted. The participant page is a
/// keyed stand-in.
Future<GoRouter> pumpEditor(
  WidgetTester tester,
  EditorFakes fakes, {
  String initialLocation = VerilyRoutePaths.actionNew,
  Size? physicalSize,
  double devicePixelRatio = 1,
  Brightness brightness = Brightness.light,
}) async {
  // A tall phone, so most of the form is laid out without scrolling.
  tester.view.physicalSize = physicalSize ?? const Size(1080, 2400);
  tester.view.devicePixelRatio = physicalSize == null
      ? 2.625
      : devicePixelRatio;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: VerilyRoutePaths.create,
        name: VerilyRouteNames.create,
        builder: (context, state) => const Scaffold(body: Text('create')),
      ),
      GoRoute(
        path: VerilyRoutePaths.actionNew,
        name: VerilyRouteNames.actionNew,
        builder: (context, state) => const ActionEditorScreen(),
      ),
      GoRoute(
        path: VerilyRoutePaths.action,
        name: VerilyRouteNames.action,
        builder: (context, state) {
          final id = state.pathParameters['actionId']!;
          return Scaffold(
            key: participantPageFor(id),
            body: Text('participant $id'),
          );
        },
        routes: [
          GoRoute(
            path: 'edit',
            name: VerilyRouteNames.actionEdit,
            builder: (context, state) => ActionEditorScreen(
              actionId: state.pathParameters['actionId'],
            ),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [...baseTestOverrides(), ...fakes.overrides],
      child: MaterialApp.router(
        theme: buildVerilyTheme(brightness: brightness),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, page) => VerilyWiredScope(child: page!),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

/// Brings [finder] on screen in the editor's scroll view and taps it.
Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Scrolls [finder] into view and types [text] into it.
Future<void> scrollAndEnter(
  WidgetTester tester,
  Finder finder,
  String text,
) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}
