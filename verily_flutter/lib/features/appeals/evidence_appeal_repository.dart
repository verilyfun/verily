import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/core/api_client.dart';

/// Contesting a rejection, from both sides.
abstract interface class EvidenceAppealRepository {
  /// A participant contests the rejection of [attemptId]. Allowed once.
  Future<EvidenceAppealView> submit({
    required UuidValue attemptId,
    required String reason,
  });

  /// The participant's appeal on [attemptId], or null when there is none.
  Future<EvidenceAppealView?> getMine(UuidValue attemptId);

  /// Appeals on the caller's own actions.
  Future<List<EvidenceAppealView>> listOwned();

  /// The action's creator accepts or rejects an appeal with a [note].
  Future<EvidenceAppealView> resolve({
    required UuidValue appealId,
    required EvidenceAppealStatus decision,
    required String note,
  });
}

class ServerpodEvidenceAppealRepository implements EvidenceAppealRepository {
  const ServerpodEvidenceAppealRepository(this._client);

  final Client _client;

  @override
  Future<EvidenceAppealView> submit({
    required UuidValue attemptId,
    required String reason,
  }) => _client.evidenceAppeal.submit(attemptId: attemptId, reason: reason);

  @override
  Future<EvidenceAppealView?> getMine(UuidValue attemptId) =>
      _client.evidenceAppeal.getMine(attemptId: attemptId);

  @override
  Future<List<EvidenceAppealView>> listOwned() =>
      _client.evidenceAppeal.listOwned(limit: 50);

  @override
  Future<EvidenceAppealView> resolve({
    required UuidValue appealId,
    required EvidenceAppealStatus decision,
    required String note,
  }) => _client.evidenceAppeal.resolve(
    appealId: appealId,
    decision: decision,
    note: note,
  );
}

final evidenceAppealRepositoryProvider = Provider<EvidenceAppealRepository>(
  (ref) => ServerpodEvidenceAppealRepository(ref.watch(verilyClientProvider)),
);
