/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_type_check

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/protocol.dart' as _isp;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;
import 'package:verily_server/src/generated/action_verification/action_attempt_view.dart'
    as _iyvinv8z;
import 'package:verily_server/src/generated/action_verification/action_opportunity.dart'
    as _iryxm23q;
import 'package:verily_server/src/generated/action_verification/action_template.dart'
    as _icxixoim;
import 'package:verily_server/src/generated/action_verification/evidence_appeal_view.dart'
    as _igl29vg6;
import 'package:verily_server/src/generated/action_verification/evidence_review_queue_item.dart'
    as _ioe3uq94;
import 'package:verily_server/src/generated/apps/app_confirmation_view.dart'
    as _i8j33595;
import 'package:verily_server/src/generated/apps/verily_app_view.dart'
    as _i4dty38s;
import 'package:verily_server/src/generated/apps/webhooks/app_webhook_delivery_view.dart'
    as _i1cq8y15;
import 'package:verily_server/src/generated/moderation/moderation_case_status_view.dart'
    as _ikb2aklq;
import 'package:verily_server/src/generated/rewards/reward_payout_view.dart'
    as _ijh2di3d;

import 'abuse/abuse_risk_assessment.dart' as _ifpimmza;
import 'account/account_closure.dart' as _if4812wc;
import 'account/account_closure_status.dart' as _i7zadist;
import 'action_verification/action_attempt.dart' as _igwrfg7c;
import 'action_verification/action_attempt_status.dart' as _iu22l7ek;
import 'action_verification/action_attempt_view.dart' as _ixgg3yqh;
import 'action_verification/action_authoring_exception.dart' as _i8z355ak;
import 'action_verification/action_authoring_problem.dart' as _ifi47ne5;
import 'action_verification/action_capture_challenge.dart' as _irhbzkbi;
import 'action_verification/action_capture_challenge_cleanup_task.dart'
    as _idx11lej;
import 'action_verification/action_capture_challenge_view.dart' as _i55m67tr;
import 'action_verification/action_definition.dart' as _ip3p3cwa;
import 'action_verification/action_definition_status.dart' as _igizisql;
import 'action_verification/action_draft_proposal.dart' as _iqti045q;
import 'action_verification/action_drafting_unavailable_exception.dart'
    as _ism88bqz;
import 'action_verification/action_evidence.dart' as _ikmbmeqc;
import 'action_verification/action_evidence_input.dart' as _iq3mdjhk;
import 'action_verification/action_location_rule.dart' as _iz39t19t;
import 'action_verification/action_media_rule.dart' as _iw9if8ju;
import 'action_verification/action_motion_axis.dart' as _i5b1uunc;
import 'action_verification/action_motion_rule.dart' as _ih8siueq;
import 'action_verification/action_motion_sample.dart' as _irayxhn9;
import 'action_verification/action_motion_type.dart' as _i6u7fweb;
import 'action_verification/action_movement_kind.dart' as _im1lc214;
import 'action_verification/action_opportunity.dart' as _im9dc1is;
import 'action_verification/action_qr_challenge.dart' as _ikdqwmpd;
import 'action_verification/action_qr_challenge_cleanup_task.dart' as _ixcs1xdh;
import 'action_verification/action_qr_challenge_view.dart' as _iqwh4ycl;
import 'action_verification/action_qr_rule.dart' as _ii99v1ve;
import 'action_verification/action_recurrence.dart' as _i45a1wjj;
import 'action_verification/action_requirement.dart' as _inly21qh;
import 'action_verification/action_requirement_draft.dart' as _ivobne24;
import 'action_verification/action_requirement_kind.dart' as _i55w548r;
import 'action_verification/action_requirement_view.dart' as _icsa4634;
import 'action_verification/action_spoken_challenge.dart' as _i14ro0o5;
import 'action_verification/action_spoken_challenge_cleanup_task.dart'
    as _ifuw4tho;
import 'action_verification/action_spoken_challenge_view.dart' as _iikyln3l;
import 'action_verification/action_template.dart' as _i0iphegd;
import 'action_verification/action_verification_policy.dart' as _i960u7rl;
import 'action_verification/action_visibility.dart' as _ichxscv5;
import 'action_verification/create_action_definition_request.dart' as _i5yjywpf;
import 'action_verification/evidence_appeal.dart' as _i9u1614a;
import 'action_verification/evidence_appeal_status.dart' as _i90o7tud;
import 'action_verification/evidence_appeal_view.dart' as _iy27rorb;
import 'action_verification/evidence_decision.dart' as _ii2t12jt;
import 'action_verification/evidence_decision_status.dart' as _i5tayeq6;
import 'action_verification/evidence_provenance_level.dart' as _i1gh041m;
import 'action_verification/evidence_review_queue_item.dart' as _i0mgpur2;
import 'action_verification/evidence_submission_result.dart' as _iy0z34jt;
import 'action_verification/evidence_verification_job.dart' as _i5dnc8lk;
import 'action_verification/evidence_verification_job_status.dart' as _i2k44lse;
import 'action_verification/evidence_verification_recovery_task.dart'
    as _il1p2vsk;
import 'action_verification/evidence_verification_task.dart' as _in8wt7wh;
import 'action_verification/evidence_verification_vote.dart' as _itcyvpmo;
import 'action_verification/local_check/action_local_check.dart' as _iu3m4umr;
import 'action_verification/local_check/device_local_check_result.dart'
    as _iarjk3hm;
import 'action_verification/local_check/local_check_model_view.dart'
    as _iqhexf0c;
import 'action_verification/local_check/local_check_task.dart' as _if2a7jyy;
import 'action_verification/media_upload_confirmation.dart' as _i9z86si9;
import 'action_verification/missing_resource.dart' as _itcje0ok;
import 'action_verification/payout_review_view.dart' as _i05z8wlg;
import 'action_verification/resource_not_found_exception.dart' as _ihri8lgz;
import 'ai_usage/ai_usage_request.dart' as _imnd8hof;
import 'ai_usage/ai_usage_status.dart' as _ij8e0uwy;
import 'apps/action_external_rule.dart' as _i00uumzo;
import 'apps/app_confirmation.dart' as _iix86y46;
import 'apps/app_confirmation_outcome.dart' as _ix5pwyym;
import 'apps/app_confirmation_view.dart' as _iqtml4wq;
import 'apps/app_platform_exception.dart' as _iwa6gvjs;
import 'apps/app_platform_problem.dart' as _if20wdmx;
import 'apps/app_pull_check.dart' as _iem3wxny;
import 'apps/app_pull_check_recovery_task.dart' as _inaep7ed;
import 'apps/app_pull_check_status.dart' as _i3ubh0mc;
import 'apps/app_pull_check_task.dart' as _i3j4e45w;
import 'apps/app_unavailable_exception.dart' as _i3krqelq;
import 'apps/app_verification_mode.dart' as _ijzftij0;
import 'apps/linking/app_link_code_cleanup_task.dart' as _i36kvzuc;
import 'apps/linking/app_link_redirect.dart' as _i6s4a256;
import 'apps/linking/app_link_request_view.dart' as _ilshz35f;
import 'apps/linking/verily_app_link_code.dart' as _i6yo3b5n;
import 'apps/verily_app.dart' as _in5ng4ea;
import 'apps/verily_app_credential.dart' as _iaui7d4n;
import 'apps/verily_app_key.dart' as _ibhkb5dt;
import 'apps/verily_app_key_view.dart' as _ipa8tni0;
import 'apps/verily_app_link.dart' as _ikhive7i;
import 'apps/verily_app_link_view.dart' as _ikihia57;
import 'apps/verily_app_rate_window.dart' as _ie89zcz8;
import 'apps/verily_app_redirect_uri.dart' as _iqs5ny0z;
import 'apps/verily_app_status.dart' as _ibal4ihb;
import 'apps/verily_app_view.dart' as _ifrl0pdw;
import 'apps/webhooks/app_event.dart' as _i13rn6uf;
import 'apps/webhooks/app_event_delivery_task.dart' as _ichijhlk;
import 'apps/webhooks/app_event_recovery_task.dart' as _igoow6fn;
import 'apps/webhooks/app_event_status.dart' as _io6036x8;
import 'apps/webhooks/app_webhook_delivery.dart' as _irpgk99g;
import 'apps/webhooks/app_webhook_delivery_view.dart' as _ifch1v2s;
import 'apps/webhooks/verily_app_webhook_secret.dart' as _it0ux8yj;
import 'evidence_storage/evidence_upload_cleanup_task.dart' as _ioo44wgs;
import 'evidence_storage/evidence_upload_reservation.dart' as _is4ltac0;
import 'evidence_storage/evidence_upload_status.dart' as _iz4zjc1b;
import 'inference/inference_cost_reservation.dart' as _ib7h7gae;
import 'moderation/moderation_audit_entry.dart' as _i6lm2vyc;
import 'moderation/moderation_audit_view.dart' as _i59xm5p1;
import 'moderation/moderation_case.dart' as _ili1rv2x;
import 'moderation/moderation_case_review_view.dart' as _iygcn9wp;
import 'moderation/moderation_case_status_view.dart' as _i7oivf7f;
import 'rewards/payout_wallet.dart' as _inzarup3;
import 'rewards/payout_wallet_challenge_cleanup_task.dart' as _iyph9n2p;
import 'rewards/payout_wallet_link_challenge.dart' as _i717n6wz;
import 'rewards/payout_wallet_link_challenge_view.dart' as _icfglt50;
import 'rewards/payout_wallet_view.dart' as _iqtp7i2n;
import 'rewards/reward_cluster.dart' as _i3rw9wf5;
import 'rewards/reward_end_plan.dart' as _ilrvghyo;
import 'rewards/reward_exception.dart' as _in6hek74;
import 'rewards/reward_funding_plan.dart' as _iyf1v3jl;
import 'rewards/reward_outcome.dart' as _iv4eta4e;
import 'rewards/reward_payout.dart' as _i09j9cr3;
import 'rewards/reward_payout_recovery_task.dart' as _i3dio64d;
import 'rewards/reward_payout_status.dart' as _idfqmhge;
import 'rewards/reward_payout_task.dart' as _isxaon27;
import 'rewards/reward_payout_view.dart' as _ieggihqi;
import 'rewards/reward_pool.dart' as _i5k7uglj;
import 'rewards/reward_pool_status.dart' as _iv8dpf52;
import 'rewards/reward_pool_view.dart' as _if6e3cxh;
import 'rewards/reward_problem.dart' as _i4sm4ipz;
import 'rewards/reward_summary.dart' as _i9b5h2nk;
import 'rewards/reward_terms_draft.dart' as _iokaii94;
import 'verification_requests/verification_request.dart' as _i3qq4r4i;
import 'verification_requests/verification_request_check.dart' as _ig30b0kc;
import 'verification_requests/verification_request_expiry_task.dart'
    as _igwxgobn;
import 'verification_requests/verification_request_kind.dart' as _ij8vmgkg;
import 'verification_requests/verification_request_redirect.dart' as _ik3wnzle;
import 'verification_requests/verification_request_status.dart' as _in2jgiwv;
import 'verification_requests/verification_request_view.dart' as _i3v95178;
export 'abuse/abuse_risk_assessment.dart';
export 'account/account_closure.dart';
export 'account/account_closure_status.dart';
export 'action_verification/action_attempt.dart';
export 'action_verification/action_attempt_status.dart';
export 'action_verification/action_attempt_view.dart';
export 'action_verification/action_authoring_exception.dart';
export 'action_verification/action_authoring_problem.dart';
export 'action_verification/action_capture_challenge.dart';
export 'action_verification/action_capture_challenge_cleanup_task.dart';
export 'action_verification/action_capture_challenge_view.dart';
export 'action_verification/action_definition.dart';
export 'action_verification/action_definition_status.dart';
export 'action_verification/action_draft_proposal.dart';
export 'action_verification/action_drafting_unavailable_exception.dart';
export 'action_verification/action_evidence.dart';
export 'action_verification/action_evidence_input.dart';
export 'action_verification/action_location_rule.dart';
export 'action_verification/action_media_rule.dart';
export 'action_verification/action_motion_axis.dart';
export 'action_verification/action_motion_rule.dart';
export 'action_verification/action_motion_sample.dart';
export 'action_verification/action_motion_type.dart';
export 'action_verification/action_movement_kind.dart';
export 'action_verification/action_opportunity.dart';
export 'action_verification/action_qr_challenge.dart';
export 'action_verification/action_qr_challenge_cleanup_task.dart';
export 'action_verification/action_qr_challenge_view.dart';
export 'action_verification/action_qr_rule.dart';
export 'action_verification/action_recurrence.dart';
export 'action_verification/action_requirement.dart';
export 'action_verification/action_requirement_draft.dart';
export 'action_verification/action_requirement_kind.dart';
export 'action_verification/action_requirement_view.dart';
export 'action_verification/action_spoken_challenge.dart';
export 'action_verification/action_spoken_challenge_cleanup_task.dart';
export 'action_verification/action_spoken_challenge_view.dart';
export 'action_verification/action_template.dart';
export 'action_verification/action_verification_policy.dart';
export 'action_verification/action_visibility.dart';
export 'action_verification/create_action_definition_request.dart';
export 'action_verification/evidence_appeal.dart';
export 'action_verification/evidence_appeal_status.dart';
export 'action_verification/evidence_appeal_view.dart';
export 'action_verification/evidence_decision.dart';
export 'action_verification/evidence_decision_status.dart';
export 'action_verification/evidence_provenance_level.dart';
export 'action_verification/evidence_review_queue_item.dart';
export 'action_verification/evidence_submission_result.dart';
export 'action_verification/evidence_verification_job.dart';
export 'action_verification/evidence_verification_job_status.dart';
export 'action_verification/evidence_verification_recovery_task.dart';
export 'action_verification/evidence_verification_task.dart';
export 'action_verification/evidence_verification_vote.dart';
export 'action_verification/local_check/action_local_check.dart';
export 'action_verification/local_check/device_local_check_result.dart';
export 'action_verification/local_check/local_check_model_view.dart';
export 'action_verification/local_check/local_check_task.dart';
export 'action_verification/media_upload_confirmation.dart';
export 'action_verification/missing_resource.dart';
export 'action_verification/payout_review_view.dart';
export 'action_verification/resource_not_found_exception.dart';
export 'ai_usage/ai_usage_request.dart';
export 'ai_usage/ai_usage_status.dart';
export 'apps/action_external_rule.dart';
export 'apps/app_confirmation.dart';
export 'apps/app_confirmation_outcome.dart';
export 'apps/app_confirmation_view.dart';
export 'apps/app_platform_exception.dart';
export 'apps/app_platform_problem.dart';
export 'apps/app_pull_check.dart';
export 'apps/app_pull_check_recovery_task.dart';
export 'apps/app_pull_check_status.dart';
export 'apps/app_pull_check_task.dart';
export 'apps/app_unavailable_exception.dart';
export 'apps/app_verification_mode.dart';
export 'apps/linking/app_link_code_cleanup_task.dart';
export 'apps/linking/app_link_redirect.dart';
export 'apps/linking/app_link_request_view.dart';
export 'apps/linking/verily_app_link_code.dart';
export 'apps/verily_app.dart';
export 'apps/verily_app_credential.dart';
export 'apps/verily_app_key.dart';
export 'apps/verily_app_key_view.dart';
export 'apps/verily_app_link.dart';
export 'apps/verily_app_link_view.dart';
export 'apps/verily_app_rate_window.dart';
export 'apps/verily_app_redirect_uri.dart';
export 'apps/verily_app_status.dart';
export 'apps/verily_app_view.dart';
export 'apps/webhooks/app_event.dart';
export 'apps/webhooks/app_event_delivery_task.dart';
export 'apps/webhooks/app_event_recovery_task.dart';
export 'apps/webhooks/app_event_status.dart';
export 'apps/webhooks/app_webhook_delivery.dart';
export 'apps/webhooks/app_webhook_delivery_view.dart';
export 'apps/webhooks/verily_app_webhook_secret.dart';
export 'evidence_storage/evidence_upload_cleanup_task.dart';
export 'evidence_storage/evidence_upload_reservation.dart';
export 'evidence_storage/evidence_upload_status.dart';
export 'inference/inference_cost_reservation.dart';
export 'moderation/moderation_audit_entry.dart';
export 'moderation/moderation_audit_view.dart';
export 'moderation/moderation_case.dart';
export 'moderation/moderation_case_review_view.dart';
export 'moderation/moderation_case_status_view.dart';
export 'rewards/payout_wallet.dart';
export 'rewards/payout_wallet_challenge_cleanup_task.dart';
export 'rewards/payout_wallet_link_challenge.dart';
export 'rewards/payout_wallet_link_challenge_view.dart';
export 'rewards/payout_wallet_view.dart';
export 'rewards/reward_cluster.dart';
export 'rewards/reward_end_plan.dart';
export 'rewards/reward_exception.dart';
export 'rewards/reward_funding_plan.dart';
export 'rewards/reward_outcome.dart';
export 'rewards/reward_payout.dart';
export 'rewards/reward_payout_recovery_task.dart';
export 'rewards/reward_payout_status.dart';
export 'rewards/reward_payout_task.dart';
export 'rewards/reward_payout_view.dart';
export 'rewards/reward_pool.dart';
export 'rewards/reward_pool_status.dart';
export 'rewards/reward_pool_view.dart';
export 'rewards/reward_problem.dart';
export 'rewards/reward_summary.dart';
export 'rewards/reward_terms_draft.dart';
export 'verification_requests/verification_request.dart';
export 'verification_requests/verification_request_check.dart';
export 'verification_requests/verification_request_expiry_task.dart';
export 'verification_requests/verification_request_kind.dart';
export 'verification_requests/verification_request_redirect.dart';
export 'verification_requests/verification_request_status.dart';
export 'verification_requests/verification_request_view.dart';

