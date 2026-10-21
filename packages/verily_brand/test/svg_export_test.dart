import 'package:flutter_test/flutter_test.dart';
import 'package:verily_brand/verily_brand.dart';
import 'package:xml/xml.dart';

XmlElement _parse(String svg) => XmlDocument.parse(svg).rootElement;

void main() {
  test('every exported file is an SVG with a viewBox and a title', () {
    final files = VerilySvg.files();
    expect(
      files.keys,
      containsAll(<String>[
        'verily-mark.svg',
        'verily-mark-mono.svg',
        'verily-mark-dark.svg',
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

  test('the mark is the single geometry stroke, round-capped', () {
    final paths = _parse(VerilySvg.mark()).findAllElements('path').toList();
    expect(paths, hasLength(1));
    final path = paths.single;
    expect(path.getAttribute('d'), VerilyGeometry.mark.pathData);
    expect(path.getAttribute('d'), startsWith('M 307 268 C'));
    expect(path.getAttribute('stroke'), '#D13F22');
    expect(path.getAttribute('stroke-linecap'), 'round');
    expect(path.getAttribute('stroke-linejoin'), 'round');
    expect(path.getAttribute('fill'), 'none');
    expect(path.getAttribute('stroke-width'), '36');
  });

  test('the mono mark inks with currentColor', () {
    final path = _parse(VerilySvg.mark(color: null))
        .findAllElements('path')
        .single;
    expect(path.getAttribute('stroke'), 'currentColor');
  });

  test('the wordmark has a vermilion check, plum letters, and a dot', () {
    final root = _parse(VerilySvg.wordmark());
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

  test('the lockups carry the mark and the whole wordmark', () {
    for (final layout in VerilyLockupLayout.values) {
      final paths = _parse(VerilySvg.lockup(layout)).findAllElements('path');
      expect(paths, hasLength(1 + VerilyGeometry.wordmark.strokes.length));
    }
  });

  test('the app icon is a paper mark on a vermilion square', () {
    final root = _parse(VerilySvg.appIcon());
    expect(root.findAllElements('rect').single.getAttribute('fill'), '#D13F22');
    expect(
      root.findAllElements('path').single.getAttribute('stroke'),
      '#FFFAF0',
    );
    final foreground = _parse(VerilySvg.appIconForeground());
    expect(foreground.getAttribute('viewBox'), '0 0 108 108');
    expect(foreground.findAllElements('rect'), isEmpty);
  });
}
