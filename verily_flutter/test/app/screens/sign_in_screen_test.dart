import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import 'package:verily_flutter/app/screens/sign_in_screen.dart';
import 'package:verily_flutter/features/account/account_session.dart';
import 'package:verily_flutter/features/account/auth_intent.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import '../../support/skribble_faces.dart';
import '../../support/test_app.dart';

const _signedOut = AccountSession.signedOut();

Future<void> _pumpSignIn(
  WidgetTester tester, {
  AccountRequestReason? reason,
  VoidCallback? onSignedIn,
  VoidCallback? onCancel,
  AccountSession session = _signedOut,
  bool emailEnabled = false,
}) => pumpVerilyPage(
  tester,
  SignInScreen(
    reason: reason,
    onSignedIn: onSignedIn ?? () {},
    onCancel: onCancel,
    emailEnabled: emailEnabled,
  ),
  session: session,
);

void main() {
  for (final (reason, heading) in [
    (null, 'Sign in to Verily'),
    (AccountRequestReason.doAction, 'Sign in to do this action'),
    (AccountRequestReason.createAction, 'Sign in to post an action'),
    (
      AccountRequestReason.privateHistory,
      'Sign in to see your proof and payouts',
    ),
    (AccountRequestReason.manageApps, 'Sign in to manage your Verily Apps'),
    (AccountRequestReason.answerRequest, 'Sign in to answer this request'),
    (AccountRequestReason.linkApp, 'Sign in to link this app'),
  ]) {
    testWidgets('asks for an account in words that fit ${reason?.name}', (
      tester,
    ) async {
      await _pumpSignIn(tester, reason: reason);

      expect(find.text(heading), findsOneWidget);
      expect(
        tester.getSemantics(find.text(heading)).getSemanticsData().headingLevel,
        1,
      );
    });
  }

  setUpAll(loadSkribbleFaces);

  // The kit's forms sit in fixed-height boxes; on the Seeker they fit at any
  // text size because the screen keeps them at the base scale.
  for (final textScale in [1.0, 1.3, 2.0]) {
    testWidgets('fits the email forms on a Seeker at ${textScale}x text', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpVerilyPage(
        tester,
        SignInScreen(
          reason: AccountRequestReason.doAction,
          onSignedIn: () {},
          onCancel: () {},
        ),
        session: _signedOut,
        physicalSize: const Size(1080, 2400),
        devicePixelRatio: 2.625,
        useAppTypeface: true,
      );
      await tester.pump();

      expect(find.byType(EmailSignInWidget), findsOneWidget);
      expect(find.text('Sign up with email'), findsOneWidget);
      expect(find.text('Have an account?\u00A0'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // The kit's sign-in step has the other prompt in the same kind of row,
      // and more fields in the same fixed box.
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in with email'), findsOneWidget);
      expect(find.text('New here?\u00A0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('opens on signing in for someone who has an account', (
    tester,
  ) async {
    await pumpVerilyPage(
      tester,
      SignInScreen(onSignedIn: () {}, startWithSignIn: true),
      session: _signedOut,
      physicalSize: const Size(1080, 2400),
      devicePixelRatio: 2.625,
      useAppTypeface: true,
    );
    await tester.pump();

    expect(find.text('Sign in with email'), findsOneWidget);
    expect(find.text('Sign up with email'), findsNothing);
  });

  testWidgets('says so plainly when this build offers no sign-in', (
    tester,
  ) async {
    await _pumpSignIn(tester);

    expect(find.text("Sign-in isn't available in this build."), findsOneWidget);
    expect(find.byType(SignInWidget), findsNothing);
  });

  testWidgets('"Not now" leaves and keeps the place', (tester) async {
    var cancelled = 0;
    await _pumpSignIn(
      tester,
      reason: AccountRequestReason.doAction,
      onCancel: () => cancelled++,
    );

    expect(
      find.text(
        "Your place is saved. Sign in when you're ready and we'll bring you "
        'back.',
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(find.byKey(VerilyTestKeys.signInCancel));
    await tester.tap(find.byKey(VerilyTestKeys.signInCancel));
    await tester.pump();

    expect(cancelled, 1);
  });

  testWidgets('has no way out when the route offers none', (tester) async {
    await _pumpSignIn(tester);

    expect(find.byKey(VerilyTestKeys.signInCancel), findsNothing);
  });

  testWidgets('finishes exactly once when the session already has an account', (
    tester,
  ) async {
    var finished = 0;
    await _pumpSignIn(
      tester,
      session: testSignedInSession,
      onSignedIn: () => finished++,
    );
    await tester.pump();
    await tester.pump();

    expect(finished, 1);
  });
}
