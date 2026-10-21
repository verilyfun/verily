/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: depend_on_referenced_packages

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _ida;

import 'package:clock/clock.dart' as _io0w16m8;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:verily_server/src/generated/action_verification/action_capture_challenge_cleanup_task.dart'
    as _issjjjw3;
import 'package:verily_server/src/generated/action_verification/action_qr_challenge_cleanup_task.dart'
    as _iyeohdwe;
import 'package:verily_server/src/generated/action_verification/action_spoken_challenge_cleanup_task.dart'
    as _i7i84atq;
import 'package:verily_server/src/generated/action_verification/evidence_verification_recovery_task.dart'
    as _ikmo5pl9;
import 'package:verily_server/src/generated/action_verification/evidence_verification_task.dart'
    as _ip06q9f7;
import 'package:verily_server/src/generated/apps/app_pull_check_recovery_task.dart'
    as _i0i951jb;
import 'package:verily_server/src/generated/apps/app_pull_check_task.dart'
    as _ips0vmbg;
import 'package:verily_server/src/generated/apps/linking/app_link_code_cleanup_task.dart'
    as _i3ew32yk;
import 'package:verily_server/src/generated/apps/webhooks/app_event_delivery_task.dart'
    as _ib4x2pmw;
import 'package:verily_server/src/generated/apps/webhooks/app_event_recovery_task.dart'
    as _i8h368fz;
import 'package:verily_server/src/generated/evidence_storage/evidence_upload_cleanup_task.dart'
    as _ivz1brjg;
import 'package:verily_server/src/generated/rewards/payout_wallet_challenge_cleanup_task.dart'
    as _iqy68f9e;
import 'package:verily_server/src/generated/rewards/reward_payout_recovery_task.dart'
    as _iii6pmpe;
import 'package:verily_server/src/generated/rewards/reward_payout_task.dart'
    as _iiiev0wf;
import 'package:verily_server/src/generated/verification_requests/verification_request_expiry_task.dart'
    as _iqe2qini;

import '../action_verification/action_capture_challenge_cleanup_future_call.dart'
    as _iw89bc2u;
import '../action_verification/action_qr_challenge_cleanup_future_call.dart'
    as _ib19nitc;
import '../action_verification/action_spoken_challenge_cleanup_future_call.dart'
    as _iggymanc;
import '../action_verification/evidence_verification_future_call.dart'
    as _i83aqavm;
import '../action_verification/evidence_verification_recovery_future_call.dart'
    as _in13zbxq;
import '../apps/app_pull_check_future_call.dart' as _iqchdy97;
import '../apps/app_pull_check_recovery_future_call.dart' as _if68ir6f;
import '../apps/linking/app_link_code_cleanup_future_call.dart' as _iy0se1pt;
import '../apps/webhooks/app_event_delivery_future_call.dart' as _i7b8o1r5;
import '../apps/webhooks/app_event_recovery_future_call.dart' as _iaeafu7l;
import '../evidence_storage/evidence_upload_cleanup_future_call.dart'
    as _ig2i46m2;
import '../rewards/payout_wallet_challenge_cleanup_future_call.dart'
    as _i1jnm1ox;
import '../rewards/reward_payout_future_call.dart' as _i5op9hs9;
import '../rewards/reward_payout_recovery_future_call.dart' as _i5te3c5b;
import '../verification_requests/verification_request_expiry_future_call.dart'
    as _i1cws02m;

/// Invokes a future call.
typedef _InvokeFutureCall = Future<void> Function(
  String name,
  _is.SerializableModel? object,
);

extension ServerpodFutureCallsGetter on _is.Serverpod {
  /// Generated future calls.
  FutureCalls get futureCalls => FutureCalls();
}

class FutureCalls extends _is.FutureCallDispatch<_FutureCallRef> {
  FutureCalls._();

  factory FutureCalls() {
    return _instance;
  }

  static final FutureCalls _instance = FutureCalls._();

  _is.FutureCallManager? _futureCallManager;

  String? _serverId;

  String get _effectiveServerId {
    if (_serverId == null) {
      throw StateError('FutureCalls is not initialized.');
    }
    return _serverId!;
  }

  _is.FutureCallManager get _effectiveFutureCallManager {
    if (_futureCallManager == null) {
      throw StateError('FutureCalls is not initialized.');
    }
    return _futureCallManager!;
  }

