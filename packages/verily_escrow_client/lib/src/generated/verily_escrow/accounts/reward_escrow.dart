// Auto-generated. Do not edit.
// ignore_for_file: type=lint

import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:solana_kit_accounts/solana_kit_accounts.dart';
import 'package:solana_kit_addresses/solana_kit_addresses.dart';
import 'package:solana_kit_codecs_core/solana_kit_codecs_core.dart';
import 'package:solana_kit_codecs_data_structures/solana_kit_codecs_data_structures.dart';
import 'package:solana_kit_codecs_numbers/solana_kit_codecs_numbers.dart';
import 'package:solana_kit_errors/solana_kit_errors.dart';

@immutable
class RewardEscrow {
  const RewardEscrow({
    required this.creator,
    required this.arbiter,
    required this.mint,
    required this.vault,
    required this.poolId,
    required this.amountPerPayout,
    required this.maxPayouts,
    required this.releasedCount,
    required this.expiresAt,
    required this.refundAfter,
    required this.refundDelay,
    required this.bump,
    required this.released,
  }) : discriminator = 1,
       migrationVersion = 0;

  final int discriminator;
  final int migrationVersion;
  final Address creator;
  final Address arbiter;
  final Address mint;
  final Address vault;
  final Uint8List poolId;
  final BigInt amountPerPayout;
  final int maxPayouts;
  final int releasedCount;
  final BigInt expiresAt;
  final BigInt refundAfter;
  final int refundDelay;
  final int bump;
  final Uint8List released;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardEscrow &&
          runtimeType == other.runtimeType &&
          discriminator == other.discriminator &&
          migrationVersion == other.migrationVersion &&
          creator == other.creator &&
          arbiter == other.arbiter &&
          mint == other.mint &&
          vault == other.vault &&
          poolId == other.poolId &&
          amountPerPayout == other.amountPerPayout &&
          maxPayouts == other.maxPayouts &&
          releasedCount == other.releasedCount &&
          expiresAt == other.expiresAt &&
          refundAfter == other.refundAfter &&
          refundDelay == other.refundDelay &&
          bump == other.bump &&
          released == other.released;

  @override
  int get hashCode => Object.hash(
    discriminator,
    migrationVersion,
    creator,
    arbiter,
    mint,
    vault,
    poolId,
    amountPerPayout,
    maxPayouts,
    releasedCount,
    expiresAt,
    refundAfter,
    refundDelay,
    bump,
    released,
  );

  @override
  String toString() =>
      'RewardEscrow(discriminator: $discriminator, migrationVersion: $migrationVersion, creator: $creator, arbiter: $arbiter, mint: $mint, vault: $vault, poolId: $poolId, amountPerPayout: $amountPerPayout, maxPayouts: $maxPayouts, releasedCount: $releasedCount, expiresAt: $expiresAt, refundAfter: $refundAfter, refundDelay: $refundDelay, bump: $bump, released: $released)';
}

Encoder<RewardEscrow> getRewardEscrowEncoder() {
  final structEncoder = getStructEncoder(<(String, Encoder<Object?>)>[
    ('discriminator', getU8Encoder()),
    ('migrationVersion', getU8Encoder()),
    ('creator', getAddressEncoder()),
    ('arbiter', getAddressEncoder()),
    ('mint', getAddressEncoder()),
    ('vault', getAddressEncoder()),
    ('poolId', fixEncoderSize(getBytesEncoder(), 16, allowTruncation: false)),
    ('amountPerPayout', getU64Encoder()),
    ('maxPayouts', getU16Encoder()),
    ('releasedCount', getU16Encoder()),
    ('expiresAt', getI64Encoder()),
    ('refundAfter', getI64Encoder()),
    ('refundDelay', getU32Encoder()),
    ('bump', getU8Encoder()),
    (
      'released',
      fixEncoderSize(getBytesEncoder(), 256, allowTruncation: false),
    ),
  ]);

  return transformEncoder(
    structEncoder,
    (RewardEscrow value) => <String, Object?>{
      'discriminator': 1,
      'migrationVersion': 0,
      'creator': value.creator,
      'arbiter': value.arbiter,
      'mint': value.mint,
      'vault': value.vault,
      'poolId': value.poolId,
      'amountPerPayout': value.amountPerPayout,
      'maxPayouts': value.maxPayouts,
      'releasedCount': value.releasedCount,
      'expiresAt': value.expiresAt,
      'refundAfter': value.refundAfter,
      'refundDelay': value.refundDelay,
      'bump': value.bump,
      'released': value.released,
    },
  );
}

