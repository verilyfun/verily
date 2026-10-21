import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_wired_scope.dart';
import 'package:verily_flutter/features/account/account_session.dart';
import 'package:verily_flutter/l10n/l10n.dart';

import '../../../support/test_app.dart';

/// The routes the Me slice navigates between, by name.
const _routes = <String, String>{
  VerilyRouteNames.welcome: VerilyRoutePaths.welcome,
  VerilyRouteNames.signIn: VerilyRoutePaths.signIn,
  VerilyRouteNames.doTab: VerilyRoutePaths.doTab,
  VerilyRouteNames.me: VerilyRoutePaths.me,
  VerilyRouteNames.settings: VerilyRoutePaths.settings,
  VerilyRouteNames.reviews: VerilyRoutePaths.reviews,
  VerilyRouteNames.appeals: VerilyRoutePaths.appeals,
  VerilyRouteNames.action: VerilyRoutePaths.action,
};

/// The key of the stand-in page for a route the test did not provide.
ValueKey<String> routeStandIn(String routeName) =>
    ValueKey<String>('route-stand-in-$routeName');

/// Pumps a real [GoRouter] over the Me slice's routes so navigation can be
/// asserted. Routes missing from [screens] render a keyed stand-in.
Future<GoRouter> pumpVerilyRoutes(
  WidgetTester tester, {
  required String initialLocation,
  required Map<String, Widget> screens,
  List<Override> overrides = const [],
  AccountSession? session,
  Size? physicalSize,
  double devicePixelRatio = 1,
}) async {
  if (physicalSize != null) {
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = devicePixelRatio;
    addTearDown(tester.view.reset);
  }
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      for (final MapEntry(key: name, value: path) in _routes.entries)
        GoRoute(
          name: name,
          path: path,
          builder: (context, state) =>
              screens[name] ??
              Scaffold(
                key: routeStandIn(name),
                body: Text(state.uri.toString()),
              ),
        ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...baseTestOverrides(session: session),
        ...overrides,
      ],
      child: MaterialApp.router(
        theme: buildVerilyTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, page) => VerilyWiredScope(child: page!),
        routerConfig: router,
      ),
    ),
  );
  return router;
}

/// The location the router is showing.
String currentLocation(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.toString();
