import 'package:skribble/skribble.dart' show WiredSvgIconData;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/l10n/l10n.dart';

/// How a requirement is proven, as the participant thinks of it.
enum ProofKind {
  place,
  venueCode,
  video,
  movement,
  photo,
  audio,
  motion,
  app;

  /// The proof [requirement] asks for. A video with a movement kind counts
  /// reps, which reads differently from a plain clip.
  static ProofKind of(ActionRequirementView requirement) =>
      switch (requirement.kind) {
        ActionRequirementKind.location => ProofKind.place,
        ActionRequirementKind.qrCode => ProofKind.venueCode,
        ActionRequirementKind.video when requirement.movementKind != null =>
          ProofKind.movement,
        ActionRequirementKind.video => ProofKind.video,
        ActionRequirementKind.photo => ProofKind.photo,
        ActionRequirementKind.audio => ProofKind.audio,
        ActionRequirementKind.motion => ProofKind.motion,
        ActionRequirementKind.externalApp => ProofKind.app,
      };

  WiredSvgIconData get icon => switch (this) {
    ProofKind.place => VerilyIcons.mapPin,
    ProofKind.venueCode => VerilyIcons.qrCode,
    ProofKind.video => VerilyIcons.video,
    ProofKind.movement => VerilyIcons.dumbbell,
    ProofKind.photo => VerilyIcons.photo,
    ProofKind.audio => VerilyIcons.microphone,
    ProofKind.motion => VerilyIcons.rotatePhone,
    ProofKind.app => VerilyIcons.link,
  };

  String label(AppLocalizations l10n) => switch (this) {
    ProofKind.place => l10n.doProofPlace,
    ProofKind.venueCode => l10n.doProofVenueCode,
    ProofKind.video => l10n.doProofVideo,
    ProofKind.movement => l10n.doProofMovement,
    ProofKind.photo => l10n.doProofPhoto,
    ProofKind.audio => l10n.doProofAudio,
    ProofKind.motion => l10n.doProofMotion,
    ProofKind.app => l10n.doProofApp,
  };
}

/// The distinct proof kinds [action] asks for, in requirement order.
List<ProofKind> proofKindsOf(ActionOpportunity action) => [
  ...{for (final requirement in action.requirements) ProofKind.of(requirement)},
];
