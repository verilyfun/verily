import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:verily_server/src/action_verification/action_authoring_service.dart';
import 'package:verily_server/src/action_verification/action_draft_generator.dart';
import 'package:verily_server/src/action_verification/action_verification_service.dart';
import 'package:verily_server/src/action_verification/model_input_security.dart';
import 'package:verily_server/src/ai_usage/ai_usage_guard.dart';
import 'package:verily_server/src/apps/app_pull_check_service.dart';
import 'package:verily_server/src/evidence_storage/media_evidence_service.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// Actions for everyone: creators design and publish their own, and
/// participants discover them, capture proof, and complete them.
///
/// Every method requires sign-in and derives the caller from the session.
/// Creator methods re-check ownership of the action on every call.
class ActionVerificationEndpoint extends Endpoint {
  ActionVerificationEndpoint({
    ActionVerificationService? service,
    ActionAuthoringService? authoring,
    ActionDraftGenerator? draftGenerator,
    MediaEvidenceService? media,
    AiUsageGuard? usageGuard,
    AppPullCheckService? pullChecks,
  }) : service = service ?? ActionVerificationService(),
       pullChecks = pullChecks ?? AppPullCheckService(),
       authoring = authoring ?? ActionAuthoringService(),
       draftGenerator = draftGenerator ?? ActionDraftGenerator(),
       media = media ?? MediaEvidenceService(),
       usageGuard = usageGuard ?? AiUsageGuard();

  final ActionVerificationService service;
  final ActionAuthoringService authoring;
  final ActionDraftGenerator draftGenerator;
  final MediaEvidenceService media;
  final AiUsageGuard usageGuard;
  final AppPullCheckService pullChecks;

  @override
  bool get requireLogin => true;

  UuidValue _caller(Session session) => session.authenticated!.authUserId;

  Future<List<ActionTemplate>> listTemplates(Session session) async {
    return service.listTemplates();
  }

  /// Drafts an action from a plain-language idea. Throws
  /// [ActionDraftingUnavailableException] when AI drafting is off, paused,
  /// or out of today's allowance; templates still work.
  Future<ActionDraftProposal> draftActionFromPrompt(
    Session session, {
    required String prompt,
  }) async {
    final normalizedPrompt = ModelInputSecurity.validateCreatorPrompt(prompt);
    if (!draftGenerator.isAvailable) {
      throw ActionDraftingUnavailableException(
        message: draftingUnavailableMessage,
      );
    }
    try {
      return await usageGuard.run(
        session,
        authUserId: _caller(session),
        operation: aiActionDraftOperation,
        task: () => draftGenerator.generate(prompt: normalizedPrompt),
      );
    } on AiUsageLimitException catch (error) {
      throw ActionDraftingUnavailableException(message: error.message);
    }
  }

  Future<ActionOpportunity> createAction(
    Session session,
    CreateActionDefinitionRequest request,
  ) {
    return authoring.createAction(
      session,
      authUserId: _caller(session),
      request: request,
    );
  }

  Future<ActionOpportunity> saveActionDraft(
    Session session,
    CreateActionDefinitionRequest request,
  ) {
    return authoring.saveActionDraft(
      session,
      authUserId: _caller(session),
      request: request,
    );
  }

  Future<ActionOpportunity> previewAction(
    Session session, {
    required UuidValue actionId,
  }) {
    return authoring.previewAction(
      session,
      authUserId: _caller(session),
      actionId: actionId,
    );
  }

  Future<List<ActionOpportunity>> listOwnedActions(
    Session session, {
    int limit = 50,
  }) {
    return authoring.listOwnedActions(
      session,
      authUserId: _caller(session),
      limit: limit,
    );
  }

  Future<ActionOpportunity> publishAction(
    Session session, {
    required UuidValue actionId,
    required int expectedRevision,
  }) {
    return authoring.publishAction(
      session,
      authUserId: _caller(session),
      actionId: actionId,
      expectedRevision: expectedRevision,
    );
  }

  Future<ActionOpportunity> pauseAction(
    Session session, {
    required UuidValue actionId,
    required int expectedRevision,
  }) {
    return authoring.pauseAction(
      session,
      authUserId: _caller(session),
      actionId: actionId,
      expectedRevision: expectedRevision,
    );
  }

  /// Creates a short-lived, single-use venue code for a live QR action.
  Future<ActionQrChallengeView> createQrChallenge(
    Session session, {
    required UuidValue requirementId,
    int validitySeconds = 300,
  }) {
    return authoring.createQrChallenge(
      session,
      authUserId: _caller(session),
      requirementId: requirementId,
      validitySeconds: validitySeconds,
    );
  }

  Future<List<ActionOpportunity>> listAvailableActions(
    Session session, {
    int limit = 50,
  }) {
    return service.listAvailableActions(
      session,
      authUserId: _caller(session),
      limit: limit,
    );
  }

