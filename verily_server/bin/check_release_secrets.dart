import 'dart:io';

import 'package:verily_server/src/config/release_secret_check.dart';
import 'package:verily_server/src/config/serverpod_secret_bootstrap.dart';

Future<void> main() async {
  final manifestPath = findMonosecretManifest();
  if (manifestPath == null) {
    stderr.writeln('Unable to find monosecret.toml.');
    exitCode = 1;
    return;
  }

  try {
    final report = await loadReleaseSecretReport(manifestPath: manifestPath);
    final missing = missingRequiredSecretNames(report);
    if (missing.isNotEmpty) {
      stderr.writeln('Missing required production secrets:');
      for (final name in missing) {
        stderr.writeln('  - $name');
      }
      exitCode = 1;
      return;
    }

    stdout.writeln(
      'Monosecret production profile passed with injected values.',
    );
  } on Exception catch (error) {
    stderr.writeln('Monosecret production validation failed: $error');
    exitCode = 1;
  }
}
