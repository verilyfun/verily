import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Largest accepted delivery body, in bytes.
const int appConfirmationMaxBytes = 16 * 1024;

/// Allowed clock difference for the `Verily-Timestamp` header.
const appConfirmationTimestampTolerance = Duration(minutes: 5);

/// How far ahead of the server clock `occurredAt` may be.
const appConfirmationMaxFutureSkew = Duration(minutes: 5);

/// How long after `occurredAt` a confirmation is still accepted.
const appConfirmationMaxEventAge = Duration(hours: 24);

/// How long after a daily period ends a confirmation may still count for it.
/// Beyond this a back-dated event is rejected as `occurred_outside_period`,
/// so a single burst can never credit more than the current and previous
/// period.
const appConfirmationLatePeriodGrace = Duration(hours: 2);

const Set<String> _fields = {'eventId', 'action', 'subject', 'occurredAt'};
final RegExp _eventIdPattern = RegExp(r'^[A-Za-z0-9._:-]{1,128}$');
final RegExp _actionKeyPattern = RegExp(r'^[a-z0-9][a-z0-9-]{1,62}[a-z0-9]$');
final RegExp _subjectPattern = RegExp(r'^vls_[A-Za-z0-9_-]{22}$');
// RFC 3339 date-time with an explicit offset and at most microsecond
// precision, which is what Dart's DateTime can represent exactly.
final RegExp _rfc3339Pattern = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(\.\d{1,6})?'
  r'(Z|[+-](\d{2}):(\d{2}))$',
);
final RegExp _timestampPattern = RegExp(r'^[0-9]{1,12}$');

/// A body that failed strict validation. [code] is a stable, documented
/// machine-readable reason; [message] explains it to the integrator.
final class AppConfirmationPayloadException implements Exception {
  const AppConfirmationPayloadException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'AppConfirmationPayloadException($code)';
}

/// One validated App confirmation.
final class AppConfirmationPayload {
  const AppConfirmationPayload({
    required this.eventId,
    required this.actionKey,
    required this.subject,
    required this.occurredAt,
    required this.digest,
  });

  final String eventId;
  final String actionKey;
  final String subject;

  /// UTC instant the participant performed the action.
  final DateTime occurredAt;

  /// SHA-256 of the normalized fields. Formatting, key order, and equivalent
  /// time offsets do not change it, so only a semantic change conflicts.
  final String digest;
}

/// Parses `{"eventId","action","subject","occurredAt"}`, rejecting unknown,
/// missing, or mistyped fields.
AppConfirmationPayload parseAppConfirmationPayload(String body) {
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    throw const AppConfirmationPayloadException(
      'invalid_json',
      'The body must be a JSON object.',
    );
  }
  if (decoded is! Map<String, Object?>) {
    throw const AppConfirmationPayloadException(
      'invalid_json',
      'The body must be a JSON object.',
    );
  }
  final unknown = decoded.keys.where((key) => !_fields.contains(key));
  if (unknown.isNotEmpty) {
    throw const AppConfirmationPayloadException(
      'unknown_field',
      'Only eventId, action, subject, and occurredAt are accepted.',
    );
  }
  final eventId = _string(decoded, 'eventId', _eventIdPattern);
  final actionKey = _string(decoded, 'action', _actionKeyPattern);
  final subject = _string(decoded, 'subject', _subjectPattern);
  final occurredAt = _rfc3339(
    _string(decoded, 'occurredAt', _rfc3339Pattern),
  );
  return AppConfirmationPayload(
    eventId: eventId,
    actionKey: actionKey,
    subject: subject,
    occurredAt: occurredAt,
    digest: appConfirmationDigest(
      eventId: eventId,
      actionKey: actionKey,
      subject: subject,
      occurredAt: occurredAt,
    ),
  );
}

/// SHA-256 over the canonical form: sorted keys, UTC microsecond time.
String appConfirmationDigest({
  required String eventId,
  required String actionKey,
  required String subject,
  required DateTime occurredAt,
}) {
  final canonical = jsonEncode({
    'action': actionKey,
    'eventId': eventId,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    'subject': subject,
  });
  return sha256.convert(utf8.encode(canonical)).toString();
}

/// Whether a `Verily-Timestamp` header (unix seconds) is within
/// [appConfirmationTimestampTolerance] of [now].
bool appTimestampIsFresh(String? header, DateTime now) {
  final value = header?.trim();
  if (value == null || !_timestampPattern.hasMatch(value)) return false;
  final sent = DateTime.fromMillisecondsSinceEpoch(
    int.parse(value) * 1000,
    isUtc: true,
  );
  return now.toUtc().difference(sent).abs() <=
      appConfirmationTimestampTolerance;
}

/// Whether [occurredAt] is recent enough and not implausibly in the future.
bool appConfirmationTimeIsAcceptable(DateTime occurredAt, DateTime now) {
  final current = now.toUtc();
  return !occurredAt.isAfter(current.add(appConfirmationMaxFutureSkew)) &&
      !occurredAt.isBefore(current.subtract(appConfirmationMaxEventAge));
}

/// Dart's parser silently rolls over out-of-range parts (month 13 becomes
/// January), so every component is range-checked before parsing.
DateTime _rfc3339(String value) {
  final match = _rfc3339Pattern.firstMatch(value)!;
  int part(int group) => int.parse(match.group(group) ?? '0');
  final year = part(1);
  final month = part(2);
  final day = part(3);
  final valid =
      month >= 1 &&
      month <= 12 &&
      day >= 1 &&
      day <= DateTime.utc(year, month + 1, 0).day &&
      part(4) <= 23 &&
      part(5) <= 59 &&
      part(6) <= 59 &&
      part(9) <= 23 &&
      part(10) <= 59;
  final parsed = valid ? DateTime.tryParse(value) : null;
  if (parsed == null) {
    throw const AppConfirmationPayloadException(
      'invalid_field',
      'occurredAt must be an RFC 3339 date-time with an offset.',
    );
  }
  return parsed.toUtc();
}

String _string(Map<String, Object?> json, String field, RegExp pattern) {
  final value = json[field];
  if (value == null) {
    throw AppConfirmationPayloadException(
      'missing_field',
      '$field is required.',
    );
  }
  if (value is! String || !pattern.hasMatch(value)) {
    throw AppConfirmationPayloadException(
      'invalid_field',
      '$field has an invalid format.',
    );
  }
  return value;
}
