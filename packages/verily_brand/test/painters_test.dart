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

List<RecordedInvocation> _ink(CustomPainter painter, Size size) {
  final canvas = TestRecordingCanvas();
  painter.paint(canvas, size);
  return [
    for (final call in canvas.invocations)
      if (_inking.contains(call.invocation.memberName)) call,
  ];
}

double _lengthOf(Path path) =>
    path.computeMetrics().fold(0, (sum, metric) => sum + metric.length);

Widget _onPaper(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: ColoredBox(
    color: VerilyBrandColors.paper,
    child: Center(child: child),
  ),
);

void main() {
  group('draw-on progress', () {
    const size = Size.square(200);

    for (final rough in [true, false]) {
      test('0 paints nothing (rough: $rough)', () {
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

    test('1 paints the whole stroke', () {
      final calls = _ink(VerilyMarkPainter(rough: false), size);
      final path = calls.single.invocation.positionalArguments.first as Path;
      expect(
        _lengthOf(path),
        closeTo(BrandInkPainter.lengthOf(VerilyGeometry.mark), 1),
      );
    });

    test('a half paints half the stroke, from its start', () {
      final calls = _ink(VerilyMarkPainter(progress: .5, rough: false), size);
      final path = calls.single.invocation.positionalArguments.first as Path;
      final full = BrandInkPainter.lengthOf(VerilyGeometry.mark);
      expect(_lengthOf(path), closeTo(full / 2, 1));
      final start = path
          .computeMetrics()
          .first
          .getTangentForOffset(0)!
          .position;
      expect(start.dx, closeTo(VerilyGeometry.mark.start.x, .01));
      expect(start.dy, closeTo(VerilyGeometry.mark.start.y, .01));
    });

    test('the rough hand inks more as progress grows', () {
      final quarter = _ink(VerilyMarkPainter(progress: .25), size);
      final whole = _ink(VerilyMarkPainter(), size);
      expect(quarter, isNotEmpty);
      double area(List<RecordedInvocation> calls) => calls
          .map((c) => c.invocation.positionalArguments.first)
          .whereType<Path>()
          .fold(
            0,
            (sum, path) =>
                sum + path.getBounds().width * path.getBounds().height,
          );
      expect(area(whole), greaterThan(area(quarter)));
    });

    test('the same seed always draws the same line', () {
      Rect bounds() => _ink(VerilyMarkPainter(seed: 5), size)
          .map((c) => c.invocation.positionalArguments.first)
          .whereType<Path>()
          .map((path) => path.getBounds())
          .reduce((a, b) => a.expandToInclude(b));
      expect(bounds(), bounds());
    });

    test('the wordmark dots its i last', () {
      final slots = BrandGlyphPainter.timeline(VerilyGeometry.wordmark);
      expect(slots, hasLength(VerilyGeometry.wordmark.strokes.length + 1));
      expect(slots.last.$2, closeTo(1, 1e-9));
      for (var i = 1; i < slots.length; i++) {
        expect(slots[i].$1, greaterThanOrEqualTo(slots[i - 1].$2));
      }
    });
  });

  group('widgets render', () {
    testWidgets('the mark at every size and progress', (tester) async {
      for (final size in [24.0, 48.0, 96.0, 320.0]) {
        for (final progress in [0.0, .3, .7, 1.0]) {
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
      expect(VerilyMark.weightFor(24), VerilyGeometry.smallWeight);
      expect(VerilyMark.weightFor(96), VerilyGeometry.markWeight);
      expect(find.bySemanticsLabel('Verily'), findsOneWidget);
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
