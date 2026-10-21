// Auto-generated. Do not edit.
// ignore_for_file: type=lint

import 'dart:typed_data';

import 'package:solana_kit_addresses/solana_kit_addresses.dart';
import 'package:solana_kit_codecs_core/solana_kit_codecs_core.dart';
import 'package:solana_kit_codecs_data_structures/solana_kit_codecs_data_structures.dart';
import 'package:solana_kit_codecs_numbers/solana_kit_codecs_numbers.dart';

import 'event_log.dart';

/// Event record `EscrowClosed`.
class EscrowClosedEvent extends VerilyEscrowEvent {
  const EscrowClosedEvent({
    required this.discriminator,
    required this.escrow,
    required this.poolId,
    required this.refunded,
    required this.releasedCount,
    required this.released,
  });

  final int discriminator;
  final Address escrow;
  final Uint8List poolId;
  final BigInt refunded;
  final int releasedCount;
  final Uint8List released;

  @override
  String get name => 'escrowClosed';

  String toString() =>
      'EscrowClosedEvent(discriminator: ${discriminator}, escrow: ${escrow}, poolId: ${poolId}, refunded: ${refunded}, releasedCount: ${releasedCount}, released: ${released})';
}

/// The discriminator this event is emitted under.
const escrowClosedEventDiscriminator = 4;

/// The discriminator bytes as stored at offset zero.
const List<int> _escrowClosedEventDiscriminatorBytes = [4];

/// Exact current byte length of a `EscrowClosed` record, envelope included.
const escrowClosedEventSize = 315;

/// Decode one `EscrowClosed` record.
EscrowClosedEvent decodeEscrowClosedEvent(Uint8List data) {
  if (data.length != escrowClosedEventSize) {
    throw RangeError(
      'expected exactly ${escrowClosedEventSize} bytes, received ${data.length}',
    );
  }
  var cursor = 0;
  final (v0, c0) = getU8Decoder().read(data, cursor);
  cursor = c0;
  if (v0 != 4) {
    throw RangeError(
      'the provided bytes do not match the "EscrowClosed" event discriminator',
    );
  }
  final (v1, c1) = getAddressDecoder().read(data, cursor);
  cursor = c1;
  final (v2, c2) = fixDecoderSize(getBytesDecoder(), 16).read(data, cursor);
  cursor = c2;
  final (v3, c3) = getU64Decoder().read(data, cursor);
  cursor = c3;
  final (v4, c4) = getU16Decoder().read(data, cursor);
  cursor = c4;
  final (v5, c5) = fixDecoderSize(getBytesDecoder(), 256).read(data, cursor);
  cursor = c5;

  return EscrowClosedEvent(
    discriminator: v0,
    escrow: v1,
    poolId: v2,
    refunded: v3,
    releasedCount: v4,
    released: v5,
  );
}

/// A decoded `EscrowClosed` log record.
typedef DecodedEscrowClosedEvent = EscrowClosedEvent;

/// Decode a `Program data:` log line, or return null when the line is not
/// this event.
EscrowClosedEvent? parseEscrowClosedEventFromLog(String log) {
  final bytes = decodeProgramDataLog(log);
  if (bytes == null || bytes.length < 1) {
    return null;
  }
  for (var index = 0; index < 1; index++) {
    if (bytes[index] != _escrowClosedEventDiscriminatorBytes[index]) {
      return null;
    }
  }
  return decodeEscrowClosedEvent(bytes);
}
