import 'dart:typed_data';

import 'package:hooks_riverpod/misc.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/account/account_repository.dart';
import 'package:verily_flutter/features/account/account_session.dart';
import 'package:verily_flutter/features/actions/action_repository.dart';
import 'package:verily_flutter/features/appeals/evidence_appeal_repository.dart';
import 'package:verily_flutter/features/review/evidence_review_repository.dart';
import 'package:verily_flutter/features/rewards/reward_repository.dart';
import 'package:verily_flutter/features/wallet/mobile_wallet.dart';

/// Fixtures and fakes for the Me, settings, review, and appeals screens.
/// Nothing here reaches a server or a plugin.

UuidValue testUuid(int n) => UuidValue.fromString(
  '00000000-0000-4000-8000-${n.toRadixString(16).padLeft(12, '0')}',
);

final fixtureNow = DateTime.utc(2026, 10, 21, 14);

/// A signed-in account with access to the review queue.
final testReviewerSession = AccountSession(
  authUserId: testUuid(1),
  scopes: const {evidenceReviewScope},
);

/// Overrides for every repository and service the Me slice reads. Anything
/// not passed gets an empty fake, so no screen reaches a server or plugin.
List<Override> meSliceOverrides({
  FakeActionRepository? actions,
  FakeRewardRepository? rewards,
  FakePayoutWalletRepository? wallets,
  FakeMobileWallet? wallet,
  FakeEvidenceAppealRepository? appeals,
  FakeEvidenceReviewRepository? reviews,
  FakeAccountRepository? accounts,
}) => [
  actionRepositoryProvider.overrideWithValue(
    actions ?? FakeActionRepository(),
  ),
  rewardRepositoryProvider.overrideWithValue(
    rewards ?? FakeRewardRepository(),
  ),
  payoutWalletRepositoryProvider.overrideWithValue(
    wallets ?? FakePayoutWalletRepository(),
  ),
  mobileWalletProvider.overrideWithValue(wallet ?? FakeMobileWallet()),
  evidenceAppealRepositoryProvider.overrideWithValue(
    appeals ?? FakeEvidenceAppealRepository(),
  ),
  evidenceReviewRepositoryProvider.overrideWithValue(
    reviews ?? FakeEvidenceReviewRepository(),
  ),
  accountRepositoryProvider.overrideWithValue(
    accounts ?? FakeAccountRepository(),
  ),
];

ActionAttemptView fakeAttempt({
  required int id,
  required int actionId,
  String? actionTitle,
  ActionAttemptStatus status = ActionAttemptStatus.collectingEvidence,
  RewardPayoutStatus? payoutStatus,
  RewardOutcome? rewardOutcome,
}) => ActionAttemptView(
  id: testUuid(id),
  actionDefinitionId: testUuid(actionId),
  actionTitle: actionTitle,
  periodKey: 'once',
  status: status,
  startedAt: fixtureNow,
  updatedAt: fixtureNow,
  payoutStatus: payoutStatus,
  rewardOutcome: rewardOutcome,
);

RewardPayoutView fakePayout({
  required int id,
  required String actionTitle,
  required RewardPayoutStatus status,
  int amount = 5000000,
}) => RewardPayoutView(
  id: testUuid(id),
  attemptId: testUuid(id + 100),
  actionTitle: actionTitle,
  cluster: RewardCluster.devnet,
  tokenSymbol: 'USDC',
  decimals: 6,
  amount: amount,
  status: status,
  createdAt: fixtureNow,
  updatedAt: fixtureNow,
  payableUntil: DateTime.utc(2026, 11, 20, 12),
);

EvidenceAppealView fakeAppeal({
  required int id,
  required int attemptId,
  EvidenceAppealStatus status = EvidenceAppealStatus.pending,
  String? resolutionNote,
  String? mediaUrl,
}) => EvidenceAppealView(
  id: testUuid(id),
  evidenceId: testUuid(id + 500),
  attemptId: testUuid(attemptId),
  actionTitle: 'Ten squats at the park',
  requirementTitle: 'Record your squats',
  requirementKind: ActionRequirementKind.video,
  reason: 'All ten squats are in the second half of the clip.',
  status: status,
  createdAt: fixtureNow,
  resolutionNote: resolutionNote,
  mediaUrl: mediaUrl,
);

EvidenceReviewQueueItem fakeReviewItem({
  required int evidenceId,
  PayoutReviewView? payoutReview,
  String? spokenChallengeWord = 'pelican',
  ActionRequirementKind kind = ActionRequirementKind.video,
  String? mediaUrl,
}) => EvidenceReviewQueueItem(
  evidenceId: testUuid(evidenceId),
  attemptId: testUuid(evidenceId + 100),
  actionDefinitionId: testUuid(evidenceId + 200),
  creatorDisplayName: 'Park Run Club',
  actionTitle: 'Ten squats at the park',
  requirementTitle: 'Record your squats',
  requirementKind: kind,
  durationSeconds: kind == ActionRequirementKind.photo ? null : 42,
  capturedAt: fixtureNow,
  submittedAt: fixtureNow.add(const Duration(minutes: 2)),
  reviewReasonCode: 'manual_review',
  reviewSummary: 'Checked by a person before it counts.',
  mediaUrl: mediaUrl,
  spokenChallengeWord: spokenChallengeWord,
  payoutReview: payoutReview,
);

class FakeActionRepository implements ActionRepository {
  FakeActionRepository({this.attempts = const []});

  List<ActionAttemptView> attempts;

  @override
  Future<List<ActionAttemptView>> listMyAttempts() async => attempts;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked.');
}

