import 'dart:io';

import 'package:verily_server/src/config/serverpod_secret_bootstrap.dart';

/// Fragments each installed constraint definition must contain.
const _constraintFragments = <String, List<String>>{
  'verily_ai_cost_check': ['"costUnits"'],
  'verily_action_capacity_check': ['"verifiedCompletions"', '"actionKey"'],
  'verily_requirement_position_check': ['"position"', '"requirementKey"'],
  'verily_capture_expiry_check': ['"expiresAt"', '"evidenceBindingHash"'],
  'verily_qr_expiry_check': ['"expiresAt"', '"createdAt"'],
  'verily_decision_confidence_check': ['confidence'],
  'verily_verification_retry_check': ['"attemptCount"'],
  'verily_moderation_audit_check': ['event', 'note'],
  'verily_wallet_link_expiry_check': ['"walletAddress"', 'nonce'],
  'verily_attempt_verification_check': ['"rewardOutcome" IS NULL'],
  'verily_location_bounds_check': ['"radiusMeters"', 'st_y'],
  'verily_media_rule_check': [
    "'photo'",
    '"spokenChallengeRequired"',
    '"movementKind"',
  ],
  'verily_motion_bounds_check': [
    '"targetRepetitions"',
    '"motionType"',
    '"maxPeakAccelerationMetersPerSecondSquared"',
  ],
  'verily_evidence_bounds_check': [
    "'motion'",
    '"motionTraceJson" IS NOT NULL',
    '"motionTraceSha256"',
  ],
  'verily_media_evidence_check': [
    '"storageVersionId" IS NOT NULL',
    '"spokenChallengeWord"',
    '"durationSeconds" IS NULL',
  ],
  'verily_external_evidence_check': ["'externalApp'", '"sha256Digest"'],
  'verily_spoken_challenge_check': ['word', '"boundAt"'],
  'verily_upload_bounds_check': ['"byteLength"', '"retainUntil"'],
  'verily_vote_usage_check': ['"spokenChallengeVerdict"'],
  'verily_inference_reservation_check': ['"reservedMicros"'],
  'verily_abuse_assessment_check': [
    '"assessmentKey"',
    '"policyVersion"',
    '"signalCodes"',
  ],
  'verily_moderation_case_check': ['category', 'status'],
  'verily_app_check': ['"revokedAt" IS NOT NULL', '"rateWindowCount"'],
  'verily_app_key_check': ['"keyId"', '"secretHash"'],
  'verily_app_link_check': ['subject'],
  'verily_app_confirmation_check': [
    '"payloadDigest"',
    '"attemptId" IS NOT NULL',
  ],
  'verily_payout_wallet_check': ['"walletAddress"'],
  'verily_reward_pool_check': [
    '"payoutsReserved"',
    '"payoutsReleased"',
    '"maxPayouts"',
    '"refundAfter"',
    '"maxWinsPerAccount"',
  ],
  'verily_reward_payout_check': ['"payoutIndex"', '"recipientWallet"'],
};

const _triggerContracts =
    <String, ({String table, String function, List<String> events})>{
      'verily_abuse_assessment_update_guard': (
        table: 'verily_abuse_risk_assessment',
        function: 'verily_reject_update_or_delete',
        events: ['BEFORE', 'DELETE', 'UPDATE'],
      ),
      'verily_moderation_audit_update_guard': (
        table: 'verily_moderation_audit_entry',
        function: 'verily_reject_update_or_delete',
        events: ['BEFORE', 'DELETE', 'UPDATE'],
      ),
      'verily_app_confirmation_update_guard': (
        table: 'verily_app_confirmation',
        function: 'verily_reject_update_or_delete',
        events: ['BEFORE', 'DELETE', 'UPDATE'],
      ),
      'verily_external_requirement_exclusive_guard': (
        table: 'verily_action_requirement',
        function: 'verily_external_requirement_exclusive_guard',
        events: ['BEFORE', 'INSERT', 'UPDATE'],
      ),
      'verily_external_rule_creator_guard': (
        table: 'verily_action_external_rule',
        function: 'verily_external_rule_creator_guard',
        events: ['BEFORE', 'INSERT', 'UPDATE'],
      ),
      'verily_media_rule_kind_guard': (
        table: 'verily_action_media_rule',
        function: 'verily_media_rule_kind_guard',
        events: ['BEFORE', 'INSERT', 'UPDATE'],
      ),
      'verily_reward_payout_pool_guard': (
        table: 'verily_reward_payout',
        function: 'verily_reward_payout_pool_guard',
        events: ['BEFORE', 'INSERT', 'UPDATE'],
      ),
      'verily_reward_pool_terms_guard': (
        table: 'verily_reward_pool',
        function: 'verily_reward_pool_terms_guard',
        events: ['BEFORE UPDATE'],
      ),
    };

