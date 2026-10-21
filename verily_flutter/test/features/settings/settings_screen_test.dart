import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/features/settings/settings_screen.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import '../me/support/fakes.dart';
import '../me/support/router_harness.dart';

Future<void> _pumpSettings(
  WidgetTester tester,
  FakeAccountRepository accounts, {
  Size physicalSize = const Size(800, 2400),
  double devicePixelRatio = 1,
}) async {
  await pumpVerilyRoutes(
    tester,
    initialLocation: VerilyRoutePaths.settings,
    physicalSize: physicalSize,
    devicePixelRatio: devicePixelRatio,
    screens: {VerilyRouteNames.settings: const SettingsScreen()},
    overrides: meSliceOverrides(accounts: accounts),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

bool _canClose(WidgetTester tester) => tester
    .widget<FilledButton>(
      find.byKey(VerilyTestKeys.settingsCloseAccountConfirm),
    )
    .enabled;

void main() {
  testWidgets('shows appearance and account controls', (tester) async {
    await _pumpSettings(tester, FakeAccountRepository());

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('How Verily looks, and your account'), findsOneWidget);
    expect(find.byKey(VerilyTestKeys.appearanceSystem), findsOneWidget);
    expect(find.byKey(VerilyTestKeys.settingsSignOut), findsOneWidget);
    expect(find.byKey(VerilyTestKeys.settingsCloseAccount), findsOneWidget);
  });

  testWidgets('signs out only after confirming, then returns to welcome', (
    tester,
  ) async {
    final accounts = FakeAccountRepository();
    await _pumpSettings(tester, accounts);

    await _tapVisible(tester, VerilyTestKeys.settingsSignOut);
    expect(find.text('Sign out of Verily?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(accounts.signOuts, 0);
    expect(find.byKey(routeStandIn(VerilyRouteNames.welcome)), findsNothing);

    await _tapVisible(tester, VerilyTestKeys.settingsSignOut);
    await tester.tap(find.byKey(VerilyTestKeys.settingsSignOutConfirm));
    await tester.pumpAndSettle();

    expect(accounts.signOuts, 1);
    expect(find.byKey(routeStandIn(VerilyRouteNames.welcome)), findsOneWidget);
  });

  testWidgets('closes the account only once DELETE is typed', (tester) async {
    final accounts = FakeAccountRepository();
    await _pumpSettings(tester, accounts);

    await _tapVisible(tester, VerilyTestKeys.settingsCloseAccount);
    expect(find.text('Close your account?'), findsOneWidget);
    expect(_canClose(tester), isFalse);

    final confirmation = find.byKey(
      VerilyTestKeys.settingsCloseAccountConfirmation,
    );
    await tester.enterText(confirmation, 'delete');
    await tester.pump();
    expect(_canClose(tester), isFalse);
    await tester.enterText(confirmation, 'DELETE');
    await tester.pump();
    expect(_canClose(tester), isTrue);

    await tester.tap(find.byKey(VerilyTestKeys.settingsCloseAccountConfirm));
    await tester.pumpAndSettle();

    expect(accounts.closures, ['DELETE']);
    expect(accounts.signOuts, 1);
    expect(find.byKey(routeStandIn(VerilyRouteNames.welcome)), findsOneWidget);
  });

  testWidgets('keeps the account and says so when closing fails', (
    tester,
  ) async {
    final accounts = FakeAccountRepository()
      ..closeError = Exception('server unavailable');
    await _pumpSettings(tester, accounts);

    await _tapVisible(tester, VerilyTestKeys.settingsCloseAccount);
    await tester.enterText(
      find.byKey(VerilyTestKeys.settingsCloseAccountConfirmation),
      'DELETE',
    );
    await tester.pump();
    await tester.tap(find.byKey(VerilyTestKeys.settingsCloseAccountConfirm));
    await tester.pumpAndSettle();

    expect(
      find.text("We couldn't close your account. Try again."),
      findsOneWidget,
    );
    expect(accounts.signOuts, 0);
    expect(find.byKey(routeStandIn(VerilyRouteNames.welcome)), findsNothing);
  });

  testWidgets('fits a Seeker at 1.3x text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpSettings(
      tester,
      FakeAccountRepository(),
      physicalSize: const Size(1080, 2400),
      devicePixelRatio: 2.625,
    );

    expect(tester.takeException(), isNull);
    const width = 1080 / 2.625;
    for (final key in [
      VerilyTestKeys.appearanceDark,
      VerilyTestKeys.settingsSignOut,
      VerilyTestKeys.settingsCloseAccount,
    ]) {
      await tester.ensureVisible(find.byKey(key));
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.byKey(key));
      expect(rect.left, greaterThanOrEqualTo(0), reason: '$key');
      expect(rect.right, lessThanOrEqualTo(width), reason: '$key');
    }

    await tester.tap(find.byKey(VerilyTestKeys.settingsCloseAccount));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
