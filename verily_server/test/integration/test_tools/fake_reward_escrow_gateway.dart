import 'dart:convert';
import 'dart:typed_data';

import 'package:bs58/bs58.dart';
import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/rewards/reward_configuration.dart';
import 'package:verily_server/src/rewards/reward_escrow_gateway.dart';
import 'package:verily_server/src/rewards/reward_payout_service.dart';

import 'serverpod_test_tools.dart';
import 'verily_fixtures.dart';

/// What [FakeRewardEscrowGateway.readEscrow] reports.
enum FakeEscrowReadMode {
  /// No escrow account exists at the derived address.
  missing,

  /// The escrow matches the pool exactly, unless [FakeRewardEscrowGateway]
  /// has a tamper function set.
  matching,
}

/// One scripted reply to a release: an outcome, or an error to throw.
typedef FakeReleaseStep = RewardReleaseOutcome Function();

/// An in-memory escrow that never touches a chain.
///
/// Addresses are deterministic hashes, reads mirror the pool row (optionally
/// tampered field by field), releases follow a script and then succeed, and a
/// per-pool released bitmap answers retries the way the program does: a
/// second release of a paid index reports [RewardAlreadyReleased].
class FakeRewardEscrowGateway implements RewardEscrowGateway {
  FakeRewardEscrowGateway({this.available = true});

  bool available;
  FakeEscrowReadMode readMode = FakeEscrowReadMode.matching;

  /// Applied to the matching state before it is returned.
  RewardEscrowAccountState Function(RewardEscrowAccountState state)? tamper;

  /// Replies consumed in order by [releasePayout]; empty means success.
  final releaseScript = <FakeReleaseStep>[];

  /// When set, [isPayoutReleased] throws it.
  Exception? bitmapError;

  final _released = <UuidValue, Set<int>>{};
  final releaseCalls =
      <({UuidValue poolId, int payoutIndex, String recipientWallet})>[];
  int readCount = 0;
  int bitmapReadCount = 0;
  int openTransactionCount = 0;
  int endTransactionCount = 0;

  /// Marks [payoutIndex] paid on chain without a release call, as if an
  /// earlier, lost release had landed.
  void markReleased(UuidValue poolId, int payoutIndex) =>
      _released.putIfAbsent(poolId, () => <int>{}).add(payoutIndex);

  bool isReleased(UuidValue poolId, int payoutIndex) =>
      _released[poolId]?.contains(payoutIndex) ?? false;

  @override
  bool get isAvailable => available;

  @override
  String arbiterAddress(RewardCluster cluster) =>
      fakeAddress(['fake-arbiter', cluster.name]);

  @override
  String deriveEscrowAddress({
    required RewardCluster cluster,
    required String creatorWallet,
    required UuidValue poolId,
  }) => fakeAddress([
    'fake-escrow',
    cluster.name,
    creatorWallet,
    poolId.toString(),
  ]);

  @override
  Future<String> buildOpenEscrowTransaction(RewardPool pool) async {
    openTransactionCount += 1;
    return base64Encode(utf8.encode('OpenEscrow:${pool.id}'));
  }

  @override
  Future<String> buildEndEarlyTransaction(RewardPool pool) async {
    endTransactionCount += 1;
    return base64Encode(utf8.encode('EndEarly:${pool.id}'));
  }

  @override
  Future<RewardEscrowAccountState?> readEscrow(RewardPool pool) async {
    readCount += 1;
    if (readMode == FakeEscrowReadMode.missing) return null;
    final state = matchingEscrowState(pool);
    return tamper == null ? state : tamper!(state);
  }

  @override
  Future<RewardReleaseOutcome> releasePayout({
    required RewardPool pool,
    required int payoutIndex,
    required String recipientWallet,
  }) async {
    releaseCalls.add((
      poolId: pool.id!,
      payoutIndex: payoutIndex,
      recipientWallet: recipientWallet,
    ));
    if (releaseScript.isNotEmpty) {
      final outcome = releaseScript.removeAt(0)();
      if (outcome is RewardReleased) markReleased(pool.id!, payoutIndex);
      return outcome;
    }
    if (isReleased(pool.id!, payoutIndex)) {
      return const RewardAlreadyReleased();
    }
    markReleased(pool.id!, payoutIndex);
    return RewardReleased(fakeSignature('release-${pool.id}-$payoutIndex'));
  }

  @override
  Future<bool> isPayoutReleased({
    required RewardPool pool,
    required int payoutIndex,
  }) async {
    bitmapReadCount += 1;
    if (bitmapError case final error?) throw error;
    return isReleased(pool.id!, payoutIndex);
  }
}

/// The escrow state that matches [pool] in every checked field.
RewardEscrowAccountState matchingEscrowState(RewardPool pool) =>
    RewardEscrowAccountState(
      escrowAddress: pool.escrowAddress!,
      ownedByEscrowProgram: true,
      creator: pool.creatorWallet!,
      arbiter: pool.arbiterAddress!,
      mint: pool.mint,
      poolId: pool.id!,
      amountPerPayout: pool.amountPerPayout,
      maxPayouts: pool.maxPayouts,
      releasedCount: 0,
      expiresAt: pool.expiresAt,
      refundAfter: pool.refundAfter,
      refundDelaySeconds: pool.refundDelaySeconds,
      vaultBalance: pool.amountPerPayout * pool.maxPayouts,
    );