class Protocol extends _is.DatabaseSerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  static List<_isp.TableDefinition> get targetTableDefinitions => [
    _isp.TableDefinition(
      name: 'verily_abuse_risk_assessment',
      dartName: 'AbuseRiskAssessment',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'actionDefinitionId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'assessmentKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'phase',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'policyVersion',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'disposition',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'tier',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'score',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'signalCodes',
          columnType: _isp.ColumnType.json,
          isNullable: false,
          dartType: 'List<String>',
        ),
        _isp.ColumnDefinition(
          name: 'correlationWindowStartsAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_abuse_risk_assessment_fk_0',
          columns: ['actionDefinitionId'],
          referenceTable: 'verily_action_definition',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_abuse_assessment_key_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'assessmentKey',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_abuse_assessment_action_time_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'actionDefinitionId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_account_closure',
      dartName: 'AccountClosure',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'authUserId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:AccountClosureStatus',
          columnDefault: '\'closed\'',
        ),
        _isp.ColumnDefinition(
          name: 'requestedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'identityPurgedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_account_closure_fk_0',
          columns: ['authUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_account_closure_user_unique_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'authUserId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_account_closure_requested_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'requestedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_action_attempt',
      dartName: 'ActionAttempt',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'actionDefinitionId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'participantAuthUserId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'periodKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'idempotencyKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ActionAttemptStatus',
        ),
        _isp.ColumnDefinition(
          name: 'verificationScore',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'verifiedRank',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'rejectionCode',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'rewardOutcome',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:RewardOutcome?',
        ),
        _isp.ColumnDefinition(
          name: 'startedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'submittedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'verifiedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_action_attempt_fk_0',
          columns: ['actionDefinitionId'],
          referenceTable: 'verily_action_definition',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_action_attempt_fk_1',
          columns: ['participantAuthUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_action_attempt_verified_window_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'status',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'verifiedAt',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'actionDefinitionId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_action_attempt_idempotency_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'participantAuthUserId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'idempotencyKey',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_action_attempt_period_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'actionDefinitionId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'participantAuthUserId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'periodKey',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_action_attempt_participant_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'participantAuthUserId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'updatedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_action_attempt_status_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'actionDefinitionId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'status',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'updatedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_action_capture_challenge',
      dartName: 'ActionCaptureChallenge',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'attemptId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'requirementId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'participantAuthUserId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'nonce',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'requestHash',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'evidenceBindingHash',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'expiresAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'usedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'provider',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'verdict',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'tokenHash',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_action_capture_challenge_fk_0',
          columns: ['attemptId'],
          referenceTable: 'verily_action_attempt',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_action_capture_challenge_fk_1',
          columns: ['requirementId'],
          referenceTable: 'verily_action_requirement',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_action_capture_challenge_fk_2',
          columns: ['participantAuthUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_action_capture_challenge_nonce_unique_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'nonce',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_action_capture_challenge_request_hash_unique_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'requestHash',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_action_capture_challenge_attempt_created_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'attemptId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_action_capture_challenge_requirement_fk_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'requirementId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_action_capture_challenge_expiry_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'expiresAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_action_definition',
      dartName: 'ActionDefinition',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'creatorAuthUserId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'actionKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
        _isp.ColumnDefinition(
          name: 'title',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'description',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ActionDefinitionStatus',
        ),
        _isp.ColumnDefinition(
          name: 'recurrence',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ActionRecurrence',
        ),
        _isp.ColumnDefinition(
          name: 'timeZone',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'maxVerifiedCompletions',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'verifiedCompletions',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'opensAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'closesAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'publishedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'pausedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'visibility',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ActionVisibility',
          columnDefault: '\'public\'',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_action_definition_fk_0',
          columns: ['creatorAuthUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_action_definition_creator_key_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'creatorAuthUserId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'actionKey',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'revision',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_action_definition_creator_updated_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'creatorAuthUserId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'updatedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_action_definition_status_created_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'status',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_action_evidence',
      dartName: 'ActionEvidence',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'attemptId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'requirementId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ActionRequirementKind',
        ),
        _isp.ColumnDefinition(
          name: 'storagePath',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'storageVersionId',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'mimeType',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'sha256Digest',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'byteLength',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'durationSeconds',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'location',
          columnType: _isp.ColumnType.geography,
          isNullable: true,
          dartType: 'GeographyPoint?',
        ),
        _isp.ColumnDefinition(
          name: 'accuracyMeters',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'motionTraceJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'motionTraceSha256',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'motionSampleCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'motionDurationMilliseconds',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'motionAnalysisJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'deviceRepetitionCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'deviceTrackerVersion',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'spokenChallengeId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'spokenChallengeWord',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'deviceLocalCheckModelId',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'deviceLocalCheckModelSha256',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'deviceLocalCheckLabel',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'deviceLocalCheckScore',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'deviceLocalCheckMatchedFrames',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'provenanceLevel',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:EvidenceProvenanceLevel',
          columnDefault: '\'basic\'',
        ),
        _isp.ColumnDefinition(
          name: 'captureManifest',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'captureSignature',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'capturePublicKey',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'captureKeyId',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'captureKeyStorage',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'captureCertificateChain',
          columnType: _isp.ColumnType.json,
          isNullable: true,
          dartType: 'List<String>?',
        ),
        _isp.ColumnDefinition(
          name: 'captureDeviceKeyId',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'capturedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'submittedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_action_evidence_fk_0',
          columns: ['attemptId'],
          referenceTable: 'verily_action_attempt',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_action_evidence_fk_1',
          columns: ['requirementId'],
          referenceTable: 'verily_action_requirement',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_action_evidence_fk_2',
          columns: ['spokenChallengeId'],
          referenceTable: 'verily_action_spoken_challenge',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_action_evidence_requirement_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'attemptId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'requirementId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_action_evidence_submitted_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'attemptId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'submittedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_action_evidence_requirement_fk_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'requirementId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_action_evidence_spoken_challenge_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'spokenChallengeId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_action_evidence_location_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'location',
            ),
          ],
          type: 'gist',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_action_external_rule',
      dartName: 'ActionExternalRule',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'requirementId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'appId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'verificationMode',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:AppVerificationMode',
          columnDefault: '\'push\'',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_action_external_rule_fk_0',
          columns: ['requirementId'],
          referenceTable: 'verily_action_requirement',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_action_external_rule_fk_1',
          columns: ['appId'],
          referenceTable: 'verily_app',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_action_external_rule_requirement_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'requirementId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_action_external_rule_app_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'appId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_action_location_rule',
      dartName: 'ActionLocationRule',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'requirementId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'location',
          columnType: _isp.ColumnType.geography,
          isNullable: false,
          dartType: 'GeographyPoint',
        ),
        _isp.ColumnDefinition(
          name: 'radiusMeters',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _isp.ColumnDefinition(
          name: 'maxAccuracyMeters',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_action_location_rule_fk_0',
          columns: ['requirementId'],
          referenceTable: 'verily_action_requirement',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_action_location_rule_requirement_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'requirementId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_action_location_rule_location_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'location',
            ),
          ],
          type: 'gist',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_action_media_rule',
      dartName: 'ActionMediaRule',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'requirementId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ActionRequirementKind',
        ),
        _isp.ColumnDefinition(
          name: 'verificationPrompt',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'minDurationSeconds',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'maxDurationSeconds',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'minConfidence',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _isp.ColumnDefinition(
          name: 'verificationPolicy',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ActionVerificationPolicy',
          columnDefault: '\'singleModel\'',
        ),
        _isp.ColumnDefinition(
          name: 'spokenChallengeRequired',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'movementKind',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:ActionMovementKind?',
        ),
        _isp.ColumnDefinition(
          name: 'targetRepetitions',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'localCheckTask',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:LocalCheckTask?',
        ),
        _isp.ColumnDefinition(
          name: 'localCheckLabel',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'localCheckMinScore',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'localCheckMinFrames',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_action_media_rule_fk_0',
          columns: ['requirementId'],
          referenceTable: 'verily_action_requirement',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_action_media_rule_requirement_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'requirementId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_action_motion_rule',
      dartName: 'ActionMotionRule',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'requirementId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'motionType',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ActionMotionType',
        ),
        _isp.ColumnDefinition(
          name: 'axis',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ActionMotionAxis',
        ),
        _isp.ColumnDefinition(
          name: 'targetRepetitions',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'minDurationSeconds',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'maxDurationSeconds',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'minAngularSpeedRadiansPerSecond',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _isp.ColumnDefinition(
          name: 'maxAngularSpeedRadiansPerSecond',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _isp.ColumnDefinition(
          name: 'minAxisDominance',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _isp.ColumnDefinition(
          name: 'minFreeFallMilliseconds',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'maxFreeFallMilliseconds',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'minPeakAccelerationMetersPerSecondSquared',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _isp.ColumnDefinition(
          name: 'maxPeakAccelerationMetersPerSecondSquared',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_action_motion_rule_fk_0',
          columns: ['requirementId'],
          referenceTable: 'verily_action_requirement',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_action_motion_rule_requirement_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'requirementId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_action_qr_challenge',
      dartName: 'ActionQrChallenge',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'requirementId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'createdByAuthUserId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'secretHash',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'expiresAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'usedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'usedByAttemptId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_action_qr_challenge_fk_0',
          columns: ['requirementId'],
          referenceTable: 'verily_action_requirement',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_action_qr_challenge_fk_1',
          columns: ['createdByAuthUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_action_qr_challenge_fk_2',
          columns: ['usedByAttemptId'],
          referenceTable: 'verily_action_attempt',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_action_qr_challenge_secret_unique_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'secretHash',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_action_qr_challenge_requirement_expiry_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'requirementId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'expiresAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_action_qr_challenge_used_attempt_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'usedByAttemptId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_action_qr_rule',
      dartName: 'ActionQrRule',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'requirementId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'secretHash',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_action_qr_rule_fk_0',
          columns: ['requirementId'],
          referenceTable: 'verily_action_requirement',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_action_qr_rule_requirement_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'requirementId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_action_requirement',
      dartName: 'ActionRequirement',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'actionDefinitionId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'requirementKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ActionRequirementKind',
        ),
        _isp.ColumnDefinition(
          name: 'title',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'instructions',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'position',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'isRequired',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_action_requirement_fk_0',
          columns: ['actionDefinitionId'],
          referenceTable: 'verily_action_definition',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_action_requirement_key_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'actionDefinitionId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'requirementKey',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_action_requirement_position_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'actionDefinitionId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'position',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_action_spoken_challenge',
      dartName: 'ActionSpokenChallenge',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'attemptId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'requirementId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'participantAuthUserId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'word',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'issuedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'expiresAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'boundAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_action_spoken_challenge_fk_0',
          columns: ['attemptId'],
          referenceTable: 'verily_action_attempt',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_action_spoken_challenge_fk_1',
          columns: ['requirementId'],
          referenceTable: 'verily_action_requirement',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_action_spoken_challenge_fk_2',
          columns: ['participantAuthUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_action_spoken_challenge_attempt_requirement_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'attemptId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'requirementId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'issuedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_action_spoken_challenge_expiry_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'expiresAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_ai_usage_request',
      dartName: 'AiUsageRequest',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'authUserId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'operation',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:AiUsageStatus',
          columnDefault: '\'reserved\'',
        ),
        _isp.ColumnDefinition(
          name: 'costUnits',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'completedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_ai_usage_request_fk_0',
          columns: ['authUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_ai_usage_user_operation_created_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'authUserId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'operation',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_ai_usage_active_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'authUserId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'operation',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'status',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_app',
      dartName: 'VerilyApp',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'creatorAuthUserId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'websiteUrl',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:VerilyAppStatus',
        ),
        _isp.ColumnDefinition(
          name: 'rateWindowStartedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'rateWindowCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'webhookUrl',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'webhookSecretVersion',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'previousWebhookSecretVersion',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'webhookSecretRotatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'revokedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_app_fk_0',
          columns: ['creatorAuthUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_app_creator_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'creatorAuthUserId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_app_confirmation',
      dartName: 'AppConfirmation',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'appId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'keyId',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'eventId',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'payloadDigest',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'actionKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'subject',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'actionDefinitionId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'attemptId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'occurredAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'receivedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'outcome',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:AppConfirmationOutcome',
        ),
        _isp.ColumnDefinition(
          name: 'reasonCode',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_app_confirmation_fk_0',
          columns: ['appId'],
          referenceTable: 'verily_app',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_app_confirmation_fk_1',
          columns: ['actionDefinitionId'],
          referenceTable: 'verily_action_definition',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_app_confirmation_fk_2',
          columns: ['attemptId'],
          referenceTable: 'verily_action_attempt',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_app_confirmation_event_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'appId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'eventId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_app_confirmation_received_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'appId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_app_confirmation_attempt_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'attemptId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_app_event',
      dartName: 'AppEvent',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'appId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'eventId',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'type',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'dedupeKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'body',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:AppEventStatus',
        ),
        _isp.ColumnDefinition(
          name: 'attemptCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'nextAttemptAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'leaseExpiresAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'lastStatusCode',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'lastErrorCode',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'deliveredAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_app_event_fk_0',
          columns: ['appId'],
          referenceTable: 'verily_app',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_app_event_id_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'eventId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_app_event_dedupe_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'appId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'dedupeKey',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_app_event_due_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'status',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'nextAttemptAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_app_event_app_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'appId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_app_key',
      dartName: 'VerilyAppKey',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'appId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'keyId',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'secretHash',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'lastUsedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'revokedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_app_key_fk_0',
          columns: ['appId'],
          referenceTable: 'verily_app',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_app_key_id_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'keyId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_app_key_app_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'appId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_app_link',
      dartName: 'VerilyAppLink',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'appId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'authUserId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'subject',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_app_link_fk_0',
          columns: ['appId'],
          referenceTable: 'verily_app',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_app_link_fk_1',
          columns: ['authUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_app_link_subject_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'appId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'subject',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_app_link_account_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'appId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'authUserId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_app_link_code',
      dartName: 'VerilyAppLinkCode',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'appId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'authUserId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'codeHash',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'redirectUri',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'state',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'expiresAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'usedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_app_link_code_fk_0',
          columns: ['appId'],
          referenceTable: 'verily_app',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_app_link_code_fk_1',
          columns: ['authUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_app_link_code_hash_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'codeHash',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_app_link_code_expiry_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'expiresAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_app_pull_check',
      dartName: 'AppPullCheck',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'attemptId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'requirementId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'appId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'eventId',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'reference',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:AppPullCheckStatus',
        ),
        _isp.ColumnDefinition(
          name: 'callCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'nextCallAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'leaseExpiresAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'lastErrorCode',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'reasonCode',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'expiresAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_app_pull_check_fk_0',
          columns: ['attemptId'],
          referenceTable: 'verily_action_attempt',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_app_pull_check_fk_1',
          columns: ['requirementId'],
          referenceTable: 'verily_action_requirement',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_app_pull_check_fk_2',
          columns: ['appId'],
          referenceTable: 'verily_app',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_app_pull_check_requirement_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'attemptId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'requirementId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_app_pull_check_event_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'eventId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_app_pull_check_due_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'status',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'nextCallAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_app_rate_window',
      dartName: 'VerilyAppRateWindow',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'appId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'bucket',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'windowStartedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'requestCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_app_rate_window_fk_0',
          columns: ['appId'],
          referenceTable: 'verily_app',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_app_rate_window_bucket_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'appId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'bucket',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_app_redirect_uri',
      dartName: 'VerilyAppRedirectUri',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'appId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'uri',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_app_redirect_uri_fk_0',
          columns: ['appId'],
          referenceTable: 'verily_app',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_app_redirect_uri_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'appId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'uri',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_app_webhook_delivery',
      dartName: 'AppWebhookDelivery',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'appId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'eventId',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'eventType',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'attemptNumber',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'requestedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'durationMilliseconds',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'statusCode',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'errorCode',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'succeeded',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_app_webhook_delivery_fk_0',
          columns: ['appId'],
          referenceTable: 'verily_app',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_app_webhook_delivery_app_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'appId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_app_webhook_delivery_event_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'eventId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'attemptNumber',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_evidence_appeal',
      dartName: 'EvidenceAppeal',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'evidenceId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'attemptId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'creatorAuthUserId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'participantAuthUserId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'reason',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:EvidenceAppealStatus',
        ),
        _isp.ColumnDefinition(
          name: 'resolutionNote',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'resolvedByAuthUserId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'resolvedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_evidence_appeal_fk_0',
          columns: ['evidenceId'],
          referenceTable: 'verily_action_evidence',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_evidence_appeal_fk_1',
          columns: ['attemptId'],
          referenceTable: 'verily_action_attempt',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_evidence_appeal_fk_2',
          columns: ['creatorAuthUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_evidence_appeal_fk_3',
          columns: ['participantAuthUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_evidence_appeal_fk_4',
          columns: ['resolvedByAuthUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_evidence_appeal_evidence_unique_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'evidenceId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_evidence_appeal_creator_queue_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'creatorAuthUserId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'status',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_evidence_appeal_participant_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'participantAuthUserId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_evidence_appeal_attempt_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'attemptId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_evidence_decision',
      dartName: 'EvidenceDecision',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'evidenceId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:EvidenceDecisionStatus',
        ),
        _isp.ColumnDefinition(
          name: 'verifierType',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'modelName',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'modelVersion',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'confidence',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'reasonCode',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'summary',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'reviewedByAuthUserId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_evidence_decision_fk_0',
          columns: ['evidenceId'],
          referenceTable: 'verily_action_evidence',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_evidence_decision_fk_1',
          columns: ['reviewedByAuthUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_evidence_decision_created_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'evidenceId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_evidence_decision_reviewer_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'reviewedByAuthUserId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_evidence_upload_reservation',
      dartName: 'EvidenceUploadReservation',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'authUserId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'attemptId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'requirementId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ActionRequirementKind',
        ),
        _isp.ColumnDefinition(
          name: 'storagePath',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'contentType',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'byteLength',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:EvidenceUploadStatus',
        ),
        _isp.ColumnDefinition(
          name: 'spokenChallengeId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'requestCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
        _isp.ColumnDefinition(
          name: 'confirmationAttemptCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'reservedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'lastSignedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'uploadExpiresAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'retainUntil',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'confirmationStartedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'confirmedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'storageVersionId',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_evidence_upload_reservation_fk_0',
          columns: ['authUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_evidence_upload_reservation_fk_1',
          columns: ['attemptId'],
          referenceTable: 'verily_action_attempt',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_evidence_upload_reservation_fk_2',
          columns: ['requirementId'],
          referenceTable: 'verily_action_requirement',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_evidence_upload_reservation_fk_3',
          columns: ['spokenChallengeId'],
          referenceTable: 'verily_action_spoken_challenge',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_evidence_upload_attempt_requirement_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'attemptId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'requirementId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_evidence_upload_storage_path_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'storagePath',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_evidence_upload_user_quota_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'authUserId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'reservedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_evidence_upload_cleanup_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'status',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'retainUntil',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_evidence_upload_requirement_fk_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'requirementId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_evidence_upload_spoken_challenge_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'spokenChallengeId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_evidence_verification_job',
      dartName: 'EvidenceVerificationJob',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'evidenceId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:EvidenceVerificationJobStatus',
          columnDefault: '\'queued\'',
        ),
        _isp.ColumnDefinition(
          name: 'attemptCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'startedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'completedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'lastErrorCode',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_evidence_verification_job_fk_0',
          columns: ['evidenceId'],
          referenceTable: 'verily_action_evidence',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_evidence_verification_evidence_unique_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'evidenceId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_evidence_verification_queue_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'status',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_evidence_verification_vote',
      dartName: 'EvidenceVerificationVote',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'decisionId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'evidenceId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'modelId',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'resolvedModelId',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'providerName',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'responseId',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'verdict',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'spokenChallengeVerdict',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'confidence',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'latencyMilliseconds',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'inputTokens',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'outputTokens',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'costCredits',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'errorCode',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_evidence_verification_vote_fk_0',
          columns: ['decisionId'],
          referenceTable: 'verily_evidence_decision',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_evidence_verification_vote_fk_1',
          columns: ['evidenceId'],
          referenceTable: 'verily_action_evidence',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_evidence_verification_vote_decision_model_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'decisionId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'modelId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_evidence_verification_vote_evidence_created_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'evidenceId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_inference_cost_reservation',
      dartName: 'InferenceCostReservation',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'actionAttemptId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'callReference',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'modelId',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'policyVersion',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'reservedMicros',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_inference_cost_reservation_fk_0',
          columns: ['actionAttemptId'],
          referenceTable: 'verily_action_attempt',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_inference_reservation_reference_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'actionAttemptId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'callReference',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_inference_reservation_created_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_moderation_audit_entry',
      dartName: 'ModerationAuditEntry',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'caseId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'actorAuthUserId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'event',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'note',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'pauseActive',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_moderation_audit_entry_fk_0',
          columns: ['caseId'],
          referenceTable: 'verily_moderation_case',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_moderation_audit_entry_fk_1',
          columns: ['actorAuthUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_moderation_audit_case_time_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'caseId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_moderation_case',
      dartName: 'ModerationCase',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'creatorAuthUserId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'actionDefinitionId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'reporterAuthUserId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'idempotencyKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'category',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'details',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'pauseActive',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'reviewedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'reviewedByAuthUserId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'appealReason',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'appealedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'appealResolvedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_moderation_case_fk_0',
          columns: ['creatorAuthUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_moderation_case_fk_1',
          columns: ['actionDefinitionId'],
          referenceTable: 'verily_action_definition',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_moderation_case_fk_2',
          columns: ['reporterAuthUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_moderation_case_fk_3',
          columns: ['reviewedByAuthUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_moderation_case_report_key_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'reporterAuthUserId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'idempotencyKey',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_moderation_case_creator_pause_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'creatorAuthUserId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'pauseActive',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_moderation_case_action_pause_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'actionDefinitionId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'pauseActive',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_moderation_case_queue_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'status',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_payout_wallet',
      dartName: 'PayoutWallet',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'authUserId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'walletAddress',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'linkedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_payout_wallet_fk_0',
          columns: ['authUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_payout_wallet_user_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'authUserId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_payout_wallet_address_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'walletAddress',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_payout_wallet_link_challenge',
      dartName: 'PayoutWalletLinkChallenge',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'authUserId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'walletAddress',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'nonce',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'message',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'expiresAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'usedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_payout_wallet_link_challenge_fk_0',
          columns: ['authUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_payout_wallet_link_nonce_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'nonce',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_payout_wallet_link_user_created_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'authUserId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_payout_wallet_link_expiry_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'expiresAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_reward_payout',
      dartName: 'RewardPayout',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'poolId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'attemptId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'recipientAuthUserId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'payoutIndex',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'amount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'recipientWallet',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:RewardPayoutStatus',
        ),
        _isp.ColumnDefinition(
          name: 'releaseSignature',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'attemptCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'lastErrorCode',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'releaseStartedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'releasedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_reward_payout_fk_0',
          columns: ['poolId'],
          referenceTable: 'verily_reward_pool',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_reward_payout_fk_1',
          columns: ['attemptId'],
          referenceTable: 'verily_action_attempt',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_reward_payout_fk_2',
          columns: ['recipientAuthUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_reward_payout_attempt_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'attemptId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_reward_payout_pool_index_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'poolId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'payoutIndex',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_reward_payout_pool_recipient_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'poolId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'recipientAuthUserId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_reward_payout_recipient_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'recipientAuthUserId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_reward_payout_status_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'status',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'updatedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_reward_pool',
      dartName: 'RewardPool',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'creatorAuthUserId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'actionKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'cluster',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:RewardCluster',
        ),
        _isp.ColumnDefinition(
          name: 'mint',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'tokenSymbol',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'decimals',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'amountPerPayout',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'maxPayouts',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'maxWinsPerAccount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
        _isp.ColumnDefinition(
          name: 'payoutsReserved',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'payoutsReleased',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'creatorWallet',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'escrowAddress',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'arbiterAddress',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'expiresAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'refundDelaySeconds',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'refundAfter',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:RewardPoolStatus',
        ),
        _isp.ColumnDefinition(
          name: 'fundingSignature',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'fundedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'endedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'closedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_reward_pool_fk_0',
          columns: ['creatorAuthUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_reward_pool_creator_key_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'creatorAuthUserId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'actionKey',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_reward_pool_escrow_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'escrowAddress',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_reward_pool_status_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'status',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'expiresAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'verily_verification_request',
      dartName: 'VerificationRequest',
      schema: 'public',
      module: 'verily',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'appId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:VerificationRequestKind',
        ),
        _isp.ColumnDefinition(
          name: 'instructions',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'check',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:VerificationRequestCheck',
        ),
        _isp.ColumnDefinition(
          name: 'placeLatitude',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'placeLongitude',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'placeRadiusMeters',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'spokenChallenge',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _isp.ColumnDefinition(
          name: 'shareEvidence',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _isp.ColumnDefinition(
          name: 'redirectUri',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'state',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:VerificationRequestStatus',
        ),
        _isp.ColumnDefinition(
          name: 'expiresAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'participantAuthUserId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'subject',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'actionDefinitionId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'attemptId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'acceptedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'evidenceShared',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'codeHash',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'codeExpiresAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'codeUsedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'completedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_verification_request_fk_0',
          columns: ['appId'],
          referenceTable: 'verily_app',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_verification_request_fk_1',
          columns: ['participantAuthUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_verification_request_fk_2',
          columns: ['actionDefinitionId'],
          referenceTable: 'verily_action_definition',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'verily_verification_request_fk_3',
          columns: ['attemptId'],
          referenceTable: 'verily_action_attempt',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'verily_verification_request_app_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'appId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_verification_request_status_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'status',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'expiresAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_verification_request_code_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'codeHash',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'verily_verification_request_attempt_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'attemptId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._iacs.Protocol.targetTableDefinitions,
    ..._iais.Protocol.targetTableDefinitions,
    ..._isp.Protocol.targetTableDefinitions,
  ];

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on _is.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _ifpimmza.AbuseRiskAssessment) {
      return _ifpimmza.AbuseRiskAssessment.fromJson(data) as T;
    }
    if (t == _if4812wc.AccountClosure) {
      return _if4812wc.AccountClosure.fromJson(data) as T;
    }
    if (t == _i7zadist.AccountClosureStatus) {
      return _i7zadist.AccountClosureStatus.fromJson(data) as T;
    }
    if (t == _igwrfg7c.ActionAttempt) {
      return _igwrfg7c.ActionAttempt.fromJson(data) as T;
    }
    if (t == _iu22l7ek.ActionAttemptStatus) {
      return _iu22l7ek.ActionAttemptStatus.fromJson(data) as T;
    }
    if (t == _ixgg3yqh.ActionAttemptView) {
      return _ixgg3yqh.ActionAttemptView.fromJson(data) as T;
    }
    if (t == _i8z355ak.ActionAuthoringException) {
      return _i8z355ak.ActionAuthoringException.fromJson(data) as T;
    }
    if (t == _ifi47ne5.ActionAuthoringProblem) {
      return _ifi47ne5.ActionAuthoringProblem.fromJson(data) as T;
    }
    if (t == _irhbzkbi.ActionCaptureChallenge) {
      return _irhbzkbi.ActionCaptureChallenge.fromJson(data) as T;
    }
    if (t == _idx11lej.ActionCaptureChallengeCleanupTask) {
      return _idx11lej.ActionCaptureChallengeCleanupTask.fromJson(data) as T;
    }
    if (t == _i55m67tr.ActionCaptureChallengeView) {
      return _i55m67tr.ActionCaptureChallengeView.fromJson(data) as T;
    }
    if (t == _ip3p3cwa.ActionDefinition) {
      return _ip3p3cwa.ActionDefinition.fromJson(data) as T;
    }
    if (t == _igizisql.ActionDefinitionStatus) {
      return _igizisql.ActionDefinitionStatus.fromJson(data) as T;
    }
    if (t == _iqti045q.ActionDraftProposal) {
      return _iqti045q.ActionDraftProposal.fromJson(data) as T;
    }
    if (t == _ism88bqz.ActionDraftingUnavailableException) {
      return _ism88bqz.ActionDraftingUnavailableException.fromJson(data) as T;
    }
    if (t == _ikmbmeqc.ActionEvidence) {
      return _ikmbmeqc.ActionEvidence.fromJson(data) as T;
    }
    if (t == _iq3mdjhk.ActionEvidenceInput) {
      return _iq3mdjhk.ActionEvidenceInput.fromJson(data) as T;
    }
    if (t == _iz39t19t.ActionLocationRule) {
      return _iz39t19t.ActionLocationRule.fromJson(data) as T;
    }
    if (t == _iw9if8ju.ActionMediaRule) {
      return _iw9if8ju.ActionMediaRule.fromJson(data) as T;
    }
    if (t == _i5b1uunc.ActionMotionAxis) {
      return _i5b1uunc.ActionMotionAxis.fromJson(data) as T;
    }
    if (t == _ih8siueq.ActionMotionRule) {
      return _ih8siueq.ActionMotionRule.fromJson(data) as T;
    }
    if (t == _irayxhn9.ActionMotionSample) {
      return _irayxhn9.ActionMotionSample.fromJson(data) as T;
    }
    if (t == _i6u7fweb.ActionMotionType) {
      return _i6u7fweb.ActionMotionType.fromJson(data) as T;
    }
    if (t == _im1lc214.ActionMovementKind) {
      return _im1lc214.ActionMovementKind.fromJson(data) as T;
    }
    if (t == _im9dc1is.ActionOpportunity) {
      return _im9dc1is.ActionOpportunity.fromJson(data) as T;
    }
    if (t == _ikdqwmpd.ActionQrChallenge) {
      return _ikdqwmpd.ActionQrChallenge.fromJson(data) as T;
    }
    if (t == _ixcs1xdh.ActionQrChallengeCleanupTask) {
      return _ixcs1xdh.ActionQrChallengeCleanupTask.fromJson(data) as T;
    }
    if (t == _iqwh4ycl.ActionQrChallengeView) {
      return _iqwh4ycl.ActionQrChallengeView.fromJson(data) as T;
    }
    if (t == _ii99v1ve.ActionQrRule) {
      return _ii99v1ve.ActionQrRule.fromJson(data) as T;
    }
    if (t == _i45a1wjj.ActionRecurrence) {
      return _i45a1wjj.ActionRecurrence.fromJson(data) as T;
    }
    if (t == _inly21qh.ActionRequirement) {
      return _inly21qh.ActionRequirement.fromJson(data) as T;
    }
    if (t == _ivobne24.ActionRequirementDraft) {
      return _ivobne24.ActionRequirementDraft.fromJson(data) as T;
    }
    if (t == _i55w548r.ActionRequirementKind) {
      return _i55w548r.ActionRequirementKind.fromJson(data) as T;
    }
    if (t == _icsa4634.ActionRequirementView) {
      return _icsa4634.ActionRequirementView.fromJson(data) as T;
    }
    if (t == _i14ro0o5.ActionSpokenChallenge) {
      return _i14ro0o5.ActionSpokenChallenge.fromJson(data) as T;
    }
    if (t == _ifuw4tho.ActionSpokenChallengeCleanupTask) {
      return _ifuw4tho.ActionSpokenChallengeCleanupTask.fromJson(data) as T;
    }
    if (t == _iikyln3l.ActionSpokenChallengeView) {
      return _iikyln3l.ActionSpokenChallengeView.fromJson(data) as T;
    }
    if (t == _i0iphegd.ActionTemplate) {
      return _i0iphegd.ActionTemplate.fromJson(data) as T;
    }
    if (t == _i960u7rl.ActionVerificationPolicy) {
      return _i960u7rl.ActionVerificationPolicy.fromJson(data) as T;
    }
    if (t == _ichxscv5.ActionVisibility) {
      return _ichxscv5.ActionVisibility.fromJson(data) as T;
    }
    if (t == _i5yjywpf.CreateActionDefinitionRequest) {
      return _i5yjywpf.CreateActionDefinitionRequest.fromJson(data) as T;
    }
    if (t == _i9u1614a.EvidenceAppeal) {
      return _i9u1614a.EvidenceAppeal.fromJson(data) as T;
    }
    if (t == _i90o7tud.EvidenceAppealStatus) {
      return _i90o7tud.EvidenceAppealStatus.fromJson(data) as T;
    }
    if (t == _iy27rorb.EvidenceAppealView) {
      return _iy27rorb.EvidenceAppealView.fromJson(data) as T;
    }
    if (t == _ii2t12jt.EvidenceDecision) {
      return _ii2t12jt.EvidenceDecision.fromJson(data) as T;
    }
    if (t == _i5tayeq6.EvidenceDecisionStatus) {
      return _i5tayeq6.EvidenceDecisionStatus.fromJson(data) as T;
    }
    if (t == _i1gh041m.EvidenceProvenanceLevel) {
      return _i1gh041m.EvidenceProvenanceLevel.fromJson(data) as T;
    }
    if (t == _i0mgpur2.EvidenceReviewQueueItem) {
      return _i0mgpur2.EvidenceReviewQueueItem.fromJson(data) as T;
    }
    if (t == _iy0z34jt.EvidenceSubmissionResult) {
      return _iy0z34jt.EvidenceSubmissionResult.fromJson(data) as T;
    }
    if (t == _i5dnc8lk.EvidenceVerificationJob) {
      return _i5dnc8lk.EvidenceVerificationJob.fromJson(data) as T;
    }
    if (t == _i2k44lse.EvidenceVerificationJobStatus) {
      return _i2k44lse.EvidenceVerificationJobStatus.fromJson(data) as T;
    }
    if (t == _il1p2vsk.EvidenceVerificationRecoveryTask) {
      return _il1p2vsk.EvidenceVerificationRecoveryTask.fromJson(data) as T;
    }
    if (t == _in8wt7wh.EvidenceVerificationTask) {
      return _in8wt7wh.EvidenceVerificationTask.fromJson(data) as T;
    }
    if (t == _itcyvpmo.EvidenceVerificationVote) {
      return _itcyvpmo.EvidenceVerificationVote.fromJson(data) as T;
    }
    if (t == _iu3m4umr.ActionLocalCheck) {
      return _iu3m4umr.ActionLocalCheck.fromJson(data) as T;
    }
    if (t == _iarjk3hm.DeviceLocalCheckResult) {
      return _iarjk3hm.DeviceLocalCheckResult.fromJson(data) as T;
    }
    if (t == _iqhexf0c.LocalCheckModelView) {
      return _iqhexf0c.LocalCheckModelView.fromJson(data) as T;
    }
    if (t == _if2a7jyy.LocalCheckTask) {
      return _if2a7jyy.LocalCheckTask.fromJson(data) as T;
    }
    if (t == _i9z86si9.MediaUploadConfirmation) {
      return _i9z86si9.MediaUploadConfirmation.fromJson(data) as T;
    }
    if (t == _itcje0ok.MissingResource) {
      return _itcje0ok.MissingResource.fromJson(data) as T;
    }
    if (t == _i05z8wlg.PayoutReviewView) {
      return _i05z8wlg.PayoutReviewView.fromJson(data) as T;
    }
    if (t == _ihri8lgz.ResourceNotFoundException) {
      return _ihri8lgz.ResourceNotFoundException.fromJson(data) as T;
    }
    if (t == _imnd8hof.AiUsageRequest) {
      return _imnd8hof.AiUsageRequest.fromJson(data) as T;
    }
    if (t == _ij8e0uwy.AiUsageStatus) {
      return _ij8e0uwy.AiUsageStatus.fromJson(data) as T;
    }
    if (t == _i00uumzo.ActionExternalRule) {
      return _i00uumzo.ActionExternalRule.fromJson(data) as T;
    }
    if (t == _iix86y46.AppConfirmation) {
      return _iix86y46.AppConfirmation.fromJson(data) as T;
    }
    if (t == _ix5pwyym.AppConfirmationOutcome) {
      return _ix5pwyym.AppConfirmationOutcome.fromJson(data) as T;
    }
    if (t == _iqtml4wq.AppConfirmationView) {
      return _iqtml4wq.AppConfirmationView.fromJson(data) as T;
    }
    if (t == _iwa6gvjs.AppPlatformException) {
      return _iwa6gvjs.AppPlatformException.fromJson(data) as T;
    }
    if (t == _if20wdmx.AppPlatformProblem) {
      return _if20wdmx.AppPlatformProblem.fromJson(data) as T;
    }
    if (t == _iem3wxny.AppPullCheck) {
      return _iem3wxny.AppPullCheck.fromJson(data) as T;
    }
    if (t == _inaep7ed.AppPullCheckRecoveryTask) {
      return _inaep7ed.AppPullCheckRecoveryTask.fromJson(data) as T;
    }
    if (t == _i3ubh0mc.AppPullCheckStatus) {
      return _i3ubh0mc.AppPullCheckStatus.fromJson(data) as T;
    }
    if (t == _i3j4e45w.AppPullCheckTask) {
      return _i3j4e45w.AppPullCheckTask.fromJson(data) as T;
    }
    if (t == _i3krqelq.AppUnavailableException) {
      return _i3krqelq.AppUnavailableException.fromJson(data) as T;
    }
    if (t == _ijzftij0.AppVerificationMode) {
      return _ijzftij0.AppVerificationMode.fromJson(data) as T;
    }
    if (t == _i36kvzuc.AppLinkCodeCleanupTask) {
      return _i36kvzuc.AppLinkCodeCleanupTask.fromJson(data) as T;
    }
    if (t == _i6s4a256.AppLinkRedirect) {
      return _i6s4a256.AppLinkRedirect.fromJson(data) as T;
    }
    if (t == _ilshz35f.AppLinkRequestView) {
      return _ilshz35f.AppLinkRequestView.fromJson(data) as T;
    }
    if (t == _i6yo3b5n.VerilyAppLinkCode) {
      return _i6yo3b5n.VerilyAppLinkCode.fromJson(data) as T;
    }
    if (t == _in5ng4ea.VerilyApp) {
      return _in5ng4ea.VerilyApp.fromJson(data) as T;
    }
    if (t == _iaui7d4n.VerilyAppCredential) {
      return _iaui7d4n.VerilyAppCredential.fromJson(data) as T;
    }
    if (t == _ibhkb5dt.VerilyAppKey) {
      return _ibhkb5dt.VerilyAppKey.fromJson(data) as T;
    }
    if (t == _ipa8tni0.VerilyAppKeyView) {
      return _ipa8tni0.VerilyAppKeyView.fromJson(data) as T;
    }
    if (t == _ikhive7i.VerilyAppLink) {
      return _ikhive7i.VerilyAppLink.fromJson(data) as T;
    }
    if (t == _ikihia57.VerilyAppLinkView) {
      return _ikihia57.VerilyAppLinkView.fromJson(data) as T;
    }
    if (t == _ie89zcz8.VerilyAppRateWindow) {
      return _ie89zcz8.VerilyAppRateWindow.fromJson(data) as T;
    }
    if (t == _iqs5ny0z.VerilyAppRedirectUri) {
      return _iqs5ny0z.VerilyAppRedirectUri.fromJson(data) as T;
    }
    if (t == _ibal4ihb.VerilyAppStatus) {
      return _ibal4ihb.VerilyAppStatus.fromJson(data) as T;
    }
    if (t == _ifrl0pdw.VerilyAppView) {
      return _ifrl0pdw.VerilyAppView.fromJson(data) as T;
    }
    if (t == _i13rn6uf.AppEvent) {
      return _i13rn6uf.AppEvent.fromJson(data) as T;
    }
    if (t == _ichijhlk.AppEventDeliveryTask) {
      return _ichijhlk.AppEventDeliveryTask.fromJson(data) as T;
    }
    if (t == _igoow6fn.AppEventRecoveryTask) {
      return _igoow6fn.AppEventRecoveryTask.fromJson(data) as T;
    }
    if (t == _io6036x8.AppEventStatus) {
      return _io6036x8.AppEventStatus.fromJson(data) as T;
    }
    if (t == _irpgk99g.AppWebhookDelivery) {
      return _irpgk99g.AppWebhookDelivery.fromJson(data) as T;
    }
    if (t == _ifch1v2s.AppWebhookDeliveryView) {
      return _ifch1v2s.AppWebhookDeliveryView.fromJson(data) as T;
    }
    if (t == _it0ux8yj.VerilyAppWebhookSecret) {
      return _it0ux8yj.VerilyAppWebhookSecret.fromJson(data) as T;
    }
    if (t == _ioo44wgs.EvidenceUploadCleanupTask) {
      return _ioo44wgs.EvidenceUploadCleanupTask.fromJson(data) as T;
    }
    if (t == _is4ltac0.EvidenceUploadReservation) {
      return _is4ltac0.EvidenceUploadReservation.fromJson(data) as T;
    }
    if (t == _iz4zjc1b.EvidenceUploadStatus) {
      return _iz4zjc1b.EvidenceUploadStatus.fromJson(data) as T;
    }
    if (t == _ib7h7gae.InferenceCostReservation) {
      return _ib7h7gae.InferenceCostReservation.fromJson(data) as T;
    }
    if (t == _i6lm2vyc.ModerationAuditEntry) {
      return _i6lm2vyc.ModerationAuditEntry.fromJson(data) as T;
    }
    if (t == _i59xm5p1.ModerationAuditView) {
      return _i59xm5p1.ModerationAuditView.fromJson(data) as T;
    }
    if (t == _ili1rv2x.ModerationCase) {
      return _ili1rv2x.ModerationCase.fromJson(data) as T;
    }
    if (t == _iygcn9wp.ModerationCaseReviewView) {
      return _iygcn9wp.ModerationCaseReviewView.fromJson(data) as T;
    }
    if (t == _i7oivf7f.ModerationCaseStatusView) {
      return _i7oivf7f.ModerationCaseStatusView.fromJson(data) as T;
    }
    if (t == _inzarup3.PayoutWallet) {
      return _inzarup3.PayoutWallet.fromJson(data) as T;
    }
    if (t == _iyph9n2p.PayoutWalletChallengeCleanupTask) {
      return _iyph9n2p.PayoutWalletChallengeCleanupTask.fromJson(data) as T;
    }
    if (t == _i717n6wz.PayoutWalletLinkChallenge) {
      return _i717n6wz.PayoutWalletLinkChallenge.fromJson(data) as T;
    }
    if (t == _icfglt50.PayoutWalletLinkChallengeView) {
      return _icfglt50.PayoutWalletLinkChallengeView.fromJson(data) as T;
    }
    if (t == _iqtp7i2n.PayoutWalletView) {
      return _iqtp7i2n.PayoutWalletView.fromJson(data) as T;
    }
    if (t == _i3rw9wf5.RewardCluster) {
      return _i3rw9wf5.RewardCluster.fromJson(data) as T;
    }
    if (t == _ilrvghyo.RewardEndPlan) {
      return _ilrvghyo.RewardEndPlan.fromJson(data) as T;
    }
    if (t == _in6hek74.RewardException) {
      return _in6hek74.RewardException.fromJson(data) as T;
    }
    if (t == _iyf1v3jl.RewardFundingPlan) {
      return _iyf1v3jl.RewardFundingPlan.fromJson(data) as T;
    }
    if (t == _iv4eta4e.RewardOutcome) {
      return _iv4eta4e.RewardOutcome.fromJson(data) as T;
    }
    if (t == _i09j9cr3.RewardPayout) {
      return _i09j9cr3.RewardPayout.fromJson(data) as T;
    }
    if (t == _i3dio64d.RewardPayoutRecoveryTask) {
      return _i3dio64d.RewardPayoutRecoveryTask.fromJson(data) as T;
    }
    if (t == _idfqmhge.RewardPayoutStatus) {
      return _idfqmhge.RewardPayoutStatus.fromJson(data) as T;
    }
    if (t == _isxaon27.RewardPayoutTask) {
      return _isxaon27.RewardPayoutTask.fromJson(data) as T;
    }
    if (t == _ieggihqi.RewardPayoutView) {
      return _ieggihqi.RewardPayoutView.fromJson(data) as T;
    }
    if (t == _i5k7uglj.RewardPool) {
      return _i5k7uglj.RewardPool.fromJson(data) as T;
    }
    if (t == _iv8dpf52.RewardPoolStatus) {
      return _iv8dpf52.RewardPoolStatus.fromJson(data) as T;
    }
    if (t == _if6e3cxh.RewardPoolView) {
      return _if6e3cxh.RewardPoolView.fromJson(data) as T;
    }
    if (t == _i4sm4ipz.RewardProblem) {
      return _i4sm4ipz.RewardProblem.fromJson(data) as T;
    }
    if (t == _i9b5h2nk.RewardSummary) {
      return _i9b5h2nk.RewardSummary.fromJson(data) as T;
    }
    if (t == _iokaii94.RewardTermsDraft) {
      return _iokaii94.RewardTermsDraft.fromJson(data) as T;
    }
    if (t == _i3qq4r4i.VerificationRequest) {
      return _i3qq4r4i.VerificationRequest.fromJson(data) as T;
    }
    if (t == _ig30b0kc.VerificationRequestCheck) {
      return _ig30b0kc.VerificationRequestCheck.fromJson(data) as T;
    }
    if (t == _igwxgobn.VerificationRequestExpiryTask) {
      return _igwxgobn.VerificationRequestExpiryTask.fromJson(data) as T;
    }
    if (t == _ij8vmgkg.VerificationRequestKind) {
      return _ij8vmgkg.VerificationRequestKind.fromJson(data) as T;
    }
    if (t == _ik3wnzle.VerificationRequestRedirect) {
      return _ik3wnzle.VerificationRequestRedirect.fromJson(data) as T;
    }
    if (t == _in2jgiwv.VerificationRequestStatus) {
      return _in2jgiwv.VerificationRequestStatus.fromJson(data) as T;
    }
    if (t == _i3v95178.VerificationRequestView) {
      return _i3v95178.VerificationRequestView.fromJson(data) as T;
    }
    if (t == _is.getType<_ifpimmza.AbuseRiskAssessment?>()) {
      return (data != null
              ? _ifpimmza.AbuseRiskAssessment.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_if4812wc.AccountClosure?>()) {
      return (data != null ? _if4812wc.AccountClosure.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i7zadist.AccountClosureStatus?>()) {
      return (data != null
              ? _i7zadist.AccountClosureStatus.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_igwrfg7c.ActionAttempt?>()) {
      return (data != null ? _igwrfg7c.ActionAttempt.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iu22l7ek.ActionAttemptStatus?>()) {
      return (data != null
              ? _iu22l7ek.ActionAttemptStatus.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ixgg3yqh.ActionAttemptView?>()) {
      return (data != null ? _ixgg3yqh.ActionAttemptView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i8z355ak.ActionAuthoringException?>()) {
      return (data != null
              ? _i8z355ak.ActionAuthoringException.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ifi47ne5.ActionAuthoringProblem?>()) {
      return (data != null
              ? _ifi47ne5.ActionAuthoringProblem.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_irhbzkbi.ActionCaptureChallenge?>()) {
      return (data != null
              ? _irhbzkbi.ActionCaptureChallenge.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_idx11lej.ActionCaptureChallengeCleanupTask?>()) {
      return (data != null
              ? _idx11lej.ActionCaptureChallengeCleanupTask.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i55m67tr.ActionCaptureChallengeView?>()) {
      return (data != null
              ? _i55m67tr.ActionCaptureChallengeView.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ip3p3cwa.ActionDefinition?>()) {
      return (data != null ? _ip3p3cwa.ActionDefinition.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_igizisql.ActionDefinitionStatus?>()) {
      return (data != null
              ? _igizisql.ActionDefinitionStatus.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iqti045q.ActionDraftProposal?>()) {
      return (data != null
              ? _iqti045q.ActionDraftProposal.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ism88bqz.ActionDraftingUnavailableException?>()) {
      return (data != null
              ? _ism88bqz.ActionDraftingUnavailableException.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ikmbmeqc.ActionEvidence?>()) {
      return (data != null ? _ikmbmeqc.ActionEvidence.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iq3mdjhk.ActionEvidenceInput?>()) {
      return (data != null
              ? _iq3mdjhk.ActionEvidenceInput.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iz39t19t.ActionLocationRule?>()) {
      return (data != null ? _iz39t19t.ActionLocationRule.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iw9if8ju.ActionMediaRule?>()) {
      return (data != null ? _iw9if8ju.ActionMediaRule.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i5b1uunc.ActionMotionAxis?>()) {
      return (data != null ? _i5b1uunc.ActionMotionAxis.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ih8siueq.ActionMotionRule?>()) {
      return (data != null ? _ih8siueq.ActionMotionRule.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_irayxhn9.ActionMotionSample?>()) {
      return (data != null ? _irayxhn9.ActionMotionSample.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i6u7fweb.ActionMotionType?>()) {
      return (data != null ? _i6u7fweb.ActionMotionType.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_im1lc214.ActionMovementKind?>()) {
      return (data != null ? _im1lc214.ActionMovementKind.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_im9dc1is.ActionOpportunity?>()) {
      return (data != null ? _im9dc1is.ActionOpportunity.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ikdqwmpd.ActionQrChallenge?>()) {
      return (data != null ? _ikdqwmpd.ActionQrChallenge.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ixcs1xdh.ActionQrChallengeCleanupTask?>()) {
      return (data != null
              ? _ixcs1xdh.ActionQrChallengeCleanupTask.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iqwh4ycl.ActionQrChallengeView?>()) {
      return (data != null
              ? _iqwh4ycl.ActionQrChallengeView.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ii99v1ve.ActionQrRule?>()) {
      return (data != null ? _ii99v1ve.ActionQrRule.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i45a1wjj.ActionRecurrence?>()) {
      return (data != null ? _i45a1wjj.ActionRecurrence.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_inly21qh.ActionRequirement?>()) {
      return (data != null ? _inly21qh.ActionRequirement.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ivobne24.ActionRequirementDraft?>()) {
      return (data != null
              ? _ivobne24.ActionRequirementDraft.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i55w548r.ActionRequirementKind?>()) {
      return (data != null
              ? _i55w548r.ActionRequirementKind.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_icsa4634.ActionRequirementView?>()) {
      return (data != null
              ? _icsa4634.ActionRequirementView.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i14ro0o5.ActionSpokenChallenge?>()) {
      return (data != null
              ? _i14ro0o5.ActionSpokenChallenge.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ifuw4tho.ActionSpokenChallengeCleanupTask?>()) {
      return (data != null
              ? _ifuw4tho.ActionSpokenChallengeCleanupTask.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iikyln3l.ActionSpokenChallengeView?>()) {
      return (data != null
              ? _iikyln3l.ActionSpokenChallengeView.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i0iphegd.ActionTemplate?>()) {
      return (data != null ? _i0iphegd.ActionTemplate.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i960u7rl.ActionVerificationPolicy?>()) {
      return (data != null
              ? _i960u7rl.ActionVerificationPolicy.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ichxscv5.ActionVisibility?>()) {
      return (data != null ? _ichxscv5.ActionVisibility.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i5yjywpf.CreateActionDefinitionRequest?>()) {
      return (data != null
              ? _i5yjywpf.CreateActionDefinitionRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i9u1614a.EvidenceAppeal?>()) {
      return (data != null ? _i9u1614a.EvidenceAppeal.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i90o7tud.EvidenceAppealStatus?>()) {
      return (data != null
              ? _i90o7tud.EvidenceAppealStatus.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iy27rorb.EvidenceAppealView?>()) {
      return (data != null ? _iy27rorb.EvidenceAppealView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ii2t12jt.EvidenceDecision?>()) {
      return (data != null ? _ii2t12jt.EvidenceDecision.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i5tayeq6.EvidenceDecisionStatus?>()) {
      return (data != null
              ? _i5tayeq6.EvidenceDecisionStatus.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i1gh041m.EvidenceProvenanceLevel?>()) {
      return (data != null
              ? _i1gh041m.EvidenceProvenanceLevel.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i0mgpur2.EvidenceReviewQueueItem?>()) {
      return (data != null
              ? _i0mgpur2.EvidenceReviewQueueItem.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iy0z34jt.EvidenceSubmissionResult?>()) {
      return (data != null
              ? _iy0z34jt.EvidenceSubmissionResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i5dnc8lk.EvidenceVerificationJob?>()) {
      return (data != null
              ? _i5dnc8lk.EvidenceVerificationJob.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i2k44lse.EvidenceVerificationJobStatus?>()) {
      return (data != null
              ? _i2k44lse.EvidenceVerificationJobStatus.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_il1p2vsk.EvidenceVerificationRecoveryTask?>()) {
      return (data != null
              ? _il1p2vsk.EvidenceVerificationRecoveryTask.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_in8wt7wh.EvidenceVerificationTask?>()) {
      return (data != null
              ? _in8wt7wh.EvidenceVerificationTask.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_itcyvpmo.EvidenceVerificationVote?>()) {
      return (data != null
              ? _itcyvpmo.EvidenceVerificationVote.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iu3m4umr.ActionLocalCheck?>()) {
      return (data != null ? _iu3m4umr.ActionLocalCheck.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iarjk3hm.DeviceLocalCheckResult?>()) {
      return (data != null
              ? _iarjk3hm.DeviceLocalCheckResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iqhexf0c.LocalCheckModelView?>()) {
      return (data != null
              ? _iqhexf0c.LocalCheckModelView.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_if2a7jyy.LocalCheckTask?>()) {
      return (data != null ? _if2a7jyy.LocalCheckTask.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i9z86si9.MediaUploadConfirmation?>()) {
      return (data != null
              ? _i9z86si9.MediaUploadConfirmation.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_itcje0ok.MissingResource?>()) {
      return (data != null ? _itcje0ok.MissingResource.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i05z8wlg.PayoutReviewView?>()) {
      return (data != null ? _i05z8wlg.PayoutReviewView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ihri8lgz.ResourceNotFoundException?>()) {
      return (data != null
              ? _ihri8lgz.ResourceNotFoundException.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_imnd8hof.AiUsageRequest?>()) {
      return (data != null ? _imnd8hof.AiUsageRequest.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ij8e0uwy.AiUsageStatus?>()) {
      return (data != null ? _ij8e0uwy.AiUsageStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i00uumzo.ActionExternalRule?>()) {
      return (data != null ? _i00uumzo.ActionExternalRule.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iix86y46.AppConfirmation?>()) {
      return (data != null ? _iix86y46.AppConfirmation.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ix5pwyym.AppConfirmationOutcome?>()) {
      return (data != null
              ? _ix5pwyym.AppConfirmationOutcome.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iqtml4wq.AppConfirmationView?>()) {
      return (data != null
              ? _iqtml4wq.AppConfirmationView.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iwa6gvjs.AppPlatformException?>()) {
      return (data != null
              ? _iwa6gvjs.AppPlatformException.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_if20wdmx.AppPlatformProblem?>()) {
      return (data != null ? _if20wdmx.AppPlatformProblem.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iem3wxny.AppPullCheck?>()) {
      return (data != null ? _iem3wxny.AppPullCheck.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_inaep7ed.AppPullCheckRecoveryTask?>()) {
      return (data != null
              ? _inaep7ed.AppPullCheckRecoveryTask.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i3ubh0mc.AppPullCheckStatus?>()) {
      return (data != null ? _i3ubh0mc.AppPullCheckStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i3j4e45w.AppPullCheckTask?>()) {
      return (data != null ? _i3j4e45w.AppPullCheckTask.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i3krqelq.AppUnavailableException?>()) {
      return (data != null
              ? _i3krqelq.AppUnavailableException.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ijzftij0.AppVerificationMode?>()) {
      return (data != null
              ? _ijzftij0.AppVerificationMode.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i36kvzuc.AppLinkCodeCleanupTask?>()) {
      return (data != null
              ? _i36kvzuc.AppLinkCodeCleanupTask.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i6s4a256.AppLinkRedirect?>()) {
      return (data != null ? _i6s4a256.AppLinkRedirect.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ilshz35f.AppLinkRequestView?>()) {
      return (data != null ? _ilshz35f.AppLinkRequestView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i6yo3b5n.VerilyAppLinkCode?>()) {
      return (data != null ? _i6yo3b5n.VerilyAppLinkCode.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_in5ng4ea.VerilyApp?>()) {
      return (data != null ? _in5ng4ea.VerilyApp.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iaui7d4n.VerilyAppCredential?>()) {
      return (data != null
              ? _iaui7d4n.VerilyAppCredential.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ibhkb5dt.VerilyAppKey?>()) {
      return (data != null ? _ibhkb5dt.VerilyAppKey.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ipa8tni0.VerilyAppKeyView?>()) {
      return (data != null ? _ipa8tni0.VerilyAppKeyView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ikhive7i.VerilyAppLink?>()) {
      return (data != null ? _ikhive7i.VerilyAppLink.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ikihia57.VerilyAppLinkView?>()) {
      return (data != null ? _ikihia57.VerilyAppLinkView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ie89zcz8.VerilyAppRateWindow?>()) {
      return (data != null
              ? _ie89zcz8.VerilyAppRateWindow.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iqs5ny0z.VerilyAppRedirectUri?>()) {
      return (data != null
              ? _iqs5ny0z.VerilyAppRedirectUri.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ibal4ihb.VerilyAppStatus?>()) {
      return (data != null ? _ibal4ihb.VerilyAppStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ifrl0pdw.VerilyAppView?>()) {
      return (data != null ? _ifrl0pdw.VerilyAppView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i13rn6uf.AppEvent?>()) {
      return (data != null ? _i13rn6uf.AppEvent.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ichijhlk.AppEventDeliveryTask?>()) {
      return (data != null
              ? _ichijhlk.AppEventDeliveryTask.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_igoow6fn.AppEventRecoveryTask?>()) {
      return (data != null
              ? _igoow6fn.AppEventRecoveryTask.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_io6036x8.AppEventStatus?>()) {
      return (data != null ? _io6036x8.AppEventStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_irpgk99g.AppWebhookDelivery?>()) {
      return (data != null ? _irpgk99g.AppWebhookDelivery.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ifch1v2s.AppWebhookDeliveryView?>()) {
      return (data != null
              ? _ifch1v2s.AppWebhookDeliveryView.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_it0ux8yj.VerilyAppWebhookSecret?>()) {
      return (data != null
              ? _it0ux8yj.VerilyAppWebhookSecret.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ioo44wgs.EvidenceUploadCleanupTask?>()) {
      return (data != null
              ? _ioo44wgs.EvidenceUploadCleanupTask.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_is4ltac0.EvidenceUploadReservation?>()) {
      return (data != null
              ? _is4ltac0.EvidenceUploadReservation.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iz4zjc1b.EvidenceUploadStatus?>()) {
      return (data != null
              ? _iz4zjc1b.EvidenceUploadStatus.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ib7h7gae.InferenceCostReservation?>()) {
      return (data != null
              ? _ib7h7gae.InferenceCostReservation.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i6lm2vyc.ModerationAuditEntry?>()) {
      return (data != null
              ? _i6lm2vyc.ModerationAuditEntry.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i59xm5p1.ModerationAuditView?>()) {
      return (data != null
              ? _i59xm5p1.ModerationAuditView.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ili1rv2x.ModerationCase?>()) {
      return (data != null ? _ili1rv2x.ModerationCase.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iygcn9wp.ModerationCaseReviewView?>()) {
      return (data != null
              ? _iygcn9wp.ModerationCaseReviewView.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i7oivf7f.ModerationCaseStatusView?>()) {
      return (data != null
              ? _i7oivf7f.ModerationCaseStatusView.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_inzarup3.PayoutWallet?>()) {
      return (data != null ? _inzarup3.PayoutWallet.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iyph9n2p.PayoutWalletChallengeCleanupTask?>()) {
      return (data != null
              ? _iyph9n2p.PayoutWalletChallengeCleanupTask.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i717n6wz.PayoutWalletLinkChallenge?>()) {
      return (data != null
              ? _i717n6wz.PayoutWalletLinkChallenge.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_icfglt50.PayoutWalletLinkChallengeView?>()) {
      return (data != null
              ? _icfglt50.PayoutWalletLinkChallengeView.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iqtp7i2n.PayoutWalletView?>()) {
      return (data != null ? _iqtp7i2n.PayoutWalletView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i3rw9wf5.RewardCluster?>()) {
      return (data != null ? _i3rw9wf5.RewardCluster.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ilrvghyo.RewardEndPlan?>()) {
      return (data != null ? _ilrvghyo.RewardEndPlan.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_in6hek74.RewardException?>()) {
      return (data != null ? _in6hek74.RewardException.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iyf1v3jl.RewardFundingPlan?>()) {
      return (data != null ? _iyf1v3jl.RewardFundingPlan.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iv4eta4e.RewardOutcome?>()) {
      return (data != null ? _iv4eta4e.RewardOutcome.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i09j9cr3.RewardPayout?>()) {
      return (data != null ? _i09j9cr3.RewardPayout.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i3dio64d.RewardPayoutRecoveryTask?>()) {
      return (data != null
              ? _i3dio64d.RewardPayoutRecoveryTask.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_idfqmhge.RewardPayoutStatus?>()) {
      return (data != null ? _idfqmhge.RewardPayoutStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_isxaon27.RewardPayoutTask?>()) {
      return (data != null ? _isxaon27.RewardPayoutTask.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ieggihqi.RewardPayoutView?>()) {
      return (data != null ? _ieggihqi.RewardPayoutView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i5k7uglj.RewardPool?>()) {
      return (data != null ? _i5k7uglj.RewardPool.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iv8dpf52.RewardPoolStatus?>()) {
      return (data != null ? _iv8dpf52.RewardPoolStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_if6e3cxh.RewardPoolView?>()) {
      return (data != null ? _if6e3cxh.RewardPoolView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i4sm4ipz.RewardProblem?>()) {
      return (data != null ? _i4sm4ipz.RewardProblem.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i9b5h2nk.RewardSummary?>()) {
      return (data != null ? _i9b5h2nk.RewardSummary.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iokaii94.RewardTermsDraft?>()) {
      return (data != null ? _iokaii94.RewardTermsDraft.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i3qq4r4i.VerificationRequest?>()) {
      return (data != null
              ? _i3qq4r4i.VerificationRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ig30b0kc.VerificationRequestCheck?>()) {
      return (data != null
              ? _ig30b0kc.VerificationRequestCheck.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_igwxgobn.VerificationRequestExpiryTask?>()) {
      return (data != null
              ? _igwxgobn.VerificationRequestExpiryTask.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ij8vmgkg.VerificationRequestKind?>()) {
      return (data != null
              ? _ij8vmgkg.VerificationRequestKind.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ik3wnzle.VerificationRequestRedirect?>()) {
      return (data != null
              ? _ik3wnzle.VerificationRequestRedirect.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_in2jgiwv.VerificationRequestStatus?>()) {
      return (data != null
              ? _in2jgiwv.VerificationRequestStatus.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i3v95178.VerificationRequestView?>()) {
      return (data != null
              ? _i3v95178.VerificationRequestView.fromJson(data)
              : null)
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_is.UuidValue>) {
      return (data as List).map((e) => deserialize<_is.UuidValue>(e)).toList()
          as T;
    }
    if (t == _is.getType<List<_is.UuidValue>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_is.UuidValue>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == _is.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_irayxhn9.ActionMotionSample>) {
      return (data as List)
              .map((e) => deserialize<_irayxhn9.ActionMotionSample>(e))
              .toList()
          as T;
    }
    if (t == _is.getType<List<_irayxhn9.ActionMotionSample>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_irayxhn9.ActionMotionSample>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_icsa4634.ActionRequirementView>) {
      return (data as List)
              .map((e) => deserialize<_icsa4634.ActionRequirementView>(e))
              .toList()
          as T;
    }
    if (t == List<_ivobne24.ActionRequirementDraft>) {
      return (data as List)
              .map((e) => deserialize<_ivobne24.ActionRequirementDraft>(e))
              .toList()
          as T;
    }
    if (t == List<_ipa8tni0.VerilyAppKeyView>) {
      return (data as List)
              .map((e) => deserialize<_ipa8tni0.VerilyAppKeyView>(e))
              .toList()
          as T;
    }
    if (t == List<_i59xm5p1.ModerationAuditView>) {
      return (data as List)
              .map((e) => deserialize<_i59xm5p1.ModerationAuditView>(e))
              .toList()
          as T;
    }
    if (t == List<_icxixoim.ActionTemplate>) {
      return (data as List)
              .map((e) => deserialize<_icxixoim.ActionTemplate>(e))
              .toList()
          as T;
    }
    if (t == List<_iryxm23q.ActionOpportunity>) {
      return (data as List)
              .map((e) => deserialize<_iryxm23q.ActionOpportunity>(e))
              .toList()
          as T;
    }
    if (t == List<_iyvinv8z.ActionAttemptView>) {
      return (data as List)
              .map((e) => deserialize<_iyvinv8z.ActionAttemptView>(e))
              .toList()
          as T;
    }
    if (t == List<_igl29vg6.EvidenceAppealView>) {
      return (data as List)
              .map((e) => deserialize<_igl29vg6.EvidenceAppealView>(e))
              .toList()
          as T;
    }
    if (t == List<_ioe3uq94.EvidenceReviewQueueItem>) {
      return (data as List)
              .map((e) => deserialize<_ioe3uq94.EvidenceReviewQueueItem>(e))
              .toList()
          as T;
    }
    if (t == List<_i4dty38s.VerilyAppView>) {
      return (data as List)
              .map((e) => deserialize<_i4dty38s.VerilyAppView>(e))
              .toList()
          as T;
    }
    if (t == List<_i8j33595.AppConfirmationView>) {
      return (data as List)
              .map((e) => deserialize<_i8j33595.AppConfirmationView>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i1cq8y15.AppWebhookDeliveryView>) {
      return (data as List)
              .map((e) => deserialize<_i1cq8y15.AppWebhookDeliveryView>(e))
              .toList()
          as T;
    }
    if (t == List<_ikb2aklq.ModerationCaseStatusView>) {
      return (data as List)
              .map((e) => deserialize<_ikb2aklq.ModerationCaseStatusView>(e))
              .toList()
          as T;
    }
    if (t == List<_ijh2di3d.RewardPayoutView>) {
      return (data as List)
              .map((e) => deserialize<_ijh2di3d.RewardPayoutView>(e))
              .toList()
          as T;
    }
    try {
      return _iacs.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _iais.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _isp.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _ifpimmza.AbuseRiskAssessment => 'AbuseRiskAssessment',
      _if4812wc.AccountClosure => 'AccountClosure',
      _i7zadist.AccountClosureStatus => 'AccountClosureStatus',
      _igwrfg7c.ActionAttempt => 'ActionAttempt',
      _iu22l7ek.ActionAttemptStatus => 'ActionAttemptStatus',
      _ixgg3yqh.ActionAttemptView => 'ActionAttemptView',
      _i8z355ak.ActionAuthoringException => 'ActionAuthoringException',
      _ifi47ne5.ActionAuthoringProblem => 'ActionAuthoringProblem',
      _irhbzkbi.ActionCaptureChallenge => 'ActionCaptureChallenge',
      _idx11lej.ActionCaptureChallengeCleanupTask =>
        'ActionCaptureChallengeCleanupTask',
      _i55m67tr.ActionCaptureChallengeView => 'ActionCaptureChallengeView',
      _ip3p3cwa.ActionDefinition => 'ActionDefinition',
      _igizisql.ActionDefinitionStatus => 'ActionDefinitionStatus',
      _iqti045q.ActionDraftProposal => 'ActionDraftProposal',
      _ism88bqz.ActionDraftingUnavailableException =>
        'ActionDraftingUnavailableException',
      _ikmbmeqc.ActionEvidence => 'ActionEvidence',
      _iq3mdjhk.ActionEvidenceInput => 'ActionEvidenceInput',
      _iz39t19t.ActionLocationRule => 'ActionLocationRule',
      _iw9if8ju.ActionMediaRule => 'ActionMediaRule',
      _i5b1uunc.ActionMotionAxis => 'ActionMotionAxis',
      _ih8siueq.ActionMotionRule => 'ActionMotionRule',
      _irayxhn9.ActionMotionSample => 'ActionMotionSample',
      _i6u7fweb.ActionMotionType => 'ActionMotionType',
      _im1lc214.ActionMovementKind => 'ActionMovementKind',
      _im9dc1is.ActionOpportunity => 'ActionOpportunity',
      _ikdqwmpd.ActionQrChallenge => 'ActionQrChallenge',
      _ixcs1xdh.ActionQrChallengeCleanupTask => 'ActionQrChallengeCleanupTask',
      _iqwh4ycl.ActionQrChallengeView => 'ActionQrChallengeView',
      _ii99v1ve.ActionQrRule => 'ActionQrRule',
      _i45a1wjj.ActionRecurrence => 'ActionRecurrence',
      _inly21qh.ActionRequirement => 'ActionRequirement',
      _ivobne24.ActionRequirementDraft => 'ActionRequirementDraft',
      _i55w548r.ActionRequirementKind => 'ActionRequirementKind',
      _icsa4634.ActionRequirementView => 'ActionRequirementView',
      _i14ro0o5.ActionSpokenChallenge => 'ActionSpokenChallenge',
      _ifuw4tho.ActionSpokenChallengeCleanupTask =>
        'ActionSpokenChallengeCleanupTask',
      _iikyln3l.ActionSpokenChallengeView => 'ActionSpokenChallengeView',
      _i0iphegd.ActionTemplate => 'ActionTemplate',
      _i960u7rl.ActionVerificationPolicy => 'ActionVerificationPolicy',
      _ichxscv5.ActionVisibility => 'ActionVisibility',
      _i5yjywpf.CreateActionDefinitionRequest =>
        'CreateActionDefinitionRequest',
      _i9u1614a.EvidenceAppeal => 'EvidenceAppeal',
      _i90o7tud.EvidenceAppealStatus => 'EvidenceAppealStatus',
      _iy27rorb.EvidenceAppealView => 'EvidenceAppealView',
      _ii2t12jt.EvidenceDecision => 'EvidenceDecision',
      _i5tayeq6.EvidenceDecisionStatus => 'EvidenceDecisionStatus',
      _i1gh041m.EvidenceProvenanceLevel => 'EvidenceProvenanceLevel',
      _i0mgpur2.EvidenceReviewQueueItem => 'EvidenceReviewQueueItem',
      _iy0z34jt.EvidenceSubmissionResult => 'EvidenceSubmissionResult',
      _i5dnc8lk.EvidenceVerificationJob => 'EvidenceVerificationJob',
      _i2k44lse.EvidenceVerificationJobStatus =>
        'EvidenceVerificationJobStatus',
      _il1p2vsk.EvidenceVerificationRecoveryTask =>
        'EvidenceVerificationRecoveryTask',
      _in8wt7wh.EvidenceVerificationTask => 'EvidenceVerificationTask',
      _itcyvpmo.EvidenceVerificationVote => 'EvidenceVerificationVote',
      _iu3m4umr.ActionLocalCheck => 'ActionLocalCheck',
      _iarjk3hm.DeviceLocalCheckResult => 'DeviceLocalCheckResult',
      _iqhexf0c.LocalCheckModelView => 'LocalCheckModelView',
      _if2a7jyy.LocalCheckTask => 'LocalCheckTask',
      _i9z86si9.MediaUploadConfirmation => 'MediaUploadConfirmation',
      _itcje0ok.MissingResource => 'MissingResource',
      _i05z8wlg.PayoutReviewView => 'PayoutReviewView',
      _ihri8lgz.ResourceNotFoundException => 'ResourceNotFoundException',
      _imnd8hof.AiUsageRequest => 'AiUsageRequest',
      _ij8e0uwy.AiUsageStatus => 'AiUsageStatus',
      _i00uumzo.ActionExternalRule => 'ActionExternalRule',
      _iix86y46.AppConfirmation => 'AppConfirmation',
      _ix5pwyym.AppConfirmationOutcome => 'AppConfirmationOutcome',
      _iqtml4wq.AppConfirmationView => 'AppConfirmationView',
      _iwa6gvjs.AppPlatformException => 'AppPlatformException',
      _if20wdmx.AppPlatformProblem => 'AppPlatformProblem',
      _iem3wxny.AppPullCheck => 'AppPullCheck',
      _inaep7ed.AppPullCheckRecoveryTask => 'AppPullCheckRecoveryTask',
      _i3ubh0mc.AppPullCheckStatus => 'AppPullCheckStatus',
      _i3j4e45w.AppPullCheckTask => 'AppPullCheckTask',
      _i3krqelq.AppUnavailableException => 'AppUnavailableException',
      _ijzftij0.AppVerificationMode => 'AppVerificationMode',
      _i36kvzuc.AppLinkCodeCleanupTask => 'AppLinkCodeCleanupTask',
      _i6s4a256.AppLinkRedirect => 'AppLinkRedirect',
      _ilshz35f.AppLinkRequestView => 'AppLinkRequestView',
      _i6yo3b5n.VerilyAppLinkCode => 'VerilyAppLinkCode',
      _in5ng4ea.VerilyApp => 'VerilyApp',
      _iaui7d4n.VerilyAppCredential => 'VerilyAppCredential',
      _ibhkb5dt.VerilyAppKey => 'VerilyAppKey',
      _ipa8tni0.VerilyAppKeyView => 'VerilyAppKeyView',
      _ikhive7i.VerilyAppLink => 'VerilyAppLink',
      _ikihia57.VerilyAppLinkView => 'VerilyAppLinkView',
      _ie89zcz8.VerilyAppRateWindow => 'VerilyAppRateWindow',
      _iqs5ny0z.VerilyAppRedirectUri => 'VerilyAppRedirectUri',
      _ibal4ihb.VerilyAppStatus => 'VerilyAppStatus',
      _ifrl0pdw.VerilyAppView => 'VerilyAppView',
      _i13rn6uf.AppEvent => 'AppEvent',
      _ichijhlk.AppEventDeliveryTask => 'AppEventDeliveryTask',
      _igoow6fn.AppEventRecoveryTask => 'AppEventRecoveryTask',
      _io6036x8.AppEventStatus => 'AppEventStatus',
      _irpgk99g.AppWebhookDelivery => 'AppWebhookDelivery',
      _ifch1v2s.AppWebhookDeliveryView => 'AppWebhookDeliveryView',
      _it0ux8yj.VerilyAppWebhookSecret => 'VerilyAppWebhookSecret',
      _ioo44wgs.EvidenceUploadCleanupTask => 'EvidenceUploadCleanupTask',
      _is4ltac0.EvidenceUploadReservation => 'EvidenceUploadReservation',
      _iz4zjc1b.EvidenceUploadStatus => 'EvidenceUploadStatus',
      _ib7h7gae.InferenceCostReservation => 'InferenceCostReservation',
      _i6lm2vyc.ModerationAuditEntry => 'ModerationAuditEntry',
      _i59xm5p1.ModerationAuditView => 'ModerationAuditView',
      _ili1rv2x.ModerationCase => 'ModerationCase',
      _iygcn9wp.ModerationCaseReviewView => 'ModerationCaseReviewView',
      _i7oivf7f.ModerationCaseStatusView => 'ModerationCaseStatusView',
      _inzarup3.PayoutWallet => 'PayoutWallet',
      _iyph9n2p.PayoutWalletChallengeCleanupTask =>
        'PayoutWalletChallengeCleanupTask',
      _i717n6wz.PayoutWalletLinkChallenge => 'PayoutWalletLinkChallenge',
      _icfglt50.PayoutWalletLinkChallengeView =>
        'PayoutWalletLinkChallengeView',
      _iqtp7i2n.PayoutWalletView => 'PayoutWalletView',
      _i3rw9wf5.RewardCluster => 'RewardCluster',
      _ilrvghyo.RewardEndPlan => 'RewardEndPlan',
      _in6hek74.RewardException => 'RewardException',
      _iyf1v3jl.RewardFundingPlan => 'RewardFundingPlan',
      _iv4eta4e.RewardOutcome => 'RewardOutcome',
      _i09j9cr3.RewardPayout => 'RewardPayout',
      _i3dio64d.RewardPayoutRecoveryTask => 'RewardPayoutRecoveryTask',
      _idfqmhge.RewardPayoutStatus => 'RewardPayoutStatus',
      _isxaon27.RewardPayoutTask => 'RewardPayoutTask',
      _ieggihqi.RewardPayoutView => 'RewardPayoutView',
      _i5k7uglj.RewardPool => 'RewardPool',
      _iv8dpf52.RewardPoolStatus => 'RewardPoolStatus',
      _if6e3cxh.RewardPoolView => 'RewardPoolView',
      _i4sm4ipz.RewardProblem => 'RewardProblem',
      _i9b5h2nk.RewardSummary => 'RewardSummary',
      _iokaii94.RewardTermsDraft => 'RewardTermsDraft',
      _i3qq4r4i.VerificationRequest => 'VerificationRequest',
      _ig30b0kc.VerificationRequestCheck => 'VerificationRequestCheck',
      _igwxgobn.VerificationRequestExpiryTask =>
        'VerificationRequestExpiryTask',
      _ij8vmgkg.VerificationRequestKind => 'VerificationRequestKind',
      _ik3wnzle.VerificationRequestRedirect => 'VerificationRequestRedirect',
      _in2jgiwv.VerificationRequestStatus => 'VerificationRequestStatus',
      _i3v95178.VerificationRequestView => 'VerificationRequestView',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('verily.', '');
    }

    switch (data) {
      case _ifpimmza.AbuseRiskAssessment():
        return 'AbuseRiskAssessment';
      case _if4812wc.AccountClosure():
        return 'AccountClosure';
      case _i7zadist.AccountClosureStatus():
        return 'AccountClosureStatus';
      case _igwrfg7c.ActionAttempt():
        return 'ActionAttempt';
      case _iu22l7ek.ActionAttemptStatus():
        return 'ActionAttemptStatus';
      case _ixgg3yqh.ActionAttemptView():
        return 'ActionAttemptView';
      case _i8z355ak.ActionAuthoringException():
        return 'ActionAuthoringException';
      case _ifi47ne5.ActionAuthoringProblem():
        return 'ActionAuthoringProblem';
      case _irhbzkbi.ActionCaptureChallenge():
        return 'ActionCaptureChallenge';
      case _idx11lej.ActionCaptureChallengeCleanupTask():
        return 'ActionCaptureChallengeCleanupTask';
      case _i55m67tr.ActionCaptureChallengeView():
        return 'ActionCaptureChallengeView';
      case _ip3p3cwa.ActionDefinition():
        return 'ActionDefinition';
      case _igizisql.ActionDefinitionStatus():
        return 'ActionDefinitionStatus';
      case _iqti045q.ActionDraftProposal():
        return 'ActionDraftProposal';
      case _ism88bqz.ActionDraftingUnavailableException():
        return 'ActionDraftingUnavailableException';
      case _ikmbmeqc.ActionEvidence():
        return 'ActionEvidence';
      case _iq3mdjhk.ActionEvidenceInput():
        return 'ActionEvidenceInput';
      case _iz39t19t.ActionLocationRule():
        return 'ActionLocationRule';
      case _iw9if8ju.ActionMediaRule():
        return 'ActionMediaRule';
      case _i5b1uunc.ActionMotionAxis():
        return 'ActionMotionAxis';
      case _ih8siueq.ActionMotionRule():
        return 'ActionMotionRule';
      case _irayxhn9.ActionMotionSample():
        return 'ActionMotionSample';
      case _i6u7fweb.ActionMotionType():
        return 'ActionMotionType';
      case _im1lc214.ActionMovementKind():
        return 'ActionMovementKind';
      case _im9dc1is.ActionOpportunity():
        return 'ActionOpportunity';
      case _ikdqwmpd.ActionQrChallenge():
        return 'ActionQrChallenge';
      case _ixcs1xdh.ActionQrChallengeCleanupTask():
        return 'ActionQrChallengeCleanupTask';
      case _iqwh4ycl.ActionQrChallengeView():
        return 'ActionQrChallengeView';
      case _ii99v1ve.ActionQrRule():
        return 'ActionQrRule';
      case _i45a1wjj.ActionRecurrence():
        return 'ActionRecurrence';
      case _inly21qh.ActionRequirement():
        return 'ActionRequirement';
      case _ivobne24.ActionRequirementDraft():
        return 'ActionRequirementDraft';
      case _i55w548r.ActionRequirementKind():
        return 'ActionRequirementKind';
      case _icsa4634.ActionRequirementView():
        return 'ActionRequirementView';
      case _i14ro0o5.ActionSpokenChallenge():
        return 'ActionSpokenChallenge';
      case _ifuw4tho.ActionSpokenChallengeCleanupTask():
        return 'ActionSpokenChallengeCleanupTask';
      case _iikyln3l.ActionSpokenChallengeView():
        return 'ActionSpokenChallengeView';
      case _i0iphegd.ActionTemplate():
        return 'ActionTemplate';
      case _i960u7rl.ActionVerificationPolicy():
        return 'ActionVerificationPolicy';
      case _ichxscv5.ActionVisibility():
        return 'ActionVisibility';
      case _i5yjywpf.CreateActionDefinitionRequest():
        return 'CreateActionDefinitionRequest';
      case _i9u1614a.EvidenceAppeal():
        return 'EvidenceAppeal';
      case _i90o7tud.EvidenceAppealStatus():
        return 'EvidenceAppealStatus';
      case _iy27rorb.EvidenceAppealView():
        return 'EvidenceAppealView';
      case _ii2t12jt.EvidenceDecision():
        return 'EvidenceDecision';
      case _i5tayeq6.EvidenceDecisionStatus():
        return 'EvidenceDecisionStatus';
      case _i1gh041m.EvidenceProvenanceLevel():
        return 'EvidenceProvenanceLevel';
      case _i0mgpur2.EvidenceReviewQueueItem():
        return 'EvidenceReviewQueueItem';
      case _iy0z34jt.EvidenceSubmissionResult():
        return 'EvidenceSubmissionResult';
      case _i5dnc8lk.EvidenceVerificationJob():
        return 'EvidenceVerificationJob';
      case _i2k44lse.EvidenceVerificationJobStatus():
        return 'EvidenceVerificationJobStatus';
      case _il1p2vsk.EvidenceVerificationRecoveryTask():
        return 'EvidenceVerificationRecoveryTask';
      case _in8wt7wh.EvidenceVerificationTask():
        return 'EvidenceVerificationTask';
      case _itcyvpmo.EvidenceVerificationVote():
        return 'EvidenceVerificationVote';
      case _iu3m4umr.ActionLocalCheck():
        return 'ActionLocalCheck';
      case _iarjk3hm.DeviceLocalCheckResult():
        return 'DeviceLocalCheckResult';
      case _iqhexf0c.LocalCheckModelView():
        return 'LocalCheckModelView';
      case _if2a7jyy.LocalCheckTask():
        return 'LocalCheckTask';
      case _i9z86si9.MediaUploadConfirmation():
        return 'MediaUploadConfirmation';
      case _itcje0ok.MissingResource():
        return 'MissingResource';
      case _i05z8wlg.PayoutReviewView():
        return 'PayoutReviewView';
      case _ihri8lgz.ResourceNotFoundException():
        return 'ResourceNotFoundException';
      case _imnd8hof.AiUsageRequest():
        return 'AiUsageRequest';
      case _ij8e0uwy.AiUsageStatus():
        return 'AiUsageStatus';
      case _i00uumzo.ActionExternalRule():
        return 'ActionExternalRule';
      case _iix86y46.AppConfirmation():
        return 'AppConfirmation';
      case _ix5pwyym.AppConfirmationOutcome():
        return 'AppConfirmationOutcome';
      case _iqtml4wq.AppConfirmationView():
        return 'AppConfirmationView';
      case _iwa6gvjs.AppPlatformException():
        return 'AppPlatformException';
      case _if20wdmx.AppPlatformProblem():
        return 'AppPlatformProblem';
      case _iem3wxny.AppPullCheck():
        return 'AppPullCheck';
      case _inaep7ed.AppPullCheckRecoveryTask():
        return 'AppPullCheckRecoveryTask';
      case _i3ubh0mc.AppPullCheckStatus():
        return 'AppPullCheckStatus';
      case _i3j4e45w.AppPullCheckTask():
        return 'AppPullCheckTask';
      case _i3krqelq.AppUnavailableException():
        return 'AppUnavailableException';
      case _ijzftij0.AppVerificationMode():
        return 'AppVerificationMode';
      case _i36kvzuc.AppLinkCodeCleanupTask():
        return 'AppLinkCodeCleanupTask';
      case _i6s4a256.AppLinkRedirect():
        return 'AppLinkRedirect';
      case _ilshz35f.AppLinkRequestView():
        return 'AppLinkRequestView';
      case _i6yo3b5n.VerilyAppLinkCode():
        return 'VerilyAppLinkCode';
      case _in5ng4ea.VerilyApp():
        return 'VerilyApp';
      case _iaui7d4n.VerilyAppCredential():
        return 'VerilyAppCredential';
      case _ibhkb5dt.VerilyAppKey():
        return 'VerilyAppKey';
      case _ipa8tni0.VerilyAppKeyView():
        return 'VerilyAppKeyView';
      case _ikhive7i.VerilyAppLink():
        return 'VerilyAppLink';
      case _ikihia57.VerilyAppLinkView():
        return 'VerilyAppLinkView';
      case _ie89zcz8.VerilyAppRateWindow():
        return 'VerilyAppRateWindow';
      case _iqs5ny0z.VerilyAppRedirectUri():
        return 'VerilyAppRedirectUri';
      case _ibal4ihb.VerilyAppStatus():
        return 'VerilyAppStatus';
      case _ifrl0pdw.VerilyAppView():
        return 'VerilyAppView';
      case _i13rn6uf.AppEvent():
        return 'AppEvent';
      case _ichijhlk.AppEventDeliveryTask():
        return 'AppEventDeliveryTask';
      case _igoow6fn.AppEventRecoveryTask():
        return 'AppEventRecoveryTask';
      case _io6036x8.AppEventStatus():
        return 'AppEventStatus';
      case _irpgk99g.AppWebhookDelivery():
        return 'AppWebhookDelivery';
      case _ifch1v2s.AppWebhookDeliveryView():
        return 'AppWebhookDeliveryView';
      case _it0ux8yj.VerilyAppWebhookSecret():
        return 'VerilyAppWebhookSecret';
      case _ioo44wgs.EvidenceUploadCleanupTask():
        return 'EvidenceUploadCleanupTask';
      case _is4ltac0.EvidenceUploadReservation():
        return 'EvidenceUploadReservation';
      case _iz4zjc1b.EvidenceUploadStatus():
        return 'EvidenceUploadStatus';
      case _ib7h7gae.InferenceCostReservation():
        return 'InferenceCostReservation';
      case _i6lm2vyc.ModerationAuditEntry():
        return 'ModerationAuditEntry';
      case _i59xm5p1.ModerationAuditView():
        return 'ModerationAuditView';
      case _ili1rv2x.ModerationCase():
        return 'ModerationCase';
      case _iygcn9wp.ModerationCaseReviewView():
        return 'ModerationCaseReviewView';
      case _i7oivf7f.ModerationCaseStatusView():
        return 'ModerationCaseStatusView';
      case _inzarup3.PayoutWallet():
        return 'PayoutWallet';
      case _iyph9n2p.PayoutWalletChallengeCleanupTask():
        return 'PayoutWalletChallengeCleanupTask';
      case _i717n6wz.PayoutWalletLinkChallenge():
        return 'PayoutWalletLinkChallenge';
      case _icfglt50.PayoutWalletLinkChallengeView():
        return 'PayoutWalletLinkChallengeView';
      case _iqtp7i2n.PayoutWalletView():
        return 'PayoutWalletView';
      case _i3rw9wf5.RewardCluster():
        return 'RewardCluster';
      case _ilrvghyo.RewardEndPlan():
        return 'RewardEndPlan';
      case _in6hek74.RewardException():
        return 'RewardException';
      case _iyf1v3jl.RewardFundingPlan():
        return 'RewardFundingPlan';
      case _iv4eta4e.RewardOutcome():
        return 'RewardOutcome';
      case _i09j9cr3.RewardPayout():
        return 'RewardPayout';
      case _i3dio64d.RewardPayoutRecoveryTask():
        return 'RewardPayoutRecoveryTask';
      case _idfqmhge.RewardPayoutStatus():
        return 'RewardPayoutStatus';
      case _isxaon27.RewardPayoutTask():
        return 'RewardPayoutTask';
      case _ieggihqi.RewardPayoutView():
        return 'RewardPayoutView';
      case _i5k7uglj.RewardPool():
        return 'RewardPool';
      case _iv8dpf52.RewardPoolStatus():
        return 'RewardPoolStatus';
      case _if6e3cxh.RewardPoolView():
        return 'RewardPoolView';
      case _i4sm4ipz.RewardProblem():
        return 'RewardProblem';
      case _i9b5h2nk.RewardSummary():
        return 'RewardSummary';
      case _iokaii94.RewardTermsDraft():
        return 'RewardTermsDraft';
      case _i3qq4r4i.VerificationRequest():
        return 'VerificationRequest';
      case _ig30b0kc.VerificationRequestCheck():
        return 'VerificationRequestCheck';
      case _igwxgobn.VerificationRequestExpiryTask():
        return 'VerificationRequestExpiryTask';
      case _ij8vmgkg.VerificationRequestKind():
        return 'VerificationRequestKind';
      case _ik3wnzle.VerificationRequestRedirect():
        return 'VerificationRequestRedirect';
      case _in2jgiwv.VerificationRequestStatus():
        return 'VerificationRequestStatus';
      case _i3v95178.VerificationRequestView():
        return 'VerificationRequestView';
    }
    className = _iacs.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
    }
    className = _iais.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    className = _isp.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.') ? className : 'serverpod.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'AbuseRiskAssessment') {
      return deserialize<_ifpimmza.AbuseRiskAssessment>(data['data']);
    }
    if (dataClassName == 'AccountClosure') {
      return deserialize<_if4812wc.AccountClosure>(data['data']);
    }
    if (dataClassName == 'AccountClosureStatus') {
      return deserialize<_i7zadist.AccountClosureStatus>(data['data']);
    }
    if (dataClassName == 'ActionAttempt') {
      return deserialize<_igwrfg7c.ActionAttempt>(data['data']);
    }
    if (dataClassName == 'ActionAttemptStatus') {
      return deserialize<_iu22l7ek.ActionAttemptStatus>(data['data']);
    }
    if (dataClassName == 'ActionAttemptView') {
      return deserialize<_ixgg3yqh.ActionAttemptView>(data['data']);
    }
    if (dataClassName == 'ActionAuthoringException') {
      return deserialize<_i8z355ak.ActionAuthoringException>(data['data']);
    }
    if (dataClassName == 'ActionAuthoringProblem') {
      return deserialize<_ifi47ne5.ActionAuthoringProblem>(data['data']);
    }
    if (dataClassName == 'ActionCaptureChallenge') {
      return deserialize<_irhbzkbi.ActionCaptureChallenge>(data['data']);
    }
    if (dataClassName == 'ActionCaptureChallengeCleanupTask') {
      return deserialize<_idx11lej.ActionCaptureChallengeCleanupTask>(
        data['data'],
      );
    }
    if (dataClassName == 'ActionCaptureChallengeView') {
      return deserialize<_i55m67tr.ActionCaptureChallengeView>(data['data']);
    }
    if (dataClassName == 'ActionDefinition') {
      return deserialize<_ip3p3cwa.ActionDefinition>(data['data']);
    }
    if (dataClassName == 'ActionDefinitionStatus') {
      return deserialize<_igizisql.ActionDefinitionStatus>(data['data']);
    }
    if (dataClassName == 'ActionDraftProposal') {
      return deserialize<_iqti045q.ActionDraftProposal>(data['data']);
    }
    if (dataClassName == 'ActionDraftingUnavailableException') {
      return deserialize<_ism88bqz.ActionDraftingUnavailableException>(
        data['data'],
      );
    }
    if (dataClassName == 'ActionEvidence') {
      return deserialize<_ikmbmeqc.ActionEvidence>(data['data']);
    }
    if (dataClassName == 'ActionEvidenceInput') {
      return deserialize<_iq3mdjhk.ActionEvidenceInput>(data['data']);
    }
    if (dataClassName == 'ActionLocationRule') {
      return deserialize<_iz39t19t.ActionLocationRule>(data['data']);
    }
    if (dataClassName == 'ActionMediaRule') {
      return deserialize<_iw9if8ju.ActionMediaRule>(data['data']);
    }
    if (dataClassName == 'ActionMotionAxis') {
      return deserialize<_i5b1uunc.ActionMotionAxis>(data['data']);
    }
    if (dataClassName == 'ActionMotionRule') {
      return deserialize<_ih8siueq.ActionMotionRule>(data['data']);
    }
    if (dataClassName == 'ActionMotionSample') {
      return deserialize<_irayxhn9.ActionMotionSample>(data['data']);
    }
    if (dataClassName == 'ActionMotionType') {
      return deserialize<_i6u7fweb.ActionMotionType>(data['data']);
    }
    if (dataClassName == 'ActionMovementKind') {
      return deserialize<_im1lc214.ActionMovementKind>(data['data']);
    }
    if (dataClassName == 'ActionOpportunity') {
      return deserialize<_im9dc1is.ActionOpportunity>(data['data']);
    }
    if (dataClassName == 'ActionQrChallenge') {
      return deserialize<_ikdqwmpd.ActionQrChallenge>(data['data']);
    }
    if (dataClassName == 'ActionQrChallengeCleanupTask') {
      return deserialize<_ixcs1xdh.ActionQrChallengeCleanupTask>(data['data']);
    }
    if (dataClassName == 'ActionQrChallengeView') {
      return deserialize<_iqwh4ycl.ActionQrChallengeView>(data['data']);
    }
    if (dataClassName == 'ActionQrRule') {
      return deserialize<_ii99v1ve.ActionQrRule>(data['data']);
    }
    if (dataClassName == 'ActionRecurrence') {
      return deserialize<_i45a1wjj.ActionRecurrence>(data['data']);
    }
    if (dataClassName == 'ActionRequirement') {
      return deserialize<_inly21qh.ActionRequirement>(data['data']);
    }
    if (dataClassName == 'ActionRequirementDraft') {
      return deserialize<_ivobne24.ActionRequirementDraft>(data['data']);
    }
    if (dataClassName == 'ActionRequirementKind') {
      return deserialize<_i55w548r.ActionRequirementKind>(data['data']);
    }
    if (dataClassName == 'ActionRequirementView') {
      return deserialize<_icsa4634.ActionRequirementView>(data['data']);
    }
    if (dataClassName == 'ActionSpokenChallenge') {
      return deserialize<_i14ro0o5.ActionSpokenChallenge>(data['data']);
    }
    if (dataClassName == 'ActionSpokenChallengeCleanupTask') {
      return deserialize<_ifuw4tho.ActionSpokenChallengeCleanupTask>(
        data['data'],
      );
    }
    if (dataClassName == 'ActionSpokenChallengeView') {
      return deserialize<_iikyln3l.ActionSpokenChallengeView>(data['data']);
    }
    if (dataClassName == 'ActionTemplate') {
      return deserialize<_i0iphegd.ActionTemplate>(data['data']);
    }
    if (dataClassName == 'ActionVerificationPolicy') {
      return deserialize<_i960u7rl.ActionVerificationPolicy>(data['data']);
    }
    if (dataClassName == 'ActionVisibility') {
      return deserialize<_ichxscv5.ActionVisibility>(data['data']);
    }
    if (dataClassName == 'CreateActionDefinitionRequest') {
      return deserialize<_i5yjywpf.CreateActionDefinitionRequest>(data['data']);
    }
    if (dataClassName == 'EvidenceAppeal') {
      return deserialize<_i9u1614a.EvidenceAppeal>(data['data']);
    }
    if (dataClassName == 'EvidenceAppealStatus') {
      return deserialize<_i90o7tud.EvidenceAppealStatus>(data['data']);
    }
    if (dataClassName == 'EvidenceAppealView') {
      return deserialize<_iy27rorb.EvidenceAppealView>(data['data']);
    }
    if (dataClassName == 'EvidenceDecision') {
      return deserialize<_ii2t12jt.EvidenceDecision>(data['data']);
    }
    if (dataClassName == 'EvidenceDecisionStatus') {
      return deserialize<_i5tayeq6.EvidenceDecisionStatus>(data['data']);
    }
    if (dataClassName == 'EvidenceProvenanceLevel') {
      return deserialize<_i1gh041m.EvidenceProvenanceLevel>(data['data']);
    }
    if (dataClassName == 'EvidenceReviewQueueItem') {
      return deserialize<_i0mgpur2.EvidenceReviewQueueItem>(data['data']);
    }
    if (dataClassName == 'EvidenceSubmissionResult') {
      return deserialize<_iy0z34jt.EvidenceSubmissionResult>(data['data']);
    }
    if (dataClassName == 'EvidenceVerificationJob') {
      return deserialize<_i5dnc8lk.EvidenceVerificationJob>(data['data']);
    }
    if (dataClassName == 'EvidenceVerificationJobStatus') {
      return deserialize<_i2k44lse.EvidenceVerificationJobStatus>(data['data']);
    }
    if (dataClassName == 'EvidenceVerificationRecoveryTask') {
      return deserialize<_il1p2vsk.EvidenceVerificationRecoveryTask>(
        data['data'],
      );
    }
    if (dataClassName == 'EvidenceVerificationTask') {
      return deserialize<_in8wt7wh.EvidenceVerificationTask>(data['data']);
    }
    if (dataClassName == 'EvidenceVerificationVote') {
      return deserialize<_itcyvpmo.EvidenceVerificationVote>(data['data']);
    }
    if (dataClassName == 'ActionLocalCheck') {
      return deserialize<_iu3m4umr.ActionLocalCheck>(data['data']);
    }
    if (dataClassName == 'DeviceLocalCheckResult') {
      return deserialize<_iarjk3hm.DeviceLocalCheckResult>(data['data']);
    }
    if (dataClassName == 'LocalCheckModelView') {
      return deserialize<_iqhexf0c.LocalCheckModelView>(data['data']);
    }
    if (dataClassName == 'LocalCheckTask') {
      return deserialize<_if2a7jyy.LocalCheckTask>(data['data']);
    }
    if (dataClassName == 'MediaUploadConfirmation') {
      return deserialize<_i9z86si9.MediaUploadConfirmation>(data['data']);
    }
    if (dataClassName == 'MissingResource') {
      return deserialize<_itcje0ok.MissingResource>(data['data']);
    }
    if (dataClassName == 'PayoutReviewView') {
      return deserialize<_i05z8wlg.PayoutReviewView>(data['data']);
    }
    if (dataClassName == 'ResourceNotFoundException') {
      return deserialize<_ihri8lgz.ResourceNotFoundException>(data['data']);
    }
    if (dataClassName == 'AiUsageRequest') {
      return deserialize<_imnd8hof.AiUsageRequest>(data['data']);
    }
    if (dataClassName == 'AiUsageStatus') {
      return deserialize<_ij8e0uwy.AiUsageStatus>(data['data']);
    }
    if (dataClassName == 'ActionExternalRule') {
      return deserialize<_i00uumzo.ActionExternalRule>(data['data']);
    }
    if (dataClassName == 'AppConfirmation') {
      return deserialize<_iix86y46.AppConfirmation>(data['data']);
    }
    if (dataClassName == 'AppConfirmationOutcome') {
      return deserialize<_ix5pwyym.AppConfirmationOutcome>(data['data']);
    }
    if (dataClassName == 'AppConfirmationView') {
      return deserialize<_iqtml4wq.AppConfirmationView>(data['data']);
    }
    if (dataClassName == 'AppPlatformException') {
      return deserialize<_iwa6gvjs.AppPlatformException>(data['data']);
    }
    if (dataClassName == 'AppPlatformProblem') {
      return deserialize<_if20wdmx.AppPlatformProblem>(data['data']);
    }
    if (dataClassName == 'AppPullCheck') {
      return deserialize<_iem3wxny.AppPullCheck>(data['data']);
    }
    if (dataClassName == 'AppPullCheckRecoveryTask') {
      return deserialize<_inaep7ed.AppPullCheckRecoveryTask>(data['data']);
    }
    if (dataClassName == 'AppPullCheckStatus') {
      return deserialize<_i3ubh0mc.AppPullCheckStatus>(data['data']);
    }
    if (dataClassName == 'AppPullCheckTask') {
      return deserialize<_i3j4e45w.AppPullCheckTask>(data['data']);
    }
    if (dataClassName == 'AppUnavailableException') {
      return deserialize<_i3krqelq.AppUnavailableException>(data['data']);
    }
    if (dataClassName == 'AppVerificationMode') {
      return deserialize<_ijzftij0.AppVerificationMode>(data['data']);
    }
    if (dataClassName == 'AppLinkCodeCleanupTask') {
      return deserialize<_i36kvzuc.AppLinkCodeCleanupTask>(data['data']);
    }
    if (dataClassName == 'AppLinkRedirect') {
      return deserialize<_i6s4a256.AppLinkRedirect>(data['data']);
    }
    if (dataClassName == 'AppLinkRequestView') {
      return deserialize<_ilshz35f.AppLinkRequestView>(data['data']);
    }
    if (dataClassName == 'VerilyAppLinkCode') {
      return deserialize<_i6yo3b5n.VerilyAppLinkCode>(data['data']);
    }
    if (dataClassName == 'VerilyApp') {
      return deserialize<_in5ng4ea.VerilyApp>(data['data']);
    }
    if (dataClassName == 'VerilyAppCredential') {
      return deserialize<_iaui7d4n.VerilyAppCredential>(data['data']);
    }
    if (dataClassName == 'VerilyAppKey') {
      return deserialize<_ibhkb5dt.VerilyAppKey>(data['data']);
    }
    if (dataClassName == 'VerilyAppKeyView') {
      return deserialize<_ipa8tni0.VerilyAppKeyView>(data['data']);
    }
    if (dataClassName == 'VerilyAppLink') {
      return deserialize<_ikhive7i.VerilyAppLink>(data['data']);
    }
    if (dataClassName == 'VerilyAppLinkView') {
      return deserialize<_ikihia57.VerilyAppLinkView>(data['data']);
    }
    if (dataClassName == 'VerilyAppRateWindow') {
      return deserialize<_ie89zcz8.VerilyAppRateWindow>(data['data']);
    }
    if (dataClassName == 'VerilyAppRedirectUri') {
      return deserialize<_iqs5ny0z.VerilyAppRedirectUri>(data['data']);
    }
    if (dataClassName == 'VerilyAppStatus') {
      return deserialize<_ibal4ihb.VerilyAppStatus>(data['data']);
    }
    if (dataClassName == 'VerilyAppView') {
      return deserialize<_ifrl0pdw.VerilyAppView>(data['data']);
    }
    if (dataClassName == 'AppEvent') {
      return deserialize<_i13rn6uf.AppEvent>(data['data']);
    }
    if (dataClassName == 'AppEventDeliveryTask') {
      return deserialize<_ichijhlk.AppEventDeliveryTask>(data['data']);
    }
    if (dataClassName == 'AppEventRecoveryTask') {
      return deserialize<_igoow6fn.AppEventRecoveryTask>(data['data']);
    }
    if (dataClassName == 'AppEventStatus') {
      return deserialize<_io6036x8.AppEventStatus>(data['data']);
    }
    if (dataClassName == 'AppWebhookDelivery') {
      return deserialize<_irpgk99g.AppWebhookDelivery>(data['data']);
    }
    if (dataClassName == 'AppWebhookDeliveryView') {
      return deserialize<_ifch1v2s.AppWebhookDeliveryView>(data['data']);
    }
    if (dataClassName == 'VerilyAppWebhookSecret') {
      return deserialize<_it0ux8yj.VerilyAppWebhookSecret>(data['data']);
    }
    if (dataClassName == 'EvidenceUploadCleanupTask') {
      return deserialize<_ioo44wgs.EvidenceUploadCleanupTask>(data['data']);
    }
    if (dataClassName == 'EvidenceUploadReservation') {
      return deserialize<_is4ltac0.EvidenceUploadReservation>(data['data']);
    }
    if (dataClassName == 'EvidenceUploadStatus') {
      return deserialize<_iz4zjc1b.EvidenceUploadStatus>(data['data']);
    }
    if (dataClassName == 'InferenceCostReservation') {
      return deserialize<_ib7h7gae.InferenceCostReservation>(data['data']);
    }
    if (dataClassName == 'ModerationAuditEntry') {
      return deserialize<_i6lm2vyc.ModerationAuditEntry>(data['data']);
    }
    if (dataClassName == 'ModerationAuditView') {
      return deserialize<_i59xm5p1.ModerationAuditView>(data['data']);
    }
    if (dataClassName == 'ModerationCase') {
      return deserialize<_ili1rv2x.ModerationCase>(data['data']);
    }
    if (dataClassName == 'ModerationCaseReviewView') {
      return deserialize<_iygcn9wp.ModerationCaseReviewView>(data['data']);
    }
    if (dataClassName == 'ModerationCaseStatusView') {
      return deserialize<_i7oivf7f.ModerationCaseStatusView>(data['data']);
    }
    if (dataClassName == 'PayoutWallet') {
      return deserialize<_inzarup3.PayoutWallet>(data['data']);
    }
    if (dataClassName == 'PayoutWalletChallengeCleanupTask') {
      return deserialize<_iyph9n2p.PayoutWalletChallengeCleanupTask>(
        data['data'],
      );
    }
    if (dataClassName == 'PayoutWalletLinkChallenge') {
      return deserialize<_i717n6wz.PayoutWalletLinkChallenge>(data['data']);
    }
    if (dataClassName == 'PayoutWalletLinkChallengeView') {
      return deserialize<_icfglt50.PayoutWalletLinkChallengeView>(data['data']);
    }
    if (dataClassName == 'PayoutWalletView') {
      return deserialize<_iqtp7i2n.PayoutWalletView>(data['data']);
    }
    if (dataClassName == 'RewardCluster') {
      return deserialize<_i3rw9wf5.RewardCluster>(data['data']);
    }
    if (dataClassName == 'RewardEndPlan') {
      return deserialize<_ilrvghyo.RewardEndPlan>(data['data']);
    }
    if (dataClassName == 'RewardException') {
      return deserialize<_in6hek74.RewardException>(data['data']);
    }
    if (dataClassName == 'RewardFundingPlan') {
      return deserialize<_iyf1v3jl.RewardFundingPlan>(data['data']);
    }
    if (dataClassName == 'RewardOutcome') {
      return deserialize<_iv4eta4e.RewardOutcome>(data['data']);
    }
    if (dataClassName == 'RewardPayout') {
      return deserialize<_i09j9cr3.RewardPayout>(data['data']);
    }
    if (dataClassName == 'RewardPayoutRecoveryTask') {
      return deserialize<_i3dio64d.RewardPayoutRecoveryTask>(data['data']);
    }
    if (dataClassName == 'RewardPayoutStatus') {
      return deserialize<_idfqmhge.RewardPayoutStatus>(data['data']);
    }
    if (dataClassName == 'RewardPayoutTask') {
      return deserialize<_isxaon27.RewardPayoutTask>(data['data']);
    }
    if (dataClassName == 'RewardPayoutView') {
      return deserialize<_ieggihqi.RewardPayoutView>(data['data']);
    }
    if (dataClassName == 'RewardPool') {
      return deserialize<_i5k7uglj.RewardPool>(data['data']);
    }
    if (dataClassName == 'RewardPoolStatus') {
      return deserialize<_iv8dpf52.RewardPoolStatus>(data['data']);
    }
    if (dataClassName == 'RewardPoolView') {
      return deserialize<_if6e3cxh.RewardPoolView>(data['data']);
    }
    if (dataClassName == 'RewardProblem') {
      return deserialize<_i4sm4ipz.RewardProblem>(data['data']);
    }
    if (dataClassName == 'RewardSummary') {
      return deserialize<_i9b5h2nk.RewardSummary>(data['data']);
    }
    if (dataClassName == 'RewardTermsDraft') {
      return deserialize<_iokaii94.RewardTermsDraft>(data['data']);
    }
    if (dataClassName == 'VerificationRequest') {
      return deserialize<_i3qq4r4i.VerificationRequest>(data['data']);
    }
    if (dataClassName == 'VerificationRequestCheck') {
      return deserialize<_ig30b0kc.VerificationRequestCheck>(data['data']);
    }
    if (dataClassName == 'VerificationRequestExpiryTask') {
      return deserialize<_igwxgobn.VerificationRequestExpiryTask>(data['data']);
    }
    if (dataClassName == 'VerificationRequestKind') {
      return deserialize<_ij8vmgkg.VerificationRequestKind>(data['data']);
    }
    if (dataClassName == 'VerificationRequestRedirect') {
      return deserialize<_ik3wnzle.VerificationRequestRedirect>(data['data']);
    }
    if (dataClassName == 'VerificationRequestStatus') {
      return deserialize<_in2jgiwv.VerificationRequestStatus>(data['data']);
    }
    if (dataClassName == 'VerificationRequestView') {
      return deserialize<_i3v95178.VerificationRequestView>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _iacs.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _iais.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _isp.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _iacs.Protocol().registerHostProtocol('verily', this);
    _iais.Protocol().registerHostProtocol('verily', this);
  }

  @override
  _is.Table? getTableForType(Type t) {
    {
      var table = _iacs.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _iais.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _isp.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _ifpimmza.AbuseRiskAssessment:
        return _ifpimmza.AbuseRiskAssessment.t;
      case _if4812wc.AccountClosure:
        return _if4812wc.AccountClosure.t;
      case _igwrfg7c.ActionAttempt:
        return _igwrfg7c.ActionAttempt.t;
      case _irhbzkbi.ActionCaptureChallenge:
        return _irhbzkbi.ActionCaptureChallenge.t;
      case _ip3p3cwa.ActionDefinition:
        return _ip3p3cwa.ActionDefinition.t;
      case _ikmbmeqc.ActionEvidence:
        return _ikmbmeqc.ActionEvidence.t;
      case _iz39t19t.ActionLocationRule:
        return _iz39t19t.ActionLocationRule.t;
      case _iw9if8ju.ActionMediaRule:
        return _iw9if8ju.ActionMediaRule.t;
      case _ih8siueq.ActionMotionRule:
        return _ih8siueq.ActionMotionRule.t;
      case _ikdqwmpd.ActionQrChallenge:
        return _ikdqwmpd.ActionQrChallenge.t;
      case _ii99v1ve.ActionQrRule:
        return _ii99v1ve.ActionQrRule.t;
      case _inly21qh.ActionRequirement:
        return _inly21qh.ActionRequirement.t;
      case _i14ro0o5.ActionSpokenChallenge:
        return _i14ro0o5.ActionSpokenChallenge.t;
      case _i9u1614a.EvidenceAppeal:
        return _i9u1614a.EvidenceAppeal.t;
      case _ii2t12jt.EvidenceDecision:
        return _ii2t12jt.EvidenceDecision.t;
      case _i5dnc8lk.EvidenceVerificationJob:
        return _i5dnc8lk.EvidenceVerificationJob.t;
      case _itcyvpmo.EvidenceVerificationVote:
        return _itcyvpmo.EvidenceVerificationVote.t;
      case _imnd8hof.AiUsageRequest:
        return _imnd8hof.AiUsageRequest.t;
      case _i00uumzo.ActionExternalRule:
        return _i00uumzo.ActionExternalRule.t;
      case _iix86y46.AppConfirmation:
        return _iix86y46.AppConfirmation.t;
      case _iem3wxny.AppPullCheck:
        return _iem3wxny.AppPullCheck.t;
      case _i6yo3b5n.VerilyAppLinkCode:
        return _i6yo3b5n.VerilyAppLinkCode.t;
      case _in5ng4ea.VerilyApp:
        return _in5ng4ea.VerilyApp.t;
      case _ibhkb5dt.VerilyAppKey:
        return _ibhkb5dt.VerilyAppKey.t;
      case _ikhive7i.VerilyAppLink:
        return _ikhive7i.VerilyAppLink.t;
      case _ie89zcz8.VerilyAppRateWindow:
        return _ie89zcz8.VerilyAppRateWindow.t;
      case _iqs5ny0z.VerilyAppRedirectUri:
        return _iqs5ny0z.VerilyAppRedirectUri.t;
      case _i13rn6uf.AppEvent:
        return _i13rn6uf.AppEvent.t;
      case _irpgk99g.AppWebhookDelivery:
        return _irpgk99g.AppWebhookDelivery.t;
      case _is4ltac0.EvidenceUploadReservation:
        return _is4ltac0.EvidenceUploadReservation.t;
      case _ib7h7gae.InferenceCostReservation:
        return _ib7h7gae.InferenceCostReservation.t;
      case _i6lm2vyc.ModerationAuditEntry:
        return _i6lm2vyc.ModerationAuditEntry.t;
      case _ili1rv2x.ModerationCase:
        return _ili1rv2x.ModerationCase.t;
      case _inzarup3.PayoutWallet:
        return _inzarup3.PayoutWallet.t;
      case _i717n6wz.PayoutWalletLinkChallenge:
        return _i717n6wz.PayoutWalletLinkChallenge.t;
      case _i09j9cr3.RewardPayout:
        return _i09j9cr3.RewardPayout.t;
      case _i5k7uglj.RewardPool:
        return _i5k7uglj.RewardPool.t;
      case _i3qq4r4i.VerificationRequest:
        return _i3qq4r4i.VerificationRequest.t;
    }
    return null;
  }

  @override
  List<_isp.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'verily';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _iacs.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _iais.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
