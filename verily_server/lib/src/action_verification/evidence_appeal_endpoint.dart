import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:verily_server/src/action_verification/evidence_appeal_service.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// Participants appeal a rejected proof once; the action's creator decides.
class EvidenceAppealEndpoint extends Endpoint {
  EvidenceAppealEndpoint({EvidenceAppealService? service})
    : service = service ?? EvidenceAppealService();

  final EvidenceAppealService service;

  @override
  bool get requireLogin => true;

  Future<EvidenceAppealView> submit(
    Session session, {
    required UuidValue attemptId,
    required String reason,
  }) {
    return service.submit(
      session,
      participantAuthUserId: session.authenticated!.authUserId,
      attemptId: attemptId,
      reason: reason,
    );
  }

  Future<EvidenceAppealView?> getMine(
    Session session, {
    required UuidValue attemptId,
  }) {
    return service.getMine(
      session,
      participantAuthUserId: session.authenticated!.authUserId,
      attemptId: attemptId,
    );
  }

  /// Pending appeals on the caller's own actions.
  Future<List<EvidenceAppealView>> listOwned(
    Session session, {
    int limit = 50,
  }) {
    return service.listOwned(
      session,
      creatorAuthUserId: session.authenticated!.authUserId,
      limit: limit,
    );
  }

  Future<EvidenceAppealView> resolve(
    Session session, {
    required UuidValue appealId,
    required EvidenceAppealStatus decision,
    required String note,
  }) {
    return service.resolve(
      session,
      creatorAuthUserId: session.authenticated!.authUserId,
      appealId: appealId,
      decision: decision,
      note: note,
    );
  }
}
