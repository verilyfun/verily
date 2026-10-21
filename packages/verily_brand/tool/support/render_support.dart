// Shared by the render tools: loads the real Skribble typefaces into the
// test engine and captures widgets to PNG files.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Skribble font package whose typefaces the reel and cover use.
const String skribbleFontPackage = 'skribble_font_recursive';

/// The families the brand draws text with.
const List<String> brandFontFamilies = [
  'SkribblePlayful',
  'SkribbleLinearPlayful',
  'SkribbleMonoPlayful',
];

/// Loads every face of [families] from the resolved `skribble_font_recursive`
/// package, so text renders in the real typefaces instead of the test font.
///
/// Fonts are registered under `packages/skribble_font_recursive/<family>`,
/// the name Skribble's themes ask for.
Future<void> loadSkribbleFonts({
  List<String> families = brandFontFamilies,
}) async {
  final root = packageRoot(skribbleFontPackage);
  final manifest = File.fromUri(root.resolve('pubspec.yaml'));
  final assets = <String, List<String>>{};
  String? family;
  for (final line in manifest.readAsLinesSync()) {
    final name = RegExp(r'^\s*- family:\s*(\S+)').firstMatch(line);
    if (name != null) {
      family = name.group(1);
      continue;
    }
    final asset = RegExp(r'asset:\s*(\S+)').firstMatch(line);
    if (asset != null && family != null && families.contains(family)) {
      (assets[family] ??= []).add(asset.group(1)!);
    }
  }
  final missing = families.where((name) => !assets.containsKey(name));
  if (missing.isNotEmpty) {
    throw StateError('Font families not found in $manifest: $missing');
  }
  for (final MapEntry(key: name, value: files) in assets.entries) {
    final loader = FontLoader('packages/$skribbleFontPackage/$name');
    for (final file in files) {
      final bytes = File.fromUri(root.resolve(file)).readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}

/// The root directory of [package], as resolved by `flutter pub get`.
Uri packageRoot(String package) {
  final config = File('.dart_tool/package_config.json');
  final json = jsonDecode(config.readAsStringSync());
  if (json case {'packages': final List<Object?> packages}) {
    for (final entry in packages) {
      if (entry case {'name': final String name, 'rootUri': final String uri}
          when name == package) {
        final root = config.absolute.uri.resolve(uri);
        return root.path.endsWith('/') ? root : Uri.parse('$root/');
      }
    }
  }
  throw StateError('$package is not in ${config.path}; run flutter pub get.');
}

/// Writes the pixels of [boundary] at [pixelRatio] to [path] as a PNG.
///
/// With [opaque], the file is RGB with no alpha channel at all, which app
/// stores require of launcher icons; every pixel must then be opaque.
Future<void> capturePng(
  WidgetTester tester,
  RenderRepaintBoundary boundary,
  String path, {
  double pixelRatio = 1,
  bool opaque = false,
}) async {
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final Uint8List bytes;
    if (opaque) {
      final rgba = await image.toByteData();
      bytes = encodeOpaquePng(image.width, image.height, rgba!);
    } else {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      bytes = png!.buffer.asUint8List();
    }
    image.dispose();
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);
  });
}

/// Encodes straight RGBA pixels as an 8-bit RGB PNG with no alpha channel.
///
/// Throws when a pixel is not fully opaque, rather than flattening it onto a
/// colour nobody chose.
Uint8List encodeOpaquePng(int width, int height, ByteData rgba) {
  final rows = BytesBuilder(copy: false);
  for (var y = 0; y < height; y++) {
    final row = Uint8List(1 + width * 3); // Filter type 0, then RGB.
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      if (rgba.getUint8(i + 3) != 255) {
        throw StateError('Pixel ($x, $y) is not opaque.');
      }
      row
        ..[1 + x * 3] = rgba.getUint8(i)
        ..[2 + x * 3] = rgba.getUint8(i + 1)
        ..[3 + x * 3] = rgba.getUint8(i + 2);
    }
    rows.add(row);
  }
  final header = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8) // Bit depth.
    ..setUint8(9, 2); // Colour type: truecolour, no alpha.
  final png = BytesBuilder(copy: false)
    ..add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
    ..add(_chunk('IHDR', header.buffer.asUint8List()))
    ..add(_chunk('IDAT', ZLibCodec(level: 9).encode(rows.takeBytes())))
    ..add(_chunk('IEND', const []));
  return png.takeBytes();
}

Uint8List _chunk(String type, List<int> data) {
  final body = [...ascii.encode(type), ...data];
  final chunk = ByteData(12 + data.length)..setUint32(0, data.length);
  final bytes = chunk.buffer.asUint8List()..setRange(4, 8 + data.length, body);
  chunk.setUint32(8 + data.length, _crc32(body));
  return bytes;
}

final List<int> _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = c & 1 == 1 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final byte in bytes) {
    crc = _crcTable[(crc ^ byte) & 0xFF] ^ (crc >>> 8);
  }
  return crc ^ 0xFFFFFFFF;
}

/// Writes the whole test view to [path] as a PNG at its physical size.
Future<void> captureView(WidgetTester tester, String path) async {
  final view = tester.view;
  final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
  await tester.runAsync(() async {
    final image = await layer.toImage(
      Offset.zero & view.physicalSize,
    );
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
  });
}
