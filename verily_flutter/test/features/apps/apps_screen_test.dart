import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/actions/action_repository.dart';
import 'package:verily_flutter/features/apps/app_screen.dart';
import 'package:verily_flutter/features/apps/apps_repository.dart';
import 'package:verily_flutter/features/apps/apps_screen.dart';
import 'package:verily_flutter/l10n/generated/app_localizations_en.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import '../create/hub/support/fakes.dart';
import '../create/hub/support/router_harness.dart';
import 'support/clipboard.dart';
import 'support/fakes.dart';

void main() {
  late FakeAppsRepository apps;
  late ClipboardRecorder clipboard;

  setUp(() {
    apps = FakeAppsRepository();
    clipboard = ClipboardRecorder();
  });

  Future<void> pumpApps(WidgetTester tester) async {
    clipboard.install(tester);
    await pumpCreateRoutes(
      tester,
      initialLocation: '/apps',
      overrides: [
        appsRepositoryProvider.overrideWithValue(apps),
        actionRepositoryProvider.overrideWithValue(FakeHubActionRepository()),
      ],
    );
    await tester.pumpAndSettle();
  }

  group('validation', () {
    final l10n = AppLocalizationsEn();

    test('a name is required and at most 80 characters', () {
      expect(validateAppName(l10n, '   '), l10n.appsNameRequired);
      expect(validateAppName(l10n, 'a' * 81), l10n.appsNameTooLong);
      expect(validateAppName(l10n, 'Sunrise Run Club'), isNull);
    });

    test('a website is optional but must be a plain https address', () {
      expect(validateAppWebsite(l10n, ''), isNull);
      expect(validateAppWebsite(l10n, 'https://club.example'), isNull);
      for (final invalid in [
        'http://club.example',
        'club.example',
        'https://user@club.example',
        'https://club.example/#top',
        'https://${'a' * 200}.example',
      ]) {
        expect(validateAppWebsite(l10n, invalid), l10n.appsWebsiteInvalid);
      }
    });
  });

  testWidgets('lists each App with its status, actions, and keys', (
    tester,
  ) async {
    apps.apps = [
      fixtureApp(boundActionCount: 3),
      fixtureApp(index: 2, name: 'Old Kiosk', status: VerilyAppStatus.revoked),
    ];
    await pumpApps(tester);

    expect(find.text('Sunrise Run Club'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('3 actions use it'), findsOneWidget);
    expect(find.text('Old Kiosk'), findsOneWidget);
    expect(find.text('Revoked'), findsOneWidget);
  });

  testWidgets('opens an App from the list', (tester) async {
    await pumpApps(tester);

    await tester.tap(
      find.byKey(VerilyTestKeys.appsCard('${apps.apps.first.id}')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppScreen), findsOneWidget);
    expect(find.text('Keys'), findsOneWidget);
  });

  testWidgets('checks the form before registering', (tester) async {
    await pumpApps(tester);

    await tester.tap(find.byKey(VerilyTestKeys.appsRegister));
    await tester.pumpAndSettle();
    expect(find.text('Name your App.'), findsOneWidget);

    await tester.enterText(find.byKey(VerilyTestKeys.appsName), 'Ferry Club');
    await tester.enterText(
      find.byKey(VerilyTestKeys.appsWebsite),
      'http://ferry.example',
    );
    await tester.tap(find.byKey(VerilyTestKeys.appsRegister));
    await tester.pumpAndSettle();
    expect(find.text('Use a full https:// address.'), findsOneWidget);
    expect(apps.created, isEmpty);
  });

  testWidgets('shows a new key once and only closes on "I\'ve saved it"', (
    tester,
  ) async {
    await pumpApps(tester);

    await tester.enterText(
      find.byKey(VerilyTestKeys.appsName),
      '  Ferry Club  ',
    );
    await tester.tap(find.byKey(VerilyTestKeys.appsRegister));
    await tester.pumpAndSettle();

    expect(apps.created, [(name: 'Ferry Club', websiteUrl: null)]);
    const fullKey = 'vly_fedcba9876543200.$fixtureSecret';
    expect(find.text(fullKey), findsOneWidget);
    expect(
      find.text(
        'Verily shows this key only once. If you lose it, make a new key and '
        'revoke this one.',
      ),
      findsOneWidget,
    );

    // Neither a tap outside nor the system Back closes it.
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.text(fullKey), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(fullKey), findsOneWidget);

    await tester.tap(find.byKey(VerilyTestKeys.appsKeyCopy));
    await tester.pumpAndSettle();
    expect(clipboard.text, fullKey);
    expect(find.text('Copied'), findsOneWidget);

    await tester.tap(find.byKey(VerilyTestKeys.appsKeySaved));
    await tester.pumpAndSettle();
    expect(find.text(fullKey), findsNothing);
    expect(find.text('Ferry Club'), findsOneWidget);
  });

  testWidgets('says plainly when registering fails', (tester) async {
    apps.createError = StateError('An active app already uses that name.');
    await pumpApps(tester);

    await tester.enterText(find.byKey(VerilyTestKeys.appsName), 'Ferry Club');
    await tester.tap(find.byKey(VerilyTestKeys.appsRegister));
    await tester.pumpAndSettle();

    expect(
      find.textContaining("We couldn't register that App."),
      findsOneWidget,
    );
    expect(find.textContaining('already uses'), findsNothing);
  });
}