  @override
  void initialize(
    _is.FutureCallManager futureCallManager,
    String serverId,
  ) {
    var registeredFutureCalls = <String, _is.InvokableFutureCall>{
      'ActionCaptureChallengeCleanupCleanupFutureCall':
          ActionCaptureChallengeCleanupCleanupFutureCall(),
      'ActionQrChallengeCleanupCleanupFutureCall':
          ActionQrChallengeCleanupCleanupFutureCall(),
      'ActionSpokenChallengeCleanupCleanupFutureCall':
          ActionSpokenChallengeCleanupCleanupFutureCall(),
      'EvidenceVerificationVerifyFutureCall':
          EvidenceVerificationVerifyFutureCall(),
      'EvidenceVerificationRecoveryRecoverFutureCall':
          EvidenceVerificationRecoveryRecoverFutureCall(),
      'AppPullCheckCheckFutureCall': AppPullCheckCheckFutureCall(),
      'AppPullCheckRecoveryRecoverFutureCall':
          AppPullCheckRecoveryRecoverFutureCall(),
      'AppLinkCodeCleanupCleanupFutureCall':
          AppLinkCodeCleanupCleanupFutureCall(),
      'AppEventDeliveryDeliverFutureCall': AppEventDeliveryDeliverFutureCall(),
      'AppEventRecoveryRecoverFutureCall': AppEventRecoveryRecoverFutureCall(),
      'EvidenceUploadCleanupCleanupFutureCall':
          EvidenceUploadCleanupCleanupFutureCall(),
      'PayoutWalletChallengeCleanupCleanupFutureCall':
          PayoutWalletChallengeCleanupCleanupFutureCall(),
      'RewardPayoutReleaseFutureCall': RewardPayoutReleaseFutureCall(),
      'RewardPayoutRecoveryRecoverFutureCall':
          RewardPayoutRecoveryRecoverFutureCall(),
      'VerificationRequestExpiryExpireFutureCall':
          VerificationRequestExpiryExpireFutureCall(),
    };
    _futureCallManager = futureCallManager;
    _serverId = serverId;
    for (final entry in registeredFutureCalls.entries) {
      _futureCallManager?.registerFutureCall(entry.value, entry.key);
    }
  }

  @override
  _FutureCallRef callAtTime(
    DateTime time, {
    String? identifier,
  }) {
    return _FutureCallRef(
      (name, object) {
        return _effectiveFutureCallManager.scheduleFutureCall(
          name,
          object,
          time,
          _effectiveServerId,
          identifier,
        );
      },
    );
  }

  @override
  _FutureCallRef callWithDelay(
    Duration delay, {
    String? identifier,
  }) {
    return _FutureCallRef(
      (name, object) {
        return _effectiveFutureCallManager.scheduleFutureCall(
          name,
          object,
          DateTime.now().toUtc().add(delay),
          _effectiveServerId,
          identifier,
        );
      },
    );
  }

  @override
  _is.RecurringFutureCallDispatch<_FutureCallRef> callRecurring({
    String? identifier,
  }) {
    return _RecurringFutureCallDispatchImpl(
      _effectiveFutureCallManager,
      _effectiveServerId,
      identifier,
    );
  }

  @override
  Future<void> cancel(String identifier) async {
    await _effectiveFutureCallManager.cancelFutureCall(identifier);
  }
}

class _RecurringFutureCallDispatchImpl
    extends _is.RecurringFutureCallDispatch<_FutureCallRef> {
  _RecurringFutureCallDispatchImpl(
    this._futureCallManager,
    this._serverId,
    this._identifier,
  );

  final _is.FutureCallManager _futureCallManager;

  final String _serverId;

  final String? _identifier;

  @override
  _FutureCallRef cron(String cronExpression) {
    return _FutureCallRef(
      (name, object) {
        return _futureCallManager.scheduleFutureCall(
          name,
          object,
          _is.Cron.parse(cronExpression).nextTime(),
          _serverId,
          _identifier,
          scheduling: _is.CronFutureCallScheduling(cron: cronExpression),
        );
      },
    );
  }

  @override
  _FutureCallRef every(
    Duration interval, {
    DateTime? start,
  }) {
    final now = _io0w16m8.clock.now().toUtc();
    return _FutureCallRef(
      (name, object) {
        return _futureCallManager.scheduleFutureCall(
          name,
          object,
          start ?? now.add(interval),
          _serverId,
          _identifier,
          scheduling: _is.IntervalFutureCallScheduling(
            interval: interval,
            start: start,
          ),
        );
      },
    );
  }
}

