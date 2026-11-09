import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:verily_brand/verily_brand.dart';

double _distance(BrandPoint a, BrandPoint b) =>
    math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));

/// Every point of [glyph]'s ink, with the pen's half width for strokes.
Iterable<(BrandPoint, double)> _ink(BrandGlyph glyph) sync* {
  for (final shape in glyph.shapes) {
    for (final point in shape.sample(perCurve: 200)) {
      yield (point, 0);
    }
  }
  for (final stroke in glyph.strokes) {
    for (final point in stroke.sample(perCurve: 200)) {
      yield (point, stroke.width / 2);
    }
  }
  for (final dot in glyph.dots) {
    yield (dot.center, dot.radius);
  }
}

void _expectBox(BrandBox actual, BrandBox expected, {double within = 0.01}) {
  expect(actual.left, closeTo(expected.left, within), reason: 'left');
  expect(actual.top, closeTo(expected.top, within), reason: 'top');
  expect(actual.width, closeTo(expected.width, within), reason: 'width');
  expect(actual.height, closeTo(expected.height, within), reason: 'height');
}

void main() {
  group('the pin-check', () {
    const pin = VerilyGeometry.pin;
    final check = VerilyGeometry.markCheck;
    final flick = VerilyGeometry.markFlick;
    final pinPath = BrandInkPainter.shapePathOf(pin);
    bool inPin(BrandPoint point) => pinPath.contains(Offset(point.x, point.y));

    test('is a solid pin, a knocked-out check, and a flick', () {
      final glyph = VerilyGeometry.markGlyph;
      expect(glyph.shapes, [same(pin)]);
      expect(glyph.knockouts, [same(check)]);
      expect(glyph.strokes, [same(flick)]);
      expect(glyph.dots, isEmpty);
      expect(pin.ink, BrandInk.accent);
      expect(flick.ink, BrandInk.accent);
    });

    test('draws the approved pin, exactly', () {
      expect(
        pin.pathData,
        'M 240 486 C 240 486 90 330.56 90 218 '
        'C 90 135.15 157.15 68 240 68 '
        'C 322.85 68 390 135.15 390 218 '
        'C 390 330.56 240 486 240 486 Z',
      );
      expect(pin.curves.last.end.x, pin.start.x);
      expect(pin.curves.last.end.y, pin.start.y);
      _expectBox(pin.bounds, const BrandBox(90, 68, 300, 418));
    });

    test('draws the approved check and flick, as straight lines', () {
      expect(check.pathData, 'M 162 230 L 220 292 L 457.3 2.5');
      expect(flick.pathData, 'M 380.7 95.9 L 420 48');
      expect(check.curves.every((curve) => curve.isLine), isTrue);
      expect(flick.curves.single.isLine, isTrue);
      expect(check.width, VerilyGeometry.markWeight);
      expect(flick.width, VerilyGeometry.markWeight);
      expect(VerilyGeometry.markWeight, 42);
      expect(VerilyGeometry.smallWeight, 54);
      expect(VerilyGeometry.iconWeight, 46);
    });

    test("puts the check's vertex inside the pin", () {
      expect(inPin(check.start), isTrue);
      expect(inPin(check.curves.first.end), isTrue);
    });

    test('runs the long arm through the rim and past it', () {
      expect(inPin(check.curves.last.end), isFalse);
      final along = check.locate(flick.curves.last.end);
      expect(
        along.along,
        lessThan(BrandInkPainter.lengthOf(check)),
        reason: 'the cut runs on past the end of the flick',
      );
    });

    test('lays the flick on the long arm, after a small gap', () {
      final start = check.locate(flick.start);
      final end = check.locate(flick.curves.last.end);
      expect(start.off, lessThan(0.05));
      expect(end.off, lessThan(0.05));
      expect(end.along, greaterThan(start.along));
      // Walk out along the long arm to find where its centreline leaves
      // the pin.
      final vertex = check.curves.first.end;
      final tip = check.curves.last.end;
      final arm = _distance(vertex, tip);
      var rim = 0.0;
      for (var d = 0.0; d <= arm; d += 0.05) {
        final t = d / arm;
        final point = BrandPoint(
          vertex.x + (tip.x - vertex.x) * t,
          vertex.y + (tip.y - vertex.y) * t,
        );
        if (inPin(point)) rim = d;
      }
      final flickStart = _distance(vertex, flick.start);
      final gap = flickStart - flick.width / 2 - rim;
      expect(gap, closeTo(16, 1.5));
    });

    test('counts the pin and the flick as ink, but not the cut', () {
      final ink = VerilyGeometry.markGlyph.inkBounds;
      _expectBox(ink, const BrandBox(90, 27, 351, 459), within: 0.05);
      final withoutCut = BrandGlyph(
        shapes: VerilyGeometry.markGlyph.shapes,
        strokes: VerilyGeometry.markGlyph.strokes,
      ).inkBounds;
      _expectBox(ink, withoutCut);
    });

    test('fits its artboard with room on every side', () {
      final ink = VerilyGeometry.markGlyph.inkBounds;
      for (final edge in [
        ink.left,
        ink.top,
        VerilyGeometry.markArtboard - ink.right,
        VerilyGeometry.markArtboard - ink.bottom,
      ]) {
        expect(edge, greaterThan(20));
      }
      for (final weight in [
        VerilyGeometry.markWeight,
        VerilyGeometry.smallWeight,
      ]) {
        final heavy = VerilyGeometry.markGlyph.withPenWidth(weight).inkBounds;
        expect(heavy.top, greaterThan(0));
        expect(heavy.right, lessThan(VerilyGeometry.markArtboard));
      }
    });
  });

  group('the geometry model', () {
    test('a line is a cubic with controls at its thirds', () {
      final line = BrandCubic.line(
        const BrandPoint(0, 0),
        const BrandPoint(30, -60),
      );
      expect(line.isLine, isTrue);
      expect(line.control1.x, closeTo(10, 1e-9));
      expect(line.control1.y, closeTo(-20, 1e-9));
      expect(line.control2.x, closeTo(20, 1e-9));
      expect(line.control2.y, closeTo(-40, 1e-9));
      expect(line.pathCommand, ' L 30 -60');
      final moved = line.transform(scale: 2, dx: 1, dy: 1);
      expect(moved.isLine, isTrue);
      expect(moved.pathCommand, ' L 61 -119');
      const curve = BrandCubic(
        BrandPoint(1, 2),
        BrandPoint(3, 4),
        BrandPoint(5, 6),
      );
      expect(curve.isLine, isFalse);
      expect(curve.pathCommand, ' C 1 2 3 4 5 6');
      expect(curve.transform(scale: 2).isLine, isFalse);
    });

    test('transform moves every part of a glyph', () {
      const scale = 0.5;
      const dx = 30.0;
      const dy = -12.0;
      final glyph = BrandGlyph(
        shapes: VerilyGeometry.markGlyph.shapes,
        knockouts: VerilyGeometry.markGlyph.knockouts,
        strokes: VerilyGeometry.markGlyph.strokes,
        dots: VerilyGeometry.wordmark.dots,
      );
      final moved = glyph.transform(scale: scale, dx: dx, dy: dy);
      expect(moved.shapes, hasLength(1));
      expect(moved.knockouts, hasLength(1));
      expect(moved.strokes, hasLength(1));
      expect(moved.dots, hasLength(1));
      expect(moved.shapes.single.start.x, 240 * scale + dx);
      expect(moved.shapes.single.start.y, 486 * scale + dy);
      expect(moved.shapes.single.ink, BrandInk.accent);
      expect(moved.knockouts.single.start.x, 162 * scale + dx);
      expect(moved.knockouts.single.width, 42 * scale);
      expect(moved.knockouts.single.curves.every((c) => c.isLine), isTrue);
      expect(moved.strokes.single.width, 42 * scale);
      expect(moved.strokes.single.start.y, 95.9 * scale + dy);
      final dot = glyph.dots.single;
      expect(moved.dots.single.center.x, dot.center.x * scale + dx);
      expect(moved.dots.single.radius, dot.radius * scale);
      expect(moved.dots.single.ink, dot.ink);
      final ink = glyph.inkBounds;
      _expectBox(
        moved.inkBounds,
        BrandBox(
          ink.left * scale + dx,
          ink.top * scale + dy,
          ink.width * scale,
          ink.height * scale,
        ),
      );
    });

    test('withPenWidth changes the cut and the strokes, not the shapes', () {
      final heavy = VerilyGeometry.markGlyph.withPenWidth(54);
      expect(heavy.knockouts.single.width, 54);
      expect(heavy.strokes.single.width, 54);
      expect(heavy.shapes.single, same(VerilyGeometry.pin));
      expect(heavy.inkBounds.top, closeTo(48 - 27, 0.05));
    });

    test('locate finds a point along a stroke and how far off it lies', () {
      final check = VerilyGeometry.markCheck;
      final vertex = check.locate(const BrandPoint(220, 292));
      expect(vertex.off, closeTo(0, 1e-6));
      expect(vertex.along, closeTo(math.sqrt(58 * 58 + 62 * 62), 1e-6));
      final aside = check.locate(const BrandPoint(162, 200));
      expect(aside.off, closeTo(30, 1e-6));
      expect(aside.along, closeTo(0, 1e-6));
    });

    test('reachFrom measures ink, not knockouts', () {
      const center = BrandPoint(240, 218);
      final mark = VerilyGeometry.markGlyph;
      final flickEnd = _distance(center, const BrandPoint(420, 48)) + 21;
      expect(mark.reachFrom(center), closeTo(flickEnd, 0.5));
      final pinOnly = BrandGlyph(
        shapes: mark.shapes,
        knockouts: mark.knockouts,
      );
      expect(pinOnly.reachFrom(center), closeTo(268, 0.5));
      final dotted = BrandGlyph(dots: VerilyGeometry.wordmark.dots);
      const dot = VerilyGeometry.iDot;
      expect(
        dotted.reachFrom(const BrandPoint(0, 0)),
        closeTo(
          _distance(const BrandPoint(0, 0), dot.center) + dot.radius,
          1e-9,
        ),
      );
    });
  });

  group('the wordmark', () {
    test('writes the check, then erily, then dots the i', () {
      const glyph = VerilyGeometry.wordmark;
      expect(glyph.shapes, isEmpty);
      expect(glyph.knockouts, isEmpty);
      expect(glyph.strokes.first, same(VerilyGeometry.checkV));
      expect(glyph.strokes.first.ink, BrandInk.accent);
      expect(
        glyph.strokes.skip(1).map((s) => s.ink),
        everyElement(BrandInk.body),
      );
      expect(glyph.dots.single.ink, BrandInk.accent);
    });
  });

  group('the lockups', () {
    final word = VerilyGeometry.wordmarkBox;

    BrandBox markInk(BrandGlyph lockup) => BrandGlyph(
      shapes: lockup.shapes,
      strokes: [lockup.strokes.first],
    ).inkBounds;

    test('carry the whole mark, then the whole wordmark', () {
      for (final lockup in [
        VerilyGeometry.horizontalLockup,
        VerilyGeometry.stackedLockup,
      ]) {
        expect(lockup.shapes, hasLength(1));
        expect(lockup.knockouts, hasLength(1));
        expect(
          lockup.strokes,
          hasLength(1 + VerilyGeometry.wordmark.strokes.length),
        );
        expect(
          lockup.strokes.skip(1).map((s) => s.pathData),
          VerilyGeometry.wordmark.strokes.map((s) => s.pathData),
        );
        expect(lockup.dots, hasLength(1));
        // The mark keeps its proportions: cut and flick at the mark weight.
        final scale = lockup.shapes.single.bounds.height / 418;
        expect(lockup.knockouts.single.width, closeTo(42 * scale, 1e-6));
        expect(lockup.strokes.first.width, closeTo(42 * scale, 1e-6));
      }
    });

    test('set the horizontal mark beside the word, as tall as it', () {
      final mark = markInk(VerilyGeometry.horizontalLockup);
      expect(mark.height, closeTo(word.height * 1.04, 1e-6));
      expect(mark.center.y, closeTo(word.center.y, 1e-6));
      expect(mark.right, closeTo(word.left - word.height * 0.17, 1e-6));
    });

    test('set the stacked mark centred over the word', () {
      final mark = markInk(VerilyGeometry.stackedLockup);
      expect(mark.height, closeTo(word.height * 1.3, 1e-6));
      expect(mark.center.x, closeTo(word.center.x, 1e-6));
      expect(mark.bottom, closeTo(word.top - word.height * 0.2, 1e-6));
    });
  });

  group('the app icons', () {
    test('centre the launcher mark at 60% of the icon', () {
      final mark = VerilyGeometry.appIconMark;
      final ink = mark.inkBounds;
      expect(ink.center.x, closeTo(VerilyGeometry.appIconArtboard / 2, 1e-6));
      expect(ink.center.y, closeTo(VerilyGeometry.appIconArtboard / 2, 1e-6));
      expect(ink.height, closeTo(VerilyGeometry.appIconArtboard * 0.6, 1e-6));
      final scale = mark.shapes.single.bounds.height / 418;
      expect(
        mark.knockouts.single.width,
        closeTo(VerilyGeometry.iconWeight * scale, 1e-6),
      );
      expect(
        mark.strokes.single.width,
        closeTo(VerilyGeometry.iconWeight * scale, 1e-6),
      );
    });

    test(
      'keep the adaptive foreground, flick included, in the safe circle',
      () {
        const side = VerilyGeometry.adaptiveIconArtboard;
        const center = BrandPoint(side / 2, side / 2);
        final mark = VerilyGeometry.adaptiveIconMark;
        expect(mark.shapes, hasLength(1));
        expect(mark.knockouts, hasLength(1));
        expect(mark.strokes, hasLength(1));
        var furthest = 0.0;
        for (final (point, pen) in _ink(mark)) {
          final reach = _distance(point, center) + pen;
          expect(
            reach,
            lessThanOrEqualTo(VerilyGeometry.adaptiveIconSafeRadius),
          );
          furthest = math.max(furthest, reach);
        }
        // Shrunk only as far as it must be: the flick's cap touches the
        // allowance.
        expect(
          furthest,
          closeTo(VerilyGeometry.adaptiveIconSafeRadius - 1.5, 0.05),
        );
        final flick = mark.strokes.single;
        expect(
          _distance(flick.curves.last.end, center) + flick.width / 2,
          closeTo(furthest, 0.05),
        );
        // The same proportions as the launcher mark.
        final launcher = VerilyGeometry.appIconMark;
        final ratio =
            launcher.knockouts.single.width /
            launcher.shapes.single.bounds.height;
        expect(
          mark.knockouts.single.width / mark.shapes.single.bounds.height,
          closeTo(ratio, 1e-9),
        );
      },
    );
  });
}
