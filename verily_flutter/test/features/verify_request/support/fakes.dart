import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/router/app_router.dart';
import 'package:verily_flutter/app/theme/theme_mode_provider.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_wired_scope.dart';
import 'package:verily_flutter/core/api_client.dart';
import 'package:verily_flutter/core/external_url_launcher.dart';
import 'package:verily_flutter/core/provider_retry.dart';
import 'package:verily_flutter/features/account/account_session.dart';
import 'package:verily_flutter/features/app_link/app_link_repository.dart';
import 'package:verily_flutter/features/verify_request/verification_request_repository.dart';
import 'package:verily_flutter/l10n/l10n.dart';

import '../../../support/memory_theme_store.dart';
import '../../../support/test_app.dart';
import '../../do/support/fakes.dart';

/// Fixtures and fakes for the pages other Apps open: verification requests
/// and App links. Nothing here reaches a server, a plugin, or a browser.

final UuidValue requestId = doUuid(0x7e9);
final UuidValue requestAppId = doUuid(0xa99);
final requestExpiresAt = DateTime.utc(2026, 10, 21, 14, 40);
const requestRedirect = 'https://slopper.app/verily/callback?state=s1';

/// The private action a request runs on once accepted: an optional place
/// check and the live capture, as the server builds it.
ActionOpportunity requestActionFixture({
  VerificationRequestKind kind = VerificationRequestKind.video,
  bool withPlace = true,
  bool spokenChallenge = true,
  ActionAttemptView? attempt,
}) {
  final place = ActionRequirementView(
    id: doUuid(0x901),
    requirementKey: 'place',
    kind: ActionRequirementKind.location,
    title: 'Check in at the place',
    instructions: 'Share your location where you were asked to be.',
    position: kind == VerificationRequestKind.location ? 0 : 1,
    isRequired: kind == VerificationRequestKind.location,
    latitude: doFixtureLatitude,
    longitude: doFixtureLongitude,
    radiusMeters: 150,
    maxAccuracyMeters: 100,
  );
  final capture = ActionRequirementView(
    id: doUuid(0x902),
    requirementKey: 'capture',
    kind: switch (kind) {
      VerificationRequestKind.photo => ActionRequirementKind.photo,
      VerificationRequestKind.audio => ActionRequirementKind.audio,
      _ => ActionRequirementKind.video,
    },
    title: 'Record a video',
    instructions: 'Show your finished sourdough.',
    position: 0,
    isRequired: true,
    minDurationSeconds: 3,
    maxDurationSeconds: 120,
    spokenChallengeRequired: spokenChallenge,
  );
  return ActionOpportunity(
    id: doUuid(0x900),
    creatorDisplayName: 'Slopper',
    viewerIsCreator: false,
    actionKey: 'verification-request',
    revision: 1,
    status: ActionDefinitionStatus.active,
    title: 'Verification for Slopper',
    description: 'Show your finished sourdough.',
    recurrence: ActionRecurrence.once,
    timeZone: 'UTC',
    verifiedCompletions: 0,
    updatedAt: doFixtureNow,
    requirements: [
      if (kind != VerificationRequestKind.location) capture,
      if (withPlace || kind == VerificationRequestKind.location) place,
    ],
    myAttempt: attempt ?? requestAttemptFixture(),
  );
}

ActionAttemptView requestAttemptFixture({
  ActionAttemptStatus status = ActionAttemptStatus.collectingEvidence,
  List<UuidValue> accepted = const [],
}) => ActionAttemptView(
  id: doUuid(0x950),
  actionDefinitionId: doUuid(0x900),
  periodKey: 'once',
  status: status,
  startedAt: doFixtureNow,
  updatedAt: doFixtureNow,
  acceptedRequirementIds: accepted,
);

VerificationRequestView requestViewFixture({
  VerificationRequestKind kind = VerificationRequestKind.video,
  VerificationRequestCheck check = VerificationRequestCheck.content,
  VerificationRequestStatus status = VerificationRequestStatus.open,
  String? instructions = 'Show your finished sourdough.',
  String? website = 'https://slopper.app',
  bool checksPlace = true,
  bool spokenChallenge = true,
  bool shareEvidence = true,
  ActionOpportunity? action,
}) => VerificationRequestView(
  id: requestId,
  appId: requestAppId,
  appName: 'Slopper',
  appWebsiteUrl: website,
  kind: kind,
  instructions: instructions,
  check: check,
  checksPlace: checksPlace,
  spokenChallenge: spokenChallenge,
  shareEvidence: shareEvidence,
  status: status,
  expiresAt: requestExpiresAt,
  action: action,
);

