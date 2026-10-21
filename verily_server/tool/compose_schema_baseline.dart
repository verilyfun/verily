import 'dart:io';

const _start = '-- BEGIN VERILY SCHEMA CONTRACTS';
const _end = '-- END VERILY SCHEMA CONTRACTS';

/// Adds reviewed database invariants to the generated fresh-install baseline.
///
/// Serverpod owns model/column generation. PostgreSQL owns cross-row and exact
/// numeric backstops that cannot be represented in the model YAML. Keeping the
/// supplement separate makes regeneration deterministic and reviewable.
void main(List<String> arguments) {
  final checkOnly = arguments.length == 1 && arguments.single == '--check';

  if (arguments.isNotEmpty && !checkOnly) {
    stderr.writeln(
      'Usage: dart run tool/compose_schema_baseline.dart [--check]',
    );
    exitCode = 64;
    return;
  }

  final registry = File('migrations/migration_registry.txt');
  final versions = registry.readAsLinesSync().where(
    (line) => line.trim().isNotEmpty && !line.startsWith('#'),
  );

  if (versions.length != 1) {
    stderr.writeln('This tool only composes one fresh-install baseline.');
    exitCode = 1;
    return;
  }

  final supplement = File(
    'tool/schema_contracts.sql',
  ).readAsStringSync().trim();
  final directory = 'migrations/${versions.single}';

  for (final file in [
    File('$directory/migration.sql'),
    File('$directory/definition.sql'),
  ]) {
    _compose(file, supplement, checkOnly: checkOnly);
  }
}

void _compose(File file, String supplement, {required bool checkOnly}) {
  final source = file.readAsStringSync();
  final marker = RegExp(
    r'-- BEGIN VERILY SCHEMA CONTRACTS[\s\S]*?-- END VERILY SCHEMA CONTRACTS\n*',
  );
  final generated = source.replaceAll(marker, '');
  final commit = generated.lastIndexOf('COMMIT;');

  if (commit < 0 || !generated.trimLeft().startsWith('BEGIN;')) {
    throw StateError('Expected a transactional Serverpod migration.');
  }

  final composed = generated.replaceRange(
    commit,
    commit,
    '$_start\n$supplement\n$_end\n\n',
  );

  if (checkOnly) {
    if (source != composed) {
      stderr.writeln('Baseline schema contracts are missing or out of date.');
      exitCode = 1;
    }
    return;
  }

  file.writeAsStringSync(composed);
  stdout.writeln('Composed schema contracts into ${file.path}.');
}
