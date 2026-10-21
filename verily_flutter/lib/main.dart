import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:verily_flutter/app/app.dart';
import 'package:verily_flutter/core/accessibility/verily_accessibility.dart';
import 'package:verily_flutter/dev/development_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
  runApp(
    const DevelopmentRestartBoundary(child: ProviderScope(child: VerilyApp())),
  );
  enableVerilyWebAccessibility();
}
