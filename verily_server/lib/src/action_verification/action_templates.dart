import 'package:verily_server/src/generated/protocol.dart';

/// The twelve value-free starting points creators can configure.
///
/// Templates are an allow-listed starting point, not a promise that every
/// action is safe or objectively verifiable. They never carry a venue code or
/// a reward.
List<ActionTemplate> actionTemplates() => [
  ActionTemplate(
    templateKey: 'daily-movement-proof',
    title: 'Daily movement proof',
    description:
        'Record a short workout or movement, saying the challenge word '
        'Verily gives you.',
    suggestedRecurrence: ActionRecurrence.daily,
    requirements: [
      ActionRequirementDraft(
        requirementKey: 'movement-video',
        kind: ActionRequirementKind.video,
        title: 'Record the movement',
        instructions:
            'Keep your whole body in frame, say the challenge word, and '
            'record one continuous attempt.',
        isRequired: true,
        verificationPrompt:
            'Verify that the person completes the described movement safely '
            'and continuously in one recording.',
        minDurationSeconds: 5,
        maxDurationSeconds: 120,
        minConfidence: 0.85,
        verificationPolicy: ActionVerificationPolicy.singleModel,
        spokenChallengeRequired: true,
      ),
    ],
  ),
  ActionTemplate(
    templateKey: 'exercise-reps',
    title: 'Exercise reps',
    description:
        'Squats, press-ups, sit-ups, and more, counted live on your phone and '
        'checked from the recording.',
    suggestedRecurrence: ActionRecurrence.daily,
    requirements: [
      ActionRequirementDraft(
        requirementKey: 'exercise-reps',
        kind: ActionRequirementKind.video,
        title: 'Do the reps',
        instructions:
            'Prop your phone up, step back until your whole body is in frame, '
            'and keep going until the counter reaches the target.',
        isRequired: true,
        minDurationSeconds: 5,
        maxDurationSeconds: 120,
        minConfidence: 0.85,
        verificationPolicy: ActionVerificationPolicy.singleModel,
        spokenChallengeRequired: true,
        movementKind: ActionMovementKind.squats,
        targetRepetitions: 10,
      ),
    ],
  ),
  ActionTemplate(
    templateKey: 'ball-skills',
    title: 'Ball skills',
    description:
        'Keep a football or table tennis ball up with consecutive touches, '
        'counted live and checked from the recording.',
    suggestedRecurrence: ActionRecurrence.daily,
    requirements: [
      ActionRequirementDraft(
        requirementKey: 'ball-skills',
        kind: ActionRequirementKind.video,
        title: 'Keep the ball up',
        instructions:
            'Find open space, keep the ball and your whole body in frame, and '
            'keep it up without letting it drop.',
        isRequired: true,
        minDurationSeconds: 5,
        maxDurationSeconds: 180,
        minConfidence: 0.85,
        verificationPolicy: ActionVerificationPolicy.singleModel,
        spokenChallengeRequired: true,
        movementKind: ActionMovementKind.footballKickUps,
        targetRepetitions: 20,
      ),
    ],
  ),
  ActionTemplate(
    templateKey: 'place-check-in',
    title: 'Place check-in',
    description: 'Show up at a place on the map.',
    suggestedRecurrence: ActionRecurrence.daily,
    requirements: [
      ActionRequirementDraft(
        requirementKey: 'location',
        kind: ActionRequirementKind.location,
        title: 'Check in at the place',
        instructions: 'Share a fresh location while you are there.',
        isRequired: true,
        radiusMeters: 100,
        maxAccuracyMeters: 50,
      ),
    ],
  ),
  ActionTemplate(
    templateKey: 'venue-visit',
    title: 'Venue visit',
    description:
        'Check in at a venue and scan a code that only exists inside it.',
    suggestedRecurrence: ActionRecurrence.once,
    requirements: [
      ActionRequirementDraft(
        requirementKey: 'location',
        kind: ActionRequirementKind.location,
        title: 'Check in at the venue',
        instructions: 'Share a fresh location from inside the venue.',
        isRequired: true,
        radiusMeters: 75,
        maxAccuracyMeters: 40,
      ),
      ActionRequirementDraft(
        requirementKey: 'venue-code',
        kind: ActionRequirementKind.qrCode,
        title: 'Scan the venue code',
        instructions: 'Scan the code on display at the venue right now.',
        isRequired: true,
      ),
    ],
  ),
  ActionTemplate(
    templateKey: 'event-code',
    title: 'Event code check-in',
    description: 'Scan a short-lived code the organizer shows at the event.',
    suggestedRecurrence: ActionRecurrence.once,
    requirements: [
      ActionRequirementDraft(
        requirementKey: 'event-code',
        kind: ActionRequirementKind.qrCode,
        title: 'Scan the event code',
        instructions: 'Scan the code the organizer is showing now.',
        isRequired: true,
      ),
    ],
  ),
  ActionTemplate(
    templateKey: 'gentle-phone-toss',
    title: 'Gentle phone toss',
    description: 'One low, controlled toss and catch, felt by your phone.',
    suggestedRecurrence: ActionRecurrence.once,
    requirements: [
      _motionTemplate(
        key: 'gentle-toss',
        type: ActionMotionType.phoneToss,
        title: 'Toss and catch gently',
        instructions:
            'Stand still over a soft, clear surface. Toss below eye level and '
            'catch with both hands.',
        maxDurationSeconds: 8,
      ),
    ],
  ),
  ActionTemplate(
    templateKey: 'yaw-five',
    title: 'Five spins',
    description: 'Turn the phone five full times with the screen facing you.',
    suggestedRecurrence: ActionRecurrence.once,
    requirements: [
      _motionTemplate(
        key: 'yaw-five',
        type: ActionMotionType.rotation,
        axis: ActionMotionAxis.yaw,
        repetitions: 5,
        title: 'Spin five times',
        instructions:
            'Keep the screen facing you and make five deliberate full turns.',
        maxDurationSeconds: 15,
      ),
    ],
  ),
  ActionTemplate(
    templateKey: 'pitch-three',
    title: 'Three forward flips',
    description: 'Three controlled forward rotations of the phone.',
    suggestedRecurrence: ActionRecurrence.once,
    requirements: [
      _motionTemplate(
        key: 'pitch-three',
        type: ActionMotionType.rotation,
        axis: ActionMotionAxis.pitch,
        repetitions: 3,
        title: 'Flip the phone forward three times',
        instructions:
            'Hold the phone securely and rotate it forward three full times.',
        maxDurationSeconds: 12,
      ),
    ],
  ),
  ActionTemplate(
    templateKey: 'roll-three',
    title: 'Three barrel rolls',
    description: 'Three controlled side-over-side rotations of the phone.',
    suggestedRecurrence: ActionRecurrence.once,
    requirements: [
      _motionTemplate(
        key: 'roll-three',
        type: ActionMotionType.rotation,
        axis: ActionMotionAxis.roll,
        repetitions: 3,
        title: 'Roll the phone three times',
        instructions:
            'Hold the phone securely and roll it side over side three full '
            'times.',
        maxDurationSeconds: 12,
      ),
    ],
  ),
  ActionTemplate(
    templateKey: 'shake-five',
    title: 'Five-count shake',
    description: 'Five deliberate back-and-forth shakes.',
    suggestedRecurrence: ActionRecurrence.once,
    requirements: [
      _motionTemplate(
        key: 'shake-five',
        type: ActionMotionType.shake,
        axis: ActionMotionAxis.pitch,
        repetitions: 5,
        title: 'Shake five times',
        instructions:
            'Keep a secure grip and make five clear, controlled shakes.',
      ),
    ],
  ),
  ActionTemplate(
    templateKey: 'steady-hand',
    title: 'Steady hand',
    description: 'Hold the phone almost perfectly still for five seconds.',
    suggestedRecurrence: ActionRecurrence.daily,
    requirements: [
      _motionTemplate(
        key: 'steady-five',
        type: ActionMotionType.stillness,
        title: 'Hold steady',
        instructions:
            'Hold the phone securely and keep it as still as you can for five '
            'seconds.',
        minDurationSeconds: 5,
        maxDurationSeconds: 6,
        minAngularSpeed: 0.1,
        maxAngularSpeed: 0.5,
      ),
    ],
  ),
];

ActionRequirementDraft _motionTemplate({
  required String key,
  required ActionMotionType type,
  required String title,
  required String instructions,
  ActionMotionAxis axis = ActionMotionAxis.any,
  int repetitions = 1,
  int minDurationSeconds = 1,
  int maxDurationSeconds = 10,
  double minAngularSpeed = 1,
  double maxAngularSpeed = 25,
}) {
  return ActionRequirementDraft(
    requirementKey: key,
    kind: ActionRequirementKind.motion,
    title: title,
    instructions: instructions,
    isRequired: true,
    minDurationSeconds: minDurationSeconds,
    maxDurationSeconds: maxDurationSeconds,
    motionType: type,
    motionAxis: axis,
    targetRepetitions: repetitions,
    minAngularSpeedRadiansPerSecond: minAngularSpeed,
    maxAngularSpeedRadiansPerSecond: maxAngularSpeed,
    minAxisDominance: 0.6,
    minFreeFallMilliseconds: 180,
    maxFreeFallMilliseconds: 700,
    minPeakAccelerationMetersPerSecondSquared: 12,
    maxPeakAccelerationMetersPerSecondSquared: 60,
  );
}
