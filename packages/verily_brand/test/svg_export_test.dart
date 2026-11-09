import 'package:flutter_test/flutter_test.dart';
import 'package:verily_brand/verily_brand.dart';
import 'package:xml/xml.dart';

XmlElement _parse(String svg) => XmlDocument.parse(svg).rootElement;

const String _pin =
    'M 240 486 C 240 486 90 330.56 90 218 C 90 135.15 157.15 68 240 68 '
    'C 322.85 68 390 135.15 390 218 C 390 330.56 240 486 240 486 Z';
const String _check = 'M 162 230 L 220 292 L 457.3 2.5';
const String _flick = 'M 380.7 95.9 L 420 48';

/// The elements drawn on the page, outside `<defs>`.
Iterable<XmlElement> _drawn(XmlElement root, String name) => root
    .findAllElements(name)
    .where((e) => e.ancestorElements.every((a) => a.name.local != 'defs'));

/// The checks every masked file shares: one mask, its white field, the cut
/// in black, and the single shape it masks.
({XmlElement mask, XmlElement cut, XmlElement shape}) _masked(
  XmlElement root,
  String id,
) {
  final mask = root.findAllElements('mask').single;
  expect(mask.getAttribute('id'), id);
  expect(mask.getAttribute('maskUnits'), 'userSpaceOnUse');
  expect(mask.findElements('rect').single.getAttribute('fill'), 'white');
  final cut = mask.findElements('path').single;
  expect(cut.getAttribute('stroke'), 'black');
  expect(cut.getAttribute('fill'), 'none');
  expect(cut.getAttribute('stroke-linecap'), 'round');
  expect(cut.getAttribute('stroke-linejoin'), 'round');
  final shapes = _drawn(
    root,
    'path',
  ).where((p) => p.getAttribute('mask') != null).toList();
  expect(shapes, hasLength(1));
  expect(shapes.single.getAttribute('mask'), 'url(#$id)');
  return (mask: mask, cut: cut, shape: shapes.single);
}

