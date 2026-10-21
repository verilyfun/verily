import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/evidence_storage/evidence_media_types.dart';
import 'package:verily_server/src/evidence_storage/evidence_object_access.dart';

/// Prefix of the synthetic version ids local storage issues.
const localEvidenceVersionPrefix = 'local-sha256-';

/// Zero-configuration evidence storage for development and tests only.
///
/// Bytes live in Serverpod's database storage table and arrive through the
/// same client flow as production: an upload description, then
/// `FileUploader`. Serverpod's upload route enforces each description's own
/// size limit and deletes the description after one upload, and the upload
/// service refuses new descriptions once a proof is confirmed, so the
/// confirmed bytes cannot change afterwards. The version id is derived from
/// the SHA-256 of those bytes, and every review link re-checks it.
///
/// Startup refuses this storage in staging and production.
class LocalEvidenceStorage extends DatabaseCloudStorage
    implements EvidenceObjectAccess {
  LocalEvidenceStorage() : super(evidenceStorageId);

  @override
  Future<EvidenceObjectInspection?> inspectAndHash(
    Session session,
    String path,
  ) async {
    validateEvidencePath(path);
    // Serverpod stores direct uploads unverified until a server confirms
    // them; confirmation is this inspection.
    await verifyUpload(session: session, path: path);
    final ByteData data;
    final FileStat stat;
    try {
      final retrieved = await retrieveFileWithStat(
        session: session,
        path: path,
      );
      data = retrieved.file;
      stat = retrieved.stat;
    } on CloudStorageFileNotFoundException {
      return null;
    }
    final bytes = Uint8List.sublistView(data);
    final digest = sha256.convert(bytes).toString();
    return EvidenceObjectInspection(
      byteLength: bytes.length,
      contentType: stat.contentType,
      compatibleContentTypes: compatibleEvidenceContentTypes(
        bytes.length <= mediaSignatureLimit
            ? bytes
            : Uint8List.sublistView(bytes, 0, mediaSignatureLimit),
      ),
      versionId: localEvidenceVersionId(digest),
      sha256Digest: digest,
    );
  }

  @override
  Future<Uri> createReviewUrl(
    Session session,
    String path, {
    required String versionId,
    Duration expiration = const Duration(minutes: 5),
  }) async {
    validateEvidencePath(path);
    validateReviewExpiration(expiration);
    final data = await retrieveFile(session: session, path: path);
    final digest = sha256.convert(Uint8List.sublistView(data)).toString();
    if (localEvidenceVersionId(digest) != versionId) {
      throw CloudStorageException(
        'The pinned local evidence version is no longer stored.',
      );
    }
    return temporaryDownloadUrl(
      session: session,
      path: path,
      options: TemporaryDownloadUrlOptions(expirationDuration: expiration),
    );
  }
}

/// The synthetic, content-derived version id for local evidence bytes.
String localEvidenceVersionId(String sha256Digest) =>
    '$localEvidenceVersionPrefix$sha256Digest';
