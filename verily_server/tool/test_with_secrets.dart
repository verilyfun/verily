import 'dart:async';
import 'dart:io';

import 'package:verily_server/src/config/serverpod_secret_bootstrap.dart';

/// Runs the Serverpod test suite with Monosecret's public test profile.
///
/// The test profile resolves only from the process environment and its
/// public, test-only defaults, so this never reaches 1Password.
Future<void> main(List<String> arguments) async {
  final resolved = await resolveVerilySecrets(
    profile: 'test',
    reason: 'Run the Verily Serverpod test suite',
  );

  try {
    final process = await Process.start(
      Platform.resolvedExecutable,
      ['test', ...arguments],
      environment: {
        ...Platform.environment,
        for (final entry in resolved.fields.entries)
          if (entry.value != null) entry.key: entry.value!,
      },
      mode: ProcessStartMode.inheritStdio,
    );
    final signalSubscriptions = <StreamSubscription<ProcessSignal>>[];
    if (!Platform.isWindows) {
      signalSubscriptions
        ..add(ProcessSignal.sigint.watch().listen(process.kill))
        ..add(ProcessSignal.sigterm.watch().listen(process.kill));
    }

    try {
      exitCode = await process.exitCode;
    } finally {
      for (final subscription in signalSubscriptions) {
        await subscription.cancel();
      }
    }
  } finally {
    await resolved.close();
  }
}
