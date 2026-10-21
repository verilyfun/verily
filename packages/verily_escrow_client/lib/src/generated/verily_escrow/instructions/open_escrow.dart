// Auto-generated. Do not edit.
// ignore_for_file: type=lint

import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:solana_kit_addresses/solana_kit_addresses.dart';
import 'package:solana_kit_codecs_core/solana_kit_codecs_core.dart';
import 'package:solana_kit_codecs_data_structures/solana_kit_codecs_data_structures.dart';
import 'package:solana_kit_codecs_numbers/solana_kit_codecs_numbers.dart';
import 'package:solana_kit_errors/solana_kit_errors.dart';
import 'package:solana_kit_instructions/solana_kit_instructions.dart';

@immutable
class OpenEscrowInstructionData {
  const OpenEscrowInstructionData({
    required this.poolId,
    required this.arbiter,
    required this.amountPerPayout,
    required this.maxPayouts,
    required this.expiresAt,
    required this.refundDelay,
  }) : discriminator = 0;

  final int discriminator;
  final Uint8List poolId;
  final Address arbiter;
  final BigInt amountPerPayout;
  final int maxPayouts;
  final BigInt expiresAt;
  final int refundDelay;
}

Encoder<OpenEscrowInstructionData> getOpenEscrowInstructionDataEncoder() {
  final structEncoder = getStructEncoder(<(String, Encoder<Object?>)>[
    ('discriminator', getU8Encoder()),
    ('poolId', fixEncoderSize(getBytesEncoder(), 16, allowTruncation: false)),
    ('arbiter', getAddressEncoder()),
    ('amountPerPayout', getU64Encoder()),
    ('maxPayouts', getU16Encoder()),
    ('expiresAt', getI64Encoder()),
    ('refundDelay', getU32Encoder()),
  ]);

  return transformEncoder(
    structEncoder,
    (OpenEscrowInstructionData value) => <String, Object?>{
      'discriminator': 0,
      'poolId': value.poolId,
      'arbiter': value.arbiter,
      'amountPerPayout': value.amountPerPayout,
      'maxPayouts': value.maxPayouts,
      'expiresAt': value.expiresAt,
      'refundDelay': value.refundDelay,
    },
  );
}

Decoder<OpenEscrowInstructionData> getOpenEscrowInstructionDataDecoder() {
  final structDecoder = getStructDecoder(<(String, Decoder<Object?>)>[
    ('discriminator', getU8Decoder()),
    ('poolId', fixDecoderSize(getBytesDecoder(), 16)),
    ('arbiter', getAddressDecoder()),
    ('amountPerPayout', getU64Decoder()),
    ('maxPayouts', getU16Decoder()),
    ('expiresAt', getI64Decoder()),
    ('refundDelay', getU32Decoder()),
  ]);

  Never throwInvalidByteLength(int expected, int bytesLength) {
    throw SolanaError(
      SolanaErrorCode.codecsInvalidByteLength,
      {
        'codecDescription': 'openEscrow instruction decoder',
        'expected': expected,
        'bytesLength': bytesLength,
      },
    );
  }

  (OpenEscrowInstructionData, int) readTopLevel(Uint8List bytes, int offset) {
    getConstantDecoder(
      getU8Encoder().encode(0),
    ).read(bytes, offset + 0);
    final (map, newOffset) = structDecoder.read(bytes, offset);
    if (newOffset != bytes.length) {
      throwInvalidByteLength(newOffset - offset, bytes.length - offset);
    }

    return (
      OpenEscrowInstructionData(
        poolId: map['poolId']! as Uint8List,
        arbiter: map['arbiter']! as Address,
        amountPerPayout: map['amountPerPayout']! as BigInt,
        maxPayouts: map['maxPayouts']! as int,
        expiresAt: map['expiresAt']! as BigInt,
        refundDelay: map['refundDelay']! as int,
      ),
      newOffset,
    );
  }

  return switch (structDecoder) {
    FixedSizeDecoder<Map<String, Object?>>() =>
      FixedSizeDecoder<OpenEscrowInstructionData>(
        fixedSize: structDecoder.fixedSize,
        read: (bytes, offset) {
          final bytesLength = bytes.length - offset;
          if (bytesLength != structDecoder.fixedSize) {
            throwInvalidByteLength(structDecoder.fixedSize, bytesLength);
          }
          return readTopLevel(bytes, offset);
        },
      ),
    VariableSizeDecoder<Map<String, Object?>>() =>
      VariableSizeDecoder<OpenEscrowInstructionData>(
        read: readTopLevel,
        maxSize: structDecoder.maxSize,
      ),
  };
}

Codec<OpenEscrowInstructionData, OpenEscrowInstructionData>
getOpenEscrowInstructionDataCodec() {
  return combineCodec(
    getOpenEscrowInstructionDataEncoder(),
    getOpenEscrowInstructionDataDecoder(),
  );
}

/// Creates a [OpenEscrow] instruction.
Instruction getOpenEscrowInstruction({
  required Address programAddress,
  required Address creator,
  required Address escrow,
  required Address vault,
  required Address creatorToken,
  required Address mint,
  required Address tokenProgram,
  required Address associatedTokenProgram,
  required Address systemProgram,
  required Uint8List poolId,
  required Address arbiter,
  required BigInt amountPerPayout,
  required int maxPayouts,
  required BigInt expiresAt,
  required int refundDelay,
}) {
  final instructionData = OpenEscrowInstructionData(
    poolId: poolId,
    arbiter: arbiter,
    amountPerPayout: amountPerPayout,
    maxPayouts: maxPayouts,
    expiresAt: expiresAt,
    refundDelay: refundDelay,
  );

  return Instruction(
    programAddress: programAddress,
    accounts: [
      AccountMeta(address: creator, role: AccountRole.writableSigner),
      AccountMeta(address: escrow, role: AccountRole.writable),
      AccountMeta(address: vault, role: AccountRole.writable),
      AccountMeta(address: creatorToken, role: AccountRole.writable),
      AccountMeta(address: mint, role: AccountRole.readonly),
      AccountMeta(address: tokenProgram, role: AccountRole.readonly),
      AccountMeta(address: associatedTokenProgram, role: AccountRole.readonly),
      AccountMeta(address: systemProgram, role: AccountRole.readonly),
    ],
    data: getOpenEscrowInstructionDataEncoder().encode(instructionData),
  );
}

/// Parses a [OpenEscrow] instruction from raw instruction data.
OpenEscrowInstructionData parseOpenEscrowInstruction(Instruction instruction) {
  return getOpenEscrowInstructionDataDecoder().decode(instruction.data!);
}
