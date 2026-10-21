import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:verily_client/verily_client.dart';
import 'package:verily_evidence/verily_evidence.dart';

import 'package:verily_flutter/core/token_amount.dart';

/// The proofs the editor offers. Movement reps are a `video` requirement with
/// a movement kind; App confirmation is the `externalApp` kind.
enum ProofKind {
  location,
  venueCode,
  motion,
  movementReps,
  video,
  photo,
  audio,
  appConfirmation;

  /// Whether this proof is captured on the phone (everything but an App's
  /// confirmation). Phone proof and App confirmation never mix.
  bool get isPhoneProof => this != ProofKind.appConfirmation;

  /// Whether this proof is a recording that can carry a spoken challenge.
  bool get isRecording =>
      this == ProofKind.video ||
      this == ProofKind.audio ||
      this == ProofKind.movementReps;

  /// Whether the creator writes what Verily should check.
  bool get hasVerificationPrompt =>
      this == ProofKind.video ||
      this == ProofKind.photo ||
      this == ProofKind.audio;

  bool get isMedia => hasVerificationPrompt || this == ProofKind.movementReps;
}

/// Server limits the editor mirrors so a creator learns about them before
/// saving (see `action_requirement_rules.dart` and `RewardBounds`).
abstract final class EditorLimits {
  static const maxRequirements = 5;
  static const minRecordingSeconds = 3;
  static const maxRecordingSeconds = 300;
  static const minRadiusMeters = 10.0;
  static const maxRadiusMeters = 5000.0;
  static const maxMovementRepetitions = 1000;
  static const int maxMotionRepetitions =
      MotionEvidenceAnalyzer.maximumRuleRepetitions;
  static final int maxMotionSeconds =
      MotionEvidenceAnalyzer.maximumDuration.inSeconds;
  static const maxTitleLength = 120;
  static const maxDescriptionLength = 1000;
  static const maxInstructionsLength = 1000;
  static const minVerificationPromptLength = 10;
  static const maxVerificationPromptLength = 2000;
  static const minDraftPromptLength = 20;
  static const maxDraftPromptLength = 2000;
  static const maxTimeZoneLength = 64;
  static const maxPayouts = 2048;
  static const maxWinsPerAccount = 365;
  static const minRefundDelayDays = 3;
  static const maxRefundDelayDays = 30;

  /// One payout of at most 1,000,000 USDC.
  static const maxAmountPerPayoutAtoms = 1000000000000;
  static const minRewardLifetime = Duration(hours: 1);
  static const maxRewardLifetime = Duration(days: 365);
  static const defaultMinConfidence = 0.85;

  /// The confidence range the editor offers. The server accepts 0 to 1, but
  /// below one half a check accepts proof it doubts, and certainty never
  /// comes, so the ends are kept out of reach.
  static const minConfidenceChoice = 0.5;
  static const maxConfidenceChoice = 0.99;
}

/// The proof kind a saved requirement draft represents.
ProofKind proofKindOf(
  ActionRequirementKind kind, {
  required bool hasMovement,
}) => switch (kind) {
  ActionRequirementKind.video =>
    hasMovement ? ProofKind.movementReps : ProofKind.video,
  ActionRequirementKind.photo => ProofKind.photo,
  ActionRequirementKind.audio => ProofKind.audio,
  ActionRequirementKind.location => ProofKind.location,
  ActionRequirementKind.qrCode => ProofKind.venueCode,
  ActionRequirementKind.motion => ProofKind.motion,
  ActionRequirementKind.externalApp => ProofKind.appConfirmation,
};

ActionRequirementKind requirementKindOf(ProofKind kind) => switch (kind) {
  ProofKind.location => ActionRequirementKind.location,
  ProofKind.venueCode => ActionRequirementKind.qrCode,
  ProofKind.motion => ActionRequirementKind.motion,
  ProofKind.movementReps || ProofKind.video => ActionRequirementKind.video,
  ProofKind.photo => ActionRequirementKind.photo,
  ProofKind.audio => ActionRequirementKind.audio,
  ProofKind.appConfirmation => ActionRequirementKind.externalApp,
};

