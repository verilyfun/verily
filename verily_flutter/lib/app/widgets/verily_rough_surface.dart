import 'package:flutter/material.dart';

import 'package:verily_flutter/app/theme/verily_pen.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';

/// A solid field with a stable hand-drawn outline.
///
/// A postcard wash or a stamp-coloured action is a real fill, and the pen
/// outline around it must be the same wobble on every rebuild. The child stays
/// transparent so it never covers the outline.
class VerilyRoughSurface extends StatelessWidget {
  const VerilyRoughSurface({
    required this.child,
    required this.fill,
    required this.outline,
    this.radius = 12,
    this.strokeWidth = VerilyPen.strokeWidth,
    this.seed = 1,
    this.padding = EdgeInsets.zero,
    this.minHeight,
    super.key,
  });

  final Widget child;
  final Color fill;
  final Color outline;
  final double radius;

  /// 2.4 units is the double pen weight the design system draws.
  final double strokeWidth;

  /// Fixed so the wobble is identical for a given surface on every rebuild.
  final int seed;

  final EdgeInsetsGeometry padding;
  final double? minHeight;

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(minHeight: minHeight ?? 0),
    padding: padding,
    decoration: VerilyRoughDecoration(
      color: fill,
      outline: outline,
      radius: radius,
      strokeWidth: strokeWidth,
      seed: seed,
    ),
    child: child,
  );
}
