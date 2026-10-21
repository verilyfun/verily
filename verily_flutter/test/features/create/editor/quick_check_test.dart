import 'package:flutter_test/flutter_test.dart';
import 'package:skribble/skribble.dart' show WiredSwitch;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/features/create/editor/editor_form.dart';
import 'package:verily_flutter/l10n/generated/app_localizations_en.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import 'support/editor_harness.dart';
import 'support/fakes.dart';

final l10n = AppLocalizationsEn();

/// Opens the editor on the morning-walk template, whose "view" proof is a
/// video with a spoken word.
Future<EditorFakes> _openWalk(WidgetTester tester) async {
  final fakes = EditorFakes(
    actions: FakeActionRepository(templates: [walkTemplate()]),
  );
  await pumpEditor(tester, fakes);
  await scrollAndTap(
    tester,
    find.byKey(VerilyTestKeys.editorTemplate('morning-walk')),
  );
  return fakes;
}

ActionRequirementDraft _savedView(EditorFakes fakes) => fakes
    .actions
    .savedRequests
    .last
    .requirements
    .singleWhere((requirement) => requirement.requirementKey == 'view');

bool _spokenOn(WidgetTester tester) => tester
    .widget<WiredSwitch>(
      find.descendant(
        of: find.byKey(VerilyTestKeys.editorSpokenChallenge('view')),
        matching: find.byType(WiredSwitch),
      ),
    )
    .value;