/// The secret a venue-code requirement is seeded with.
///
/// The creator never types or sees it: participants scan short-lived codes
/// the server issues from it, shown on the creator's phone at the venue.
String freshVenueSecret([math.Random? random]) {
  final source = random ?? math.Random.secure();
  final bytes = List<int>.generate(24, (_) => source.nextInt(256));
  return 'verily-venue:${base64Url.encode(bytes)}';
}

/// A stable action key from [title]: a slug plus a short random suffix, so
/// two of the creator's actions with the same title never collide.
String actionKeyFor(String title, [math.Random? random]) {
  final source = random ?? math.Random.secure();
  final slug = title
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final base = slug.length < 3
      ? 'action'
      : slug
            .substring(0, math.min(slug.length, 50))
            .replaceAll(
              RegExp(r'-+$'),
              '',
            );
  const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final suffix = List.generate(
    5,
    (_) => alphabet[source.nextInt(alphabet.length)],
  ).join();
  return '$base-$suffix';
}

/// One proof being edited.
///
/// Holds the text controllers for the fields the creator types and the plain
/// values for the ones they pick. Everything a kind does not use is dropped
/// when the draft is built, so switching kinds never leaks a stale rule.
class RequirementForm {
  RequirementForm({
    required this.requirementKey,
    required this.kind,
    required String title,
    required String instructions,
    this.isRequired = true,
    double? latitude,
    double? longitude,
    this.radiusMeters = 100,
    this.maxAccuracyMeters = 50,
    String prompt = '',
    this.promptNeedsRewrite = false,
    int? minSeconds,
    int? maxSeconds,
    bool? spokenChallenge,
    this.policy = ActionVerificationPolicy.singleModel,
    this.minConfidence = EditorLimits.defaultMinConfidence,
    this.movementKind = ActionMovementKind.squats,
    int? targetRepetitions,
    this.motionType = ActionMotionType.rotation,
    this.motionAxis = ActionMotionAxis.yaw,
    this.minAngularSpeed = 1,
    this.maxAngularSpeed = 25,
    this.minAxisDominance = 0.6,
    this.minFreeFallMilliseconds = 180,
    this.maxFreeFallMilliseconds = 700,
    this.minPeakAcceleration = 12,
    this.maxPeakAcceleration = 60,
    String? venueSecret,
    this.appId,
    this.appName,
    this.localCheck,
  }) : title = TextEditingController(text: title),
       instructions = TextEditingController(text: instructions),
       latitude = TextEditingController(text: _coordinate(latitude)),
       longitude = TextEditingController(text: _coordinate(longitude)),
       prompt = TextEditingController(text: prompt),
       minSeconds = TextEditingController(
         text: '${minSeconds ?? _defaultMinSeconds(kind)}',
       ),
       maxSeconds = TextEditingController(
         text: '${maxSeconds ?? _defaultMaxSeconds(kind)}',
       ),
       spokenChallenge = spokenChallenge ?? kind.isRecording,
       targetRepetitions = TextEditingController(
         text: '${targetRepetitions ?? _defaultTarget(kind)}',
       ),
       venueSecret = venueSecret ?? freshVenueSecret();

  /// A new proof of [kind] with [title] and [instructions] as starting copy.
  factory RequirementForm.blank(
    ProofKind kind, {
    required String requirementKey,
    required String title,
    required String instructions,
  }) => RequirementForm(
    requirementKey: requirementKey,
    kind: kind,
    title: title,
    instructions: instructions,
  );

