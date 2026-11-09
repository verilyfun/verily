import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verily_brand/verily_brand.dart';

/// The calls that put ink on the canvas.
const Set<Symbol> _inking = {
  #drawPath,
  #drawCircle,
  #drawLine,
  #drawRect,
  #drawRRect,
  #drawOval,
};

List<RecordedInvocation> _calls(CustomPainter painter, Size size) {
  final canvas = TestRecordingCanvas();
  painter.paint(canvas, size);
  return canvas.invocations;
}

List<RecordedInvocation> _ink(CustomPainter painter, Size size) => [
  for (final call in _calls(painter, size))
    if (_inking.contains(call.invocation.memberName)) call,
];

Path _path(RecordedInvocation call) =>
    call.invocation.positionalArguments.first as Path;

Paint _paint(RecordedInvocation call) =>
    call.invocation.positionalArguments.last as Paint;

bool _isCut(RecordedInvocation call) =>
    call.invocation.memberName == #drawPath &&
    _paint(call).blendMode == BlendMode.dstOut;

double _lengthOf(Path path) =>
    path.computeMetrics().fold(0, (sum, metric) => sum + metric.length);

Widget _onPaper(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: ColoredBox(
    color: VerilyBrandColors.paper,
    child: Center(child: child),
  ),
);

/// The clean mark's calls at [progress], on a canvas the artboard's size.
List<RecordedInvocation> _cleanMark(double progress, {double width = 42}) =>
    _calls(
      VerilyMarkPainter(progress: progress, rough: false, strokeWidth: width),
      const Size.square(VerilyGeometry.markArtboard),
    );

