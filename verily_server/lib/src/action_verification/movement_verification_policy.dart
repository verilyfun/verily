import 'package:verily_server/src/action_verification/action_draft_refusal.dart';
import 'package:verily_server/src/action_verification/model_input_security.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// The largest repetition or touch target a movement challenge may request.
const maximumMovementRepetitions = 1000;

/// Server-owned verification wording for tracked movement challenges.
///
/// Movement requirements never carry creator-written verifier text. The prompt
/// is derived from the typed [kind] and [targetRepetitions] so creator input
/// cannot steer the model, and every challenge of one kind is judged by the
/// same definition of a complete repetition.
String movementVerificationPrompt(
  ActionMovementKind kind,
  int targetRepetitions,
) {
  final movement = _movement(kind);
  final sequence = movement.consecutive
      ? ' The $targetRepetitions ${movement.plural} must be consecutive, '
            'without the ball being caught or landing in between.'
      : '';
  return ModelInputSecurity.validateVerificationPolicy(
    'Movement challenge: $targetRepetitions complete ${movement.plural}. '
    'One complete ${movement.singular} is ${movement.definition} '
    'The video must show one person performing at least $targetRepetitions '
    'complete ${movement.plural} in a single continuous recording, with the '
    'body parts${movement.consecutive ? ' and the ball' : ''} needed to judge '
    'each one visible.$sequence Count only clearly complete repetitions. '
    'Partial, obstructed, sped-up, edited, or looped footage does not count.',
  );
}

/// Rejects movement targets that are invalid or cannot fit the recording.
///
/// [maxDurationSeconds] is the requirement's recording limit; a target that
/// would need more time than that at a brisk but safe pace can never be
/// completed honestly, so it is refused before publication. Throws
/// [ActionDraftRefusal].
void validateMovementTarget(
  ActionMovementKind kind,
  int? targetRepetitions,
  int maxDurationSeconds,
) {
  if (targetRepetitions == null ||
      targetRepetitions < 1 ||
      targetRepetitions > maximumMovementRepetitions) {
    throw const ActionDraftRefusal(
      'Movement targets must be between 1 and $maximumMovementRepetitions.',
    );
  }
  final minimumSeconds =
      (targetRepetitions * _movement(kind).minimumMillisecondsEach / 1000)
          .ceil();
  if (minimumSeconds > maxDurationSeconds) {
    throw ActionDraftRefusal(
      'The recording limit is too short for $targetRepetitions repetitions.',
    );
  }
}

final class _Movement {
  const _Movement({
    required this.singular,
    required this.plural,
    required this.definition,
    required this.minimumMillisecondsEach,
    this.consecutive = false,
  });

  final String singular;
  final String plural;

  /// One complete repetition, written as a sentence ending in a full stop.
  final String definition;

  /// The fastest believable pace, used to reject impossible targets.
  final int minimumMillisecondsEach;

  /// Ball skills count an unbroken run of touches.
  final bool consecutive;
}

_Movement _movement(ActionMovementKind kind) => switch (kind) {
  ActionMovementKind.squats => const _Movement(
    singular: 'squat',
    plural: 'squats',
    definition:
        'standing tall, bending both knees until the hips lower to about knee '
        'height, then returning to standing with the knees straight.',
    minimumMillisecondsEach: 1000,
  ),
  ActionMovementKind.pressUps => const _Movement(
    singular: 'press-up',
    plural: 'press-ups',
    definition:
        'from a straight-body plank with hands on the floor, bending both '
        'elbows to lower the chest toward the floor, then pressing back up '
        'until the arms are straight.',
    minimumMillisecondsEach: 1000,
  ),
  ActionMovementKind.sitUps => const _Movement(
    singular: 'sit-up',
    plural: 'sit-ups',
    definition:
        'lying on the back with knees bent, lifting the torso from the floor '
        'toward the knees, then lowering the shoulders back to the floor.',
    minimumMillisecondsEach: 1200,
  ),
  ActionMovementKind.lunges => const _Movement(
    singular: 'lunge',
    plural: 'lunges',
    definition:
        'from a split stance, bending both knees until the back knee nears '
        'the floor, then rising until the front knee is straight.',
    minimumMillisecondsEach: 1200,
  ),
  ActionMovementKind.starJumps => const _Movement(
    singular: 'star jump',
    plural: 'star jumps',
    definition:
        'jumping from feet together with arms down to feet wide apart with '
        'both arms raised overhead, then jumping back to the start.',
    minimumMillisecondsEach: 700,
  ),
  ActionMovementKind.burpees => const _Movement(
    singular: 'burpee',
    plural: 'burpees',
    definition:
        'from standing, crouching with hands on the floor, kicking the feet '
        'back into a plank, returning the feet to a crouch, then jumping up '
        'and landing standing.',
    minimumMillisecondsEach: 2500,
  ),
  ActionMovementKind.highKnees => const _Movement(
    singular: 'high knee',
    plural: 'high knees',
    definition:
        'standing upright and lifting one knee to at least hip height, then '
        'lowering it; each knee raise counts once.',
    minimumMillisecondsEach: 400,
  ),
  ActionMovementKind.lateralRaises => const _Movement(
    singular: 'lateral raise',
    plural: 'lateral raises',
    definition:
        'from arms at the sides, raising both straight arms sideways to about '
        'shoulder height, then lowering them back to the sides.',
    minimumMillisecondsEach: 1200,
  ),
  ActionMovementKind.bicepsCurls => const _Movement(
    singular: 'biceps curl',
    plural: 'biceps curls',
    definition:
        'with the upper arms still and close to the body, bending both elbows '
        'to bring the hands toward the shoulders, then lowering them until '
        'the arms are straight.',
    minimumMillisecondsEach: 1200,
  ),
  ActionMovementKind.sideBends => const _Movement(
    singular: 'side bend',
    plural: 'side bends',
    definition:
        'standing with the hips still, leaning the torso clearly to one side, '
        'then returning upright.',
    minimumMillisecondsEach: 1200,
  ),
  ActionMovementKind.footballKickUps => const _Movement(
    singular: 'kick-up',
    plural: 'kick-ups',
    definition:
        'one touch that sends a football back up using a foot, knee, thigh, '
        'chest, or head, never the hands or arms.',
    minimumMillisecondsEach: 350,
    consecutive: true,
  ),
  ActionMovementKind.tableTennisBounces => const _Movement(
    singular: 'bat bounce',
    plural: 'bat bounces',
    definition:
        'one hit that sends a table tennis ball back up off a table tennis bat '
        'held in one hand, without the ball touching anything else.',
    minimumMillisecondsEach: 250,
    consecutive: true,
  ),
};
