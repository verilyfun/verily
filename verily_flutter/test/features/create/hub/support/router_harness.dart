import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_wired_scope.dart';
import 'package:verily_flutter/features/apps/app_screen.dart';
import 'package:verily_flutter/features/apps/apps_screen.dart';
import 'package:verily_flutter/features/create/create_screen.dart';
import 'package:verily_flutter/l10n/l10n.dart';

import '../../../../support/test_app.dart';

/// The Seeker's portrait panel.
const seekerPhysicalSize = Size(1080, 2400);
const seekerPixelRatio = 2.625;

/// Pumps the Create hub and Apps pages behind a real router, with stand-in
/// pages for the destinations they link to, and returns the router.
Future<GoRouter> pumpCreateRoutes(
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

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: VerilyRoutePaths.create,
        name: VerilyRouteNames.create,
        builder: (context, state) => const CreateScreen(),
      ),
      GoRoute(
        path: VerilyRoutePaths.actionNew,
        builder: (context, state) => const Text('editor: new'),
      ),
      GoRoute(
        path: VerilyRoutePaths.action,
        builder: (context, state) =>
            Text('action: ${state.pathParameters['actionId']}'),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) =>
                Text('editor: ${state.pathParameters['actionId']}'),
          ),
        ],
      ),
      GoRoute(
        path: VerilyRoutePaths.appeals,
        builder: (context, state) => const Text('appeals'),
      ),
      GoRoute(
        path: VerilyRoutePaths.apps,
        name: VerilyRouteNames.apps,
        builder: (context, state) => const AppsScreen(),
        routes: [
          GoRoute(
            path: ':appId',
            name: VerilyRouteNames.app,
            builder: (context, state) =>
                AppScreen(appId: state.pathParameters['appId']!),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [...baseTestOverrides(), ...overrides],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
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
