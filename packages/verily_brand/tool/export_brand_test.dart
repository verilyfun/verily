// Writes Verily's brand files from the brand geometry, and renders a review
// sheet of the logo at every size that matters.
//
//   flutter test tool/export_brand_test.dart \
//     --dart-define=BRAND_OUT=../../brand \
//     --dart-define=SPECIMEN_OUT=../../.screenshots/brand
//
// BRAND_OUT receives the committed SVG files and the 1024 px launcher icon.
// SPECIMEN_OUT receives review PNGs (never commit those).
import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verily_brand/verily_brand.dart';

import 'support/render_support.dart';

const String _brandOut = String.fromEnvironment('BRAND_OUT');
const String _specimenOut = String.fromEnvironment('SPECIMEN_OUT');

void main() {
  test('export the brand vector files', () {
    if (_brandOut.isEmpty) {
      markTestSkipped('Set --dart-define=BRAND_OUT=<dir> to export.');
      return;
    }
    for (final MapEntry(key: name, value: svg) in VerilySvg.files().entries) {
      File('$_brandOut/$name')
        ..createSync(recursive: true)
        ..writeAsStringSync(svg);
    }
  });

  testWidgets('render the launcher icon', (tester) async {
    if (_brandOut.isEmpty) {
      markTestSkipped('Set --dart-define=BRAND_OUT=<dir> to export.');
      return;
    }
    const side = VerilyGeometry.appIconArtboard;
    tester.view
      ..physicalSize = const Size.square(side)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: CustomPaint(
          size: const Size.square(side),
          painter: _LauncherIconPainter(),
        ),
      ),
    );
    await capturePng(
      tester,
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary,
      '$_brandOut/verily-app-icon.png',
      opaque: true,
    );
  });

  testWidgets('render the brand specimen', (tester) async {
    if (_specimenOut.isEmpty) {
      markTestSkipped('Set --dart-define=SPECIMEN_OUT=<dir> to render.');
      return;
    }
    tester.view
      ..physicalSize = const Size(1600, 1500)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const _Specimen());
    await captureView(tester, '$_specimenOut/specimen.png');

    tester.view.physicalSize = const Size.square(1024);
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: ColoredBox(
          color: VerilyBrandColors.paper,
          child: Center(child: VerilyMark(size: 1024)),
        ),
      ),
    );
    await captureView(tester, '$_specimenOut/mark-1024.png');

    for (final size in [96.0, 48.0, 24.0]) {
      tester.view.physicalSize = Size(size * 4 + 40, size + 16);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ColoredBox(
            color: VerilyBrandColors.paper,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VerilyMark(size: size),
                  const SizedBox(width: 8),
                  VerilyMark(size: size, rough: false),
                  const SizedBox(width: 8),
                  _Icon(size: size),
                  const SizedBox(width: 8),
                  ColoredBox(
                    color: VerilyBrandColors.night,
                    child: VerilyMark(
                      size: size,
                      color: VerilyBrandColors.stampOnNight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await captureView(tester, '$_specimenOut/mark-${size.round()}.png');
    }
  });
}

/// The launcher icon: full-bleed vermilion with the paper pin-check. Every
/// launcher applies its own mask, so the square has no corners of its own.
class _LauncherIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / VerilyGeometry.appIconArtboard;
    canvas
      ..drawRect(Offset.zero & size, Paint()..color = VerilyBrandColors.stamp)
      ..scale(scale);
    BrandInkPainter.paint(
      canvas,
      VerilyGeometry.appIconMark,
      color: VerilyBrandColors.paper,
      rough: false,
    );
  }

  @override
  bool shouldRepaint(_LauncherIconPainter oldDelegate) => false;
}

/// The app icon preview: rounded vermilion square, paper mark.
class _Icon extends StatelessWidget {
  const _Icon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(
      size *
          VerilyGeometry.appIconCornerRadius /
          VerilyGeometry.appIconArtboard,
    ),
    child: CustomPaint(
      size: Size.square(size),
      painter: _LauncherIconPainter(),
    ),
  );
}

class _Specimen extends StatelessWidget {
  const _Specimen();

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: ColoredBox(
      color: VerilyBrandColors.paper,
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                VerilyMark(size: 300),
                SizedBox(width: 40),
                VerilyMark(size: 300, rough: false),
                SizedBox(width: 40),
                VerifiedStamp(size: 300),
                SizedBox(width: 40),
                VerifiedStamp(size: 300, rough: false),
              ],
            ),
            const SizedBox(height: 30),
            const Row(
              children: [
                VerilyWordmark(height: 180),
                SizedBox(width: 40),
                VerilyWordmark(height: 180, rough: false),
              ],
            ),
            const SizedBox(height: 30),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                VerilyLockup(height: 150),
                SizedBox(width: 60),
                VerilyLockup(height: 300, layout: VerilyLockupLayout.stacked),
              ],
            ),
            const SizedBox(height: 30),
            ColoredBox(
              color: VerilyBrandColors.night,
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const VerilyLockup(
                      height: 140,
                      accentColor: VerilyBrandColors.stampOnNight,
                      inkColor: VerilyBrandColors.paper,
                    ),
                    const SizedBox(width: 40),
                    const VerifiedStamp(
                      size: 160,
                      color: VerilyBrandColors.stampOnNight,
                    ),
                    const SizedBox(width: 40),
                    for (final pressed in [0.2, 0.45, 0.55, 0.7, 0.85])
                      Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: VerifiedStamp(
                          size: 90,
                          pressed: pressed,
                          color: VerilyBrandColors.stampOnNight,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
