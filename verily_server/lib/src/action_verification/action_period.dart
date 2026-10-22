import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;
import 'package:verily_server/src/generated/protocol.dart';

/// Period key for a `once` action: one attempt for the action's lifetime.
const onceActionPeriodKey = 'once';

bool _timeZonesInitialized = false;

/// The attempt period an [instant] falls in for an action.
///
/// Daily actions use the calendar date (`YYYY-MM-DD`) in the action's IANA
/// [timeZone], so daylight-saving shifts never skip or repeat a day; `once`
/// actions always use [onceActionPeriodKey].
String actionPeriodKey(
  ActionRecurrence recurrence,
  String timeZone,
  DateTime instant,
) {
  if (recurrence == ActionRecurrence.once) return onceActionPeriodKey;
  final local = timezone.TZDateTime.from(
    instant.toUtc(),
    actionTimeZone(timeZone),
  );
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

/// The UTC instant at which the period containing [instant] ends: the next
/// local midnight for daily actions (23 or 25 hours away across a
/// daylight-saving change), or null for `once` actions, whose single period
/// never ends.
DateTime? actionPeriodEnd(
  ActionRecurrence recurrence,
  String timeZone,
  DateTime instant,
) {
  if (recurrence == ActionRecurrence.once) return null;
  final location = actionTimeZone(timeZone);
  final local = timezone.TZDateTime.from(instant.toUtc(), location);
  return timezone.TZDateTime(
    location,
    local.year,
    local.month,
    local.day + 1,
  ).toUtc();
}

/// Resolves a stored action's IANA time zone. Authoring refuses unknown
/// names, so one here is a bug: throws [ArgumentError].
timezone.Location actionTimeZone(String name) {
  return findActionTimeZone(name) ??
      (throw ArgumentError.value(name, 'timeZone', 'Unknown IANA time zone.'));
}

/// Resolves an IANA time zone, or null for an unknown name.
timezone.Location? findActionTimeZone(String name) {
  if (!_timeZonesInitialized) {
    timezone_data.initializeTimeZones();
    _timeZonesInitialized = true;
  }
  try {
    return timezone.getLocation(name);
  } on timezone.LocationNotFoundException {
    return null;
  }
}
