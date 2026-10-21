/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _ida;

import 'package:http/http.dart' as _i85jenna;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _iacc;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _iaic;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'package:verily_client/src/protocol/action_verification/action_attempt_view.dart'
    as _ir431rrk;
import 'package:verily_client/src/protocol/action_verification/action_capture_challenge_view.dart'
    as _itq9cig8;
import 'package:verily_client/src/protocol/action_verification/action_draft_proposal.dart'
    as _if2jk5sg;
import 'package:verily_client/src/protocol/action_verification/action_evidence_input.dart'
    as _ie2q4cr4;
import 'package:verily_client/src/protocol/action_verification/action_opportunity.dart'
    as _ijjtlylw;
import 'package:verily_client/src/protocol/action_verification/action_qr_challenge_view.dart'
    as _i81fl04r;
import 'package:verily_client/src/protocol/action_verification/action_spoken_challenge_view.dart'
    as _idk923ry;
import 'package:verily_client/src/protocol/action_verification/action_template.dart'
    as _i6d3vqey;
import 'package:verily_client/src/protocol/action_verification/create_action_definition_request.dart'
    as _ivnldkuj;
import 'package:verily_client/src/protocol/action_verification/evidence_appeal_status.dart'
    as _ito2zfn8;
import 'package:verily_client/src/protocol/action_verification/evidence_appeal_view.dart'
    as _igtzj0f1;
import 'package:verily_client/src/protocol/action_verification/evidence_decision_status.dart'
    as _irim9waa;
import 'package:verily_client/src/protocol/action_verification/evidence_review_queue_item.dart'
    as _iyuppglq;
import 'package:verily_client/src/protocol/action_verification/evidence_submission_result.dart'
    as _is1oqp1g;
import 'package:verily_client/src/protocol/action_verification/media_upload_confirmation.dart'
    as _iy5c6735;
import 'package:verily_client/src/protocol/apps/app_confirmation_view.dart'
    as _iw9760io;
import 'package:verily_client/src/protocol/apps/linking/app_link_redirect.dart'
    as _ietd10id;
import 'package:verily_client/src/protocol/apps/linking/app_link_request_view.dart'
    as _ihri8xdm;
import 'package:verily_client/src/protocol/apps/verily_app_credential.dart'
    as _i3hnfj5e;
import 'package:verily_client/src/protocol/apps/verily_app_link_view.dart'
    as _i7ba7git;
import 'package:verily_client/src/protocol/apps/verily_app_view.dart'
    as _in92p10u;
import 'package:verily_client/src/protocol/apps/webhooks/app_webhook_delivery_view.dart'
    as _ifzy4ji6;
import 'package:verily_client/src/protocol/apps/webhooks/verily_app_webhook_secret.dart'
    as _iwmhqfps;
import 'package:verily_client/src/protocol/moderation/moderation_case_review_view.dart'
    as _ics7hcmp;
import 'package:verily_client/src/protocol/moderation/moderation_case_status_view.dart'
    as _ie976x46;
import 'package:verily_client/src/protocol/rewards/payout_wallet_link_challenge_view.dart'
    as _izs3rc7f;
import 'package:verily_client/src/protocol/rewards/payout_wallet_view.dart'
    as _iuosx0t6;
import 'package:verily_client/src/protocol/rewards/reward_end_plan.dart'
    as _i8qz9pd7;
import 'package:verily_client/src/protocol/rewards/reward_funding_plan.dart'
    as _iq3ahgh8;
import 'package:verily_client/src/protocol/rewards/reward_payout_view.dart'
    as _isztzkpq;
import 'package:verily_client/src/protocol/rewards/reward_pool_view.dart'
    as _i68mfray;
import 'package:verily_client/src/protocol/verification_requests/verification_request_redirect.dart'
    as _iv7cvvng;
import 'package:verily_client/src/protocol/verification_requests/verification_request_view.dart'
    as _izhqijgv;

import 'protocol.dart' as _il2as5qe;

