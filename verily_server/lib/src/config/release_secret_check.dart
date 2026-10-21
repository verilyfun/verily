import 'package:monosecret/monosecret.dart';

/// Resolves a value-free production secret report through the Dart SDK.
Future<ResolutionReport> loadReleaseSecretReport({
  required String manifestPath,
}) => Monosecret.builder()
    .withPath(manifestPath)
    .withProfile('production')
    .withProvider('injected')
    .withReason('Validate Verily production secrets before release')
    .report();

/// Returns the required declarations that the selected provider could not fill.
List<String> missingRequiredSecretNames(ResolutionReport report) => report
    .secrets
    .where((secret) => secret.status == 'missing_required')
    .map((secret) => secret.name)
    .toList(growable: false);
