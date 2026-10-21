import 'package:flutter_driver/driver_extension.dart';

import 'package:verily_flutter/main.dart' as app;

/// The app with the Flutter Driver extension, for MCP tools and screenshots
/// in debug builds (`devenv shell dev:seeker` launches it).
///
/// Text entry emulation stays off unless `FLUTTER_DRIVER_TEXT_EMULATION` is
/// set, so the real Android keyboard opens during manual testing. MCP
/// text-entry automation uses `devenv shell dev:seeker:mcp`.
Future<void> main() async {
  const enableTextEntryEmulation = bool.fromEnvironment(
    'FLUTTER_DRIVER_TEXT_EMULATION',
  );
  enableFlutterDriverExtension(
    enableTextEntryEmulation: enableTextEntryEmulation,
  );
  await app.main();
}
