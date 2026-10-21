import 'dart:collection';

import 'package:flutter/painting.dart';
import 'package:skribble/skribble.dart';

/// The Verily pen: the one hand-drawn line every outline in the app
/// shares.
///
/// Preparing a rough drawing is expensive, so drawings are cached by
/// everything that shapes them. The seed is part of that key, which is what
/// keeps an outline identical on every frame: a control that rebuilds, is
/// pressed, or gains focus never re-rolls its wobble.
abstract final class VerilyPen {
  /// The pen weight `DESIGN.md` draws cards and controls with.
  static const double strokeWidth = 2.6;

  /// How far inside its box the centre of an outline lands.
  ///
  /// Skribble keeps the whole line, including its wobble and the pen's
  /// widest point, inside the box. Fills and clips inset by this much meet
  /// the line at its centre, so nothing pokes out past the pen.
  static double inset({double strokeWidth = VerilyPen.strokeWidth}) {
    final config = DrawConfig.defaultValues;
    return strokeWidth * config.pen.reach +
        1 +
        config.maxRandomnessOffset * config.roughness;
  }

  static const int _cacheCapacity = 256;
  static final LinkedHashMap<Object, RoughDrawing> _cache =
      LinkedHashMap<Object, RoughDrawing>();

  /// Inks a rounded-rectangle outline that fits inside [size].
  ///
  /// The line stays inside the box, including its wobble, so a parent never
  /// clips it.
  static void outline(
    Canvas canvas,
    Size size, {
    required Color color,
    double radius = 12,
    double strokeWidth = VerilyPen.strokeWidth,
    int seed = 1,
  }) {
    if (size.isEmpty || color.a == 0 || strokeWidth <= 0) {
      return;
    }
    _cached(
      ('outline', size, color.toARGB32(), radius, strokeWidth, seed),
      () => WiredRoundedRectangleBase(
        borderRadius: BorderRadius.circular(radius),
        fillColor: color.withValues(alpha: 0),
        borderColor: color,
        strokeWidth: strokeWidth,
      ).prepare(size, DrawConfig.build(seed: seed), NoFiller()),
    ).paint(canvas);
  }

  /// Inks a hatched oval flourish, tilted inside [size].
  ///
  /// Posters and empty states carry it as a small flourish; it is decoration
  /// only and never carries meaning.
  static void hatchedOval(
    Canvas canvas,
    Size size, {
    required Color color,
    int seed = 5,
  }) {
    if (size.isEmpty || color.a == 0) {
      return;
    }
    final drawing = _cached(('hatch', size, color.toARGB32(), seed), () {
      final config = DrawConfig.build(seed: seed);
      final filler = HachureFiller(
        FillerConfig.build(
          drawConfig: config,
          hachureGap: size.shortestSide / 7,
          hachureAngle: 70,
        ),
      );
      final width = size.width * 0.86;
      final height = size.height * 0.56;
      return RoughDrawing(
        Generator(config, filler).ellipse(
          size.width / 2,
          size.height / 2,
          width,
          height,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = color,
      );
    });
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..rotate(-0.32)
      ..translate(-size.width / 2, -size.height / 2);
    drawing.paint(canvas);
    canvas.restore();
  }

  static RoughDrawing _cached(Object key, RoughDrawing Function() prepare) {
    // Re-inserting marks the entry as most recently used.
    final drawing = _cache.remove(key) ?? prepare();
    _cache[key] = drawing;
    if (_cache.length > _cacheCapacity) {
      _cache.remove(_cache.keys.first);
    }
    return drawing;
  }
}
