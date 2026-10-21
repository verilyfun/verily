// Renders the placeholder and the theme specimen at the Solana Seeker's
// portrait size with the real Skribble face, so layout is checked against
// true font metrics rather than the test font.
//
// Every run asserts the screens lay out without errors. To also write PNGs
// for review into `.screenshots/phase-a/` (ignored by git):
//
//   flutter test --dart-define=VERILY_SCREENSHOTS=true test/screenshots
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:verily_flutter/app/app.dart';
import 'package:verily_flutter/app/theme/theme_mode_provider.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_wired_scope.dart';
import 'package:verily_flutter/dev/skribble_preview_screen.dart';
import 'package:verily_flutter/l10n/l10n.dart';

import '../support/memory_theme_store.dart';

const _writeScreenshots = bool.fromEnvironment('VERILY_SCREENSHOTS');
const _outputDirectory = '.screenshots/phase-a';

/// The Seeker's portrait panel: 1080 × 2400 at about 2.6 pixels per point.
const _seekerPhysicalSize = Size(1080, 2400);
const _seekerPixelRatio = 2.625;

const _frameKey = ValueKey<String>('screenshot-frame');

/// Loads the three Skribble faces the theme letters with, at the weights it
/// uses, under the resolved family names the text theme asks for.
Future<void> _loadSkribbleFaces() async {
  const package = 'packages/skribble_font_recursive/assets/fonts';
  for (final (family, typeface, weights) in [
    (
      verilyDisplayFontFamily,
      verilyDisplayTypeface,
      ['Regular', 'Bold', 'ExtraBold'],
    ),
    (verilyTextFontFamily, verilyTextTypeface, ['Medium', 'Bold']),
    (verilyNumeralFontFamily, verilyNumeralTypeface, ['SemiBold']),
  ]) {
    final loader = FontLoader(family);
    for (final weight in weights) {
      loader.addFont(rootBundle.load('$package/$typeface-$weight.ttf'));
    }
    await loader.load();
  }
}

void _useSeekerView(WidgetTester tester) {
  tester.view.physicalSize = _seekerPhysicalSize;
  tester.view.devicePixelRatio = _seekerPixelRatio;
  addTearDown(tester.view.reset);
}

/// Lets ink motion, theme changes, and route transitions finish. Loading
/// indicators spin forever, so this pumps fixed steps instead of settling;
/// several steps let an animation that starts mid-way (such as a restored
/// theme) run to its end.
Future<void> _letInkDry(WidgetTester tester) async {
  await tester.pump();
  for (var step = 0; step < 4; step++) {
    await tester.pump(const Duration(milliseconds: 600));
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  expect(tester.takeException(), isNull, reason: name);
  if (!_writeScreenshots) return;

  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_frameKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _seekerPixelRatio);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('$_outputDirectory/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(png!.buffer.asUint8List());
  });
}

Widget _framed(Widget child) => RepaintBoundary(key: _frameKey, child: child);

void main() {
  setUpAll(_loadSkribbleFaces);

  for (final (mode, saved) in [('light', 'light'), ('dark', 'dark')]) {
    testWidgets('placeholder, $mode', (tester) async {
      _useSeekerView(tester);
      await tester.pumpWidget(
        _framed(
          ProviderScope(
            overrides: [
              themePreferenceStoreProvider.overrideWithValue(
                MemoryThemeStore(saved: saved),
              ),
            ],
            child: const VerilyApp(),
          ),
        ),
      );
      await _letInkDry(tester);
      await _capture(tester, 'placeholder-$mode');

      await tester.tap(find.byTooltip('Open settings'));
      await _letInkDry(tester);
      await _capture(tester, 'placeholder-settings-$mode');
    });

    testWidgets('theme specimen, $mode', (tester) async {
      _useSeekerView(tester);
      await tester.pumpWidget(
        _framed(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildVerilyTheme(
              brightness: mode == 'dark' ? Brightness.dark : Brightness.light,
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => VerilyWiredScope(child: child!),
            home: const SkribblePreviewScreen(),
          ),
        ),
      );
      await _letInkDry(tester);

      // Page through the specimen a screen at a time.
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      for (var page = 1; ; page++) {
        await _capture(tester, 'specimen-$mode-$page');
        if (position.pixels >= position.maxScrollExtent) break;
        position.jumpTo(
          math.min(
            position.pixels + position.viewportDimension * 0.85,
            position.maxScrollExtent,
          ),
        );
        await _letInkDry(tester);
      }
    });
  }
}
