import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon, WiredSlider;
import 'package:skribble_maps/skribble_maps.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/features/create/editor/editor_form.dart';
import 'package:verily_flutter/features/create/editor/widgets/editor_common.dart';
import 'package:verily_flutter/features/evidence/evidence_service.dart';
import 'package:verily_flutter/features/evidence/location_service.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';
import 'package:verily_flutter/features/places/places.dart';

/// The radii a creator can choose, close together where small differences
/// matter (a doorway, a park bench) and wider apart for a whole district.
const placeRadiusSteps = <double>[
  10,
  25,
  50,
  75,
  100,
  150,
  200,
  300,
  500,
  750,
  1000,
  1500,
  2000,
  3000,
  5000,
];

/// How long the basemap may take to load before the picker says so and
/// offers coordinates instead of an empty frame.
const placeMapLoadTimeout = Duration(seconds: 15);

/// Where a location proof counts: tap the map to drop the pin, see the
/// radius as a hatched area in place green, and size it with the slider.
///
/// Latitude and longitude fields sit under the map for precise entry and for
/// screen readers. Where the map cannot draw (no MapLibre on this platform,
/// or the basemap never loads) the picker says so and keeps only the fields,
/// rather than showing an empty frame.
class PlacePicker extends HookConsumerWidget {
  const PlacePicker({
    required this.requirement,
    required this.onChanged,
    super.key,
  });

  final RequirementForm requirement;

  /// Called after the pin or the radius moves.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final key = requirement.requirementKey;
    useListenable(
      Listenable.merge([requirement.latitude, requirement.longitude]),
    );

    final mapViewBuilder = ref.watch(actionMapViewBuilderProvider);
    final platformHasMap =
        mapViewBuilder != null ||
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    final styleLoaded = useRef(false);
    final mapFailed = useState(false);
    final showMap = platformHasMap && !mapFailed.value;
    final showCoordinates = useState(false);
    final locating = useState(false);
    final locationProblem = useState<String?>(null);

    final hasPlace = requirement.hasPlace;
    final center = hasPlace
        ? LatLng(requirement.latitudeValue!, requirement.longitudeValue!)
        : null;
    final controller = useMemoized(
      () => WiredMapController(
        initialCenter: center ?? const LatLng(20, 0),
        initialZoom: center == null
            ? 1.5
            : placeZoomFor(requirement.radiusMeters),
      ),
    );
    useEffect(() => controller.dispose, [controller]);

    // A test's map view never loads a style, so only the real basemap is
    // timed.
    useEffect(() {
      if (mapViewBuilder != null || !platformHasMap) return null;
      final timer = Timer(placeMapLoadTimeout, () {
        if (!styleLoaded.value) mapFailed.value = true;
      });
      return timer.cancel;
    }, const []);

    void place(double latitude, double longitude) {
      requirement.setPlace(latitude, longitude);
      onChanged();
    }

    Future<void> locateMe() async {
      locating.value = true;
      locationProblem.value = null;
      try {
        final fix = await ref.read(locationServiceProvider).precisePosition();
        if (!context.mounted) return;
        place(fix.latitude, fix.longitude);
        unawaited(
          controller.move(
            LatLng(fix.latitude, fix.longitude),
            zoom: placeZoomFor(requirement.radiusMeters),
          ),
        );
      } on LocationException catch (error) {
        if (!context.mounted) return;
        locationProblem.value = switch (error.failure) {
          LocationFailure.servicesOff ||
          LocationFailure.denied ||
          LocationFailure.deniedForever => l10n.editorLocationOff,
          LocationFailure.timedOut => l10n.editorLocationFailed,
        };
      } on Object catch (error) {
        debugPrint('Reading the position for a place failed: $error');
        if (!context.mounted) return;
        locationProblem.value = l10n.editorLocationFailed;
      } finally {
        if (context.mounted) locating.value = false;
      }
    }

