// Renders the App platform screens (App settings, webhook calls, the
// signing-secret dialog, push or pull in the editor, and the participant's
// pull check) through the real router at the Solana Seeker's portrait size,
// with the real Skribble faces, in light and dark. Every repository is a fake.
//
// Every run asserts the screens lay out without errors. To also write PNGs
// for review into `.screenshots/phase-c/` (ignored by git):
//
//   flutter test --dart-define=VERILY_SCREENSHOTS=true \
//     test/screenshots/phase_c_app_platform_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/router/app_router.dart';
import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_wired_scope.dart';
import 'package:verily_flutter/core/provider_retry.dart';
import 'package:verily_flutter/features/actions/action_repository.dart';
import 'package:verily_flutter/features/apps/apps_repository.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import '../features/apps/support/fakes.dart' as apps;
import '../features/create/editor/support/fakes.dart' as editor;
import '../features/create/hub/support/fakes.dart' as hub;
import '../features/do/support/fakes.dart' as doing;
import '../support/skribble_faces.dart';
import '../support/test_app.dart';

const _writeScreenshots = bool.fromEnvironment('VERILY_SCREENSHOTS');
const _outputDirectory = '.screenshots/phase-c';
const _seekerPhysicalSize = Size(1080, 2400);
const _seekerPixelRatio = 2.625;

void main() {
  setUpAll(loadSkribbleFaces);

  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    group('App settings ($theme)', () {
      late apps.FakeAppsRepository repository;
      late VerilyAppView app;

      setUp(() {
        app = apps.fixtureApp().copyWith(
          webhookUrl: 'https://sunrise.example/verily/webhook',
          webhookSecretVersion: 2,
          redirectUris: [
            'com.sunrise.club://verily',
            'https://sunrise.example/verily/return',
          ],
        );
        repository = apps.FakeAppsRepository(apps: [app])
          ..deliveryPages = [
            [
              apps.fixtureDelivery(1),
              apps.fixtureDelivery(
                2,
                eventType: 'attempt.verify',
                succeeded: false,
                statusCode: null,
                errorCode: 'timeout',
                attemptNumber: 2,
                eventStatus: null,
              ),
              apps.fixtureDelivery(
                3,
                eventType: 'payout.released',
                succeeded: false,
                statusCode: 503,
                attemptNumber: 3,
                eventStatus: AppEventStatus.pending,
              ),
            ],
          ];
      });

      List<Override> overrides() => [
        appsRepositoryProvider.overrideWithValue(repository),
        actionRepositoryProvider.overrideWithValue(
          hub.FakeHubActionRepository(owned: []),
        ),
      ];

      testWidgets('webhook, secret, return addresses, and calls', (
        tester,
      ) async {
        await _pumpApp(
          tester,
          location: '/apps/${app.id}',
          overrides: overrides(),
          brightness: brightness,
        );
        await _scrollToTop(tester, find.byKey(VerilyTestKeys.appsWebhookPanel));
        await _capture(tester, 'app-webhook-$theme');

        await _scrollToTop(
          tester,
          find.byKey(VerilyTestKeys.appsRedirectPanel),
        );
        await _capture(tester, 'app-redirects-$theme');

        await _scrollToTop(
          tester,
          find.byKey(
            VerilyTestKeys.appsDelivery(apps.fixtureDelivery(1).id.uuid),
          ),
        );
        await _capture(tester, 'app-deliveries-$theme');

        await _scrollToTop(
          tester,
          find.byKey(VerilyTestKeys.appsWebhookPanel),
          upwards: true,
        );
        await tester.ensureVisible(find.byKey(VerilyTestKeys.appsSecretRotate));
        await _settle(tester);
        await tester.tap(find.byKey(VerilyTestKeys.appsSecretRotate));
        await _settle(tester);
        await _capture(tester, 'app-secret-dialog-$theme');
      });

      testWidgets('a refused webhook address', (tester) async {
        app = apps.fixtureApp();
        repository = apps.FakeAppsRepository(apps: [app])
          ..settingsError = AppPlatformException(
            problem: AppPlatformProblem.invalidWebhookUrl,
            message: 'refused',
          );
        await _pumpApp(
          tester,
          location: '/apps/${app.id}',
          overrides: overrides(),
          brightness: brightness,
        );
        await _scrollToTop(tester, find.byKey(VerilyTestKeys.appsWebhookPanel));
        await tester.enterText(
          find.byKey(VerilyTestKeys.appsWebhookUrl),
          'https://10.0.0.4/hook',
        );
        await tester.pump();
        await tester.tap(find.byKey(VerilyTestKeys.appsWebhookSave));
        await _settle(tester);
        // The keyboard is not part of the picture.
        FocusManager.instance.primaryFocus?.unfocus();
        await _settle(tester);
        await _capture(tester, 'app-webhook-refused-$theme');
      });
    });

    testWidgets('editor: how the App confirms ($theme)', (tester) async {
      final saved = editor.actionFixture(
        title: 'Bake a loaf',
        requirements: [
          ActionRequirementView(
            id: editor.editorUuid(150),
            requirementKey: 'app-confirmation',
            kind: ActionRequirementKind.externalApp,
            title: 'Bake in Slopper',
            instructions: 'Finish a loaf in Slopper.',
            position: 0,
            isRequired: true,
            appId: editor.editorUuid(900),
            appName: 'Slopper',
            appAvailable: true,
            appVerificationMode: AppVerificationMode.pull,
          ),
        ],
      );
      final fakes = editor.EditorFakes(
        actions: editor.FakeActionRepository(previews: {saved.id.uuid: saved})
          ..lastSaved = saved,
        apps: editor.FakeAppsRepository(apps: [editor.appFixture()]),
      );
      await _pumpApp(
        tester,
        location: VerilyLocations.actionEdit(saved.id.uuid),
        overrides: fakes.overrides,
        brightness: brightness,
      );
      await _scrollToTop(
        tester,
        find.byKey(
          VerilyTestKeys.editorAppMode('app-confirmation', 'push'),
        ),
        offset: 260,
      );
      await _capture(tester, 'editor-app-mode-$theme');
    });

    group('participant pull check ($theme)', () {
      final pull = doing.appRequirement(mode: AppVerificationMode.pull);

      Future<doing.DoFakes> pumpPull(WidgetTester tester) async {
        final fakes = doing.DoFakes();
        fakes.actions.available = [
          doing.actionFixture(
            id: 40,
            title: 'Bake a loaf',
            description: 'Bake a sourdough loaf and log it in Slopper.',
            creator: 'Slopper',
            requirements: [pull],
            myAttempt: doing.attemptFixture(actionId: 40),
          ),
        ];
        await _pumpApp(
          tester,
          location: '/actions/${doing.doUuid(40)}',
          overrides: fakes.overrides,
          brightness: brightness,
        );
        return fakes;
      }

      EvidenceSubmissionResult answer(
        String reasonCode, {
        EvidenceDecisionStatus? status,
      }) => EvidenceSubmissionResult(
        attempt: doing.attemptFixture(actionId: 40),
        requirementId: pull.id,
        status: status,
        reasonCode: reasonCode,
        summary: '',
      );

      Finder ask() =>
          find.byKey(VerilyTestKeys.actionPullAsk(pull.requirementKey));

      testWidgets('ready with a note', (tester) async {
        await pumpPull(tester);
        await tester.enterText(
          find.byKey(VerilyTestKeys.actionPullReference(pull.requirementKey)),
          'ada_lovelace',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await _settle(tester);
        await _capture(tester, 'pull-ready-$theme');
      });

      testWidgets('waiting for the App', (tester) async {
        final fakes = await pumpPull(tester);
        fakes.actions.onAskApp = (_) => answer('app_checking');
        await tester.ensureVisible(ask());
        await tester.tap(ask());
        await _settle(tester);
        await _capture(tester, 'pull-waiting-$theme');
      });

      testWidgets('the App said no', (tester) async {
        final fakes = await pumpPull(tester);
        fakes.actions.onAskApp = (_) => answer(
          'app_not_confirmed',
          status: EvidenceDecisionStatus.rejected,
        );
        await tester.ensureVisible(ask());
        await tester.tap(ask());
        await _settle(tester);
        await _capture(tester, 'pull-rejected-$theme');
      });

      testWidgets('the App did not answer', (tester) async {
        final fakes = await pumpPull(tester);
        fakes.actions.onAskApp = (_) => answer('app_unreachable');
        await tester.ensureVisible(ask());
        await tester.tap(ask());
        await _settle(tester);
        await _capture(tester, 'pull-failed-$theme');
      });
    });
  }
}

