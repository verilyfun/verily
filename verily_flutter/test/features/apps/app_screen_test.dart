import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/core/api_client.dart';
import 'package:verily_flutter/core/config/server_config.dart';
import 'package:verily_flutter/features/actions/action_repository.dart';
import 'package:verily_flutter/features/apps/apps_repository.dart';
import 'package:verily_flutter/features/apps/widgets/integration_guide.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import '../create/hub/support/fakes.dart';
import '../create/hub/support/router_harness.dart';
import 'support/clipboard.dart';
import 'support/fakes.dart';

/// The page's own list; the request example scrolls sideways inside it.
final Finder _page = find.byType(Scrollable).first;

void main() {
  late FakeAppsRepository apps;
  late FakeHubActionRepository actions;
  late ClipboardRecorder clipboard;
  late VerilyAppView app;

  setUp(() {
    app = fixtureApp();
    apps = FakeAppsRepository(apps: [app]);
    actions = FakeHubActionRepository(owned: []);
    clipboard = ClipboardRecorder();
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    String? appId,
    ServerConfig? config,
    Size physicalSize = const Size(800, 2400),
    double devicePixelRatio = 1,
    double textScale = 1,
    Brightness brightness = Brightness.light,
  }) async {
    clipboard.install(tester);
    await pumpCreateRoutes(
      tester,
      initialLocation: '/apps/${appId ?? app.id}',
      physicalSize: physicalSize,
      devicePixelRatio: devicePixelRatio,
      textScale: textScale,
      brightness: brightness,
      overrides: [
        appsRepositoryProvider.overrideWithValue(apps),
        actionRepositoryProvider.overrideWithValue(actions),
        if (config != null) serverConfigProvider.overrideWithValue(config),
      ],
    );
    await tester.pumpAndSettle();
  }

  test('the example request carries no real key and the documented body', () {
    final snippet = appConfirmationCurlExample(
      confirmationsUrl: Uri.parse('https://verily.test/api/v1/confirmations'),
      actionKey: 'daily-situps',
    );

    expect(snippet, contains("VERILY_APP_KEY='vly_<your key>'"));
    expect(
      snippet,
      contains("curl -X POST 'https://verily.test/api/v1/confirmations'"),
    );
    expect(snippet, contains(r'Authorization: Bearer $VERILY_APP_KEY'));
    expect(snippet, contains(r'Verily-Timestamp: $(date +%s)'));
    expect(snippet, contains('Content-Type: application/json'));
    for (final field in ['eventId', 'action', 'subject', 'occurredAt']) {
      expect(snippet, contains('\\"$field\\"'));
    }
    expect(snippet, contains(r'\"daily-situps\"'));
    expect(snippet, isNot(contains(fixtureSecret)));
  });

  testWidgets('lists keys and issues a new one, shown once', (tester) async {
    await pumpApp(tester);

    expect(find.text('vly_0123456789abcdef'), findsOneWidget);
    expect(find.text('Not used yet'), findsOneWidget);

    await tester.tap(find.byKey(VerilyTestKeys.appsNewKey));
    await tester.pumpAndSettle();
    expect(apps.keysCreated, [app.id]);
    const fullKey = 'vly_fedcba9876543200.$fixtureSecret';
    expect(find.text(fullKey), findsOneWidget);

    await tester.tap(find.byKey(VerilyTestKeys.appsKeySaved));
    await tester.pumpAndSettle();

    expect(find.text('vly_fedcba9876543200'), findsOneWidget);
    // Two working keys is the most an App may hold.
    expect(
      tester
          .widget<VerilyActionButton>(find.byKey(VerilyTestKeys.appsNewKey))
          .onPressed,
      isNull,
    );
    expect(
      find.text(
        'An App can have two working keys. Revoke one to make another.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('asks before revoking a key', (tester) async {
    await pumpApp(tester);
    final revoke = find.byKey(VerilyTestKeys.appsRevokeKey('0123456789abcdef'));

    await tester.tap(revoke);
    await tester.pumpAndSettle();
    expect(find.text('Revoke this key?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(apps.keysRevoked, isEmpty);

    await tester.tap(revoke);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(VerilyTestKeys.appsRevokeConfirm));
    await tester.pumpAndSettle();

    expect(apps.keysRevoked, [(appId: app.id, keyId: '0123456789abcdef')]);
    expect(find.textContaining('Revoked '), findsOneWidget);
  });

  testWidgets('asks before revoking the App, then shows it revoked', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.scrollUntilVisible(
      find.byKey(VerilyTestKeys.appsRevokeApp),
      300,
      scrollable: _page,
    );
    await tester.tap(find.byKey(VerilyTestKeys.appsRevokeApp));
    await tester.pumpAndSettle();
    expect(find.text('Revoke Sunrise Run Club?'), findsOneWidget);
    expect(
      find.textContaining('every action it confirms is paused'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(VerilyTestKeys.appsRevokeConfirm));
    await tester.pumpAndSettle();

    expect(apps.appsRevoked, [app.id]);
    await tester.scrollUntilVisible(
      find.text(
        'This App is revoked. Its keys no longer work and its actions are '
        'paused.',
      ),
      -300,
      scrollable: _page,
    );
    expect(find.byKey(VerilyTestKeys.appsNewKey), findsNothing);
  });

  testWidgets('loads older confirmations a page at a time', (tester) async {
    final first = [for (var i = 1; i <= 50; i++) fixtureConfirmation(i)];
    final second = [for (var i = 51; i <= 53; i++) fixtureConfirmation(i)];
    apps.confirmationPages = [first, second];
    await pumpApp(tester);

    final more = find.byKey(VerilyTestKeys.appsConfirmationsMore);
    await tester.scrollUntilVisible(more, 600, scrollable: _page);
    await tester.ensureVisible(more);
    await tester.pumpAndSettle();
    await tester.tap(more);
    await tester.pumpAndSettle();

    expect(apps.confirmationRequests, [
      (appId: app.id, beforeId: null),
      (appId: app.id, beforeId: first.last.id),
    ]);
    await tester.scrollUntilVisible(
      find.byKey(VerilyTestKeys.appsConfirmation('evt_53')),
      600,
      scrollable: _page,
    );
    expect(more, findsNothing);
  });

  testWidgets(
    'explains a rejection in words and keeps the code for developers',
    (
      tester,
    ) async {
      apps.confirmationPages = [
        [
          fixtureConfirmation(
            1,
            outcome: AppConfirmationOutcome.rejected,
            reasonCode: 'unknown_subject',
            attemptStatus: null,
          ),
        ],
      ];
      await pumpApp(tester);

      final row = find.byKey(VerilyTestKeys.appsConfirmation('evt_1'));
      await tester.scrollUntilVisible(row, 600, scrollable: _page);
      expect(
        find.descendant(of: row, matching: find.text('Rejected')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: row,
          matching: find.text('No participant has that link code'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: row,
          matching: find.text('Response code unknown_subject'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('the example posts to the configured URL with a bound action', (
    tester,
  ) async {
    actions.owned = [
      fixtureOwnedAction(
        requirements: [
          fixtureRequirement(
            kind: ActionRequirementKind.externalApp,
            appId: app.id,
            appName: app.name,
          ),
        ],
      ),
    ];
    await pumpApp(
      tester,
      config: serverConfigFrom(
        apiUrl: 'https://api.verily.test/',
        publicWebUrl: 'https://verily.test/',
      ),
    );

    final example = find.byKey(VerilyTestKeys.appsCurlExample);
    await tester.scrollUntilVisible(example, 300, scrollable: _page);
    final snippet = tester.widget<Text>(example).data!;
    expect(
      snippet,
      contains("curl -X POST 'https://verily.test/api/v1/confirmations'"),
    );
    expect(snippet, contains(r'\"action\":\"action-1\"'));

    await tester.scrollUntilVisible(
      find.byKey(VerilyTestKeys.appsCurlCopy),
      300,
      scrollable: _page,
    );
    await tester.tap(find.byKey(VerilyTestKeys.appsCurlCopy));
    await tester.pumpAndSettle();
    expect(clipboard.text, snippet);
  });

  testWidgets('says plainly when the App is not one of yours', (
    tester,
  ) async {
    await pumpApp(tester, appId: 'missing');

    expect(
      find.text("We couldn't find that. It may have ended or been removed."),
      findsOneWidget,
    );
  });

  for (final brightness in Brightness.values) {
    testWidgets('fits a Seeker phone with large text ($brightness)', (
      tester,
    ) async {
      apps.confirmationPages = [
        [
          fixtureConfirmation(1),
          fixtureConfirmation(
            2,
            outcome: AppConfirmationOutcome.rejected,
            reasonCode: 'occurred_outside_period',
          ),
        ],
      ];
      await pumpApp(
        tester,
        physicalSize: seekerPhysicalSize,
        devicePixelRatio: seekerPixelRatio,
        textScale: 1.3,
        brightness: brightness,
      );

      expect(tester.takeException(), isNull);
    });
  }
}
