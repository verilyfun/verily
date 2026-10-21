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
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _iacc;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _iaic;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'package:verily_client/src/protocol/action_verification/action_attempt_view.dart'
    as _ir431rrk;
import 'package:verily_client/src/protocol/action_verification/action_opportunity.dart'
    as _ijjtlylw;
import 'package:verily_client/src/protocol/action_verification/action_template.dart'
    as _i6d3vqey;
import 'package:verily_client/src/protocol/action_verification/evidence_appeal_view.dart'
    as _igtzj0f1;
import 'package:verily_client/src/protocol/action_verification/evidence_review_queue_item.dart'
    as _iyuppglq;
import 'package:verily_client/src/protocol/apps/app_confirmation_view.dart'
    as _iw9760io;
import 'package:verily_client/src/protocol/apps/verily_app_view.dart'
    as _in92p10u;
import 'package:verily_client/src/protocol/moderation/moderation_case_status_view.dart'
    as _ie976x46;
import 'package:verily_client/src/protocol/rewards/reward_payout_view.dart'
    as _isztzkpq;

import 'account/account_closure_status.dart' as _i7zadist;
import 'action_verification/action_attempt_status.dart' as _iu22l7ek;
import 'action_verification/action_attempt_view.dart' as _ixgg3yqh;
import 'action_verification/action_authoring_exception.dart' as _i8z355ak;
import 'action_verification/action_authoring_problem.dart' as _ifi47ne5;
import 'action_verification/action_capture_challenge_cleanup_task.dart'
    as _idx11lej;
import 'action_verification/action_capture_challenge_view.dart' as _i55m67tr;
import 'action_verification/action_definition_status.dart' as _igizisql;
import 'action_verification/action_draft_proposal.dart' as _iqti045q;
import 'action_verification/action_drafting_unavailable_exception.dart'
    as _ism88bqz;
import 'action_verification/action_evidence_input.dart' as _iq3mdjhk;
import 'action_verification/action_motion_axis.dart' as _i5b1uunc;
import 'action_verification/action_motion_sample.dart' as _irayxhn9;
import 'action_verification/action_motion_type.dart' as _i6u7fweb;
import 'action_verification/action_movement_kind.dart' as _im1lc214;
import 'action_verification/action_opportunity.dart' as _im9dc1is;
import 'action_verification/action_qr_challenge_cleanup_task.dart' as _ixcs1xdh;
import 'action_verification/action_qr_challenge_view.dart' as _iqwh4ycl;
import 'action_verification/action_recurrence.dart' as _i45a1wjj;
import 'action_verification/action_requirement_draft.dart' as _ivobne24;
import 'action_verification/action_requirement_kind.dart' as _i55w548r;
import 'action_verification/action_requirement_view.dart' as _icsa4634;
import 'action_verification/action_spoken_challenge_cleanup_task.dart'
    as _ifuw4tho;
