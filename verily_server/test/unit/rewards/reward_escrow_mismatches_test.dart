import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/rewards/reward_escrow_gateway.dart';

void main() {
  final pool = _pool();

  group('Given an escrow that exactly matches its pool', () {
    test('when compared then there are no mismatches', () {
      expect(rewardEscrowMismatches(pool, _state(pool)), isEmpty);
    });

    test('when the vault holds more than the budget then it still matches', () {
      expect(
        rewardEscrowMismatches(
          pool,
          _state(
            pool,
            vaultBalance: pool.amountPerPayout * pool.maxPayouts + 1,
          ),
        ),
        isEmpty,
      );
    });

    test('when times differ only below a second then they still match', () {
      expect(
        rewardEscrowMismatches(
          pool,
          _state(
            pool,
            expiresAt: pool.expiresAt.add(const Duration(milliseconds: 400)),
            refundAfter: pool.refundAfter.add(
              const Duration(milliseconds: 999),
            ),
          ),
        ),
        isEmpty,
      );
    });
  });

  group('Given an escrow that disagrees with its pool', () {
    final otherId = UuidValue.withValidation(
      '0198bc26-4be5-7ca0-94d2-000000000077',
    );
    final cases = <String, RewardEscrowAccountState>{
      'owner': _state(pool, ownedByEscrowProgram: false),
      'address': _state(pool, escrowAddress: 'OtherEscrow'),
      'creator': _state(pool, creator: 'OtherCreator'),
      'arbiter': _state(pool, arbiter: 'OtherArbiter'),
      'mint': _state(pool, mint: 'OtherMint'),
      'poolId': _state(pool, poolId: otherId),
      'amountPerPayout': _state(pool, amountPerPayout: 999999),
      'maxPayouts': _state(pool, maxPayouts: 11),
      'expiresAt': _state(
        pool,
        expiresAt: pool.expiresAt.add(const Duration(seconds: 1)),
      ),
      'refundAfter': _state(
        pool,
        refundAfter: pool.refundAfter.subtract(const Duration(seconds: 1)),
      ),
      'refundDelay': _state(pool, refundDelaySeconds: 3 * 86400),
      'releasedCount': _state(pool, releasedCount: 1),
      'vaultBalance': _state(
        pool,
        vaultBalance: pool.amountPerPayout * pool.maxPayouts - 1,
      ),
    };

    for (final entry in cases.entries) {
      test('when only ${entry.key} differs then exactly that field is '
          'reported', () {
        expect(rewardEscrowMismatches(pool, entry.value), [entry.key]);
      });
    }

    test('when several fields differ then each is reported once', () {
      expect(
        rewardEscrowMismatches(
          pool,
          _state(pool, mint: 'OtherMint', releasedCount: 2, vaultBalance: 0),
        ),
        ['mint', 'releasedCount', 'vaultBalance'],
      );
    });

    test('when the pool never froze its wallet or escrow then nothing can '
        'match', () {
      final mismatches = rewardEscrowMismatches(
        _poolWithoutEscrow(),
        _state(pool),
      );

      expect(mismatches, containsAll(['address', 'creator', 'arbiter']));
    });
  });
}

RewardPool _pool() {
  final expiresAt = DateTime.utc(2026, 12, 1, 12);
  return RewardPool(
    id: UuidValue.withValidation('0198bc26-4be5-7ca0-94d2-000000000042'),
    creatorAuthUserId: UuidValue.withValidation(
      '0198bc26-4be5-7ca0-94d2-000000000001',
    ),
    actionKey: 'water-a-plant',
    cluster: RewardCluster.devnet,
    mint: '4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU',
    tokenSymbol: 'USDC',
    decimals: 6,
    amountPerPayout: 1000000,
    maxPayouts: 10,
    creatorWallet: 'CreatorWallet',
    escrowAddress: 'EscrowAddress',
    arbiterAddress: 'ArbiterAddress',
    expiresAt: expiresAt,
    refundDelaySeconds: 7 * 86400,
    refundAfter: expiresAt.add(const Duration(days: 7)),
    status: RewardPoolStatus.awaitingFunding,
  );
}

RewardPool _poolWithoutEscrow() {
  final base = _pool();
  return RewardPool(
    id: base.id,
    creatorAuthUserId: base.creatorAuthUserId,
    actionKey: base.actionKey,
    cluster: base.cluster,
    mint: base.mint,
    tokenSymbol: base.tokenSymbol,
    decimals: base.decimals,
    amountPerPayout: base.amountPerPayout,
    maxPayouts: base.maxPayouts,
    expiresAt: base.expiresAt,
    refundDelaySeconds: base.refundDelaySeconds,
    refundAfter: base.refundAfter,
    status: RewardPoolStatus.draft,
  );
}

RewardEscrowAccountState _state(
  RewardPool pool, {
  bool ownedByEscrowProgram = true,
  String? escrowAddress,
  String? creator,
  String? arbiter,
  String? mint,
  UuidValue? poolId,
  int? amountPerPayout,
  int? maxPayouts,
  int releasedCount = 0,
  DateTime? expiresAt,
  DateTime? refundAfter,
  int? refundDelaySeconds,
  int? vaultBalance,
}) => RewardEscrowAccountState(
  escrowAddress: escrowAddress ?? pool.escrowAddress!,
  ownedByEscrowProgram: ownedByEscrowProgram,
  creator: creator ?? pool.creatorWallet!,
  arbiter: arbiter ?? pool.arbiterAddress!,
  mint: mint ?? pool.mint,
  poolId: poolId ?? pool.id!,
  amountPerPayout: amountPerPayout ?? pool.amountPerPayout,
  maxPayouts: maxPayouts ?? pool.maxPayouts,
  releasedCount: releasedCount,
  expiresAt: expiresAt ?? pool.expiresAt,
  refundAfter: refundAfter ?? pool.refundAfter,
  refundDelaySeconds: refundDelaySeconds ?? pool.refundDelaySeconds,
  vaultBalance: vaultBalance ?? pool.amountPerPayout * pool.maxPayouts,
);
