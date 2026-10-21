import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:verily_flutter/app/screens/coming_soon_screen.dart';
import 'package:verily_flutter/app/theme/theme_mode_provider.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_appearance_settings.dart';
import 'package:verily_flutter/app/widgets/verily_state_panel.dart';
import 'package:verily_flutter/app/widgets/verily_wired_scope.dart';
import 'package:verily_flutter/l10n/l10n.dart';

import '../support/memory_theme_store.dart';

/// The Solana Seeker's portrait viewport: 1080 × 2400 physical pixels.
const _seekerPhysicalSize = Size(1080, 2400);
const _seekerPixelRatio = 2.625;

/// The narrowest phone the app supports, at the same density.
const _compactPhysicalSize = Size(840, 1800);

Future<void> _pumpAt(
  WidgetTester tester,
  Widget home, {
  required Size physicalSize,
  required double textScale,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = _seekerPixelRatio;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        themePreferenceStoreProvider.overrideWithValue(MemoryThemeStore()),
      ],
      child: MaterialApp(
        theme: buildVerilyTheme(
          brightness: brightness,
          useAppTypeface: false,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => VerilyWiredScope(child: child!),
        home: home,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  for (final (label, size) in [
    ('Seeker', _seekerPhysicalSize),
    ('compact', _compactPhysicalSize),
  ]) {
    for (final textScale in [1.0, 1.3, 2.0]) {
      testWidgets('a landing page fits a $label phone at ${textScale}x text', (
        tester,
      ) async {
        await _pumpAt(
          tester,
          const ComingSoonScreen(kind: ComingSoonKind.verificationRequest),
          physicalSize: size,
          textScale: textScale,
        );

        expect(tester.takeException(), isNull);
        final width = size.width / _seekerPixelRatio;
        for (final text in ['Verily', 'Verify with Verily is almost here']) {
          final rect = tester.getRect(find.text(text));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(width));
        }
      });

      testWidgets('appearance and states fit a $label phone at ${textScale}x', (
        tester,
      ) async {
        await _pumpAt(
          tester,
          Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const VerilyAppearanceSettings(),
                const SizedBox(height: 16),
                VerilyStatePanel.empty(
                  title: 'No actions nearby yet',
                  message: 'Widen the map or post the first one here.',
                  action: VerilyStateAction(
                    label: 'Post an action',
                    onPressed: () {},
                  ),
                  secondaryAction: VerilyStateAction(
                    label: 'Maybe later',
                    onPressed: () {},
                  ),
                ),
                const SizedBox(height: 16),
                const VerilyStatePanel.problem(
                  title: 'We couldn’t load your proof',
                  message: 'Reference VER-104.',
                ),
              ],
            ),
          ),
          physicalSize: size,
          textScale: textScale,
          brightness: Brightness.dark,
        );

        expect(tester.takeException(), isNull);
      });
    }
  }
}
