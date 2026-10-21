// Auto-generated. Do not edit.
// ignore_for_file: type=lint

import 'dart:typed_data';

import 'package:solana_kit_addresses/solana_kit_addresses.dart';
import 'package:solana_kit_codecs_core/solana_kit_codecs_core.dart';
import 'package:solana_kit_codecs_data_structures/solana_kit_codecs_data_structures.dart';
import 'package:solana_kit_codecs_numbers/solana_kit_codecs_numbers.dart';

import 'event_log.dart';

/// Event record `EscrowEnded`.
class EscrowEndedEvent extends VerilyEscrowEvent {
  const EscrowEndedEvent({
    required this.discriminator,
    required this.escrow,
    required this.poolId,
    required this.expiresAt,
    required this.refundAfter,
  });

  final int discriminator;
  final Address escrow;
  final Uint8List poolId;
  final BigInt expiresAt;
  final BigInt refundAfter;

  @override
  String get name => 'escrowEnded';

  String toString() =>
      'EscrowEndedEvent(discriminator: ${discriminator}, escrow: ${escrow}, poolId: ${poolId}, expiresAt: ${expiresAt}, refundAfter: ${refundAfter})';
}

/// The discriminator this event is emitted under.
const escrowEndedEventDiscriminator = 3;

/// The discriminator bytes as stored at offset zero.
const List<int> _escrowEndedEventDiscriminatorBytes = [3];

/// Exact current byte length of a `EscrowEnded` record, envelope included.
const escrowEndedEventSize = 65;

/// Decode one `EscrowEnded` record.
EscrowEndedEvent decodeEscrowEndedEvent(Uint8List data) {
  if (data.length != escrowEndedEventSize) {
    throw RangeError(
      'expected exactly ${escrowEndedEventSize} bytes, received ${data.length}',
    );
  }
  var cursor = 0;
  final (v0, c0) = getU8Decoder().read(data, cursor);
  cursor = c0;
  if (v0 != 3) {
    throw RangeError(
      'the provided bytes do not match the "EscrowEnded" event discriminator',
    );
  }
  final (v1, c1) = getAddressDecoder().read(data, cursor);
  cursor = c1;
  final (v2, c2) = fixDecoderSize(getBytesDecoder(), 16).read(data, cursor);
  cursor = c2;
  final (v3, c3) = getI64Decoder().read(data, cursor);
  cursor = c3;
  final (v4, c4) = getI64Decoder().read(data, cursor);
  cursor = c4;

  return EscrowEndedEvent(
    discriminator: v0,
    escrow: v1,
    poolId: v2,
    expiresAt: v3,
    refundAfter: v4,
  );
}

/// A decoded `EscrowEnded` log record.
typedef DecodedEscrowEndedEvent = EscrowEndedEvent;

/// Decode a `Program data:` log line, or return null when the line is not
/// this event.
EscrowEndedEvent? parseEscrowEndedEventFromLog(String log) {
  final bytes = decodeProgramDataLog(log);
  if (bytes == null || bytes.length < 1) {
    return null;
  }
  for (var index = 0; index < 1; index++) {
    if (bytes[index] != _escrowEndedEventDiscriminatorBytes[index]) {
      return null;
    }
  }
  return decodeEscrowEndedEvent(bytes);
}