  /// A proof from a template or an AI draft.
  ///
  /// A draft never decides who confirms the proof or what the venue secret
  /// is: the creator picks one of their own Apps, and every venue gets a
  /// fresh secret, so a template's (or a model's) value can never be reused.
  factory RequirementForm.fromDraft(ActionRequirementDraft draft) {
    final kind = proofKindOf(
      draft.kind,
      hasMovement: draft.movementKind != null,
    );
    return RequirementForm(
      requirementKey: draft.requirementKey,
      kind: kind,
      title: draft.title,
      instructions: draft.instructions,
      isRequired: draft.isRequired,
      latitude: draft.latitude,
      longitude: draft.longitude,
      radiusMeters: draft.radiusMeters ?? 100,
      maxAccuracyMeters: draft.maxAccuracyMeters ?? 50,
      prompt: draft.verificationPrompt ?? '',
      minSeconds: draft.minDurationSeconds,
      maxSeconds: draft.maxDurationSeconds,
      spokenChallenge: draft.spokenChallengeRequired,
      policy: draft.verificationPolicy ?? ActionVerificationPolicy.singleModel,
      minConfidence: draft.minConfidence ?? EditorLimits.defaultMinConfidence,
      movementKind: draft.movementKind ?? ActionMovementKind.squats,
      targetRepetitions: draft.targetRepetitions,
      motionType: draft.motionType ?? ActionMotionType.rotation,
      motionAxis: draft.motionAxis ?? ActionMotionAxis.yaw,
      minAngularSpeed: draft.minAngularSpeedRadiansPerSecond ?? 1,
      maxAngularSpeed: draft.maxAngularSpeedRadiansPerSecond ?? 25,
      minAxisDominance: draft.minAxisDominance ?? 0.6,
      minFreeFallMilliseconds: draft.minFreeFallMilliseconds ?? 180,
      maxFreeFallMilliseconds: draft.maxFreeFallMilliseconds ?? 700,
      minPeakAcceleration:
          draft.minPeakAccelerationMetersPerSecondSquared ?? 12,
      maxPeakAcceleration:
          draft.maxPeakAccelerationMetersPerSecondSquared ?? 60,
      localCheck: draft.localCheck,
    );
  }

  /// A saved proof, for editing.
  ///
  /// The server does not return a media proof's verification prompt, its
  /// confidence threshold, or a venue code's secret. The prompt is marked for
  /// rewriting, the threshold falls back to the default, and the venue gets a
  /// fresh secret (participants only ever scan server-issued codes).
  factory RequirementForm.fromView(ActionRequirementView view) {
    final kind = proofKindOf(view.kind, hasMovement: view.movementKind != null);
    return RequirementForm(
      requirementKey: view.requirementKey,
      kind: kind,
      title: view.title,
      instructions: view.instructions,
      isRequired: view.isRequired,
      latitude: view.latitude,
      longitude: view.longitude,
      radiusMeters: view.radiusMeters ?? 100,
      maxAccuracyMeters: view.maxAccuracyMeters ?? 50,
      promptNeedsRewrite: kind.hasVerificationPrompt,
      minSeconds: view.minDurationSeconds,
      maxSeconds: view.maxDurationSeconds,
      spokenChallenge: view.spokenChallengeRequired,
      policy: view.verificationPolicy ?? ActionVerificationPolicy.singleModel,
      movementKind: view.movementKind ?? ActionMovementKind.squats,
      targetRepetitions: view.targetRepetitions,
      motionType: view.motionType ?? ActionMotionType.rotation,
      motionAxis: view.motionAxis ?? ActionMotionAxis.yaw,
      minAngularSpeed: view.minAngularSpeedRadiansPerSecond ?? 1,
      maxAngularSpeed: view.maxAngularSpeedRadiansPerSecond ?? 25,
      minAxisDominance: view.minAxisDominance ?? 0.6,
      minFreeFallMilliseconds: view.minFreeFallMilliseconds ?? 180,
      maxFreeFallMilliseconds: view.maxFreeFallMilliseconds ?? 700,
      minPeakAcceleration: view.minPeakAccelerationMetersPerSecondSquared ?? 12,
      maxPeakAcceleration: view.maxPeakAccelerationMetersPerSecondSquared ?? 60,
      appId: view.appId,
      appName: view.appName,
      localCheck: view.localCheck,
    );
  }

  final String requirementKey;
  final ProofKind kind;
  bool isRequired;
  final TextEditingController title;
  final TextEditingController instructions;

  // Location.
  final TextEditingController latitude;
  final TextEditingController longitude;
  double radiusMeters;
  double maxAccuracyMeters;

  // Media.
  final TextEditingController prompt;

  /// True when editing a saved media proof: the server does not hand its
  /// prompt back, so the creator writes it again before saving.
  bool promptNeedsRewrite;
  final TextEditingController minSeconds;
  final TextEditingController maxSeconds;
  bool spokenChallenge;
  ActionVerificationPolicy policy;
  double minConfidence;