/// [state] with one field changed, so funding sees exactly one mismatch.
RewardEscrowAccountState escrowStateWith(
  RewardEscrowAccountState state, {
  bool? ownedByEscrowProgram,
  String? escrowAddress,
  String? creator,
  String? arbiter,
  String? mint,
  UuidValue? poolId,
  int? amountPerPayout,
  int? maxPayouts,
  int? releasedCount,
  DateTime? expiresAt,
  DateTime? refundAfter,
  int? refundDelaySeconds,
  int? vaultBalance,
}) => RewardEscrowAccountState(
  escrowAddress: escrowAddress ?? state.escrowAddress,
  ownedByEscrowProgram: ownedByEscrowProgram ?? state.ownedByEscrowProgram,
  creator: creator ?? state.creator,
  arbiter: arbiter ?? state.arbiter,
  mint: mint ?? state.mint,
  poolId: poolId ?? state.poolId,
  amountPerPayout: amountPerPayout ?? state.amountPerPayout,
  maxPayouts: maxPayouts ?? state.maxPayouts,
  releasedCount: releasedCount ?? state.releasedCount,
  expiresAt: expiresAt ?? state.expiresAt,
  refundAfter: refundAfter ?? state.refundAfter,
  refundDelaySeconds: refundDelaySeconds ?? state.refundDelaySeconds,
  vaultBalance: vaultBalance ?? state.vaultBalance,
);

/// Records every release the payout service schedules, instead of creating
/// a future call.
class RecordingRewardPayoutScheduler implements RewardPayoutScheduler {
  final scheduled = <({UuidValue payoutId, Duration delay})>[];

  @override
  Future<void> schedule(
    Session session,
    UuidValue payoutId, {
    Duration delay = Duration.zero,
  }) async {
    scheduled.add((payoutId: payoutId, delay: delay));
  }
}

/// A deterministic base58 address derived from [parts].
String fakeAddress(List<String> parts) => base58.encode(
  Uint8List.fromList(sha256.convert(utf8.encode(parts.join('|'))).bytes),
);

/// A deterministic base58 64-byte signature derived from [seed].
String fakeSignature(String seed) {
  final first = sha256.convert(utf8.encode('$seed:0')).bytes;
  final second = sha256.convert(utf8.encode('$seed:1')).bytes;
  return base58.encode(Uint8List.fromList([...first, ...second]));
}

/// The process reward configuration for one test, using [gateway].
RewardConfiguration fakeRewardConfiguration(
  FakeRewardEscrowGateway gateway, {
  int reviewThresholdAtoms = defaultRewardReviewThresholdAtoms,
}) => RewardConfiguration(
  gateway: gateway,
  cluster: RewardCluster.devnet,
  reviewThresholdAtoms: reviewThresholdAtoms,
);

/// Reward terms that pass validation unless a bound is overridden.
RewardTermsDraft rewardTerms({
  int amountPerPayout = 1000000,
  int maxPayouts = 3,
  int maxWinsPerAccount = 1,
  Duration expiresIn = const Duration(days: 7),
  int refundDelayDays = 3,
}) => RewardTermsDraft(
  amountPerPayout: amountPerPayout,
  maxPayouts: maxPayouts,
  maxWinsPerAccount: maxWinsPerAccount,
  expiresAt: DateTime.now().toUtc().add(expiresIn),
  refundDelayDays: refundDelayDays,
);

/// Saves a rewarded location action as [creator], funds its escrow through
/// the fake gateway, and publishes it. The creator must have a linked
/// payout wallet.
Future<ActionOpportunity> fundedRewardAction(
  TestEndpoints endpoints,
  TestSessionBuilder creator, {
  required String actionKey,
  required RewardTermsDraft reward,
  int? maxVerifiedCompletions,
}) async {
  final draft = await endpoints.actionVerification.saveActionDraft(
    creator,
    actionRequest(
      actionKey: actionKey,
      requirements: [locationRequirement()],
      maxVerifiedCompletions: maxVerifiedCompletions,
      reward: reward,
    ),
  );
  await endpoints.rewards.prepareRewardFunding(creator, actionId: draft.id);
  await endpoints.rewards.confirmRewardFunding(
    creator,
    actionId: draft.id,
    signature: fakeSignature('fund-$actionKey'),
  );
  return endpoints.actionVerification.publishAction(
    creator,
    actionId: draft.id,
    expectedRevision: draft.revision,
  );
}

/// Starts an attempt on [action] and submits an accepted location check-in,
/// leaving the attempt ready to complete.
Future<ActionAttemptView> readyLocationAttempt(
  TestEndpoints endpoints,
  TestSessionBuilder participant, {
  required ActionOpportunity action,
  required String idempotencyKey,
}) async {
  final attempt = await endpoints.actionVerification.beginAttempt(
    participant,
    actionId: action.id,
    idempotencyKey: idempotencyKey,
  );
  final requirement = action.requirements.single;
  final result = await endpoints.actionVerification.submitEvidence(
    participant,
    ActionEvidenceInput(
      attemptId: attempt.id,
      requirementId: requirement.id,
      capturedAt: DateTime.now().toUtc(),
      latitude: requirement.latitude,
      longitude: requirement.longitude,
      accuracyMeters: 10,
    ),
  );
  if (result.status != EvidenceDecisionStatus.accepted) {
    throw StateError('Fixture location proof was ${result.status}.');
  }
  return result.attempt;
}

/// [readyLocationAttempt], then completion through the endpoint.
Future<ActionAttemptView> completedLocationAttempt(
  TestEndpoints endpoints,
  TestSessionBuilder participant, {
  required ActionOpportunity action,
  required String idempotencyKey,
}) async {
  final attempt = await readyLocationAttempt(
    endpoints,
    participant,
    action: action,
    idempotencyKey: idempotencyKey,
  );
  return endpoints.actionVerification.completeAttempt(participant, attempt.id);
}