/// The server's side of `/r/<id>`, answering from fixtures.
class FakeVerificationRequestRepository
    implements VerificationRequestRepository {
  FakeVerificationRequestRepository({
    VerificationRequestView? view,
    this.loadError,
  }) : view = view ?? requestViewFixture();

  VerificationRequestView view;

  /// Thrown by [get] while set.
  Exception? loadError;

  /// Thrown by [accept] while set.
  Exception? acceptError;

  /// What [accept] returns; defaults to [view] accepted with its action.
  VerificationRequestView? accepted;

  /// Thrown by [finish] until cleared.
  Exception? finishError;

  final calls = <String>[];
  int finishes = 0;

  @override
  Future<VerificationRequestView> get(UuidValue requestId) async {
    calls.add('get');
    if (loadError case final error?) throw error;
    return view;
  }

  @override
  Future<VerificationRequestView> accept(UuidValue requestId) async {
    calls.add('accept');
    if (acceptError case final error?) throw error;
    return accepted ??
        view.copyWith(
          status: VerificationRequestStatus.accepted,
          action: requestActionFixture(
            kind: view.kind,
            withPlace: view.checksPlace,
            spokenChallenge: view.spokenChallenge,
          ),
        );
  }

  @override
  Future<VerificationRequestRedirect> decline(UuidValue requestId) async {
    calls.add('decline');
    return VerificationRequestRedirect(
      redirectUrl: '$requestRedirect&request_id=$requestId&status=declined',
    );
  }

  @override
  Future<VerificationRequestRedirect> finish(UuidValue requestId) async {
    calls.add('finish');
    if (finishError case final error?) throw error;
    finishes++;
    return VerificationRequestRedirect(
      redirectUrl:
          '$requestRedirect&request_id=$requestId&code=receipt-$finishes',
      codeExpiresAt: doFixtureNow.add(const Duration(minutes: 5)),
    );
  }
}

/// The server's side of `/link`.
class FakeAppLinkRepository implements AppLinkRepository {
  FakeAppLinkRepository({this.alreadyLinked = false, this.describeError});

  bool alreadyLinked;
  Exception? describeError;
  Exception? approveError;
  final requests = <AppLinkRequest>[];
  final calls = <String>[];

  @override
  Future<AppLinkRequestView> describe(AppLinkRequest request) async {
    calls.add('describe');
    requests.add(request);
    if (describeError case final error?) throw error;
    return AppLinkRequestView(
      appId: request.appId,
      appName: 'Slopper',
      websiteUrl: 'https://slopper.app',
      redirectUri: request.redirectUri,
      alreadyLinked: alreadyLinked,
    );
  }

  @override
  Future<AppLinkRedirect> approve(AppLinkRequest request) async {
    calls.add('approve');
    if (approveError case final error?) throw error;
    return AppLinkRedirect(
      redirectUrl:
          '${request.redirectUri}?code=link-code&state=${request.state}',
      codeExpiresAt: doFixtureNow.add(const Duration(minutes: 5)),
    );
  }

  @override
  Future<AppLinkRedirect> decline(AppLinkRequest request) async {
    calls.add('decline');
    return AppLinkRedirect(
      redirectUrl:
          '${request.redirectUri}?error=access_denied&state=${request.state}',
    );
  }
}

/// Records every address handed to another app, and answers whether it
/// opened.
class FakeExternalUrlLauncher {
  FakeExternalUrlLauncher({this.opens = true});

  /// What the next launches answer.
  bool opens;
  final launched = <Uri>[];

  Future<bool> call(Uri uri) async {
    launched.add(uri);
    return opens;
  }
}

/// The session for a test, which can sign in part-way through.
class TestSession extends ValueNotifier<AccountSession> {
  TestSession([AccountSession? initial])
    : super(initial ?? testSignedInSession);

  void signIn() => value = testSignedInSession;
}

/// Every fake the deep-link pages touch, wired into one set of overrides.
class DeepLinkFakes {
  DeepLinkFakes({
    FakeVerificationRequestRepository? requests,
    FakeAppLinkRepository? links,
    FakeExternalUrlLauncher? launcher,
    DoFakes? doing,
    TestSession? session,
  }) : requests = requests ?? FakeVerificationRequestRepository(),
       links = links ?? FakeAppLinkRepository(),
       launcher = launcher ?? FakeExternalUrlLauncher(),
       doing = doing ?? DoFakes(),
       session = session ?? TestSession();

  final FakeVerificationRequestRepository requests;
  final FakeAppLinkRepository links;
  final FakeExternalUrlLauncher launcher;

  /// Actions, location, evidence, and the capture launcher, shared with the
  /// action page's tests.
  final DoFakes doing;
  final TestSession session;

  List<Override> get overrides => [
    themePreferenceStoreProvider.overrideWithValue(MemoryThemeStore()),
    verilyClientProvider.overrideWithValue(testVerilyClient()),
    accountSessionProvider.overrideWith((ref) {
      void changed() => ref.invalidateSelf();
      session.addListener(changed);
      ref.onDispose(() => session.removeListener(changed));
      return session.value;
    }),
    verificationRequestRepositoryProvider.overrideWithValue(requests),
    appLinkRepositoryProvider.overrideWithValue(links),
    externalUrlLauncherProvider.overrideWithValue(launcher.call),
    ...doing.overrides,
  ];
}

/// Pumps the whole app at [location] through the real router.
Future<GoRouter> pumpDeepLink(
  WidgetTester tester,
  DeepLinkFakes fakes, {
  required String location,
  Brightness brightness = Brightness.light,
  Size physicalSize = const Size(1080, 2400),
  double devicePixelRatio = 2.625,
  bool useAppTypeface = false,
}) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = devicePixelRatio;
  addTearDown(tester.view.reset);
  final refresh = ValueNotifier<int>(0);
  addTearDown(refresh.dispose);
  final router = buildAppRouter(
    isSignedIn: () => fakes.session.value.isSignedIn,
    refresh: refresh,
    initialLocation: location,
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: noAutomaticProviderRetry,
      overrides: fakes.overrides,
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
  await settleDeepLink(tester);
  return router;
}

/// Lets futures, launches, and route changes settle without waiting on
/// loading indicators that never stop.
Future<void> settleDeepLink(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Scrolls [finder] into view and taps it.
Future<void> tapDeepLink(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await settleDeepLink(tester);
}
