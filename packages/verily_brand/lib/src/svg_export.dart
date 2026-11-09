import 'dart:ui' show Color;

import 'package:verily_brand/src/colors.dart';
import 'package:verily_brand/src/geometry.dart';
import 'package:verily_brand/src/lockup.dart';

/// Writes the brand's vector files from [VerilyGeometry].
///
/// Exports are clean vectors: shapes are filled paths, strokes are single
/// round-capped, round-joined paths, and knockouts are an SVG `<mask>` that
/// cuts only the shapes, so the background shows through the cut. There is no
/// seeded wobble, so the logo stays crisp at every size. The painters draw
/// the same geometry.
///
/// Each file's mask has an id of its own (`<file name>-knockout`), so several
/// files can be inlined into one page without their masks colliding.
abstract final class VerilySvg {
  /// Every brand file, by file name.
  static Map<String, String> files() => {
    'verily-mark.svg': mark(),
    'verily-mark-mono.svg': mark(color: null, id: 'verily-mark-mono'),
    'verily-mark-dark.svg': mark(
      color: VerilyBrandColors.stampOnNight,
      id: 'verily-mark-dark',
    ),
    'verily-mark-small.svg': mark(
      weight: VerilyGeometry.smallWeight,
      id: 'verily-mark-small',
    ),
    'verily-wordmark.svg': wordmark(),
    'verily-lockup-horizontal.svg': lockup(VerilyLockupLayout.horizontal),
    'verily-lockup-stacked.svg': lockup(VerilyLockupLayout.stacked),
    'verily-app-icon.svg': appIcon(),
    'verily-app-icon-foreground.svg': appIconForeground(),
  };

  /// The pin-check on its square artboard, in [color], its check and flick
  /// [weight] artboard units wide. A null [color] inks with `currentColor`,
  /// for single-colour use. [id] names the file's knockout mask.
  static String mark({
    Color? color = VerilyBrandColors.stamp,
    double weight = VerilyGeometry.markWeight,
    String id = 'verily-mark',
  }) => _svg(
    VerilyGeometry.markBox,
    title: 'Verily',
    body: _glyph(
      VerilyGeometry.markGlyph.withPenWidth(weight),
      id: id,
      inkOf: (_) => color == null ? 'currentColor' : hex(color),
    ),
  );

  /// The ✓erily wordmark for light paper.
  static String wordmark() => _svg(
    VerilyGeometry.wordmarkBox.inflate(8),
    title: 'Verily',
    body: _glyph(VerilyGeometry.wordmark, id: 'verily-wordmark'),
  );

  /// The lockup in [layout] for light paper.
  static String lockup(VerilyLockupLayout layout) => _svg(
    VerilyLockup.boxOf(layout).inflate(8),
    title: 'Verily',
    body: _glyph(
      VerilyLockup.glyphOf(layout),
      id: switch (layout) {
        VerilyLockupLayout.horizontal => 'verily-lockup-horizontal',
        VerilyLockupLayout.stacked => 'verily-lockup-stacked',
      },
    ),
  );

  /// The app icon preview: the paper pin-check on a vermilion rounded square.
  /// The check is cut through the pin, so the vermilion shows through it.
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
          '${_glyph(VerilyGeometry.appIconMark, id: 'verily-app-icon', inkOf: _paper)}',
    );
  }

  /// The Android adaptive icon's foreground layer on a 108 dp artboard, with
  /// the whole mark inside the 66 dp safe circle. Its background layer is
  /// solid [VerilyBrandColors.stamp], which shows through the cut check.
  static String appIconForeground() {
    const side = VerilyGeometry.adaptiveIconArtboard;
    return _svg(
      const BrandBox(0, 0, side, side),
      title: 'Verily',
      body: _glyph(
        VerilyGeometry.adaptiveIconMark,
        id: 'verily-app-icon-foreground',
        inkOf: _paper,
      ),
    );
  }

  /// [color] as an SVG hex colour, such as `#D13F22`.
  static String hex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  static String _paper(BrandInk ink) => hex(VerilyBrandColors.paper);

  static String _onPaper(BrandInk ink) => hex(VerilyBrandColors.onPaper(ink));

  /// [glyph] as SVG elements: a knockout mask (named `<id>-knockout`) when it
  /// has knockouts, the shapes, each cut by it, then the strokes and dots,
  /// which the mask never touches. [inkOf]
  /// gives each part's colour.
  static String _glyph(
    BrandGlyph glyph, {
    required String id,
    String Function(BrandInk ink) inkOf = _onPaper,
  }) {
    final body = StringBuffer();
    final maskId = '$id-knockout';
    final cut = glyph.knockouts.isNotEmpty && glyph.shapes.isNotEmpty;
    if (cut) {
      // The mask covers the shapes with room for any rounding, in the same
      // units as the paths, so it never depends on a shape's own box.
      final shapes = BrandGlyph(shapes: glyph.shapes).inkBounds;
      final area = shapes.inflate(shapes.height * 0.05);
      final region =
          'x="${svgNumber(area.left)}" y="${svgNumber(area.top)}" '
          'width="${svgNumber(area.width)}" height="${svgNumber(area.height)}"';
      body
        ..writeln('  <defs>')
        ..writeln(
          '    <mask id="$maskId" maskUnits="userSpaceOnUse" $region>',
        )
        ..writeln('      <rect $region fill="white"/>');
      for (final knockout in glyph.knockouts) {
        body.writeln('      ${_stroke(knockout, 'black')}');
      }
      body
        ..writeln('    </mask>')
        ..writeln('  </defs>');
    }
    final mask = cut ? ' mask="url(#$maskId)"' : '';
    for (final shape in glyph.shapes) {
      body.writeln(
        '  <path d="${shape.pathData}" fill="${inkOf(shape.ink)}"$mask/>',
      );
    }
    for (final stroke in glyph.strokes) {
      body.writeln('  ${_stroke(stroke, inkOf(stroke.ink))}');
    }
    for (final dot in glyph.dots) {
      body.writeln(
        '  <circle cx="${svgNumber(dot.center.x)}" cy="${svgNumber(dot.center.y)}" '
        'r="${svgNumber(dot.radius)}" fill="${inkOf(dot.ink)}"/>',
      );
    }
    return body.toString().trimRight();
  }

  static String _stroke(BrandStroke stroke, String color) =>
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
