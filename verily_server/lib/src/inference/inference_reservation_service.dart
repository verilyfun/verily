import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/inference/inference_cost_policy.dart';

/// Commits one durable cost reservation before each external model request.
///
/// Reservations are keyed by attempt: the caps bound what one attempt can
/// spend across every proof, council member, and retry. There is no funding
/// precondition; the per-attempt caps and the per-account attempt limits are
/// the spend controls. An unknown outcome stays charged, so a retry can never
/// obtain free inference.
class InferenceReservationService {
  const InferenceReservationService({
    this.policy = const InferenceCostPolicy.disabled(),
  });

  final InferenceCostPolicy policy;

  /// Reserves one call in its own committed transaction.
  ///
  /// Concurrent council calls for one attempt serialize on a transaction
  /// advisory lock, so they cannot both pass the cap check.
  Future<void> reserve(
    Session session, {
    required UuidValue actionAttemptId,
    required String callReference,
    required String modelId,
  }) async {
    final cost = policy.costFor(modelId);
    if (callReference.isEmpty || callReference.length > 240) {
      throw ArgumentError('Invalid inference call reference.');
    }

    await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        await session.db.unsafeQuery(
          'SELECT pg_advisory_xact_lock(hashtextextended(@lockKey, 0));',
          parameters: QueryParameters.named({
            'lockKey': 'verily:inference:$actionAttemptId',
          }),
          transaction: transaction,
        );
        final reservations = await InferenceCostReservation.db.find(
          session,
          where: (table) => table.actionAttemptId.equals(actionAttemptId),
          transaction: transaction,
          limit: maxInferenceCallsPerAttempt + 1,
        );
        if (reservations.any((row) => row.callReference == callReference)) {
          throw StateError('Inference call was already reserved.');
        }
        policy.checkReservation(
          reservedMicros: reservations.fold(
            0,
            (total, row) => total + row.reservedMicros,
          ),
          calls: reservations.length,
          nextCostMicros: cost,
        );
        await InferenceCostReservation.db.insertRow(
          session,
          InferenceCostReservation(
            actionAttemptId: actionAttemptId,
            callReference: callReference,
            modelId: modelId,
            policyVersion: policy.version,
            reservedMicros: cost,
          ),
          transaction: transaction,
        );
      },
    );
  }
}
