import 'package:verily_server/src/abuse/abuse_risk_policy.dart';

/// A bounded history request for one private candidate observation.
final class AbuseHistoryQuery {
  const AbuseHistoryQuery({
    required this.candidate,
    required this.startsAt,
    required this.limit,
  });

  final AbuseObservation candidate;
  final DateTime startsAt;
  final int limit;
}

/// Loads pseudonymized facts without coupling the policy to PostgreSQL.
typedef AbuseHistoryLoader = Future<List<AbuseObservation>> Function(
  AbuseHistoryQuery query,
);

/// Applies the risk policy to a source that must honor the bounded query.
///
/// Loader failures deliberately propagate so a protected transaction cannot
/// authorize an achievement or reward from an unavailable risk history.
final class AbuseRiskService {
  const AbuseRiskService({
    required this.loadHistory,
    this.policy = const AbuseRiskPolicy(),
  });

  final AbuseHistoryLoader loadHistory;
  final AbuseRiskPolicy policy;

  Future<AbuseRiskDecision> evaluate(AbuseObservation candidate) async {
    final history = await loadHistory(
      AbuseHistoryQuery(
        candidate: candidate,
        startsAt: candidate.receivedAt.subtract(
          AbuseRiskPolicy.historyWindow,
        ),
        // Security: the extra row lets the policy detect a truncated result
        // instead of silently treating incomplete history as low risk.
        limit: AbuseRiskPolicy.maxHistoryObservations + 1,
      ),
    );

    return policy.evaluate(candidate: candidate, history: history);
  }
}
