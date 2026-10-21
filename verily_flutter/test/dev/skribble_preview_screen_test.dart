import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skribble/skribble.dart';

import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/app/widgets/verily_sketch_postcard.dart';
import 'package:verily_flutter/app/widgets/verily_state_panel.dart';
import 'package:verily_flutter/app/widgets/verily_wired_scope.dart';
import 'package:verily_flutter/dev/skribble_preview_screen.dart';
import 'package:verily_flutter/l10n/l10n.dart';

void main() {
  Future<void> pumpPreview(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
  }) async {
    // Tall enough that the lazy list builds every section at once.
    tester.view.physicalSize = const Size(390, 6400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerilyTheme(
          brightness: brightness,
          useAppTypeface: false,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // Mirrors the app, which installs one scope above its navigator.
        builder: (context, child) => VerilyWiredScope(child: child!),
        home: const SkribblePreviewScreen(),
      ),
    );
    await tester.pump();
  }

  for (final brightness in Brightness.values) {
    testWidgets('the $brightness gallery renders every primitive', (
      tester,
    ) async {
      await pumpPreview(tester, brightness: brightness);

      // The gallery relies on the app's scope rather than installing its own.
      expect(find.byType(VerilyWiredScope), findsOneWidget);
      expect(find.text('Colours'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Body · 16/23'), findsOneWidget);
      expect(find.text('Heading · 32/35'), findsOneWidget);
      expect(find.byType(VerilySketchPostcard), findsNWidgets(2));
      expect(find.byType(VerilyActionButton), findsNWidgets(7));
      expect(find.byType(VerilyStatePanel), findsNWidgets(2));
      expect(find.byType(VerilyLoadingPanel), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(WiredCheckbox), findsOneWidget);
      expect(find.byType(WiredSwitch), findsOneWidget);
      expect(find.byType(WiredRadio<Brightness>), findsNWidgets(2));
      expect(find.byType(WiredSlider), findsOneWidget);
      expect(find.byType(WiredProgress), findsOneWidget);
      expect(find.byType(WiredCircularProgress), findsOneWidget);
      expect(find.byType(WiredDoodle), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('gallery toggles wired selection controls', (tester) async {
    await pumpPreview(tester);

    await tester.tap(find.byType(WiredCheckbox));
    await tester.pump();
    await tester.tap(find.byType(WiredRadio<Brightness>).last);
    await tester.pump();
    expect(
      tester
          .widget<WiredRadio<Brightness>>(
            find.byType(WiredRadio<Brightness>).last,
          )
          .groupValue,
      Brightness.dark,
    );

    // Turning the roughen switch off disables the slider it drives.
    await tester.tap(find.byType(WiredSwitch));
    await tester.pump();
    expect(
      tester.widget<WiredSlider>(find.byType(WiredSlider)).onChanged,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}
