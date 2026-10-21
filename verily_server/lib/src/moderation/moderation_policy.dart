/// Triage categories are labels for humans, not an automated safety classifier.
abstract final class ModerationPolicy {
  static const reviewScope = 'moderation.review';
  static const categories = {
    'spam',
    'harassment',
    'hate',
    'sexualExploitation',
    'childSafety',
    'violence',
    'selfHarm',
    'dangerousActivity',
    'privacy',
    'fraud',
    'other',
  };
  static const highRiskCategories = {
    'hate',
    'sexualExploitation',
    'childSafety',
    'violence',
    'selfHarm',
    'dangerousActivity',
    'privacy',
    'fraud',
  };
  static const appealWindow = Duration(days: 7);

  /// Unknown labels never silently become a low-risk decision.
  static bool requiresPrecautionaryPause(String category) {
    if (!categories.contains(category)) {
      throw ArgumentError('Choose a supported report category.');
    }

    return highRiskCategories.contains(category);
  }

  /// Checks explicit staff authority; being a creator and models confer no scope.
  static void requireStaff({
    required bool authenticated,
    required Set<String> scopes,
  }) {
    if (!authenticated || !scopes.contains(reviewScope)) {
      throw StateError('Staff review access is required.');
    }
  }

  /// Avoids self-review and requires a different reviewer for a safety appeal.
  static void requireIndependentReviewer({
    required String reviewerId,
    required String creatorId,
    required String? reporterId,
    String? originalReviewerId,
  }) {
    if (reviewerId == creatorId ||
        reviewerId == reporterId ||
        reviewerId == originalReviewerId) {
      throw StateError('An independent staff reviewer is required.');
    }
  }

  /// Bounds free text without pretending that keywords establish safety.
  static String text(String value, {int minimum = 10, int maximum = 1000}) {
    final normalized = value.trim();

    if (normalized.length < minimum || normalized.length > maximum) {
      throw ArgumentError('Use $minimum to $maximum characters.');
    }

    return normalized;
  }

  /// Appeals do not lift a pause while human review is pending.
  static bool canAppeal({
    required bool isCreator,
    required bool pauseActive,
    required DateTime? reviewedAt,
    required DateTime? appealedAt,
    required DateTime now,
  }) =>
      isCreator &&
      pauseActive &&
      reviewedAt != null &&
      appealedAt == null &&
      !now.isBefore(reviewedAt) &&
      now.isBefore(reviewedAt.add(appealWindow));
}
