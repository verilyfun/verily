import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/theme_mode_provider.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_wired_scope.dart';
import 'package:verily_flutter/core/api_client.dart';
import 'package:verily_flutter/core/provider_retry.dart';
import 'package:verily_flutter/features/account/account_session.dart';
import 'package:verily_flutter/l10n/l10n.dart';

import 'memory_theme_store.dart';

/// A signed-in session for tests.
final testSignedInSession = AccountSession(
  authUserId: UuidValue.fromString('00000000-0000-4000-8000-000000000001'),
);

/// Keeps the sign-in kit's session in memory instead of secure storage.
class MemoryAuthSuccessStorage implements ClientAuthSuccessStorage {
  AuthSuccess? _value;

  @override
  Future<AuthSuccess?> get() async => _value;

  @override
  Future<void> set(AuthSuccess? data) async => _value = data;
}

/// A client pointed at the local port that never sends a request on its own.
/// Screens that hand the client to the sign-in kit need one; repositories in
/// tests are always fakes.
Client testVerilyClient() =>
    Client('http://localhost:8180/')
      ..authSessionManager = FlutterAuthSessionManager(
        storage: MemoryAuthSuccessStorage(),
      );

/// The overrides every widget test needs: an in-memory appearance store, a
/// session, and a client that never sends a request, so nothing reaches a
/// plugin or a server.
List<Override> baseTestOverrides({
  AccountSession? session,
  ThemePreferenceStore? themeStore,
}) => [
  themePreferenceStoreProvider.overrideWithValue(
    themeStore ?? MemoryThemeStore(),
  ),
  accountSessionProvider.overrideWithValue(session ?? testSignedInSession),
  verilyClientProvider.overrideWithValue(testVerilyClient()),
];

/// Pumps [child] as a page with the app's theme, localizations, and Skribble
/// scope. Use [overrides] for repositories and services.
Future<void> pumpVerilyPage(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  AccountSession? session,
  Brightness brightness = Brightness.light,
  Size? physicalSize,
  double devicePixelRatio = 1,
  bool useAppTypeface = false,
}) async {
  if (physicalSize != null) {
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = devicePixelRatio;
    addTearDown(tester.view.reset);
  }
  await tester.pumpWidget(
    ProviderScope(
      // Like the app: a failed load stays visible with its retry action.
      retry: noAutomaticProviderRetry,
      overrides: [
        ...baseTestOverrides(session: session),
        ...overrides,
      ],
      child: MaterialApp(
        // As in the app, so screenshots carry no debug ribbon.
        debugShowCheckedModeBanner: false,
        theme: buildVerilyTheme(
          brightness: brightness,
          useAppTypeface: useAppTypeface,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, page) => VerilyWiredScope(child: page!),
        home: child,
      ),
    ),
  );
}
