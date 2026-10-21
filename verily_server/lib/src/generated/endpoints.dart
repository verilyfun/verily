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
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;
import 'package:verily_server/src/generated/action_verification/action_evidence_input.dart'
    as _iwt0swaj;
import 'package:verily_server/src/generated/action_verification/create_action_definition_request.dart'
    as _iknf9wff;
import 'package:verily_server/src/generated/action_verification/evidence_appeal_status.dart'
    as _iae6saoz;
import 'package:verily_server/src/generated/action_verification/evidence_decision_status.dart'
    as _i4x5kh6m;
import 'package:verily_server/src/generated/action_verification/media_upload_confirmation.dart'
    as _iihlm2mq;
import 'package:verily_server/src/generated/future_calls.dart' as _ic0hj7xj;

import '../account/account_lifecycle_endpoint.dart' as _ilf52cbk;
import '../action_verification/action_verification_endpoint.dart' as _il8ja9q3;
import '../action_verification/evidence_appeal_endpoint.dart' as _ia38af11;
import '../action_verification/evidence_review_endpoint.dart' as _i96y5npp;
import '../apps/verily_app_endpoint.dart' as _iqeqjjry;
import '../auth/email_idp_endpoint.dart' as _iuc1hd5t;
import '../auth/google_idp_endpoint.dart' as _i71axiz0;
import '../auth/jwt_refresh_endpoint.dart' as _inwq3ztq;
import '../moderation/moderation_endpoint.dart' as _icwcy5wq;
import '../moderation/moderation_review_endpoint.dart' as _ilzfasxk;
import '../rewards/payout_wallet_endpoint.dart' as _i9hfqu1s;
import '../rewards/rewards_endpoint.dart' as _i4hn2z2u;
import '../verification_requests/verification_request_endpoint.dart'
    as _iw1snziy;
export 'future_calls.dart' show ServerpodFutureCallsGetter;

