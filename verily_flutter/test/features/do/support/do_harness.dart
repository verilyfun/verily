import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_wired_scope.dart';
import 'package:verily_flutter/core/provider_retry.dart';
import 'package:verily_flutter/features/do/action_screen.dart';
import 'package:verily_flutter/features/do/do_screen.dart';
import 'package:verily_flutter/l10n/l10n.dart';

import '../../../support/test_app.dart';

/// The Seeker's portrait panel.
const seekerPhysicalSize = Size(1080, 2400);
const seekerPixelRatio = 2.625;

/// Pumps the Do tab and the action page behind a real router, with stand-in
/// pages for the places they link to, and returns the router.
Future<GoRouter> pumpDoRoutes(
  WidgetTester tester, {
  required String initialLocation,
  List<Override> overrides = const [],
  Brightness brightness = Brightness.light,
  Size physicalSize = const Size(800, 2000),
  double devicePixelRatio = 1,
  double textScale = 1,
  bool useAppTypeface = false,
}) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = devicePixelRatio;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  Widget standIn(String label) => Scaffold(body: Center(child: Text(label)));

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: VerilyRoutePaths.doTab,
        name: VerilyRouteNames.doTab,
        // The shell gives the tab its Scaffold in the app.
        builder: (context, state) => const Scaffold(body: DoScreen()),
      ),
      GoRoute(
        path: VerilyRoutePaths.actionNew,
        builder: (context, state) => standIn('editor: new'),
      ),
      GoRoute(
        path: VerilyRoutePaths.action,
        name: VerilyRouteNames.action,
        builder: (context, state) =>
            ActionScreen(actionId: state.pathParameters['actionId']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) =>
                standIn('editor: ${state.pathParameters['actionId']}'),
          ),
        ],
      ),
      GoRoute(
        path: VerilyRoutePaths.me,
        builder: (context, state) => standIn('me'),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      // As in main.dart: failures stay visible behind an explicit retry.
      retry: noAutomaticProviderRetry,
      overrides: [...baseTestOverrides(), ...overrides],
      child: MaterialApp.router(
        theme: buildVerilyTheme(
          brightness: brightness,
          useAppTypeface: useAppTypeface,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, page) => VerilyWiredScope(child: page!),
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  return router;
}

/// Lets the page's futures settle without waiting on animations that never
/// end (loading indicators, the stamp's settle).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
