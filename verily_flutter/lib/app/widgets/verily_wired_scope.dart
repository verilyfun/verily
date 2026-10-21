import 'package:flutter/material.dart';
import 'package:skribble/skribble.dart';

import 'package:verily_flutter/app/theme/verily_skribble_theme.dart';

/// Renders descendant Skribble components with the active Verily palette.
///
/// The app installs one scope above its navigator, so every route, dialog,
/// and sheet draws Wired components in Verily ink. A nested scope may pick a
/// different [roughnessLevel] for one section. Rough outlines stay
/// seed-stable across rebuilds.
class VerilyWiredScope extends StatelessWidget {
  const VerilyWiredScope({
    required this.child,
    this.roughnessLevel = WiredRoughness.playful,
    super.key,
  });

  /// Coordinated border preset for this subtree.
  final WiredRoughness roughnessLevel;

  final Widget child;

  @override
  Widget build(BuildContext context) => WiredThemeScope(
    data: VerilySkribbleTheme.of(context, roughnessLevel: roughnessLevel),
    child: child,
  );
}