class FakeRewardRepository implements RewardRepository {
  FakeRewardRepository({this.payouts = const []});

  List<RewardPayoutView> payouts;

  @override
  Future<List<RewardPayoutView>> listMyPayouts() async => payouts;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked.');
}

class FakePayoutWalletRepository implements PayoutWalletRepository {
  FakePayoutWalletRepository({this.wallet});

  PayoutWalletView? wallet;
  final challenges = <String>[];
  final links = <({String walletAddress, String nonce, String signature})>[];

  @override
  Future<PayoutWalletView?> getMine() async => wallet;

  @override
  Future<PayoutWalletLinkChallengeView> createLinkChallenge(
    String walletAddress,
  ) async {
    challenges.add(walletAddress);
    return PayoutWalletLinkChallengeView(
      walletAddress: walletAddress,
      message: 'Link $walletAddress to Verily',
      nonce: 'nonce-1',
      expiresAt: fixtureNow.add(const Duration(minutes: 5)),
    );
  }

  @override
  Future<PayoutWalletView> link({
    required String walletAddress,
    required String nonce,
    required String signature,
  }) async {
    links.add((
      walletAddress: walletAddress,
      nonce: nonce,
      signature: signature,
    ));
    final linked = PayoutWalletView(
      walletAddress: walletAddress,
      label: 'Mobile wallet',
      linkedAt: fixtureNow,
    );
    wallet = linked;
    return linked;
  }
}

/// A wallet that authorizes [address] and signs with a fixed signature, or
/// fails with [failure].
class FakeMobileWallet implements MobileWallet {
  FakeMobileWallet({
    this.isSupported = true,
    this.address = '7t4rL4Ph7v8iKxBHZQH7BdsM5zFi3pCYpu2eMXWJxqP1',
    this.failure,
  });

  @override
  final bool isSupported;
  final String address;
  final WalletFailure? failure;
  final signedMessages = <String>[];

  @override
  Future<T> connect<T>({
    required WalletChain chain,
    required Future<T> Function(WalletConnection wallet) body,
  }) async {
    if (failure case final reason?) throw WalletException(reason);
    return body(_FakeConnection(this));
  }
}

class _FakeConnection implements WalletConnection {
  _FakeConnection(this._wallet);

  final FakeMobileWallet _wallet;

  @override
  String get address => _wallet.address;

  @override
  Future<String> signMessage(String message) async {
    _wallet.signedMessages.add(message);
    return 'signature-base58';
  }

  @override
  Future<String> signAndSendTransaction(Uint8List wireTransaction) =>
      throw UnimplementedError();
}

class FakeEvidenceAppealRepository implements EvidenceAppealRepository {
  FakeEvidenceAppealRepository({
    Map<UuidValue, EvidenceAppealView>? mine,
    this.owned = const [],
  }) : mine = mine ?? {};

  final Map<UuidValue, EvidenceAppealView> mine;
  List<EvidenceAppealView> owned;
  final submitted = <({UuidValue attemptId, String reason})>[];
  final resolved =
      <({UuidValue appealId, EvidenceAppealStatus decision, String note})>[];

  @override
  Future<EvidenceAppealView?> getMine(UuidValue attemptId) async =>
      mine[attemptId];

  @override
  Future<EvidenceAppealView> submit({
    required UuidValue attemptId,
    required String reason,
  }) async {
    submitted.add((attemptId: attemptId, reason: reason));
    final appeal = fakeAppeal(id: 900, attemptId: 0).copyWith(
      attemptId: attemptId,
      reason: reason,
    );
    mine[attemptId] = appeal;
    return appeal;
  }

  @override
  Future<List<EvidenceAppealView>> listOwned() async => owned;

  @override
  Future<EvidenceAppealView> resolve({
    required UuidValue appealId,
    required EvidenceAppealStatus decision,
    required String note,
  }) async {
    resolved.add((appealId: appealId, decision: decision, note: note));
    final current = owned.firstWhere((appeal) => appeal.id == appealId);
    final updated = current.copyWith(status: decision, resolutionNote: note);
    owned = owned
        .map((appeal) => appeal.id == appealId ? updated : appeal)
        .toList();
    return updated;
  }
}

class FakeEvidenceReviewRepository implements EvidenceReviewRepository {
  FakeEvidenceReviewRepository({this.queue = const []});

  List<EvidenceReviewQueueItem> queue;
  int queueLoads = 0;
  final reviews =
      <
        ({UuidValue evidenceId, EvidenceDecisionStatus decision, String note})
      >[];

  @override
  Future<List<EvidenceReviewQueueItem>> listQueue() async {
    queueLoads++;
    return queue;
  }

  @override
  Future<ActionAttemptView> review({
    required UuidValue evidenceId,
    required EvidenceDecisionStatus decision,
    required String note,
  }) async {
    reviews.add((evidenceId: evidenceId, decision: decision, note: note));
    queue = [
      for (final item in queue)
        if (item.evidenceId != evidenceId) item,
    ];
    return fakeAttempt(
      id: 1,
      actionId: 2,
      status: decision == EvidenceDecisionStatus.accepted
          ? ActionAttemptStatus.verified
          : ActionAttemptStatus.rejected,
    );
  }
}

class FakeAccountRepository implements AccountRepository {
  int signOuts = 0;
  final closures = <String>[];
  Exception? closeError;

  @override
  Future<void> signOut() async => signOuts++;

  @override
  Future<DateTime> closeAccount({required String confirmation}) async {
    if (closeError case final error?) throw error;
    closures.add(confirmation);
    return fixtureNow;
  }
}