void main() {
  test('every exported file is an SVG with a viewBox and a title', () {
    final files = VerilySvg.files();
    expect(
      files.keys,
      containsAll(<String>[
        'verily-mark.svg',
        'verily-mark-mono.svg',
        'verily-mark-dark.svg',
        'verily-mark-small.svg',
        'verily-wordmark.svg',
        'verily-lockup-horizontal.svg',
        'verily-lockup-stacked.svg',
        'verily-app-icon.svg',
        'verily-app-icon-foreground.svg',
      ]),
    );
    for (final MapEntry(key: name, value: svg) in files.entries) {
      final root = _parse(svg);
      expect(root.name.local, 'svg', reason: name);
      expect(root.getAttribute('viewBox'), isNotNull, reason: name);
      expect(root.findElements('title').single.innerText, 'Verily');
    }
  });

  test('every mask id is unique and every reference resolves', () {
    final ids = <String>[];
    for (final MapEntry(key: name, value: svg) in VerilySvg.files().entries) {
      final root = _parse(svg);
      final defined = {
        for (final mask in root.findAllElements('mask'))
          mask.getAttribute('id')!,
      };
      ids.addAll(defined);
      for (final element in root.descendantElements) {
        final mask = element.getAttribute('mask');
        if (mask == null) continue;
        final id = RegExp(r'^url\(#(.+)\)$').firstMatch(mask)!.group(1);
        expect(defined, contains(id), reason: name);
      }
      if (name != 'verily-wordmark.svg') {
        expect(defined, {'${name.replaceAll('.svg', '')}-knockout'});
      }
    }
    expect(ids.toSet(), hasLength(ids.length));
    expect(ids, hasLength(VerilySvg.files().length - 1));
  });

  test('the mark is the pin cut by the check, then the flick', () {
    final root = _parse(VerilySvg.mark());
    final (:mask, :cut, :shape) = _masked(root, 'verily-mark-knockout');
    expect(cut.getAttribute('d'), _check);
    expect(cut.getAttribute('d'), VerilyGeometry.markCheck.pathData);
    expect(cut.getAttribute('stroke-width'), '42');
    expect(shape.getAttribute('d'), _pin);
    expect(shape.getAttribute('d'), VerilyGeometry.pin.pathData);
    expect(shape.getAttribute('fill'), '#D13F22');
    expect(shape.getAttribute('stroke'), isNull);
    // The mask covers the whole pin.
    final x = double.parse(mask.getAttribute('x')!);
    final y = double.parse(mask.getAttribute('y')!);
    final width = double.parse(mask.getAttribute('width')!);
    final height = double.parse(mask.getAttribute('height')!);
    expect(x, lessThan(90));
    expect(y, lessThan(68));
    expect(x + width, greaterThan(390));
    expect(y + height, greaterThan(486));
    final flick = _drawn(
      root,
      'path',
    ).singleWhere((p) => p.getAttribute('mask') == null);
    expect(flick.getAttribute('d'), _flick);
    expect(flick.getAttribute('stroke'), '#D13F22');
    expect(flick.getAttribute('fill'), 'none');
    expect(flick.getAttribute('stroke-width'), '42');
    expect(flick.getAttribute('stroke-linecap'), 'round');
    // The flick is drawn after the pin, over it.
    final drawn = _drawn(root, 'path').toList();
    expect(drawn.indexOf(flick), greaterThan(drawn.indexOf(shape)));
  });

  test('the mono mark inks with currentColor', () {
    final root = _parse(VerilySvg.mark(color: null, id: 'verily-mark-mono'));
    final (mask: _, :cut, :shape) = _masked(root, 'verily-mark-mono-knockout');
    expect(shape.getAttribute('fill'), 'currentColor');
    expect(cut.getAttribute('stroke'), 'black');
    final flick = _drawn(
      root,
      'path',
    ).singleWhere((p) => p.getAttribute('mask') == null);
    expect(flick.getAttribute('stroke'), 'currentColor');
    expect(root.toXmlString(), isNot(contains(RegExp('#[0-9A-Fa-f]{6}'))));
  });

  test('the dark mark inks in night vermilion', () {
    final root = _parse(VerilySvg.files()['verily-mark-dark.svg']!);
    final (mask: _, cut: _, :shape) = _masked(
      root,
      'verily-mark-dark-knockout',
    );
    expect(shape.getAttribute('fill'), '#F2856A');
    expect(
      _drawn(root, 'path').last.getAttribute('stroke'),
      '#F2856A',
    );
  });

  test('the small mark widens the cut and the flick', () {
    final root = _parse(VerilySvg.files()['verily-mark-small.svg']!);
    final (mask: _, :cut, :shape) = _masked(
      root,
      'verily-mark-small-knockout',
    );
    expect(cut.getAttribute('stroke-width'), '54');
    expect(shape.getAttribute('d'), _pin);
    expect(_drawn(root, 'path').last.getAttribute('stroke-width'), '54');
  });

  test('the wordmark has a vermilion check, plum letters, and a dot', () {
    final root = _parse(VerilySvg.wordmark());
    expect(root.findAllElements('mask'), isEmpty);
    expect(root.findAllElements('defs'), isEmpty);
    final paths = root.findAllElements('path').toList();
    expect(paths, hasLength(VerilyGeometry.wordmark.strokes.length));
    expect(paths.first.getAttribute('d'), VerilyGeometry.checkV.pathData);
    expect(paths.first.getAttribute('stroke'), '#D13F22');
    expect(
      paths.skip(1).map((p) => p.getAttribute('stroke')),
      everyElement('#34283F'),
    );
    expect(
      root.findAllElements('circle').single.getAttribute('fill'),
      '#D13F22',
    );
  });

  test('the lockups cut only the mark and carry the whole wordmark', () {
    for (final layout in VerilyLockupLayout.values) {
      final root = _parse(VerilySvg.lockup(layout));
      final id = 'verily-lockup-${layout.name}-knockout';
      final (mask: _, :cut, :shape) = _masked(root, id);
      final glyph = VerilyLockup.glyphOf(layout);
      expect(cut.getAttribute('d'), glyph.knockouts.single.pathData);
      expect(shape.getAttribute('d'), glyph.shapes.single.pathData);
      expect(shape.getAttribute('fill'), '#D13F22');
      final strokes = _drawn(
        root,
        'path',
      ).where((p) => p.getAttribute('mask') == null).toList();
      expect(strokes, hasLength(1 + VerilyGeometry.wordmark.strokes.length));
      expect(strokes.first.getAttribute('d'), glyph.strokes.first.pathData);
      expect(root.findAllElements('circle'), hasLength(1));
    }
  });

  test('the app icon is a paper mark on a vermilion square', () {
    final root = _parse(VerilySvg.appIcon());
    final background = _drawn(root, 'rect').single;
    expect(background.getAttribute('fill'), '#D13F22');
    expect(background.getAttribute('rx'), '228');
    final (mask: _, :cut, :shape) = _masked(root, 'verily-app-icon-knockout');
    expect(shape.getAttribute('fill'), '#FFFAF0');
    expect(
      double.parse(cut.getAttribute('stroke-width')!),
      closeTo(VerilyGeometry.appIconMark.knockouts.single.width, 0.01),
    );
    expect(_drawn(root, 'path').last.getAttribute('stroke'), '#FFFAF0');

    final foreground = _parse(VerilySvg.appIconForeground());
    expect(foreground.getAttribute('viewBox'), '0 0 108 108');
    expect(_drawn(foreground, 'rect'), isEmpty);
    final (mask: _, cut: _, shape: pin) = _masked(
      foreground,
      'verily-app-icon-foreground-knockout',
    );
    expect(pin.getAttribute('fill'), '#FFFAF0');
    expect(_drawn(foreground, 'path').last.getAttribute('stroke'), '#FFFAF0');
  });
}