import 'action_verification/action_spoken_challenge_view.dart' as _iikyln3l;
import 'action_verification/action_template.dart' as _i0iphegd;
import 'action_verification/action_verification_policy.dart' as _i960u7rl;
import 'action_verification/create_action_definition_request.dart' as _i5yjywpf;
import 'action_verification/evidence_appeal_status.dart' as _i90o7tud;
import 'action_verification/evidence_appeal_view.dart' as _iy27rorb;
import 'action_verification/evidence_decision_status.dart' as _i5tayeq6;
import 'action_verification/evidence_provenance_level.dart' as _i1gh041m;
import 'action_verification/evidence_review_queue_item.dart' as _i0mgpur2;
import 'action_verification/evidence_submission_result.dart' as _iy0z34jt;
import 'action_verification/evidence_verification_job_status.dart' as _i2k44lse;
import 'action_verification/evidence_verification_task.dart' as _in8wt7wh;
import 'action_verification/media_upload_confirmation.dart' as _i9z86si9;
import 'action_verification/payout_review_view.dart' as _i05z8wlg;
import 'ai_usage/ai_usage_status.dart' as _ij8e0uwy;
import 'apps/app_confirmation_outcome.dart' as _ix5pwyym;
import 'apps/app_confirmation_view.dart' as _iqtml4wq;
import 'apps/app_unavailable_exception.dart' as _i3krqelq;
import 'apps/verily_app_credential.dart' as _iaui7d4n;
import 'apps/verily_app_key_view.dart' as _ipa8tni0;
import 'apps/verily_app_link_view.dart' as _ikihia57;
import 'apps/verily_app_status.dart' as _ibal4ihb;
import 'apps/verily_app_view.dart' as _ifrl0pdw;
import 'evidence_storage/evidence_upload_cleanup_task.dart' as _ioo44wgs;
import 'evidence_storage/evidence_upload_status.dart' as _iz4zjc1b;
import 'moderation/moderation_audit_view.dart' as _i59xm5p1;
import 'moderation/moderation_case_review_view.dart' as _iygcn9wp;
import 'moderation/moderation_case_status_view.dart' as _i7oivf7f;
import 'rewards/payout_wallet_challenge_cleanup_task.dart' as _iyph9n2p;
import 'rewards/payout_wallet_link_challenge_view.dart' as _icfglt50;
import 'rewards/payout_wallet_view.dart' as _iqtp7i2n;
import 'rewards/reward_cluster.dart' as _i3rw9wf5;
import 'rewards/reward_end_plan.dart' as _ilrvghyo;
import 'rewards/reward_exception.dart' as _in6hek74;
import 'rewards/reward_funding_plan.dart' as _iyf1v3jl;
import 'rewards/reward_outcome.dart' as _iv4eta4e;
import 'rewards/reward_payout_recovery_task.dart' as _i3dio64d;
import 'rewards/reward_payout_status.dart' as _idfqmhge;
import 'rewards/reward_payout_task.dart' as _isxaon27;
import 'rewards/reward_payout_view.dart' as _ieggihqi;
import 'rewards/reward_pool_status.dart' as _iv8dpf52;
import 'rewards/reward_pool_view.dart' as _if6e3cxh;
import 'rewards/reward_problem.dart' as _i4sm4ipz;
import 'rewards/reward_summary.dart' as _i9b5h2nk;
import 'rewards/reward_terms_draft.dart' as _iokaii94;
export 'account/account_closure_status.dart';
export 'action_verification/action_attempt_status.dart';
export 'action_verification/action_attempt_view.dart';
export 'action_verification/action_authoring_exception.dart';
export 'action_verification/action_authoring_problem.dart';
export 'action_verification/action_capture_challenge_cleanup_task.dart';
export 'action_verification/action_capture_challenge_view.dart';
export 'action_verification/action_definition_status.dart';
export 'action_verification/action_draft_proposal.dart';
export 'action_verification/action_drafting_unavailable_exception.dart';
export 'action_verification/action_evidence_input.dart';
export 'action_verification/action_motion_axis.dart';
export 'action_verification/action_motion_sample.dart';
export 'action_verification/action_motion_type.dart';
export 'action_verification/action_movement_kind.dart';
export 'action_verification/action_opportunity.dart';
export 'action_verification/action_qr_challenge_cleanup_task.dart';
export 'action_verification/action_qr_challenge_view.dart';
export 'action_verification/action_recurrence.dart';
export 'action_verification/action_requirement_draft.dart';
export 'action_verification/action_requirement_kind.dart';
export 'action_verification/action_requirement_view.dart';
export 'action_verification/action_spoken_challenge_cleanup_task.dart';
export 'action_verification/action_spoken_challenge_view.dart';
export 'action_verification/action_template.dart';
export 'action_verification/action_verification_policy.dart';
export 'action_verification/create_action_definition_request.dart';
export 'action_verification/evidence_appeal_status.dart';
export 'action_verification/evidence_appeal_view.dart';
export 'action_verification/evidence_decision_status.dart';
export 'action_verification/evidence_provenance_level.dart';
export 'action_verification/evidence_review_queue_item.dart';
export 'action_verification/evidence_submission_result.dart';
export 'action_verification/evidence_verification_job_status.dart';
export 'action_verification/evidence_verification_task.dart';
export 'action_verification/media_upload_confirmation.dart';
export 'action_verification/payout_review_view.dart';
export 'ai_usage/ai_usage_status.dart';
export 'apps/app_confirmation_outcome.dart';
export 'apps/app_confirmation_view.dart';
export 'apps/app_unavailable_exception.dart';
export 'apps/verily_app_credential.dart';
export 'apps/verily_app_key_view.dart';
export 'apps/verily_app_link_view.dart';
export 'apps/verily_app_status.dart';
export 'apps/verily_app_view.dart';
export 'evidence_storage/evidence_upload_cleanup_task.dart';
export 'evidence_storage/evidence_upload_status.dart';
export 'moderation/moderation_audit_view.dart';
export 'moderation/moderation_case_review_view.dart';
export 'moderation/moderation_case_status_view.dart';
export 'rewards/payout_wallet_challenge_cleanup_task.dart';
export 'rewards/payout_wallet_link_challenge_view.dart';
export 'rewards/payout_wallet_view.dart';
export 'rewards/reward_cluster.dart';
export 'rewards/reward_end_plan.dart';
export 'rewards/reward_exception.dart';
export 'rewards/reward_funding_plan.dart';
export 'rewards/reward_outcome.dart';
export 'rewards/reward_payout_recovery_task.dart';
export 'rewards/reward_payout_status.dart';
export 'rewards/reward_payout_task.dart';
export 'rewards/reward_payout_view.dart';
export 'rewards/reward_pool_status.dart';
export 'rewards/reward_pool_view.dart';
export 'rewards/reward_problem.dart';
export 'rewards/reward_summary.dart';
export 'rewards/reward_terms_draft.dart';
export 'client.dart';

