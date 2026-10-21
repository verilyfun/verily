import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/appeals/appeals_screen.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import '../../support/test_app.dart';
import '../me/support/fakes.dart';

Future<void> _pumpAppeals(
  WidgetTester tester,
  FakeEvidenceAppealRepository appeals,
) async {
  await pumpVerilyPage(
    tester,
    const AppealsScreen(),
    physicalSize: const Size(800, 2400),
    overrides: meSliceOverrides(appeals: appeals),
  );
  await tester.pumpAndSettle();
}

bool _canSubmit(WidgetTester tester) => tester
    .widget<FilledButton>(find.byKey(VerilyTestKeys.decisionSubmit))
    .enabled;

void main() {
  testWidgets('says when no one has appealed', (tester) async {
    await _pumpAppeals(tester, FakeEvidenceAppealRepository());

    expect(find.text('No appeals'), findsOneWidget);
  });

  testWidgets("shows the appeal in the participant's words", (tester) async {
    await _pumpAppeals(
      tester,
      FakeEvidenceAppealRepository(owned: [fakeAppeal(id: 1, attemptId: 2)]),
    );

    expect(find.text('Ten squats at the park'), findsOneWidget);
    expect(find.text('Record your squats · Video proof'), findsOneWidget);
    expect(find.text('Their words'), findsOneWidget);
    expect(
      find.text('All ten squats are in the second half of the clip.'),
      findsOneWidget,
    );
    expect(find.text('Waiting for you'), findsOneWidget);
  });

  for (final (decision, key, title, outcome) in [
    (
      EvidenceAppealStatus.accepted,
      VerilyTestKeys.appealAccept,
      'Accept this appeal?',
      'You accepted this appeal',
    ),
    (
      EvidenceAppealStatus.rejected,
      VerilyTestKeys.appealReject,
      'Reject this appeal?',
      'You turned this appeal down',
    ),
  ]) {
    testWidgets('resolves an appeal as ${decision.name} with an answer', (
      tester,
    ) async {
      final appeal = fakeAppeal(id: 1, attemptId: 2);
      final appeals = FakeEvidenceAppealRepository(owned: [appeal]);
      await _pumpAppeals(tester, appeals);

      await tester.ensureVisible(find.byKey(key('${appeal.id}')));
      await tester.tap(find.byKey(key('${appeal.id}')));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
      expect(_canSubmit(tester), isFalse);

      await tester.enterText(
        find.byKey(VerilyTestKeys.decisionNote),
        'Counted again on the full clip.',
      );
      await tester.pump();
      await tester.tap(find.byKey(VerilyTestKeys.decisionSubmit));
      await tester.pumpAndSettle();

      expect(appeals.resolved, [
        (
          appealId: appeal.id,
          decision: decision,
          note: 'Counted again on the full clip.',
        ),
      ]);
      expect(find.text('Appeal decided.'), findsOneWidget);
      expect(find.text(outcome), findsOneWidget);
      expect(find.text('Counted again on the full clip.'), findsOneWidget);
      expect(
        find.byKey(VerilyTestKeys.appealAccept('${appeal.id}')),
        findsNothing,
      );
      expect(
        find.byKey(VerilyTestKeys.appealReject('${appeal.id}')),
        findsNothing,
      );
    });
  }

  testWidgets('offers no decision on an appeal already resolved', (
    tester,
  ) async {
    final appeal = fakeAppeal(
      id: 1,
      attemptId: 2,
      status: EvidenceAppealStatus.accepted,
      resolutionNote: 'All ten are there.',
    );
    await _pumpAppeals(
      tester,
      FakeEvidenceAppealRepository(owned: [appeal]),
    );

    expect(find.text('You accepted this appeal'), findsOneWidget);
    expect(find.text('All ten are there.'), findsOneWidget);
    expect(
      find.byKey(VerilyTestKeys.appealAccept('${appeal.id}')),
      findsNothing,
    );
  });
}
