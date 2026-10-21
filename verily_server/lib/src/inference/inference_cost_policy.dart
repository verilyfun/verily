/// Absolute ceiling on the approved worst-case cost of verifying one attempt,
/// in micro-units of the deployment's billing currency. Raising it is a
/// reviewed change, not a deployment setting.
const maxInferenceMicrosPerAttempt = 50000;

/// Absolute ceiling on external model calls for one attempt, including
/// council members and retries.
const maxInferenceCallsPerAttempt = 12;

/// Thrown when an attempt has no approved inference budget left. Callers
/// route the proof to a person instead of calling a model.
class InferenceBudgetExhaustedException implements Exception {
  const InferenceBudgetExhaustedException(this.reasonCode);

  /// A stable code safe to persist on a verification vote.
  final String reasonCode;

  @override
  String toString() => 'InferenceBudgetExhaustedException: $reasonCode';
}

/// Approved worst-case all-in request costs, including media and output limits.
/// Untrusted provider usage never releases a reservation or raises this cap.
class InferenceCostPolicy {
  const InferenceCostPolicy({
    required this.version,
    required this.maxMicrosPerAttempt,
    required this.maxCallsPerAttempt,
    required this.modelMaxCostMicros,
  });

  /// No model call is approved. Every reservation fails closed.
  const InferenceCostPolicy.disabled()
    : version = 'disabled',
      maxMicrosPerAttempt = 0,
      maxCallsPerAttempt = 0,
      modelMaxCostMicros = const {};

  final String version;
  final int maxMicrosPerAttempt;
  final int maxCallsPerAttempt;
  final Map<String, int> modelMaxCostMicros;

  bool get isDisabled => version == 'disabled';

  /// The approved worst-case cost of one call to [modelId].
  int costFor(String modelId) {
    final cost = modelMaxCostMicros[modelId];

    if (isDisabled ||
        version.isEmpty ||
        version.length > 80 ||
        cost == null ||
        cost <= 0 ||
        maxMicrosPerAttempt <= 0 ||
        maxMicrosPerAttempt > maxInferenceMicrosPerAttempt ||
        cost > maxMicrosPerAttempt ||
        maxCallsPerAttempt < 1 ||
        maxCallsPerAttempt > maxInferenceCallsPerAttempt) {
      throw const InferenceBudgetExhaustedException(
        'verification_budget_unapproved',
      );
    }

    return cost;
  }

  /// Throws when one more call of [nextCostMicros] would exceed a cap.
  void checkReservation({
    required int reservedMicros,
    required int calls,
    required int nextCostMicros,
  }) {
    if (reservedMicros < 0 ||
        calls < 0 ||
        nextCostMicros <= 0 ||
        calls >= maxCallsPerAttempt ||
        reservedMicros + nextCostMicros > maxMicrosPerAttempt) {
      throw const InferenceBudgetExhaustedException(
        'verification_budget_exhausted',
      );
    }
  }
}
