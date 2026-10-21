import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/evidence_storage/backblaze_evidence_storage.dart';
import 'package:verily_server/src/evidence_storage/local_evidence_storage.dart';

/// Where private evidence bytes live.
enum EvidenceStorageMode {
  /// A private, versioned Backblaze B2 bucket. The only production mode.
  b2,

  /// Serverpod's database storage, so a fresh checkout runs end to end
  /// without object storage. Development and test only.
  local,
}

/// Selects and builds the evidence storage for one run mode.
///
/// `VERILY_EVIDENCE_STORAGE` may be `b2` or `local`. When unset, development
/// and test use B2 if all five B2 values are present and local storage
/// otherwise. Staging and production always require B2 and refuse to start
/// without it, so a missing secret can never fall back to the database.
abstract final class EvidenceStorageSelection {
  static EvidenceStorageMode resolveMode({
    required String runMode,
    required Map<String, String> environment,
    required PasswordReader readPassword,
  }) {
    final allowsLocal =
        runMode == ServerpodRunMode.development ||
        runMode == ServerpodRunMode.test;
    final configured = environment['VERILY_EVIDENCE_STORAGE']
        ?.trim()
        .toLowerCase();
    final mode = switch (configured) {
      null || '' when allowsLocal && !_hasAnyB2Value(readPassword) =>
        EvidenceStorageMode.local,
      null || '' => EvidenceStorageMode.b2,
      'b2' => EvidenceStorageMode.b2,
      'local' => EvidenceStorageMode.local,
      _ => throw StateError('VERILY_EVIDENCE_STORAGE must be b2 or local.'),
    };
    if (mode == EvidenceStorageMode.local && !allowsLocal) {
      throw StateError(
        'Local evidence storage is only available in development and test '
        'run modes. Configure the private Backblaze B2 evidence bucket.',
      );
    }
    return mode;
  }

  /// Builds the storage for [mode]. B2 configuration errors propagate so
  /// startup fails before any request is accepted.
  static CloudStorage create({
    required EvidenceStorageMode mode,
    required PasswordReader readPassword,
  }) => switch (mode) {
    EvidenceStorageMode.b2 =>
      BackblazeEvidenceStorageConfiguration.fromPasswords(
        readPassword,
      ).createStorage(),
    EvidenceStorageMode.local => LocalEvidenceStorage(),
  };

  static bool _hasAnyB2Value(PasswordReader readPassword) =>
      BackblazeEvidenceStorageConfiguration.passwordAliases.any(
        (alias) => (readPassword(alias)?.trim() ?? '').isNotEmpty,
      );
}
