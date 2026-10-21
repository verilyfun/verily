import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/abuse/abuse_risk_policy.dart';
import 'package:verily_server/src/abuse/abuse_risk_service.dart';

void main() {
  test('requests one extra bounded row and applies policy', () async {
    final now = DateTime.utc(2026, 9, 4, 12);
    final candidate = _observation(1, now);
    final source = _HistorySource(const []);
    final service = AbuseRiskService(loadHistory: source.load);

    final decision = await service.evaluate(candidate);

    expect(decision.disposition, AbuseRiskDisposition.allow);
    expect(source.query?.candidate, same(candidate));
    expect(
      source.query?.startsAt,
      now.subtract(AbuseRiskPolicy.historyWindow),
    );
    expect(
      source.query?.limit,
      AbuseRiskPolicy.maxHistoryObservations + 1,
    );
  });

  test(
    'fails closed when a source returns the overflow sentinel row',
    () async {
      final now = DateTime.utc(2026, 9, 4, 12);
      final candidate = _observation(1, now);
      final source = _HistorySource(
        List.filled(AbuseRiskPolicy.maxHistoryObservations + 1, candidate),
      );
      final service = AbuseRiskService(loadHistory: source.load);

      final decision = await service.evaluate(candidate);

      expect(decision.disposition, AbuseRiskDisposition.manualReview);
      expect(decision.signals, [AbuseSignalCode.historyLimitExceeded]);
    },
  );

  test(
    'does not produce an allow decision when history loading fails',
    () async {
      final now = DateTime.utc(2026, 9, 4, 12);
      final service = AbuseRiskService(
        loadHistory: (_) => throw StateError('history unavailable'),
      );

      await expectLater(
        service.evaluate(_observation(1, now)),
        throwsA(isA<StateError>()),
      );
    },
  );
}

final class _HistorySource {
  _HistorySource(this.rows);

  final List<AbuseObservation> rows;
  AbuseHistoryQuery? query;

  Future<List<AbuseObservation>> load(AbuseHistoryQuery query) async {
    this.query = query;

    return rows;
  }
}

AbuseObservation _observation(int index, DateTime now) => AbuseObservation(
  accountPseudonym: _digest('account-$index'),
  creatorPseudonym: _digest('creator-$index'),
  actionPseudonym: _digest('action-$index'),
  attemptPseudonym: _digest('attempt-$index'),
  evidenceKind: AbuseEvidenceKind.video,
  capturedAt: now,
  receivedAt: now,
  evidenceDigest: _digest('evidence-$index'),
);

String _digest(String value) => sha256.convert(utf8.encode(value)).toString();