  /// One action by id, for a deep-linked action page. Throws
  /// [ResourceNotFoundException] when it does not exist or is not visible.
  Future<ActionOpportunity> getAction(
    Session session, {
    required UuidValue actionId,
  }) {
    return service.getAction(
      session,
      authUserId: _caller(session),
      actionId: actionId,
    );
  }

  /// Live actions whose public place is within [radiusKm] (clamped to
  /// 0.1-50 km) of the given point, nearest first. The point is coarsened
  /// and never stored.
  Future<List<ActionOpportunity>> listNearbyActions(
    Session session, {
    required double latitude,
    required double longitude,
    required double radiusKm,
    int limit = 30,
  }) {
    return service.listNearbyActions(
      session,
      authUserId: _caller(session),
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      limit: limit,
    );
  }

  Future<ActionAttemptView> beginAttempt(
    Session session, {
    required UuidValue actionId,
    required String idempotencyKey,
  }) {
    return service.beginAttempt(
      session,
      authUserId: _caller(session),
      actionId: actionId,
      idempotencyKey: idempotencyKey,
    );
  }

  /// The live word to say while recording a video or audio proof. Call it
  /// before recording; the upload binds the recording to this word.
  Future<ActionSpokenChallengeView> issueSpokenChallenge(
    Session session, {
    required UuidValue attemptId,
    required UuidValue requirementId,
  }) {
    return service.issueSpokenChallenge(
      session,
      authUserId: _caller(session),
      attemptId: attemptId,
      requirementId: requirementId,
    );
  }

  /// Binds the next proof to a fresh device-integrity request committing to
  /// [evidenceBindingHash].
  Future<ActionCaptureChallengeView> createCaptureChallenge(
    Session session, {
    required UuidValue attemptId,
    required UuidValue requirementId,
    required String evidenceBindingHash,
  }) {
    return service.createCaptureChallenge(
      session,
      authUserId: _caller(session),
      attemptId: attemptId,
      requirementId: requirementId,
      evidenceBindingHash: evidenceBindingHash,
    );
  }

  /// Location checks, venue codes, and phone-motion traces.
  Future<EvidenceSubmissionResult> submitEvidence(
    Session session,
    ActionEvidenceInput input,
  ) {
    return service.submitEvidence(
      session,
      authUserId: _caller(session),
      input: input,
    );
  }

  /// A short-lived private upload for one video, photo, or audio proof.
  /// The returned description is passed to Serverpod's `FileUploader`.
  Future<String> requestMediaUpload(
    Session session, {
    required UuidValue attemptId,
    required UuidValue requirementId,
    required String contentType,
    required int byteLength,
  }) {
    return media.requestUpload(
      session,
      authUserId: _caller(session),
      attemptId: attemptId,
      requirementId: requirementId,
      contentType: contentType,
      byteLength: byteLength,
    );
  }

  /// Verifies a completed upload and submits its server-measured identity.
  /// Automated verification then finishes the attempt on its own.
  Future<EvidenceSubmissionResult> confirmMediaUpload(
    Session session,
    MediaUploadConfirmation confirmation,
  ) {
    return media.confirmUpload(
      session,
      authUserId: _caller(session),
      confirmation: confirmation,
    );
  }

  /// "I did it" for a pull-verified `externalApp` requirement: Verily asks
  /// the App's webhook. [reference] is optional text the participant typed
  /// (at most 120 characters), such as a username or order number.
  Future<EvidenceSubmissionResult> requestAppVerification(
    Session session, {
    required UuidValue attemptId,
    required UuidValue requirementId,
    String? reference,
  }) {
    return pullChecks.requestVerification(
      session,
      authUserId: _caller(session),
      attemptId: attemptId,
      requirementId: requirementId,
      reference: reference,
    );
  }

  /// Where the caller's "I did it" on a pull-verified `externalApp`
  /// requirement stands, in the same shape `requestAppVerification`
  /// answers; null before they ask. Reading it calls nobody.
  Future<EvidenceSubmissionResult?> getAppVerification(
    Session session, {
    required UuidValue attemptId,
    required UuidValue requirementId,
  }) {
    return pullChecks.currentVerification(
      session,
      authUserId: _caller(session),
      attemptId: attemptId,
      requirementId: requirementId,
    );
  }

  Future<ActionAttemptView> completeAttempt(
    Session session,
    UuidValue attemptId,
  ) {
    return service.completeAttempt(
      session,
      authUserId: _caller(session),
      attemptId: attemptId,
    );
  }

  Future<List<ActionAttemptView>> listMyAttempts(
    Session session, {
    int limit = 50,
  }) {
    return service.listMyAttempts(
      session,
      authUserId: _caller(session),
      limit: limit,
    );
  }
}
