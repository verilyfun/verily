import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:verily_flutter/app/app.dart';
import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/app/screens/coming_soon_screen.dart';
import 'package:verily_flutter/app/screens/sign_in_screen.dart';
import 'package:verily_flutter/app/screens/welcome_screen.dart';
import 'package:verily_flutter/app/shell/tabs_shell.dart';
import 'package:verily_flutter/core/provider_retry.dart';
import 'package:verily_flutter/features/account/account_session.dart';
import 'package:verily_flutter/features/do/action_screen.dart';
import 'package:verily_flutter/features/do/do_screen.dart';

import '../../support/skribble_faces.dart';
import '../../support/test_app.dart';

Future<void> _pumpApp(WidgetTester tester, {required bool signedIn}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: noAutomaticProviderRetry,
      overrides: baseTestOverrides(
        session: signedIn
            ? testSignedInSession
            : const AccountSession.signedOut(),
      ),
      child: const VerilyApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Delivers [location] the way the Android embedding does for a deep link.
Future<void> _openDeepLink(WidgetTester tester, String location) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    const JSONMethodCodec().encodeMethodCall(
      MethodCall('pushRouteInformation', {'location': location}),
    ),
    (_) {},
  );
  await tester.pumpAndSettle();
}

void main() {
  group('deepLinkLocation', () {
    test('maps the custom scheme host into the path', () {
      expect(deepLinkLocation(Uri.parse('verily://r/req_123')), '/r/req_123');
      expect(
        deepLinkLocation(Uri.parse('verily://link?app=abc&state=xyz')),
        '/link?app=abc&state=xyz',
      );
    });

    test('keeps verily.fun app links as they are', () {
      expect(
        deepLinkLocation(Uri.parse('https://verily.fun/r/req_123')),
        '/r/req_123',
      );
      expect(
        deepLinkLocation(Uri.parse('https://verily.fun/link?app=abc')),
        '/link?app=abc',
      );
    });

    test('sends unknown or foreign links to the front door', () {
      expect(deepLinkLocation(Uri.parse('verily://elsewhere/x')), '/');
      expect(deepLinkLocation(Uri.parse('verily://r/a/b')), '/');
      expect(deepLinkLocation(Uri.parse('https://example.com/r/x')), '/');
    });

    test('leaves in-app locations alone', () {
      expect(deepLinkLocation(Uri.parse('/actions/abc')), isNull);
    });
  });

  test('only the front door and deep-link pages are public', () {
    expect(guestAccessibleRouteNames, {
      VerilyRouteNames.welcome,
      VerilyRouteNames.signIn,
      VerilyRouteNames.verificationRequest,
      VerilyRouteNames.link,
    });
  });

  testWidgets('a visitor starts at the front door', (tester) async {
    await _pumpApp(tester, signedIn: false);

    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('a signed-in person starts on Do inside the tabs', (
    tester,
  ) async {
    await _pumpApp(tester, signedIn: true);

    expect(find.byType(TabsShell), findsOneWidget);
    expect(find.byType(DoScreen), findsOneWidget);
  });

  test('the sign-in location says when the visitor has an account', () {
    expect(
      VerilyLocations.signIn(from: '/do', returning: true),
      '/sign-in?from=%2Fdo&account=returning',
    );
    expect(VerilyLocations.signIn(), '/sign-in');
  });

  for (final (location, startWithSignIn) in [
    ('/sign-in?account=returning', true),
    ('/sign-in?from=%2Fdo', false),
  ]) {
    testWidgets('$location opens the matching email form', (tester) async {
      // The kit's forms are measured for a phone and Verily's faces.
      await loadSkribbleFaces();
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      await _pumpApp(tester, signedIn: false);
      await _openDeepLink(tester, location);

      expect(
        tester.widget<SignInScreen>(find.byType(SignInScreen)).startWithSignIn,
        startWithSignIn,
      );
    });
  }

  testWidgets('a gated page asks a visitor to sign in and keeps the URL', (
    tester,
  ) async {
    await _pumpApp(tester, signedIn: false);
    await _openDeepLink(tester, '/actions/abc');

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.byType(ActionScreen), findsNothing);
  });

  testWidgets('an action link opens the action for a signed-in person', (
    tester,
  ) async {
    await _pumpApp(tester, signedIn: true);
    await _openDeepLink(tester, '/actions/abc');

    expect(
      tester.widget<ActionScreen>(find.byType(ActionScreen)).actionId,
      'abc',
    );
  });

  for (final (link, kind) in [
    ('verily://r/req_123', ComingSoonKind.verificationRequest),
    ('https://verily.fun/r/req_123', ComingSoonKind.verificationRequest),
    ('verily://link?app=abc', ComingSoonKind.appLink),
    ('https://verily.fun/link?app=abc', ComingSoonKind.appLink),
  ]) {
    testWidgets('$link lands on the coming-soon page', (tester) async {
      await _pumpApp(tester, signedIn: false);
      await _openDeepLink(tester, link);

      expect(
        tester.widget<ComingSoonScreen>(find.byType(ComingSoonScreen)).kind,
        kind,
      );
    });
  }
}
