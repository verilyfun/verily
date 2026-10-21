import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:verily_flutter/app/theme/verily_pen.dart';
import 'package:verily_flutter/app/theme/verily_rough_border.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';

void main() {
  testWidgets('themed buttons draw the pen outline at a full target', (
    tester,
  ) async {
    final theme = buildVerilyTheme(useAppTypeface: false);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton(onPressed: () {}, child: const Text('Save')),
                OutlinedButton(onPressed: () {}, child: const Text('Cancel')),
              ],
            ),
          ),
        ),
      ),
    );

    for (final type in [FilledButton, OutlinedButton]) {
      final button = find.byType(type);
      expect(tester.getSize(button).height, greaterThanOrEqualTo(56));

      final material = tester.widget<Material>(
        find.descendant(of: button, matching: find.byType(Material)).first,
      );
      final shape = material.shape! as VerilyRoughBorder;
      expect(shape.side.style, BorderStyle.solid);
      expect(shape.side.width, VerilyPen.strokeWidth);
    }
  });

  test('inks only the pen, never a fill over the control', () {
    const ink = VerilyColors.movementJoint;
    const border = VerilyRoughBorder(
      side: BorderSide(color: ink, width: VerilyPen.strokeWidth),
    );
    final canvas = TestRecordingCanvas();
    border.paint(canvas, const Rect.fromLTWH(0, 0, 160, 56));

    // Skribble's pen inks each line as a filled, variable-width outline, so
    // every visible paint must carry the pen colour: anything else would be
    // a fill drawn over the control's own Material.
    final visible = [
      for (final call in canvas.invocations)
        if (call.invocation.memberName == #drawPath)
          call.invocation.positionalArguments[1] as Paint,
    ].where((paint) => paint.color.a > 0);
    expect(visible, isNotEmpty);
    expect(
      visible.map((paint) => paint.color.toARGB32()),
      everyElement(ink.toARGB32()),
    );
  });

  test('a border without a side paints nothing', () {
    final canvas = TestRecordingCanvas();
    const VerilyRoughBorder().paint(canvas, const Rect.fromLTWH(0, 0, 160, 56));

    expect(canvas.invocations, isEmpty);
  });
}
