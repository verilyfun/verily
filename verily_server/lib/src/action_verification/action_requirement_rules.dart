import 'package:serverpod/serverpod.dart';
import 'package:verily_evidence/verily_evidence.dart';
import 'package:verily_server/src/action_verification/action_draft_refusal.dart';
import 'package:verily_server/src/action_verification/local_check/local_check_catalog.dart';
import 'package:verily_server/src/action_verification/model_input_security.dart';
import 'package:verily_server/src/action_verification/movement_verification_policy.dart';
import 'package:verily_server/src/evidence_storage/evidence_media_types.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/security/secret_digest.dart';

const maxActionRequirements = 5;
const _minimumQrCodeLength = 8;

/// Recording bounds for video and audio proof.
const minRecordingSeconds = 3;
const maxRecordingSeconds = 300;

/// One requirement draft after validation, with its normalized identity.
final class ValidatedRequirement {
  const ValidatedRequirement({
    required this.draft,
    required this.key,
    required this.title,
    required this.instructions,
    required this.position,
    required this.spokenChallengeRequired,
  });

  final ActionRequirementDraft draft;
  final String key;
  final String title;
  final String instructions;
  final int position;

  /// Resolved default: on for video and audio unless the creator opted out.
  final bool spokenChallengeRequired;
}

/// Validates one requirement draft against the server-owned allow-list.
///
/// Media verifier text is creator-written only for free-form proof; tracked
/// movements derive theirs on the server. Every free-form policy passes the
/// central model-input security check before it can be persisted.
///
/// Throws [ActionDraftRefusal] for a broken rule and
/// [ModelInputSecurityException] for unsafe verifier text.
ValidatedRequirement validateRequirementDraft(
  ActionRequirementDraft draft,
  int position,
) {
  final key = requiredSlug(draft.requirementKey, 'requirementKey');
  final title = requiredText(draft.title, 'requirement title', maxLength: 120);
  final instructions = requiredText(
    draft.instructions,
    'instructions',
  );
  if (draft.kind != ActionRequirementKind.externalApp &&
      (draft.appId != null || draft.appVerificationMode != null)) {
    throw const ActionDraftRefusal(
      'Only app-confirmed requirements name an app.',
    );
  }
  final mediaKind = mediaKindOf(draft.kind);
  if (mediaKind == null &&
      (draft.verificationPrompt != null ||
          draft.minConfidence != null ||
          draft.verificationPolicy != null ||
          draft.spokenChallengeRequired != null ||
          draft.movementKind != null ||
          draft.localCheck != null)) {
    throw const ActionDraftRefusal(
      'Media verification settings need a media proof.',
    );
  }
  var spokenChallengeRequired = false;
  switch (draft.kind) {
    case ActionRequirementKind.externalApp:
      if (draft.appId == null) {
        throw const ActionDraftRefusal(
          'Choose the app that confirms this proof.',
        );
      }
    case ActionRequirementKind.location:
      final latitude = draft.latitude;
      final longitude = draft.longitude;
      final radius = draft.radiusMeters;
      final accuracy = draft.maxAccuracyMeters;
      if (latitude == null ||
          longitude == null ||
          !validCoordinates(latitude, longitude)) {
        throw const ActionDraftRefusal(
          'Location requirements need valid coordinates.',
        );
      }
      if (radius == null || !radius.isFinite || radius < 10 || radius > 5000) {
        throw const ActionDraftRefusal(
          'Location radius must be between 10m and 5km.',
        );
      }
      if (accuracy == null ||
          !accuracy.isFinite ||
          accuracy <= 0 ||
          accuracy > 1000) {
        throw const ActionDraftRefusal(
          'Location accuracy must be between 0m and 1km.',
        );
      }
    case ActionRequirementKind.video ||
        ActionRequirementKind.photo ||
        ActionRequirementKind.audio:
      spokenChallengeRequired = _validateMediaDraft(draft, mediaKind!);
    case ActionRequirementKind.qrCode:
      // A null code keeps the secret stored for this requirement key; the
      // authoring service resolves it, or refuses when there is none.
      if (draft.qrCode case final value?) {
        final code = requiredText(value, 'qrCode', maxLength: 512);
        if (code.length < _minimumQrCodeLength) {
          throw const ActionDraftRefusal(
            'QR codes need at least $_minimumQrCodeLength characters.',
          );
        }
      }
    case ActionRequirementKind.motion:
      final rule = _motionRuleFromDraft(draft);
      if (const MotionEvidenceAnalyzer().ruleProblem(rule)
          case final problem?) {
        throw ActionDraftRefusal(problem);
      }
  }
  return ValidatedRequirement(
    draft: draft,
    key: key,
    title: title,
    instructions: instructions,
    position: position,
    spokenChallengeRequired: spokenChallengeRequired,
  );
}

