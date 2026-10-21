// Auto-generated. Do not edit.
// ignore_for_file: type=lint

import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:solana_kit_addresses/solana_kit_addresses.dart';
import 'package:solana_kit_codecs_core/solana_kit_codecs_core.dart';
import 'package:solana_kit_codecs_data_structures/solana_kit_codecs_data_structures.dart';

@immutable
class RewardEscrowSeeds {
  const RewardEscrowSeeds({
    required this.creator,
    required this.poolId,
  });

  final Address creator;
  final Uint8List poolId;
}

/// Finds the program derived address for [RewardEscrow].
Future<(Address, int)> findRewardEscrowPda({
  required RewardEscrowSeeds seeds,
  required Address programAddress,
}) async {
  final seedValues = <Object>[
    'reward-escrow',
    getAddressEncoder().encode(seeds.creator),
    fixEncoderSize(
      getBytesEncoder(),
      16,
      allowTruncation: false,
    ).encode(seeds.poolId),
  ];

  return getProgramDerivedAddress(
    programAddress: programAddress,
    seeds: seedValues,
  );
}
