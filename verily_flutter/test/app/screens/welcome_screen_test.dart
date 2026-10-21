import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/app/screens/welcome_screen.dart';
import 'package:verily_flutter/features/account/account_session.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import '../../features/me/support/router_harness.dart';
import '../../support/test_app.dart';

const _signedOut = AccountSession.signedOut();

void main() {
  testWidgets('says what Verily is and the three-part promise', (
    tester,
  ) async {
    await pumpVerilyPage(tester, const WelcomeScreen(), session: _signedOut);

    expect(find.text('Do it. Prove it. Get paid.'), findsOneWidget);
    expect(find.text('Every action is a small promise'), findsOneWidget);
    expect(find.text('A place'), findsOneWidget);
    expect(find.text('Proof, captured live'), findsOneWidget);
    expect(find.text('A reward, locked first'), findsOneWidget);
    expect(find.byKey(VerilyTestKeys.welcomeGetStarted), findsOneWidget);
    expect(find.byKey(VerilyTestKeys.welcomeHaveAccount), findsOneWidget);
  });

  for (final (label, key, returning) in [
    ('Get started', VerilyTestKeys.welcomeGetStarted, false),
    ('I already have an account', VerilyTestKeys.welcomeHaveAccount, true),
  ]) {
    testWidgets('"$label" opens sign-in and comes back to Do', (tester) async {
      final router = await pumpVerilyRoutes(
        tester,
        initialLocation: VerilyRoutePaths.welcome,
        session: _signedOut,
        screens: {VerilyRouteNames.welcome: const WelcomeScreen()},
      );

      await tester.ensureVisible(find.byKey(key));
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();

      expect(find.byKey(routeStandIn(VerilyRouteNames.signIn)), findsOneWidget);
      expect(
        currentLocation(router),
        VerilyLocations.signIn(
          from: VerilyRoutePaths.doTab,
          returning: returning,
        ),
      );
    });
  }

  testWidgets('fits a Seeker at 1.3x text with both choices in reach', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpVerilyPage(
      tester,
      const WelcomeScreen(),
      session: _signedOut,
      physicalSize: const Size(1080, 2400),
      devicePixelRatio: 2.625,
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    const width = 1080 / 2.625;
    for (final key in [
      VerilyTestKeys.welcomeGetStarted,
      VerilyTestKeys.welcomeHaveAccount,
    ]) {
      await tester.ensureVisible(find.byKey(key));
      await tester.pump();
      final rect = tester.getRect(find.byKey(key));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(width));
      expect(rect.height, greaterThanOrEqualTo(48));
    }
    expect(
      tester.getRect(find.text('Do it. Prove it. Get paid.')).right,
      lessThanOrEqualTo(width),
    );
  });
}