class Endpoints extends _is.EndpointDispatch {
  @override
  void initializeEndpoints(_is.Server server) {
    var endpoints = <String, _is.Endpoint>{
      'accountLifecycle': _ilf52cbk.AccountLifecycleEndpoint()
        ..initialize(
          server,
          'accountLifecycle',
          null,
        ),
      'actionVerification': _il8ja9q3.ActionVerificationEndpoint()
        ..initialize(
          server,
          'actionVerification',
          null,
        ),
      'evidenceAppeal': _ia38af11.EvidenceAppealEndpoint()
        ..initialize(
          server,
          'evidenceAppeal',
          null,
        ),
      'evidenceReview': _i96y5npp.EvidenceReviewEndpoint()
        ..initialize(
          server,
          'evidenceReview',
          null,
        ),
      'verilyApp': _iqeqjjry.VerilyAppEndpoint()
        ..initialize(
          server,
          'verilyApp',
          null,
        ),
      'emailIdp': _iuc1hd5t.EmailIdpEndpoint()
        ..initialize(
          server,
          'emailIdp',
          null,
        ),
      'googleIdp': _i71axiz0.GoogleIdpEndpoint()
        ..initialize(
          server,
          'googleIdp',
          null,
        ),
      'jwtRefresh': _inwq3ztq.JwtRefreshEndpoint()
        ..initialize(
          server,
          'jwtRefresh',
          null,
        ),
      'moderation': _icwcy5wq.ModerationEndpoint()
        ..initialize(
          server,
          'moderation',
          null,
        ),
      'moderationReview': _ilzfasxk.ModerationReviewEndpoint()
        ..initialize(
          server,
          'moderationReview',
          null,
        ),
      'payoutWallet': _i9hfqu1s.PayoutWalletEndpoint()
        ..initialize(
          server,
          'payoutWallet',
          null,
        ),
      'rewards': _i4hn2z2u.RewardsEndpoint()
        ..initialize(
          server,
          'rewards',
          null,
        ),
      'verificationRequest': _iw1snziy.VerificationRequestEndpoint()
        ..initialize(
          server,
          'verificationRequest',
          null,
        ),
    };
    connectors['accountLifecycle'] = _is.EndpointConnector(
      name: 'accountLifecycle',
      endpoint: endpoints['accountLifecycle']!,
      methodConnectors: {
        'closeAccount': _is.MethodConnector(
          name: 'closeAccount',
          params: {
            'confirmation': _is.ParameterDescription(
              name: 'confirmation',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['accountLifecycle']
                          as _ilf52cbk.AccountLifecycleEndpoint)
                      .closeAccount(
                        session,
                        confirmation: params['confirmation'],
                      ),
        ),
      },
    );
    connectors['actionVerification'] = _is.EndpointConnector(
      name: 'actionVerification',
      endpoint: endpoints['actionVerification']!,
      methodConnectors: {
        'listTemplates': _is.MethodConnector(
          name: 'listTemplates',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['actionVerification']
                          as _il8ja9q3.ActionVerificationEndpoint)
                      .listTemplates(session),
        ),
        'draftActionFromPrompt': _is.MethodConnector(
          name: 'draftActionFromPrompt',
          params: {
            'prompt': _is.ParameterDescription(
              name: 'prompt',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['actionVerification']
                          as _il8ja9q3.ActionVerificationEndpoint)
                      .draftActionFromPrompt(
                        session,
                        prompt: params['prompt'],
                      ),
        ),
        'createAction': _is.MethodConnector(
          name: 'createAction',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_iknf9wff.CreateActionDefinitionRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['actionVerification']
                          as _il8ja9q3.ActionVerificationEndpoint)
                      .createAction(
                        session,
                        params['request'],
                      ),
        ),
        'saveActionDraft': _is.MethodConnector(
          name: 'saveActionDraft',
          params: {
            'request': _is.ParameterDescription(
              name: 'request',
              type: _is.getType<_iknf9wff.CreateActionDefinitionRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['actionVerification']
                          as _il8ja9q3.ActionVerificationEndpoint)
                      .saveActionDraft(
                        session,
                        params['request'],
                      ),
        ),
        'previewAction': _is.MethodConnector(
          name: 'previewAction',
          params: {
            'actionId': _is.ParameterDescription(
              name: 'actionId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['actionVerification']
                          as _il8ja9q3.ActionVerificationEndpoint)
                      .previewAction(
                        session,
                        actionId: params['actionId'],
                      ),
        ),
        'listOwnedActions': _is.MethodConnector(
          name: 'listOwnedActions',
          params: {
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['actionVerification']
                          as _il8ja9q3.ActionVerificationEndpoint)
                      .listOwnedActions(
                        session,
                        limit: params['limit'],
                      ),
        ),
        'publishAction': _is.MethodConnector(
          name: 'publishAction',
          params: {
            'actionId': _is.ParameterDescription(
              name: 'actionId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'expectedRevision': _is.ParameterDescription(
              name: 'expectedRevision',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['actionVerification']
                          as _il8ja9q3.ActionVerificationEndpoint)
                      .publishAction(
                        session,
                        actionId: params['actionId'],
                        expectedRevision: params['expectedRevision'],
                      ),
        ),
        'pauseAction': _is.MethodConnector(
          name: 'pauseAction',
          params: {
            'actionId': _is.ParameterDescription(
              name: 'actionId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'expectedRevision': _is.ParameterDescription(
              name: 'expectedRevision',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['actionVerification']
                          as _il8ja9q3.ActionVerificationEndpoint)
                      .pauseAction(
                        session,
                        actionId: params['actionId'],
                        expectedRevision: params['expectedRevision'],
                      ),
        ),
        'createQrChallenge': _is.MethodConnector(
          name: 'createQrChallenge',
          params: {
            'requirementId': _is.ParameterDescription(
              name: 'requirementId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'validitySeconds': _is.ParameterDescription(
              name: 'validitySeconds',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['actionVerification']
                          as _il8ja9q3.ActionVerificationEndpoint)
                      .createQrChallenge(
                        session,
                        requirementId: params['requirementId'],
                        validitySeconds: params['validitySeconds'],
                      ),
        ),
        'listAvailableActions': _is.MethodConnector(
          name: 'listAvailableActions',
          params: {
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['actionVerification']
                          as _il8ja9q3.ActionVerificationEndpoint)
                      .listAvailableActions(
                        session,
                        limit: params['limit'],
                      ),
        ),
        'listNearbyActions': _is.MethodConnector(
          name: 'listNearbyActions',
          params: {
            'latitude': _is.ParameterDescription(
              name: 'latitude',
              type: _is.getType<double>(),
              nullable: false,
            ),
            'longitude': _is.ParameterDescription(
              name: 'longitude',
              type: _is.getType<double>(),
              nullable: false,
            ),
            'radiusKm': _is.ParameterDescription(
              name: 'radiusKm',
              type: _is.getType<double>(),
              nullable: false,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['actionVerification']
                          as _il8ja9q3.ActionVerificationEndpoint)
                      .listNearbyActions(
                        session,
                        latitude: params['latitude'],
                        longitude: params['longitude'],
                        radiusKm: params['radiusKm'],
                        limit: params['limit'],
                      ),
        ),
        'beginAttempt': _is.MethodConnector(
          name: 'beginAttempt',
          params: {
            'actionId': _is.ParameterDescription(
              name: 'actionId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'idempotencyKey': _is.ParameterDescription(
              name: 'idempotencyKey',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['actionVerification']
                          as _il8ja9q3.ActionVerificationEndpoint)
                      .beginAttempt(
                        session,
                        actionId: params['actionId'],
                        idempotencyKey: params['idempotencyKey'],
                      ),
        ),
        'issueSpokenChallenge': _is.MethodConnector(
          name: 'issueSpokenChallenge',
          params: {
            'attemptId': _is.ParameterDescription(
              name: 'attemptId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'requirementId': _is.ParameterDescription(
              name: 'requirementId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['actionVerification']
                          as _il8ja9q3.ActionVerificationEndpoint)
                      .issueSpokenChallenge(
                        session,
                        attemptId: params['attemptId'],
                        requirementId: params['requirementId'],
                      ),
        ),
        'createCaptureChallenge': _is.MethodConnector(
          name: 'createCaptureChallenge',
          params: {
            'attemptId': _is.ParameterDescription(
              name: 'attemptId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'requirementId': _is.ParameterDescription(
              name: 'requirementId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'evidenceBindingHash': _is.ParameterDescription(
              name: 'evidenceBindingHash',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['actionVerification']
                          as _il8ja9q3.ActionVerificationEndpoint)
                      .createCaptureChallenge(
                        session,
                        attemptId: params['attemptId'],
                        requirementId: params['requirementId'],
                        evidenceBindingHash: params['evidenceBindingHash'],
                      ),
        ),
        'submitEvidence': _is.MethodConnector(
          name: 'submitEvidence',
          params: {
            'input': _is.ParameterDescription(
              name: 'input',
              type: _is.getType<_iwt0swaj.ActionEvidenceInput>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['actionVerification']
                          as _il8ja9q3.ActionVerificationEndpoint)
                      .submitEvidence(
                        session,
                        params['input'],
                      ),
        ),
        'requestMediaUpload': _is.MethodConnector(
          name: 'requestMediaUpload',
          params: {
            'attemptId': _is.ParameterDescription(
              name: 'attemptId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'requirementId': _is.ParameterDescription(
              name: 'requirementId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'contentType': _is.ParameterDescription(
              name: 'contentType',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'byteLength': _is.ParameterDescription(
              name: 'byteLength',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['actionVerification']
                          as _il8ja9q3.ActionVerificationEndpoint)
                      .requestMediaUpload(
                        session,
                        attemptId: params['attemptId'],
                        requirementId: params['requirementId'],
                        contentType: params['contentType'],
                        byteLength: params['byteLength'],
                      ),
        ),
        'confirmMediaUpload': _is.MethodConnector(
          name: 'confirmMediaUpload',
          params: {
            'confirmation': _is.ParameterDescription(
              name: 'confirmation',
              type: _is.getType<_iihlm2mq.MediaUploadConfirmation>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['actionVerification']
                          as _il8ja9q3.ActionVerificationEndpoint)
                      .confirmMediaUpload(
                        session,
                        params['confirmation'],
                      ),
        ),
        'requestAppVerification': _is.MethodConnector(
          name: 'requestAppVerification',
          params: {
            'attemptId': _is.ParameterDescription(
              name: 'attemptId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'requirementId': _is.ParameterDescription(
              name: 'requirementId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'reference': _is.ParameterDescription(
              name: 'reference',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['actionVerification']
                          as _il8ja9q3.ActionVerificationEndpoint)
                      .requestAppVerification(
                        session,
                        attemptId: params['attemptId'],
                        requirementId: params['requirementId'],
                        reference: params['reference'],
                      ),
        ),
        'completeAttempt': _is.MethodConnector(
          name: 'completeAttempt',
          params: {
            'attemptId': _is.ParameterDescription(
              name: 'attemptId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['actionVerification']
                          as _il8ja9q3.ActionVerificationEndpoint)
                      .completeAttempt(
                        session,
                        params['attemptId'],
                      ),
        ),
        'listMyAttempts': _is.MethodConnector(
          name: 'listMyAttempts',
          params: {
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['actionVerification']
                          as _il8ja9q3.ActionVerificationEndpoint)
                      .listMyAttempts(
                        session,
                        limit: params['limit'],
                      ),
        ),
      },
    );
    connectors['evidenceAppeal'] = _is.EndpointConnector(
      name: 'evidenceAppeal',
      endpoint: endpoints['evidenceAppeal']!,
      methodConnectors: {
        'submit': _is.MethodConnector(
          name: 'submit',
          params: {
            'attemptId': _is.ParameterDescription(
              name: 'attemptId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'reason': _is.ParameterDescription(
              name: 'reason',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['evidenceAppeal']
                          as _ia38af11.EvidenceAppealEndpoint)
                      .submit(
                        session,
                        attemptId: params['attemptId'],
                        reason: params['reason'],
                      ),
        ),
        'getMine': _is.MethodConnector(
          name: 'getMine',
          params: {
            'attemptId': _is.ParameterDescription(
              name: 'attemptId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['evidenceAppeal']
                          as _ia38af11.EvidenceAppealEndpoint)
                      .getMine(
                        session,
                        attemptId: params['attemptId'],
                      ),
        ),
        'listOwned': _is.MethodConnector(
          name: 'listOwned',
          params: {
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['evidenceAppeal']
                          as _ia38af11.EvidenceAppealEndpoint)
                      .listOwned(
                        session,
                        limit: params['limit'],
                      ),
        ),
        'resolve': _is.MethodConnector(
          name: 'resolve',
          params: {
            'appealId': _is.ParameterDescription(
              name: 'appealId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'decision': _is.ParameterDescription(
              name: 'decision',
              type: _is.getType<_iae6saoz.EvidenceAppealStatus>(),
              nullable: false,
            ),
            'note': _is.ParameterDescription(
              name: 'note',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['evidenceAppeal']
                          as _ia38af11.EvidenceAppealEndpoint)
                      .resolve(
                        session,
                        appealId: params['appealId'],
                        decision: params['decision'],
                        note: params['note'],
                      ),
        ),
      },
    );
    connectors['evidenceReview'] = _is.EndpointConnector(
      name: 'evidenceReview',
      endpoint: endpoints['evidenceReview']!,
      methodConnectors: {
        'listQueue': _is.MethodConnector(
          name: 'listQueue',
          params: {
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['evidenceReview']
                          as _i96y5npp.EvidenceReviewEndpoint)
                      .listQueue(
                        session,
                        limit: params['limit'],
                      ),
        ),
        'review': _is.MethodConnector(
          name: 'review',
          params: {
            'evidenceId': _is.ParameterDescription(
              name: 'evidenceId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'decision': _is.ParameterDescription(
              name: 'decision',
              type: _is.getType<_i4x5kh6m.EvidenceDecisionStatus>(),
              nullable: false,
            ),
            'note': _is.ParameterDescription(
              name: 'note',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['evidenceReview']
                          as _i96y5npp.EvidenceReviewEndpoint)
                      .review(
                        session,
                        evidenceId: params['evidenceId'],
                        decision: params['decision'],
                        note: params['note'],
                      ),
        ),
      },
    );
    connectors['verilyApp'] = _is.EndpointConnector(
      name: 'verilyApp',
      endpoint: endpoints['verilyApp']!,
      methodConnectors: {
        'listApps': _is.MethodConnector(
          name: 'listApps',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['verilyApp'] as _iqeqjjry.VerilyAppEndpoint)
                  .listApps(session),
        ),
        'createApp': _is.MethodConnector(
          name: 'createApp',
          params: {
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'websiteUrl': _is.ParameterDescription(
              name: 'websiteUrl',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['verilyApp'] as _iqeqjjry.VerilyAppEndpoint)
                  .createApp(
                    session,
                    name: params['name'],
                    websiteUrl: params['websiteUrl'],
                  ),
        ),
        'createKey': _is.MethodConnector(
          name: 'createKey',
          params: {
            'appId': _is.ParameterDescription(
              name: 'appId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['verilyApp'] as _iqeqjjry.VerilyAppEndpoint)
                  .createKey(
                    session,
                    appId: params['appId'],
                  ),
        ),
        'revokeKey': _is.MethodConnector(
          name: 'revokeKey',
          params: {
            'appId': _is.ParameterDescription(
              name: 'appId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'keyId': _is.ParameterDescription(
              name: 'keyId',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['verilyApp'] as _iqeqjjry.VerilyAppEndpoint)
                  .revokeKey(
                    session,
                    appId: params['appId'],
                    keyId: params['keyId'],
                  ),
        ),
        'revokeApp': _is.MethodConnector(
          name: 'revokeApp',
          params: {
            'appId': _is.ParameterDescription(
              name: 'appId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['verilyApp'] as _iqeqjjry.VerilyAppEndpoint)
                  .revokeApp(
                    session,
                    appId: params['appId'],
                  ),
        ),
        'listConfirmations': _is.MethodConnector(
          name: 'listConfirmations',
          params: {
            'appId': _is.ParameterDescription(
              name: 'appId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'beforeId': _is.ParameterDescription(
              name: 'beforeId',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['verilyApp'] as _iqeqjjry.VerilyAppEndpoint)
                  .listConfirmations(
                    session,
                    appId: params['appId'],
                    limit: params['limit'],
                    beforeId: params['beforeId'],
                  ),
        ),
        'linkApp': _is.MethodConnector(
          name: 'linkApp',
          params: {
            'appId': _is.ParameterDescription(
              name: 'appId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['verilyApp'] as _iqeqjjry.VerilyAppEndpoint)
                  .linkApp(
                    session,
                    appId: params['appId'],
                  ),
        ),
        'setWebhookUrl': _is.MethodConnector(
          name: 'setWebhookUrl',
          params: {
            'appId': _is.ParameterDescription(
              name: 'appId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'webhookUrl': _is.ParameterDescription(
              name: 'webhookUrl',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['verilyApp'] as _iqeqjjry.VerilyAppEndpoint)
                  .setWebhookUrl(
                    session,
                    appId: params['appId'],
                    webhookUrl: params['webhookUrl'],
                  ),
        ),
        'rotateWebhookSecret': _is.MethodConnector(
          name: 'rotateWebhookSecret',
          params: {
            'appId': _is.ParameterDescription(
              name: 'appId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['verilyApp'] as _iqeqjjry.VerilyAppEndpoint)
                  .rotateWebhookSecret(
                    session,
                    appId: params['appId'],
                  ),
        ),
        'setRedirectUris': _is.MethodConnector(
          name: 'setRedirectUris',
          params: {
            'appId': _is.ParameterDescription(
              name: 'appId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'redirectUris': _is.ParameterDescription(
              name: 'redirectUris',
              type: _is.getType<List<String>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['verilyApp'] as _iqeqjjry.VerilyAppEndpoint)
                  .setRedirectUris(
                    session,
                    appId: params['appId'],
                    redirectUris: params['redirectUris'],
                  ),
        ),
        'listWebhookDeliveries': _is.MethodConnector(
          name: 'listWebhookDeliveries',
          params: {
            'appId': _is.ParameterDescription(
              name: 'appId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'beforeId': _is.ParameterDescription(
              name: 'beforeId',
              type: _is.getType<_is.UuidValue?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['verilyApp'] as _iqeqjjry.VerilyAppEndpoint)
                  .listWebhookDeliveries(
                    session,
                    appId: params['appId'],
                    limit: params['limit'],
                    beforeId: params['beforeId'],
                  ),
        ),
        'describeLinkRequest': _is.MethodConnector(
          name: 'describeLinkRequest',
          params: {
            'appId': _is.ParameterDescription(
              name: 'appId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'redirectUri': _is.ParameterDescription(
              name: 'redirectUri',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'state': _is.ParameterDescription(
              name: 'state',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['verilyApp'] as _iqeqjjry.VerilyAppEndpoint)
                  .describeLinkRequest(
                    session,
                    appId: params['appId'],
                    redirectUri: params['redirectUri'],
                    state: params['state'],
                  ),
        ),
        'approveLink': _is.MethodConnector(
          name: 'approveLink',
          params: {
            'appId': _is.ParameterDescription(
              name: 'appId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'redirectUri': _is.ParameterDescription(
              name: 'redirectUri',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'state': _is.ParameterDescription(
              name: 'state',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['verilyApp'] as _iqeqjjry.VerilyAppEndpoint)
                  .approveLink(
                    session,
                    appId: params['appId'],
                    redirectUri: params['redirectUri'],
                    state: params['state'],
                  ),
        ),
        'declineLink': _is.MethodConnector(
          name: 'declineLink',
          params: {
            'appId': _is.ParameterDescription(
              name: 'appId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'redirectUri': _is.ParameterDescription(
              name: 'redirectUri',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'state': _is.ParameterDescription(
              name: 'state',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['verilyApp'] as _iqeqjjry.VerilyAppEndpoint)
                  .declineLink(
                    session,
                    appId: params['appId'],
                    redirectUri: params['redirectUri'],
                    state: params['state'],
                  ),
        ),
      },
    );
    connectors['emailIdp'] = _is.EndpointConnector(
      name: 'emailIdp',
      endpoint: endpoints['emailIdp']!,
      methodConnectors: {
        'login': _is.MethodConnector(
          name: 'login',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint).login(
                    session,
                    email: params['email'],
                    password: params['password'],
                  ),
        ),
        'startRegistration': _is.MethodConnector(
          name: 'startRegistration',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .startRegistration(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyRegistrationCode': _is.MethodConnector(
          name: 'verifyRegistrationCode',
          params: {
            'accountRequestId': _is.ParameterDescription(
              name: 'accountRequestId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _is.ParameterDescription(
              name: 'verificationCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .verifyRegistrationCode(
                    session,
                    accountRequestId: params['accountRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishRegistration': _is.MethodConnector(
          name: 'finishRegistration',
          params: {
            'registrationToken': _is.ParameterDescription(
              name: 'registrationToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .finishRegistration(
                    session,
                    registrationToken: params['registrationToken'],
                    password: params['password'],
                  ),
        ),
        'startPasswordReset': _is.MethodConnector(
          name: 'startPasswordReset',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .startPasswordReset(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyPasswordResetCode': _is.MethodConnector(
          name: 'verifyPasswordResetCode',
          params: {
            'passwordResetRequestId': _is.ParameterDescription(
              name: 'passwordResetRequestId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _is.ParameterDescription(
              name: 'verificationCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .verifyPasswordResetCode(
                    session,
                    passwordResetRequestId: params['passwordResetRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishPasswordReset': _is.MethodConnector(
          name: 'finishPasswordReset',
          params: {
            'finishPasswordResetToken': _is.ParameterDescription(
              name: 'finishPasswordResetToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'newPassword': _is.ParameterDescription(
              name: 'newPassword',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .finishPasswordReset(
                    session,
                    finishPasswordResetToken:
                        params['finishPasswordResetToken'],
                    newPassword: params['newPassword'],
                  ),
        ),
        'hasAccount': _is.MethodConnector(
          name: 'hasAccount',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .hasAccount(session),
        ),
      },
    );
    connectors['googleIdp'] = _is.EndpointConnector(
      name: 'googleIdp',
      endpoint: endpoints['googleIdp']!,
      methodConnectors: {
        'login': _is.MethodConnector(
          name: 'login',
          params: {
            'idToken': _is.ParameterDescription(
              name: 'idToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'accessToken': _is.ParameterDescription(
              name: 'accessToken',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['googleIdp'] as _i71axiz0.GoogleIdpEndpoint).login(
                    session,
                    idToken: params['idToken'],
                    accessToken: params['accessToken'],
                  ),
        ),
        'loginWithCode': _is.MethodConnector(
          name: 'loginWithCode',
          params: {
            'code': _is.ParameterDescription(
              name: 'code',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'codeVerifier': _is.ParameterDescription(
              name: 'codeVerifier',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'redirectUri': _is.ParameterDescription(
              name: 'redirectUri',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['googleIdp'] as _i71axiz0.GoogleIdpEndpoint)
                  .loginWithCode(
                    session,
                    code: params['code'],
                    codeVerifier: params['codeVerifier'],
                    redirectUri: params['redirectUri'],
                  ),
        ),
        'hasAccount': _is.MethodConnector(
          name: 'hasAccount',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['googleIdp'] as _i71axiz0.GoogleIdpEndpoint)
                  .hasAccount(session),
        ),
      },
    );
    connectors['jwtRefresh'] = _is.EndpointConnector(
      name: 'jwtRefresh',
      endpoint: endpoints['jwtRefresh']!,
      methodConnectors: {
        'refreshAccessToken': _is.MethodConnector(
          name: 'refreshAccessToken',
          params: {
            'refreshToken': _is.ParameterDescription(
              name: 'refreshToken',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['jwtRefresh'] as _inwq3ztq.JwtRefreshEndpoint)
                      .refreshAccessToken(
                        session,
                        refreshToken: params['refreshToken'],
                      ),
        ),
      },
    );
    connectors['moderation'] = _is.EndpointConnector(
      name: 'moderation',
      endpoint: endpoints['moderation']!,
      methodConnectors: {
        'report': _is.MethodConnector(
          name: 'report',
          params: {
            'actionDefinitionId': _is.ParameterDescription(
              name: 'actionDefinitionId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'category': _is.ParameterDescription(
              name: 'category',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'details': _is.ParameterDescription(
              name: 'details',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'idempotencyKey': _is.ParameterDescription(
              name: 'idempotencyKey',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['moderation'] as _icwcy5wq.ModerationEndpoint)
                      .report(
                        session,
                        actionDefinitionId: params['actionDefinitionId'],
                        category: params['category'],
                        details: params['details'],
                        idempotencyKey: params['idempotencyKey'],
                      ),
        ),
        'getStatus': _is.MethodConnector(
          name: 'getStatus',
          params: {
            'caseId': _is.ParameterDescription(
              name: 'caseId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['moderation'] as _icwcy5wq.ModerationEndpoint)
                      .getStatus(
                        session,
                        caseId: params['caseId'],
                      ),
        ),
        'listMine': _is.MethodConnector(
          name: 'listMine',
          params: {
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['moderation'] as _icwcy5wq.ModerationEndpoint)
                      .listMine(
                        session,
                        limit: params['limit'],
                      ),
        ),
        'appeal': _is.MethodConnector(
          name: 'appeal',
          params: {
            'caseId': _is.ParameterDescription(
              name: 'caseId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'reason': _is.ParameterDescription(
              name: 'reason',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['moderation'] as _icwcy5wq.ModerationEndpoint)
                      .appeal(
                        session,
                        caseId: params['caseId'],
                        reason: params['reason'],
                      ),
        ),
      },
    );
    connectors['moderationReview'] = _is.EndpointConnector(
      name: 'moderationReview',
      endpoint: endpoints['moderationReview']!,
      methodConnectors: {
        'listQueue': _is.MethodConnector(
          name: 'listQueue',
          params: {
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['moderationReview']
                          as _ilzfasxk.ModerationReviewEndpoint)
                      .listQueue(
                        session,
                        limit: params['limit'],
                      ),
        ),
        'getCase': _is.MethodConnector(
          name: 'getCase',
          params: {
            'caseId': _is.ParameterDescription(
              name: 'caseId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['moderationReview']
                          as _ilzfasxk.ModerationReviewEndpoint)
                      .getCase(
                        session,
                        caseId: params['caseId'],
                      ),
        ),
        'review': _is.MethodConnector(
          name: 'review',
          params: {
            'caseId': _is.ParameterDescription(
              name: 'caseId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'decision': _is.ParameterDescription(
              name: 'decision',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'note': _is.ParameterDescription(
              name: 'note',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['moderationReview']
                          as _ilzfasxk.ModerationReviewEndpoint)
                      .review(
                        session,
                        caseId: params['caseId'],
                        decision: params['decision'],
                        note: params['note'],
                      ),
        ),
        'resolveAppeal': _is.MethodConnector(
          name: 'resolveAppeal',
          params: {
            'caseId': _is.ParameterDescription(
              name: 'caseId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'decision': _is.ParameterDescription(
              name: 'decision',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'note': _is.ParameterDescription(
              name: 'note',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['moderationReview']
                          as _ilzfasxk.ModerationReviewEndpoint)
                      .resolveAppeal(
                        session,
                        caseId: params['caseId'],
                        decision: params['decision'],
                        note: params['note'],
                      ),
        ),
      },
    );
    connectors['payoutWallet'] = _is.EndpointConnector(
      name: 'payoutWallet',
      endpoint: endpoints['payoutWallet']!,
      methodConnectors: {
        'getMine': _is.MethodConnector(
          name: 'getMine',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['payoutWallet'] as _i9hfqu1s.PayoutWalletEndpoint)
                      .getMine(session),
        ),
        'createWalletLinkChallenge': _is.MethodConnector(
          name: 'createWalletLinkChallenge',
          params: {
            'walletAddress': _is.ParameterDescription(
              name: 'walletAddress',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['payoutWallet'] as _i9hfqu1s.PayoutWalletEndpoint)
                      .createWalletLinkChallenge(
                        session,
                        walletAddress: params['walletAddress'],
                      ),
        ),
        'linkPayoutWallet': _is.MethodConnector(
          name: 'linkPayoutWallet',
          params: {
            'walletAddress': _is.ParameterDescription(
              name: 'walletAddress',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'nonce': _is.ParameterDescription(
              name: 'nonce',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'signature': _is.ParameterDescription(
              name: 'signature',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['payoutWallet'] as _i9hfqu1s.PayoutWalletEndpoint)
                      .linkPayoutWallet(
                        session,
                        walletAddress: params['walletAddress'],
                        nonce: params['nonce'],
                        signature: params['signature'],
                      ),
        ),
      },
    );
    connectors['rewards'] = _is.EndpointConnector(
      name: 'rewards',
      endpoint: endpoints['rewards']!,
      methodConnectors: {
        'getRewardPool': _is.MethodConnector(
          name: 'getRewardPool',
          params: {
            'actionId': _is.ParameterDescription(
              name: 'actionId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['rewards'] as _i4hn2z2u.RewardsEndpoint)
                  .getRewardPool(
                    session,
                    actionId: params['actionId'],
                  ),
        ),
        'prepareRewardFunding': _is.MethodConnector(
          name: 'prepareRewardFunding',
          params: {
            'actionId': _is.ParameterDescription(
              name: 'actionId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['rewards'] as _i4hn2z2u.RewardsEndpoint)
                  .prepareRewardFunding(
                    session,
                    actionId: params['actionId'],
                  ),
        ),
        'confirmRewardFunding': _is.MethodConnector(
          name: 'confirmRewardFunding',
          params: {
            'actionId': _is.ParameterDescription(
              name: 'actionId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'signature': _is.ParameterDescription(
              name: 'signature',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['rewards'] as _i4hn2z2u.RewardsEndpoint)
                  .confirmRewardFunding(
                    session,
                    actionId: params['actionId'],
                    signature: params['signature'],
                  ),
        ),
        'endRewardEarly': _is.MethodConnector(
          name: 'endRewardEarly',
          params: {
            'actionId': _is.ParameterDescription(
              name: 'actionId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['rewards'] as _i4hn2z2u.RewardsEndpoint)
                  .endRewardEarly(
                    session,
                    actionId: params['actionId'],
                  ),
        ),
        'listMyPayouts': _is.MethodConnector(
          name: 'listMyPayouts',
          params: {
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['rewards'] as _i4hn2z2u.RewardsEndpoint)
                  .listMyPayouts(
                    session,
                    limit: params['limit'],
                  ),
        ),
      },
    );
    connectors['verificationRequest'] = _is.EndpointConnector(
      name: 'verificationRequest',
      endpoint: endpoints['verificationRequest']!,
      methodConnectors: {
        'getRequest': _is.MethodConnector(
          name: 'getRequest',
          params: {
            'requestId': _is.ParameterDescription(
              name: 'requestId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['verificationRequest']
                          as _iw1snziy.VerificationRequestEndpoint)
                      .getRequest(
                        session,
                        requestId: params['requestId'],
                      ),
        ),
        'accept': _is.MethodConnector(
          name: 'accept',
          params: {
            'requestId': _is.ParameterDescription(
              name: 'requestId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['verificationRequest']
                          as _iw1snziy.VerificationRequestEndpoint)
                      .accept(
                        session,
                        requestId: params['requestId'],
                      ),
        ),
        'decline': _is.MethodConnector(
          name: 'decline',
          params: {
            'requestId': _is.ParameterDescription(
              name: 'requestId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['verificationRequest']
                          as _iw1snziy.VerificationRequestEndpoint)
                      .decline(
                        session,
                        requestId: params['requestId'],
                      ),
        ),
        'finish': _is.MethodConnector(
          name: 'finish',
          params: {
            'requestId': _is.ParameterDescription(
              name: 'requestId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['verificationRequest']
                          as _iw1snziy.VerificationRequestEndpoint)
                      .finish(
                        session,
                        requestId: params['requestId'],
                      ),
        ),
      },
    );
    modules['serverpod_auth_core'] = _iacs.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth_idp'] = _iais.Endpoints()
      ..initializeEndpoints(server);
  }

  @override
  _is.FutureCallDispatch? get futureCalls {
    return _ic0hj7xj.FutureCalls();
  }
}