class Protocol extends _isc.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(dynamic data, [Type? t]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on _isc.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i7zadist.AccountClosureStatus) {
      return _i7zadist.AccountClosureStatus.fromJson(data) as T;
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
    if (t == _idx11lej.ActionCaptureChallengeCleanupTask) {
      return _idx11lej.ActionCaptureChallengeCleanupTask.fromJson(data) as T;
    }
    if (t == _i55m67tr.ActionCaptureChallengeView) {
      return _i55m67tr.ActionCaptureChallengeView.fromJson(data) as T;
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
    if (t == _iq3mdjhk.ActionEvidenceInput) {
      return _iq3mdjhk.ActionEvidenceInput.fromJson(data) as T;
    }
    if (t == _i5b1uunc.ActionMotionAxis) {
      return _i5b1uunc.ActionMotionAxis.fromJson(data) as T;
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
    if (t == _ixcs1xdh.ActionQrChallengeCleanupTask) {
      return _ixcs1xdh.ActionQrChallengeCleanupTask.fromJson(data) as T;
    }
    if (t == _iqwh4ycl.ActionQrChallengeView) {
      return _iqwh4ycl.ActionQrChallengeView.fromJson(data) as T;
    }
    if (t == _i45a1wjj.ActionRecurrence) {
      return _i45a1wjj.ActionRecurrence.fromJson(data) as T;
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
    if (t == _i5yjywpf.CreateActionDefinitionRequest) {
      return _i5yjywpf.CreateActionDefinitionRequest.fromJson(data) as T;
    }
    if (t == _i90o7tud.EvidenceAppealStatus) {
      return _i90o7tud.EvidenceAppealStatus.fromJson(data) as T;
    }
    if (t == _iy27rorb.EvidenceAppealView) {
      return _iy27rorb.EvidenceAppealView.fromJson(data) as T;
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
    if (t == _i2k44lse.EvidenceVerificationJobStatus) {
      return _i2k44lse.EvidenceVerificationJobStatus.fromJson(data) as T;
    }
    if (t == _in8wt7wh.EvidenceVerificationTask) {
      return _in8wt7wh.EvidenceVerificationTask.fromJson(data) as T;
    }
    if (t == _i9z86si9.MediaUploadConfirmation) {
      return _i9z86si9.MediaUploadConfirmation.fromJson(data) as T;
    }
    if (t == _i05z8wlg.PayoutReviewView) {
      return _i05z8wlg.PayoutReviewView.fromJson(data) as T;
    }
    if (t == _ij8e0uwy.AiUsageStatus) {
      return _ij8e0uwy.AiUsageStatus.fromJson(data) as T;
    }
    if (t == _ix5pwyym.AppConfirmationOutcome) {
      return _ix5pwyym.AppConfirmationOutcome.fromJson(data) as T;
    }
    if (t == _iqtml4wq.AppConfirmationView) {
      return _iqtml4wq.AppConfirmationView.fromJson(data) as T;
    }
    if (t == _i3krqelq.AppUnavailableException) {
      return _i3krqelq.AppUnavailableException.fromJson(data) as T;
    }
    if (t == _iaui7d4n.VerilyAppCredential) {
      return _iaui7d4n.VerilyAppCredential.fromJson(data) as T;
    }
    if (t == _ipa8tni0.VerilyAppKeyView) {
      return _ipa8tni0.VerilyAppKeyView.fromJson(data) as T;
    }
    if (t == _ikihia57.VerilyAppLinkView) {
      return _ikihia57.VerilyAppLinkView.fromJson(data) as T;
    }
    if (t == _ibal4ihb.VerilyAppStatus) {
      return _ibal4ihb.VerilyAppStatus.fromJson(data) as T;
    }
    if (t == _ifrl0pdw.VerilyAppView) {
      return _ifrl0pdw.VerilyAppView.fromJson(data) as T;
    }
    if (t == _ioo44wgs.EvidenceUploadCleanupTask) {
      return _ioo44wgs.EvidenceUploadCleanupTask.fromJson(data) as T;
    }
    if (t == _iz4zjc1b.EvidenceUploadStatus) {
      return _iz4zjc1b.EvidenceUploadStatus.fromJson(data) as T;
    }
    if (t == _i59xm5p1.ModerationAuditView) {
      return _i59xm5p1.ModerationAuditView.fromJson(data) as T;
    }
    if (t == _iygcn9wp.ModerationCaseReviewView) {
      return _iygcn9wp.ModerationCaseReviewView.fromJson(data) as T;
    }
    if (t == _i7oivf7f.ModerationCaseStatusView) {
      return _i7oivf7f.ModerationCaseStatusView.fromJson(data) as T;
    }
    if (t == _iyph9n2p.PayoutWalletChallengeCleanupTask) {
      return _iyph9n2p.PayoutWalletChallengeCleanupTask.fromJson(data) as T;
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
    if (t == _isc.getType<_i7zadist.AccountClosureStatus?>()) {
      return (data != null
              ? _i7zadist.AccountClosureStatus.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iu22l7ek.ActionAttemptStatus?>()) {
      return (data != null
              ? _iu22l7ek.ActionAttemptStatus.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ixgg3yqh.ActionAttemptView?>()) {
      return (data != null ? _ixgg3yqh.ActionAttemptView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i8z355ak.ActionAuthoringException?>()) {
      return (data != null
              ? _i8z355ak.ActionAuthoringException.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ifi47ne5.ActionAuthoringProblem?>()) {
      return (data != null
              ? _ifi47ne5.ActionAuthoringProblem.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_idx11lej.ActionCaptureChallengeCleanupTask?>()) {
      return (data != null
              ? _idx11lej.ActionCaptureChallengeCleanupTask.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i55m67tr.ActionCaptureChallengeView?>()) {
      return (data != null
              ? _i55m67tr.ActionCaptureChallengeView.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_igizisql.ActionDefinitionStatus?>()) {
      return (data != null
              ? _igizisql.ActionDefinitionStatus.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iqti045q.ActionDraftProposal?>()) {
      return (data != null
              ? _iqti045q.ActionDraftProposal.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ism88bqz.ActionDraftingUnavailableException?>()) {
      return (data != null
              ? _ism88bqz.ActionDraftingUnavailableException.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iq3mdjhk.ActionEvidenceInput?>()) {
      return (data != null
              ? _iq3mdjhk.ActionEvidenceInput.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i5b1uunc.ActionMotionAxis?>()) {
      return (data != null ? _i5b1uunc.ActionMotionAxis.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_irayxhn9.ActionMotionSample?>()) {
      return (data != null ? _irayxhn9.ActionMotionSample.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i6u7fweb.ActionMotionType?>()) {
      return (data != null ? _i6u7fweb.ActionMotionType.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_im1lc214.ActionMovementKind?>()) {
      return (data != null ? _im1lc214.ActionMovementKind.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_im9dc1is.ActionOpportunity?>()) {
      return (data != null ? _im9dc1is.ActionOpportunity.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ixcs1xdh.ActionQrChallengeCleanupTask?>()) {
      return (data != null
              ? _ixcs1xdh.ActionQrChallengeCleanupTask.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iqwh4ycl.ActionQrChallengeView?>()) {
      return (data != null
              ? _iqwh4ycl.ActionQrChallengeView.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i45a1wjj.ActionRecurrence?>()) {
      return (data != null ? _i45a1wjj.ActionRecurrence.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ivobne24.ActionRequirementDraft?>()) {
      return (data != null
              ? _ivobne24.ActionRequirementDraft.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i55w548r.ActionRequirementKind?>()) {
      return (data != null
              ? _i55w548r.ActionRequirementKind.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_icsa4634.ActionRequirementView?>()) {
      return (data != null
              ? _icsa4634.ActionRequirementView.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ifuw4tho.ActionSpokenChallengeCleanupTask?>()) {
      return (data != null
              ? _ifuw4tho.ActionSpokenChallengeCleanupTask.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iikyln3l.ActionSpokenChallengeView?>()) {
      return (data != null
              ? _iikyln3l.ActionSpokenChallengeView.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i0iphegd.ActionTemplate?>()) {
      return (data != null ? _i0iphegd.ActionTemplate.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i960u7rl.ActionVerificationPolicy?>()) {
      return (data != null
              ? _i960u7rl.ActionVerificationPolicy.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i5yjywpf.CreateActionDefinitionRequest?>()) {
      return (data != null
              ? _i5yjywpf.CreateActionDefinitionRequest.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i90o7tud.EvidenceAppealStatus?>()) {
      return (data != null
              ? _i90o7tud.EvidenceAppealStatus.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iy27rorb.EvidenceAppealView?>()) {
      return (data != null ? _iy27rorb.EvidenceAppealView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i5tayeq6.EvidenceDecisionStatus?>()) {
      return (data != null
              ? _i5tayeq6.EvidenceDecisionStatus.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i1gh041m.EvidenceProvenanceLevel?>()) {
      return (data != null
              ? _i1gh041m.EvidenceProvenanceLevel.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i0mgpur2.EvidenceReviewQueueItem?>()) {
      return (data != null
              ? _i0mgpur2.EvidenceReviewQueueItem.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iy0z34jt.EvidenceSubmissionResult?>()) {
      return (data != null
              ? _iy0z34jt.EvidenceSubmissionResult.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i2k44lse.EvidenceVerificationJobStatus?>()) {
      return (data != null
              ? _i2k44lse.EvidenceVerificationJobStatus.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_in8wt7wh.EvidenceVerificationTask?>()) {
      return (data != null
              ? _in8wt7wh.EvidenceVerificationTask.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i9z86si9.MediaUploadConfirmation?>()) {
      return (data != null
              ? _i9z86si9.MediaUploadConfirmation.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i05z8wlg.PayoutReviewView?>()) {
      return (data != null ? _i05z8wlg.PayoutReviewView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ij8e0uwy.AiUsageStatus?>()) {
      return (data != null ? _ij8e0uwy.AiUsageStatus.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ix5pwyym.AppConfirmationOutcome?>()) {
      return (data != null
              ? _ix5pwyym.AppConfirmationOutcome.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iqtml4wq.AppConfirmationView?>()) {
      return (data != null
              ? _iqtml4wq.AppConfirmationView.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i3krqelq.AppUnavailableException?>()) {
      return (data != null
              ? _i3krqelq.AppUnavailableException.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iaui7d4n.VerilyAppCredential?>()) {
      return (data != null
              ? _iaui7d4n.VerilyAppCredential.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ipa8tni0.VerilyAppKeyView?>()) {
      return (data != null ? _ipa8tni0.VerilyAppKeyView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ikihia57.VerilyAppLinkView?>()) {
      return (data != null ? _ikihia57.VerilyAppLinkView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ibal4ihb.VerilyAppStatus?>()) {
      return (data != null ? _ibal4ihb.VerilyAppStatus.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ifrl0pdw.VerilyAppView?>()) {
      return (data != null ? _ifrl0pdw.VerilyAppView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ioo44wgs.EvidenceUploadCleanupTask?>()) {
      return (data != null
              ? _ioo44wgs.EvidenceUploadCleanupTask.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iz4zjc1b.EvidenceUploadStatus?>()) {
      return (data != null
              ? _iz4zjc1b.EvidenceUploadStatus.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i59xm5p1.ModerationAuditView?>()) {
      return (data != null
              ? _i59xm5p1.ModerationAuditView.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iygcn9wp.ModerationCaseReviewView?>()) {
      return (data != null
              ? _iygcn9wp.ModerationCaseReviewView.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i7oivf7f.ModerationCaseStatusView?>()) {
      return (data != null
              ? _i7oivf7f.ModerationCaseStatusView.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iyph9n2p.PayoutWalletChallengeCleanupTask?>()) {
      return (data != null
              ? _iyph9n2p.PayoutWalletChallengeCleanupTask.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_icfglt50.PayoutWalletLinkChallengeView?>()) {
      return (data != null
              ? _icfglt50.PayoutWalletLinkChallengeView.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iqtp7i2n.PayoutWalletView?>()) {
      return (data != null ? _iqtp7i2n.PayoutWalletView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i3rw9wf5.RewardCluster?>()) {
      return (data != null ? _i3rw9wf5.RewardCluster.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ilrvghyo.RewardEndPlan?>()) {
      return (data != null ? _ilrvghyo.RewardEndPlan.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_in6hek74.RewardException?>()) {
      return (data != null ? _in6hek74.RewardException.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iyf1v3jl.RewardFundingPlan?>()) {
      return (data != null ? _iyf1v3jl.RewardFundingPlan.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iv4eta4e.RewardOutcome?>()) {
      return (data != null ? _iv4eta4e.RewardOutcome.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i3dio64d.RewardPayoutRecoveryTask?>()) {
      return (data != null
              ? _i3dio64d.RewardPayoutRecoveryTask.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_idfqmhge.RewardPayoutStatus?>()) {
      return (data != null ? _idfqmhge.RewardPayoutStatus.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_isxaon27.RewardPayoutTask?>()) {
      return (data != null ? _isxaon27.RewardPayoutTask.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ieggihqi.RewardPayoutView?>()) {
      return (data != null ? _ieggihqi.RewardPayoutView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iv8dpf52.RewardPoolStatus?>()) {
      return (data != null ? _iv8dpf52.RewardPoolStatus.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_if6e3cxh.RewardPoolView?>()) {
      return (data != null ? _if6e3cxh.RewardPoolView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i4sm4ipz.RewardProblem?>()) {
      return (data != null ? _i4sm4ipz.RewardProblem.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i9b5h2nk.RewardSummary?>()) {
      return (data != null ? _i9b5h2nk.RewardSummary.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iokaii94.RewardTermsDraft?>()) {
      return (data != null ? _iokaii94.RewardTermsDraft.fromJson(data) : null)
          as T;
    }
    if (t == List<_isc.UuidValue>) {
      return (data as List).map((e) => deserialize<_isc.UuidValue>(e)).toList()
          as T;
    }
    if (t == _isc.getType<List<_isc.UuidValue>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_isc.UuidValue>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_irayxhn9.ActionMotionSample>) {
      return (data as List)
              .map((e) => deserialize<_irayxhn9.ActionMotionSample>(e))
              .toList()
          as T;
    }
    if (t == _isc.getType<List<_irayxhn9.ActionMotionSample>?>()) {
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
    if (t == _isc.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
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
    if (t == List<_i6d3vqey.ActionTemplate>) {
      return (data as List)
              .map((e) => deserialize<_i6d3vqey.ActionTemplate>(e))
              .toList()
          as T;
    }
    if (t == List<_ijjtlylw.ActionOpportunity>) {
      return (data as List)
              .map((e) => deserialize<_ijjtlylw.ActionOpportunity>(e))
              .toList()
          as T;
    }
    if (t == List<_ir431rrk.ActionAttemptView>) {
      return (data as List)
              .map((e) => deserialize<_ir431rrk.ActionAttemptView>(e))
              .toList()
          as T;
    }
    if (t == List<_igtzj0f1.EvidenceAppealView>) {
      return (data as List)
              .map((e) => deserialize<_igtzj0f1.EvidenceAppealView>(e))
              .toList()
          as T;
    }
    if (t == List<_iyuppglq.EvidenceReviewQueueItem>) {
      return (data as List)
              .map((e) => deserialize<_iyuppglq.EvidenceReviewQueueItem>(e))
              .toList()
          as T;
    }
    if (t == List<_in92p10u.VerilyAppView>) {
      return (data as List)
              .map((e) => deserialize<_in92p10u.VerilyAppView>(e))
              .toList()
          as T;
    }
    if (t == List<_iw9760io.AppConfirmationView>) {
      return (data as List)
              .map((e) => deserialize<_iw9760io.AppConfirmationView>(e))
              .toList()
          as T;
    }
    if (t == List<_ie976x46.ModerationCaseStatusView>) {
      return (data as List)
              .map((e) => deserialize<_ie976x46.ModerationCaseStatusView>(e))
              .toList()
          as T;
    }
    if (t == List<_isztzkpq.RewardPayoutView>) {
      return (data as List)
              .map((e) => deserialize<_isztzkpq.RewardPayoutView>(e))
              .toList()
          as T;
    }
    try {
      return _iacc.Protocol().deserialize<T>(data, t);
    } on _isc.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _iaic.Protocol().deserialize<T>(data, t);
    } on _isc.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i7zadist.AccountClosureStatus => 'AccountClosureStatus',
      _iu22l7ek.ActionAttemptStatus => 'ActionAttemptStatus',
      _ixgg3yqh.ActionAttemptView => 'ActionAttemptView',
      _i8z355ak.ActionAuthoringException => 'ActionAuthoringException',
      _ifi47ne5.ActionAuthoringProblem => 'ActionAuthoringProblem',
      _idx11lej.ActionCaptureChallengeCleanupTask =>
        'ActionCaptureChallengeCleanupTask',
      _i55m67tr.ActionCaptureChallengeView => 'ActionCaptureChallengeView',
      _igizisql.ActionDefinitionStatus => 'ActionDefinitionStatus',
      _iqti045q.ActionDraftProposal => 'ActionDraftProposal',
      _ism88bqz.ActionDraftingUnavailableException =>
        'ActionDraftingUnavailableException',
      _iq3mdjhk.ActionEvidenceInput => 'ActionEvidenceInput',
      _i5b1uunc.ActionMotionAxis => 'ActionMotionAxis',
      _irayxhn9.ActionMotionSample => 'ActionMotionSample',
      _i6u7fweb.ActionMotionType => 'ActionMotionType',
      _im1lc214.ActionMovementKind => 'ActionMovementKind',
      _im9dc1is.ActionOpportunity => 'ActionOpportunity',
      _ixcs1xdh.ActionQrChallengeCleanupTask => 'ActionQrChallengeCleanupTask',
      _iqwh4ycl.ActionQrChallengeView => 'ActionQrChallengeView',
      _i45a1wjj.ActionRecurrence => 'ActionRecurrence',
      _ivobne24.ActionRequirementDraft => 'ActionRequirementDraft',
      _i55w548r.ActionRequirementKind => 'ActionRequirementKind',
      _icsa4634.ActionRequirementView => 'ActionRequirementView',
      _ifuw4tho.ActionSpokenChallengeCleanupTask =>
        'ActionSpokenChallengeCleanupTask',
      _iikyln3l.ActionSpokenChallengeView => 'ActionSpokenChallengeView',
      _i0iphegd.ActionTemplate => 'ActionTemplate',
      _i960u7rl.ActionVerificationPolicy => 'ActionVerificationPolicy',
      _i5yjywpf.CreateActionDefinitionRequest =>
        'CreateActionDefinitionRequest',
      _i90o7tud.EvidenceAppealStatus => 'EvidenceAppealStatus',
      _iy27rorb.EvidenceAppealView => 'EvidenceAppealView',
      _i5tayeq6.EvidenceDecisionStatus => 'EvidenceDecisionStatus',
      _i1gh041m.EvidenceProvenanceLevel => 'EvidenceProvenanceLevel',
      _i0mgpur2.EvidenceReviewQueueItem => 'EvidenceReviewQueueItem',
      _iy0z34jt.EvidenceSubmissionResult => 'EvidenceSubmissionResult',
      _i2k44lse.EvidenceVerificationJobStatus =>
        'EvidenceVerificationJobStatus',
      _in8wt7wh.EvidenceVerificationTask => 'EvidenceVerificationTask',
      _i9z86si9.MediaUploadConfirmation => 'MediaUploadConfirmation',
      _i05z8wlg.PayoutReviewView => 'PayoutReviewView',
      _ij8e0uwy.AiUsageStatus => 'AiUsageStatus',
      _ix5pwyym.AppConfirmationOutcome => 'AppConfirmationOutcome',
      _iqtml4wq.AppConfirmationView => 'AppConfirmationView',
      _i3krqelq.AppUnavailableException => 'AppUnavailableException',
      _iaui7d4n.VerilyAppCredential => 'VerilyAppCredential',
      _ipa8tni0.VerilyAppKeyView => 'VerilyAppKeyView',
      _ikihia57.VerilyAppLinkView => 'VerilyAppLinkView',
      _ibal4ihb.VerilyAppStatus => 'VerilyAppStatus',
      _ifrl0pdw.VerilyAppView => 'VerilyAppView',
      _ioo44wgs.EvidenceUploadCleanupTask => 'EvidenceUploadCleanupTask',
      _iz4zjc1b.EvidenceUploadStatus => 'EvidenceUploadStatus',
      _i59xm5p1.ModerationAuditView => 'ModerationAuditView',
      _iygcn9wp.ModerationCaseReviewView => 'ModerationCaseReviewView',
      _i7oivf7f.ModerationCaseStatusView => 'ModerationCaseStatusView',
      _iyph9n2p.PayoutWalletChallengeCleanupTask =>
        'PayoutWalletChallengeCleanupTask',
      _icfglt50.PayoutWalletLinkChallengeView =>
        'PayoutWalletLinkChallengeView',
      _iqtp7i2n.PayoutWalletView => 'PayoutWalletView',
      _i3rw9wf5.RewardCluster => 'RewardCluster',
      _ilrvghyo.RewardEndPlan => 'RewardEndPlan',
      _in6hek74.RewardException => 'RewardException',
      _iyf1v3jl.RewardFundingPlan => 'RewardFundingPlan',
      _iv4eta4e.RewardOutcome => 'RewardOutcome',
      _i3dio64d.RewardPayoutRecoveryTask => 'RewardPayoutRecoveryTask',
      _idfqmhge.RewardPayoutStatus => 'RewardPayoutStatus',
      _isxaon27.RewardPayoutTask => 'RewardPayoutTask',
      _ieggihqi.RewardPayoutView => 'RewardPayoutView',
      _iv8dpf52.RewardPoolStatus => 'RewardPoolStatus',
      _if6e3cxh.RewardPoolView => 'RewardPoolView',
      _i4sm4ipz.RewardProblem => 'RewardProblem',
      _i9b5h2nk.RewardSummary => 'RewardSummary',
      _iokaii94.RewardTermsDraft => 'RewardTermsDraft',
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
      case _i7zadist.AccountClosureStatus():
        return 'AccountClosureStatus';
      case _iu22l7ek.ActionAttemptStatus():
        return 'ActionAttemptStatus';
      case _ixgg3yqh.ActionAttemptView():
        return 'ActionAttemptView';
      case _i8z355ak.ActionAuthoringException():
        return 'ActionAuthoringException';
      case _ifi47ne5.ActionAuthoringProblem():
        return 'ActionAuthoringProblem';
      case _idx11lej.ActionCaptureChallengeCleanupTask():
        return 'ActionCaptureChallengeCleanupTask';
      case _i55m67tr.ActionCaptureChallengeView():
        return 'ActionCaptureChallengeView';
      case _igizisql.ActionDefinitionStatus():
        return 'ActionDefinitionStatus';
      case _iqti045q.ActionDraftProposal():
        return 'ActionDraftProposal';
      case _ism88bqz.ActionDraftingUnavailableException():
        return 'ActionDraftingUnavailableException';
      case _iq3mdjhk.ActionEvidenceInput():
        return 'ActionEvidenceInput';
      case _i5b1uunc.ActionMotionAxis():
        return 'ActionMotionAxis';
      case _irayxhn9.ActionMotionSample():
        return 'ActionMotionSample';
      case _i6u7fweb.ActionMotionType():
        return 'ActionMotionType';
      case _im1lc214.ActionMovementKind():
        return 'ActionMovementKind';
      case _im9dc1is.ActionOpportunity():
        return 'ActionOpportunity';
      case _ixcs1xdh.ActionQrChallengeCleanupTask():
        return 'ActionQrChallengeCleanupTask';
      case _iqwh4ycl.ActionQrChallengeView():
        return 'ActionQrChallengeView';
      case _i45a1wjj.ActionRecurrence():
        return 'ActionRecurrence';
      case _ivobne24.ActionRequirementDraft():
        return 'ActionRequirementDraft';
      case _i55w548r.ActionRequirementKind():
        return 'ActionRequirementKind';
      case _icsa4634.ActionRequirementView():
        return 'ActionRequirementView';
      case _ifuw4tho.ActionSpokenChallengeCleanupTask():
        return 'ActionSpokenChallengeCleanupTask';
      case _iikyln3l.ActionSpokenChallengeView():
        return 'ActionSpokenChallengeView';
      case _i0iphegd.ActionTemplate():
        return 'ActionTemplate';
      case _i960u7rl.ActionVerificationPolicy():
        return 'ActionVerificationPolicy';
      case _i5yjywpf.CreateActionDefinitionRequest():
        return 'CreateActionDefinitionRequest';
      case _i90o7tud.EvidenceAppealStatus():
        return 'EvidenceAppealStatus';
      case _iy27rorb.EvidenceAppealView():
        return 'EvidenceAppealView';
      case _i5tayeq6.EvidenceDecisionStatus():
        return 'EvidenceDecisionStatus';
      case _i1gh041m.EvidenceProvenanceLevel():
        return 'EvidenceProvenanceLevel';
      case _i0mgpur2.EvidenceReviewQueueItem():
        return 'EvidenceReviewQueueItem';
      case _iy0z34jt.EvidenceSubmissionResult():
        return 'EvidenceSubmissionResult';
      case _i2k44lse.EvidenceVerificationJobStatus():
        return 'EvidenceVerificationJobStatus';
      case _in8wt7wh.EvidenceVerificationTask():
        return 'EvidenceVerificationTask';
      case _i9z86si9.MediaUploadConfirmation():
        return 'MediaUploadConfirmation';
      case _i05z8wlg.PayoutReviewView():
        return 'PayoutReviewView';
      case _ij8e0uwy.AiUsageStatus():
        return 'AiUsageStatus';
      case _ix5pwyym.AppConfirmationOutcome():
        return 'AppConfirmationOutcome';
      case _iqtml4wq.AppConfirmationView():
        return 'AppConfirmationView';
      case _i3krqelq.AppUnavailableException():
        return 'AppUnavailableException';
      case _iaui7d4n.VerilyAppCredential():
        return 'VerilyAppCredential';
      case _ipa8tni0.VerilyAppKeyView():
        return 'VerilyAppKeyView';
      case _ikihia57.VerilyAppLinkView():
        return 'VerilyAppLinkView';
      case _ibal4ihb.VerilyAppStatus():
        return 'VerilyAppStatus';
      case _ifrl0pdw.VerilyAppView():
        return 'VerilyAppView';
      case _ioo44wgs.EvidenceUploadCleanupTask():
        return 'EvidenceUploadCleanupTask';
      case _iz4zjc1b.EvidenceUploadStatus():
        return 'EvidenceUploadStatus';
      case _i59xm5p1.ModerationAuditView():
        return 'ModerationAuditView';
      case _iygcn9wp.ModerationCaseReviewView():
        return 'ModerationCaseReviewView';
      case _i7oivf7f.ModerationCaseStatusView():
        return 'ModerationCaseStatusView';
      case _iyph9n2p.PayoutWalletChallengeCleanupTask():
        return 'PayoutWalletChallengeCleanupTask';
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
      case _i3dio64d.RewardPayoutRecoveryTask():
        return 'RewardPayoutRecoveryTask';
      case _idfqmhge.RewardPayoutStatus():
        return 'RewardPayoutStatus';
      case _isxaon27.RewardPayoutTask():
        return 'RewardPayoutTask';
      case _ieggihqi.RewardPayoutView():
        return 'RewardPayoutView';
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
    }
    className = _iacc.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
    }
    className = _iaic.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'AccountClosureStatus') {
      return deserialize<_i7zadist.AccountClosureStatus>(data['data']);
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
    if (dataClassName == 'ActionCaptureChallengeCleanupTask') {
      return deserialize<_idx11lej.ActionCaptureChallengeCleanupTask>(
        data['data'],
      );
    }
    if (dataClassName == 'ActionCaptureChallengeView') {
      return deserialize<_i55m67tr.ActionCaptureChallengeView>(data['data']);
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
    if (dataClassName == 'ActionEvidenceInput') {
      return deserialize<_iq3mdjhk.ActionEvidenceInput>(data['data']);
    }
    if (dataClassName == 'ActionMotionAxis') {
      return deserialize<_i5b1uunc.ActionMotionAxis>(data['data']);
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
    if (dataClassName == 'ActionQrChallengeCleanupTask') {
      return deserialize<_ixcs1xdh.ActionQrChallengeCleanupTask>(data['data']);
    }
    if (dataClassName == 'ActionQrChallengeView') {
      return deserialize<_iqwh4ycl.ActionQrChallengeView>(data['data']);
    }
    if (dataClassName == 'ActionRecurrence') {
      return deserialize<_i45a1wjj.ActionRecurrence>(data['data']);
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
    if (dataClassName == 'CreateActionDefinitionRequest') {
      return deserialize<_i5yjywpf.CreateActionDefinitionRequest>(data['data']);
    }
    if (dataClassName == 'EvidenceAppealStatus') {
      return deserialize<_i90o7tud.EvidenceAppealStatus>(data['data']);
    }
    if (dataClassName == 'EvidenceAppealView') {
      return deserialize<_iy27rorb.EvidenceAppealView>(data['data']);
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
    if (dataClassName == 'EvidenceVerificationJobStatus') {
      return deserialize<_i2k44lse.EvidenceVerificationJobStatus>(data['data']);
    }
    if (dataClassName == 'EvidenceVerificationTask') {
      return deserialize<_in8wt7wh.EvidenceVerificationTask>(data['data']);
    }
    if (dataClassName == 'MediaUploadConfirmation') {
      return deserialize<_i9z86si9.MediaUploadConfirmation>(data['data']);
    }
    if (dataClassName == 'PayoutReviewView') {
      return deserialize<_i05z8wlg.PayoutReviewView>(data['data']);
    }
    if (dataClassName == 'AiUsageStatus') {
      return deserialize<_ij8e0uwy.AiUsageStatus>(data['data']);
    }
    if (dataClassName == 'AppConfirmationOutcome') {
      return deserialize<_ix5pwyym.AppConfirmationOutcome>(data['data']);
    }
    if (dataClassName == 'AppConfirmationView') {
      return deserialize<_iqtml4wq.AppConfirmationView>(data['data']);
    }
    if (dataClassName == 'AppUnavailableException') {
      return deserialize<_i3krqelq.AppUnavailableException>(data['data']);
    }
    if (dataClassName == 'VerilyAppCredential') {
      return deserialize<_iaui7d4n.VerilyAppCredential>(data['data']);
    }
    if (dataClassName == 'VerilyAppKeyView') {
      return deserialize<_ipa8tni0.VerilyAppKeyView>(data['data']);
    }
    if (dataClassName == 'VerilyAppLinkView') {
      return deserialize<_ikihia57.VerilyAppLinkView>(data['data']);
    }
    if (dataClassName == 'VerilyAppStatus') {
      return deserialize<_ibal4ihb.VerilyAppStatus>(data['data']);
    }
    if (dataClassName == 'VerilyAppView') {
      return deserialize<_ifrl0pdw.VerilyAppView>(data['data']);
    }
    if (dataClassName == 'EvidenceUploadCleanupTask') {
      return deserialize<_ioo44wgs.EvidenceUploadCleanupTask>(data['data']);
    }
    if (dataClassName == 'EvidenceUploadStatus') {
      return deserialize<_iz4zjc1b.EvidenceUploadStatus>(data['data']);
    }
    if (dataClassName == 'ModerationAuditView') {
      return deserialize<_i59xm5p1.ModerationAuditView>(data['data']);
    }
    if (dataClassName == 'ModerationCaseReviewView') {
      return deserialize<_iygcn9wp.ModerationCaseReviewView>(data['data']);
    }
    if (dataClassName == 'ModerationCaseStatusView') {
      return deserialize<_i7oivf7f.ModerationCaseStatusView>(data['data']);
    }
    if (dataClassName == 'PayoutWalletChallengeCleanupTask') {
      return deserialize<_iyph9n2p.PayoutWalletChallengeCleanupTask>(
        data['data'],
      );
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
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _iacc.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _iaic.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _iacc.Protocol().registerHostProtocol('verily', this);
    _iaic.Protocol().registerHostProtocol('verily', this);
  }

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
      return _iacc.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _iaic.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
