// Auto-generated. Do not edit.
// ignore_for_file: type=lint

import 'dart:typed_data';

import 'package:solana_kit_addresses/solana_kit_addresses.dart';
import 'package:solana_kit_codecs_core/solana_kit_codecs_core.dart';
import 'package:solana_kit_codecs_data_structures/solana_kit_codecs_data_structures.dart';
import 'package:solana_kit_codecs_numbers/solana_kit_codecs_numbers.dart';

import 'event_log.dart';

/// Event record `EscrowOpened`.
class EscrowOpenedEvent extends VerilyEscrowEvent {
  const EscrowOpenedEvent({
    required this.discriminator,
    required this.escrow,
    required this.creator,
    required this.arbiter,
    required this.mint,
    required this.vault,
    required this.poolId,
    required this.amountPerPayout,
    required this.maxPayouts,
    required this.expiresAt,
    required this.refundAfter,
  });

  final int discriminator;
  final Address escrow;
  final Address creator;
  final Address arbiter;
  final Address mint;
  final Address vault;
  final Uint8List poolId;
  final BigInt amountPerPayout;
  final int maxPayouts;
  final BigInt expiresAt;
  final BigInt refundAfter;

  @override
  String get name => 'escrowOpened';

  String toString() =>
      'EscrowOpenedEvent(discriminator: ${discriminator}, escrow: ${escrow}, creator: ${creator}, arbiter: ${arbiter}, mint: ${mint}, vault: ${vault}, poolId: ${poolId}, amountPerPayout: ${amountPerPayout}, maxPayouts: ${maxPayouts}, expiresAt: ${expiresAt}, refundAfter: ${refundAfter})';
}

/// The discriminator this event is emitted under.
const escrowOpenedEventDiscriminator = 1;

/// The discriminator bytes as stored at offset zero.
const List<int> _escrowOpenedEventDiscriminatorBytes = [1];

/// Exact current byte length of a `EscrowOpened` record, envelope included.
const escrowOpenedEventSize = 203;

/// Decode one `EscrowOpened` record.
EscrowOpenedEvent decodeEscrowOpenedEvent(Uint8List data) {
  if (data.length != escrowOpenedEventSize) {
    throw RangeError(
      'expected exactly ${escrowOpenedEventSize} bytes, received ${data.length}',
    );
  }
  var cursor = 0;
  final (v0, c0) = getU8Decoder().read(data, cursor);
  cursor = c0;
  if (v0 != 1) {
    throw RangeError(
      'the provided bytes do not match the "EscrowOpened" event discriminator',
    );
  }
  final (v1, c1) = getAddressDecoder().read(data, cursor);
  cursor = c1;
  final (v2, c2) = getAddressDecoder().read(data, cursor);
  cursor = c2;
  final (v3, c3) = getAddressDecoder().read(data, cursor);
  cursor = c3;
  final (v4, c4) = getAddressDecoder().read(data, cursor);
  cursor = c4;
  final (v5, c5) = getAddressDecoder().read(data, cursor);
  cursor = c5;
  final (v6, c6) = fixDecoderSize(getBytesDecoder(), 16).read(data, cursor);
  cursor = c6;
  final (v7, c7) = getU64Decoder().read(data, cursor);
  cursor = c7;
  final (v8, c8) = getU16Decoder().read(data, cursor);
  cursor = c8;
  final (v9, c9) = getI64Decoder().read(data, cursor);
  cursor = c9;
  final (v10, c10) = getI64Decoder().read(data, cursor);
  cursor = c10;

  return EscrowOpenedEvent(
    discriminator: v0,
    escrow: v1,
    creator: v2,
    arbiter: v3,
    mint: v4,
    vault: v5,
    poolId: v6,
    amountPerPayout: v7,
    maxPayouts: v8,
    expiresAt: v9,
    refundAfter: v10,
  );
}

/// A decoded `EscrowOpened` log record.
typedef DecodedEscrowOpenedEvent = EscrowOpenedEvent;

/// Decode a `Program data:` log line, or return null when the line is not
/// this event.
EscrowOpenedEvent? parseEscrowOpenedEventFromLog(String log) {
  final bytes = decodeProgramDataLog(log);
  if (bytes == null || bytes.length < 1) {
    return null;
  }
  for (var index = 0; index < 1; index++) {
    if (bytes[index] != _escrowOpenedEventDiscriminatorBytes[index]) {
      return null;
    }
  }
  return decodeEscrowOpenedEvent(bytes);
}
