import 'dart:convert';
import 'dart:io';

import 'package:verily_server/src/readiness/verily_production_gate.dart';

void main(List<String> arguments) {
  try {
    final report = const VerilyProductionGate().evaluate(Platform.environment);
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(report.toJson()));

    final requireDeployable = arguments.contains('--require-deployable');
    if (requireDeployable && report.stage == VerilyReleaseStage.development) {
      stderr.writeln(
        'A production release must select VERILY_RELEASE_STAGE=closed-pilot.',
      );
      exitCode = 1;
      return;
    }
    if (!report.releaseAllowed) {
      stderr.writeln('Verily production gates are not satisfied.');
      exitCode = 1;
    }
  } on FormatException catch (error) {
    stderr.writeln('Verily production gate configuration is invalid: $error');
    exitCode = 1;
  }
}
