import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:verily_server/src/action_verification/evidence_review_service.dart';
import 'package:verily_server/src/generated/protocol.dart';

const evidenceReviewScope = Scope('evidence.review');

/// Verily's scoped reviewers decide proof sent to a person.
class EvidenceReviewEndpoint extends Endpoint {
  EvidenceReviewEndpoint({EvidenceReviewService? service})
    : service = service ?? EvidenceReviewService();

  final EvidenceReviewService service;

  @override
  bool get requireLogin => true;

  @override
  Set<Scope> get requiredScopes => {evidenceReviewScope};

  Future<List<EvidenceReviewQueueItem>> listQueue(
    Session session, {
    int limit = 30,
  }) {
    return service.listQueue(
      session,
      reviewerAuthUserId: session.authenticated!.authUserId,
      limit: limit,
    );
  }

  Future<ActionAttemptView> review(
    Session session, {
    required UuidValue evidenceId,
    required EvidenceDecisionStatus decision,
    required String note,
  }) {
    return service.review(
      session,
      reviewerAuthUserId: session.authenticated!.authUserId,
      evidenceId: evidenceId,
      decision: decision,
      note: note,
    );
  }
}
