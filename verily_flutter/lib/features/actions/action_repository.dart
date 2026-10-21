import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/core/api_client.dart';

/// Every `actionVerification` call the app makes, apart from evidence (see
/// `EvidenceService`).
///
/// The server derives the caller from the session and re-checks ownership on
/// every creator call, so nothing here passes an account id.
abstract interface class ActionRepository {
  // Creating.
  Future<List<ActionTemplate>> listTemplates();

  /// Throws `ActionDraftingUnavailableException` when AI drafting is off or
  /// today's allowance is spent; templates always work.
  Future<ActionDraftProposal> draftFromPrompt(String prompt);
  Future<ActionOpportunity> createAction(CreateActionDefinitionRequest request);
  Future<ActionOpportunity> saveDraft(CreateActionDefinitionRequest request);

  /// The creator's own view of one of their actions. Throws
  /// [ResourceNotFoundException] for an action that is not theirs.
  Future<ActionOpportunity> preview(UuidValue actionId);
  Future<List<ActionOpportunity>> listOwned();
  Future<ActionOpportunity> publish(ActionOpportunity action);
  Future<ActionOpportunity> pause(ActionOpportunity action);

  /// A short-lived, single-use venue code for a QR requirement.
  Future<ActionQrChallengeView> createQrChallenge(
    UuidValue requirementId, {
    Duration validity = const Duration(minutes: 5),
  });

  // Doing.
  Future<List<ActionOpportunity>> listAvailable();

  /// One action as a participant sees it: any published public action,
  /// including paused and completed ones, or the caller's own draft. Throws
  /// [ResourceNotFoundException] for anything else.
  Future<ActionOpportunity> getAction(UuidValue actionId);

  /// Live actions with a place within [radiusKm] (0.1 to 50), nearest first.
  /// The server coarsens the point to about 100 m and never stores it.
  Future<List<ActionOpportunity>> listNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  });

  /// Opens (or returns) the caller's attempt for the current period.
  Future<ActionAttemptView> beginAttempt(UuidValue actionId);

  /// The word to say while recording. Must be fetched before recording
  /// starts; the server binds it to the upload.
  Future<ActionSpokenChallengeView> issueSpokenChallenge({
    required UuidValue attemptId,
    required UuidValue requirementId,
  });
  Future<ActionAttemptView> completeAttempt(UuidValue attemptId);
  Future<List<ActionAttemptView>> listMyAttempts();

  /// "I did it" on a pull-verified App proof: Verily asks the App's webhook
  /// and answers with where the check stands (`status` null while the App
  /// has not decided). Asking again while the App is deciding makes no new
  /// call. [reference] is the participant's optional note for the App.
  Future<EvidenceSubmissionResult> requestAppVerification({
    required UuidValue attemptId,
    required UuidValue requirementId,
    String? reference,
  });

  /// Where the caller's "I did it" on a pull-verified App proof stands, in
  /// the shape [requestAppVerification] answers; null before they ask.
  /// Reading it never calls the App.
  Future<EvidenceSubmissionResult?> getAppVerification({
    required UuidValue attemptId,
    required UuidValue requirementId,
  });
}

class ServerpodActionRepository implements ActionRepository {
  ServerpodActionRepository(this._client, {this._uuid = const Uuid()});

  final Client _client;
  final Uuid _uuid;

  EndpointActionVerification get _actions => _client.actionVerification;

  @override
  Future<List<ActionTemplate>> listTemplates() => _actions.listTemplates();

  @override
  Future<ActionDraftProposal> draftFromPrompt(String prompt) =>
      _actions.draftActionFromPrompt(prompt: prompt);

  @override
  Future<ActionOpportunity> createAction(
    CreateActionDefinitionRequest request,
  ) => _actions.createAction(request);

  @override
  Future<ActionOpportunity> saveDraft(CreateActionDefinitionRequest request) =>
      _actions.saveActionDraft(request);

  @override
  Future<ActionOpportunity> preview(UuidValue actionId) =>
      _actions.previewAction(actionId: actionId);

  @override
  Future<List<ActionOpportunity>> listOwned() =>
      _actions.listOwnedActions(limit: 50);

  @override
  Future<ActionOpportunity> publish(ActionOpportunity action) =>
      _actions.publishAction(
        actionId: action.id,
        expectedRevision: action.revision,
      );

  @override
  Future<ActionOpportunity> pause(ActionOpportunity action) =>
      _actions.pauseAction(
        actionId: action.id,
        expectedRevision: action.revision,
      );

  @override
  Future<ActionQrChallengeView> createQrChallenge(
    UuidValue requirementId, {
    Duration validity = const Duration(minutes: 5),
  }) => _actions.createQrChallenge(
    requirementId: requirementId,
    validitySeconds: validity.inSeconds,
  );

  @override
  Future<List<ActionOpportunity>> listAvailable() =>
      _actions.listAvailableActions(limit: 100);

  @override
  Future<ActionOpportunity> getAction(UuidValue actionId) =>
      _actions.getAction(actionId: actionId);

  @override
  Future<List<ActionOpportunity>> listNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) => _actions.listNearbyActions(
    latitude: latitude,
    longitude: longitude,
    radiusKm: radiusKm,
    limit: 50,
  );

  @override
  Future<ActionAttemptView> beginAttempt(UuidValue actionId) =>
      _actions.beginAttempt(
        actionId: actionId,
        // A fresh key per tap: the server still returns the existing attempt
        // for this period, and a retried request with the same key is safe.
        idempotencyKey: 'app-${_uuid.v4()}',
      );

  @override
  Future<ActionSpokenChallengeView> issueSpokenChallenge({
    required UuidValue attemptId,
    required UuidValue requirementId,
  }) => _actions.issueSpokenChallenge(
    attemptId: attemptId,
    requirementId: requirementId,
  );

  @override
  Future<ActionAttemptView> completeAttempt(UuidValue attemptId) =>
      _actions.completeAttempt(attemptId);

  @override
  Future<List<ActionAttemptView>> listMyAttempts() =>
      _actions.listMyAttempts(limit: 50);

  @override
  Future<EvidenceSubmissionResult> requestAppVerification({
    required UuidValue attemptId,
    required UuidValue requirementId,
    String? reference,
  }) => _actions.requestAppVerification(
    attemptId: attemptId,
    requirementId: requirementId,
    reference: reference,
  );

  @override
  Future<EvidenceSubmissionResult?> getAppVerification({
    required UuidValue attemptId,
    required UuidValue requirementId,
  }) => _actions.getAppVerification(
    attemptId: attemptId,
    requirementId: requirementId,
  );
}

final actionRepositoryProvider = Provider<ActionRepository>(
  (ref) => ServerpodActionRepository(ref.watch(verilyClientProvider)),
);
