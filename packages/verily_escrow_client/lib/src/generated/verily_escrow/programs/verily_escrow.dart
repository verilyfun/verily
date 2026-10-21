// Auto-generated. Do not edit.
// ignore_for_file: type=lint

import 'dart:typed_data';

import 'package:solana_kit_addresses/solana_kit_addresses.dart';
import 'package:solana_kit_codecs_core/solana_kit_codecs_core.dart';
import 'package:solana_kit_codecs_numbers/solana_kit_codecs_numbers.dart';
import 'package:solana_kit_errors/solana_kit_errors.dart';
import 'package:solana_kit_instructions/solana_kit_instructions.dart';

import '../instructions/instructions.dart';

/// The address of the VerilyEscrow program.
const verilyEscrowProgramAddress = Address(
  'ANL35GQjGtSuCAHTbXGBjnevFqbEtKNf6wDGPKwuPN1p',
);

/// Known accounts for the VerilyEscrow program.
enum VerilyEscrowAccount {
  rewardEscrow,
}

/// Known instructions for the VerilyEscrow program.
enum VerilyEscrowInstruction {
  openEscrow,
  releasePayout,
  endEarly,
  closeEscrow,
}

/// Identifies the type of a VerilyEscrow instruction.
VerilyEscrowInstruction identifyVerilyEscrowInstruction(
  Uint8List data,
) {
  if (containsBytes(data, getU8Encoder().encode(0), 0)) {
    return VerilyEscrowInstruction.openEscrow;
  }
  if (containsBytes(data, getU8Encoder().encode(1), 0)) {
    return VerilyEscrowInstruction.releasePayout;
  }
  if (containsBytes(data, getU8Encoder().encode(2), 0)) {
    return VerilyEscrowInstruction.endEarly;
  }
  if (containsBytes(data, getU8Encoder().encode(3), 0)) {
    return VerilyEscrowInstruction.closeEscrow;
  }

  throw SolanaError(
    SolanaErrorCode.programClientsFailedToIdentifyInstruction,
    {
      'instructionData': data,
      'programName': 'verilyEscrow',
    },
  );
}

/// A parsed instruction from the VerilyEscrow program.
sealed class ParsedVerilyEscrowInstruction {
  const ParsedVerilyEscrowInstruction(this.instructionType);

  final VerilyEscrowInstruction instructionType;
}

/// A parsed OpenEscrow instruction.
final class ParsedOpenEscrow extends ParsedVerilyEscrowInstruction {
  const ParsedOpenEscrow({required this.data})
    : super(VerilyEscrowInstruction.openEscrow);

  final OpenEscrowInstructionData data;
}

/// A parsed ReleasePayout instruction.
final class ParsedReleasePayout extends ParsedVerilyEscrowInstruction {
  const ParsedReleasePayout({required this.data})
    : super(VerilyEscrowInstruction.releasePayout);

  final ReleasePayoutInstructionData data;
}

/// A parsed EndEarly instruction.
final class ParsedEndEarly extends ParsedVerilyEscrowInstruction {
  const ParsedEndEarly({required this.data})
    : super(VerilyEscrowInstruction.endEarly);

  final EndEarlyInstructionData data;
}

/// A parsed CloseEscrow instruction.
final class ParsedCloseEscrow extends ParsedVerilyEscrowInstruction {
  const ParsedCloseEscrow({required this.data})
    : super(VerilyEscrowInstruction.closeEscrow);

  final CloseEscrowInstructionData data;
}

/// Parses a VerilyEscrow instruction.
ParsedVerilyEscrowInstruction parseVerilyEscrowInstruction(
  Instruction instruction,
) {
  return switch (identifyVerilyEscrowInstruction(
    instruction.data ?? Uint8List(0),
  )) {
    VerilyEscrowInstruction.openEscrow => ParsedOpenEscrow(
      data: parseOpenEscrowInstruction(instruction),
    ),
    VerilyEscrowInstruction.releasePayout => ParsedReleasePayout(
      data: parseReleasePayoutInstruction(instruction),
    ),
    VerilyEscrowInstruction.endEarly => ParsedEndEarly(
      data: parseEndEarlyInstruction(instruction),
    ),
    VerilyEscrowInstruction.closeEscrow => ParsedCloseEscrow(
      data: parseCloseEscrowInstruction(instruction),
    ),
  };
}
