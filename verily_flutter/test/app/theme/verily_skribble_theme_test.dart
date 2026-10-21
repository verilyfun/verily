import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skribble/skribble.dart';

import 'package:verily_flutter/app/theme/verily_skribble_theme.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_wired_scope.dart';

void main() {
  Future<WiredThemeData> pumpScope(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    WiredRoughness roughnessLevel = WiredRoughness.playful,
    bool disableAnimations = false,
  }) async {
    WiredThemeData? captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerilyTheme(brightness: brightness, useAppTypeface: false),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: disableAnimations,
          ),
          child: child!,
        ),
        home: VerilyWiredScope(
          roughnessLevel: roughnessLevel,
          child: Builder(
            builder: (context) {
              captured = WiredTheme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return captured!;
  }

  testWidgets('binds the light palette roles to the wired theme', (
    tester,
  ) async {
    final theme = buildVerilyTheme(useAppTypeface: false);
    final wired = await pumpScope(tester);

    expect(wired.borderColor, theme.verily.ink);
    expect(wired.textColor, theme.verily.ink);
    expect(wired.disabledTextColor, theme.verily.mutedInk);
    expect(wired.fillColor, theme.verily.surface);
    expect(wired.roughnessLevel, WiredRoughness.playful);
    expect(wired.motionEnabled, isTrue);
  });

  testWidgets('follows the night palette', (tester) async {
    final theme = buildVerilyTheme(
      brightness: Brightness.dark,
      useAppTypeface: false,
    );
    final wired = await pumpScope(tester, brightness: Brightness.dark);

    expect(wired.borderColor, theme.verily.ink);
    expect(wired.fillColor, theme.verily.surface);
    expect(
      wired.fillColor,
      isNot(buildVerilyTheme(useAppTypeface: false).verily.surface),
    );
  });

  testWidgets('keeps the outline preset overridable per scope', (
    tester,
  ) async {
    final wired = await pumpScope(
      tester,
      roughnessLevel: WiredRoughness.gentle,
    );

    expect(wired.roughnessLevel, WiredRoughness.gentle);
    // Lettering stays the label typeface whatever the outline preset, so
    // wired labels match the Material label role.
    expect(wired.fontFamily, VerilySkribbleTheme.fontFamily);
    expect(wired.fontPackage, 'skribble_font_recursive');
  });

  test(
    'letters display by hand and labels in the linear face, both playful',
    () {
      expect(
        verilyDisplayTypeface,
        WiredFont.casual.familyFor(WiredRoughness.playful),
      );
      expect(
        verilyTextTypeface,
        WiredFont.linear.familyFor(WiredRoughness.playful),
      );
      expect(
        verilyNumeralTypeface,
        WiredFont.mono.familyFor(WiredRoughness.playful),
      );
      // Wired controls letter their labels like the Material label role.
      expect(VerilySkribbleTheme.fontFamily, verilyTextTypeface);
    },
  );

  testWidgets('washes selections in the palette marker', (tester) async {
    final theme = buildVerilyTheme(useAppTypeface: false);
    final wired = await pumpScope(tester);

    expect(wired.markerColor, theme.verily.highlight);
  });

  testWidgets('reduced motion disables decorative ink animation', (
    tester,
  ) async {
    final wired = await pumpScope(tester, disableAnimations: true);

    expect(wired.motionEnabled, isFalse);
  });

  testWidgets('wired components render inside the scope', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerilyTheme(useAppTypeface: false),
        home: VerilyWiredScope(
          child: WiredButton(
            onPressed: () {},
            child: const Text('Publish action'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(WiredButton), findsOneWidget);
    expect(find.text('Publish action'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
