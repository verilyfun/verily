import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/features/create/venue_code/venue_code_sheet.dart';
import 'package:verily_flutter/l10n/generated/app_localizations_en.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import '../../../support/test_app.dart';
import '../editor/support/fakes.dart';

final l10n = AppLocalizationsEn();
const _launch = ValueKey<String>('launch-venue-code');

final _door = ActionRequirementView(
  id: editorUuid(150),
  requirementKey: 'door',
  kind: ActionRequirementKind.qrCode,
  title: 'Scan at the door',
  instructions: 'Scan the code the host shows.',
  position: 0,
  isRequired: true,
);

Future<void> openVenueCode(
  WidgetTester tester,
  EditorFakes fakes, {
  Brightness brightness = Brightness.light,
}) async {
  final action = actionFixture(requirements: [_door]);
  await pumpVerilyPage(
    tester,
    Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            key: _launch,
            onPressed: () =>
                showVenueCode(context, action: action, requirement: _door),
            child: const Text('Show'),
          ),
        ),
      ),
    ),
    overrides: fakes.overrides,
    brightness: brightness,
    physicalSize: const Size(1080, 2400),
    devicePixelRatio: 2.625,
  );
  await tester.tap(find.byKey(_launch));
  await tester.pumpAndSettle();
}

Finder codeShown(String code) => find.byKey(ValueKey<String>(code));

void main() {
  testWidgets('shows the code, counts down, and swaps it when it expires', (
    tester,
  ) async {
    final fakes = EditorFakes(
      actions: FakeActionRepository(),
    );
    await openVenueCode(tester, fakes);

    expect(fakes.actions.qrRequests, [_door.id]);
    expect(codeShown('venue-code-1'), findsOneWidget);
    expect(find.byKey(VerilyTestKeys.venueCodeImage), findsOneWidget);
    expect(find.text(l10n.venueCodeBody), findsOneWidget);
    expect(find.text(l10n.venueCodeChangesIn('0:05')), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text(l10n.venueCodeChangesIn('0:04')), findsOneWidget);

    for (var second = 0; second < 5; second++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pump();
    expect(fakes.actions.qrRequests, hasLength(2));
    expect(codeShown('venue-code-1'), findsNothing);
    expect(codeShown('venue-code-2'), findsOneWidget);
    // The fresh code starts its own window, a second or so into it.
    final countdown = tester.widget<Text>(
      find.byKey(VerilyTestKeys.venueCodeCountdown),
    );
    expect(
      countdown.data,
      anyOf(l10n.venueCodeChangesIn('0:05'), l10n.venueCodeChangesIn('0:04')),
    );
  });

  testWidgets('a new code can be shown on demand', (tester) async {
    final fakes = EditorFakes(
      actions: FakeActionRepository(qrValidity: const Duration(minutes: 5)),
    );
    await openVenueCode(tester, fakes);
    expect(find.text(l10n.venueCodeChangesIn('5:00')), findsOneWidget);

    await tester.tap(find.byKey(VerilyTestKeys.venueCodeNew));
    await tester.pump();
    expect(codeShown('venue-code-2'), findsOneWidget);
  });

  testWidgets('a failed code offers to try again', (tester) async {
    final fakes = EditorFakes(
      actions: FakeActionRepository()
        ..qrError = ActionAuthoringException(
          reason: ActionAuthoringProblem.appUnavailable,
          message: 'No.',
        ),
    );
    await openVenueCode(tester, fakes);
    expect(find.text(l10n.venueCodeFailed), findsOneWidget);

    // A failure waits for the creator instead of retrying every second.
    await tester.pump(const Duration(seconds: 3));
    expect(fakes.actions.qrRequests, hasLength(1));

    fakes.actions.qrError = null;
    await tester.tap(find.text(l10n.dialogRetry));
    await tester.pump();
    expect(codeShown('venue-code-2'), findsOneWidget);
  });

  testWidgets('the code is ink on paper in dark mode too', (tester) async {
    await openVenueCode(tester, EditorFakes(), brightness: Brightness.dark);

    const paper = VerilyPalette.paper();
    final qr = tester.widget<QrImageView>(
      find.byKey(VerilyTestKeys.venueCodeImage),
    );
    expect(qr.backgroundColor, paper.surface);
    expect(qr.dataModuleStyle.color, paper.ink);
    expect(qr.eyeStyle.color, paper.ink);
  });
}