/// {@category Endpoint}
class EndpointAccountLifecycle extends _isc.EndpointRef {
  EndpointAccountLifecycle(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'accountLifecycle';

  _ida.Future<DateTime> closeAccount({required String confirmation}) =>
      caller.callServerEndpoint<DateTime>(
        'accountLifecycle',
        'closeAccount',
        {'confirmation': confirmation},
      );
}

/// Actions for everyone: creators design and publish their own, and
/// participants discover them, capture proof, and complete them.
///
/// Every method requires sign-in and derives the caller from the session.
/// Creator methods re-check ownership of the action on every call.
/// {@category Endpoint}
class EndpointActionVerification extends _isc.EndpointRef {
  EndpointActionVerification(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'actionVerification';

  _ida.Future<List<_i6d3vqey.ActionTemplate>> listTemplates() =>
      caller.callServerEndpoint<List<_i6d3vqey.ActionTemplate>>(
        'actionVerification',
        'listTemplates',
        {},
      );

  /// Drafts an action from a plain-language idea. Throws
  /// [ActionDraftingUnavailableException] when AI drafting is off, paused,
  /// or out of today's allowance; templates still work.
  _ida.Future<_if2jk5sg.ActionDraftProposal> draftActionFromPrompt({
    required String prompt,
  }) => caller.callServerEndpoint<_if2jk5sg.ActionDraftProposal>(
    'actionVerification',
    'draftActionFromPrompt',
    {'prompt': prompt},
  );

  _ida.Future<_ijjtlylw.ActionOpportunity> createAction(
    _ivnldkuj.CreateActionDefinitionRequest request,
  ) => caller.callServerEndpoint<_ijjtlylw.ActionOpportunity>(
    'actionVerification',
    'createAction',
    {'request': request},
  );

  _ida.Future<_ijjtlylw.ActionOpportunity> saveActionDraft(
    _ivnldkuj.CreateActionDefinitionRequest request,
  ) => caller.callServerEndpoint<_ijjtlylw.ActionOpportunity>(
    'actionVerification',
    'saveActionDraft',
    {'request': request},
  );

  _ida.Future<_ijjtlylw.ActionOpportunity> previewAction({
    required _isc.UuidValue actionId,
  }) => caller.callServerEndpoint<_ijjtlylw.ActionOpportunity>(
    'actionVerification',
    'previewAction',
    {'actionId': actionId},
  );

  _ida.Future<List<_ijjtlylw.ActionOpportunity>> listOwnedActions({
    required int limit,
  }) => caller.callServerEndpoint<List<_ijjtlylw.ActionOpportunity>>(
    'actionVerification',
    'listOwnedActions',
    {'limit': limit},
  );

  _ida.Future<_ijjtlylw.ActionOpportunity> publishAction({
    required _isc.UuidValue actionId,
    required int expectedRevision,
  }) => caller.callServerEndpoint<_ijjtlylw.ActionOpportunity>(
    'actionVerification',
    'publishAction',
    {
      'actionId': actionId,
      'expectedRevision': expectedRevision,
    },
  );

  _ida.Future<_ijjtlylw.ActionOpportunity> pauseAction({
    required _isc.UuidValue actionId,
    required int expectedRevision,
  }) => caller.callServerEndpoint<_ijjtlylw.ActionOpportunity>(
    'actionVerification',
    'pauseAction',
    {
      'actionId': actionId,
      'expectedRevision': expectedRevision,
    },
  );

  /// Creates a short-lived, single-use venue code for a live QR action.
  _ida.Future<_i81fl04r.ActionQrChallengeView> createQrChallenge({
    required _isc.UuidValue requirementId,
    required int validitySeconds,
  }) => caller.callServerEndpoint<_i81fl04r.ActionQrChallengeView>(
    'actionVerification',
    'createQrChallenge',
    {
      'requirementId': requirementId,
      'validitySeconds': validitySeconds,
    },
  );

  _ida.Future<List<_ijjtlylw.ActionOpportunity>> listAvailableActions({
    required int limit,
  }) => caller.callServerEndpoint<List<_ijjtlylw.ActionOpportunity>>(
    'actionVerification',
    'listAvailableActions',
    {'limit': limit},
  );

  /// Live actions whose public place is within [radiusKm] (clamped to
  /// 0.1-50 km) of the given point, nearest first. The point is coarsened
  /// and never stored.
  _ida.Future<List<_ijjtlylw.ActionOpportunity>> listNearbyActions({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required int limit,
  }) => caller.callServerEndpoint<List<_ijjtlylw.ActionOpportunity>>(
    'actionVerification',
    'listNearbyActions',
    {
      'latitude': latitude,
      'longitude': longitude,
      'radiusKm': radiusKm,
      'limit': limit,
    },
  );

  _ida.Future<_ir431rrk.ActionAttemptView> beginAttempt({
    required _isc.UuidValue actionId,
    required String idempotencyKey,
  }) => caller.callServerEndpoint<_ir431rrk.ActionAttemptView>(
    'actionVerification',
    'beginAttempt',
    {
      'actionId': actionId,
      'idempotencyKey': idempotencyKey,
    },
  );

  /// The live word to say while recording a video or audio proof. Call it
  /// before recording; the upload binds the recording to this word.
  _ida.Future<_idk923ry.ActionSpokenChallengeView> issueSpokenChallenge({
    required _isc.UuidValue attemptId,
    required _isc.UuidValue requirementId,
  }) => caller.callServerEndpoint<_idk923ry.ActionSpokenChallengeView>(
    'actionVerification',
    'issueSpokenChallenge',
    {
      'attemptId': attemptId,
      'requirementId': requirementId,
    },
  );

  /// Binds the next proof to a fresh device-integrity request committing to
  /// [evidenceBindingHash].
  _ida.Future<_itq9cig8.ActionCaptureChallengeView> createCaptureChallenge({
    required _isc.UuidValue attemptId,
    required _isc.UuidValue requirementId,
    required String evidenceBindingHash,
  }) => caller.callServerEndpoint<_itq9cig8.ActionCaptureChallengeView>(
    'actionVerification',
    'createCaptureChallenge',
    {
      'attemptId': attemptId,
      'requirementId': requirementId,
      'evidenceBindingHash': evidenceBindingHash,
    },
  );

  /// Location checks, venue codes, and phone-motion traces.
  _ida.Future<_is1oqp1g.EvidenceSubmissionResult> submitEvidence(
    _ie2q4cr4.ActionEvidenceInput input,
  ) => caller.callServerEndpoint<_is1oqp1g.EvidenceSubmissionResult>(
    'actionVerification',
    'submitEvidence',
    {'input': input},
  );

  /// A short-lived private upload for one video, photo, or audio proof.
  /// The returned description is passed to Serverpod's `FileUploader`.
  _ida.Future<String> requestMediaUpload({
    required _isc.UuidValue attemptId,
    required _isc.UuidValue requirementId,
    required String contentType,
    required int byteLength,
  }) => caller.callServerEndpoint<String>(
    'actionVerification',
    'requestMediaUpload',
    {
      'attemptId': attemptId,
      'requirementId': requirementId,
      'contentType': contentType,
      'byteLength': byteLength,
    },
  );

  /// Verifies a completed upload and submits its server-measured identity.
  /// Automated verification then finishes the attempt on its own.
  _ida.Future<_is1oqp1g.EvidenceSubmissionResult> confirmMediaUpload(
    _iy5c6735.MediaUploadConfirmation confirmation,
  ) => caller.callServerEndpoint<_is1oqp1g.EvidenceSubmissionResult>(
    'actionVerification',
    'confirmMediaUpload',
    {'confirmation': confirmation},
  );

  /// "I did it" for a pull-verified `externalApp` requirement: Verily asks
  /// the App's webhook. [reference] is optional text the participant typed
  /// (at most 120 characters), such as a username or order number.
  _ida.Future<_is1oqp1g.EvidenceSubmissionResult> requestAppVerification({
    required _isc.UuidValue attemptId,
    required _isc.UuidValue requirementId,
    String? reference,
  }) => caller.callServerEndpoint<_is1oqp1g.EvidenceSubmissionResult>(
    'actionVerification',
    'requestAppVerification',
    {
      'attemptId': attemptId,
      'requirementId': requirementId,
      'reference': reference,
    },
  );

  _ida.Future<_ir431rrk.ActionAttemptView> completeAttempt(
    _isc.UuidValue attemptId,
  ) => caller.callServerEndpoint<_ir431rrk.ActionAttemptView>(
    'actionVerification',
    'completeAttempt',
    {'attemptId': attemptId},
  );

  _ida.Future<List<_ir431rrk.ActionAttemptView>> listMyAttempts({
    required int limit,
  }) => caller.callServerEndpoint<List<_ir431rrk.ActionAttemptView>>(
    'actionVerification',
    'listMyAttempts',
    {'limit': limit},
  );
}

/// Participants appeal a rejected proof once; the action's creator decides.
/// {@category Endpoint}
class EndpointEvidenceAppeal extends _isc.EndpointRef {
  EndpointEvidenceAppeal(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'evidenceAppeal';

  _ida.Future<_igtzj0f1.EvidenceAppealView> submit({
    required _isc.UuidValue attemptId,
    required String reason,
  }) => caller.callServerEndpoint<_igtzj0f1.EvidenceAppealView>(
    'evidenceAppeal',
    'submit',
    {
      'attemptId': attemptId,
      'reason': reason,
    },
  );

  _ida.Future<_igtzj0f1.EvidenceAppealView?> getMine({
    required _isc.UuidValue attemptId,
  }) => caller.callServerEndpoint<_igtzj0f1.EvidenceAppealView?>(
    'evidenceAppeal',
    'getMine',
    {'attemptId': attemptId},
  );

  /// Pending appeals on the caller's own actions.
  _ida.Future<List<_igtzj0f1.EvidenceAppealView>> listOwned({
    required int limit,
  }) => caller.callServerEndpoint<List<_igtzj0f1.EvidenceAppealView>>(
    'evidenceAppeal',
    'listOwned',
    {'limit': limit},
  );

  _ida.Future<_igtzj0f1.EvidenceAppealView> resolve({
    required _isc.UuidValue appealId,
    required _ito2zfn8.EvidenceAppealStatus decision,
    required String note,
  }) => caller.callServerEndpoint<_igtzj0f1.EvidenceAppealView>(
    'evidenceAppeal',
    'resolve',
    {
      'appealId': appealId,
      'decision': decision,
      'note': note,
    },
  );
}

/// Verily's scoped reviewers decide proof sent to a person.
/// {@category Endpoint}
class EndpointEvidenceReview extends _isc.EndpointRef {
  EndpointEvidenceReview(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'evidenceReview';

  _ida.Future<List<_iyuppglq.EvidenceReviewQueueItem>> listQueue({
    required int limit,
  }) => caller.callServerEndpoint<List<_iyuppglq.EvidenceReviewQueueItem>>(
    'evidenceReview',
    'listQueue',
    {'limit': limit},
  );

  _ida.Future<_ir431rrk.ActionAttemptView> review({
    required _isc.UuidValue evidenceId,
    required _irim9waa.EvidenceDecisionStatus decision,
    required String note,
  }) => caller.callServerEndpoint<_ir431rrk.ActionAttemptView>(
    'evidenceReview',
    'review',
    {
      'evidenceId': evidenceId,
      'decision': decision,
      'note': note,
    },
  );
}

/// Creator management of Verily Apps, and a participant's own subject.
///
/// Every method derives the caller from the authenticated session; creator
/// methods re-check App ownership on each call. Apps themselves never use
/// this endpoint: they call `POST /api/v1/confirmations` with an App key.
/// {@category Endpoint}
class EndpointVerilyApp extends _isc.EndpointRef {
  EndpointVerilyApp(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'verilyApp';

  _ida.Future<List<_in92p10u.VerilyAppView>> listApps() =>
      caller.callServerEndpoint<List<_in92p10u.VerilyAppView>>(
        'verilyApp',
        'listApps',
        {},
      );

  /// Registers an App. The returned key is never retrievable again.
  _ida.Future<_i3hnfj5e.VerilyAppCredential> createApp({
    required String name,
    String? websiteUrl,
  }) => caller.callServerEndpoint<_i3hnfj5e.VerilyAppCredential>(
    'verilyApp',
    'createApp',
    {
      'name': name,
      'websiteUrl': websiteUrl,
    },
  );

  /// Adds a rotation key. The returned key is never retrievable again.
  _ida.Future<_i3hnfj5e.VerilyAppCredential> createKey({
    required _isc.UuidValue appId,
  }) => caller.callServerEndpoint<_i3hnfj5e.VerilyAppCredential>(
    'verilyApp',
    'createKey',
    {'appId': appId},
  );

  _ida.Future<_in92p10u.VerilyAppView> revokeKey({
    required _isc.UuidValue appId,
    required String keyId,
  }) => caller.callServerEndpoint<_in92p10u.VerilyAppView>(
    'verilyApp',
    'revokeKey',
    {
      'appId': appId,
      'keyId': keyId,
    },
  );

  _ida.Future<_in92p10u.VerilyAppView> revokeApp({
    required _isc.UuidValue appId,
  }) => caller.callServerEndpoint<_in92p10u.VerilyAppView>(
    'verilyApp',
    'revokeApp',
    {'appId': appId},
  );

  _ida.Future<List<_iw9760io.AppConfirmationView>> listConfirmations({
    required _isc.UuidValue appId,
    required int limit,
    _isc.UuidValue? beforeId,
  }) => caller.callServerEndpoint<List<_iw9760io.AppConfirmationView>>(
    'verilyApp',
    'listConfirmations',
    {
      'appId': appId,
      'limit': limit,
      'beforeId': beforeId,
    },
  );

  /// Returns the caller's own subject for an App of a live action.
  _ida.Future<_i7ba7git.VerilyAppLinkView> linkApp({
    required _isc.UuidValue appId,
  }) => caller.callServerEndpoint<_i7ba7git.VerilyAppLinkView>(
    'verilyApp',
    'linkApp',
    {'appId': appId},
  );

  /// Sets or clears the HTTPS URL that receives signed events and pull
  /// verification calls.
  _ida.Future<_in92p10u.VerilyAppView> setWebhookUrl({
    required _isc.UuidValue appId,
    String? webhookUrl,
  }) => caller.callServerEndpoint<_in92p10u.VerilyAppView>(
    'verilyApp',
    'setWebhookUrl',
    {
      'appId': appId,
      'webhookUrl': webhookUrl,
    },
  );

  /// Issues the next `whsec_` signing secret, returned only this once.
  _ida.Future<_iwmhqfps.VerilyAppWebhookSecret> rotateWebhookSecret({
    required _isc.UuidValue appId,
  }) => caller.callServerEndpoint<_iwmhqfps.VerilyAppWebhookSecret>(
    'verilyApp',
    'rotateWebhookSecret',
    {'appId': appId},
  );

  /// Replaces the exact-match redirect URIs used by deep links.
  _ida.Future<_in92p10u.VerilyAppView> setRedirectUris({
    required _isc.UuidValue appId,
    required List<String> redirectUris,
  }) => caller.callServerEndpoint<_in92p10u.VerilyAppView>(
    'verilyApp',
    'setRedirectUris',
    {
      'appId': appId,
      'redirectUris': redirectUris,
    },
  );

  /// The App's outbound webhook log, newest first.
  _ida.Future<List<_ifzy4ji6.AppWebhookDeliveryView>> listWebhookDeliveries({
    required _isc.UuidValue appId,
    required int limit,
    _isc.UuidValue? beforeId,
  }) => caller.callServerEndpoint<List<_ifzy4ji6.AppWebhookDeliveryView>>(
    'verilyApp',
    'listWebhookDeliveries',
    {
      'appId': appId,
      'limit': limit,
      'beforeId': beforeId,
    },
  );

  /// What to show before linking this account to an App that opened
  /// `https://verily.fun/link?app=…&redirect_uri=…&state=…`.
  _ida.Future<_ihri8xdm.AppLinkRequestView> describeLinkRequest({
    required _isc.UuidValue appId,
    required String redirectUri,
    String? state,
  }) => caller.callServerEndpoint<_ihri8xdm.AppLinkRequestView>(
    'verilyApp',
    'describeLinkRequest',
    {
      'appId': appId,
      'redirectUri': redirectUri,
      'state': state,
    },
  );

  /// Approves the link and returns the App's redirect with a one-time,
  /// five-minute code.
  _ida.Future<_ietd10id.AppLinkRedirect> approveLink({
    required _isc.UuidValue appId,
    required String redirectUri,
    String? state,
  }) => caller.callServerEndpoint<_ietd10id.AppLinkRedirect>(
    'verilyApp',
    'approveLink',
    {
      'appId': appId,
      'redirectUri': redirectUri,
      'state': state,
    },
  );

  /// Declines the link and returns the App's redirect with
  /// `error=access_denied`.
  _ida.Future<_ietd10id.AppLinkRedirect> declineLink({
    required _isc.UuidValue appId,
    required String redirectUri,
    String? state,
  }) => caller.callServerEndpoint<_ietd10id.AppLinkRedirect>(
    'verilyApp',
    'declineLink',
    {
      'appId': appId,
      'redirectUri': redirectUri,
      'state': state,
    },
  );
}

/// By extending [EmailIdpBaseEndpoint], the email identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
/// {@category Endpoint}
class EndpointEmailIdp extends _iaic.EndpointEmailIdpBase {
  EndpointEmailIdp(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'emailIdp';

  /// Logs in the user and returns a new session.
  ///
  /// Throws an [EmailAccountLoginException] in case of errors, with reason:
  /// - [EmailAccountLoginExceptionReason.invalidCredentials] if the email or
  ///   password is incorrect.
  /// - [EmailAccountLoginExceptionReason.tooManyAttempts] if there have been
  ///   too many failed login attempts.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _ida.Future<_iacc.AuthSuccess> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
    'emailIdp',
    'login',
    {
      'email': email,
      'password': password,
    },
  );

