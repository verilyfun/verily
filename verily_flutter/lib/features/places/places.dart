import 'dart:math' as math;

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skribble_maps/skribble_maps.dart';

/// Builds the map's basemap. Null uses MapLibre; tests and screenshots
/// replace it, because the native map view cannot run there.
final actionMapViewBuilderProvider = Provider<WiredMapViewBuilder?>(
  (ref) => null,
);

/// Great-circle distance in metres between two points (haversine).
double distanceMeters(
  double fromLatitude,
  double fromLongitude,
  double toLatitude,
  double toLongitude,
) {
  const earthRadius = 6371000.0;
  double radians(double degrees) => degrees * math.pi / 180;
  final dLat = radians(toLatitude - fromLatitude);
  final dLon = radians(toLongitude - fromLongitude);
  final a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(radians(fromLatitude)) *
          math.cos(radians(toLatitude)) *
          math.pow(math.sin(dLon / 2), 2);
  return 2 * earthRadius * math.asin(math.sqrt(a));
}

/// Points tracing a circle of [radiusMeters] around [center], for drawing a
/// place's radius as a hatched area.
List<LatLng> circlePoints(
  LatLng center,
  double radiusMeters, {
  int segments = 48,
}) {
  const earthRadius = 6371000.0;
  final angular = radiusMeters / earthRadius;
  final lat = center.latitude * math.pi / 180;
  final lon = center.longitude * math.pi / 180;
  return [
    for (var i = 0; i < segments; i++)
      () {
        final bearing = 2 * math.pi * i / segments;
        final pointLat = math.asin(
          math.sin(lat) * math.cos(angular) +
              math.cos(lat) * math.sin(angular) * math.cos(bearing),
        );
        final pointLon =
            lon +
            math.atan2(
              math.sin(bearing) * math.sin(angular) * math.cos(lat),
              math.cos(angular) - math.sin(lat) * math.sin(pointLat),
            );
        return LatLng(pointLat * 180 / math.pi, pointLon * 180 / math.pi);
      }(),
  ];
}