Decoder<RewardEscrow> getRewardEscrowDecoder() {
  final structDecoder = getStructDecoder(<(String, Decoder<Object?>)>[
    ('discriminator', getU8Decoder()),
    ('migrationVersion', getU8Decoder()),
    ('creator', getAddressDecoder()),
    ('arbiter', getAddressDecoder()),
    ('mint', getAddressDecoder()),
    ('vault', getAddressDecoder()),
    ('poolId', fixDecoderSize(getBytesDecoder(), 16)),
    ('amountPerPayout', getU64Decoder()),
    ('maxPayouts', getU16Decoder()),
    ('releasedCount', getU16Decoder()),
    ('expiresAt', getI64Decoder()),
    ('refundAfter', getI64Decoder()),
    ('refundDelay', getU32Decoder()),
    ('bump', getU8Decoder()),
    ('released', fixDecoderSize(getBytesDecoder(), 256)),
  ]);

  Never throwInvalidByteLength(int expected, int bytesLength) {
    throw SolanaError(
      SolanaErrorCode.codecsInvalidByteLength,
      {
        'codecDescription': 'rewardEscrow account decoder',
        'expected': expected,
        'bytesLength': bytesLength,
      },
    );
  }

  (RewardEscrow, int) readTopLevel(Uint8List bytes, int offset) {
    getConstantDecoder(
      getU8Encoder().encode(1),
    ).read(bytes, offset + 0);
    final (storedMigrationVersion, _) = getU8Decoder().read(bytes, offset + 1);
    if (storedMigrationVersion != 0) {
      throw StateError(
        storedMigrationVersion < 0
            ? 'migration version mismatch: expected 0, received $storedMigrationVersion (the data predates this client; migrate it by sending a transaction to the program, or decode it with a client generated from an older IDL)'
            : 'migration version mismatch: expected 0, received $storedMigrationVersion (the data was written by a newer program; upgrade this client)',
      );
    }
    final (map, newOffset) = structDecoder.read(bytes, offset);

    return (
      RewardEscrow(
        creator: map['creator']! as Address,
        arbiter: map['arbiter']! as Address,
        mint: map['mint']! as Address,
        vault: map['vault']! as Address,
        poolId: map['poolId']! as Uint8List,
        amountPerPayout: map['amountPerPayout']! as BigInt,
        maxPayouts: map['maxPayouts']! as int,
        releasedCount: map['releasedCount']! as int,
        expiresAt: map['expiresAt']! as BigInt,
        refundAfter: map['refundAfter']! as BigInt,
        refundDelay: map['refundDelay']! as int,
        bump: map['bump']! as int,
        released: map['released']! as Uint8List,
      ),
      newOffset,
    );
  }

  return switch (structDecoder) {
    FixedSizeDecoder<Map<String, Object?>>() => FixedSizeDecoder<RewardEscrow>(
      fixedSize: structDecoder.fixedSize,
      read: (bytes, offset) {
        final bytesLength = bytes.length - offset;
        if (bytesLength < structDecoder.fixedSize) {
          throwInvalidByteLength(structDecoder.fixedSize, bytesLength);
        }
        return readTopLevel(bytes, offset);
      },
    ),
    VariableSizeDecoder<Map<String, Object?>>() =>
      VariableSizeDecoder<RewardEscrow>(
        read: readTopLevel,
        maxSize: structDecoder.maxSize,
      ),
  };
}

Codec<RewardEscrow, RewardEscrow> getRewardEscrowCodec() {
  return combineCodec(getRewardEscrowEncoder(), getRewardEscrowDecoder());
}

Account<RewardEscrow> decodeRewardEscrow(EncodedAccount encodedAccount) {
  return decodeAccount(encodedAccount, getRewardEscrowDecoder());
}

/// The account schema version this client was generated from.
const int rewardEscrowMigrationVersion = 0;

/// Cheap envelope check for fetched `RewardEscrow` bytes: returns true only when
/// the bytes carry this account's discriminator and a migration version older
/// than this client's schema — exactly the accounts [getMigrateInstruction]
/// can bring current. Decoding reports every other mismatch.
bool rewardEscrowNeedsMigration(List<int> data) {
  if (data.length < 2) {
    return false;
  }
  if (data[0] != 1) {
    return false;
  }
  return data[1] < 0;
}
