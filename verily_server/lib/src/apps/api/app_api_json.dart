import 'dart:convert';

/// A request body that failed strict validation. [code] is stable and
/// documented; [message] names the field and the rule, never the value.
final class AppApiSchemaException implements Exception {
  const AppApiSchemaException(this.code, this.message);

  /// `invalid_json`, `unknown_field`, `missing_field`, or `invalid_field`.
  final String code;
  final String message;

  @override
  String toString() => 'AppApiSchemaException($code)';
}

/// Strict reader for one JSON object in an App API request.
///
/// Unknown fields are refused, types are exact (an integer is never a
/// fraction or a string), strings are bounded, and an optional field may be
/// omitted or null. Values are never echoed into errors.
final class StrictJsonObject {
  StrictJsonObject._(this._json, this._path);

  /// Decodes [body] as a single JSON object whose keys are all in [allowed].
  factory StrictJsonObject.parse(String body, {required Set<String> allowed}) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw const AppApiSchemaException(
        'invalid_json',
        'The body must be a JSON object.',
      );
    }
    return StrictJsonObject.of(decoded, allowed: allowed, path: '');
  }

  /// Wraps an already decoded value, which must be an object of [allowed]
  /// keys. [path] prefixes field names in messages (`requirements[0].`).
  factory StrictJsonObject.of(
    Object? value, {
    required Set<String> allowed,
    required String path,
  }) {
    if (value is! Map<String, Object?>) {
      throw AppApiSchemaException(
        'invalid_json',
        path.isEmpty
            ? 'The body must be a JSON object.'
            : '${path.substring(0, path.length - 1)} must be a JSON object.',
      );
    }
    if (value.keys.any((key) => !allowed.contains(key))) {
      final sorted = allowed.toList()..sort();
      throw AppApiSchemaException(
        'unknown_field',
        '${path.isEmpty ? 'The body' : path.substring(0, path.length - 1)} '
            'accepts only: ${sorted.join(', ')}.',
      );
    }
    return StrictJsonObject._(value, path);
  }

  final Map<String, Object?> _json;
  final String _path;

  String _name(String field) => '$_path$field';

  Object? _required(String field) {
    final value = _json[field];
    if (value == null) {
      throw AppApiSchemaException(
        'missing_field',
        '${_name(field)} is required.',
      );
    }
    return value;
  }

  AppApiSchemaException _invalid(String field, String rule) =>
      AppApiSchemaException('invalid_field', '${_name(field)} $rule.');

  String string(
    String field, {
    required int maxLength,
    int minLength = 1,
    RegExp? pattern,
  }) {
    final value = _required(field);
    if (value is! String ||
        value.length < minLength ||
        value.length > maxLength ||
        (pattern != null && !pattern.hasMatch(value))) {
      throw _invalid(
        field,
        pattern == null
            ? 'must be a string of $minLength to $maxLength characters'
            : 'has an invalid format',
      );
    }
    return value;
  }

  String? optionalString(
    String field, {
    required int maxLength,
    int minLength = 1,
    RegExp? pattern,
  }) => _json[field] == null
      ? null
      : string(
          field,
          maxLength: maxLength,
          minLength: minLength,
          pattern: pattern,
        );

  /// One of [allowed] values.
  String choice(String field, Set<String> allowed) {
    final value = _required(field);
    if (value is! String || !allowed.contains(value)) {
      final sorted = allowed.toList()..sort();
      throw _invalid(field, 'must be one of ${sorted.join(', ')}');
    }
    return value;
  }

  String? optionalChoice(String field, Set<String> allowed) =>
      _json[field] == null ? null : choice(field, allowed);

  int integer(String field, {required int min, required int max}) {
    final value = _required(field);
    if (value is! int || value < min || value > max) {
      throw _invalid(field, 'must be a whole number from $min to $max');
    }
    return value;
  }

  int? optionalInteger(String field, {required int min, required int max}) =>
      _json[field] == null ? null : integer(field, min: min, max: max);

  bool? optionalBoolean(String field) {
    final value = _json[field];
    if (value == null) return null;
    if (value is! bool) throw _invalid(field, 'must be true or false');
    return value;
  }

  /// An RFC 3339 date-time with an explicit offset, returned in UTC.
  DateTime? optionalDateTime(String field) {
    final value = _json[field];
    if (value == null) return null;
    final parsed = value is String ? parseRfc3339(value) : null;
    if (parsed == null) {
      throw _invalid(field, 'must be an RFC 3339 date-time with an offset');
    }
    return parsed;
  }

  /// A list of [minLength] to [maxLength] objects.
  List<Object?> list(
    String field, {
    required int minLength,
    required int maxLength,
  }) {
    final value = _required(field);
    if (value is! List<Object?> ||
        value.length < minLength ||
        value.length > maxLength) {
      throw _invalid(
        field,
        minLength == maxLength
            ? 'must contain exactly $minLength item${minLength == 1 ? '' : 's'}'
            : 'must contain $minLength to $maxLength items',
      );
    }
    return value;
  }
}

// RFC 3339 date-time with an explicit offset and at most microsecond
// precision, which is what Dart's DateTime can represent exactly.
final RegExp _rfc3339Pattern = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(\.\d{1,6})?'
  r'(Z|[+-](\d{2}):(\d{2}))$',
);

/// Parses an RFC 3339 date-time with an explicit offset, or returns null.
/// Every component is range-checked first: Dart's parser would silently roll
/// month 13 over into January.
DateTime? parseRfc3339(String value) {
  final match = _rfc3339Pattern.firstMatch(value);
  if (match == null) return null;
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
  return valid ? DateTime.tryParse(value)?.toUtc() : null;
}
