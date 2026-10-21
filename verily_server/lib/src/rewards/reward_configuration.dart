import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/rewards/local_development_reward_escrow_gateway.dart';
import 'package:verily_server/src/rewards/reward_escrow_gateway.dart';

/// The token a pool pays in. v1 supports classic-SPL USDC only, so the
/// creator never chooses a mint and a scam or fee-bearing token can never be
/// escrowed.
final class RewardToken {
  const RewardToken({
    required this.mint,
    required this.symbol,
    required this.decimals,
  });

  final String mint;
  final String symbol;
  final int decimals;
}

const rewardTokens = <RewardCluster, RewardToken>{
  RewardCluster.devnet: RewardToken(
    mint: '4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU',
    symbol: 'USDC',
    decimals: 6,
  ),
  RewardCluster.mainnet: RewardToken(
    mint: 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v',
    symbol: 'USDC',
    decimals: 6,
  ),
};

/// Bounds shared with the `verily_escrow` program.
abstract final class RewardBounds {
  static const maxPayouts = 2048;
  static const maxWinsPerAccount = 365;
  static const minRefundDelayDays = 3;
  static const maxRefundDelayDays = 30;

  /// One payout of at most 1,000,000 USDC keeps every budget within the
  /// 53-bit integers web clients represent exactly.
  static const maxAmountPerPayoutAtoms = 1000000000000;
  static const minLifetime = Duration(hours: 1);
  static const maxLifetime = Duration(days: 365);

  /// Releases stop this long before the refund window opens so a release can
  /// never race the creator closing the escrow.
  static const releaseSafetyMargin = Duration(minutes: 30);
}

/// Default threshold above which a payout is released only on proof a person
/// accepted: 25 USDC.
const defaultRewardReviewThresholdAtoms = 25000000;

/// The highest threshold a deployment may set: 1,000 USDC.
const maxRewardReviewThresholdAtoms = 1000000000;

/// Server-owned reward settings for one process.
class RewardConfiguration {
  const RewardConfiguration({
    required this.gateway,
    required this.cluster,
    required this.reviewThresholdAtoms,
  });

  /// Rewards unavailable: the default until startup configures a gateway.
  const RewardConfiguration.disabled()
    : gateway = const DisabledRewardEscrowGateway(),
      cluster = RewardCluster.devnet,
      reviewThresholdAtoms = defaultRewardReviewThresholdAtoms;

  /// Reads `VERILY_REWARD_ESCROW_MODE` (`disabled`, `local-development`, or
  /// `solana`), `VERILY_REWARD_CLUSTER` (`devnet` or `mainnet`), and
  /// `VERILY_REWARD_REVIEW_THRESHOLD_ATOMS`. Every invalid value stops the
  /// server, so a typo can never wave valuable payouts through.
  factory RewardConfiguration.fromEnvironment({
    required String runMode,
    required Map<String, String> environment,
  }) {
    final developmentLike =
        runMode == ServerpodRunMode.development ||
        runMode == ServerpodRunMode.test;
    final cluster = switch (environment['VERILY_REWARD_CLUSTER']
        ?.trim()
        .toLowerCase()) {
      null || '' when developmentLike => RewardCluster.devnet,
      null || '' => RewardCluster.mainnet,
      'devnet' => RewardCluster.devnet,
      'mainnet' => RewardCluster.mainnet,
      _ => throw StateError('VERILY_REWARD_CLUSTER must be devnet or mainnet.'),
    };
    final threshold = rewardReviewThresholdFromEnvironment(environment);
    final gateway = switch (environment['VERILY_REWARD_ESCROW_MODE']
        ?.trim()
        .toLowerCase()) {
      null || '' || 'disabled' => const DisabledRewardEscrowGateway(),
      'local-development' when developmentLike =>
        cluster == RewardCluster.devnet
            ? const LocalDevelopmentRewardEscrowGateway()
            : throw StateError(
                'The local development escrow only simulates devnet.',
              ),
      'local-development' => throw StateError(
        'The local development escrow is refused outside development and '
        'test run modes.',
      ),
      // The Solana gateway is built against the generated verily_escrow
      // client in a later phase. Until then the mode fails closed.
      'solana' => throw StateError(
        'The Solana reward escrow gateway is not available in this build.',
      ),
      _ => throw StateError(
        'VERILY_REWARD_ESCROW_MODE must be disabled, local-development, or '
        'solana.',
      ),
    };
    return RewardConfiguration(
      gateway: gateway,
      cluster: cluster,
      reviewThresholdAtoms: threshold,
    );
  }

  final RewardEscrowGateway gateway;

  /// The cluster new pools are created on.
  final RewardCluster cluster;

  /// Payouts worth more than this many token atoms need proof a person
  /// accepted before they are reserved.
  final int reviewThresholdAtoms;

  RewardToken get token => rewardTokens[cluster]!;
}

/// Parses `VERILY_REWARD_REVIEW_THRESHOLD_ATOMS`: a whole number of atoms
/// from 0 (every payout needs a person) to [maxRewardReviewThresholdAtoms].
int rewardReviewThresholdFromEnvironment(Map<String, String> environment) {
  final value = parseRewardReviewThreshold(environment);
  if (value == null) throw StateError(rewardReviewThresholdError);
  return value;
}

/// The configured threshold, the default when unset, or null when the value
/// is not a whole number of atoms within bounds.
int? parseRewardReviewThreshold(Map<String, String> environment) {
  final raw = environment['VERILY_REWARD_REVIEW_THRESHOLD_ATOMS']?.trim();
  if (raw == null || raw.isEmpty) return defaultRewardReviewThresholdAtoms;
  if (!RegExp(r'^[0-9]{1,13}$').hasMatch(raw)) return null;
  final value = int.parse(raw);
  return value > maxRewardReviewThresholdAtoms ? null : value;
}

const rewardReviewThresholdError =
    'VERILY_REWARD_REVIEW_THRESHOLD_ATOMS must be a whole number of atoms '
    'from 0 to $maxRewardReviewThresholdAtoms.';

/// Process-wide reward configuration, set at startup before endpoints run.
abstract final class RewardRuntime {
  static RewardConfiguration current = const RewardConfiguration.disabled();
}