class _FutureCallRef {
  _FutureCallRef(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  late final actionCaptureChallengeCleanup =
      _ActionCaptureChallengeCleanupFutureCallDispatcher(_invokeFutureCall);

  late final actionQrChallengeCleanup =
      _ActionQrChallengeCleanupFutureCallDispatcher(_invokeFutureCall);

  late final actionSpokenChallengeCleanup =
      _ActionSpokenChallengeCleanupFutureCallDispatcher(_invokeFutureCall);

  late final evidenceVerification = _EvidenceVerificationFutureCallDispatcher(
    _invokeFutureCall,
  );

  late final evidenceVerificationRecovery =
      _EvidenceVerificationRecoveryFutureCallDispatcher(_invokeFutureCall);

  late final appPullCheck = _AppPullCheckFutureCallDispatcher(
    _invokeFutureCall,
  );

  late final appPullCheckRecovery = _AppPullCheckRecoveryFutureCallDispatcher(
    _invokeFutureCall,
  );

  late final appLinkCodeCleanup = _AppLinkCodeCleanupFutureCallDispatcher(
    _invokeFutureCall,
  );

  late final appEventDelivery = _AppEventDeliveryFutureCallDispatcher(
    _invokeFutureCall,
  );

  late final appEventRecovery = _AppEventRecoveryFutureCallDispatcher(
    _invokeFutureCall,
  );

  late final evidenceUploadCleanup = _EvidenceUploadCleanupFutureCallDispatcher(
    _invokeFutureCall,
  );

  late final payoutWalletChallengeCleanup =
      _PayoutWalletChallengeCleanupFutureCallDispatcher(_invokeFutureCall);

  late final rewardPayout = _RewardPayoutFutureCallDispatcher(
    _invokeFutureCall,
  );

  late final rewardPayoutRecovery = _RewardPayoutRecoveryFutureCallDispatcher(
    _invokeFutureCall,
  );

  late final verificationRequestExpiry =
      _VerificationRequestExpiryFutureCallDispatcher(_invokeFutureCall);
}

class _ActionCaptureChallengeCleanupFutureCallDispatcher {
  _ActionCaptureChallengeCleanupFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> cleanup(_issjjjw3.ActionCaptureChallengeCleanupTask task) {
    return _invokeFutureCall(
      'ActionCaptureChallengeCleanupCleanupFutureCall',
      task,
    );
  }
}

class _ActionQrChallengeCleanupFutureCallDispatcher {
  _ActionQrChallengeCleanupFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> cleanup(_iyeohdwe.ActionQrChallengeCleanupTask task) {
    return _invokeFutureCall(
      'ActionQrChallengeCleanupCleanupFutureCall',
      task,
    );
  }
}

class _ActionSpokenChallengeCleanupFutureCallDispatcher {
  _ActionSpokenChallengeCleanupFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> cleanup(_i7i84atq.ActionSpokenChallengeCleanupTask task) {
    return _invokeFutureCall(
      'ActionSpokenChallengeCleanupCleanupFutureCall',
      task,
    );
  }
}

class _EvidenceVerificationFutureCallDispatcher {
  _EvidenceVerificationFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> verify(_ip06q9f7.EvidenceVerificationTask task) {
    return _invokeFutureCall(
      'EvidenceVerificationVerifyFutureCall',
      task,
    );
  }
}

class _EvidenceVerificationRecoveryFutureCallDispatcher {
  _EvidenceVerificationRecoveryFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> recover(_ikmo5pl9.EvidenceVerificationRecoveryTask task) {
    return _invokeFutureCall(
      'EvidenceVerificationRecoveryRecoverFutureCall',
      task,
    );
  }
}

class _AppPullCheckFutureCallDispatcher {
  _AppPullCheckFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> check(_ips0vmbg.AppPullCheckTask task) {
    return _invokeFutureCall(
      'AppPullCheckCheckFutureCall',
      task,
    );
  }
}

class _AppPullCheckRecoveryFutureCallDispatcher {
  _AppPullCheckRecoveryFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> recover(_i0i951jb.AppPullCheckRecoveryTask task) {
    return _invokeFutureCall(
      'AppPullCheckRecoveryRecoverFutureCall',
      task,
    );
  }
}

class _AppLinkCodeCleanupFutureCallDispatcher {
  _AppLinkCodeCleanupFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> cleanup(_i3ew32yk.AppLinkCodeCleanupTask task) {
    return _invokeFutureCall(
      'AppLinkCodeCleanupCleanupFutureCall',
      task,
    );
  }
}

class _AppEventDeliveryFutureCallDispatcher {
  _AppEventDeliveryFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> deliver(_ib4x2pmw.AppEventDeliveryTask task) {
    return _invokeFutureCall(
      'AppEventDeliveryDeliverFutureCall',
      task,
    );
  }
}

class _AppEventRecoveryFutureCallDispatcher {
  _AppEventRecoveryFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> recover(_i8h368fz.AppEventRecoveryTask task) {
    return _invokeFutureCall(
      'AppEventRecoveryRecoverFutureCall',
      task,
    );
  }
}

class _EvidenceUploadCleanupFutureCallDispatcher {
  _EvidenceUploadCleanupFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> cleanup(_ivz1brjg.EvidenceUploadCleanupTask task) {
    return _invokeFutureCall(
      'EvidenceUploadCleanupCleanupFutureCall',
      task,
    );
  }
}

class _PayoutWalletChallengeCleanupFutureCallDispatcher {
  _PayoutWalletChallengeCleanupFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> cleanup(_iqy68f9e.PayoutWalletChallengeCleanupTask task) {
    return _invokeFutureCall(
      'PayoutWalletChallengeCleanupCleanupFutureCall',
      task,
    );
  }
}

class _RewardPayoutFutureCallDispatcher {
  _RewardPayoutFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> release(_iiiev0wf.RewardPayoutTask task) {
    return _invokeFutureCall(
      'RewardPayoutReleaseFutureCall',
      task,
    );
  }
}

class _RewardPayoutRecoveryFutureCallDispatcher {
  _RewardPayoutRecoveryFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> recover(_iii6pmpe.RewardPayoutRecoveryTask task) {
    return _invokeFutureCall(
      'RewardPayoutRecoveryRecoverFutureCall',
      task,
    );
  }
}

class _VerificationRequestExpiryFutureCallDispatcher {
  _VerificationRequestExpiryFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> expire(_iqe2qini.VerificationRequestExpiryTask task) {
    return _invokeFutureCall(
      'VerificationRequestExpiryExpireFutureCall',
      task,
    );
  }
}

class ActionCaptureChallengeCleanupCleanupFutureCall
    extends _is.FutureCall<_issjjjw3.ActionCaptureChallengeCleanupTask>
    implements
        _is.InvokableFutureCall<_issjjjw3.ActionCaptureChallengeCleanupTask> {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _issjjjw3.ActionCaptureChallengeCleanupTask? task,
  ) async {
    await _iw89bc2u.ActionCaptureChallengeCleanupFutureCall().cleanup(
      session,
      task!,
    );
  }
}

