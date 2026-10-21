import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/evidence_storage/evidence_upload_service.dart';
import 'package:verily_server/src/generated/protocol.dart';

const evidenceUploadCleanupIdentifier = 'evidence-upload-cleanup-v1';

class EvidenceUploadCleanupFutureCall
    extends FutureCall<EvidenceUploadCleanupTask> {
  Future<void> cleanup(
    Session session,
    EvidenceUploadCleanupTask task,
  ) async {
    final deleted = await EvidenceUploadService().cleanupExpired(
      session,
      batchSize: task.batchSize,
    );
    session.log(
      'Evidence retention cleanup removed $deleted expired upload records.',
    );
  }
}