void main() {
  group('draw-on progress', () {
    const size = Size.square(200);

    for (final rough in [true, false]) {
      test('0 paints nothing (rough: $rough)', () {
        expect(
          _calls(
            VerilyMarkPainter(progress: 0, rough: rough),
            size,
          ).where((c) => c.invocation.memberName == #saveLayer),
          isEmpty,
        );
        expect(
          _ink(VerilyMarkPainter(progress: 0, rough: rough), size),
          isEmpty,
        );
        expect(
          _ink(
            BrandGlyphPainter(
              glyph: VerilyGeometry.wordmark,
              box: VerilyGeometry.wordmarkBox,
              accentColor: VerilyBrandColors.stamp,
              bodyColor: VerilyBrandColors.ink,
              progress: 0,
              rough: rough,
            ),
            size,
          ),
          isEmpty,
        );
        expect(
          _ink(VerifiedStampPainter(pressed: 0, rough: rough), size),
          isEmpty,
        );
      });
    }

    test('the mark presses in, is cut, then flicks', () {
      final slots = BrandGlyphPainter.timeline(VerilyGeometry.markGlyph);
      expect(slots, hasLength(3));
      final (pinStart, pinEnd) = slots[0];
      final (cutStart, cutEnd) = slots[1];
      final (flickStart, flickEnd) = slots[2];
      expect(pinStart, 0);
      expect(pinEnd, inInclusiveRange(0.4, 0.5));
      expect(cutStart, closeTo(pinEnd, 1e-9));
      expect(cutEnd, closeTo(1, 1e-9));
      expect(flickStart, inInclusiveRange(0.82, 0.9));
      expect(flickEnd, inInclusiveRange(0.9, 1));
      expect(flickStart, greaterThan(cutStart));
      expect(flickEnd, lessThanOrEqualTo(cutEnd));
      expect(BrandGlyphPainter.ridesKnockout(VerilyGeometry.markGlyph), [
        isTrue,
      ]);
      // The flick draws exactly as the cutting pen passes over it.
      final check = VerilyGeometry.markCheck;
      final length = BrandInkPainter.lengthOf(check);
      final along = check.locate(VerilyGeometry.markFlick.start).along;
      expect(
        flickStart,
        closeTo(cutStart + (cutEnd - cutStart) * along / length, 1e-6),
      );
    });

    test('the wordmark dots its i last, and rides no knockout', () {
      final slots = BrandGlyphPainter.timeline(VerilyGeometry.wordmark);
      expect(slots, hasLength(VerilyGeometry.wordmark.strokes.length + 1));
      expect(slots.first.$1, 0);
      expect(slots.last.$2, closeTo(1, 1e-9));
      for (var i = 1; i < slots.length; i++) {
        expect(slots[i].$1, greaterThanOrEqualTo(slots[i - 1].$2));
      }
      expect(
        BrandGlyphPainter.ridesKnockout(VerilyGeometry.wordmark),
        everyElement(isFalse),
      );
    });

    test('the lockups draw the mark, then write the word', () {
      for (final lockup in [
        VerilyGeometry.horizontalLockup,
        VerilyGeometry.stackedLockup,
      ]) {
        final slots = BrandGlyphPainter.timeline(lockup);
        expect(
          slots,
          hasLength(2 + lockup.strokes.length + lockup.dots.length),
        );
        final cutEnd = slots[1].$2;
        final flick = slots[2];
        expect(flick.$2, lessThanOrEqualTo(cutEnd));
        // The check-v starts after the cut and a pen lift.
        expect(slots[3].$1, greaterThan(cutEnd));
        expect(slots.last.$2, closeTo(1, 1e-9));
        expect(BrandGlyphPainter.ridesKnockout(lockup), [
          isTrue,
          ...List.filled(lockup.strokes.length - 1, isFalse),
        ]);
      }
    });

    test('a glyph of only shapes presses them in over the whole time', () {
      const glyph = BrandGlyph(shapes: [VerilyGeometry.pin]);
      expect(BrandGlyphPainter.timeline(glyph), [(0.0, 1.0)]);
      expect(BrandGlyphPainter.timeline(const BrandGlyph()), isEmpty);
    });

    test('1 paints the pin, cuts the whole check, and draws the flick', () {
      final calls = _cleanMark(1);
      final names = calls.map((c) => c.invocation.memberName).toList();
      final layer = names.indexOf(#saveLayer);
      final cut = calls.indexWhere(_isCut);
      final restore = names.lastIndexOf(#restore);
      expect(layer, isNot(-1));
      expect(cut, greaterThan(layer));
      // The pin is filled inside the layer, before the cut.
      final fill = calls.indexWhere(
        (c) =>
            c.invocation.memberName == #drawPath &&
            _paint(c).style == PaintingStyle.fill,
      );
      expect(fill, inExclusiveRange(layer, cut));
      expect(
        _path(calls[fill]).getBounds(),
        BrandInkPainter.shapePathOf(VerilyGeometry.pin).getBounds(),
      );
      // The cut is the whole check at the mark weight.
      expect(_paint(calls[cut]).strokeWidth, 42);
      expect(_paint(calls[cut]).strokeCap, StrokeCap.round);
      expect(
        _lengthOf(_path(calls[cut])),
        closeTo(BrandInkPainter.lengthOf(VerilyGeometry.markCheck), 0.5),
      );
      // The layer closes after the cut, and only then is the flick drawn,
      // so nothing but the pin is ever cut.
      final layerEnd = names.indexOf(#restore, cut);
      expect(layerEnd, greaterThan(cut));
      final flick = calls.lastIndexWhere(
        (c) => c.invocation.memberName == #drawPath,
      );
      expect(flick, inExclusiveRange(layerEnd, restore));
      expect(_paint(calls[flick]).blendMode, BlendMode.srcOver);
      expect(
        _paint(calls[flick]).color.toARGB32(),
        VerilyBrandColors.stamp.toARGB32(),
      );
      expect(_paint(calls[flick]).strokeWidth, 42);
      expect(
        _lengthOf(_path(calls[flick])),
        closeTo(BrandInkPainter.lengthOf(VerilyGeometry.markFlick), 0.5),
      );
    });

    test('pressing in, the pin grows from its point and fades up', () {
      final calls = _cleanMark(0.2);
      expect(calls.where(_isCut), isEmpty);
      final layers = calls
          .where((c) => c.invocation.memberName == #saveLayer)
          .toList();
      expect(layers, hasLength(2), reason: 'the cut layer and the press');
      final press = layers.last.invocation.positionalArguments.last as Paint;
      expect(press.color.a, inExclusiveRange(0, 1));
      expect(
        calls.where((c) => c.invocation.memberName == #scale),
        hasLength(2),
      );
      final fills = calls.where((c) => c.invocation.memberName == #drawPath);
      expect(fills, hasLength(1), reason: 'only the pin, no flick yet');
    });

    test('mid-cut, part of the check is cut and the flick waits', () {
      final calls = _cleanMark(0.7);
      final cut = calls.singleWhere(_isCut);
      final full = BrandInkPainter.lengthOf(VerilyGeometry.markCheck);
      final cutLength = _lengthOf(_path(cut));
      expect(cutLength, greaterThan(full * 0.2));
      expect(cutLength, lessThan(full * 0.6));
      final strokes = calls.where(
        (c) =>
            c.invocation.memberName == #drawPath &&
            !_isCut(c) &&
            _paint(c).style == PaintingStyle.stroke,
      );
      expect(strokes, isEmpty);
      // Pressed in completely: no press layer, so only the cut layer.
      expect(
        calls.where((c) => c.invocation.memberName == #saveLayer),
        hasLength(1),
      );
    });

    test('as the cut runs out past the rim, the flick draws on', () {
      final slots = BrandGlyphPainter.timeline(VerilyGeometry.markGlyph);
      final (start, end) = slots[2];
      final calls = _cleanMark((start + end) / 2);
      final flick = calls.lastWhere(
        (c) => c.invocation.memberName == #drawPath && !_isCut(c),
      );
      expect(
        _lengthOf(_path(flick)),
        closeTo(BrandInkPainter.lengthOf(VerilyGeometry.markFlick) / 2, 0.5),
      );
    });

    test('a heavier pen widens the cut and the flick, not the pin', () {
      final calls = _cleanMark(1, width: 54);
      expect(_paint(calls.singleWhere(_isCut)).strokeWidth, 54);
      final flick = calls.lastWhere(
        (c) => c.invocation.memberName == #drawPath && !_isCut(c),
      );
      expect(_paint(flick).strokeWidth, 54);
      final fill = calls.firstWhere(
        (c) => c.invocation.memberName == #drawPath,
      );
      expect(
        _path(fill).getBounds(),
        BrandInkPainter.shapePathOf(VerilyGeometry.pin).getBounds(),
      );
    });

    test('the rough hand cuts with the mark pen and inks more over time', () {
      final quarter = _ink(VerilyMarkPainter(progress: .25), size);
      final whole = _ink(VerilyMarkPainter(), size);
      expect(quarter, isNotEmpty);
      expect(whole.where(_isCut), isNotEmpty);
      expect(quarter.where(_isCut), isEmpty);
      expect(whole.length, greaterThan(quarter.length));
    });

    test('the same seed always draws the same mark', () {
      Rect bounds(int seed) => _ink(VerilyMarkPainter(seed: seed), size)
          .map(_path)
          .map((path) => path.getBounds())
          .reduce((a, b) => a.expandToInclude(b));
      expect(bounds(5), bounds(5));
      expect(bounds(5), isNot(bounds(6)));
    });

    test('a lockup cuts its mark, never the word', () {
      final calls = _calls(
        BrandGlyphPainter(
          glyph: VerilyGeometry.horizontalLockup,
          box: VerilyGeometry.horizontalLockupBox,
          accentColor: VerilyBrandColors.stamp,
          bodyColor: VerilyBrandColors.ink,
          rough: false,
        ),
        const Size(600, 200),
      );
      final names = calls.map((c) => c.invocation.memberName).toList();
      final cut = calls.indexWhere(_isCut);
      final layerEnd = names.indexOf(#restore, cut);
      expect(names.indexOf(#saveLayer), lessThan(cut));
      final body = [
        for (final (index, call) in calls.indexed)
          if (call.invocation.memberName == #drawPath &&
              !_isCut(call) &&
              _paint(call).color.toARGB32() == VerilyBrandColors.ink.toARGB32())
            index,
      ];
      expect(body, hasLength(VerilyGeometry.erily.length));
      expect(body, everyElement(greaterThan(layerEnd)));
    });
  });

  group('the knockout is transparent', () {
    Future<ByteData> render(WidgetTester tester, Widget child) async {
      tester.view
        ..physicalSize = const Size.square(VerilyGeometry.markArtboard)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: key,
            child: ColoredBox(color: VerilyBrandColors.place, child: child),
          ),
        ),
      );
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      return (await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData();
        image.dispose();
        return bytes!;
      }))!;
    }

    /// The pixel at ([x], [y]) as 0xAARRGGBB.
    int pixel(ByteData bytes, int x, int y) {
      final i = (y * VerilyGeometry.markArtboard.toInt() + x) * 4;
      return bytes.getUint8(i + 3) << 24 |
          bytes.getUint8(i) << 16 |
          bytes.getUint8(i + 1) << 8 |
          bytes.getUint8(i + 2);
    }

    void expectColor(int actual, Color expected, String where) {
      expect(
        actual.toRadixString(16),
        expected.toARGB32().toRadixString(16),
        reason: where,
      );
    }

    for (final rough in [true, false]) {
      testWidgets('over any background (rough: $rough)', (tester) async {
        final bytes = await render(
          tester,
          VerilyMark(size: VerilyGeometry.markArtboard, rough: rough),
        );
        // The background shows through the cut, fully opaque: the cut went
        // through the pin only, not through what is behind the mark.
        expectColor(pixel(bytes, 220, 292), VerilyBrandColors.place, 'vertex');
        expectColor(pixel(bytes, 300, 194), VerilyBrandColors.place, 'arm');
        // The pin and the flick are vermilion.
        expectColor(pixel(bytes, 240, 420), VerilyBrandColors.stamp, 'pin');
        expectColor(pixel(bytes, 130, 200), VerilyBrandColors.stamp, 'head');
        expectColor(pixel(bytes, 400, 72), VerilyBrandColors.stamp, 'flick');
        // The gap between the rim and the flick is open.
        expectColor(pixel(bytes, 362, 118), VerilyBrandColors.place, 'gap');
      });
    }
  });

  group('widgets render', () {
    testWidgets('the mark at every size and progress', (tester) async {
      for (final size in [24.0, 48.0, 96.0, 320.0]) {
        for (final progress in [0.0, .2, .5, .7, .9, 1.0]) {
          for (final rough in [true, false]) {
            await tester.pumpWidget(
              _onPaper(
                VerilyMark(size: size, progress: progress, rough: rough),
              ),
            );
            expect(tester.takeException(), isNull);
          }
        }
      }
      expect(find.bySemanticsLabel('Verily'), findsOneWidget);
    });

    testWidgets('decorative marks stay out of the semantics tree', (
      tester,
    ) async {
      await tester.pumpWidget(
        _onPaper(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VerilyMark(semanticLabel: null),
              VerilyWordmark(semanticLabel: null),
              VerilyLockup(semanticLabel: null),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('Verily'), findsNothing);
      expect(find.byType(ExcludeSemantics), findsAtLeastNWidgets(3));
      expect(const BrandPoint(1, 2.5).toString(), 'BrandPoint(1.0, 2.5)');
    });

    test('small marks get a wider cut and flick', () {
      expect(VerilyMark.weightFor(16), VerilyGeometry.smallWeight);
      expect(VerilyMark.weightFor(24), VerilyGeometry.smallWeight);
      expect(VerilyMark.weightFor(32), VerilyGeometry.smallWeight);
      expect(VerilyMark.weightFor(48), closeTo(48, 1e-9));
      expect(VerilyMark.weightFor(64), VerilyGeometry.markWeight);
      expect(VerilyMark.weightFor(96), VerilyGeometry.markWeight);
    });

    testWidgets('the mark passes its weight to the painter', (tester) async {
      await tester.pumpWidget(_onPaper(const VerilyMark(size: 24)));
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(VerilyMark),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as BrandGlyphPainter;
      expect(painter.weight, closeTo(54 / 42, 1e-9));
      expect(painter.glyph, same(VerilyGeometry.markGlyph));
      expect(painter.shouldRepaint(VerilyMarkPainter()), isTrue);
      expect(
        VerilyMarkPainter().shouldRepaint(VerilyMarkPainter()),
        isFalse,
      );
    });

    testWidgets('the wordmark and the lockups', (tester) async {
      for (final progress in [0.0, .2, .5, .95, 1.0]) {
        await tester.pumpWidget(
          _onPaper(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                VerilyWordmark(height: 60, progress: progress),
                VerilyLockup(height: 60, progress: progress),
                VerilyLockup(
                  height: 120,
                  layout: VerilyLockupLayout.stacked,
                  progress: progress,
                  rough: false,
                ),
              ],
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      }
      final size = tester.getSize(find.byType(VerilyWordmark));
      expect(size.width, closeTo(VerilyWordmark.widthFor(60), .01));
    });

    testWidgets('the stamp through its slam', (tester) async {
      for (final pressed in [0.0, .2, .49, .5, .6, .8, 1.0]) {
        await tester.pumpWidget(
          _onPaper(VerifiedStamp(size: 120, pressed: pressed)),
        );
        expect(tester.takeException(), isNull);
      }
      expect(find.bySemanticsLabel('Verified'), findsOneWidget);
      await tester.pumpWidget(_onPaper(const VerifiedStamp(pressed: .3)));
      expect(find.bySemanticsLabel('Verified'), findsNothing);
    });
  });

  group('reduced motion', () {
    Widget still(Widget child) => MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: _onPaper(child),
    );

    CustomPainter painterOf(WidgetTester tester, Type type) => tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byType(type),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter!;

    testWidgets('draws the marks complete', (tester) async {
      await tester.pumpWidget(still(const VerilyMark(progress: 0)));
      expect(
        (painterOf(tester, VerilyMark) as BrandGlyphPainter).progress,
        1,
      );
      await tester.pumpWidget(still(const VerilyWordmark(progress: .2)));
      expect(
        (painterOf(tester, VerilyWordmark) as BrandGlyphPainter).progress,
        1,
      );
      await tester.pumpWidget(still(const VerilyLockup(progress: .4)));
      expect(
        (painterOf(tester, VerilyLockup) as BrandGlyphPainter).progress,
        1,
      );
    });

    testWidgets('skips the stamp slam', (tester) async {
      await tester.pumpWidget(still(const VerifiedStamp(pressed: .3)));
      expect(
        (painterOf(tester, VerifiedStamp) as VerifiedStampPainter).pressed,
        0,
      );
      await tester.pumpWidget(still(const VerifiedStamp(pressed: .6)));
      expect(
        (painterOf(tester, VerifiedStamp) as VerifiedStampPainter).pressed,
        1,
      );
    });
  });
}