  /// Starts the registration for a new user account with an email-based login
  /// associated to it.
  ///
  /// Upon successful completion of this method, an email will have been
  /// sent to [email] with a verification link, which the user must open to
  /// complete the registration.
  ///
  /// Always returns a account request ID, which can be used to complete the
  /// registration. If the email is already registered, the returned ID will not
  /// be valid.
  @override
  _ida.Future<_isc.UuidValue> startRegistration({required String email}) =>
      caller.callServerEndpoint<_isc.UuidValue>(
        'emailIdp',
        'startRegistration',
        {'email': email},
      );

  /// Verifies an account request code and returns a token
  /// that can be used to complete the account creation.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if no request exists
  ///   for the given [accountRequestId] or [verificationCode] is invalid.
  @override
  _ida.Future<String> verifyRegistrationCode({
    required _isc.UuidValue accountRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyRegistrationCode',
    {
      'accountRequestId': accountRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a new account registration, creating a new auth user with a
  /// profile and attaching the given email account to it.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if the [registrationToken]
  ///   is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  ///
  /// Returns a session for the newly created user.
  @override
  _ida.Future<_iacc.AuthSuccess> finishRegistration({
    required String registrationToken,
    required String password,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
    'emailIdp',
    'finishRegistration',
    {
      'registrationToken': registrationToken,
      'password': password,
    },
  );

  /// Requests a password reset for [email].
  ///
  /// If the email address is registered, an email with reset instructions will
  /// be send out. If the email is unknown, this method will have no effect.
  ///
  /// Always returns a password reset request ID, which can be used to complete
  /// the reset. If the email is not registered, the returned ID will not be
  /// valid.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to request a password reset.
  ///
  @override
  _ida.Future<_isc.UuidValue> startPasswordReset({required String email}) =>
      caller.callServerEndpoint<_isc.UuidValue>(
        'emailIdp',
        'startPasswordReset',
        {'email': email},
      );

  /// Verifies a password reset code and returns a finishPasswordResetToken
  /// that can be used to finish the password reset.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to verify the password reset.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// If multiple steps are required to complete the password reset, this endpoint
  /// should be overridden to return credentials for the next step instead
  /// of the credentials for setting the password.
  @override
  _ida.Future<String> verifyPasswordResetCode({
    required _isc.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyPasswordResetCode',
    {
      'passwordResetRequestId': passwordResetRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a password reset request by setting a new password.
  ///
  /// The [verificationCode] returned from [verifyPasswordResetCode] is used to
  /// validate the password reset request.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.policyViolation] if the new
  ///   password does not comply with the password policy.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _ida.Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) => caller.callServerEndpoint<void>(
    'emailIdp',
    'finishPasswordReset',
    {
      'finishPasswordResetToken': finishPasswordResetToken,
      'newPassword': newPassword,
    },
  );

  @override
  _ida.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'emailIdp',
    'hasAccount',
    {},
  );
}

/// Enables Google sign-in for generated clients.
/// {@category Endpoint}
class EndpointGoogleIdp extends _iaic.EndpointGoogleIdpBase {
  EndpointGoogleIdp(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'googleIdp';

  /// Validates a Google ID token and either logs in the associated user or
  /// creates a new user account if the Google account ID is not yet known.
  ///
  /// If a new user is created an associated [UserProfile] is also created.
  @override
  _ida.Future<_iacc.AuthSuccess> login({
    required String idToken,
    required String? accessToken,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
    'googleIdp',
    'login',
    {
      'idToken': idToken,
      'accessToken': accessToken,
    },
  );

  /// Validates a Google authorization code from the web OAuth2 PKCE flow and
  /// either logs in the associated user or creates a new account.
  ///
  /// This is the web counterpart of [login], which accepts an ID token directly
  /// (used on native platforms via the `google_sign_in` package).
  ///
  /// If a new user is created an associated [UserProfile] is also created.
  @override
  _ida.Future<_iacc.AuthSuccess> loginWithCode({
    required String code,
    required String codeVerifier,
    required String redirectUri,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
    'googleIdp',
    'loginWithCode',
    {
      'code': code,
      'codeVerifier': codeVerifier,
      'redirectUri': redirectUri,
    },
  );

  @override
  _ida.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'googleIdp',
    'hasAccount',
    {},
  );
}

/// By extending [RefreshJwtTokensEndpoint], the JWT token refresh endpoint
/// is made available on the server and enables automatic token refresh on the client.
/// {@category Endpoint}
class EndpointJwtRefresh extends _iacc.EndpointRefreshJwtTokens {
  EndpointJwtRefresh(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'jwtRefresh';

  /// Creates a new token pair for the given [refreshToken].
  ///
  /// If [refreshToken] is omitted, cookie-mode web clients fall back to the
  /// configured HttpOnly refresh cookie. When neither source is present this
  /// throws [RefreshTokenNotFoundException], the same public "no usable refresh
  /// credential" exception used for unknown refresh tokens.
  ///
  /// Can throw the following exceptions:
  /// -[RefreshTokenMalformedException]: refresh token is malformed and could
  ///   not be parsed. Not expected to happen for tokens issued by the server.
  /// -[RefreshTokenNotFoundException]: refresh token is unknown to the server.
  ///   Either the token was deleted or generated by a different server.
  /// -[RefreshTokenExpiredException]: refresh token has expired. Will happen
  ///   only if it has not been used within configured `refreshTokenLifetime`.
  /// -[RefreshTokenInvalidSecretException]: refresh token is incorrect, meaning
  ///   it does not refer to the current secret refresh token. This indicates
  ///   either a malfunctioning client or a malicious attempt by someone who has
  ///   obtained the refresh token. In this case the underlying refresh token
  ///   will be deleted, and access to it will expire fully when the last access
  ///   token is elapsed.
  ///
  /// This endpoint is unauthenticated, meaning the client won't include any
  /// authentication information with the call.
  @override
  _ida.Future<_iacc.AuthSuccess> refreshAccessToken({String? refreshToken}) =>
      caller.callServerEndpoint<_iacc.AuthSuccess>(
        'jwtRefresh',
        'refreshAccessToken',
        {'refreshToken': refreshToken},
        authenticated: false,
      );
}

/// Authenticated reporting and creator appeals; no review authority.
/// {@category Endpoint}
class EndpointModeration extends _isc.EndpointRef {
  EndpointModeration(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'moderation';

  _ida.Future<_ie976x46.ModerationCaseStatusView> report({
    required _isc.UuidValue actionDefinitionId,
    required String category,
    required String details,
    required String idempotencyKey,
  }) => caller.callServerEndpoint<_ie976x46.ModerationCaseStatusView>(
    'moderation',
    'report',
    {
      'actionDefinitionId': actionDefinitionId,
      'category': category,
      'details': details,
      'idempotencyKey': idempotencyKey,
    },
  );

  _ida.Future<_ie976x46.ModerationCaseStatusView> getStatus({
    required _isc.UuidValue caseId,
  }) => caller.callServerEndpoint<_ie976x46.ModerationCaseStatusView>(
    'moderation',
    'getStatus',
    {'caseId': caseId},
  );

  _ida.Future<List<_ie976x46.ModerationCaseStatusView>> listMine({
    required int limit,
  }) => caller.callServerEndpoint<List<_ie976x46.ModerationCaseStatusView>>(
    'moderation',
    'listMine',
    {'limit': limit},
  );

  _ida.Future<_ie976x46.ModerationCaseStatusView> appeal({
    required _isc.UuidValue caseId,
    required String reason,
  }) => caller.callServerEndpoint<_ie976x46.ModerationCaseStatusView>(
    'moderation',
    'appeal',
    {
      'caseId': caseId,
      'reason': reason,
    },
  );
}

/// Staff-only case review and immutable audit access.
/// {@category Endpoint}
class EndpointModerationReview extends _isc.EndpointRef {
  EndpointModerationReview(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'moderationReview';

  _ida.Future<List<_ie976x46.ModerationCaseStatusView>> listQueue({
    required int limit,
  }) => caller.callServerEndpoint<List<_ie976x46.ModerationCaseStatusView>>(
    'moderationReview',
    'listQueue',
    {'limit': limit},
  );

  _ida.Future<_ics7hcmp.ModerationCaseReviewView> getCase({
    required _isc.UuidValue caseId,
  }) => caller.callServerEndpoint<_ics7hcmp.ModerationCaseReviewView>(
    'moderationReview',
    'getCase',
    {'caseId': caseId},
  );

  _ida.Future<_ie976x46.ModerationCaseStatusView> review({
    required _isc.UuidValue caseId,
    required String decision,
    required String note,
  }) => caller.callServerEndpoint<_ie976x46.ModerationCaseStatusView>(
    'moderationReview',
    'review',
    {
      'caseId': caseId,
      'decision': decision,
      'note': note,
    },
  );

  _ida.Future<_ie976x46.ModerationCaseStatusView> resolveAppeal({
    required _isc.UuidValue caseId,
    required String decision,
    required String note,
  }) => caller.callServerEndpoint<_ie976x46.ModerationCaseStatusView>(
    'moderationReview',
    'resolveAppeal',
    {
      'caseId': caseId,
      'decision': decision,
      'note': note,
    },
  );
}

/// The one Solana wallet an account is paid to and funds rewards from.
/// {@category Endpoint}
class EndpointPayoutWallet extends _isc.EndpointRef {
  EndpointPayoutWallet(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'payoutWallet';

  _ida.Future<_iuosx0t6.PayoutWalletView?> getMine() =>
      caller.callServerEndpoint<_iuosx0t6.PayoutWalletView?>(
        'payoutWallet',
        'getMine',
        {},
      );

  /// Returns the exact text the wallet must sign to prove ownership.
  _ida.Future<_izs3rc7f.PayoutWalletLinkChallengeView>
  createWalletLinkChallenge({required String walletAddress}) =>
      caller.callServerEndpoint<_izs3rc7f.PayoutWalletLinkChallengeView>(
        'payoutWallet',
        'createWalletLinkChallenge',
        {'walletAddress': walletAddress},
      );

  /// Links (or re-links) the wallet with its base58 ed25519 signature.
  _ida.Future<_iuosx0t6.PayoutWalletView> linkPayoutWallet({
    required String walletAddress,
    required String nonce,
    required String signature,
  }) => caller.callServerEndpoint<_iuosx0t6.PayoutWalletView>(
    'payoutWallet',
    'linkPayoutWallet',
    {
      'walletAddress': walletAddress,
      'nonce': nonce,
      'signature': signature,
    },
  );
}

/// Escrowed rewards: creator funding and ending, participant payouts.
///
/// Creator methods re-derive ownership from the authenticated account and
/// the action id. Funding is confirmed from chain state, never from the
/// client's word.
/// {@category Endpoint}
class EndpointRewards extends _isc.EndpointRef {
  EndpointRewards(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'rewards';

  /// The creator's view of an action's reward; null when it has none.
  _ida.Future<_i68mfray.RewardPoolView?> getRewardPool({
    required _isc.UuidValue actionId,
  }) => caller.callServerEndpoint<_i68mfray.RewardPoolView?>(
    'rewards',
    'getRewardPool',
    {'actionId': actionId},
  );

  /// Freezes the reward terms and returns the transaction the creator's
  /// linked payout wallet signs to open the escrow.
  _ida.Future<_iq3ahgh8.RewardFundingPlan> prepareRewardFunding({
    required _isc.UuidValue actionId,
  }) => caller.callServerEndpoint<_iq3ahgh8.RewardFundingPlan>(
    'rewards',
    'prepareRewardFunding',
    {'actionId': actionId},
  );

  /// Verifies the escrow on chain and marks the reward funded.
  _ida.Future<_i68mfray.RewardPoolView> confirmRewardFunding({
    required _isc.UuidValue actionId,
    required String signature,
  }) => caller.callServerEndpoint<_i68mfray.RewardPoolView>(
    'rewards',
    'confirmRewardFunding',
    {
      'actionId': actionId,
      'signature': signature,
    },
  );

  /// Stops new payouts now; reserved payouts still release.
  _ida.Future<_i8qz9pd7.RewardEndPlan> endRewardEarly({
    required _isc.UuidValue actionId,
  }) => caller.callServerEndpoint<_i8qz9pd7.RewardEndPlan>(
    'rewards',
    'endRewardEarly',
    {'actionId': actionId},
  );

  /// The caller's own payouts, newest first.
  _ida.Future<List<_isztzkpq.RewardPayoutView>> listMyPayouts({
    required int limit,
  }) => caller.callServerEndpoint<List<_isztzkpq.RewardPayoutView>>(
    'rewards',
    'listMyPayouts',
    {'limit': limit},
  );
}

/// The Verily app's side of a verification request opened from
/// `https://verily.fun/r/<id>` or `verily://r/<id>`.
///
/// The link carries only the request id; everything shown comes from here,
/// so a forged link can only point at a real request.
/// {@category Endpoint}
class EndpointVerificationRequest extends _isc.EndpointRef {
  EndpointVerificationRequest(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'verificationRequest';

  /// Who is asking, for what, and exactly what will be shared.
  _ida.Future<_izhqijgv.VerificationRequestView> getRequest({
    required _isc.UuidValue requestId,
  }) => caller.callServerEndpoint<_izhqijgv.VerificationRequestView>(
    'verificationRequest',
    'getRequest',
    {'requestId': requestId},
  );

  /// Accepts the request. The returned view carries the private action to
  /// capture against with the normal proof flow.
  _ida.Future<_izhqijgv.VerificationRequestView> accept({
    required _isc.UuidValue requestId,
  }) => caller.callServerEndpoint<_izhqijgv.VerificationRequestView>(
    'verificationRequest',
    'accept',
    {'requestId': requestId},
  );

  /// Declines; the App receives `status=declined`.
  _ida.Future<_iv7cvvng.VerificationRequestRedirect> decline({
    required _isc.UuidValue requestId,
  }) => caller.callServerEndpoint<_iv7cvvng.VerificationRequestRedirect>(
    'verificationRequest',
    'decline',
    {'requestId': requestId},
  );

  /// After the proof is submitted: the App's redirect with a one-time,
  /// five-minute receipt code.
  _ida.Future<_iv7cvvng.VerificationRequestRedirect> finish({
    required _isc.UuidValue requestId,
  }) => caller.callServerEndpoint<_iv7cvvng.VerificationRequestRedirect>(
    'verificationRequest',
    'finish',
    {'requestId': requestId},
  );
}

class Modules {
  Modules(Client client) {
    auth = _iacc.Caller(client);
    serverpod_auth_idp = _iaic.Caller(client);
  }

  late final _iacc.Caller auth;

  late final _iaic.Caller serverpod_auth_idp;
}

class Client extends _isc.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _isc.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_isc.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
    _i85jenna.Client? httpClientOverride,
  }) : super(
         host,
         _il2as5qe.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
         httpClientOverride: httpClientOverride,
       ) {
    accountLifecycle = EndpointAccountLifecycle(this);
    actionVerification = EndpointActionVerification(this);
    evidenceAppeal = EndpointEvidenceAppeal(this);
    evidenceReview = EndpointEvidenceReview(this);
    verilyApp = EndpointVerilyApp(this);
    emailIdp = EndpointEmailIdp(this);
    googleIdp = EndpointGoogleIdp(this);
    jwtRefresh = EndpointJwtRefresh(this);
    moderation = EndpointModeration(this);
    moderationReview = EndpointModerationReview(this);
    payoutWallet = EndpointPayoutWallet(this);
    rewards = EndpointRewards(this);
    verificationRequest = EndpointVerificationRequest(this);
    modules = Modules(this);
  }

  late final EndpointAccountLifecycle accountLifecycle;

  late final EndpointActionVerification actionVerification;

  late final EndpointEvidenceAppeal evidenceAppeal;

  late final EndpointEvidenceReview evidenceReview;

  late final EndpointVerilyApp verilyApp;

  late final EndpointEmailIdp emailIdp;

  late final EndpointGoogleIdp googleIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointModeration moderation;

  late final EndpointModerationReview moderationReview;

  late final EndpointPayoutWallet payoutWallet;

  late final EndpointRewards rewards;

  late final EndpointVerificationRequest verificationRequest;

  late final Modules modules;

  @override
  Map<String, _isc.EndpointRef> get endpointRefLookup => {
    'accountLifecycle': accountLifecycle,
    'actionVerification': actionVerification,
    'evidenceAppeal': evidenceAppeal,
    'evidenceReview': evidenceReview,
    'verilyApp': verilyApp,
    'emailIdp': emailIdp,
    'googleIdp': googleIdp,
    'jwtRefresh': jwtRefresh,
    'moderation': moderation,
    'moderationReview': moderationReview,
    'payoutWallet': payoutWallet,
    'rewards': rewards,
    'verificationRequest': verificationRequest,
  };

  @override
  Map<String, _isc.ModuleEndpointCaller> get moduleLookup => {
    'auth': modules.auth,
    'serverpod_auth_idp': modules.serverpod_auth_idp,
  };
}
