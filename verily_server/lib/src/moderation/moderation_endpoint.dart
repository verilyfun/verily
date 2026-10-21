import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/moderation/moderation_service.dart';

/// Authenticated reporting and creator appeals; no review authority.
class ModerationEndpoint extends Endpoint {
  ModerationEndpoint({ModerationService? service})
    : service = service ?? ModerationService();

  final ModerationService service;

  @override
  bool get requireLogin => true;

  Future<ModerationCaseStatusView> report(
    Session session, {
    required UuidValue actionDefinitionId,
    required String category,
    required String details,
    required String idempotencyKey,
  }) => service.report(
    session,
    actionDefinitionId: actionDefinitionId,
    category: category,
    details: details,
    idempotencyKey: idempotencyKey,
  );

  Future<ModerationCaseStatusView> getStatus(
    Session session, {
    required UuidValue caseId,
  }) => service.getStatus(session, caseId: caseId);

  Future<List<ModerationCaseStatusView>> listMine(
    Session session, {
    int limit = 30,
  }) => service.listMine(session, limit: limit);

  Future<ModerationCaseStatusView> appeal(
    Session session, {
    required UuidValue caseId,
    required String reason,
  }) => service.appeal(session, caseId: caseId, reason: reason);
}