/// Scrolls the page so [finder] sits [offset] logical pixels below the top.
Future<void> _scrollToTop(
  WidgetTester tester,
  Finder finder, {
  double offset = 0,
  bool upwards = false,
}) async {
  final page = find.byType(Scrollable).first;
  await tester.scrollUntilVisible(
    finder,
    upwards ? -300 : 300,
    scrollable: page,
  );
  await Scrollable.ensureVisible(tester.element(finder));
  await _settle(tester);
  if (offset > 0) {
    await tester.drag(page, Offset(0, offset));
    await _settle(tester);
  }
}

/// Pumps the whole app at [location] through the real router and tab shell.
Future<void> _pumpApp(
  WidgetTester tester, {
  required String location,
  required Brightness brightness,
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = _seekerPhysicalSize;
  tester.view.devicePixelRatio = _seekerPixelRatio;
  addTearDown(tester.view.reset);

  final refresh = ValueNotifier<int>(0);
  addTearDown(refresh.dispose);
  final router = buildAppRouter(
    isSignedIn: () => true,
    refresh: refresh,
    initialLocation: location,
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      retry: noAutomaticProviderRetry,
      overrides: [...baseTestOverrides(), ...overrides],
      child: MaterialApp.router(
        // As in the app.
        debugShowCheckedModeBanner: false,
        theme: buildVerilyTheme(brightness: brightness),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, page) => VerilyWiredScope(child: page!),
        routerConfig: router,
      ),
    ),
  );
  await _settle(tester);
}

Future<void> _capture(WidgetTester tester, String name) async {
  expect(tester.takeException(), isNull, reason: name);
  if (!_writeScreenshots) return;

  final view = tester.binding.renderViews.first;
  final layer = view.debugLayer! as OffsetLayer;
  await tester.runAsync(() async {
    // The root layer already scales by the device pixel ratio.
    final image = await layer.toImage(Offset.zero & tester.view.physicalSize);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('$_outputDirectory/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(png!.buffer.asUint8List());
  });
}

/// Lets ink motion, async work, and route transitions finish. Loading
/// indicators spin forever, so this pumps fixed steps instead of settling.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  for (var step = 0; step < 4; step++) {
    await tester.pump(const Duration(milliseconds: 600));
  }
}