class ActionQrChallengeCleanupCleanupFutureCall
    extends _is.FutureCall<_iyeohdwe.ActionQrChallengeCleanupTask>
    implements _is.InvokableFutureCall<_iyeohdwe.ActionQrChallengeCleanupTask> {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _iyeohdwe.ActionQrChallengeCleanupTask? task,
  ) async {
    await _ib19nitc.ActionQrChallengeCleanupFutureCall().cleanup(
      session,
      task!,
    );
  }
}

class ActionSpokenChallengeCleanupCleanupFutureCall
    extends _is.FutureCall<_i7i84atq.ActionSpokenChallengeCleanupTask>
    implements
        _is.InvokableFutureCall<_i7i84atq.ActionSpokenChallengeCleanupTask> {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _i7i84atq.ActionSpokenChallengeCleanupTask? task,
  ) async {
    await _iggymanc.ActionSpokenChallengeCleanupFutureCall().cleanup(
      session,
      task!,
    );
  }
}

class EvidenceVerificationVerifyFutureCall
    extends _is.FutureCall<_ip06q9f7.EvidenceVerificationTask>
    implements _is.InvokableFutureCall<_ip06q9f7.EvidenceVerificationTask> {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _ip06q9f7.EvidenceVerificationTask? task,
  ) async {
    await _i83aqavm.EvidenceVerificationFutureCall().verify(
      session,
      task!,
    );
  }
}

class EvidenceVerificationRecoveryRecoverFutureCall
    extends _is.FutureCall<_ikmo5pl9.EvidenceVerificationRecoveryTask>
    implements
        _is.InvokableFutureCall<_ikmo5pl9.EvidenceVerificationRecoveryTask> {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _ikmo5pl9.EvidenceVerificationRecoveryTask? task,
  ) async {
    await _in13zbxq.EvidenceVerificationRecoveryFutureCall().recover(
      session,
      task!,
    );
  }
}

