import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/app/screens/sign_in_screen.dart';
import 'package:verily_flutter/app/screens/welcome_screen.dart';
import 'package:verily_flutter/app/shell/tabs_shell.dart';
import 'package:verily_flutter/features/account/account_required.dart';
import 'package:verily_flutter/features/account/auth_intent.dart';
import 'package:verily_flutter/features/app_link/app_link_screen.dart';
import 'package:verily_flutter/features/appeals/appeals_screen.dart';
import 'package:verily_flutter/features/apps/app_screen.dart';
import 'package:verily_flutter/features/apps/apps_screen.dart';
import 'package:verily_flutter/features/create/create_screen.dart';
import 'package:verily_flutter/features/create/editor/action_editor_screen.dart';
import 'package:verily_flutter/features/do/action_screen.dart';
import 'package:verily_flutter/features/do/do_screen.dart';
import 'package:verily_flutter/features/me/me_screen.dart';
import 'package:verily_flutter/features/review/review_queue_screen.dart';
import 'package:verily_flutter/features/settings/settings_screen.dart';
import 'package:verily_flutter/features/verify_request/verify_request_screen.dart';

/// Builds the app's router.
///
/// [isSignedIn] is read on every navigation; [refresh] fires when the
/// session changes so a signed-in visitor on the front door moves to Do.
GoRouter buildAppRouter({
  required bool Function() isSignedIn,
  required Listenable refresh,
  GlobalKey<NavigatorState>? navigatorKey,
  String initialLocation = VerilyRoutePaths.welcome,
}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: initialLocation,
    refreshListenable: refresh,
    redirect: (context, state) {
      // Deep links arrive as whole URIs (custom scheme or app link).
      if (deepLinkLocation(state.uri) case final location?) return location;
      if (state.uri.path == VerilyRoutePaths.welcome && isSignedIn()) {
        return VerilyRoutePaths.doTab;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: VerilyRoutePaths.welcome,
        name: VerilyRouteNames.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: VerilyRoutePaths.signIn,
        name: VerilyRouteNames.signIn,
        builder: (context, state) => _SignInRoute(
          from: state.uri.queryParameters['from'],
          returning:
              state.uri.queryParameters[VerilyLocations
                  .signInAccountParameter] ==
              VerilyLocations.signInReturningAccount,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => TabsShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: VerilyRoutePaths.doTab,
                name: VerilyRouteNames.doTab,
                builder: (context, state) =>
                    const AccountRequired(child: DoScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: VerilyRoutePaths.create,
                name: VerilyRouteNames.create,
                builder: (context, state) => const AccountRequired(
                  reason: AccountRequestReason.createAction,
                  child: CreateScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: VerilyRoutePaths.me,
                name: VerilyRouteNames.me,
                builder: (context, state) => const AccountRequired(
                  reason: AccountRequestReason.privateHistory,
                  child: MeScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      // `/actions/new` must come before `/actions/:actionId`.
      GoRoute(
        path: VerilyRoutePaths.actionNew,
        name: VerilyRouteNames.actionNew,
        builder: (context, state) => const AccountRequired(
          reason: AccountRequestReason.createAction,
          child: ActionEditorScreen(),
        ),
      ),
      GoRoute(
        path: VerilyRoutePaths.action,
        name: VerilyRouteNames.action,
        builder: (context, state) => AccountRequired(
          child: ActionScreen(actionId: state.pathParameters['actionId']!),
        ),
        routes: [
          GoRoute(
            path: 'edit',
            name: VerilyRouteNames.actionEdit,
            builder: (context, state) => AccountRequired(
              reason: AccountRequestReason.createAction,
              child: ActionEditorScreen(
                actionId: state.pathParameters['actionId'],
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: VerilyRoutePaths.reviews,
        name: VerilyRouteNames.reviews,
        builder: (context, state) =>
            const AccountRequired(child: ReviewQueueScreen()),
      ),
      GoRoute(
        path: VerilyRoutePaths.appeals,
        name: VerilyRouteNames.appeals,
        builder: (context, state) => const AccountRequired(
          reason: AccountRequestReason.privateHistory,
          child: AppealsScreen(),
        ),
      ),
      GoRoute(
        path: VerilyRoutePaths.apps,
        name: VerilyRouteNames.apps,
        builder: (context, state) => const AccountRequired(
          reason: AccountRequestReason.manageApps,
          child: AppsScreen(),
        ),
        routes: [
          GoRoute(
            path: ':appId',
            name: VerilyRouteNames.app,
            builder: (context, state) => AccountRequired(
              reason: AccountRequestReason.manageApps,
              child: AppScreen(appId: state.pathParameters['appId']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: VerilyRoutePaths.settings,
        name: VerilyRouteNames.settings,
        builder: (context, state) =>
            const AccountRequired(child: SettingsScreen()),
      ),
      // Opened by other Apps. The account prompt shows in place, so the
      // request or link is still on screen once the person has signed in.
      GoRoute(
        path: VerilyRoutePaths.verificationRequest,
        name: VerilyRouteNames.verificationRequest,
        builder: (context, state) => AccountRequired(
          reason: AccountRequestReason.answerRequest,
          child: VerifyRequestScreen(
            requestId: state.pathParameters['requestId']!,
          ),
        ),
      ),
      GoRoute(
        path: VerilyRoutePaths.link,
        name: VerilyRouteNames.link,
        builder: (context, state) => AccountRequired(
          reason: AccountRequestReason.linkApp,
          child: AppLinkScreen(query: state.uri.queryParameters),
        ),
      ),
    ],
  );
}

/// The account prompt as a destination. `from` is the page to return to, so
/// the requested destination survives sign-in.
class _SignInRoute extends StatelessWidget {
  const _SignInRoute({this.from, this.returning = false});

  final String? from;
  final bool returning;

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      startWithSignIn: returning,
      onSignedIn: () {
        final router = GoRouter.of(context);
        if (from case final destination? when destination.startsWith('/')) {
          router.go(destination);
          return;
        }
        router.goNamed(VerilyRouteNames.doTab);
      },
      onCancel: () {
        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
          return;
        }
        router.goNamed(VerilyRouteNames.welcome);
      },
    );
  }
}
