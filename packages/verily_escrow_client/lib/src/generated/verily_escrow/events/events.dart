// Auto-generated. Do not edit.
// ignore_for_file: type=lint

export 'event_log.dart';
export 'escrow_opened.dart';
export 'payout_released.dart';
export 'escrow_ended.dart';
export 'escrow_closed.dart';

import 'event_log.dart';
import 'escrow_opened.dart';
import 'payout_released.dart';
import 'escrow_ended.dart';
import 'escrow_closed.dart';

/// The program whose invocation frames emit the events decoded here.
const verilyEscrowEventSourceAddress =
    'ANL35GQjGtSuCAHTbXGBjnevFqbEtKNf6wDGPKwuPN1p';

final _programInvokeLog = RegExp(r'^Program (\S+) invoke \[\d+\]$');
final _programExitLog = RegExp(r'^Program (\S+) (?:success|failed: .*)$');

/// Decode every `Program data:` line this program emitted in a transaction's
/// logs.
///
/// [logs] must be the complete, ordered log messages of one transaction. The
/// parser follows the runtime's `Program <address> invoke [n]` and
/// `Program <address> success` / `failed` frames and decodes a data line only
/// while [programAddress] is the innermost invoked program. Any program can
/// write a `Program data:` line with this program's discriminator, so data
/// lines from other programs (including ones this program invokes through CPI)
/// and lines outside any frame are skipped rather than trusted.
///
/// Unrelated lines are skipped. A line this program emitted that names an event
/// but carries a version no generated event describes throws instead of being
/// silently dropped. The per-event `parse*FromLog` helpers decode one line
/// without this attribution and are only safe for data already known to come
/// from this program.
List<VerilyEscrowEvent> parseVerilyEscrowEventsFromLogs(
  List<String> logs, {
  String programAddress = verilyEscrowEventSourceAddress,
}) {
  final discovered = <VerilyEscrowEvent>[];
  final frames = <String>[];
  for (final log in logs) {
    final invoke = _programInvokeLog.firstMatch(log);
    if (invoke != null) {
      frames.add(invoke.group(1)!);
      continue;
    }
    if (_programExitLog.hasMatch(log)) {
      if (frames.isNotEmpty) {
        frames.removeLast();
      }
      continue;
    }
    if (frames.isEmpty || frames.last != programAddress) {
      continue;
    }
    final escrowOpened = parseEscrowOpenedEventFromLog(log);
    if (escrowOpened != null) {
      discovered.add(escrowOpened);
      continue;
    }
    final payoutReleased = parsePayoutReleasedEventFromLog(log);
    if (payoutReleased != null) {
      discovered.add(payoutReleased);
      continue;
    }
    final escrowEnded = parseEscrowEndedEventFromLog(log);
    if (escrowEnded != null) {
      discovered.add(escrowEnded);
      continue;
    }
    final escrowClosed = parseEscrowClosedEventFromLog(log);
    if (escrowClosed != null) {
      discovered.add(escrowClosed);
      continue;
    }
  }
  return discovered;
}