  // Movement reps and motion.
  ActionMovementKind movementKind;
  final TextEditingController targetRepetitions;
  ActionMotionType motionType;
  ActionMotionAxis motionAxis;
  double minAngularSpeed;
  double maxAngularSpeed;
  double minAxisDominance;
  int minFreeFallMilliseconds;
  int maxFreeFallMilliseconds;
  double minPeakAcceleration;
  double maxPeakAcceleration;

  // Venue code.
  final String venueSecret;

  // App confirmation.
  UuidValue? appId;
  String? appName;

  /// An on-device check a template carries for a photo, video, or audio
  /// proof. The editor keeps it as it is; the server bounds it.
  final ActionLocalCheck? localCheck;

  double? get latitudeValue => double.tryParse(latitude.text.trim());
  double? get longitudeValue => double.tryParse(longitude.text.trim());

  /// Whether a location proof has a usable place.
  bool get hasPlace {
    final lat = latitudeValue;
    final lng = longitudeValue;
    return lat != null &&
        lng != null &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;
  }

  void setPlace(double lat, double lng) {
    latitude.text = _coordinate(lat);
    longitude.text = _coordinate(lng);
  }

  /// Switches a motion proof's type, keeping its axis and target valid for
  /// the new type the way the server's analyzer expects.
  void setMotionType(ActionMotionType type) {
    motionType = type;
    switch (type) {
      case ActionMotionType.rotation:
        if (motionAxis == ActionMotionAxis.any) {
          motionAxis = ActionMotionAxis.yaw;
        }
        minAngularSpeed = 1;
        maxAngularSpeed = 25;
      case ActionMotionType.shake:
        if (motionAxis == ActionMotionAxis.any) {
          motionAxis = ActionMotionAxis.pitch;
        }
        minAngularSpeed = 1;
        maxAngularSpeed = 25;
      case ActionMotionType.phoneToss:
        motionAxis = ActionMotionAxis.any;
        targetRepetitions.text = '1';
      case ActionMotionType.stillness:
        motionAxis = ActionMotionAxis.any;
        targetRepetitions.text = '1';
        minAngularSpeed = 0.1;
        maxAngularSpeed = 0.5;
    }
  }

  /// The draft the server validates. Fields the kind does not use are left
  /// out, because the server refuses media settings on non-media proof.
  ActionRequirementDraft toDraft() {
    final requirementKind = requirementKindOf(kind);
    // Recordings and motion traces have a duration window; photos do not.
    final timed = kind.isRecording || kind == ProofKind.motion;
    return ActionRequirementDraft(
      requirementKey: requirementKey,
      kind: requirementKind,
      title: title.text.trim(),
      instructions: instructions.text.trim(),
      isRequired: isRequired,
      latitude: kind == ProofKind.location ? latitudeValue : null,
      longitude: kind == ProofKind.location ? longitudeValue : null,
      radiusMeters: kind == ProofKind.location ? radiusMeters : null,
      maxAccuracyMeters: kind == ProofKind.location ? maxAccuracyMeters : null,
      verificationPrompt: kind.hasVerificationPrompt
          ? prompt.text.trim()
          : null,
      minDurationSeconds: timed ? int.tryParse(minSeconds.text) : null,
      maxDurationSeconds: timed ? int.tryParse(maxSeconds.text) : null,
      minConfidence: kind.isMedia ? minConfidence : null,
      verificationPolicy: kind.isMedia ? policy : null,
      spokenChallengeRequired: switch (kind) {
        ProofKind.video ||
        ProofKind.audio ||
        ProofKind.movementReps => spokenChallenge,
        ProofKind.photo => false,
        _ => null,
      },
      movementKind: kind == ProofKind.movementReps ? movementKind : null,
      motionType: kind == ProofKind.motion ? motionType : null,
      motionAxis: kind == ProofKind.motion ? motionAxis : null,
      targetRepetitions:
          kind == ProofKind.movementReps || kind == ProofKind.motion
          ? int.tryParse(targetRepetitions.text)
          : null,
      minAngularSpeedRadiansPerSecond: kind == ProofKind.motion
          ? minAngularSpeed
          : null,
      maxAngularSpeedRadiansPerSecond: kind == ProofKind.motion
          ? maxAngularSpeed
          : null,
      minAxisDominance: kind == ProofKind.motion ? minAxisDominance : null,
      minFreeFallMilliseconds: kind == ProofKind.motion
          ? minFreeFallMilliseconds
          : null,
      maxFreeFallMilliseconds: kind == ProofKind.motion
          ? maxFreeFallMilliseconds
          : null,
      minPeakAccelerationMetersPerSecondSquared: kind == ProofKind.motion
          ? minPeakAcceleration
          : null,
      maxPeakAccelerationMetersPerSecondSquared: kind == ProofKind.motion
          ? maxPeakAcceleration
          : null,
      qrCode: kind == ProofKind.venueCode ? venueSecret : null,
      appId: kind == ProofKind.appConfirmation ? appId : null,
      localCheck: kind.hasVerificationPrompt ? localCheck : null,
    );
  }

