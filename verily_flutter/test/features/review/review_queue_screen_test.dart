import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/review/review_queue_screen.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import '../../support/test_app.dart';
import '../me/support/fakes.dart';

Future<void> _pumpQueue(
  WidgetTester tester,
  FakeEvidenceReviewRepository reviews, {
  bool reviewer = true,
}) async {
  await pumpVerilyPage(
    tester,
    const ReviewQueueScreen(),
    session: reviewer ? testReviewerSession : testSignedInSession,
    physicalSize: const Size(800, 2400),
    overrides: meSliceOverrides(reviews: reviews),
  );
  await tester.pumpAndSettle();
}

bool _canSubmit(WidgetTester tester) => tester
    .widget<FilledButton>(find.byKey(VerilyTestKeys.decisionSubmit))
    .enabled;

void main() {
  testWidgets('is closed to accounts without review access', (tester) async {
    final reviews = FakeEvidenceReviewRepository(
      queue: [fakeReviewItem(evidenceId: 1)],
    );
    await _pumpQueue(tester, reviews, reviewer: false);

    expect(find.text("Reviewing is for Verily's reviewers"), findsOneWidget);
    expect(find.text('Ten squats at the park'), findsNothing);
    expect(reviews.queueLoads, 0);
  });

  testWidgets('says when there is nothing to review', (tester) async {
    await _pumpQueue(tester, FakeEvidenceReviewRepository());

    expect(find.text('Nothing to review'), findsOneWidget);
  });

  testWidgets('shows what a reviewer needs and nothing internal', (
    tester,
  ) async {
    await _pumpQueue(
      tester,
      FakeEvidenceReviewRepository(
        queue: [
          fakeReviewItem(
            evidenceId: 1,
            payoutReview: PayoutReviewView(
              amountPerPayout: 250000000,
              tokenSymbol: 'USDC',
              decimals: 6,
              thresholdAtoms: 100000000,
            ),
          ),
        ],
      ),
    );

    expect(find.text('Ten squats at the park'), findsOneWidget);
    expect(find.text('Park Run Club · Record your squats'), findsOneWidget);
    expect(find.text('Video proof · 42 seconds'), findsOneWidget);
    expect(find.text('Checked by a person before it counts.'), findsOneWidget);
    expect(find.text('Listen for “pelican”'), findsOneWidget);
    expect(
      find.text('Pays 250 USDC, above the 100 USDC review threshold'),
      findsOneWidget,
    );
    expect(find.textContaining('Captured '), findsOneWidget);
    expect(find.textContaining('manual_review'), findsNothing);
    // With no private link there is nothing to play or reload.
    expect(
      find.text("This proof can't play here. Reload to get a fresh link."),
      findsOneWidget,
    );
    expect(find.byKey(VerilyTestKeys.reviewMediaReload), findsNothing);
  });

  for (final (decision, key, title) in [
    (
      EvidenceDecisionStatus.accepted,
      VerilyTestKeys.reviewAccept,
      'Accept this proof?',
    ),
    (
      EvidenceDecisionStatus.rejected,
      VerilyTestKeys.reviewReject,
      'Reject this proof?',
    ),
  ]) {
    testWidgets('records a ${decision.name} decision with its note', (
      tester,
    ) async {
      final item = fakeReviewItem(evidenceId: 1);
      final reviews = FakeEvidenceReviewRepository(queue: [item]);
      await _pumpQueue(tester, reviews);

      await tester.ensureVisible(find.byKey(key('${item.evidenceId}')));
      await tester.tap(find.byKey(key('${item.evidenceId}')));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
      expect(_canSubmit(tester), isFalse);

      await tester.enterText(find.byKey(VerilyTestKeys.decisionNote), '   ');
      await tester.pump();
      expect(_canSubmit(tester), isFalse);

      await tester.enterText(
        find.byKey(VerilyTestKeys.decisionNote),
        '  Ten squats, word said clearly.  ',
      );
      await tester.pump();
      expect(_canSubmit(tester), isTrue);
      await tester.tap(find.byKey(VerilyTestKeys.decisionSubmit));
      await tester.pumpAndSettle();

      expect(reviews.reviews, [
        (
          evidenceId: item.evidenceId,
          decision: decision,
          note: 'Ten squats, word said clearly.',
        ),
      ]);
      expect(find.text('Decision saved.'), findsOneWidget);
      expect(find.text('Nothing to review'), findsOneWidget);
    });
  }

  testWidgets('a cancelled decision records nothing', (tester) async {
    final item = fakeReviewItem(evidenceId: 1);
    final reviews = FakeEvidenceReviewRepository(queue: [item]);
    await _pumpQueue(tester, reviews);

    await tester.ensureVisible(
      find.byKey(VerilyTestKeys.reviewAccept('${item.evidenceId}')),
    );
    await tester.tap(
      find.byKey(VerilyTestKeys.reviewAccept('${item.evidenceId}')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(reviews.reviews, isEmpty);
    expect(find.text('Ten squats at the park'), findsOneWidget);
  });
}
