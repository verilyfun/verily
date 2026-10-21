import 'dart:math' as math;

/// Server-owned limits for deciding whether a location proof is fresh and
/// physically plausible. Device coordinates remain untrusted input; this
/// policy complements, rather than replaces, device-integrity attestation.
///
/// The policy does no geodesy of its own. Distances come from PostGIS
/// (`ST_Distance` on the WGS 84 spheroid) so every location decision is
/// measured by the same engine that stores and indexes the coordinates.
class LocationEvidencePolicy {
  const LocationEvidencePolicy({
    this.maximumAge = const Duration(minutes: 5),
    this.futureTolerance = const Duration(minutes: 1),
    this.maximumPlausibleSpeedMetersPerSecond = 300,
    this.minimumTravelDistanceMeters = 50000,
  });

  final Duration maximumAge;
  final Duration futureTolerance;
  final double maximumPlausibleSpeedMetersPerSecond;
  final double minimumTravelDistanceMeters;

  LocationEvidenceRisk evaluate({
    required DateTime now,
    required LocationObservation current,
    PreviousLocationObservation? previous,
  }) {
    final capturedAt = current.capturedAt.toUtc();
    final observedAt = now.toUtc();
    if (capturedAt.isBefore(observedAt.subtract(maximumAge))) {
      return LocationEvidenceRisk.stale;
    }
    if (capturedAt.isAfter(observedAt.add(futureTolerance))) {
      return LocationEvidenceRisk.fromFuture;
    }
    if (previous == null || capturedAt.isBefore(previous.capturedAt.toUtc())) {
      return LocationEvidenceRisk.none;
    }

    final elapsedSeconds =
        capturedAt.difference(previous.capturedAt.toUtc()).inMilliseconds /
        Duration.millisecondsPerSecond;
    final effectiveDistance = math.max(
      0,
      previous.distanceMeters -
          previous.accuracyMeters -
          current.accuracyMeters,
    );
    if (effectiveDistance < minimumTravelDistanceMeters) {
      return LocationEvidenceRisk.none;
    }
    if (elapsedSeconds <= 0) {
      return LocationEvidenceRisk.implausibleTravel;
    }
    final speed = effectiveDistance / elapsedSeconds;
    return speed > maximumPlausibleSpeedMetersPerSecond
        ? LocationEvidenceRisk.implausibleTravel
        : LocationEvidenceRisk.none;
  }
}

enum LocationEvidenceRisk { none, stale, fromFuture, implausibleTravel }

/// The submitted check-in being evaluated.
class LocationObservation {
  const LocationObservation({
    required this.accuracyMeters,
    required this.capturedAt,
  });

  final double accuracyMeters;
  final DateTime capturedAt;
}

/// The collector's newest earlier accepted check-in, with its geodesic
/// distance to the current check-in as measured by PostGIS.
class PreviousLocationObservation {
  const PreviousLocationObservation({
    required this.distanceMeters,
    required this.accuracyMeters,
    required this.capturedAt,
  });

  final double distanceMeters;
  final double accuracyMeters;
  final DateTime capturedAt;
}
