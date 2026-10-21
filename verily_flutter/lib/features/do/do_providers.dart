import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:uuid/validation.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/actions/action_repository.dart';
import 'package:verily_flutter/features/capture/capture_flow.dart';
import 'package:verily_flutter/features/do/venue_scanner_screen.dart';
import 'package:verily_flutter/features/evidence/evidence_service.dart';
import 'package:verily_flutter/features/evidence/location_service.dart';

/// Live actions the caller can do, as the server orders them.
final FutureProvider<List<ActionOpportunity>> actionFeedProvider =
    FutureProvider.autoDispose(
      (ref) => ref.watch(actionRepositoryProvider).listAvailable(),
    );

/// Where the Nearby filter stands with the device's approximate location.
///
/// Kept for the whole session: once someone has said yes or not now, the
/// app does not ask again until they ask for nearby actions themselves.
sealed class NearbyLocation {
  const NearbyLocation();
}

/// Nobody has asked yet; the explanation comes first.
final class NearbyLocationUnasked extends NearbyLocation {
  const NearbyLocationUnasked();
}

/// The person chose not now.
final class NearbyLocationDeclined extends NearbyLocation {
  const NearbyLocationDeclined();
}

final class NearbyLocationLocating extends NearbyLocation {
  const NearbyLocationLocating();
}

final class NearbyLocationFound extends NearbyLocation {
  const NearbyLocationFound(this.fix);

  final LocationFix fix;
}

final class NearbyLocationFailed extends NearbyLocation {
  const NearbyLocationFailed(this.failure);

  final LocationFailure failure;
}

/// Reads the approximate location for the Nearby filter, once per ask.
class NearbyLocationController extends Notifier<NearbyLocation> {
  @override
  NearbyLocation build() => const NearbyLocationUnasked();

  /// Reads one approximate position. The server rounds it to about 100 m for
  /// the query and never stores it.
  Future<void> locate() async {
    state = const NearbyLocationLocating();
    try {
      final fix = await ref.read(locationServiceProvider).approximatePosition();
      state = NearbyLocationFound(fix);
    } on LocationException catch (error) {
      state = NearbyLocationFailed(error.failure);
    }
  }

  void decline() => state = const NearbyLocationDeclined();
}

final nearbyLocationProvider =
    NotifierProvider<NearbyLocationController, NearbyLocation>(
      NearbyLocationController.new,
    );

/// Actions with a place near a location fix, nearest first.
final FutureProviderFamily<List<ActionOpportunity>, LocationFix>
nearbyActionsProvider = FutureProvider.autoDispose.family(
  (ref, fix) => ref
      .watch(actionRepositoryProvider)
      .listNearby(latitude: fix.latitude, longitude: fix.longitude),
);

/// One action, resolved for its page.
///
/// There is no participant endpoint for a single action yet, so the page
/// looks in the caller's live actions first and then asks for the creator's
/// own view, which only the creator can open. Returns null when neither has
/// it (ended, removed, not live, or a malformed link).
final FutureProviderFamily<ActionOpportunity?, String> actionDetailProvider =
    FutureProvider.autoDispose.family((ref, actionId) async {
      if (!UuidValidation.isValidUUIDFormat(fromString: actionId)) return null;
      final id = UuidValue.fromString(actionId);
      final repository = ref.watch(actionRepositoryProvider);
      final available = await repository.listAvailable();
      for (final action in available) {
        if (action.id == id) return action;
      }
      try {
        return await repository.preview(id);
      } on ServerpodClientInternalServerError {
        // previewAction refuses another creator's action with an untyped
        // error, which arrives as a 500. The live feed it was missing from
        // just loaded, so this means "not here", not an outage. Any other
        // failure (a lapsed session, the network) surfaces as one.
        return null;
      }
    });

/// Opens the venue-code scanner and returns the scanned code, or null.
typedef VenueCodeScanner = Future<String?> Function(BuildContext context);

final venueCodeScannerProvider = Provider<VenueCodeScanner>(
  (ref) => scanVenueCode,
);

/// Captures camera, microphone, motion, or movement proof for one
/// requirement. Defaults to the capture flow; tests replace it.
typedef EvidenceCaptureLauncher = Future<EvidenceSubmissionResult?> Function(
  BuildContext context, {
  required ActionAttemptView attempt,
  required ActionRequirementView requirement,
});

final evidenceCaptureLauncherProvider = Provider<EvidenceCaptureLauncher>(
  (ref) => captureEvidence,
);

/// How long to wait before checking a proof again, given how long the page
/// has been checking: every 5 seconds for two minutes, then every 30.
Duration attemptPollInterval(Duration elapsed) =>
    elapsed < const Duration(minutes: 2)
    ? const Duration(seconds: 5)
    : const Duration(seconds: 30);

final attemptPollIntervalProvider = Provider<Duration Function(Duration)>(
  (ref) => attemptPollInterval,
);

/// The first location requirement of [action], if it has a place.
ActionRequirementView? placeOf(ActionOpportunity action) {
  for (final requirement in action.requirements) {
    if (requirement.kind == ActionRequirementKind.location &&
        requirement.latitude != null &&
        requirement.longitude != null) {
      return requirement;
    }
  }
  return null;
}