  void dispose() {
    title.dispose();
    instructions.dispose();
    latitude.dispose();
    longitude.dispose();
    prompt.dispose();
    minSeconds.dispose();
    maxSeconds.dispose();
    targetRepetitions.dispose();
  }

  static String _coordinate(double? value) =>
      value == null ? '' : value.toStringAsFixed(6);

  static int _defaultMinSeconds(ProofKind kind) => switch (kind) {
    ProofKind.motion => 1,
    _ => 5,
  };

  static int _defaultMaxSeconds(ProofKind kind) => switch (kind) {
    ProofKind.motion => 10,
    ProofKind.movementReps => 120,
    _ => 60,
  };

  static int _defaultTarget(ProofKind kind) => switch (kind) {
    ProofKind.movementReps => 10,
    ProofKind.motion => 3,
    _ => 1,
  };
}

/// Why reward terms cannot be saved yet.
enum RewardInputProblem {
  amountInvalid,
  amountTooLarge,
  maxPayoutsInvalid,
  maxWinsInvalid,
  endTooSoon,
  endTooLate,
}

/// The escrowed reward being edited.
class RewardForm {
  RewardForm({
    this.enabled = false,
    String amount = '',
    int maxPayouts = 10,
    int maxWinsPerAccount = 1,
    DateTime? expiresAt,
    this.refundDelayDays = 7,
    this.lockedStatus,
  }) : amount = TextEditingController(text: amount),
       maxPayouts = TextEditingController(text: '$maxPayouts'),
       maxWinsPerAccount = TextEditingController(text: '$maxWinsPerAccount'),
       expiresAt =
           expiresAt ??
           DateTime.now()
               .add(const Duration(days: 30))
               .copyWith(
                 hour: 23,
                 minute: 59,
                 second: 0,
                 millisecond: 0,
                 microsecond: 0,
               );

  /// The reward of a saved action. Terms freeze once funding starts, so a
  /// pool past `draft` is shown read-only and left untouched on save.
  factory RewardForm.fromSummary(RewardSummary? summary) {
    if (summary == null) return RewardForm();
    final amount = TokenAmount(
      atoms: summary.amountPerPayout,
      decimals: summary.decimals,
      symbol: summary.tokenSymbol,
    );
    return RewardForm(
      enabled: true,
      amount: amount.formatValue('en').replaceAll(',', ''),
      maxPayouts: summary.maxPayouts,
      maxWinsPerAccount: summary.maxWinsPerAccount,
      expiresAt: summary.expiresAt.toLocal(),
      lockedStatus: summary.status == RewardPoolStatus.draft
          ? null
          : summary.status,
    );
  }

  bool enabled;
  final TextEditingController amount;
  final TextEditingController maxPayouts;
  final TextEditingController maxWinsPerAccount;
  DateTime expiresAt;
  int refundDelayDays;

  /// Set when funding has started: the terms can no longer change.
  RewardPoolStatus? lockedStatus;

  bool get isLocked => lockedStatus != null;

  /// One payout, or null when [amount] is not a valid USDC amount.
  TokenAmount? get amountPerPayout => TokenAmount.tryParse(
    amount.text,
    decimals: DefaultRewardToken.decimals,
    symbol: DefaultRewardToken.symbol,
  );

