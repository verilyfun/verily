import 'package:skribble/skribble.dart' show WiredSvgIconData;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/features/create/editor/editor_form.dart';
import 'package:verily_flutter/l10n/l10n.dart';

/// The plain name of a proof kind, as the add-proof sheet lists it.
String proofKindName(AppLocalizations l10n, ProofKind kind) => switch (kind) {
  ProofKind.location => l10n.editorKindLocation,
  ProofKind.venueCode => l10n.editorKindVenueCode,
  ProofKind.motion => l10n.editorKindMotion,
  ProofKind.movementReps => l10n.editorKindMovementReps,
  ProofKind.video => l10n.editorKindVideo,
  ProofKind.photo => l10n.editorKindPhoto,
  ProofKind.audio => l10n.editorKindAudio,
  ProofKind.appConfirmation => l10n.editorKindApp,
};

/// One line on what a proof kind asks of participants.
String proofKindHelp(AppLocalizations l10n, ProofKind kind) => switch (kind) {
  ProofKind.location => l10n.editorKindLocationHelp,
  ProofKind.venueCode => l10n.editorKindVenueCodeHelp,
  ProofKind.motion => l10n.editorKindMotionHelp,
  ProofKind.movementReps => l10n.editorKindMovementRepsHelp,
  ProofKind.video => l10n.editorKindVideoHelp,
  ProofKind.photo => l10n.editorKindPhotoHelp,
  ProofKind.audio => l10n.editorKindAudioHelp,
  ProofKind.appConfirmation => l10n.editorKindAppHelp,
};

/// The starting title of a new proof of [kind].
String proofKindDefaultTitle(AppLocalizations l10n, ProofKind kind) =>
    switch (kind) {
      ProofKind.location => l10n.editorKindLocationDefaultTitle,
      ProofKind.venueCode => l10n.editorKindVenueCodeDefaultTitle,
      ProofKind.motion => l10n.editorKindMotionDefaultTitle,
      ProofKind.movementReps => l10n.editorKindMovementRepsDefaultTitle,
      ProofKind.video => l10n.editorKindVideoDefaultTitle,
      ProofKind.photo => l10n.editorKindPhotoDefaultTitle,
      ProofKind.audio => l10n.editorKindAudioDefaultTitle,
      ProofKind.appConfirmation => l10n.editorKindAppDefaultTitle,
    };

/// The starting instructions of a new proof of [kind].
String proofKindDefaultInstructions(AppLocalizations l10n, ProofKind kind) =>
    switch (kind) {
      ProofKind.location => l10n.editorKindLocationDefaultInstructions,
      ProofKind.venueCode => l10n.editorKindVenueCodeDefaultInstructions,
      ProofKind.motion => l10n.editorKindMotionDefaultInstructions,
      ProofKind.movementReps => l10n.editorKindMovementRepsDefaultInstructions,
      ProofKind.video => l10n.editorKindVideoDefaultInstructions,
      ProofKind.photo => l10n.editorKindPhotoDefaultInstructions,
      ProofKind.audio => l10n.editorKindAudioDefaultInstructions,
      ProofKind.appConfirmation => l10n.editorKindAppDefaultInstructions,
    };

/// The drawing that stands for a proof kind next to its name.
WiredSvgIconData proofKindIcon(ProofKind kind) => switch (kind) {
  ProofKind.location => VerilyIcons.mapPin,
  ProofKind.venueCode => VerilyIcons.qrCode,
  ProofKind.motion => VerilyIcons.rotatePhone,
  ProofKind.movementReps => VerilyIcons.dumbbell,
  ProofKind.video => VerilyIcons.video,
  ProofKind.photo => VerilyIcons.photo,
  ProofKind.audio => VerilyIcons.microphone,
  ProofKind.appConfirmation => VerilyIcons.network,
};

String movementName(AppLocalizations l10n, ActionMovementKind kind) =>
    switch (kind) {
      ActionMovementKind.squats => l10n.editorMovementSquats,
      ActionMovementKind.pressUps => l10n.editorMovementPressUps,
      ActionMovementKind.sitUps => l10n.editorMovementSitUps,
      ActionMovementKind.lunges => l10n.editorMovementLunges,
      ActionMovementKind.starJumps => l10n.editorMovementStarJumps,
      ActionMovementKind.burpees => l10n.editorMovementBurpees,
      ActionMovementKind.highKnees => l10n.editorMovementHighKnees,
      ActionMovementKind.lateralRaises => l10n.editorMovementLateralRaises,
      ActionMovementKind.bicepsCurls => l10n.editorMovementBicepsCurls,
      ActionMovementKind.sideBends => l10n.editorMovementSideBends,
      ActionMovementKind.footballKickUps => l10n.editorMovementFootballKickUps,
      ActionMovementKind.tableTennisBounces =>
        l10n.editorMovementTableTennisBounces,
    };

String motionTypeName(AppLocalizations l10n, ActionMotionType type) =>
    switch (type) {
      ActionMotionType.phoneToss => l10n.editorMotionToss,
      ActionMotionType.rotation => l10n.editorMotionRotation,
      ActionMotionType.shake => l10n.editorMotionShake,
      ActionMotionType.stillness => l10n.editorMotionStillness,
    };

String motionAxisName(AppLocalizations l10n, ActionMotionAxis axis) =>
    switch (axis) {
      ActionMotionAxis.yaw => l10n.editorMotionAxisYaw,
      ActionMotionAxis.pitch => l10n.editorMotionAxisPitch,
      ActionMotionAxis.roll => l10n.editorMotionAxisRoll,
      ActionMotionAxis.any => l10n.editorMotionAxisAny,
    };

String actionStatusName(AppLocalizations l10n, ActionDefinitionStatus status) =>
    switch (status) {
      ActionDefinitionStatus.draft => l10n.editorStatusDraft,
      ActionDefinitionStatus.active => l10n.editorStatusLive,
      ActionDefinitionStatus.paused => l10n.editorStatusPaused,
      ActionDefinitionStatus.completed => l10n.editorStatusCompleted,
    };

/// What a reward pool past `draft` is doing, or null while its terms can
/// still change.
String? lockedRewardStatusName(
  AppLocalizations l10n,
  RewardPoolStatus status,
) => switch (status) {
  RewardPoolStatus.draft => null,
  RewardPoolStatus.awaitingFunding => l10n.editorRewardStatusAwaiting,
  RewardPoolStatus.funded => l10n.editorRewardStatusFunded,
  RewardPoolStatus.ended => l10n.editorRewardStatusEnded,
  RewardPoolStatus.closed => l10n.editorRewardStatusClosed,
};
