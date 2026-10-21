import 'dart:async';
import 'dart:io';

import 'package:monosecret/monosecret.dart';

const _loadedMarker = 'VERILY_MONOSECRET_LOADED';
const _onePasswordToken = 'OP_SERVICE_ACCOUNT_TOKEN';

/// Selects the Monosecret profile that corresponds to Serverpod's run mode.
String monosecretProfileForServerpod(
  List<String> arguments, {
  Map<String, String> environment = const {},
}) {
  final explicitProfile = environment['MONOSECRET_PROFILE']?.trim();
  if (explicitProfile != null && explicitProfile.isNotEmpty) {
    return explicitProfile;
  }

  for (var index = 0; index < arguments.length; index += 1) {
    final argument = arguments[index];
    if (argument.startsWith('--mode=')) {
      return argument.substring('--mode='.length);
    }
    if (argument == '--mode' && index + 1 < arguments.length) {
      return arguments[index + 1];
    }
  }

  final runMode = environment['runmode']?.trim();
  return runMode == null || runMode.isEmpty ? 'development' : runMode;
}

/// Starts a fresh Serverpod process with secrets resolved by the Dart SDK.
///
/// Serverpod reads its password environment during synchronous construction,
/// so the small parent process resolves Monosecret once and injects the values
/// into an otherwise identical child process. The marker prevents recursion.
Future<int> launchServerpodWithMonosecret(
  List<String> arguments, {
  Map<String, String>? environment,
  String? executable,
  Uri? script,
}) async {
  final sourceEnvironment = environment ?? Platform.environment;
  final profile = monosecretProfileForServerpod(
    arguments,
    environment: sourceEnvironment,
  );
  final command = serverpodChildCommand(
    arguments,
    executable: executable ?? Platform.resolvedExecutable,
    script: script ?? Platform.script,
  );
  final configuredManifestPath = sourceEnvironment['MONOSECRET_FILE']?.trim();
  final manifestPath =
      configuredManifestPath == null || configuredManifestPath.isEmpty
      ? findMonosecretManifest()
      : File(configuredManifestPath).absolute.path;
  final provider = sourceEnvironment['MONOSECRET_PROVIDER']?.trim();

  final resolved = await resolveVerilySecrets(
    profile: profile,
    manifestPath: manifestPath,
    provider: provider,
    reason: 'Start the Verily Serverpod backend',
  );

  try {
    final childEnvironment = serverpodChildEnvironment(
      sourceEnvironment: sourceEnvironment,
      resolvedFields: resolved.fields,
      profile: profile,
    );
    final child = await Process.start(
      command.executable,
      command.arguments,
      environment: childEnvironment,
      mode: ProcessStartMode.inheritStdio,
    );

    final signalSubscriptions = <StreamSubscription<ProcessSignal>>[];
    if (!Platform.isWindows) {
      signalSubscriptions
        ..add(ProcessSignal.sigint.watch().listen(child.kill))
        ..add(ProcessSignal.sigterm.watch().listen(child.kill));
    }

    try {
      return await child.exitCode;
    } finally {
      for (final subscription in signalSubscriptions) {
        await subscription.cancel();
      }
    }
  } finally {
    await resolved.close();
  }
}

/// Finds the nearest MonoSecret manifest without changing the working directory.
String? findMonosecretManifest({Directory? start}) {
  var directory = (start ?? Directory.current).absolute;
  while (true) {
    final candidate = File(
      '${directory.path}${Platform.pathSeparator}monosecret.toml',
    );
    if (candidate.existsSync()) return candidate.absolute.path;

    final parent = directory.parent;
    if (parent.path == directory.path) return null;
    directory = parent;
  }
}

/// Resolves Verily's declared secrets for one runtime profile.
Future<Resolved> resolveVerilySecrets({
  required String profile,
  required String reason,
  String? manifestPath,
  String? provider,
}) async {
  final effectiveManifestPath = manifestPath == null || manifestPath.isEmpty
      ? findMonosecretManifest()
      : File(manifestPath).absolute.path;
  final originalDirectory = Directory.current;

  try {
    if (effectiveManifestPath != null) {
      Directory.current = File(effectiveManifestPath).parent;
    }
    return await Monosecret.builder()
        .withPath(effectiveManifestPath)
        .withProfile(profile)
        .withProvider(provider == null || provider.isEmpty ? null : provider)
        .withReason(reason)
        .load();
  } finally {
    Directory.current = originalDirectory;
  }
}

/// Builds the runtime environment without forwarding provider credentials.
Map<String, String> serverpodChildEnvironment({
  required Map<String, String> sourceEnvironment,
  required Map<String, String?> resolvedFields,
  required String profile,
}) => <String, String>{
  ...sourceEnvironment,
  for (final entry in resolvedFields.entries)
    if (entry.value != null && entry.key != _onePasswordToken)
      entry.key: entry.value!,
  'MONOSECRET_PROFILE': profile,
  _loadedMarker: '1',
}..remove(_onePasswordToken);

/// True only in the child process that has received resolved secret values.
bool serverpodSecretsAreLoaded({Map<String, String>? environment}) =>
    (environment ?? Platform.environment)[_loadedMarker] == '1';

/// Returns the executable and arguments needed to re-run this Dart program.
({String executable, List<String> arguments}) serverpodChildCommand(
  List<String> serverpodArguments, {
  required String executable,
  required Uri script,
}) {
  final scriptPath = File(script.toFilePath()).absolute.path;
  final executablePath = File(executable).absolute.path;
  final isCompiledExecutable = File(scriptPath).absolute.path == executablePath;

  return (
    executable: executable,
    arguments: [
      if (!isCompiledExecutable) scriptPath,
      ...serverpodArguments,
    ],
  );
}
