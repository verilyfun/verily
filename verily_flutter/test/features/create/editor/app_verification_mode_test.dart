import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/features/create/editor/editor_form.dart';
import 'package:verily_flutter/l10n/generated/app_localizations_en.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import 'support/editor_harness.dart';
import 'support/fakes.dart';

final _l10n = AppLocalizationsEn();
const _key = 'app-confirmation';

Finder _mode(AppVerificationMode mode) =>
    find.byKey(VerilyTestKeys.editorAppMode(_key, mode.name));

bool _isSelected(WidgetTester tester, AppVerificationMode mode) =>
    tester.widget<ChoiceChip>(_mode(mode)).selected;

ActionRequirementView _appRequirement(AppVerificationMode? mode) =>
    ActionRequirementView(
      id: editorUuid(150),
      requirementKey: _key,
      kind: ActionRequirementKind.externalApp,
      title: 'Bake in Slopper',
      instructions: 'Finish a loaf in Slopper.',
      position: 0,
      isRequired: true,
      appId: editorUuid(900),
      appName: 'Slopper',
      appAvailable: true,
      appVerificationMode: mode,
    );

Future<EditorFakes> _editSaved(
  WidgetTester tester, {
  AppVerificationMode? mode,
  String? webhookUrl = 'https://slopper.example/verily',
}) async {
  final saved = actionFixture(requirements: [_appRequirement(mode)]);
  final fakes = EditorFakes(
    actions: FakeActionRepository(previews: {saved.id.uuid: saved})
      ..lastSaved = saved,
    apps: FakeAppsRepository(
      apps: [appFixture().copyWith(webhookUrl: webhookUrl)],
    ),
  );
  await pumpEditor(
    tester,
    fakes,
    initialLocation: VerilyLocations.actionEdit(saved.id.uuid),
  );
  return fakes;
}

void main() {
  test('a requirement form sends its mode only for App proof', () {
    final app = RequirementForm.fromView(
      _appRequirement(AppVerificationMode.pull),
    );
    expect(app.toDraft().appVerificationMode, AppVerificationMode.pull);

    final unset = RequirementForm.fromView(_appRequirement(null));
    expect(unset.appVerificationMode, AppVerificationMode.push);

    final photo = RequirementForm.blank(
      ProofKind.photo,
      requirementKey: 'photo',
      title: 'A photo',
      instructions: 'Take it.',
    )..appVerificationMode = AppVerificationMode.pull;
    expect(photo.toDraft().appVerificationMode, isNull);
  });

  testWidgets('a saved pull proof opens as pull and saves a switch to push', (
    tester,
  ) async {
    final fakes = await _editSaved(tester, mode: AppVerificationMode.pull);

    await tester.ensureVisible(_mode(AppVerificationMode.pull));
    expect(_isSelected(tester, AppVerificationMode.pull), isTrue);
    expect(find.text(_l10n.editorAppModePullBody('Slopper')), findsOneWidget);

    await scrollAndTap(tester, _mode(AppVerificationMode.push));
    expect(_isSelected(tester, AppVerificationMode.push), isTrue);
    expect(find.text(_l10n.editorAppModePushBody('Slopper')), findsOneWidget);

    await scrollAndTap(tester, find.byKey(VerilyTestKeys.editorSave));
    final draft = fakes.actions.savedRequests.single.requirements.single;
    expect(draft.appVerificationMode, AppVerificationMode.push);
  });

  testWidgets('pull warns when the App has no webhook address', (
    tester,
  ) async {
    await _editSaved(tester, webhookUrl: null);

    expect(find.byKey(VerilyTestKeys.editorAppModeNeedsWebhook), findsNothing);
    await scrollAndTap(tester, _mode(AppVerificationMode.pull));

    expect(
      find.text(_l10n.editorAppModePullNeedsWebhook('Slopper')),
      findsOneWidget,
    );
  });

  testWidgets('pull with a webhook address has nothing to warn about', (
    tester,
  ) async {
    await _editSaved(tester, mode: AppVerificationMode.pull);

    expect(find.byKey(VerilyTestKeys.editorAppModeNeedsWebhook), findsNothing);
  });
}
