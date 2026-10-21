import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/screens/sign_in_screen.dart';
import 'package:verily_flutter/features/account/account_session.dart';
import 'package:verily_flutter/features/app_link/app_link_repository.dart';
import 'package:verily_flutter/features/app_link/app_link_screen.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import '../../support/skribble_faces.dart';
import '../verify_request/support/fakes.dart';

const _redirect = 'com.slopper.app://verily';

String _link({String? app, String? redirect = _redirect, String? state}) => Uri(
  path: '/link',
  queryParameters: {
    'app': app ?? requestAppId.toString(),
    'redirect_uri': ?redirect,
    'state': state ?? 'abc',
  },
).toString();

void main() {
  setUpAll(loadSkribbleFaces);

  group('AppLinkRequest.fromQuery', () {
    test('reads the App, its return address, and the state', () {
      final request = AppLinkRequest.fromQuery({
        'app': requestAppId.toString(),
        'redirect_uri': _redirect,
        'state': 'abc',
      });
      expect(request?.appId, requestAppId);
      expect(request?.redirectUri, _redirect);
      expect(request?.state, 'abc');
    });

    test('an empty state is no state', () {
      final request = AppLinkRequest.fromQuery({
        'app': requestAppId.toString(),
        'redirect_uri': _redirect,
        'state': '',
      });
      expect(request?.state, isNull);
    });

    test('a link without an App or a return address is unusable', () {
      expect(AppLinkRequest.fromQuery({'redirect_uri': _redirect}), isNull);
      expect(
        AppLinkRequest.fromQuery({'app': requestAppId.toString()}),
        isNull,
      );
      expect(
        AppLinkRequest.fromQuery({'app': 'slopper', 'redirect_uri': _redirect}),
        isNull,
      );
    });
  });

  testWidgets('says who wants to link and what they get', (tester) async {
    final fakes = DeepLinkFakes();
    await pumpDeepLink(tester, fakes, location: _link());

    expect(find.text('Link an app'), findsOneWidget);
    expect(find.text('From Slopper · slopper.app'), findsOneWidget);
    expect(
      find.text('Slopper wants to link with your Verily account'),
      findsOneWidget,
    );
    expect(
      find.text(
        "Once linked, Slopper can tell Verily when you've done its actions.",
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'A private ID made only for Slopper. Never your name, email, or '
        'account.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        "Nothing else. It can't see your proof, payouts, or other apps.",
      ),
      findsOneWidget,
    );
    final asked = fakes.links.requests.single;
    expect(asked.appId, requestAppId);
    expect(asked.redirectUri, _redirect);
    expect(asked.state, 'abc');
    expect(fakes.links.calls, ['describe']);
  });

  testWidgets('an App linked before says linking again confirms it', (
    tester,
  ) async {
    final fakes = DeepLinkFakes(
      links: FakeAppLinkRepository(alreadyLinked: true),
    );
    await pumpDeepLink(tester, fakes, location: _link());

    expect(
      find.text(
        "You've linked Slopper before. Linking again confirms it's still you.",
      ),
      findsOneWidget,
    );
  });

  testWidgets('linking returns to the App with its code', (tester) async {
    final fakes = DeepLinkFakes();
    await pumpDeepLink(tester, fakes, location: _link());

    await tapDeepLink(tester, find.byKey(VerilyTestKeys.appLinkApprove));

    expect(fakes.links.calls, ['describe', 'approve']);
    final opened = fakes.launcher.launched.single;
    expect(opened.queryParameters['code'], 'link-code');
    expect(opened.queryParameters['state'], 'abc');
    expect(find.text('Returning you to Slopper'), findsOneWidget);
    expect(
      find.text('Slopper is linked to your Verily account.'),
      findsOneWidget,
    );
    expect(find.textContaining('link-code'), findsNothing);
  });

  testWidgets('not linking returns to the App with the refusal', (
    tester,
  ) async {
    final fakes = DeepLinkFakes();
    await pumpDeepLink(tester, fakes, location: _link());

    await tapDeepLink(tester, find.byKey(VerilyTestKeys.appLinkDecline));

    expect(fakes.links.calls, ['describe', 'decline']);
    expect(
      fakes.launcher.launched.single.queryParameters['error'],
      'access_denied',
    );
    expect(find.text('Not linked'), findsOneWidget);
    expect(
      find.text("Slopper wasn't linked. Nothing was shared."),
      findsOneWidget,
    );
  });

  testWidgets('a link missing its parts is refused without a server call', (
    tester,
  ) async {
    final fakes = DeepLinkFakes();
    await pumpDeepLink(tester, fakes, location: _link(redirect: null));

    expect(find.text("This link doesn't work"), findsOneWidget);
    expect(fakes.links.calls, isEmpty);
  });

  for (final (label, error, text) in [
    (
      'an unregistered return address',
      AppPlatformException(
        problem: AppPlatformProblem.linkRequestInvalid,
        message: 'x',
      ),
      "This link doesn't work",
    ),
    (
      'too many tries',
      AppPlatformException(
        problem: AppPlatformProblem.rateLimited,
        message: 'x',
      ),
      "That's a lot of requests for now",
    ),
    (
      'a revoked App',
      AppUnavailableException(
        appName: 'Slopper',
        message: 'This app was revoked by its creator.',
      ),
      "Slopper isn't available",
    ),
    ('no connection', Exception('offline'), "We couldn't load this link"),
  ]) {
    testWidgets('$label is said plainly', (tester) async {
      final fakes = DeepLinkFakes(
        links: FakeAppLinkRepository(describeError: error),
      );
      await pumpDeepLink(tester, fakes, location: _link());

      expect(find.text(text), findsOneWidget);
      expect(find.byKey(VerilyTestKeys.appLinkApprove), findsNothing);
    });
  }

  testWidgets('a failed load can be retried', (tester) async {
    final fakes = DeepLinkFakes(
      links: FakeAppLinkRepository(describeError: Exception('offline')),
    );
    await pumpDeepLink(tester, fakes, location: _link());

    fakes.links.describeError = null;
    await tapDeepLink(tester, find.text('Try again'));
    expect(find.byKey(VerilyTestKeys.appLinkApprove), findsOneWidget);
  });

  testWidgets('a failed answer stays on the consent and can be sent again', (
    tester,
  ) async {
    final fakes = DeepLinkFakes();
    fakes.links.approveError = Exception('offline');
    await pumpDeepLink(tester, fakes, location: _link());

    await tapDeepLink(tester, find.byKey(VerilyTestKeys.appLinkApprove));
    expect(find.byKey(VerilyTestKeys.verifyRequestNotice), findsOneWidget);
    expect(fakes.launcher.launched, isEmpty);

    fakes.links.approveError = null;
    await tapDeepLink(tester, find.byKey(VerilyTestKeys.appLinkApprove));
    expect(fakes.launcher.launched, hasLength(1));
  });

  testWidgets('signing in shows the link request where it opened', (
    tester,
  ) async {
    final fakes = DeepLinkFakes(
      session: TestSession(const AccountSession.signedOut()),
    );
    await pumpDeepLink(tester, fakes, location: _link(), useAppTypeface: true);

    expect(find.text('Sign in to link this app'), findsOneWidget);
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(fakes.links.calls, isEmpty);

    fakes.session.signIn();
    await settleDeepLink(tester);
    expect(find.byType(AppLinkScreen), findsOneWidget);
    expect(find.byKey(VerilyTestKeys.appLinkApprove), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('fits a compact phone at 1.3x text (${brightness.name})', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpDeepLink(
        tester,
        DeepLinkFakes(),
        location: _link(),
        physicalSize: const Size(840, 1800),
        brightness: brightness,
        useAppTypeface: true,
      );

      expect(tester.takeException(), isNull);
    });
  }
}
