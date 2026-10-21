import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/action_verification/evidence_verification_worker.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// Durable entry point for one media verification job.
/// See [EvidenceVerificationWorker].
class EvidenceVerificationFutureCall
    extends FutureCall<EvidenceVerificationTask> {
  Future<void> verify(Session session, EvidenceVerificationTask task) {
    return EvidenceVerificationWorker().verify(session, task.evidenceId);
  }
}
