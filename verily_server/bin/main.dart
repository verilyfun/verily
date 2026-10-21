import 'dart:io';

import 'package:verily_server/server.dart';
import 'package:verily_server/src/config/serverpod_secret_bootstrap.dart';

/// Starts Serverpod after resolving its runtime secrets through Monosecret.
Future<void> main(List<String> args) async {
  if (serverpodSecretsAreLoaded()) {
    await run(args);
    return;
  }

  try {
    exitCode = await launchServerpodWithMonosecret(args);
  } on Object catch (error) {
    stderr.writeln('Unable to load Verily server secrets: $error');
    exitCode = 78;
  }
}
