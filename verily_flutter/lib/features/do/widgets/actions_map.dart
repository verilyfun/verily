import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skribble_maps/skribble_maps.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_state_panel.dart';
import 'package:verily_flutter/features/do/do_providers.dart';
import 'package:verily_flutter/features/evidence/location_service.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';
import 'package:verily_flutter/features/places/places.dart';

/// The feed's actions with a place, as pins on a sketched map.
///
/// The basemap is MapLibre with OpenFreeMap's keyless style (paper by day,
/// dark at night); pins and areas are drawn by the pen above it. Actions
/// without a place are not on the map.
class ActionsMap extends ConsumerWidget {
  const ActionsMap({
    required this.actions,
    required this.onOpen,
    this.here,
    super.key,
  });

  final List<ActionOpportunity> actions;
  final ValueChanged<ActionOpportunity> onOpen;

  /// The device's approximate position, when shared.
  final LocationFix? here;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    final placed = [
      for (final action in actions)
        if (placeOf(action) case final place?) (action, place),
    ];
    if (placed.isEmpty) {
      return VerilyStatePanel.empty(
        title: l10n.doMapEmptyTitle,
        message: l10n.doMapEmptyBody,
        tone: VerilyTone.place,
      );
    }
    final center = here != null
        ? LatLng(here!.latitude, here!.longitude)
        : LatLng(placed.first.$2.latitude!, placed.first.$2.longitude!);

    return WiredMap(
      key: VerilyTestKeys.doMap,
      initialCenter: center,
      initialZoom: here == null ? 12 : 13,
      style: theme.brightness == Brightness.dark
          ? WiredMapStyle.night
          : WiredMapStyle.paper,
      backgroundColor: palette.canvas,
      semanticLabel: l10n.doMapLabel,
      // The map owns drags that start on it; the page around it still
      // scrolls.
      gestureRecognizers: const {
        Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
      },
      mapViewBuilder: ref.watch(actionMapViewBuilderProvider),
      children: [
        WiredMapMarkerLayer(
          markers: [
            for (final (action, place) in placed)
              WiredMapMarker(
                key: VerilyTestKeys.doMapPin(action.id.toString()),
                point: LatLng(place.latitude!, place.longitude!),
                semanticLabel: action.title,
                onTap: () => onOpen(action),
                child: WiredMapPin(
                  fillColor: palette.placeWash,
                  inkColor: palette.ink,
                  iconColor: palette.place,
                  seed: action.actionKey.hashCode & 0x7fffffff,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
