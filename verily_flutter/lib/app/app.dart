import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:verily_flutter/app/router/app_router.dart';
import 'package:verily_flutter/app/theme/theme_mode_provider.dart';
import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_accessible_app_surface.dart';
import 'package:verily_flutter/app/widgets/verily_wired_scope.dart';
import 'package:verily_flutter/core/api_client.dart';
import 'package:verily_flutter/dev/development_overlay.dart';
import 'package:verily_flutter/dev/movement_tracking_preview_screen.dart';
import 'package:verily_flutter/features/account/account_session.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// The Verily app: router, themes, and the app-wide scopes.
class VerilyApp extends HookConsumerWidget {
  const VerilyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appShellKey = useState(0);
    final navigatorKey = useMemoized(GlobalKey<NavigatorState>.new);
    // Tells the router to re-run its redirect when someone signs in or out.
    final sessionChanged = useMemoized(() => ValueNotifier<int>(0));
    useEffect(() => sessionChanged.dispose, [sessionChanged]);
    ref.listen(
      accountSessionProvider.select((session) => session.isSignedIn),
      (previous, next) => sessionChanged.value++,
    );
    final router = useMemoized(
      () => buildAppRouter(
        navigatorKey: navigatorKey,
        isSignedIn: () => ref.read(accountSessionProvider).isSignedIn,
        refresh: sessionChanged,
      ),
      [appShellKey.value],
    );
    useEffect(() => router.dispose, [router]);
    final preference = ref.watch(verilyThemePreferenceProvider);
    final lightTheme = useMemoized(buildVerilyTheme);
    final darkTheme = useMemoized(
      () => buildVerilyTheme(brightness: Brightness.dark),
    );
    final serverConfig = ref.watch(serverConfigProvider);

    return MaterialApp.router(
      key: ValueKey(appShellKey.value),
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: preference.themeMode,
      routerConfig: router,
      builder: (context, child) => VerilyAccessibleAppSurface(
        // One Skribble scope above the navigator inks every route, dialog,
        // and sheet with the active palette.
        child: VerilyWiredScope(
          child: DevelopmentOverlay(
            navigatorKey: navigatorKey,
            serverUrl: serverConfig.apiUrl.toString(),
            onFullReload: () => appShellKey.value++,
            onFullRestart: DevelopmentRestartBoundary.restart,
            tools: [
              DevelopmentTool(
                key: VerilyTestKeys.developerMovementPreview,
                icon: VerilyIcons.run,
                title: context.l10n.developerMovementPreview,
                subtitle: context.l10n.developerMovementPreviewSubtitle,
                builder: (context) => const MovementTrackingPreviewScreen(),
              ),
            ],
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