/// Returns whether the spoken challenge applies.
bool _validateMediaDraft(ActionRequirementDraft draft, MediaEvidenceKind kind) {
  final movement = draft.movementKind;
  if (movement != null && kind != MediaEvidenceKind.video) {
    throw const ActionDraftRefusal('Tracked movements are recorded as video.');
  }
  final localCheck = draft.localCheck;
  if (localCheck != null) {
    if (movement != null) {
      throw const ActionDraftRefusal(
        'A tracked movement cannot also run a local check.',
      );
    }
    validateLocalCheck(localCheck, kind);
  }
  if (movement == null &&
      (localCheck == null || draft.verificationPrompt != null)) {
    if (draft.targetRepetitions != null) {
      throw const ActionDraftRefusal('Repetition targets need a movement.');
    }
    ModelInputSecurity.validateVerificationPolicy(
      requiredText(
        draft.verificationPrompt ?? '',
        'verificationPrompt',
        minLength: ModelInputSecurity.minVerificationPolicyLength,
        maxLength: ModelInputSecurity.maxVerificationPolicyLength,
      ),
    );
  } else if (movement == null && draft.targetRepetitions != null) {
    throw const ActionDraftRefusal('Repetition targets need a movement.');
  } else if (draft.verificationPrompt != null) {
    throw const ActionDraftRefusal(
      'Movement checks are written by the server, not the creator.',
    );
  }
  final minimum = draft.minDurationSeconds;
  final maximum = draft.maxDurationSeconds;
  if (kind == MediaEvidenceKind.photo) {
    if (minimum != null || maximum != null) {
      throw const ActionDraftRefusal('A photo has no duration.');
    }
    if (draft.spokenChallengeRequired ?? false) {
      throw const ActionDraftRefusal(
        'A photo cannot carry a spoken challenge.',
      );
    }
  } else {
    if (minimum == null ||
        maximum == null ||
        minimum < minRecordingSeconds ||
        maximum > maxRecordingSeconds) {
      throw const ActionDraftRefusal(
        'Recordings must last between $minRecordingSeconds and '
        '$maxRecordingSeconds seconds.',
      );
    }
    if (maximum < minimum) {
      throw const ActionDraftRefusal(
        'The longest recording must exceed the shortest.',
      );
    }
  }
  final confidence = draft.minConfidence;
  if (confidence == null ||
      !confidence.isFinite ||
      confidence < 0 ||
      confidence > 1) {
    throw const ActionDraftRefusal(
      'Verification confidence must be between 0 and 1.',
    );
  }
  if (movement != null) {
    validateMovementTarget(movement, draft.targetRepetitions, maximum!);
  }
  // A local check cannot hear a word, so the challenge is opt-in there;
  // otherwise it is on by default for recordings.
  return kind != MediaEvidenceKind.photo &&
      (draft.spokenChallengeRequired ?? localCheck == null);
}