void main() {
  testWidgets('adds a gesture check and turns the spoken word off', (
    tester,
  ) async {
    final fakes = await _openWalk(tester);
    expect(_spokenOn(tester), isTrue);

    await scrollAndTap(
      tester,
      find.byKey(VerilyTestKeys.editorQuickCheckAdd('view')),
    );

    expect(find.text(l10n.editorQuickCheckTitle), findsOneWidget);
    expect(_spokenOn(tester), isFalse);
    expect(find.text(l10n.editorQuickCheckSpokenHelp), findsOneWidget);
    expect(find.text(l10n.editorQuickCheckPromptHelp), findsOneWidget);

    await scrollAndTap(
      tester,
      find.byKey(VerilyTestKeys.editorQuickCheckGesture('view', 'Victory')),
    );
    await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorSave));

    final saved = _savedView(fakes);
    expect(saved.localCheck?.task, LocalCheckTask.gesture);
    expect(saved.localCheck?.label, 'Victory');
    expect(saved.localCheck?.minScore, 0.6);
    expect(saved.localCheck?.minFrames, 3);
    expect(saved.spokenChallengeRequired, isFalse);
    expect(saved.verificationPrompt, 'The video shows a park in daylight.');
  });

  testWidgets('picks a thing from the searchable list', (tester) async {
    final fakes = await _openWalk(tester);
    await scrollAndTap(
      tester,
      find.byKey(VerilyTestKeys.editorQuickCheckAdd('view')),
    );
    await scrollAndTap(
      tester,
      find.byKey(VerilyTestKeys.editorQuickCheckTask('view', 'object')),
    );
    expect(find.text('Cup'), findsOneWidget);

    await scrollAndTap(
      tester,
      find.byKey(VerilyTestKeys.editorQuickCheckPickLabel('view')),
    );
    expect(find.text(l10n.editorQuickCheckPickObject), findsOneWidget);
    await tester.enterText(
      find.byKey(VerilyTestKeys.editorQuickCheckSearch),
      'bicy',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(VerilyTestKeys.editorQuickCheckLabelOption('car')),
      findsNothing,
    );
    await tester.tap(
      find.byKey(VerilyTestKeys.editorQuickCheckLabelOption('bicycle')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bicycle'), findsOneWidget);
    await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorSave));
    expect(_savedView(fakes).localCheck?.label, 'bicycle');
    expect(_savedView(fakes).localCheck?.task, LocalCheckTask.object);
  });

  testWidgets('a search with no match says so', (tester) async {
    await _openWalk(tester);
    await scrollAndTap(
      tester,
      find.byKey(VerilyTestKeys.editorQuickCheckAdd('view')),
    );
    await scrollAndTap(
      tester,
      find.byKey(VerilyTestKeys.editorQuickCheckTask('view', 'object')),
    );
    await scrollAndTap(
      tester,
      find.byKey(VerilyTestKeys.editorQuickCheckPickLabel('view')),
    );
    await tester.enterText(
      find.byKey(VerilyTestKeys.editorQuickCheckSearch),
      'zzz',
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.editorQuickCheckNoMatches), findsOneWidget);
  });

  testWidgets('with a quick check the prompt may be left empty', (
    tester,
  ) async {
    final fakes = await _openWalk(tester);
    await scrollAndTap(
      tester,
      find.byKey(VerilyTestKeys.editorQuickCheckAdd('view')),
    );
    await scrollAndEnter(
      tester,
      find.byKey(VerilyTestKeys.editorVerifierPrompt('view')),
      '',
    );
    await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorSave));

    expect(find.text(l10n.editorVerifierPromptInvalid), findsNothing);
    expect(_savedView(fakes).verificationPrompt, isNull);
  });

  testWidgets('without one, an empty prompt is still refused', (tester) async {
    final fakes = await _openWalk(tester);
    await scrollAndEnter(
      tester,
      find.byKey(VerilyTestKeys.editorVerifierPrompt('view')),
      '',
    );
    await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorSave));

    expect(find.text(l10n.editorVerifierPromptInvalid), findsOneWidget);
    expect(fakes.actions.savedRequests, isEmpty);
  });

  testWidgets('removing the quick check saves none', (tester) async {
    final fakes = await _openWalk(tester);
    await scrollAndTap(
      tester,
      find.byKey(VerilyTestKeys.editorQuickCheckAdd('view')),
    );
    await scrollAndTap(
      tester,
      find.byKey(VerilyTestKeys.editorQuickCheckRemove('view')),
    );
    expect(
      find.byKey(VerilyTestKeys.editorQuickCheckAdd('view')),
      findsOneWidget,
    );

    await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorSave));
    expect(_savedView(fakes).localCheck, isNull);
  });

  testWidgets('a saved quick check comes back for editing', (tester) async {
    final saved = actionFixture(
      requirements: [
        for (final (index, draft) in walkTemplate().requirements.indexed)
          requirementViewFor(draft, index).copyWith(
            localCheck: draft.requirementKey == 'view'
                ? ActionLocalCheck(
                    task: LocalCheckTask.object,
                    label: 'dog',
                    minScore: 0.7,
                    minFrames: 5,
                  )
                : null,
            spokenChallengeRequired: false,
          ),
      ],
    );
    final fakes = EditorFakes(
      actions: FakeActionRepository(previews: {saved.id.uuid: saved})
        ..lastSaved = saved,
    );
    await pumpEditor(
      tester,
      fakes,
      initialLocation: VerilyLocations.actionEdit(saved.id.uuid),
    );

    expect(find.text('Dog'), findsOneWidget);
    expect(find.text(l10n.editorQuickCheckScore(70)), findsOneWidget);
    expect(find.text(l10n.editorQuickCheckFrames(5)), findsOneWidget);

    await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorSave));
    final check = _savedView(fakes).localCheck!;
    expect(check.label, 'dog');
    expect(check.minScore, 0.7);
    expect(check.minFrames, 5);
  });

  group('RequirementForm', () {
    test('a photo checks one frame and offers sight only', () {
      final photo = RequirementForm.blank(
        ProofKind.photo,
        requirementKey: 'snap',
        title: 'Snap it',
        instructions: 'Take the photo.',
      )..setLocalCheckTask(LocalCheckTask.object);
      final draft = photo.toDraft();
      expect(draft.localCheck?.minFrames, 1);
      expect(draft.localCheck?.label, 'cup');
      expect(draft.spokenChallengeRequired, isFalse);
    });

    test('an audio proof listens for a sound', () {
      final audio = RequirementForm.blank(
        ProofKind.audio,
        requirementKey: 'clap',
        title: 'Clap',
        instructions: 'Clap twice.',
      )..setLocalCheckTask(LocalCheckTask.sound);
      final draft = audio.toDraft();
      expect(draft.localCheck?.task, LocalCheckTask.sound);
      expect(draft.localCheck?.label, 'Clapping');
      expect(draft.spokenChallengeRequired, isFalse);
      expect(draft.verificationPrompt, isNull);
    });

    test('a proof that is not media never carries one', () {
      final place =
          RequirementForm.blank(
              ProofKind.location,
              requirementKey: 'park',
              title: 'Park',
              instructions: 'Be there.',
            )
            ..localCheck = ActionLocalCheck(
              task: LocalCheckTask.gesture,
              label: 'Thumb_Up',
              minScore: 0.6,
              minFrames: 3,
            );
      expect(place.toDraft().localCheck, isNull);
    });
  });

  testWidgets('an audio proof offers only a sound', (tester) async {
    await pumpEditor(tester, EditorFakes());
    await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorStartBlank));
    await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorAddProof));
    await scrollAndTap(
      tester,
      find.byKey(VerilyTestKeys.editorAddProofKind(ProofKind.audio.name)),
    );
    // An added proof is keyed by its kind.
    const key = 'audio';
    await scrollAndTap(
      tester,
      find.byKey(VerilyTestKeys.editorQuickCheckAdd(key)),
    );

    expect(
      find.byKey(VerilyTestKeys.editorQuickCheckTask(key, 'sound')),
      findsNothing,
    );
    expect(find.text('Clapping'), findsOneWidget);
    expect(find.text(l10n.editorQuickCheckFrames(3)), findsOneWidget);
  });
}
