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

import '../action_verification/action_motion_sample.dart' as _if8wodvr;

/// Deterministic proof submitted directly: location, venue code, or motion.
/// Media proof never uses this path; it goes through the private upload flow.
abstract class ActionEvidenceInput
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ActionEvidenceInput._({
    required this.attemptId,
    required this.requirementId,
    required this.capturedAt,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.qrCode,
    this.motionSamples,
    this.captureChallengeId,
    this.deviceIntegrityToken,
    this.captureManifest,
    this.captureSignature,
    this.capturePublicKey,
    this.captureKeyId,
    this.captureKeyStorage,
  });

  factory ActionEvidenceInput({
    required _isc.UuidValue attemptId,
    required _isc.UuidValue requirementId,
    required DateTime capturedAt,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    String? qrCode,
    List<_if8wodvr.ActionMotionSample>? motionSamples,
    _isc.UuidValue? captureChallengeId,
    String? deviceIntegrityToken,
    String? captureManifest,
    String? captureSignature,
    String? capturePublicKey,
    String? captureKeyId,
    String? captureKeyStorage,
  }) = _ActionEvidenceInputImpl;

  factory ActionEvidenceInput.fromJson(Map<String, dynamic> jsonSerialization) {
    return ActionEvidenceInput(
      attemptId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['attemptId'],
      ),
      requirementId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['requirementId'],
      ),
      capturedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['capturedAt'],
      ),
      latitude: (jsonSerialization['latitude'] as num?)?.toDouble(),
      longitude: (jsonSerialization['longitude'] as num?)?.toDouble(),
      accuracyMeters: (jsonSerialization['accuracyMeters'] as num?)?.toDouble(),
      qrCode: jsonSerialization['qrCode'] as String?,
      motionSamples: jsonSerialization['motionSamples'] == null
          ? null
          : _iop4qpu5.Protocol()
                .deserialize<List<_if8wodvr.ActionMotionSample>>(
                  jsonSerialization['motionSamples'],
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
      capturePublicKey: jsonSerialization['capturePublicKey'] as String?,
      captureKeyId: jsonSerialization['captureKeyId'] as String?,
      captureKeyStorage: jsonSerialization['captureKeyStorage'] as String?,
    );
  }

  _isc.UuidValue attemptId;

  _isc.UuidValue requirementId;

  DateTime capturedAt;

  double? latitude;

  double? longitude;

  double? accuracyMeters;

  String? qrCode;

  List<_if8wodvr.ActionMotionSample>? motionSamples;

  _isc.UuidValue? captureChallengeId;

  String? deviceIntegrityToken;

  String? captureManifest;

  String? captureSignature;

  String? capturePublicKey;

  String? captureKeyId;

  String? captureKeyStorage;

  /// Returns a shallow copy of this [ActionEvidenceInput]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ActionEvidenceInput copyWith({
    _isc.UuidValue? attemptId,
    _isc.UuidValue? requirementId,
    DateTime? capturedAt,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    String? qrCode,
    List<_if8wodvr.ActionMotionSample>? motionSamples,
    _isc.UuidValue? captureChallengeId,
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
      '__className__': 'ActionEvidenceInput',
      'attemptId': attemptId.toJson(),
      'requirementId': requirementId.toJson(),
      'capturedAt': capturedAt.toJson(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
      if (qrCode != null) 'qrCode': qrCode,
      if (motionSamples != null)
        'motionSamples': motionSamples?.toJson(valueToJson: (v) => v.toJson()),
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
      '__className__': 'ActionEvidenceInput',
      'attemptId': attemptId.toJson(),
      'requirementId': requirementId.toJson(),
      'capturedAt': capturedAt.toJson(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
      if (qrCode != null) 'qrCode': qrCode,
      if (motionSamples != null)
        'motionSamples': motionSamples?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
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
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ActionEvidenceInputImpl extends ActionEvidenceInput {
  _ActionEvidenceInputImpl({
    required _isc.UuidValue attemptId,
    required _isc.UuidValue requirementId,
    required DateTime capturedAt,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    String? qrCode,
    List<_if8wodvr.ActionMotionSample>? motionSamples,
    _isc.UuidValue? captureChallengeId,
    String? deviceIntegrityToken,
    String? captureManifest,
    String? captureSignature,
    String? capturePublicKey,
    String? captureKeyId,
    String? captureKeyStorage,
  }) : super._(
         attemptId: attemptId,
         requirementId: requirementId,
         capturedAt: capturedAt,
         latitude: latitude,
         longitude: longitude,
         accuracyMeters: accuracyMeters,
         qrCode: qrCode,
         motionSamples: motionSamples,
         captureChallengeId: captureChallengeId,
         deviceIntegrityToken: deviceIntegrityToken,
         captureManifest: captureManifest,
         captureSignature: captureSignature,
         capturePublicKey: capturePublicKey,
         captureKeyId: captureKeyId,
         captureKeyStorage: captureKeyStorage,
       );

  /// Returns a shallow copy of this [ActionEvidenceInput]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ActionEvidenceInput copyWith({
    _isc.UuidValue? attemptId,
    _isc.UuidValue? requirementId,
    DateTime? capturedAt,
    Object? latitude = _Undefined,
    Object? longitude = _Undefined,
    Object? accuracyMeters = _Undefined,
    Object? qrCode = _Undefined,
    Object? motionSamples = _Undefined,
    Object? captureChallengeId = _Undefined,
    Object? deviceIntegrityToken = _Undefined,
    Object? captureManifest = _Undefined,
    Object? captureSignature = _Undefined,
    Object? capturePublicKey = _Undefined,
    Object? captureKeyId = _Undefined,
    Object? captureKeyStorage = _Undefined,
  }) {
    return ActionEvidenceInput(
      attemptId: attemptId ?? this.attemptId,
      requirementId: requirementId ?? this.requirementId,
      capturedAt: capturedAt ?? this.capturedAt,
      latitude: latitude is double? ? latitude : this.latitude,
      longitude: longitude is double? ? longitude : this.longitude,
      accuracyMeters: accuracyMeters is double?
          ? accuracyMeters
          : this.accuracyMeters,
      qrCode: qrCode is String? ? qrCode : this.qrCode,
      motionSamples: motionSamples is List<_if8wodvr.ActionMotionSample>?
          ? motionSamples
          : this.motionSamples?.map((e0) => e0.copyWith()).toList(),
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
