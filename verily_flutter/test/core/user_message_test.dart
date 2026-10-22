import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/core/user_message.dart';
import 'package:verily_flutter/l10n/generated/app_localizations_en.dart';

final _l10n = AppLocalizationsEn();

void main() {
  test('an action refused as invalid shows the app copy, not the rule', () {
    final error = ActionAuthoringException(
      reason: ActionAuthoringProblem.invalidRequest,
      message: 'closesAt must be after opensAt.',
    );

    expect(userMessageFor(_l10n, error), _l10n.errorActionInvalid);
  });

  test('an action refused for unsafe text shows the app copy', () {
    final error = ActionAuthoringException(
      reason: ActionAuthoringProblem.unsafeText,
      message: 'Some of this text cannot be used. Rephrase it.',
    );

    expect(userMessageFor(_l10n, error), _l10n.errorActionUnsafeText);
  });

  test('other authoring refusals still show the server message', () {
    final error = ActionAuthoringException(
      reason: ActionAuthoringProblem.actionKeyTaken,
      message: 'You already use that action key.',
    );

    expect(userMessageFor(_l10n, error), 'You already use that action key.');
  });

  test('anything untyped becomes the generic message', () {
    expect(
      userMessageFor(_l10n, StateError('socket closed')),
      _l10n.errorGeneric,
    );
  });
}
