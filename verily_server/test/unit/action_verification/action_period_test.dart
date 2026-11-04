import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/action_period.dart';
import 'package:verily_server/src/generated/protocol.dart';

void main() {
  group('actionPeriodEnd', () {
    test('ends a daily period at the next local midnight', () {
      expect(
        actionPeriodEnd(
          ActionRecurrence.daily,
          'UTC',
          DateTime.utc(2026, 10, 12, 23, 59),
        ),
        DateTime.utc(2026, 10, 13),
      );
      expect(
        actionPeriodEnd(
          ActionRecurrence.daily,
          'Asia/Tokyo',
          DateTime.utc(2026, 10, 12, 12),
        ),
        DateTime.utc(2026, 10, 12, 15),
      );
    });

    test('follows daylight-saving days of 23 and 25 hours', () {
      // Europe/London: 29 March 2026 has 23 hours, 25 October 2026 has 25.
      final spring = DateTime.utc(2026, 3, 29, 0, 30);
      expect(
        actionPeriodEnd(ActionRecurrence.daily, 'Europe/London', spring),
        DateTime.utc(2026, 3, 29, 23),
      );
      final autumn = DateTime.utc(2026, 10, 24, 23, 30);
      expect(
        actionPeriodEnd(ActionRecurrence.daily, 'Europe/London', autumn),
        DateTime.utc(2026, 10, 26),
      );
    });

    test('a once period never ends', () {
      expect(
        actionPeriodEnd(ActionRecurrence.once, 'UTC', DateTime.utc(2026)),
        isNull,
      );
      expect(
        actionPeriodKey(ActionRecurrence.once, 'UTC', DateTime.utc(2026)),
        onceActionPeriodKey,
      );
    });
  });

  group('time zones', () {
    test('an unknown name is not found, and is a bug when stored', () {
      expect(findActionTimeZone('Europe/London')?.name, 'Europe/London');
      expect(findActionTimeZone('Mars/Olympus_Mons'), isNull);
      expect(() => actionTimeZone('Mars/Olympus_Mons'), throwsArgumentError);
    });

    test('IANA link names that devices still report are found', () {
      for (final name in [
        'UTC',
        'GMT',
        'US/Eastern',
        'Europe/Kiev',
        'Asia/Calcutta',
      ]) {
        expect(findActionTimeZone(name), isNotNull, reason: name);
      }
    });
  });
}