/// Persists the rule row for one validated requirement.
///
/// A venue-code requirement saved with `qrCode: null` stores
/// [inheritedQrSecretHash], the hash already stored for its requirement key.
Future<void> insertRequirementRule(
  Session session,
  UuidValue requirementId,
  ValidatedRequirement requirement,
  Transaction transaction, {
  String? inheritedQrSecretHash,
}) async {
  final draft = requirement.draft;
  switch (draft.kind) {
    case ActionRequirementKind.location:
      await ActionLocationRule.db.insertRow(
        session,
        ActionLocationRule(
          requirementId: requirementId,
          location: GeographyPoint(
            latitude: draft.latitude!,
            longitude: draft.longitude!,
          ),
          radiusMeters: draft.radiusMeters!,
          maxAccuracyMeters: draft.maxAccuracyMeters!,
        ),
        transaction: transaction,
      );
    case ActionRequirementKind.video ||
        ActionRequirementKind.photo ||
        ActionRequirementKind.audio:
      await ActionMediaRule.db.insertRow(
        session,
        ActionMediaRule(
          requirementId: requirementId,
          kind: draft.kind,
          verificationPrompt: switch ((draft.movementKind, draft.localCheck)) {
            (final movement?, _) => movementVerificationPrompt(
              movement,
              draft.targetRepetitions!,
            ),
            (null, final check?) when draft.verificationPrompt == null =>
              localCheckVerificationPrompt(check),
            _ => draft.verificationPrompt!.trim(),
          },
          minDurationSeconds: draft.minDurationSeconds,
          maxDurationSeconds: draft.maxDurationSeconds,
          minConfidence: draft.minConfidence!,
          verificationPolicy:
              draft.verificationPolicy ?? ActionVerificationPolicy.singleModel,
          spokenChallengeRequired: requirement.spokenChallengeRequired,
          movementKind: draft.movementKind,
          targetRepetitions: draft.movementKind == null
              ? null
              : draft.targetRepetitions,
          localCheckTask: draft.localCheck?.task,
          localCheckLabel: draft.localCheck?.label,
          localCheckMinScore: draft.localCheck?.minScore,
          localCheckMinFrames: draft.localCheck?.minFrames,
        ),
        transaction: transaction,
      );
    case ActionRequirementKind.qrCode:
      await ActionQrRule.db.insertRow(
        session,
        ActionQrRule(
          requirementId: requirementId,
          secretHash: switch (draft.qrCode) {
            final code? => secretSha256Hex(code),
            // Authoring refuses a draft that leaves out a code it has no
            // stored secret for, so a missing one here is a bug.
            null =>
              inheritedQrSecretHash ??
                  (throw ArgumentError('Enter the venue code for this proof.')),
          },
        ),
        transaction: transaction,
      );
    case ActionRequirementKind.externalApp:
      await ActionExternalRule.db.insertRow(
        session,
        ActionExternalRule(
          requirementId: requirementId,
          appId: draft.appId!,
          verificationMode:
              draft.appVerificationMode ?? AppVerificationMode.push,
        ),
        transaction: transaction,
      );
    case ActionRequirementKind.motion:
      await ActionMotionRule.db.insertRow(
        session,
        ActionMotionRule(
          requirementId: requirementId,
          motionType: draft.motionType!,
          axis: draft.motionAxis!,
          targetRepetitions: draft.targetRepetitions!,
          minDurationSeconds: draft.minDurationSeconds!,
          maxDurationSeconds: draft.maxDurationSeconds!,
          minAngularSpeedRadiansPerSecond:
              draft.minAngularSpeedRadiansPerSecond!,
          maxAngularSpeedRadiansPerSecond:
              draft.maxAngularSpeedRadiansPerSecond!,
          minAxisDominance: draft.minAxisDominance!,
          minFreeFallMilliseconds: draft.minFreeFallMilliseconds!,
          maxFreeFallMilliseconds: draft.maxFreeFallMilliseconds!,
          minPeakAccelerationMetersPerSecondSquared:
              draft.minPeakAccelerationMetersPerSecondSquared!,
          maxPeakAccelerationMetersPerSecondSquared:
              draft.maxPeakAccelerationMetersPerSecondSquared!,
        ),
        transaction: transaction,
      );
  }
}

/// v1 limit: an action is either confirmed by Apps or proven on the phone,
/// never both. An App confirmation and a phone proof can land in different
/// attempt periods (the App reports when the act happened), which would split
/// one completion across two attempts. A database trigger backs this up.
void assertExternalProofNotMixed(Iterable<ActionRequirementKind> kinds) {
  final external = kinds.where(
    (kind) => kind == ActionRequirementKind.externalApp,
  );
  if (external.isNotEmpty && external.length != kinds.length) {
    throw ActionAuthoringException(
      reason: ActionAuthoringProblem.externalProofMixed,
      message: 'App confirmations cannot be combined with phone proof.',
    );
  }
}

