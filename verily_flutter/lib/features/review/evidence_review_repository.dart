import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/core/api_client.dart';

/// Proof waiting for a person. Requires the `evidence.review` scope; the
/// server refuses everyone else.
abstract interface class EvidenceReviewRepository {
  /// Each item carries a five-minute private link to the pinned media.
  Future<List<EvidenceReviewQueueItem>> listQueue();

  /// Accepts or rejects one proof with a [note] for the record. Accepting
  /// completes the attempt.
  Future<ActionAttemptView> review({
    required UuidValue evidenceId,
    required EvidenceDecisionStatus decision,
    required String note,
  });
}

class ServerpodEvidenceReviewRepository implements EvidenceReviewRepository {
  const ServerpodEvidenceReviewRepository(this._client);

  final Client _client;

  @override
  Future<List<EvidenceReviewQueueItem>> listQueue() =>
      _client.evidenceReview.listQueue(limit: 50);

  @override
  Future<ActionAttemptView> review({
    required UuidValue evidenceId,
    required EvidenceDecisionStatus decision,
    required String note,
  }) => _client.evidenceReview.review(
    evidenceId: evidenceId,
    decision: decision,
    note: note,
  );
}

final evidenceReviewRepositoryProvider = Provider<EvidenceReviewRepository>(
  (ref) => ServerpodEvidenceReviewRepository(ref.watch(verilyClientProvider)),
);
