import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:verily_flutter/app/app.dart';
import 'package:verily_flutter/app/screens/placeholder_screen.dart';
import 'package:verily_flutter/app/theme/theme_mode_provider.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import '../support/memory_theme_store.dart';

void main() {
  testWidgets('opens on the placeholder and switches to night from settings', (
    tester,
  ) async {
    final store = MemoryThemeStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [themePreferenceStoreProvider.overrideWithValue(store)],
        child: const VerilyApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(PlaceholderScreen), findsOneWidget);
    expect(find.text('Verily'), findsOneWidget);
    expect(find.text('Do it. Prove it. Get paid.'), findsOneWidget);
    BuildContext screen() => tester.element(find.byType(PlaceholderScreen));
    expect(Theme.of(screen()).brightness, Brightness.light);

    await tester.tap(find.byTooltip('Open settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.byKey(VerilyTestKeys.appearanceDark));
    await tester.pumpAndSettle();
    expect(store.saved, 'dark');
    expect(
      Theme.of(screen()).verily.canvas,
      const VerilyPalette.night().canvas,
    );

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsNothing);
  });

  testWidgets('restores a saved night preference on launch', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themePreferenceStoreProvider.overrideWithValue(
            MemoryThemeStore(saved: 'dark'),
          ),
        ],
        child: const VerilyApp(),
      ),
    );
    await tester.pumpAndSettle();

    final screen = tester.element(find.byType(PlaceholderScreen));
    expect(Theme.of(screen).brightness, Brightness.dark);
  });
}
