// Auto-generated. Do not edit.
// ignore_for_file: type=lint

import 'dart:typed_data';

import 'package:solana_kit_addresses/solana_kit_addresses.dart';
import 'package:solana_kit_codecs_core/solana_kit_codecs_core.dart';
import 'package:solana_kit_codecs_data_structures/solana_kit_codecs_data_structures.dart';
import 'package:solana_kit_codecs_numbers/solana_kit_codecs_numbers.dart';

import 'event_log.dart';

/// Event record `PayoutReleased`.
class PayoutReleasedEvent extends VerilyEscrowEvent {
  const PayoutReleasedEvent({
    required this.discriminator,
    required this.escrow,
    required this.poolId,
    required this.index,
    required this.recipient,
    required this.amount,
  });

  final int discriminator;
  final Address escrow;
  final Uint8List poolId;
  final int index;
  final Address recipient;
  final BigInt amount;

  @override
  String get name => 'payoutReleased';

  String toString() =>
      'PayoutReleasedEvent(discriminator: ${discriminator}, escrow: ${escrow}, poolId: ${poolId}, index: ${index}, recipient: ${recipient}, amount: ${amount})';
}

/// The discriminator this event is emitted under.
const payoutReleasedEventDiscriminator = 2;

/// The discriminator bytes as stored at offset zero.
const List<int> _payoutReleasedEventDiscriminatorBytes = [2];

/// Exact current byte length of a `PayoutReleased` record, envelope included.
const payoutReleasedEventSize = 91;

/// Decode one `PayoutReleased` record.
PayoutReleasedEvent decodePayoutReleasedEvent(Uint8List data) {
  if (data.length != payoutReleasedEventSize) {
    throw RangeError(
      'expected exactly ${payoutReleasedEventSize} bytes, received ${data.length}',
    );
  }
  var cursor = 0;
  final (v0, c0) = getU8Decoder().read(data, cursor);
  cursor = c0;
  if (v0 != 2) {
    throw RangeError(
      'the provided bytes do not match the "PayoutReleased" event discriminator',
    );
  }
  final (v1, c1) = getAddressDecoder().read(data, cursor);
  cursor = c1;
  final (v2, c2) = fixDecoderSize(getBytesDecoder(), 16).read(data, cursor);
  cursor = c2;
  final (v3, c3) = getU16Decoder().read(data, cursor);
  cursor = c3;
  final (v4, c4) = getAddressDecoder().read(data, cursor);
  cursor = c4;
  final (v5, c5) = getU64Decoder().read(data, cursor);
  cursor = c5;

  return PayoutReleasedEvent(
    discriminator: v0,
    escrow: v1,
    poolId: v2,
    index: v3,
    recipient: v4,
    amount: v5,
  );
}

/// A decoded `PayoutReleased` log record.
typedef DecodedPayoutReleasedEvent = PayoutReleasedEvent;

/// Decode a `Program data:` log line, or return null when the line is not
/// this event.
PayoutReleasedEvent? parsePayoutReleasedEventFromLog(String log) {
  final bytes = decodeProgramDataLog(log);
  if (bytes == null || bytes.length < 1) {
    return null;
  }
  for (var index = 0; index < 1; index++) {
    if (bytes[index] != _payoutReleasedEventDiscriminatorBytes[index]) {
      return null;
    }
  }
  return decodePayoutReleasedEvent(bytes);
}
