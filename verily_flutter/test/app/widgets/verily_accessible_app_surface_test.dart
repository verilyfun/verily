import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:verily_flutter/app/widgets/verily_accessible_app_surface.dart';
import 'package:verily_flutter/app/widgets/verily_copyable_error_text.dart';

void main() {
  testWidgets('keeps passive copy inert and follows visual focus order', (
    tester,
  ) async {
    final firstFocus = FocusNode();
    final secondFocus = FocusNode();
    addTearDown(firstFocus.dispose);
    addTearDown(secondFocus.dispose);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            VerilyAccessibleAppSurface(child: child ?? const SizedBox.shrink()),
        home: Scaffold(
          body: Column(
            children: [
              const Text('Action description'),
              const TextField(canRequestFocus: false),
              TextButton(
                focusNode: firstFocus,
                onPressed: () {},
                child: const Text('First action'),
              ),
              TextButton(
                focusNode: secondFocus,
                onPressed: () {},
                child: const Text('Second action'),
              ),
            ],
          ),
        ),
      ),
    );
    // The root intentionally joins focus traversal after its first layout
    // frame so Flutter web cannot inspect unlaid-out bounds during startup.
    await tester.pump();

    expect(find.byType(SelectionArea), findsNothing);
    expect(find.byType(SelectableText), findsNothing);
    expect(find.byType(FocusTraversalGroup), findsWidgets);
    expect(
      tester
          .widget<TextField>(find.byType(TextField))
          .enableInteractiveSelection,
      isNot(false),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(firstFocus.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(secondFocus.hasFocus, isTrue);
  });

  testWidgets('allows persistent error messages to be copied', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VerilyCopyableErrorText('Reference VER-104 for support.'),
        ),
      ),
    );

    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.text('Reference VER-104 for support.'), findsOneWidget);
  });
}
