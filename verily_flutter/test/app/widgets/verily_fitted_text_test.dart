import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_app_header.dart';
import 'package:verily_flutter/app/widgets/verily_fitted_text.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon;

const _longTitle = 'Choose the action your neighbours will love';

Future<void> _pump(WidgetTester tester, Widget child, {double width = 320}) {
  tester.view.physicalSize = Size(width, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    MaterialApp(
      theme: buildVerilyTheme(useAppTypeface: false),
      home: Scaffold(body: child),
    ),
  );
}

/// The paragraph that paints [text], wherever it sits in the tree.
RenderParagraph _paragraph(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text));

void main() {
  testWidgets('keeps its size when the text fits', (tester) async {
    await _pump(
      tester,
      const Center(
        child: VerilyFittedText('Settings', style: TextStyle(fontSize: 24)),
      ),
    );

    // Painted at its natural size: the box neither shrinks nor grows it.
    final painted = tester.getRect(find.text('Settings')).height;
    final natural = _paragraph(tester, 'Settings').size.height;
    expect(painted, closeTo(natural, .01));
  });

  testWidgets('shrinks a long title to fit instead of clipping it', (
    tester,
  ) async {
    await _pump(
      tester,
      const Padding(
        padding: EdgeInsets.all(20),
        child: VerilyFittedText(_longTitle, style: TextStyle(fontSize: 32)),
      ),
    );

    final paragraph = _paragraph(tester, _longTitle);
    // The paragraph lays out the whole title on one line…
    expect(paragraph.didExceedMaxLines, isFalse);
    // …and the painted, scaled-down line still fits the 280-unit space.
    expect(
      tester.getRect(find.text(_longTitle)).width,
      lessThanOrEqualTo(280.01),
    );
    expect(paragraph.size.width, greaterThan(280));
  });

  testWidgets(
    'the page header fits a long title on a small phone with an action',
    (tester) async {
      await _pump(
        tester,
        VerilyAppHeader(
          title: _longTitle,
          subtitle: 'Your actions · Drafts',
          trailing: IconButton(
            onPressed: () {},
            icon: const SkribbleIcon(data: VerilyIcons.close),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(_paragraph(tester, _longTitle).didExceedMaxLines, isFalse);
      final title = tester.getRect(find.text(_longTitle));
      final action = tester.getRect(find.byType(IconButton));
      expect(title.right, lessThanOrEqualTo(action.left));
      // The 16dp page gutter.
      expect(title.left, greaterThanOrEqualTo(16));
    },
  );
}
