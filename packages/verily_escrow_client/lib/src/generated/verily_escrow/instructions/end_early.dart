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
class EndEarlyInstructionData {
  const EndEarlyInstructionData() : discriminator = 2;

  final int discriminator;
}

Encoder<EndEarlyInstructionData> getEndEarlyInstructionDataEncoder() {
  final structEncoder = getStructEncoder(<(String, Encoder<Object?>)>[
    ('discriminator', getU8Encoder()),
  ]);

  return transformEncoder(
    structEncoder,
    (EndEarlyInstructionData value) => <String, Object?>{
      'discriminator': 2,
    },
  );
}

Decoder<EndEarlyInstructionData> getEndEarlyInstructionDataDecoder() {
  final structDecoder = getStructDecoder(<(String, Decoder<Object?>)>[
    ('discriminator', getU8Decoder()),
  ]);

  Never throwInvalidByteLength(int expected, int bytesLength) {
    throw SolanaError(
      SolanaErrorCode.codecsInvalidByteLength,
      {
        'codecDescription': 'endEarly instruction decoder',
        'expected': expected,
        'bytesLength': bytesLength,
      },
    );
  }

  (EndEarlyInstructionData, int) readTopLevel(Uint8List bytes, int offset) {
    getConstantDecoder(
      getU8Encoder().encode(2),
    ).read(bytes, offset + 0);
    final (map, newOffset) = structDecoder.read(bytes, offset);
    if (newOffset != bytes.length) {
      throwInvalidByteLength(newOffset - offset, bytes.length - offset);
    }

    return (
      EndEarlyInstructionData(),
      newOffset,
    );
  }

  return switch (structDecoder) {
    FixedSizeDecoder<Map<String, Object?>>() =>
      FixedSizeDecoder<EndEarlyInstructionData>(
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
      VariableSizeDecoder<EndEarlyInstructionData>(
        read: readTopLevel,
        maxSize: structDecoder.maxSize,
      ),
  };
}

Codec<EndEarlyInstructionData, EndEarlyInstructionData>
getEndEarlyInstructionDataCodec() {
  return combineCodec(
    getEndEarlyInstructionDataEncoder(),
    getEndEarlyInstructionDataDecoder(),
  );
}

/// Creates a [EndEarly] instruction.
Instruction getEndEarlyInstruction({
  required Address programAddress,
  required Address creator,
  required Address escrow,
}) {
  final instructionData = EndEarlyInstructionData();

  return Instruction(
    programAddress: programAddress,
    accounts: [
      AccountMeta(address: creator, role: AccountRole.readonlySigner),
      AccountMeta(address: escrow, role: AccountRole.writable),
    ],
    data: getEndEarlyInstructionDataEncoder().encode(instructionData),
  );
}

/// Parses a [EndEarly] instruction from raw instruction data.
EndEarlyInstructionData parseEndEarlyInstruction(Instruction instruction) {
  return getEndEarlyInstructionDataDecoder().decode(instruction.data!);
}
