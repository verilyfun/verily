import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skribble_maps/skribble_maps.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/features/places/places.dart';

/// The place sheet: a sketched map with the pin in place green and the
/// radius as a hatched sage area, with its name and radius written under
/// it (DESIGN.md).
class PlacePreview extends ConsumerWidget {
  const PlacePreview({required this.place, super.key});

  /// A location requirement with coordinates.
  final ActionRequirementView place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    final center = LatLng(place.latitude!, place.longitude!);
    final radius = place.radiusMeters ?? 100;

    return Container(
      decoration: VerilyRoughDecoration(
        color: palette.surface,
        outline: palette.ink,
        seed: 241,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 200,
            child: WiredMap(
              initialCenter: center,
              initialZoom: _zoomFor(radius),
              style: theme.brightness == Brightness.dark
                  ? WiredMapStyle.night
                  : WiredMapStyle.paper,
              backgroundColor: palette.placeWash,
              semanticLabel: l10n.actionPlaceMapLabel(place.title),
              // A preview, not a map to explore: it never steals the page's
              // scroll.
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: false,
              showZoomControls: false,
              mapViewBuilder: ref.watch(actionMapViewBuilderProvider),
              children: [
                WiredMapFeatureLayer(
                  semanticLabel: l10n.actionPlaceRadiusLabel(radius.round()),
                  features: [
                    WiredMapPolygon(
                      points: circlePoints(center, radius),
                      inkColor: palette.place,
                      fillColor: palette.place.withValues(alpha: 0.35),
                    ),
                  ],
                ),
                WiredMapMarkerLayer(
                  markers: [
                    WiredMapMarker(
                      point: center,
                      child: WiredMapPin(
                        fillColor: palette.placeWash,
                        inkColor: palette.ink,
                        iconColor: palette.place,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.actionPlaceRadius(radius.round()),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.mutedInk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A zoom that shows the whole radius with some street around it.
  static double _zoomFor(double radiusMeters) => switch (radiusMeters) {
    < 60 => 17,
    < 150 => 16,
    < 400 => 15,
    < 1000 => 14,
    < 3000 => 12.5,
    _ => 11,
  };
}
