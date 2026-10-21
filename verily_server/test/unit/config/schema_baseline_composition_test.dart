import 'dart:io';

import 'package:test/test.dart';

const _begin = '-- BEGIN VERILY SCHEMA CONTRACTS';
const _end = '-- END VERILY SCHEMA CONTRACTS';

void main() {
  group('fresh schema baseline composition', () {
    test('the reviewed supplement is composed exactly once and is current', () {
      final result = Process.runSync(
        Platform.resolvedExecutable,
        ['run', 'tool/compose_schema_baseline.dart', '--check'],
        workingDirectory: Directory.current.path,
      );

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');

      for (final schema in _baselineSchemas()) {
        final source = schema.readAsStringSync();
        expect(_occurrences(source, _begin), 1, reason: schema.path);
        expect(_occurrences(source, _end), 1, reason: schema.path);
        expect(source.indexOf(_begin), greaterThan(source.indexOf('BEGIN;')));
        expect(source.indexOf(_end), lessThan(source.lastIndexOf('COMMIT;')));
      }
    });

    test('the baseline contains the critical custom database backstops', () {
      for (final schema in _baselineSchemas()) {
        final source = schema.readAsStringSync();

        for (final contract in _reviewedContracts) {
          expect(
            source,
            contains(contract),
            reason: '${schema.path}: $contract',
          );
        }
      }
    });

    test('Serverpod owns the PostGIS extension, columns, and indexes', () {
      for (final schema in _baselineSchemas()) {
        final source = schema.readAsStringSync();
        final supplement = source.substring(source.indexOf(_begin));

        for (final generated in const [
          "EXECUTE 'CREATE EXTENSION IF NOT EXISTS postgis'",
          '"location" geography(Point,4326) NOT NULL,',
          '"location" geography(Point,4326),',
          '"verily_action_location_rule_location_idx" ON "verily_action_location_rule" USING gist ("location")',
          '"verily_action_evidence_location_idx" ON "verily_action_evidence" USING gist ("location")',
        ]) {
          expect(
            source.indexOf(generated),
            allOf(isNonNegative, lessThan(source.indexOf(_begin))),
            reason: '${schema.path}: $generated',
          );
        }

        // The reviewed supplement must not redefine spatial DDL that the
        // Serverpod model now owns.
        expect(supplement, isNot(contains('CREATE EXTENSION')));
        expect(supplement, isNot(contains('USING gist')));
        expect(supplement, isNot(contains('ST_Point(')));
        // Serverpod's development integrity check compares tables, columns,
        // indexes, and foreign keys with its definition, so the supplement
        // adds only checks, functions, and triggers.
        for (final forbidden in const [
          'CREATE INDEX',
          'CREATE UNIQUE INDEX',
          'FOREIGN KEY',
          'ADD COLUMN',
          'CREATE TABLE',
        ]) {
          expect(supplement, isNot(contains(forbidden)), reason: forbidden);
        }
      }
    });
  });
}

List<File> _baselineSchemas() {
  final registry = File('migrations/migration_registry.txt');
  final versions = registry
      .readAsLinesSync()
      .where(
        (line) => line.trim().isNotEmpty && !line.startsWith('#'),
      )
      .toList(growable: false);

  expect(versions, hasLength(1));

  // Serverpod provisions disposable and fresh databases from definition.sql,
  // while migration.sql is the deployment path. Checking both prevents a
  // protected upgrade schema from masking an unprotected clean install.
  return [
    File('migrations/${versions.single}/migration.sql'),
    File('migrations/${versions.single}/definition.sql'),
  ];
}

int _occurrences(String source, String value) =>
    value.allMatches(source).length;

/// Every reviewed backstop the composed baseline must carry.
final List<String> _reviewedContracts = [
  for (final name in [
    'abuse_assessment_check',
    'action_capacity_check',
    'ai_cost_check',
    'app_check',
    'app_confirmation_check',
    'app_key_check',
    'app_link_check',
    'attempt_verification_check',
    'capture_expiry_check',
    'decision_confidence_check',
    'evidence_bounds_check',
    'external_evidence_check',
    'inference_reservation_check',
    'location_bounds_check',
    'media_evidence_check',
    'media_rule_check',
    'moderation_audit_check',
    'moderation_case_check',
    'motion_bounds_check',
    'payout_wallet_check',
    'qr_expiry_check',
    'requirement_position_check',
    'reward_payout_check',
    'reward_pool_check',
    'spoken_challenge_check',
    'upload_bounds_check',
    'verification_retry_check',
    'vote_usage_check',
    'wallet_link_expiry_check',
  ])
    'CONSTRAINT verily_$name',
  for (final name in [
    'abuse_assessment_update_guard',
    'app_confirmation_update_guard',
    'external_requirement_exclusive_guard',
    'external_rule_creator_guard',
    'media_rule_kind_guard',
    'moderation_audit_update_guard',
    'reward_payout_pool_guard',
    'reward_pool_terms_guard',
  ])
    'CREATE TRIGGER verily_$name',
];
