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
class ReleasePayoutInstructionData {
  const ReleasePayoutInstructionData({
    required this.index,
  }) : discriminator = 1;

  final int discriminator;
  final int index;
}

Encoder<ReleasePayoutInstructionData> getReleasePayoutInstructionDataEncoder() {
  final structEncoder = getStructEncoder(<(String, Encoder<Object?>)>[
    ('discriminator', getU8Encoder()),
    ('index', getU16Encoder()),
  ]);

  return transformEncoder(
    structEncoder,
    (ReleasePayoutInstructionData value) => <String, Object?>{
      'discriminator': 1,
      'index': value.index,
    },
  );
}

Decoder<ReleasePayoutInstructionData> getReleasePayoutInstructionDataDecoder() {
  final structDecoder = getStructDecoder(<(String, Decoder<Object?>)>[
    ('discriminator', getU8Decoder()),
    ('index', getU16Decoder()),
  ]);

  Never throwInvalidByteLength(int expected, int bytesLength) {
    throw SolanaError(
      SolanaErrorCode.codecsInvalidByteLength,
      {
        'codecDescription': 'releasePayout instruction decoder',
        'expected': expected,
        'bytesLength': bytesLength,
      },
    );
  }

  (ReleasePayoutInstructionData, int) readTopLevel(
    Uint8List bytes,
    int offset,
  ) {
    getConstantDecoder(
      getU8Encoder().encode(1),
    ).read(bytes, offset + 0);
    final (map, newOffset) = structDecoder.read(bytes, offset);
    if (newOffset != bytes.length) {
      throwInvalidByteLength(newOffset - offset, bytes.length - offset);
    }

    return (
      ReleasePayoutInstructionData(
        index: map['index']! as int,
      ),
      newOffset,
    );
  }

  return switch (structDecoder) {
    FixedSizeDecoder<Map<String, Object?>>() =>
      FixedSizeDecoder<ReleasePayoutInstructionData>(
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
      VariableSizeDecoder<ReleasePayoutInstructionData>(
        read: readTopLevel,
        maxSize: structDecoder.maxSize,
      ),
  };
}

Codec<ReleasePayoutInstructionData, ReleasePayoutInstructionData>
getReleasePayoutInstructionDataCodec() {
  return combineCodec(
    getReleasePayoutInstructionDataEncoder(),
    getReleasePayoutInstructionDataDecoder(),
  );
}

/// Creates a [ReleasePayout] instruction.
Instruction getReleasePayoutInstruction({
  required Address programAddress,
  required Address arbiter,
  required Address escrow,
  required Address vault,
  required Address recipientToken,
  required Address mint,
  required Address tokenProgram,
  required int index,
}) {
  final instructionData = ReleasePayoutInstructionData(
    index: index,
  );

  return Instruction(
    programAddress: programAddress,
    accounts: [
      AccountMeta(address: arbiter, role: AccountRole.readonlySigner),
      AccountMeta(address: escrow, role: AccountRole.writable),
      AccountMeta(address: vault, role: AccountRole.writable),
      AccountMeta(address: recipientToken, role: AccountRole.writable),
      AccountMeta(address: mint, role: AccountRole.readonly),
      AccountMeta(address: tokenProgram, role: AccountRole.readonly),
    ],
    data: getReleasePayoutInstructionDataEncoder().encode(instructionData),
  );
}

/// Parses a [ReleasePayout] instruction from raw instruction data.
ReleasePayoutInstructionData parseReleasePayoutInstruction(
  Instruction instruction,
) {
  return getReleasePayoutInstructionDataDecoder().decode(instruction.data!);
}