  int? get maxPayoutsValue => int.tryParse(maxPayouts.text.trim());
  int? get maxWinsValue => int.tryParse(maxWinsPerAccount.text.trim());

  /// The whole budget the creator locks in escrow, or null while the inputs
  /// are incomplete.
  TokenAmount? get budget {
    final perPayout = amountPerPayout;
    final payouts = maxPayoutsValue;
    if (perPayout == null || payouts == null || payouts < 1) return null;
    return perPayout * payouts;
  }

  /// What is wrong with the terms as typed, relative to [now].
  Set<RewardInputProblem> problems(DateTime now) {
    final found = <RewardInputProblem>{};
    final perPayout = amountPerPayout;
    if (perPayout == null) {
      found.add(RewardInputProblem.amountInvalid);
    } else if (perPayout.atoms > EditorLimits.maxAmountPerPayoutAtoms) {
      found.add(RewardInputProblem.amountTooLarge);
    }
    final payouts = maxPayoutsValue;
    if (payouts == null || payouts < 1 || payouts > EditorLimits.maxPayouts) {
      found.add(RewardInputProblem.maxPayoutsInvalid);
    }
    final wins = maxWinsValue;
    final winCap = math.min(
      EditorLimits.maxWinsPerAccount,
      payouts ?? EditorLimits.maxWinsPerAccount,
    );
    if (wins == null || wins < 1 || wins > winCap) {
      found.add(RewardInputProblem.maxWinsInvalid);
    }
    if (expiresAt.isBefore(now.add(EditorLimits.minRewardLifetime))) {
      found.add(RewardInputProblem.endTooSoon);
    } else if (expiresAt.isAfter(now.add(EditorLimits.maxRewardLifetime))) {
      found.add(RewardInputProblem.endTooLate);
    }
    return found;
  }

  /// The terms to save, or null when there is no reward to change (off, or
  /// locked by funding, which the server keeps as it is).
  RewardTermsDraft? toDraft() {
    if (!enabled || isLocked) return null;
    return RewardTermsDraft(
      amountPerPayout: amountPerPayout!.atoms,
      maxPayouts: maxPayoutsValue!,
      maxWinsPerAccount: maxWinsValue,
      expiresAt: expiresAt.toUtc(),
      refundDelayDays: refundDelayDays,
    );
  }

  void dispose() {
    amount.dispose();
    maxPayouts.dispose();
    maxWinsPerAccount.dispose();
  }
}

/// The whole action being edited.
class EditorForm extends ChangeNotifier {
  EditorForm({
    required String title,
    required String description,
    this.recurrence = ActionRecurrence.once,
    String timeZone = 'UTC',
    int? maxVerifiedCompletions,
    this.opensAt,
    this.closesAt,
    List<RequirementForm>? requirements,
    RewardForm? reward,
    this.actionKey,
    this.savedAction,
    this.safetyNotes = const [],
  }) : title = TextEditingController(text: title),
       description = TextEditingController(text: description),
       timeZone = TextEditingController(text: timeZone),
       maxVerifiedCompletions = TextEditingController(
         text: maxVerifiedCompletions?.toString() ?? '',
       ),
       requirements = requirements ?? [],
       reward = reward ?? RewardForm();

  /// A template or AI proposal, ready to edit. The key comes from the title
  /// at the first save, so a template's own key is never reused.
  factory EditorForm.fromRequest(
    CreateActionDefinitionRequest request, {
    List<String> safetyNotes = const [],
  }) => EditorForm(
    title: request.title,
    description: request.description,
    recurrence: request.recurrence,
    timeZone: request.timeZone,
    maxVerifiedCompletions: request.maxVerifiedCompletions,
    opensAt: request.opensAt?.toLocal(),
    closesAt: request.closesAt?.toLocal(),
    requirements: [
      for (final draft in request.requirements)
        RequirementForm.fromDraft(draft),
    ],
    safetyNotes: safetyNotes,
  );