/// Read-only verification of the custom contracts installed in one database.
///
/// The database must be selected explicitly through Serverpod's environment
/// variables. This tool never applies migrations, creates schemas, or writes
/// rows; it fails when the selected database lacks a reviewed constraint or
/// trigger from the composed baseline.
Future<void> main(List<String> arguments) async {
  if (arguments.isNotEmpty) {
    stderr.writeln('Usage: dart run tool/verify_schema_contracts.dart');
    exitCode = 64;
    return;
  }

  final environment = Platform.environment;
  final host = environment['SERVERPOD_DATABASE_HOST']?.trim();
  final port = environment['SERVERPOD_DATABASE_PORT']?.trim();
  final database = environment['SERVERPOD_DATABASE_NAME']?.trim();
  final user = environment['SERVERPOD_DATABASE_USER']?.trim().isNotEmpty == true
      ? environment['SERVERPOD_DATABASE_USER']!.trim()
      : 'postgres';

  if (host == null ||
      host.isEmpty ||
      port == null ||
      int.tryParse(port) == null ||
      database == null ||
      !RegExp(r'^[A-Za-z0-9_]{1,63}$').hasMatch(database)) {
    stderr.writeln(
      'Set an explicit, valid Serverpod database host, port, and name.',
    );
    exitCode = 64;
    return;
  }

  final secrets = await resolveVerilySecrets(
    profile: 'test',
    reason: 'Read-only verification of the isolated schema baseline',
  );

  try {
    final password = secrets.fields['SERVERPOD_DATABASE_PASSWORD'];
    final result = await Process.run(
      'psql',
      [
        '--host=$host',
        '--port=$port',
        '--username=$user',
        '--dbname=$database',
        '--no-psqlrc',
        '--tuples-only',
        '--no-align',
        '--field-separator=|',
        '--set=ON_ERROR_STOP=1',
        '--command=${_inventoryQuery()}',
      ],
      environment: {
        ...environment,
        'PGPASSWORD': ?password,
      }..remove('OP_SERVICE_ACCOUNT_TOKEN'),
    );

    if (result.exitCode != 0) {
      stderr.write(result.stderr);
      exitCode = result.exitCode;
      return;
    }

    final rows = (result.stdout as String)
        .split('\n')
        .where((line) => line.isNotEmpty)
        .map((line) => line.split('|'))
        .toList(growable: false);
    final currentDatabase = [
      for (final row in rows)
        if (row.length == 2 && row[0] == 'database') row[1],
    ].singleOrNull;
    final installedConstraints = {
      for (final row in rows)
        if (row.length == 3 && row[0] == 'constraint') row[1]: row[2],
    };
    final installedTriggers = {
      for (final row in rows)
        if (row.length == 5 && row[0] == 'trigger')
          row[1]: (table: row[2], function: row[3], definition: row[4]),
    };
    final failures = <String>[
      for (final contract in _constraintFragments.entries)
        if (installedConstraints[contract.key] case final definition?
            when contract.value.every(
              (fragment) => definition.toLowerCase().contains(
                fragment.toLowerCase(),
              ),
            ))
          ...[]
        else
          'constraint ${contract.key}',
      for (final contract in _triggerContracts.entries)
        if (installedTriggers[contract.key] case final installed?
            when installed.table == contract.value.table &&
                installed.function == contract.value.function &&
                contract.value.events.every(installed.definition.contains))
          ...[]
        else
          'trigger ${contract.key}',
    ];

    if (currentDatabase != database || failures.isNotEmpty) {
      stderr.writeln('Schema contract verification failed for $database.');
      if (currentDatabase != database) {
        stderr.writeln('Connected to unexpected database: $currentDatabase');
      }
      if (failures.isNotEmpty) {
        stderr.writeln(
          'Missing or invalid contracts: ${(failures..sort()).join(', ')}',
        );
      }
      exitCode = 1;
      return;
    }

    stdout.writeln(
      'Verified ${_constraintFragments.length} constraints and '
      '${_triggerContracts.length} triggers in $database.',
    );
  } finally {
    await secrets.close();
  }
}

String _inventoryQuery() {
  String names(Iterable<String> values) =>
      values.map((value) => "'$value'").join(', ');
  return '''
BEGIN TRANSACTION READ ONLY;
SELECT 'database', current_database();
SELECT 'constraint', conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conname = ANY(ARRAY[${names(_constraintFragments.keys)}])
ORDER BY conname;
SELECT 'trigger', t.tgname, c.relname, p.proname, pg_get_triggerdef(t.oid)
FROM pg_trigger t
JOIN pg_class c ON c.oid = t.tgrelid
JOIN pg_proc p ON p.oid = t.tgfoid
WHERE NOT t.tgisinternal AND t.tgname = ANY(ARRAY[${names(_triggerContracts.keys)}])
ORDER BY tgname;
COMMIT;
''';
}
