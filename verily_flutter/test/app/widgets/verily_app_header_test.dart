import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon;

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_app_header.dart';
import 'package:verily_flutter/l10n/l10n.dart';

void main() {
  testWidgets('names the page by its task below the system status bar', (
    tester,
  ) async {
    const systemTopInset = 32.0;
    const contentTopPadding = 16.0;
    const closeButtonKey = ValueKey('close-button');

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildVerilyTheme(useAppTypeface: false),
        home: MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(top: systemTopInset),
          ),
          child: Scaffold(
            body: VerilyAppHeader(
              title: 'Your proof',
              subtitle: 'Your actions · Your proof',
              trailing: IconButton(
                key: closeButtonKey,
                onPressed: () {},
                icon: const SkribbleIcon(data: VerilyIcons.close),
              ),
            ),
          ),
        ),
      ),
    );

    const safeContentTop = systemTopInset + contentTopPadding;
    expect(
      tester.getTopLeft(find.text('Your proof')).dy,
      greaterThanOrEqualTo(safeContentTop),
    );
    expect(
      tester.getTopLeft(find.byKey(closeButtonKey)).dy,
      greaterThanOrEqualTo(safeContentTop),
    );
    expect(find.text('Your actions · Your proof'), findsOneWidget);
    final heading = tester
        .getSemantics(find.text('Your proof'))
        .getSemanticsData();
    expect(heading.label, 'Your proof');
    expect(heading.headingLevel, 1);
  });

  testWidgets('a bottom slot sits under the title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerilyTheme(useAppTypeface: false),
        home: const Scaffold(
          body: VerilyAppHeader(
            title: 'Post an action',
            bottom: LinearProgressIndicator(value: 0.5),
          ),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.byType(LinearProgressIndicator)).dy,
      greaterThan(tester.getBottomLeft(find.text('Post an action')).dy),
    );
  });
}