class AppPullCheckCheckFutureCall
    extends _is.FutureCall<_ips0vmbg.AppPullCheckTask>
    implements _is.InvokableFutureCall<_ips0vmbg.AppPullCheckTask> {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _ips0vmbg.AppPullCheckTask? task,
  ) async {
    await _iqchdy97.AppPullCheckFutureCall().check(
      session,
      task!,
    );
  }
}

class AppPullCheckRecoveryRecoverFutureCall
    extends _is.FutureCall<_i0i951jb.AppPullCheckRecoveryTask>
    implements _is.InvokableFutureCall<_i0i951jb.AppPullCheckRecoveryTask> {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _i0i951jb.AppPullCheckRecoveryTask? task,
  ) async {
    await _if68ir6f.AppPullCheckRecoveryFutureCall().recover(
      session,
      task!,
    );
  }
}

class AppLinkCodeCleanupCleanupFutureCall
    extends _is.FutureCall<_i3ew32yk.AppLinkCodeCleanupTask>
    implements _is.InvokableFutureCall<_i3ew32yk.AppLinkCodeCleanupTask> {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _i3ew32yk.AppLinkCodeCleanupTask? task,
  ) async {
    await _iy0se1pt.AppLinkCodeCleanupFutureCall().cleanup(
      session,
      task!,
    );
  }
}

class AppEventDeliveryDeliverFutureCall
    extends _is.FutureCall<_ib4x2pmw.AppEventDeliveryTask>
    implements _is.InvokableFutureCall<_ib4x2pmw.AppEventDeliveryTask> {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _ib4x2pmw.AppEventDeliveryTask? task,
  ) async {
    await _i7b8o1r5.AppEventDeliveryFutureCall().deliver(
      session,
      task!,
    );
  }
}

class AppEventRecoveryRecoverFutureCall
    extends _is.FutureCall<_i8h368fz.AppEventRecoveryTask>
    implements _is.InvokableFutureCall<_i8h368fz.AppEventRecoveryTask> {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _i8h368fz.AppEventRecoveryTask? task,
  ) async {
    await _iaeafu7l.AppEventRecoveryFutureCall().recover(
      session,
      task!,
    );
  }
}

class EvidenceUploadCleanupCleanupFutureCall
    extends _is.FutureCall<_ivz1brjg.EvidenceUploadCleanupTask>
    implements _is.InvokableFutureCall<_ivz1brjg.EvidenceUploadCleanupTask> {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _ivz1brjg.EvidenceUploadCleanupTask? task,
  ) async {
    await _ig2i46m2.EvidenceUploadCleanupFutureCall().cleanup(
      session,
      task!,
    );
  }
}

class PayoutWalletChallengeCleanupCleanupFutureCall
    extends _is.FutureCall<_iqy68f9e.PayoutWalletChallengeCleanupTask>
    implements
        _is.InvokableFutureCall<_iqy68f9e.PayoutWalletChallengeCleanupTask> {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _iqy68f9e.PayoutWalletChallengeCleanupTask? task,
  ) async {
    await _i1jnm1ox.PayoutWalletChallengeCleanupFutureCall().cleanup(
      session,
      task!,
    );
  }
}

class RewardPayoutReleaseFutureCall
    extends _is.FutureCall<_iiiev0wf.RewardPayoutTask>
    implements _is.InvokableFutureCall<_iiiev0wf.RewardPayoutTask> {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _iiiev0wf.RewardPayoutTask? task,
  ) async {
    await _i5op9hs9.RewardPayoutFutureCall().release(
      session,
      task!,
    );
  }
}

class RewardPayoutRecoveryRecoverFutureCall
    extends _is.FutureCall<_iii6pmpe.RewardPayoutRecoveryTask>
    implements _is.InvokableFutureCall<_iii6pmpe.RewardPayoutRecoveryTask> {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _iii6pmpe.RewardPayoutRecoveryTask? task,
  ) async {
    await _i5te3c5b.RewardPayoutRecoveryFutureCall().recover(
      session,
      task!,
    );
  }
}

class VerificationRequestExpiryExpireFutureCall
    extends _is.FutureCall<_iqe2qini.VerificationRequestExpiryTask>
    implements
        _is.InvokableFutureCall<_iqe2qini.VerificationRequestExpiryTask> {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _iqe2qini.VerificationRequestExpiryTask? task,
  ) async {
    await _i1cws02m.VerificationRequestExpiryFutureCall().expire(
      session,
      task!,
    );
  }
}
