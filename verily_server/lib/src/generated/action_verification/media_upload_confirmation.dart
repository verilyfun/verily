/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _is;
import 'package:verily_server/src/generated/protocol.dart' as _itf691yl;

import '../action_verification/local_check/device_local_check_result.dart'
    as _ikz5p9kp;

/// What the app reports after uploading a recording or photo. The server
/// re-derives the bytes, digest, and pinned version from storage; only the
/// capture time, duration, and integrity material come from the device.
abstract class MediaUploadConfirmation
    implements _is.SerializableModel, _is.ProtocolSerialization {
  MediaUploadConfirmation._({
    required this.attemptId,
    required this.requirementId,
    required this.contentType,
    required this.byteLength,
    this.durationSeconds,
    required this.capturedAt,
    this.deviceRepetitionCount,
    this.deviceTrackerVersion,
    this.deviceLocalCheck,
    this.captureChallengeId,
    this.deviceIntegrityToken,
    this.captureManifest,
    this.captureSignature,
    this.capturePublicKey,
    this.captureKeyId,
    this.captureKeyStorage,
  });

  factory MediaUploadConfirmation({
    required _is.UuidValue attemptId,
    required _is.UuidValue requirementId,
    required String contentType,
    required int byteLength,
    int? durationSeconds,
    required DateTime capturedAt,
    int? deviceRepetitionCount,
    String? deviceTrackerVersion,
    _ikz5p9kp.DeviceLocalCheckResult? deviceLocalCheck,
    _is.UuidValue? captureChallengeId,
    String? deviceIntegrityToken,
    String? captureManifest,
    String? captureSignature,
    String? capturePublicKey,
    String? captureKeyId,
    String? captureKeyStorage,
  }) = _MediaUploadConfirmationImpl;

  factory MediaUploadConfirmation.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return MediaUploadConfirmation(
      attemptId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['attemptId'],
      ),
      requirementId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['requirementId'],
      ),
      contentType: jsonSerialization['contentType'] as String,
      byteLength: jsonSerialization['byteLength'] as int,
      durationSeconds: jsonSerialization['durationSeconds'] as int?,
      capturedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['capturedAt'],
      ),
      deviceRepetitionCount: jsonSerialization['deviceRepetitionCount'] as int?,
      deviceTrackerVersion:
          jsonSerialization['deviceTrackerVersion'] as String?,
      deviceLocalCheck: jsonSerialization['deviceLocalCheck'] == null
          ? null
          : _itf691yl.Protocol().deserialize<_ikz5p9kp.DeviceLocalCheckResult>(
              jsonSerialization['deviceLocalCheck'],
            ),
      captureChallengeId: jsonSerialization['captureChallengeId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['captureChallengeId'],
            ),
      deviceIntegrityToken:
          jsonSerialization['deviceIntegrityToken'] as String?,
      captureManifest: jsonSerialization['captureManifest'] as String?,
      captureSignature: jsonSerialization['captureSignature'] as String?,
      capturePublicKey: jsonSerialization['capturePublicKey'] as String?,
      captureKeyId: jsonSerialization['captureKeyId'] as String?,
      captureKeyStorage: jsonSerialization['captureKeyStorage'] as String?,
    );
  }

  _is.UuidValue attemptId;

  _is.UuidValue requirementId;

  String contentType;

  int byteLength;

  /// Recording length; null for a photo.
  int? durationSeconds;

  DateTime capturedAt;

  int? deviceRepetitionCount;

  String? deviceTrackerVersion;

  /// Advisory only; the server replays the pinned model itself.
  _ikz5p9kp.DeviceLocalCheckResult? deviceLocalCheck;

  _is.UuidValue? captureChallengeId;

  String? deviceIntegrityToken;

  String? captureManifest;

  String? captureSignature;

  String? capturePublicKey;

  String? captureKeyId;

  String? captureKeyStorage;

  /// Returns a shallow copy of this [MediaUploadConfirmation]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  MediaUploadConfirmation copyWith({
    _is.UuidValue? attemptId,
    _is.UuidValue? requirementId,
    String? contentType,
    int? byteLength,
    int? durationSeconds,
    DateTime? capturedAt,
    int? deviceRepetitionCount,
    String? deviceTrackerVersion,
    _ikz5p9kp.DeviceLocalCheckResult? deviceLocalCheck,
    _is.UuidValue? captureChallengeId,
    String? deviceIntegrityToken,
    String? captureManifest,
    String? captureSignature,
    String? capturePublicKey,
    String? captureKeyId,
    String? captureKeyStorage,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MediaUploadConfirmation',
      'attemptId': attemptId.toJson(),
      'requirementId': requirementId.toJson(),
      'contentType': contentType,
      'byteLength': byteLength,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      'capturedAt': capturedAt.toJson(),
      if (deviceRepetitionCount != null)
        'deviceRepetitionCount': deviceRepetitionCount,
      if (deviceTrackerVersion != null)
        'deviceTrackerVersion': deviceTrackerVersion,
      if (deviceLocalCheck != null)
        'deviceLocalCheck': deviceLocalCheck?.toJson(),
      if (captureChallengeId != null)
        'captureChallengeId': captureChallengeId?.toJson(),
      if (deviceIntegrityToken != null)
        'deviceIntegrityToken': deviceIntegrityToken,
      if (captureManifest != null) 'captureManifest': captureManifest,
      if (captureSignature != null) 'captureSignature': captureSignature,
      if (capturePublicKey != null) 'capturePublicKey': capturePublicKey,
      if (captureKeyId != null) 'captureKeyId': captureKeyId,
      if (captureKeyStorage != null) 'captureKeyStorage': captureKeyStorage,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MediaUploadConfirmation',
      'attemptId': attemptId.toJson(),
      'requirementId': requirementId.toJson(),
      'contentType': contentType,
      'byteLength': byteLength,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      'capturedAt': capturedAt.toJson(),
      if (deviceRepetitionCount != null)
        'deviceRepetitionCount': deviceRepetitionCount,
      if (deviceTrackerVersion != null)
        'deviceTrackerVersion': deviceTrackerVersion,
      if (deviceLocalCheck != null)
        'deviceLocalCheck': deviceLocalCheck?.toJsonForProtocol(),
      if (captureChallengeId != null)
        'captureChallengeId': captureChallengeId?.toJson(),
      if (deviceIntegrityToken != null)
        'deviceIntegrityToken': deviceIntegrityToken,
      if (captureManifest != null) 'captureManifest': captureManifest,
      if (captureSignature != null) 'captureSignature': captureSignature,
      if (capturePublicKey != null) 'capturePublicKey': capturePublicKey,
      if (captureKeyId != null) 'captureKeyId': captureKeyId,
      if (captureKeyStorage != null) 'captureKeyStorage': captureKeyStorage,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MediaUploadConfirmationImpl extends MediaUploadConfirmation {
  _MediaUploadConfirmationImpl({
    required _is.UuidValue attemptId,
    required _is.UuidValue requirementId,
    required String contentType,
    required int byteLength,
    int? durationSeconds,
    required DateTime capturedAt,
    int? deviceRepetitionCount,
    String? deviceTrackerVersion,
    _ikz5p9kp.DeviceLocalCheckResult? deviceLocalCheck,
    _is.UuidValue? captureChallengeId,
    String? deviceIntegrityToken,
    String? captureManifest,
    String? captureSignature,
    String? capturePublicKey,
    String? captureKeyId,
    String? captureKeyStorage,
  }) : super._(
         attemptId: attemptId,
         requirementId: requirementId,
         contentType: contentType,
         byteLength: byteLength,
         durationSeconds: durationSeconds,
         capturedAt: capturedAt,
         deviceRepetitionCount: deviceRepetitionCount,
         deviceTrackerVersion: deviceTrackerVersion,
         deviceLocalCheck: deviceLocalCheck,
         captureChallengeId: captureChallengeId,
         deviceIntegrityToken: deviceIntegrityToken,
         captureManifest: captureManifest,
         captureSignature: captureSignature,
         capturePublicKey: capturePublicKey,
         captureKeyId: captureKeyId,
         captureKeyStorage: captureKeyStorage,
       );

  /// Returns a shallow copy of this [MediaUploadConfirmation]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  MediaUploadConfirmation copyWith({
    _is.UuidValue? attemptId,
    _is.UuidValue? requirementId,
    String? contentType,
    int? byteLength,
    Object? durationSeconds = _Undefined,
    DateTime? capturedAt,
    Object? deviceRepetitionCount = _Undefined,
    Object? deviceTrackerVersion = _Undefined,
    Object? deviceLocalCheck = _Undefined,
    Object? captureChallengeId = _Undefined,
    Object? deviceIntegrityToken = _Undefined,
    Object? captureManifest = _Undefined,
    Object? captureSignature = _Undefined,
    Object? capturePublicKey = _Undefined,
    Object? captureKeyId = _Undefined,
    Object? captureKeyStorage = _Undefined,
  }) {
    return MediaUploadConfirmation(
      attemptId: attemptId ?? this.attemptId,
      requirementId: requirementId ?? this.requirementId,
      contentType: contentType ?? this.contentType,
      byteLength: byteLength ?? this.byteLength,
      durationSeconds: durationSeconds is int?
          ? durationSeconds
          : this.durationSeconds,
      capturedAt: capturedAt ?? this.capturedAt,
      deviceRepetitionCount: deviceRepetitionCount is int?
          ? deviceRepetitionCount
          : this.deviceRepetitionCount,
      deviceTrackerVersion: deviceTrackerVersion is String?
          ? deviceTrackerVersion
          : this.deviceTrackerVersion,
      deviceLocalCheck: deviceLocalCheck is _ikz5p9kp.DeviceLocalCheckResult?
          ? deviceLocalCheck
          : this.deviceLocalCheck?.copyWith(),
      captureChallengeId: captureChallengeId is _is.UuidValue?
          ? captureChallengeId
          : this.captureChallengeId,
      deviceIntegrityToken: deviceIntegrityToken is String?
          ? deviceIntegrityToken
          : this.deviceIntegrityToken,
      captureManifest: captureManifest is String?
          ? captureManifest
          : this.captureManifest,
      captureSignature: captureSignature is String?
          ? captureSignature
          : this.captureSignature,
      capturePublicKey: capturePublicKey is String?
          ? capturePublicKey
          : this.capturePublicKey,
      captureKeyId: captureKeyId is String? ? captureKeyId : this.captureKeyId,
      captureKeyStorage: captureKeyStorage is String?
          ? captureKeyStorage
          : this.captureKeyStorage,
    );
  }
}
