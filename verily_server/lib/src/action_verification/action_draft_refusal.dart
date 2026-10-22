/// An action draft broke an authoring rule its creator, or the App writing
/// it, can fix: a missing title, an out-of-range radius, a repeated
/// requirement key.
///
/// Authoring validation throws this, and only for input the client sent.
/// Callers that face a client turn it into a typed refusal: the RPC endpoint
/// into `ActionAuthoringProblem.invalidRequest` and the App API into
/// `invalid_request`. An [ArgumentError] or [StateError] from the same write
/// is a bug and still surfaces as one.
///
/// A draft the server builds itself, such as a verification request's
/// private action, can only fail these rules through a bug, so its caller
/// lets this propagate.
final class ActionDraftRefusal implements Exception {
  const ActionDraftRefusal(this.message);

  /// Names the broken rule for developers, in product-safe words, without
  /// repeating text from the draft.
  final String message;

  @override
  String toString() => 'ActionDraftRefusal: $message';
}
