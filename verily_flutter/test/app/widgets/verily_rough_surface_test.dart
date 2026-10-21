import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_rough_surface.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    theme: buildVerilyTheme(useAppTypeface: false),
    home: Scaffold(
      body: Center(child: SizedBox(width: 320, child: child)),
    ),
  );

  testWidgets('paints the pen outline over its fill, not under the child', (
    tester,
  ) async {
    const fill = VerilyColors.movementHudWash;
    const outline = VerilyColors.shadow;
    await tester.pumpWidget(
      host(
        const VerilyRoughSurface(
          fill: fill,
          outline: outline,
          minHeight: 120,
          child: Text('Postcard'),
        ),
      ),
    );

    final surface = tester.renderObject(
      find.descendant(
        of: find.byType(VerilyRoughSurface),
        matching: find.byType(DecoratedBox),
      ),
    );
    // The field first, then the pen inked on top. Any further rounded fill
    // would mean the child is repainting over the outline.
    expect(
      surface,
      paints
        ..rrect(color: fill)
        ..path(color: outline),
    );
    expect(surface, paintsExactlyCountTimes(#drawRRect, 1));
  });

  testWidgets('draws the whole 56-unit action target', (tester) async {
    await tester.pumpWidget(
      host(VerilyActionButton(label: 'Find actions', onPressed: () {})),
    );

    final surface = tester.getSize(find.byType(VerilyRoughSurface));
    expect(surface.height, greaterThanOrEqualTo(56));
    expect(surface.width, 320);

    // The label sits centred inside the drawn surface.
    final surfaceRect = tester.getRect(find.byType(VerilyRoughSurface));
    final labelCenter = tester.getCenter(find.text('Find actions'));
    expect(labelCenter.dy, closeTo(surfaceRect.center.dy, 1));
  });

  testWidgets('an inline action hugs its label', (tester) async {
    await tester.pumpWidget(
      host(
        Row(
          children: [
            VerilyActionButton(
              label: 'Retry',
              expand: false,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );

    final surface = tester.getSize(find.byType(VerilyRoughSurface));
    expect(surface.height, greaterThanOrEqualTo(56));
    expect(surface.width, lessThan(200));
  });
}