MotionEvidenceRule _motionRuleFromDraft(ActionRequirementDraft draft) {
  final motionType = draft.motionType;
  final motionAxis = draft.motionAxis;
  final targetRepetitions = draft.targetRepetitions;
  final minDuration = draft.minDurationSeconds;
  final maxDuration = draft.maxDurationSeconds;
  final minAngularSpeed = draft.minAngularSpeedRadiansPerSecond;
  final maxAngularSpeed = draft.maxAngularSpeedRadiansPerSecond;
  final minAxisDominance = draft.minAxisDominance;
  final minFreeFall = draft.minFreeFallMilliseconds;
  final maxFreeFall = draft.maxFreeFallMilliseconds;
  final minPeakAcceleration = draft.minPeakAccelerationMetersPerSecondSquared;
  final maxPeakAcceleration = draft.maxPeakAccelerationMetersPerSecondSquared;
  if (motionType == null ||
      motionAxis == null ||
      targetRepetitions == null ||
      minDuration == null ||
      maxDuration == null ||
      minAngularSpeed == null ||
      maxAngularSpeed == null ||
      minAxisDominance == null ||
      minFreeFall == null ||
      maxFreeFall == null ||
      minPeakAcceleration == null ||
      maxPeakAcceleration == null) {
    throw const ActionDraftRefusal(
      'Motion requirements need complete thresholds.',
    );
  }
  return MotionEvidenceRule(
    type: MotionActionType.values.byName(motionType.name),
    axis: MotionAxis.values.byName(motionAxis.name),
    targetRepetitions: targetRepetitions,
    minimumDurationSeconds: minDuration,
    maximumDurationSeconds: maxDuration,
    minimumAngularSpeedRadiansPerSecond: minAngularSpeed,
    maximumAngularSpeedRadiansPerSecond: maxAngularSpeed,
    minimumAxisDominance: minAxisDominance,
    minimumFreeFallMilliseconds: minFreeFall,
    maximumFreeFallMilliseconds: maxFreeFall,
    minimumPeakAccelerationMetersPerSecondSquared: minPeakAcceleration,
    maximumPeakAccelerationMetersPerSecondSquared: maxPeakAcceleration,
  );
}

/// The persisted motion rule as the shared analyzer's rule.
MotionEvidenceRule motionEvidenceRule(ActionMotionRule rule) {
  return MotionEvidenceRule(
    type: MotionActionType.values.byName(rule.motionType.name),
    axis: MotionAxis.values.byName(rule.axis.name),
    targetRepetitions: rule.targetRepetitions,
    minimumDurationSeconds: rule.minDurationSeconds,
    maximumDurationSeconds: rule.maxDurationSeconds,
    minimumAngularSpeedRadiansPerSecond: rule.minAngularSpeedRadiansPerSecond,
    maximumAngularSpeedRadiansPerSecond: rule.maxAngularSpeedRadiansPerSecond,
    minimumAxisDominance: rule.minAxisDominance,
    minimumFreeFallMilliseconds: rule.minFreeFallMilliseconds,
    maximumFreeFallMilliseconds: rule.maxFreeFallMilliseconds,
    minimumPeakAccelerationMetersPerSecondSquared:
        rule.minPeakAccelerationMetersPerSecondSquared,
    maximumPeakAccelerationMetersPerSecondSquared:
        rule.maxPeakAccelerationMetersPerSecondSquared,
  );
}

/// PostGIS silently wraps out-of-range geography coordinates, so every caller
/// validates ranges before a point reaches the database.
bool validCoordinates(double latitude, double longitude) {
  return latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

/// The trimmed draft text of field [name], refused with
/// [ActionDraftRefusal] when it is empty or outside the length bounds.
String requiredText(
  String value,
  String name, {
  int minLength = 1,
  int maxLength = 1000,
}) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ActionDraftRefusal('$name is required.');
  if (normalized.length < minLength) {
    throw ActionDraftRefusal('$name must be $minLength characters or more.');
  }
  if (normalized.length > maxLength) {
    throw ActionDraftRefusal('$name must be $maxLength characters or fewer.');
  }
  return normalized;
}

/// The lowercase draft key of field [name], refused with
/// [ActionDraftRefusal] unless it is a 3-64 character slug.
String requiredSlug(String value, String name) {
  final normalized = requiredText(value, name).toLowerCase();
  if (!RegExp(r'^[a-z0-9][a-z0-9-]{1,62}[a-z0-9]$').hasMatch(normalized)) {
    throw ActionDraftRefusal(
      '$name must contain 3-64 lowercase letters, numbers, or hyphens.',
    );
  }
  return normalized;
}
