import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/app/widgets/verily_copyable_error_text.dart';
import 'package:verily_flutter/app/widgets/verily_rough_surface.dart';
import 'package:verily_flutter/app/widgets/verily_sketch_postcard.dart';
import 'package:verily_flutter/app/widgets/verily_state_panel.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildVerilyTheme(useAppTypeface: false),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('an empty state invites with a postcard in its tone', (
    tester,
  ) async {
    var pressed = 0;
    await tester.pumpWidget(
      _host(
        VerilyStatePanel.empty(
          title: 'No actions nearby yet',
          message: 'Widen the map or post the first one here.',
          tone: VerilyTone.place,
          action: VerilyStateAction(
            label: 'Post an action',
            onPressed: () => pressed++,
          ),
          secondaryAction: VerilyStateAction(
            label: 'Widen the map',
            onPressed: () {},
          ),
        ),
      ),
    );

    final postcard = tester.widget<VerilySketchPostcard>(
      find.byType(VerilySketchPostcard),
    );
    expect(postcard.tone, VerilyTone.place);
    final surface = tester.widget<VerilyRoughSurface>(
      find.descendant(
        of: find.byType(VerilySketchPostcard),
        matching: find.byType(VerilyRoughSurface),
      ),
    );
    expect(surface.fill, const VerilyPalette.paper().placeWash);
    expect(find.byType(VerilyCopyableErrorText), findsNothing);

    final buttons = tester
        .widgetList<VerilyActionButton>(find.byType(VerilyActionButton))
        .toList();
    expect(buttons.map((button) => button.tone), [
      VerilyActionTone.primary,
      VerilyActionTone.secondary,
    ]);

    await tester.tap(find.text('Post an action'));
    expect(pressed, 1);
  });

  testWidgets('a problem stays on paper and its message can be copied', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const VerilyStatePanel.problem(
          title: 'We couldn’t load your proof',
          message: 'Reference VER-104.',
        ),
      ),
    );

    expect(find.byType(VerilySketchPostcard), findsNothing);
    expect(find.byType(VerilyCopyableErrorText), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
    expect(
      tester
          .getSemantics(find.text('We couldn’t load your proof'))
          .getSemanticsData()
          .flagsCollection
          .isHeader,
      isTrue,
    );
  });

  testWidgets('a wait is announced, not just drawn', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(const VerilyLoadingPanel(label: 'Checking your proof…')),
    );

    expect(
      find.bySemanticsLabel('Checking your proof…'),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(find.byType(VerilyLoadingPanel)),
      isSemantics(label: 'Checking your proof…', isLiveRegion: true),
    );
    handle.dispose();
  });

  testWidgets('a disabled action keeps its place but cannot be activated', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const VerilyActionButton(label: 'Publish action', onPressed: null)),
    );

    expect(
      tester.getSemantics(find.byType(VerilyActionButton)),
      isSemantics(
        label: 'Publish action',
        isButton: true,
        isEnabled: false,
        hasTapAction: false,
      ),
    );
    expect(
      tester.getSize(find.byType(VerilyRoughSurface)).height,
      greaterThanOrEqualTo(56),
    );
  });
}
