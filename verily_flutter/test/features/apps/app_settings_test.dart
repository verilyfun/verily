import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/actions/action_repository.dart';
import 'package:verily_flutter/features/apps/apps_repository.dart';
import 'package:verily_flutter/l10n/generated/app_localizations_en.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import '../create/hub/support/fakes.dart';
import '../create/hub/support/router_harness.dart';
import 'support/clipboard.dart';
import 'support/fakes.dart';

final _l10n = AppLocalizationsEn();

/// The App page's own list.
final Finder _page = find.byType(Scrollable).first;

void main() {
  late FakeAppsRepository apps;
  late VerilyAppView app;
  late ClipboardRecorder clipboard;

  setUp(() {
    app = fixtureApp();
    apps = FakeAppsRepository(apps: [app]);
    clipboard = ClipboardRecorder();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    clipboard.install(tester);
    await pumpCreateRoutes(
      tester,
      initialLocation: '/apps/${app.id}',
      physicalSize: const Size(800, 4000),
      overrides: [
        appsRepositoryProvider.overrideWithValue(apps),
        actionRepositoryProvider.overrideWithValue(
          FakeHubActionRepository(owned: []),
        ),
      ],
    );
    await tester.pumpAndSettle();
  }

  /// Brings [finder] fully on screen; a list builds a little past its edge,
  /// so being built is not enough to be tapped.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 200, scrollable: _page);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, Key key) async {
    await reveal(tester, find.byKey(key));
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, Key key, String text) async {
    await reveal(tester, find.byKey(key));
    await tester.enterText(find.byKey(key), text);
    await tester.pump();
  }

  group('webhook address', () {
    testWidgets('says nothing is sent until the address and secret exist', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(find.text(_l10n.appsSecretNone), findsOneWidget);
      expect(find.byKey(VerilyTestKeys.appsWebhookNotSending), findsOneWidget);
      expect(find.byKey(VerilyTestKeys.appsWebhookRemove), findsNothing);
    });

    testWidgets('saves an https address', (tester) async {
      await pumpApp(tester);

      await enter(
        tester,
        VerilyTestKeys.appsWebhookUrl,
        '  https://sunrise.example/verily  ',
      );
      await tapKey(tester, VerilyTestKeys.appsWebhookSave);

      expect(apps.webhookUrlsSet, ['https://sunrise.example/verily']);
      expect(find.text(_l10n.appsWebhookSaved), findsOneWidget);
      expect(find.byKey(VerilyTestKeys.appsWebhookRemove), findsOneWidget);
    });

    testWidgets('catches a plain http address before asking', (tester) async {
      await pumpApp(tester);

      await enter(
        tester,
        VerilyTestKeys.appsWebhookUrl,
        'http://sunrise.example/verily',
      );
      await tapKey(tester, VerilyTestKeys.appsWebhookSave);

      expect(apps.webhookUrlsSet, isEmpty);
      expect(find.text(_l10n.appsWebhookInvalid), findsOneWidget);
    });

    testWidgets("explains the server's refusal of a private host", (
      tester,
    ) async {
      apps.settingsError = AppPlatformException(
        problem: AppPlatformProblem.invalidWebhookUrl,
        message: 'The webhook host must be a public address.',
      );
      await pumpApp(tester);

      await enter(
        tester,
        VerilyTestKeys.appsWebhookUrl,
        'https://192.168.1.10/hook',
      );
      await tapKey(tester, VerilyTestKeys.appsWebhookSave);

      expect(apps.webhookUrlsSet, ['https://192.168.1.10/hook']);
      expect(
        find.descendant(
          of: find.byKey(VerilyTestKeys.appsWebhookProblem),
          matching: find.text(_l10n.appsWebhookInvalid),
        ),
        findsOneWidget,
      );
      // The server's own English never replaces the explanation.
      expect(find.textContaining('public address.'), findsNothing);
    });

    testWidgets('removes the address', (tester) async {
      app = app.copyWith(webhookUrl: 'https://sunrise.example/verily');
      apps = FakeAppsRepository(apps: [app]);
      await pumpApp(tester);

      await tapKey(tester, VerilyTestKeys.appsWebhookRemove);

      expect(apps.webhookUrlsSet, [null]);
      expect(find.text(_l10n.appsWebhookRemoved), findsOneWidget);
      expect(find.byKey(VerilyTestKeys.appsWebhookRemove), findsNothing);
    });
  });

  group('signing secret', () {
    testWidgets('shows a new secret once, then only its version', (
      tester,
    ) async {
      await pumpApp(tester);

      await tapKey(tester, VerilyTestKeys.appsSecretRotate);

      const secret = 'whsec_${fixtureSecret}v1';
      expect(find.text(_l10n.appsSecretTitle), findsOneWidget);
      expect(find.text(secret), findsOneWidget);
      expect(find.text(_l10n.appsSecretLabel(1)), findsOneWidget);
      // A first secret has nothing to overlap with.
      expect(find.textContaining('previous one until'), findsNothing);

      await tester.tap(find.byKey(VerilyTestKeys.appsSecretCopy));
      await tester.pumpAndSettle();
      expect(clipboard.text, secret);

      await tester.tap(find.byKey(VerilyTestKeys.appsSecretSaved));
      await tester.pumpAndSettle();

      expect(find.text(secret), findsNothing);
      expect(find.text(_l10n.appsSecretVersion(1)), findsOneWidget);
      expect(find.text(_l10n.appsSecretRotate), findsOneWidget);
    });

    testWidgets('says how long the previous secret keeps signing', (
      tester,
    ) async {
      app = app.copyWith(webhookSecretVersion: 1);
      apps = FakeAppsRepository(apps: [app]);
      await pumpApp(tester);

      await tapKey(tester, VerilyTestKeys.appsSecretRotate);

      expect(apps.secretsRotated, [app.id]);
      expect(find.textContaining('previous one until'), findsOneWidget);
    });

    testWidgets('says plainly when webhooks are off on the server', (
      tester,
    ) async {
      apps.settingsError = AppPlatformException(
        problem: AppPlatformProblem.webhooksUnavailable,
        message: 'Webhooks are not available on this server yet.',
      );
      await pumpApp(tester);

      await tapKey(tester, VerilyTestKeys.appsSecretRotate);

      expect(find.text(_l10n.appsSecretTitle), findsNothing);
      expect(find.text(_l10n.appsWebhooksUnavailable), findsOneWidget);
    });
  });

  group('return addresses', () {
    const uri = 'com.sunrise.app://verily';

    testWidgets('adds an address exactly as typed', (tester) async {
      await pumpApp(tester);
      expect(find.text(_l10n.appsRedirectEmpty), findsOneWidget);

      await enter(tester, VerilyTestKeys.appsRedirectInput, uri);
      await tapKey(tester, VerilyTestKeys.appsRedirectAdd);

      expect(apps.redirectUrisSet, [
        [uri],
      ]);
      expect(find.byKey(VerilyTestKeys.appsRedirectRow(uri)), findsOneWidget);
      expect(find.text(_l10n.appsRedirectCount(1, 10)), findsOneWidget);
    });

    testWidgets('refuses a duplicate without asking', (tester) async {
      app = app.copyWith(redirectUris: [uri]);
      apps = FakeAppsRepository(apps: [app]);
      await pumpApp(tester);

      await enter(tester, VerilyTestKeys.appsRedirectInput, uri);
      await tapKey(tester, VerilyTestKeys.appsRedirectAdd);

      expect(apps.redirectUrisSet, isEmpty);
      expect(find.text(_l10n.appsRedirectDuplicate), findsOneWidget);
    });

    testWidgets("explains the server's refusal of a wildcard", (tester) async {
      apps.settingsError = AppPlatformException(
        problem: AppPlatformProblem.invalidRedirectUri,
        message: 'Redirect URIs must be exact.',
      );
      await pumpApp(tester);

      await enter(
        tester,
        VerilyTestKeys.appsRedirectInput,
        'https://*.sunrise.example',
      );
      await tapKey(tester, VerilyTestKeys.appsRedirectAdd);

      expect(find.text(_l10n.appsRedirectInvalid), findsOneWidget);
      expect(find.text(_l10n.appsRedirectEmpty), findsOneWidget);
    });

    testWidgets('removes an address after asking', (tester) async {
      app = app.copyWith(redirectUris: [uri, 'https://sunrise.example/back']);
      apps = FakeAppsRepository(apps: [app]);
      await pumpApp(tester);

      await tapKey(tester, VerilyTestKeys.appsRedirectRemove(uri));
      expect(find.text(_l10n.appsRedirectRemoveTitle), findsOneWidget);
      await tester.tap(find.byKey(VerilyTestKeys.appsRedirectRemoveConfirm));
      await tester.pumpAndSettle();

      expect(apps.redirectUrisSet, [
        ['https://sunrise.example/back'],
      ]);
      expect(find.byKey(VerilyTestKeys.appsRedirectRow(uri)), findsNothing);
    });

    testWidgets('stops at ten addresses', (tester) async {
      app = app.copyWith(
        redirectUris: [for (var i = 0; i < 10; i++) 'com.sunrise.app$i://v'],
      );
      apps = FakeAppsRepository(apps: [app]);
      await pumpApp(tester);

      await tester.scrollUntilVisible(
        find.byKey(VerilyTestKeys.appsRedirectAdd),
        200,
        scrollable: _page,
      );
      expect(find.text(_l10n.appsRedirectFull(10)), findsOneWidget);
      final add = tester.widget<TextField>(
        find.byKey(VerilyTestKeys.appsRedirectInput),
      );
      expect(add.enabled, isFalse);
    });
  });

  group('webhook calls', () {
    testWidgets('lead with plain words and keep the codes underneath', (
      tester,
    ) async {
      apps.deliveryPages = [
        [
          fixtureDelivery(1),
          fixtureDelivery(
            2,
            eventType: 'attempt.verify',
            succeeded: false,
            statusCode: null,
            errorCode: 'timeout',
            attemptNumber: 3,
            eventStatus: null,
          ),
          fixtureDelivery(
            3,
            eventType: 'payout.released',
            succeeded: false,
            statusCode: 503,
            eventStatus: AppEventStatus.pending,
          ),
        ],
      ];
      await pumpApp(tester);
      await tester.scrollUntilVisible(
        find.byKey(VerilyTestKeys.appsDelivery(fixtureDelivery(3).id.uuid)),
        200,
        scrollable: _page,
      );

      expect(find.text(_l10n.appsEventAttemptVerified), findsOneWidget);
      expect(find.text(_l10n.appsDeliverySucceeded), findsOneWidget);
      expect(find.text(_l10n.appsEventAttemptVerify), findsOneWidget);
      expect(find.text(_l10n.appsDeliveryTimeout), findsOneWidget);
      expect(
        find.text(
          _l10n.appsDeliveryDetails(3, _l10n.appsDeliveryNoAnswer, 122),
        ),
        findsOneWidget,
      );
      expect(find.text(_l10n.appsDeliveryRefused(503)), findsOneWidget);
      expect(find.text(_l10n.appsEventStatusPending), findsOneWidget);
      expect(
        find.text(_l10n.appsDeliveryEventError('attempt.verify', 'timeout')),
        findsOneWidget,
      );
      expect(find.byKey(VerilyTestKeys.appsDeliveriesMore), findsNothing);
    });

    testWidgets('page back from the oldest call shown', (tester) async {
      final first = [
        for (var i = 0; i < AppPageSizes.deliveries; i++) fixtureDelivery(i),
      ];
      apps.deliveryPages = [
        first,
        [fixtureDelivery(900, eventType: 'attempt.rejected')],
      ];
      await pumpApp(tester);

      await tapKey(tester, VerilyTestKeys.appsDeliveriesMore);

      expect(apps.deliveryRequests.map((request) => request.beforeId), [
        null,
        first.last.id,
      ]);
      await tester.scrollUntilVisible(
        find.text(_l10n.appsEventAttemptRejected),
        200,
        scrollable: _page,
      );
      expect(find.byKey(VerilyTestKeys.appsDeliveriesMore), findsNothing);
    });

    testWidgets('say when there are none yet', (tester) async {
      await pumpApp(tester);

      await tester.scrollUntilVisible(
        find.text(_l10n.appsDeliveriesEmpty),
        200,
        scrollable: _page,
      );
    });
  });

  group('the App page', () {
    Future<void> pumpAt(WidgetTester tester, String location) async {
      await pumpCreateRoutes(
        tester,
        initialLocation: location,
        physicalSize: const Size(800, 2400),
        overrides: [
          appsRepositoryProvider.overrideWithValue(apps),
          actionRepositoryProvider.overrideWithValue(
            FakeHubActionRepository(owned: []),
          ),
        ],
      );
      await tester.pumpAndSettle();
    }

    testWidgets('loads the one App it shows', (tester) async {
      await pumpAt(tester, '/apps/${app.id}');

      expect(apps.appsFetched, [app.id]);
      expect(find.text(app.name), findsWidgets);
    });

    testWidgets('an App the server does not know is not found', (
      tester,
    ) async {
      await pumpAt(tester, '/apps/${fixtureId(999)}');

      expect(find.text(_l10n.errorNotFound), findsOneWidget);
      expect(find.text(_l10n.appsBackToApps), findsOneWidget);
    });

    testWidgets('a malformed link is not found without asking', (
      tester,
    ) async {
      await pumpAt(tester, '/apps/not-an-app');

      expect(apps.appsFetched, isEmpty);
      expect(find.text(_l10n.errorNotFound), findsOneWidget);
    });
  });

  testWidgets('a revoked App shows its log but no settings', (tester) async {
    app = app.copyWith(status: VerilyAppStatus.revoked, revokedAt: fixtureNow);
    apps = FakeAppsRepository(apps: [app]);
    await pumpApp(tester);

    expect(find.byKey(VerilyTestKeys.appsWebhookPanel), findsNothing);
    expect(find.byKey(VerilyTestKeys.appsRedirectPanel), findsNothing);
    await tester.scrollUntilVisible(
      find.text(_l10n.appsDeliveriesHeading),
      200,
      scrollable: _page,
    );
  });
}
