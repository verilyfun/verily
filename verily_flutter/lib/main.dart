import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import 'package:verily_flutter/app/app.dart';
import 'package:verily_flutter/app/theme/verily_icon_catalog.dart';
import 'package:verily_flutter/core/accessibility/verily_accessibility.dart';
import 'package:verily_flutter/core/api_client.dart';
import 'package:verily_flutter/core/config/server_config.dart';
import 'package:verily_flutter/core/provider_retry.dart';
import 'package:verily_flutter/dev/development_overlay.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // The splash stays until the saved session is restored, so a signed-in
  // person never sees the front door flash before Do.
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  registerVerilyIconCatalog();
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  final config = await resolveServerConfig();
  final client = createVerilyClient(config);
  try {
    await client.auth.initialize().timeout(const Duration(seconds: 3));
  } on TimeoutException {
    // Restoring the session is local; if it stalls the app still opens
    // signed out and updates when the session arrives.
    debugPrint('Session restore is taking longer than expected.');
  }
  FlutterNativeSplash.remove();

  runApp(
    DevelopmentRestartBoundary(
      child: ProviderScope(
        retry: noAutomaticProviderRetry,
        overrides: [
          verilyClientProvider.overrideWithValue(client),
          serverConfigProvider.overrideWithValue(config),
        ],
        child: const VerilyApp(),
      ),
    ),
  );
  enableVerilyWebAccessibility();
}
