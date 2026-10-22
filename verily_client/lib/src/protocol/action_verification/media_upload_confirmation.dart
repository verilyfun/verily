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
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'package:verily_client/src/protocol/protocol.dart' as _iop4qpu5;

import '../action_verification/local_check/device_local_check_result.dart'
    as _ikz5p9kp;

/// What the app reports after uploading a recording or photo. The server
/// re-derives the bytes, digest, and pinned version from storage; only the
/// capture time, duration, and integrity material come from the device.
abstract class MediaUploadConfirmation
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
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
    this.captureCertificateChain,
    this.captureAppAttestKeyId,
  });

  factory MediaUploadConfirmation({
    required _isc.UuidValue attemptId,
    required _isc.UuidValue requirementId,
    required String contentType,
    required int byteLength,
    int? durationSeconds,
    required DateTime capturedAt,
    int? deviceRepetitionCount,
    String? deviceTrackerVersion,
    _ikz5p9kp.DeviceLocalCheckResult? deviceLocalCheck,
    _isc.UuidValue? captureChallengeId,
    String? deviceIntegrityToken,
    String? captureManifest,
    String? captureSignature,
    List<String>? captureCertificateChain,
    String? captureAppAttestKeyId,
  }) = _MediaUploadConfirmationImpl;

  factory MediaUploadConfirmation.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return MediaUploadConfirmation(
      attemptId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['attemptId'],
      ),
      requirementId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['requirementId'],
      ),
      contentType: jsonSerialization['contentType'] as String,
      byteLength: jsonSerialization['byteLength'] as int,
      durationSeconds: jsonSerialization['durationSeconds'] as int?,
      capturedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['capturedAt'],
      ),
      deviceRepetitionCount: jsonSerialization['deviceRepetitionCount'] as int?,
      deviceTrackerVersion:
          jsonSerialization['deviceTrackerVersion'] as String?,
      deviceLocalCheck: jsonSerialization['deviceLocalCheck'] == null
          ? null
          : _iop4qpu5.Protocol().deserialize<_ikz5p9kp.DeviceLocalCheckResult>(
              jsonSerialization['deviceLocalCheck'],
            ),
      captureChallengeId: jsonSerialization['captureChallengeId'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(
              jsonSerialization['captureChallengeId'],
            ),
      deviceIntegrityToken:
          jsonSerialization['deviceIntegrityToken'] as String?,
      captureManifest: jsonSerialization['captureManifest'] as String?,
      captureSignature: jsonSerialization['captureSignature'] as String?,
      captureCertificateChain:
          jsonSerialization['captureCertificateChain'] == null
          ? null
          : _iop4qpu5.Protocol().deserialize<List<String>>(
              jsonSerialization['captureCertificateChain'],
            ),
      captureAppAttestKeyId:
          jsonSerialization['captureAppAttestKeyId'] as String?,
    );
  }

  _isc.UuidValue attemptId;

  _isc.UuidValue requirementId;

  String contentType;

  int byteLength;

  /// Recording length; null for a photo.
  int? durationSeconds;

  DateTime capturedAt;

  int? deviceRepetitionCount;

  String? deviceTrackerVersion;

  /// Advisory only; the server replays the pinned model itself.
  _ikz5p9kp.DeviceLocalCheckResult? deviceLocalCheck;

  _isc.UuidValue? captureChallengeId;

  String? deviceIntegrityToken;

  String? captureManifest;

  /// The device's signature over the manifest: from an Android capture key,
  /// IEEE P1363 `r ‖ s`; from an iPhone, the App Attest assertion object
  /// (CBOR). Both base64.
  String? captureSignature;

  /// The Android capture key's Key Attestation chain: base64 DER, leaf
  /// first. The key, its id, and where it lives come only from here.
  List<String>? captureCertificateChain;

  /// The iPhone's App Attest key identifier (base64, as `generateKey`
  /// returns it), registered through `appAttest.registerKey`. Send it or
  /// `captureCertificateChain`, never both.
  String? captureAppAttestKeyId;

  /// Returns a shallow copy of this [MediaUploadConfirmation]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  MediaUploadConfirmation copyWith({
    _isc.UuidValue? attemptId,
    _isc.UuidValue? requirementId,
    String? contentType,
    int? byteLength,
    int? durationSeconds,
    DateTime? capturedAt,
    int? deviceRepetitionCount,
    String? deviceTrackerVersion,
    _ikz5p9kp.DeviceLocalCheckResult? deviceLocalCheck,
    _isc.UuidValue? captureChallengeId,
    String? deviceIntegrityToken,
    String? captureManifest,
    String? captureSignature,
    List<String>? captureCertificateChain,
    String? captureAppAttestKeyId,
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
      if (captureCertificateChain != null)
        'captureCertificateChain': captureCertificateChain?.toJson(),
      if (captureAppAttestKeyId != null)
        'captureAppAttestKeyId': captureAppAttestKeyId,
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
      if (captureCertificateChain != null)
        'captureCertificateChain': captureCertificateChain?.toJson(),
      if (captureAppAttestKeyId != null)
        'captureAppAttestKeyId': captureAppAttestKeyId,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MediaUploadConfirmationImpl extends MediaUploadConfirmation {
  _MediaUploadConfirmationImpl({
    required _isc.UuidValue attemptId,
    required _isc.UuidValue requirementId,
    required String contentType,
    required int byteLength,
    int? durationSeconds,
    required DateTime capturedAt,
    int? deviceRepetitionCount,
    String? deviceTrackerVersion,
    _ikz5p9kp.DeviceLocalCheckResult? deviceLocalCheck,
    _isc.UuidValue? captureChallengeId,
    String? deviceIntegrityToken,
    String? captureManifest,
    String? captureSignature,
    List<String>? captureCertificateChain,
    String? captureAppAttestKeyId,
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
         captureCertificateChain: captureCertificateChain,
         captureAppAttestKeyId: captureAppAttestKeyId,
       );

  /// Returns a shallow copy of this [MediaUploadConfirmation]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  MediaUploadConfirmation copyWith({
    _isc.UuidValue? attemptId,
    _isc.UuidValue? requirementId,
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
    Object? captureCertificateChain = _Undefined,
    Object? captureAppAttestKeyId = _Undefined,
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
      captureChallengeId: captureChallengeId is _isc.UuidValue?
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
      captureCertificateChain: captureCertificateChain is List<String>?
          ? captureCertificateChain
          : this.captureCertificateChain?.map((e0) => e0).toList(),
      captureAppAttestKeyId: captureAppAttestKeyId is String?
          ? captureAppAttestKeyId
          : this.captureAppAttestKeyId,
    );
  }
}
