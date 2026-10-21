import 'dart:ui' show Color;

import 'package:verily_brand/src/colors.dart';
import 'package:verily_brand/src/geometry.dart';
import 'package:verily_brand/src/lockup.dart';

/// Writes the brand's vector files from [VerilyGeometry].
///
/// Exports are clean single-stroke vectors with round caps and joins: no
/// seeded wobble, so the logo stays crisp at every size. The painters draw the
/// same centrelines.
abstract final class VerilySvg {
  /// Every brand file, by file name.
  static Map<String, String> files() => {
    'verily-mark.svg': mark(),
    'verily-mark-mono.svg': mark(color: null),
    'verily-mark-dark.svg': mark(color: VerilyBrandColors.stampOnNight),
    'verily-mark-small.svg': mark(weight: VerilyGeometry.smallWeight),
    'verily-wordmark.svg': wordmark(),
    'verily-lockup-horizontal.svg': lockup(VerilyLockupLayout.horizontal),
    'verily-lockup-stacked.svg': lockup(VerilyLockupLayout.stacked),
    'verily-app-icon.svg': appIcon(),
    'verily-app-icon-foreground.svg': appIconForeground(),
  };

  /// The pin-check on its square artboard, in [color] at [weight] artboard
  /// units. A null [color] inks with `currentColor`, for single-colour use.
  static String mark({
    Color? color = VerilyBrandColors.stamp,
    double weight = VerilyGeometry.markWeight,
  }) {
    final stroke = VerilyGeometry.mark.withWidth(weight);
    return _svg(
      VerilyGeometry.markBox,
      title: 'Verily',
      body: _path(stroke, color == null ? 'currentColor' : hex(color)),
    );
  }

  /// The ✓erily wordmark for light paper.
  static String wordmark() => _svg(
    VerilyGeometry.wordmarkBox.inflate(8),
    title: 'Verily',
    body: _glyph(VerilyGeometry.wordmark),
  );

  /// The lockup in [layout] for light paper.
  static String lockup(VerilyLockupLayout layout) => _svg(
    VerilyLockup.boxOf(layout).inflate(8),
    title: 'Verily',
    body: _glyph(VerilyLockup.glyphOf(layout)),
  );

  /// The app icon preview: the paper pin-check on a vermilion rounded square.
  static String appIcon() {
    const side = VerilyGeometry.appIconArtboard;
    final background =
        '<rect width="${svgNumber(side)}" height="${svgNumber(side)}" '
        'rx="${svgNumber(VerilyGeometry.appIconCornerRadius)}" '
        'fill="${hex(VerilyBrandColors.stamp)}"/>';
    return _svg(
      const BrandBox(0, 0, side, side),
      title: 'Verily',
      body:
          '$background\n'
          '  ${_path(VerilyGeometry.appIconMark, hex(VerilyBrandColors.paper))}',
    );
  }

  /// The Android adaptive icon's foreground layer on a 108 dp artboard, with
  /// the whole mark inside the 66 dp safe circle. Its background layer is
  /// solid [VerilyBrandColors.stamp].
  static String appIconForeground() {
    const side = VerilyGeometry.adaptiveIconArtboard;
    return _svg(
      const BrandBox(0, 0, side, side),
      title: 'Verily',
      body: _path(
        VerilyGeometry.adaptiveIconMark,
        hex(VerilyBrandColors.paper),
      ),
    );
  }

  /// [color] as an SVG hex colour, such as `#D13F22`.
  static String hex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  static String _glyph(BrandGlyph glyph) {
    final body = StringBuffer();
    for (final stroke in glyph.strokes) {
      body.writeln(
        '  ${_path(stroke, hex(VerilyBrandColors.onPaper(stroke.ink)))}',
      );
    }
    for (final dot in glyph.dots) {
      body.writeln(
        '  <circle cx="${svgNumber(dot.center.x)}" cy="${svgNumber(dot.center.y)}" '
        'r="${svgNumber(dot.radius)}" '
        'fill="${hex(VerilyBrandColors.onPaper(dot.ink))}"/>',
      );
    }
    return body.toString().trimRight();
  }

  static String _path(BrandStroke stroke, String color) =>
      '<path d="${stroke.pathData}" fill="none" stroke="$color" '
      'stroke-width="${svgNumber(stroke.width)}" stroke-linecap="round" '
      'stroke-linejoin="round"/>';

  static String _svg(
    BrandBox box, {
    required String title,
    required String body,
  }) {
    final width = svgNumber(box.width);
    final height = svgNumber(box.height);
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="${box.viewBox}" '
        'width="$width" height="$height" role="img" aria-label="$title">\n'
        '  <title>$title</title>\n'
        '  ${body.trimLeft()}\n'
        '</svg>\n';
  }
}
