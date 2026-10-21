import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/do/widgets/app_pull_check.dart';
import 'package:verily_flutter/l10n/generated/app_localizations_en.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import 'support/do_harness.dart';
import 'support/fakes.dart';

final _l10n = AppLocalizationsEn();
const _actionId = 40;

final ActionRequirementView _pull = appRequirement(
  mode: AppVerificationMode.pull,
);

ActionAttemptView _attempt({
  ActionAttemptStatus status = ActionAttemptStatus.collectingEvidence,
  bool accepted = false,
}) => attemptFixture(
  actionId: _actionId,
  status: status,
  accepted: [if (accepted) _pull.id],
);

EvidenceSubmissionResult _answer({
  EvidenceDecisionStatus? status,
  String reasonCode = 'app_checking',
  ActionAttemptView? attempt,
}) => EvidenceSubmissionResult(
  attempt: attempt ?? _attempt(),
  requirementId: _pull.id,
  status: status,
  reasonCode: reasonCode,
  summary: '',
);

Future<DoFakes> _pump(
  WidgetTester tester, {
  ActionRequirementView? requirement,
  ActionAttemptView? myAttempt,
  bool viewerIsCreator = false,
}) async {
  final fakes = DoFakes()
    ..pollInterval = const Duration(seconds: 5)
    ..actions.onBegin = ((_) => _attempt());
  fakes.actions.available = [
    actionFixture(
      id: _actionId,
      title: 'Bake a loaf',
      creator: 'Slopper',
      requirements: [requirement ?? _pull],
      myAttempt: myAttempt,
      viewerIsCreator: viewerIsCreator,
    ),
  ];
  await pumpDoRoutes(
    tester,
    initialLocation: '/actions/${doUuid(_actionId)}',
    overrides: fakes.overrides,
    physicalSize: const Size(800, 2400),
  );
  await settle(tester);
  return fakes;
}

Finder get _ask =>
    find.byKey(VerilyTestKeys.actionPullAsk(_pull.requirementKey));
Finder get _reference =>
    find.byKey(VerilyTestKeys.actionPullReference(_pull.requirementKey));
Finder get _status =>
    find.byKey(VerilyTestKeys.actionPullStatus(_pull.requirementKey));

Future<void> _tapAsk(WidgetTester tester) async {
  await tester.ensureVisible(_ask);
  await tester.pump();
  await tester.tap(_ask);
  await settle(tester);
}

