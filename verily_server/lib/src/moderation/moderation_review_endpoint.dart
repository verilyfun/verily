import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/moderation/moderation_access.dart';
import 'package:verily_server/src/moderation/moderation_service.dart';

/// Staff-only case review and immutable audit access.
class ModerationReviewEndpoint extends Endpoint {
  ModerationReviewEndpoint({ModerationService? service})
    : service = service ?? ModerationService();

  final ModerationService service;

  @override
  bool get requireLogin => true;

  @override
  Set<Scope> get requiredScopes => {moderationReviewScope};

  Future<List<ModerationCaseStatusView>> listQueue(
    Session session, {
    int limit = 30,
  }) => service.listQueue(session, limit: limit);

  Future<ModerationCaseReviewView> getCase(
    Session session, {
    required UuidValue caseId,
  }) => service.getCase(session, caseId: caseId);

  Future<ModerationCaseStatusView> review(
    Session session, {
    required UuidValue caseId,
    required String decision,
    required String note,
  }) => service.review(session, caseId: caseId, decision: decision, note: note);

  Future<ModerationCaseStatusView> resolveAppeal(
    Session session, {
    required UuidValue caseId,
    required String decision,
    required String note,
  }) => service.resolveAppeal(
    session,
    caseId: caseId,
    decision: decision,
    note: note,
  );
}
