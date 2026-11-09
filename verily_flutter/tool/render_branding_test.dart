// Renders the launcher and splash images the app ships, from the brand
// geometry in package:verily_brand, so they can never drift from the mark.
//
//   flutter test tool/render_branding_test.dart \
//     --dart-define=BRANDING_OUT=assets/branding
//
// Then regenerate the platform files:
//
//   dart run flutter_launcher_icons
//   dart run flutter_native_splash:create
//
// The launcher icon's full-bleed source is brand/verily-app-icon.png itself.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verily_brand/verily_brand.dart';

const String _out = String.fromEnvironment('BRANDING_OUT');

/// Paints [mark] (laid out on a [artboard] square) in [color], clean,
/// centred in the canvas at [scale] of its side. The mark's cut check is
/// transparent, so the launcher or splash background shows through it.
class _MarkPainter extends CustomPainter {
  const _MarkPainter({
    required this.mark,
    required this.artboard,
    required this.color,
    this.scale = 1,
  });

  final BrandGlyph mark;
  final double artboard;
  final Color color;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide * scale;
    canvas.translate((size.width - side) / 2, (size.height - side) / 2);
    BrandGlyphPainter(
      glyph: mark,
      box: BrandBox(0, 0, artboard, artboard),
      accentColor: color,
      bodyColor: color,
      rough: false,
    ).paint(canvas, Size.square(side));
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => false;
}

Future<void> _render(
  WidgetTester tester, {
  required String name,
  required double side,
  required CustomPainter painter,
}) async {
  tester.view
    ..physicalSize = Size.square(side)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final key = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: CustomPaint(size: Size.square(side), painter: painter),
    ),
  );
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    await File('$_out/$name').writeAsBytes(png!.buffer.asUint8List());
  });
}

void main() {
  setUp(() {
    if (_out.isEmpty) {
      markTestSkipped('Set --dart-define=BRANDING_OUT=<dir> to render.');
    }
  });

  testWidgets('adaptive icon foreground and monochrome layer', (tester) async {
    if (_out.isEmpty) return;
    // 108 dp at xxxhdpi. The mark already sits inside the 66 dp safe circle.
    await _render(
      tester,
      name: 'launcher_foreground.png',
      side: 432,
      painter: _MarkPainter(
        mark: VerilyGeometry.adaptiveIconMark,
        artboard: VerilyGeometry.adaptiveIconArtboard,
        color: VerilyBrandColors.paper,
      ),
    );
  });

  testWidgets('splash marks for paper and night', (tester) async {
    if (_out.isEmpty) return;
    // The splash images are treated as 4x: a 96 dp mark, with the same
    // proportions as the app icon's mark.
    for (final (name, color) in [
      ('splash_mark.png', VerilyBrandColors.stamp),
      ('splash_mark_dark.png', VerilyBrandColors.stampOnNight),
    ]) {
      await _render(
        tester,
        name: name,
        side: 384,
        painter: _MarkPainter(
          mark: VerilyGeometry.appIconMark,
          artboard: VerilyGeometry.appIconArtboard,
          color: color,
        ),
      );
    }
  });

  testWidgets('Android 12 splash icons', (tester) async {
    if (_out.isEmpty) return;
    // Android 12 shows the splash icon in a 640 px circle of a 960 px square.
    for (final (name, color) in [
      ('splash_android12.png', VerilyBrandColors.stamp),
      ('splash_android12_dark.png', VerilyBrandColors.stampOnNight),
    ]) {
      await _render(
        tester,
        name: name,
        side: 960,
        painter: _MarkPainter(
          mark: VerilyGeometry.appIconMark,
          artboard: VerilyGeometry.appIconArtboard,
          color: color,
          scale: 0.62,
        ),
      );
    }
  });
}
