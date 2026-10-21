import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/capture/movement/exercise_tracking.dart';
import 'package:verily_flutter/l10n/l10n.dart';

/// Participant-facing names for each movement.
String movementName(AppLocalizations l10n, ActionMovementKind kind) {
  return switch (kind) {
    ActionMovementKind.squats => l10n.movementNameSquats,
    ActionMovementKind.pressUps => l10n.movementNamePressUps,
    ActionMovementKind.sitUps => l10n.movementNameSitUps,
    ActionMovementKind.lunges => l10n.movementNameLunges,
    ActionMovementKind.starJumps => l10n.movementNameStarJumps,
    ActionMovementKind.burpees => l10n.movementNameBurpees,
    ActionMovementKind.highKnees => l10n.movementNameHighKnees,
    ActionMovementKind.lateralRaises => l10n.movementNameLateralRaises,
    ActionMovementKind.bicepsCurls => l10n.movementNameBicepsCurls,
    ActionMovementKind.sideBends => l10n.movementNameSideBends,
    ActionMovementKind.footballKickUps => l10n.movementNameFootballKickUps,
    ActionMovementKind.tableTennisBounces =>
      l10n.movementNameTableTennisBounces,
  };
}

/// A counted target, for example "10 squats".
String movementTarget(
  AppLocalizations l10n,
  ActionMovementKind kind,
  int count,
) {
  return switch (kind) {
    ActionMovementKind.squats => l10n.movementTargetSquats(count),
    ActionMovementKind.pressUps => l10n.movementTargetPressUps(count),
    ActionMovementKind.sitUps => l10n.movementTargetSitUps(count),
    ActionMovementKind.lunges => l10n.movementTargetLunges(count),
    ActionMovementKind.starJumps => l10n.movementTargetStarJumps(count),
    ActionMovementKind.burpees => l10n.movementTargetBurpees(count),
    ActionMovementKind.highKnees => l10n.movementTargetHighKnees(count),
    ActionMovementKind.lateralRaises => l10n.movementTargetLateralRaises(
      count,
    ),
    ActionMovementKind.bicepsCurls => l10n.movementTargetBicepsCurls(count),
    ActionMovementKind.sideBends => l10n.movementTargetSideBends(count),
    ActionMovementKind.footballKickUps => l10n.movementTargetFootballKickUps(
      count,
    ),
    ActionMovementKind.tableTennisBounces =>
      l10n.movementTargetTableTennisBounces(count),
  };
}

/// Where to put the phone so the counter can see the movement.
String movementGuide(AppLocalizations l10n, ActionMovementKind kind) {
  return switch (kind) {
    ActionMovementKind.squats => l10n.movementGuideSquats,
    ActionMovementKind.pressUps => l10n.movementGuidePressUps,
    ActionMovementKind.sitUps => l10n.movementGuideSitUps,
    ActionMovementKind.lunges => l10n.movementGuideLunges,
    ActionMovementKind.starJumps => l10n.movementGuideStarJumps,
    ActionMovementKind.burpees => l10n.movementGuideBurpees,
    ActionMovementKind.highKnees => l10n.movementGuideHighKnees,
    ActionMovementKind.lateralRaises => l10n.movementGuideLateralRaises,
    ActionMovementKind.bicepsCurls => l10n.movementGuideBicepsCurls,
    ActionMovementKind.sideBends => l10n.movementGuideSideBends,
    ActionMovementKind.footballKickUps => l10n.movementGuideFootballKickUps,
    ActionMovementKind.tableTennisBounces =>
      l10n.movementGuideTableTennisBounces,
  };
}

/// The short instruction shown while the participant moves.
String movementCue(
  AppLocalizations l10n,
  ActionMovementKind kind,
  MovementCue cue,
) {
  return switch (cue) {
    MovementCue.stepIntoFrame => l10n.movementCueStepIntoFrame,
    MovementCue.getIntoPosition => l10n.movementCueGetIntoPosition,
    MovementCue.returnToStart => l10n.movementCueReturnToStart,
    MovementCue.crouch => l10n.movementCueCrouch,
    MovementCue.plank => l10n.movementCuePlank,
    MovementCue.feetForward => l10n.movementCueFeetForward,
    MovementCue.jump => l10n.movementCueJump,
    MovementCue.land => l10n.movementCueLand,
    MovementCue.showBall => l10n.movementCueShowBall,
    MovementCue.dropped => l10n.movementCueDropped,
    MovementCue.perform => switch (kind) {
      ActionMovementKind.squats => l10n.movementCueSquats,
      ActionMovementKind.pressUps => l10n.movementCuePressUps,
      ActionMovementKind.sitUps => l10n.movementCueSitUps,
      ActionMovementKind.lunges => l10n.movementCueLunges,
      ActionMovementKind.starJumps => l10n.movementCueStarJumps,
      ActionMovementKind.burpees => l10n.movementCueBurpees,
      ActionMovementKind.highKnees => l10n.movementCueHighKnees,
      ActionMovementKind.lateralRaises => l10n.movementCueLateralRaises,
      ActionMovementKind.bicepsCurls => l10n.movementCueBicepsCurls,
      ActionMovementKind.sideBends => l10n.movementCueSideBends,
      ActionMovementKind.footballKickUps => l10n.movementCueFootballKickUps,
      ActionMovementKind.tableTennisBounces =>
        l10n.movementCueTableTennisBounces,
    },
  };
}
