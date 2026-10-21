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
class CloseEscrowInstructionData {
  const CloseEscrowInstructionData() : discriminator = 3;

  final int discriminator;
}

Encoder<CloseEscrowInstructionData> getCloseEscrowInstructionDataEncoder() {
  final structEncoder = getStructEncoder(<(String, Encoder<Object?>)>[
    ('discriminator', getU8Encoder()),
  ]);

  return transformEncoder(
    structEncoder,
    (CloseEscrowInstructionData value) => <String, Object?>{
      'discriminator': 3,
    },
  );
}

Decoder<CloseEscrowInstructionData> getCloseEscrowInstructionDataDecoder() {
  final structDecoder = getStructDecoder(<(String, Decoder<Object?>)>[
    ('discriminator', getU8Decoder()),
  ]);

  Never throwInvalidByteLength(int expected, int bytesLength) {
    throw SolanaError(
      SolanaErrorCode.codecsInvalidByteLength,
      {
        'codecDescription': 'closeEscrow instruction decoder',
        'expected': expected,
        'bytesLength': bytesLength,
      },
    );
  }

  (CloseEscrowInstructionData, int) readTopLevel(Uint8List bytes, int offset) {
    getConstantDecoder(
      getU8Encoder().encode(3),
    ).read(bytes, offset + 0);
    final (map, newOffset) = structDecoder.read(bytes, offset);
    if (newOffset != bytes.length) {
      throwInvalidByteLength(newOffset - offset, bytes.length - offset);
    }

    return (
      CloseEscrowInstructionData(),
      newOffset,
    );
  }

  return switch (structDecoder) {
    FixedSizeDecoder<Map<String, Object?>>() =>
      FixedSizeDecoder<CloseEscrowInstructionData>(
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
      VariableSizeDecoder<CloseEscrowInstructionData>(
        read: readTopLevel,
        maxSize: structDecoder.maxSize,
      ),
  };
}

Codec<CloseEscrowInstructionData, CloseEscrowInstructionData>
getCloseEscrowInstructionDataCodec() {
  return combineCodec(
    getCloseEscrowInstructionDataEncoder(),
    getCloseEscrowInstructionDataDecoder(),
  );
}

/// Creates a [CloseEscrow] instruction.
Instruction getCloseEscrowInstruction({
  required Address programAddress,
  required Address creator,
  required Address escrow,
  required Address vault,
  required Address creatorToken,
  required Address mint,
  required Address tokenProgram,
}) {
  final instructionData = CloseEscrowInstructionData();

  return Instruction(
    programAddress: programAddress,
    accounts: [
      AccountMeta(address: creator, role: AccountRole.writableSigner),
      AccountMeta(address: escrow, role: AccountRole.writable),
      AccountMeta(address: vault, role: AccountRole.writable),
      AccountMeta(address: creatorToken, role: AccountRole.writable),
      AccountMeta(address: mint, role: AccountRole.readonly),
      AccountMeta(address: tokenProgram, role: AccountRole.readonly),
    ],
    data: getCloseEscrowInstructionDataEncoder().encode(instructionData),
  );
}

/// Parses a [CloseEscrow] instruction from raw instruction data.
CloseEscrowInstructionData parseCloseEscrowInstruction(
  Instruction instruction,
) {
  return getCloseEscrowInstructionDataDecoder().decode(instruction.data!);
}
