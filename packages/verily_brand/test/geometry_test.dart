import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:verily_brand/verily_brand.dart';

double _distance(BrandPoint a, BrandPoint b) =>
    math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));

/// The direction a curve leaves [from] or arrives at its end, in radians.
double _angle(BrandPoint from, BrandPoint to) =>
    math.atan2(to.y - from.y, to.x - from.x);

void main() {
  group('the pin-check', () {
    const mark = VerilyGeometry.mark;

    test('is one continuous stroke', () {
      expect(VerilyGeometry.markGlyph.strokes, hasLength(1));
      expect(VerilyGeometry.markGlyph.dots, isEmpty);
      expect(mark.curves, hasLength(4));
    });

    test('starts on the centreline of its own long arm', () {
      final arm = BrandStroke(
        start: mark.curves[2].end,
        curves: [mark.curves[3]],
        width: mark.width,
      ).sample(perCurve: 2000);
      final nearest = arm
          .map((point) => _distance(point, mark.start))
          .reduce(math.min);
      expect(nearest, lessThan(0.6));
    });

    test('leaves the arm heading straight up', () {
      final leaving = _angle(mark.start, mark.curves.first.control1);
      expect(leaving * 180 / math.pi, closeTo(-90, 5));
    });

    test('turns sharply at the pin point, the vertex of the check', () {
      final down = _angle(mark.curves[2].control2, mark.curves[2].end);
      final up = _angle(mark.curves[2].end, mark.curves[3].control1);
      var turn = (up - down).abs() * 180 / math.pi;
      if (turn > 180) turn = 360 - turn;
      expect(turn, greaterThan(60));
    });

    test('is smooth everywhere else', () {
      for (final i in [0, 1]) {
        final arrive = _angle(mark.curves[i].control2, mark.curves[i].end);
        final leave = _angle(mark.curves[i].end, mark.curves[i + 1].control1);
        expect((arrive - leave).abs(), lessThan(0.05), reason: 'join $i');
      }
    });

    test('is centred on its artboard', () {
      final ink = VerilyGeometry.markGlyph.inkBounds;
      expect(ink.center.x, closeTo(VerilyGeometry.markArtboard / 2, 2));
      expect(ink.center.y, closeTo(VerilyGeometry.markArtboard / 2, 2));
      expect(ink.left, greaterThan(0));
      expect(ink.right, lessThan(VerilyGeometry.markArtboard));
    });
  });

  group('the wordmark', () {
    test('writes the check, then erily, then dots the i', () {
      const glyph = VerilyGeometry.wordmark;
      expect(glyph.strokes.first, same(VerilyGeometry.checkV));
      expect(glyph.strokes.first.ink, BrandInk.accent);
      expect(
        glyph.strokes.skip(1).map((s) => s.ink),
        everyElement(BrandInk.body),
      );
      expect(glyph.dots.single.ink, BrandInk.accent);
    });
  });

  group('the app icons', () {
    test('keep the adaptive foreground inside the safe circle', () {
      const center = VerilyGeometry.adaptiveIconArtboard / 2;
      final mark = VerilyGeometry.adaptiveIconMark;
      for (final point in mark.sample()) {
        final reach =
            math.sqrt(
              math.pow(point.x - center, 2) + math.pow(point.y - center, 2),
            ) +
            mark.width / 2;
        expect(reach, lessThanOrEqualTo(VerilyGeometry.adaptiveIconSafeRadius));
      }
    });

    test('centre the launcher mark', () {
      final ink = BrandGlyph(strokes: [VerilyGeometry.appIconMark]).inkBounds;
      expect(ink.center.x, closeTo(VerilyGeometry.appIconArtboard / 2, 1));
      expect(ink.center.y, closeTo(VerilyGeometry.appIconArtboard / 2, 1));
    });
  });
}
