import 'package:skribble/skribble.dart' show WiredSvgIconData;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/features/do/proof_kind.dart';
import 'package:verily_flutter/l10n/l10n.dart';

/// What the Do feed shows.
enum DoFilter {
  all,

  /// Actions with a place near the device, from the server's nearby search.
  nearby,

  /// Actions you prove by being somewhere.
  place,

  /// Phone motion, or reps counted on camera.
  movement,

  /// Actions you prove with a code at the venue.
  venueCode,

  /// Actions a Verily App confirms.
  apps;

  /// Whether [action] belongs under this filter. Nearby is decided by the
  /// server's search, so every nearby result matches.
  bool matches(ActionOpportunity action) {
    final kinds = proofKindsOf(action);
    return switch (this) {
      DoFilter.all || DoFilter.nearby => true,
      DoFilter.place => kinds.contains(ProofKind.place),
      DoFilter.movement =>
        kinds.contains(ProofKind.motion) || kinds.contains(ProofKind.movement),
      DoFilter.venueCode => kinds.contains(ProofKind.venueCode),
      DoFilter.apps => kinds.contains(ProofKind.app),
    };
  }

  String label(AppLocalizations l10n) => switch (this) {
    DoFilter.all => l10n.doFilterAll,
    DoFilter.nearby => l10n.doFilterNearby,
    DoFilter.place => l10n.doFilterPlace,
    DoFilter.movement => l10n.doFilterMovement,
    DoFilter.venueCode => l10n.doFilterVenueCode,
    DoFilter.apps => l10n.doFilterApps,
  };

  WiredSvgIconData get icon => switch (this) {
    DoFilter.all => VerilyIcons.bolt,
    DoFilter.nearby => VerilyIcons.nearby,
    DoFilter.place => VerilyIcons.mapPin,
    DoFilter.movement => VerilyIcons.run,
    DoFilter.venueCode => VerilyIcons.qrCode,
    DoFilter.apps => VerilyIcons.link,
  };
}