  /// One of the creator's saved actions.
  factory EditorForm.fromAction(ActionOpportunity action) => EditorForm(
    title: action.title,
    description: action.description,
    recurrence: action.recurrence,
    timeZone: action.timeZone,
    maxVerifiedCompletions: action.maxVerifiedCompletions,
    opensAt: action.opensAt?.toLocal(),
    closesAt: action.closesAt?.toLocal(),
    requirements: [
      for (final view in action.requirements) RequirementForm.fromView(view),
    ],
    reward: RewardForm.fromSummary(action.reward),
    actionKey: action.actionKey,
    savedAction: action,
  );

  final TextEditingController title;
  final TextEditingController description;
  final TextEditingController timeZone;
  final TextEditingController maxVerifiedCompletions;
  ActionRecurrence recurrence;
  DateTime? opensAt;
  DateTime? closesAt;
  final List<RequirementForm> requirements;
  final RewardForm reward;
  final List<String> safetyNotes;

  /// Fixed after the first save; the server identifies the action by it.
  String? actionKey;

  /// The latest version the server returned.
  ActionOpportunity? savedAction;

  bool get hasAppConfirmation =>
      requirements.any((r) => r.kind == ProofKind.appConfirmation);

  bool get hasPhoneProof => requirements.any((r) => r.kind.isPhoneProof);

  /// Whether [kind] can be added now: at most five proofs, and phone proof
  /// never mixes with an App's confirmation (the server enforces both).
  bool canAdd(ProofKind kind) {
    if (requirements.length >= EditorLimits.maxRequirements) return false;
    if (kind == ProofKind.appConfirmation) return requirements.isEmpty;
    return !hasAppConfirmation;
  }

  void add(RequirementForm requirement) {
    requirements.add(requirement);
    notifyListeners();
  }

  /// Removes [requirement]; its controllers are disposed after the frame
  /// that stops showing them.
  void remove(RequirementForm requirement) {
    requirements.remove(requirement);
    notifyListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) => requirement.dispose());
  }

  /// A requirement key for [kind] not yet used on this action.
  String keyFor(ProofKind kind) {
    final base = switch (kind) {
      ProofKind.location => 'location',
      ProofKind.venueCode => 'venue-code',
      ProofKind.motion => 'motion',
      ProofKind.movementReps => 'movement-reps',
      ProofKind.video => 'video',
      ProofKind.photo => 'photo',
      ProofKind.audio => 'audio',
      ProofKind.appConfirmation => 'app-confirmation',
    };
    final used = {for (final r in requirements) r.requirementKey};
    var key = base;
    for (var suffix = 2; used.contains(key); suffix++) {
      key = '$base-$suffix';
    }
    return key;
  }

  /// Tells listeners that a picked value (not a text field) changed.
  void touch() => notifyListeners();

  /// Records the version the server returned after a save or publish. Its
  /// reward status decides whether the terms are still editable.
  void acceptSaved(ActionOpportunity action) {
    savedAction = action;
    actionKey = action.actionKey;
    lockReward(action.reward?.status);
  }

  /// Freezes the reward terms once the pool has left `draft`.
  void lockReward(RewardPoolStatus? status) {
    reward.lockedStatus = status == null || status == RewardPoolStatus.draft
        ? null
        : status;
    notifyListeners();
  }

  /// Whether this action has been saved at least once.
  bool get isSaved => savedAction != null;

  /// The request to save. Fixes the action key on first use.
  CreateActionDefinitionRequest toRequest([math.Random? random]) {
    final key = actionKey ??= actionKeyFor(title.text, random);
    final completions = int.tryParse(maxVerifiedCompletions.text.trim());
    return CreateActionDefinitionRequest(
      actionKey: key,
      title: title.text.trim(),
      description: description.text.trim(),
      recurrence: recurrence,
      timeZone: timeZone.text.trim().isEmpty ? 'UTC' : timeZone.text.trim(),
      maxVerifiedCompletions: completions,
      opensAt: opensAt?.toUtc(),
      closesAt: closesAt?.toUtc(),
      requirements: [for (final r in requirements) r.toDraft()],
      reward: reward.toDraft(),
    );
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    timeZone.dispose();
    maxVerifiedCompletions.dispose();
    for (final requirement in requirements) {
      requirement.dispose();
    }
    reward.dispose();
    super.dispose();
  }
}
