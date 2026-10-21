import 'dart:convert';

import 'package:verily_server/src/action_verification/action_requirement_rules.dart';
import 'package:verily_server/src/action_verification/model_input_security.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// Shortest and longest life of a verification request.
const minVerificationRequestSeconds = 60;
const maxVerificationRequestSeconds = 3600;

/// Longest instructions shown to the person.
const maxVerificationInstructionsLength = 280;

/// Longest opaque `state` returned to the App unchanged.
const maxVerificationStateLength = 256;

const Set<String> _requiredFields = {
  'kind',
  'check',
  'shareEvidence',
  'redirectUri',
  'expiresInSeconds',
};
const Set<String> _optionalFields = {
  'instructions',
  'place',
  'liveChallenge',
  'state',
};

/// The App's place, private to Verily.
final class VerificationPlace {
  const VerificationPlace({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final double latitude;
  final double longitude;
  final double radiusMeters;
}

/// A validated `POST /api/v1/verification-requests` body.
final class VerificationRequestPayload {
  const VerificationRequestPayload({
    required this.kind,
    required this.check,
    required this.spokenChallenge,
    required this.shareEvidence,
    required this.redirectUri,
    required this.expiresIn,
    this.instructions,
    this.place,
    this.state,
  });

  final VerificationRequestKind kind;
  final VerificationRequestCheck check;
  final String? instructions;
  final VerificationPlace? place;
  final bool spokenChallenge;
  final bool shareEvidence;
  final String redirectUri;
  final String? state;
  final Duration expiresIn;
}

/// A body that failed strict validation. [code] and [field] are stable;
/// [message] never echoes the submitted value.
final class VerificationRequestPayloadException implements Exception {
  const VerificationRequestPayloadException(
    this.code,
    this.message, {
    this.field,
  });

  final String code;
  final String message;
  final String? field;

  @override
  String toString() => 'VerificationRequestPayloadException($code, $field)';
}

/// Parses and validates a verification request body with no unknown,
/// missing, null, or mistyped fields. Instructions pass the central
/// model-input policy because they become the verifier's text for a
/// `content` check.
VerificationRequestPayload parseVerificationRequestPayload(String body) {
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    throw const VerificationRequestPayloadException(
      'invalid_json',
      'The body must be a JSON object.',
    );
  }
  if (decoded is! Map<String, Object?>) {
    throw const VerificationRequestPayloadException(
      'invalid_json',
      'The body must be a JSON object.',
    );
  }
  for (final key in decoded.keys) {
    if (!_requiredFields.contains(key) && !_optionalFields.contains(key)) {
      throw const VerificationRequestPayloadException(
        'unknown_field',
        'The body contains a field this endpoint does not accept.',
      );
    }
    if (decoded[key] == null) {
      throw const VerificationRequestPayloadException(
        'invalid_field',
        'Omit optional fields instead of sending null.',
      );
    }
  }
  for (final key in _requiredFields) {
    if (!decoded.containsKey(key)) {
      throw VerificationRequestPayloadException(
        'missing_field',
        'A required field is missing.',
        field: key,
      );
    }
  }

  final kind = switch (decoded['kind']) {
    'video' => VerificationRequestKind.video,
    'photo' => VerificationRequestKind.photo,
    'audio' => VerificationRequestKind.audio,
    'location' => VerificationRequestKind.location,
    _ => throw _invalid(
      'kind',
      'kind must be video, photo, audio, or location.',
    ),
  };
  final check = switch (decoded['check']) {
    'captureOnly' => VerificationRequestCheck.captureOnly,
    'content' => VerificationRequestCheck.content,
    _ => throw _invalid('check', 'check must be captureOnly or content.'),
  };

  String? instructions;
  if (decoded['instructions'] case final Object value) {
    if (value is! String) {
      throw _invalid('instructions', 'instructions must be a string.');
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.length > maxVerificationInstructionsLength) {
      throw _invalid(
        'instructions',
        'instructions must be 1 to $maxVerificationInstructionsLength '
            'characters.',
      );
    }
    try {
      ModelInputSecurity.validateVerificationPolicy(
        verificationRequestPrompt(trimmed),
      );
    } on ModelInputSecurityException {
      throw const VerificationRequestPayloadException(
        'unsafe_instructions',
        'The instructions cannot be used for verification.',
        field: 'instructions',
      );
    }
    instructions = trimmed;
  }
  if (check == VerificationRequestCheck.content) {
    if (kind == VerificationRequestKind.location) {
      throw _invalid(
        'check',
        'A location request checks the place; use captureOnly.',
      );
    }
    if (instructions == null) {
      throw _invalid('instructions', 'A content check needs instructions.');
    }
  }

  final place = switch (decoded['place']) {
    null => null,
    final Object value => _place(value),
  };
  if (kind == VerificationRequestKind.location && place == null) {
    throw _invalid('place', 'A location request needs a place.');
  }

  final recording =
      kind == VerificationRequestKind.video ||
      kind == VerificationRequestKind.audio;
  final spokenChallenge = switch (decoded['liveChallenge']) {
    null => recording,
    'spokenWord' when recording => true,
    'spokenWord' => throw _invalid(
      'liveChallenge',
      'Only video and audio requests can use the spoken challenge.',
    ),
    'none' => false,
    _ => throw _invalid(
      'liveChallenge',
      'liveChallenge must be spokenWord or none.',
    ),
  };

  final shareEvidence = decoded['shareEvidence'];
  if (shareEvidence is! bool) {
    throw _invalid('shareEvidence', 'shareEvidence must be true or false.');
  }
  if (shareEvidence && kind == VerificationRequestKind.location) {
    throw _invalid(
      'shareEvidence',
      'A location request has no capture to share.',
    );
  }

  final redirectUri = decoded['redirectUri'];
  if (redirectUri is! String ||
      redirectUri.isEmpty ||
      redirectUri.length > 512) {
    throw _invalid('redirectUri', 'redirectUri must be a registered URI.');
  }

  String? state;
  if (decoded['state'] case final Object value) {
    if (value is! String ||
        value.isEmpty ||
        value.length > maxVerificationStateLength ||
        value.runes.any((rune) => rune < 0x20 || rune == 0x7f)) {
      throw _invalid(
        'state',
        'state must be 1 to $maxVerificationStateLength printable characters.',
      );
    }
    state = value;
  }

  final seconds = decoded['expiresInSeconds'];
  if (seconds is! int ||
      seconds < minVerificationRequestSeconds ||
      seconds > maxVerificationRequestSeconds) {
    throw _invalid(
      'expiresInSeconds',
      'expiresInSeconds must be a whole number from '
          '$minVerificationRequestSeconds to $maxVerificationRequestSeconds.',
    );
  }

  return VerificationRequestPayload(
    kind: kind,
    check: check,
    instructions: instructions,
    place: place,
    spokenChallenge: spokenChallenge,
    shareEvidence: shareEvidence,
    redirectUri: redirectUri,
    state: state,
    expiresIn: Duration(seconds: seconds),
  );
}

/// The verifier text for a `content` check: the App's instructions, quoted
/// by the verifier as data.
String verificationRequestPrompt(String instructions) =>
    'Verify that this live capture shows: $instructions';

/// The server-written verifier text for a `captureOnly` check.
const captureOnlyVerificationPrompt =
    'Verify only that this is a genuine, continuous live capture of a real '
    'scene: not a screen, a photo of a photo, an edit, or a blank or covered '
    'lens. Do not judge what it shows.';

VerificationPlace _place(Object value) {
  if (value is! Map<String, Object?> ||
      value.length != 3 ||
      !value.keys.toSet().containsAll(const {
        'latitude',
        'longitude',
        'radiusMeters',
      })) {
    throw _invalid(
      'place',
      'place must have exactly latitude, longitude, and radiusMeters.',
    );
  }
  final latitude = value['latitude'];
  final longitude = value['longitude'];
  final radius = value['radiusMeters'];
  if (latitude is! num ||
      longitude is! num ||
      radius is! num ||
      !validCoordinates(latitude.toDouble(), longitude.toDouble())) {
    throw _invalid('place', 'place needs valid coordinates.');
  }
  if (!radius.isFinite || radius < 10 || radius > 5000) {
    throw _invalid('place', 'radiusMeters must be between 10 and 5000.');
  }
  return VerificationPlace(
    latitude: latitude.toDouble(),
    longitude: longitude.toDouble(),
    radiusMeters: radius.toDouble(),
  );
}

VerificationRequestPayloadException _invalid(String field, String message) =>
    VerificationRequestPayloadException('invalid_field', message, field: field);
