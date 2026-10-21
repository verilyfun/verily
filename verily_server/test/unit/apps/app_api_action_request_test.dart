import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/apps/api/app_api_action_request.dart';
import 'package:verily_server/src/apps/api/app_api_json.dart';
import 'package:verily_server/src/generated/protocol.dart';

Map<String, Object?> _valid() => {
  'actionKey': 'daily-situps',
  'title': 'Daily sit-ups',
  'description': 'Do your sit-ups and the app confirms them.',
  'recurrence': 'daily',
  'timeZone': 'Europe/London',
  'requirements': [
    {
      'requirementKey': 'situps',
      'title': 'Do the sit-ups',
      'instructions': 'Finish the set in the app.',
    },
  ],
};

Matcher _schemaError(String code, [String? messagePart]) => throwsA(
  isA<AppApiSchemaException>()
      .having((error) => error.code, 'code', code)
      .having(
        (error) => error.message,
        'message',
        messagePart == null ? anything : contains(messagePart),
      ),
);

void main() {
  group('Given an App action body', () {
    test('when it has only required fields then defaults apply', () {
      final request = parseAppApiActionRequest(jsonEncode(_valid()));

      expect(request.actionKey, 'daily-situps');
      expect(request.recurrence, ActionRecurrence.daily);
      expect(request.maxVerifiedCompletions, isNull);
      expect(request.opensAt, isNull);
      final requirement = request.requirements.single;
      expect(requirement.isRequired, isTrue);
      expect(requirement.verification, AppVerificationMode.push);
    });

    test('when every optional field is set then they are typed', () {
      final request = parseAppApiActionRequest(
        jsonEncode({
          ..._valid(),
          'maxVerifiedCompletions': 100,
          'opensAt': '2026-10-21T09:00:00+01:00',
          'closesAt': null,
          'requirements': [
            {
              'requirementKey': 'situps',
              'title': 'Do the sit-ups',
              'instructions': 'Finish the set in the app.',
              'isRequired': true,
              'verification': 'pull',
            },
          ],
        }),
      );

      expect(request.maxVerifiedCompletions, 100);
      expect(request.opensAt, DateTime.utc(2026, 10, 21, 8));
      expect(request.closesAt, isNull);
      expect(
        request.requirements.single.verification,
        AppVerificationMode.pull,
      );
    });

    test('when converted then every requirement binds to the calling App', () {
      final appId = UuidValue.withValidation(
        '0198bc26-4be5-7ca0-94d2-000000000001',
      );
      final draft = parseAppApiActionRequest(
        jsonEncode(_valid()),
      ).toDefinitionRequest(appId);

      expect(draft.reward, isNull);
      final requirement = draft.requirements.single;
      expect(requirement.kind, ActionRequirementKind.externalApp);
      expect(requirement.appId, appId);
      expect(requirement.appVerificationMode, AppVerificationMode.push);
    });

    test('when the body is not an object then it is invalid JSON', () {
      expect(
        () => parseAppApiActionRequest('[1]'),
        _schemaError('invalid_json'),
      );
      expect(
        () => parseAppApiActionRequest('{'),
        _schemaError('invalid_json'),
      );
    });

    test('when it carries an unknown field then it is refused', () {
      expect(
        () => parseAppApiActionRequest(
          jsonEncode({
            ..._valid(),
            'reward': {'amountPerPayout': 1},
          }),
        ),
        _schemaError('unknown_field', 'accepts only'),
      );
      expect(
        () => parseAppApiActionRequest(
          jsonEncode({
            ..._valid(),
            'requirements': [
              {
                'requirementKey': 'situps',
                'title': 'Do the sit-ups',
                'instructions': 'Finish the set in the app.',
                'appId': '0198bc26-4be5-7ca0-94d2-000000000001',
              },
            ],
          }),
        ),
        _schemaError('unknown_field', 'requirements[0]'),
      );
    });

    test('when a required field is missing then it is named', () {
      expect(
        () => parseAppApiActionRequest(
          jsonEncode(Map.of(_valid())..remove('title')),
        ),
        _schemaError('missing_field', 'title is required'),
      );
    });

    test('when types or bounds are wrong then each field is refused', () {
      for (final (field, value) in [
        ('actionKey', 'Daily Situps'),
        ('actionKey', 'ab'),
        ('title', ''),
        ('title', 'x' * 121),
        ('description', 7),
        ('recurrence', 'weekly'),
        ('timeZone', 'x' * 65),
        ('maxVerifiedCompletions', 0),
        ('maxVerifiedCompletions', 1.5),
        ('maxVerifiedCompletions', '10'),
        ('opensAt', '2026-13-01T00:00:00Z'),
        ('opensAt', '2026-10-21T09:00:00'),
        ('opensAt', 1791820800),
        ('requirements', <Object?>[]),
        ('requirements', [_valid()['requirements'], _valid()['requirements']]),
        ('requirements', 'situps'),
      ]) {
        expect(
          () =>
              parseAppApiActionRequest(jsonEncode({..._valid(), field: value})),
          throwsA(isA<AppApiSchemaException>()),
          reason: '$field = $value',
        );
      }
    });

    test('when a requirement field is wrong then the path is named', () {
      for (final (field, value) in [
        ('requirementKey', 'Situps!'),
        ('instructions', 'x' * 1001),
        ('isRequired', 'yes'),
        ('verification', 'webhook'),
      ]) {
        final requirement = {
          'requirementKey': 'situps',
          'title': 'Do the sit-ups',
          'instructions': 'Finish the set in the app.',
          field: value,
        };
        expect(
          () => parseAppApiActionRequest(
            jsonEncode({
              ..._valid(),
              'requirements': [requirement],
            }),
          ),
          _schemaError('invalid_field', 'requirements[0].$field'),
          reason: field,
        );
      }
    });

    test('when an error is raised then the value is never echoed', () {
      const secret = 'leaked-value-should-not-appear';
      try {
        parseAppApiActionRequest(
          jsonEncode({..._valid(), 'timeZone': secret * 4}),
        );
        fail('expected a schema error');
      } on AppApiSchemaException catch (error) {
        expect(error.message, isNot(contains(secret)));
      }
    });
  });

  group('Given a lifecycle body', () {
    test('when it names a revision then it is returned', () {
      expect(parseAppApiLifecycleRequest('{"expectedRevision": 3}'), 3);
    });

    test('when it is missing, fractional, or extended then it is refused', () {
      expect(
        () => parseAppApiLifecycleRequest('{}'),
        _schemaError('missing_field'),
      );
      expect(
        () => parseAppApiLifecycleRequest('{"expectedRevision": 0}'),
        _schemaError('invalid_field'),
      );
      expect(
        () => parseAppApiLifecycleRequest('{"expectedRevision": 1.0}'),
        _schemaError('invalid_field'),
      );
      expect(
        () => parseAppApiLifecycleRequest(
          '{"expectedRevision": 1, "status": "active"}',
        ),
        _schemaError('unknown_field'),
      );
    });
  });

  group('Given RFC 3339 times', () {
    test('when components are in range then they parse to UTC', () {
      expect(
        parseRfc3339('2026-02-28T23:59:59.123456-05:00'),
        DateTime.utc(2026, 3, 1, 4, 59, 59, 123, 456),
      );
    });

    test('when a component rolls over then it is refused', () {
      for (final value in [
        '2026-02-29T00:00:00Z',
        '2026-10-21T24:00:00Z',
        '2026-10-21T10:60:00Z',
        '2026-10-21T10:00:00+24:00',
        '2026-10-21 10:00:00Z',
      ]) {
        expect(parseRfc3339(value), isNull, reason: value);
      }
    });
  });
}
