import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:verily_flutter/app/screens/placeholder_screen.dart';
import 'package:verily_flutter/app/theme/theme_mode_provider.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_accessible_app_surface.dart';
import 'package:verily_flutter/app/widgets/verily_wired_scope.dart';
import 'package:verily_flutter/dev/development_overlay.dart';
import 'package:verily_flutter/l10n/l10n.dart';

/// The Verily app shell.
///
/// Phase A shows a placeholder home; the router and real screens replace it
/// once the Serverpod client is available.
class VerilyApp extends HookConsumerWidget {
  const VerilyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appShellKey = useState(0);
    final navigatorKey = useMemoized(GlobalKey<NavigatorState>.new);
    final preference = ref.watch(verilyThemePreferenceProvider);
    final lightTheme = useMemoized(buildVerilyTheme);
    final darkTheme = useMemoized(
      () => buildVerilyTheme(brightness: Brightness.dark),
    );

    return MaterialApp(
      key: ValueKey(appShellKey.value),
      navigatorKey: navigatorKey,
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: preference.themeMode,
      builder: (context, child) => VerilyAccessibleAppSurface(
        // One Skribble scope above the navigator inks every route, dialog,
        // and sheet with the active palette.
        child: VerilyWiredScope(
          child: DevelopmentOverlay(
            navigatorKey: navigatorKey,
            onFullReload: () => appShellKey.value++,
            onFullRestart: DevelopmentRestartBoundary.restart,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
      home: const PlaceholderScreen(),
    );
  }
}
