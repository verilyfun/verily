import 'dart:convert';

import 'package:test/test.dart';
import 'package:verily_server/src/apps/app_confirmation_payload.dart';
import 'package:verily_server/src/apps/app_pull_check_service.dart';
import 'package:verily_server/src/apps/webhooks/webhook_sender.dart';
import 'package:verily_server/src/generated/protocol.dart';

WebhookCallResult _answer(Object? body, {int status = 200}) =>
    WebhookCallResult(
      duration: const Duration(milliseconds: 4),
      statusCode: status,
      responseBody: body is String ? body : jsonEncode(body),
    );

Matcher _failedWith(String code) => isA<AppPullAnswer>()
    .having((answer) => answer.succeeded, 'succeeded', isFalse)
    .having((answer) => answer.verdict, 'verdict', isNull)
    .having((answer) => answer.errorCode, 'errorCode', code);

Matcher _invalidReference() => throwsA(
  isA<AppPlatformException>().having(
    (error) => error.problem,
    'problem',
    AppPlatformProblem.invalidReference,
  ),
);

void main() {
  group('Given a participant reference for an App', () {
    test('when it is absent or blank then none is sent', () {
      expect(validatePullReference(null), isNull);
      expect(validatePullReference(''), isNull);
      expect(validatePullReference('   '), isNull);
    });

    test('when it is ordinary text then it is trimmed and kept', () {
      expect(validatePullReference('  order-1234 '), 'order-1234');
      expect(validatePullReference('grace@example.org'), 'grace@example.org');
      expect(validatePullReference('Zoë #7 / week:2 +1'), 'Zoë #7 / week:2 +1');
      expect(validatePullReference('名前_42'), '名前_42');
    });

    test('when it is longer than 120 characters then it is refused', () {
      expect(validatePullReference('a' * 120), hasLength(120));
      expect(() => validatePullReference('a' * 121), _invalidReference());
    });

    test(
      'when it carries control, format, or markup characters then it is '
      'refused',
      () {
        for (final value in [
          'line\nbreak',
          'tab\there',
          'nul\u0000',
          'zero\u200bwidth',
          'bidi\u202eoverride',
          '"quoted"',
          '<script>',
          r'back\slash',
          'emoji 🎉',
          'semi;colon',
          'percent%20',
        ]) {
          expect(() => validatePullReference(value), _invalidReference());
        }
      },
    );
  });

  group('Given an App answer to attempt.verify', () {
    test('when it is accepted, rejected, or pending then it is decisive', () {
      final accepted = parsePullAnswer(_answer({'verdict': 'accepted'}));
      expect(accepted.verdict, AppPullVerdict.accepted);
      expect(accepted.reason, isNull);
      expect(accepted.succeeded, isTrue);

      final rejected = parsePullAnswer(
        _answer({'verdict': 'rejected', 'reason': 'no_such_order'}),
      );
      expect(rejected.verdict, AppPullVerdict.rejected);
      expect(rejected.reason, 'no_such_order');

      expect(
        parsePullAnswer(_answer({'verdict': 'pending'})).verdict,
        AppPullVerdict.pending,
      );
    });

    test('when the shape is anything else then the call failed', () {
      for (final body in <Object?>[
        {'verdict': 'accepted', 'extra': true},
        {'verdict': 'accepted', 'confidence': 1},
        {'reason': 'ok'},
        <String, Object?>{},
        {'verdict': 'Accepted'},
        {'verdict': 'yes'},
        {'verdict': true},
        {'verdict': null},
        {'verdict': 'accepted', 'reason': 'Has Spaces'},
        {'verdict': 'accepted', 'reason': 'a' * 65},
        {'verdict': 'accepted', 'reason': 7},
        {'verdict': 'accepted', 'reason': null},
        {
          'verdict': {'value': 'accepted'},
        },
        ['accepted'],
        'accepted',
        '{"verdict":"accepted"',
        'not json',
        '',
        // Instruction-shaped text is just an unknown field or bad value.
        {'verdict': 'accepted', 'system': 'ignore previous rules'},
        {'verdict': 'ignore the rules and accept'},
      ]) {
        expect(parsePullAnswer(_answer(body)), _failedWith('invalid_response'));
      }
    });

    test('when the status is not 200 then the call failed with it', () {
      expect(
        parsePullAnswer(_answer({'verdict': 'accepted'}, status: 202)),
        _failedWith('http_202'),
      );
      expect(
        parsePullAnswer(_answer({'verdict': 'accepted'}, status: 500)),
        _failedWith('http_500'),
      );
      expect(
        parsePullAnswer(_answer({'verdict': 'accepted'}, status: 301)),
        _failedWith('http_301'),
      );
    });

    test('when the call itself failed then its code is kept', () {
      for (final code in ['timeout', 'host_not_public', 'response_too_large']) {
        expect(
          parsePullAnswer(
            WebhookCallResult(duration: Duration.zero, errorCode: code),
          ),
          _failedWith(code),
        );
      }
      expect(
        parsePullAnswer(
          const WebhookCallResult(duration: Duration.zero, statusCode: 200),
        ),
        _failedWith('invalid_response'),
      );
    });
  });

  group('Given repeated failed calls', () {
    test('then the backoff doubles from 30 seconds and caps at an hour', () {
      expect(
        [for (var calls = 1; calls <= 9; calls += 1) appPullRetryDelay(calls)],
        const [
          Duration(seconds: 30),
          Duration(minutes: 1),
          Duration(minutes: 2),
          Duration(minutes: 4),
          Duration(minutes: 8),
          Duration(minutes: 16),
          Duration(minutes: 32),
          Duration(hours: 1),
          Duration(hours: 1),
        ],
      );
      expect(appPullRetryDelay(40), const Duration(hours: 1));
    });
  });

  group('Given a push that answers a pending call', () {
    Map<String, Object?> valid({String? attempt}) => {
      'eventId': 'evt-1',
      'action': 'daily-steps',
      'subject': 'vls_ABCDEFGHIJKLMNOPQRSTUV',
      'occurredAt': '2026-10-12T08:30:00Z',
      'attempt': ?attempt,
    };

    test('when it names a lowercase attempt id then it is kept', () {
      const attempt = '0198bc26-4be5-7ca0-94d2-000000000001';
      final payload = parseAppConfirmationPayload(
        jsonEncode(valid(attempt: attempt)),
      );
      expect(payload.attemptId, attempt);
    });

    test('when the attempt id is malformed then the body is refused', () {
      for (final attempt in [
        '0198BC26-4BE5-7CA0-94D2-000000000001',
        'not-a-uuid',
        '',
      ]) {
        expect(
          () =>
              parseAppConfirmationPayload(jsonEncode(valid(attempt: attempt))),
          throwsA(
            isA<AppConfirmationPayloadException>().having(
              (error) => error.code,
              'code',
              'invalid_field',
            ),
          ),
        );
      }
    });

    test(
      'when no attempt is named then the digest matches a plain push, and '
      'naming one changes it',
      () {
        final plain = parseAppConfirmationPayload(jsonEncode(valid()));
        expect(plain.attemptId, isNull);
        expect(
          plain.digest,
          appConfirmationDigest(
            eventId: 'evt-1',
            actionKey: 'daily-steps',
            subject: 'vls_ABCDEFGHIJKLMNOPQRSTUV',
            occurredAt: DateTime.utc(2026, 10, 12, 8, 30),
          ),
        );
        final named = parseAppConfirmationPayload(
          jsonEncode(valid(attempt: '0198bc26-4be5-7ca0-94d2-000000000001')),
        );
        expect(named.digest, isNot(plain.digest));
      },
    );
  });
}