    final radiusIndex = _nearestStep(requirement.radiusMeters);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showMap) ...[
          Container(
            height: 240,
            decoration: VerilyRoughDecoration(
              color: palette.placeWash,
              outline: palette.ink,
              seed: 257,
            ),
            clipBehavior: Clip.antiAlias,
            child: WiredMap(
              key: VerilyTestKeys.editorPlaceMap(key),
              controller: controller,
              style: theme.brightness == Brightness.dark
                  ? WiredMapStyle.night
                  : WiredMapStyle.paper,
              backgroundColor: palette.placeWash,
              semanticLabel: l10n.editorMapLabel,
              // Drags that start on the map move the map; the page scrolls
              // from everywhere else.
              gestureRecognizers: const {
                Factory<OneSequenceGestureRecognizer>(
                  EagerGestureRecognizer.new,
                ),
              },
              onStyleLoaded: () => styleLoaded.value = true,
              onTap: (point) => place(point.latitude, point.longitude),
              mapViewBuilder: mapViewBuilder,
              children: [
                if (center != null) ...[
                  WiredMapFeatureLayer(
                    semanticLabel: l10n.editorRadius(
                      requirement.radiusMeters.round(),
                    ),
                    features: [
                      WiredMapPolygon(
                        points: circlePoints(center, requirement.radiusMeters),
                        inkColor: palette.place,
                        fillColor: palette.place.withValues(alpha: 0.35),
                      ),
                    ],
                  ),
                  WiredMapMarkerLayer(
                    markers: [
                      WiredMapMarker(
                        point: center,
                        semanticLabel: l10n.editorPlacePin,
                        child: WiredMapPin(
                          fillColor: palette.placeWash,
                          inkColor: palette.ink,
                          iconColor: palette.place,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.editorPlaceTapHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.mutedInk,
            ),
          ),
        ] else
          EditorNote(
            text: l10n.editorMapUnavailable,
            icon: VerilyIcons.map,
            tone: VerilyTone.place,
          ),
        const SizedBox(height: editorStackGap),
        VerilyActionButton(
          key: VerilyTestKeys.editorUseMyLocation(key),
          label: l10n.editorUseMyLocation,
          tone: VerilyActionTone.secondary,
          isLoading: locating.value,
          leading: const SkribbleIcon(data: VerilyIcons.myLocation),
          onPressed: locateMe,
        ),
        if (locationProblem.value case final problem?) ...[
          const SizedBox(height: 8),
          Text(
            problem,
            style: theme.textTheme.bodySmall?.copyWith(color: palette.ink),
          ),
        ],
        const SizedBox(height: editorStackGap),
        Text(
          l10n.editorRadius(requirement.radiusMeters.round()),
          style: theme.textTheme.labelLarge?.copyWith(color: palette.ink),
        ),
        SizedBox(
          height: 48,
          child: WiredSlider(
            key: VerilyTestKeys.editorPlaceRadius(key),
            value: radiusIndex.toDouble(),
            max: (placeRadiusSteps.length - 1).toDouble(),
            divisions: placeRadiusSteps.length - 1,
            semanticLabel: l10n.editorRadiusSemantic,
            onChanged: (value) {
              requirement.radiusMeters = placeRadiusSteps[value.round()];
              onChanged();
              return true;
            },
          ),
        ),
        if (showMap)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: VerilyTestKeys.editorPlaceCoordinates(key),
              onPressed: () => showCoordinates.value = !showCoordinates.value,
              icon: AnimatedRotation(
                turns: showCoordinates.value ? 0.5 : 0,
                duration: const Duration(milliseconds: 150),
                child: const SkribbleIcon(
                  data: VerilyIcons.chevronDown,
                  size: 18,
                ),
              ),
              label: Text(l10n.editorCoordinates),
            ),
          ),
        if (!showMap || showCoordinates.value) ...[
          const SizedBox(height: 8),
          _CoordinateFields(requirement: requirement, onChanged: onChanged),
        ],
        FormField<void>(
          validator: (_) =>
              requirement.hasPlace ? null : l10n.editorPlaceMissing,
          builder: (field) => field.hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    field.errorText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.ink,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  static int _nearestStep(double radius) {
    var nearest = 0;
    for (var index = 1; index < placeRadiusSteps.length; index++) {
      if ((placeRadiusSteps[index] - radius).abs() <
          (placeRadiusSteps[nearest] - radius).abs()) {
        nearest = index;
      }
    }
    return nearest;
  }
}

/// A zoom that shows the whole radius with some street around it.
double placeZoomFor(double radiusMeters) => switch (radiusMeters) {
  < 60 => 17,
  < 150 => 16,
  < 400 => 15,
  < 1000 => 14,
  < 3000 => 12.5,
  _ => 11,
};

class _CoordinateFields extends StatelessWidget {
  const _CoordinateFields({required this.requirement, required this.onChanged});

  final RequirementForm requirement;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final key = requirement.requirementKey;

    String? validate(String? text, double limit) {
      final trimmed = text?.trim() ?? '';
      if (trimmed.isEmpty) return null;
      final value = double.tryParse(trimmed);
      if (value == null || !value.isFinite || value.abs() > limit) {
        return l10n.editorCoordinatesInvalid;
      }
      return null;
    }

    const keyboard = TextInputType.numberWithOptions(
      signed: true,
      decimal: true,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            key: VerilyTestKeys.editorPlaceLatitude(key),
            controller: requirement.latitude,
            keyboardType: keyboard,
            decoration: InputDecoration(labelText: l10n.editorLatitudeLabel),
            validator: (text) => validate(text, 90),
            onChanged: (_) => onChanged(),
          ),
        ),
        const SizedBox(width: editorStackGap),
        Expanded(
          child: TextFormField(
            key: VerilyTestKeys.editorPlaceLongitude(key),
            controller: requirement.longitude,
            keyboardType: keyboard,
            decoration: InputDecoration(labelText: l10n.editorLongitudeLabel),
            validator: (text) => validate(text, 180),
            onChanged: (_) => onChanged(),
          ),
        ),
      ],
    );
  }
}