void main() {
  test('reads the phase from the public reason', () {
    expect(appPullPhaseOf(_answer()), AppPullPhase.waiting);
    expect(
      appPullPhaseOf(_answer(reasonCode: 'app_unreachable')),
      AppPullPhase.failed,
    );
    expect(
      appPullPhaseOf(
        _answer(
          status: EvidenceDecisionStatus.accepted,
          reasonCode: 'app_confirmed',
        ),
      ),
      AppPullPhase.accepted,
    );
    expect(
      appPullPhaseOf(
        _answer(
          status: EvidenceDecisionStatus.rejected,
          reasonCode: 'app_not_confirmed',
        ),
      ),
      AppPullPhase.rejected,
    );
    expect(
      appPullPhaseOf(
        _answer(
          status: EvidenceDecisionStatus.rejected,
          reasonCode: 'app_no_answer',
        ),
      ),
      AppPullPhase.unanswered,
    );
  });

  testWidgets('a push App keeps only the link code', (tester) async {
    await _pump(tester, requirement: appRequirement());

    expect(_ask, findsNothing);
    expect(find.byKey(VerilyTestKeys.actionLinkCodeOpen), findsOneWidget);
  });

  testWidgets('the creator sees no "I did it"', (tester) async {
    await _pump(tester, viewerIsCreator: true);

    expect(_ask, findsNothing);
  });

  testWidgets('"I did it" opens the attempt and asks without a note', (
    tester,
  ) async {
    final fakes = await _pump(tester);
    fakes.actions.onAskApp = (_) => _answer();

    expect(find.text(_l10n.actionPullIntro('Slopper')), findsOneWidget);
    await _tapAsk(tester);

    expect(fakes.actions.begun, [doUuid(_actionId)]);
    final request = fakes.actions.appRequests.single;
    expect(request.attemptId, doUuid(500));
    expect(request.requirementId, _pull.id);
    expect(request.reference, isNull);
    expect(find.text(_l10n.actionPullWaitingTitle('Slopper')), findsOneWidget);
    expect(_ask, findsNothing);
  });

  testWidgets('sends the trimmed note with the request', (tester) async {
    final fakes = await _pump(tester, myAttempt: _attempt());
    fakes.actions.onAskApp = (_) => _answer();

    await tester.enterText(_reference, '  ada_lovelace #1234  ');
    await _tapAsk(tester);

    expect(fakes.actions.begun, isEmpty);
    expect(fakes.actions.appRequests.single.reference, 'ada_lovelace #1234');
  });

  testWidgets('refuses a note the App could not be sent', (tester) async {
    final fakes = await _pump(tester, myAttempt: _attempt());
    fakes.actions.onAskApp = (_) => _answer();

    await tester.enterText(_reference, 'ada<script>');
    await _tapAsk(tester);

    expect(fakes.actions.appRequests, isEmpty);
    expect(find.text(_l10n.actionPullReferenceInvalid), findsOneWidget);
  });

  testWidgets('waiting turns into the verified outcome on its own', (
    tester,
  ) async {
    final fakes = await _pump(tester, myAttempt: _attempt());
    fakes.actions.onAskApp = (_) => _answer();
    await _tapAsk(tester);
    expect(_status, findsOneWidget);

    fakes.actions.myAttempts = [
      _attempt(status: ActionAttemptStatus.verified, accepted: true),
    ];
    await tester.pump(const Duration(seconds: 5));
    await settle(tester);

    expect(fakes.actions.listMyAttemptsCalls, greaterThan(0));
    expect(find.byKey(VerilyTestKeys.actionVerifiedOutcome), findsOneWidget);
    expect(find.text(_l10n.actionAppConfirmed('Slopper')), findsOneWidget);
    // Waiting for an answer asks the App only once.
    expect(fakes.actions.appRequests, hasLength(1));
  });

  testWidgets('a rejection while waiting says what to do next', (
    tester,
  ) async {
    final fakes = await _pump(tester, myAttempt: _attempt());
    fakes.actions.onAskApp = (_) => _answer();
    await _tapAsk(tester);

    fakes.actions.myAttempts = [
      _attempt(status: ActionAttemptStatus.rejected),
    ];
    await tester.pump(const Duration(seconds: 5));
    await settle(tester);

    expect(find.text(_l10n.actionPullRejectedTitle('Slopper')), findsOneWidget);
    expect(find.text(_l10n.actionPullRejectedBody('Slopper')), findsOneWidget);
  });

  testWidgets('an App that did not answer can be asked again', (tester) async {
    final fakes = await _pump(tester, myAttempt: _attempt());
    fakes.actions.onAskApp = (_) => _answer(reasonCode: 'app_unreachable');
    await _tapAsk(tester);

    expect(find.text(_l10n.actionPullFailedTitle('Slopper')), findsOneWidget);
    expect(find.text(_l10n.actionPullAskAgain), findsOneWidget);

    fakes.actions.onAskApp = (_) => _answer(
      status: EvidenceDecisionStatus.accepted,
      reasonCode: 'app_confirmed',
      attempt: _attempt(status: ActionAttemptStatus.verified, accepted: true),
    );
    await _tapAsk(tester);

    expect(fakes.actions.appRequests, hasLength(2));
    expect(find.byKey(VerilyTestKeys.actionVerifiedOutcome), findsOneWidget);
  });

  testWidgets('waiting keeps checking without asking the App again', (
    tester,
  ) async {
    final fakes = await _pump(tester, myAttempt: _attempt());
    fakes.actions.onAskApp = (_) => _answer();
    await _tapAsk(tester);

    expect(find.text(_l10n.actionPullWaitingTitle('Slopper')), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await settle(tester);
    expect(fakes.actions.appRequests, hasLength(1));
    expect(fakes.actions.listMyAttemptsCalls, greaterThan(0));
  });

  testWidgets('an App that never answered says so', (tester) async {
    final fakes = await _pump(tester, myAttempt: _attempt());
    fakes.actions.onAskApp = (_) => _answer(
      status: EvidenceDecisionStatus.rejected,
      reasonCode: 'app_no_answer',
    );
    await _tapAsk(tester);

    expect(
      find.text(_l10n.actionPullUnansweredTitle('Slopper')),
      findsOneWidget,
    );
    expect(_ask, findsNothing);
  });

  for (final (problem, message) in [
    (AppPlatformProblem.rateLimited, _l10n.appsRateLimited),
    (
      AppPlatformProblem.pullVerificationUnavailable,
      _l10n.actionPullUnavailable('Slopper'),
    ),
    (AppPlatformProblem.invalidReference, _l10n.actionPullReferenceInvalid),
  ]) {
    testWidgets('explains ${problem.name}', (tester) async {
      final fakes = await _pump(tester, myAttempt: _attempt());
      fakes.actions.onAskApp = (_) => throw AppPlatformException(
        problem: problem,
        message: 'server words',
      );

      await _tapAsk(tester);

      expect(find.text(message), findsOneWidget);
      expect(find.text('server words'), findsNothing);
      expect(_ask, findsOneWidget);
    });
  }
}
