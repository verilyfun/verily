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

import '../action_verification/action_motion_axis.dart' as _i2kywim4;
import '../action_verification/action_motion_type.dart' as _iw0fdt08;
import '../action_verification/action_movement_kind.dart' as _idij3jhk;
import '../action_verification/action_requirement_kind.dart' as _iws572ni;
import '../action_verification/action_verification_policy.dart' as _i0pk7h0c;
import '../action_verification/local_check/action_local_check.dart'
    as _iyt6y350;
import '../apps/app_verification_mode.dart' as _is7dtawb;

abstract class ActionRequirementDraft
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ActionRequirementDraft._({
    required this.requirementKey,
    required this.kind,
    required this.title,
    required this.instructions,
    required this.isRequired,
    this.latitude,
    this.longitude,
    this.radiusMeters,
    this.maxAccuracyMeters,
    this.verificationPrompt,
    this.minDurationSeconds,
    this.maxDurationSeconds,
    this.minConfidence,
    this.verificationPolicy,
    this.spokenChallengeRequired,
    this.movementKind,
    this.motionType,
    this.motionAxis,
    this.targetRepetitions,
    this.minAngularSpeedRadiansPerSecond,
    this.maxAngularSpeedRadiansPerSecond,
    this.minAxisDominance,
    this.minFreeFallMilliseconds,
    this.maxFreeFallMilliseconds,
    this.minPeakAccelerationMetersPerSecondSquared,
    this.maxPeakAccelerationMetersPerSecondSquared,
    this.qrCode,
    this.appId,
    this.appVerificationMode,
    this.localCheck,
  });

  factory ActionRequirementDraft({
    required String requirementKey,
    required _iws572ni.ActionRequirementKind kind,
    required String title,
    required String instructions,
    required bool isRequired,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    double? maxAccuracyMeters,
    String? verificationPrompt,
    int? minDurationSeconds,
    int? maxDurationSeconds,
    double? minConfidence,
    _i0pk7h0c.ActionVerificationPolicy? verificationPolicy,
    bool? spokenChallengeRequired,
    _idij3jhk.ActionMovementKind? movementKind,
    _iw0fdt08.ActionMotionType? motionType,
    _i2kywim4.ActionMotionAxis? motionAxis,
    int? targetRepetitions,
    double? minAngularSpeedRadiansPerSecond,
    double? maxAngularSpeedRadiansPerSecond,
    double? minAxisDominance,
    int? minFreeFallMilliseconds,
    int? maxFreeFallMilliseconds,
    double? minPeakAccelerationMetersPerSecondSquared,
    double? maxPeakAccelerationMetersPerSecondSquared,
    String? qrCode,
    _isc.UuidValue? appId,
    _is7dtawb.AppVerificationMode? appVerificationMode,
    _iyt6y350.ActionLocalCheck? localCheck,
  }) = _ActionRequirementDraftImpl;

  factory ActionRequirementDraft.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ActionRequirementDraft(
      requirementKey: jsonSerialization['requirementKey'] as String,
      kind: _iws572ni.ActionRequirementKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      title: jsonSerialization['title'] as String,
      instructions: jsonSerialization['instructions'] as String,
      isRequired: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['isRequired'],
      ),
      latitude: (jsonSerialization['latitude'] as num?)?.toDouble(),
      longitude: (jsonSerialization['longitude'] as num?)?.toDouble(),
      radiusMeters: (jsonSerialization['radiusMeters'] as num?)?.toDouble(),
      maxAccuracyMeters: (jsonSerialization['maxAccuracyMeters'] as num?)
          ?.toDouble(),
      verificationPrompt: jsonSerialization['verificationPrompt'] as String?,
      minDurationSeconds: jsonSerialization['minDurationSeconds'] as int?,
      maxDurationSeconds: jsonSerialization['maxDurationSeconds'] as int?,
      minConfidence: (jsonSerialization['minConfidence'] as num?)?.toDouble(),
      verificationPolicy: jsonSerialization['verificationPolicy'] == null
          ? null
          : _i0pk7h0c.ActionVerificationPolicy.fromJson(
              (jsonSerialization['verificationPolicy'] as String),
            ),
      spokenChallengeRequired:
          jsonSerialization['spokenChallengeRequired'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(
              jsonSerialization['spokenChallengeRequired'],
            ),
      movementKind: jsonSerialization['movementKind'] == null
          ? null
          : _idij3jhk.ActionMovementKind.fromJson(
              (jsonSerialization['movementKind'] as String),
            ),
      motionType: jsonSerialization['motionType'] == null
          ? null
          : _iw0fdt08.ActionMotionType.fromJson(
              (jsonSerialization['motionType'] as String),
            ),
      motionAxis: jsonSerialization['motionAxis'] == null
          ? null
          : _i2kywim4.ActionMotionAxis.fromJson(
              (jsonSerialization['motionAxis'] as String),
            ),
      targetRepetitions: jsonSerialization['targetRepetitions'] as int?,
      minAngularSpeedRadiansPerSecond:
          (jsonSerialization['minAngularSpeedRadiansPerSecond'] as num?)
              ?.toDouble(),
      maxAngularSpeedRadiansPerSecond:
          (jsonSerialization['maxAngularSpeedRadiansPerSecond'] as num?)
              ?.toDouble(),
      minAxisDominance: (jsonSerialization['minAxisDominance'] as num?)
          ?.toDouble(),
      minFreeFallMilliseconds:
          jsonSerialization['minFreeFallMilliseconds'] as int?,
      maxFreeFallMilliseconds:
          jsonSerialization['maxFreeFallMilliseconds'] as int?,
      minPeakAccelerationMetersPerSecondSquared:
          (jsonSerialization['minPeakAccelerationMetersPerSecondSquared']
                  as num?)
              ?.toDouble(),
      maxPeakAccelerationMetersPerSecondSquared:
          (jsonSerialization['maxPeakAccelerationMetersPerSecondSquared']
                  as num?)
              ?.toDouble(),
      qrCode: jsonSerialization['qrCode'] as String?,
      appId: jsonSerialization['appId'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['appId']),
      appVerificationMode: jsonSerialization['appVerificationMode'] == null
          ? null
          : _is7dtawb.AppVerificationMode.fromJson(
              (jsonSerialization['appVerificationMode'] as String),
            ),
      localCheck: jsonSerialization['localCheck'] == null
          ? null
          : _iop4qpu5.Protocol().deserialize<_iyt6y350.ActionLocalCheck>(
              jsonSerialization['localCheck'],
            ),
    );
  }

  String requirementKey;

  _iws572ni.ActionRequirementKind kind;

  String title;

  String instructions;

  bool isRequired;

  double? latitude;

  double? longitude;

  double? radiusMeters;

  double? maxAccuracyMeters;

  String? verificationPrompt;

  int? minDurationSeconds;

  int? maxDurationSeconds;

  double? minConfidence;

  _i0pk7h0c.ActionVerificationPolicy? verificationPolicy;

  /// Video and audio only; null keeps the default (on). Photos never have one.
  bool? spokenChallengeRequired;

  _idij3jhk.ActionMovementKind? movementKind;

  _iw0fdt08.ActionMotionType? motionType;

  _i2kywim4.ActionMotionAxis? motionAxis;

  int? targetRepetitions;

  double? minAngularSpeedRadiansPerSecond;

  double? maxAngularSpeedRadiansPerSecond;

  double? minAxisDominance;

  int? minFreeFallMilliseconds;

  int? maxFreeFallMilliseconds;

  double? minPeakAccelerationMetersPerSecondSquared;

  double? maxPeakAccelerationMetersPerSecondSquared;

  String? qrCode;

  /// The creator's App that confirms an `external` requirement.
  _isc.UuidValue? appId;

  /// Push (the App confirms) or pull (Verily asks the App); push when null.
  _is7dtawb.AppVerificationMode? appVerificationMode;

  /// Optional phone-only check for video, photo, or audio proof.
  _iyt6y350.ActionLocalCheck? localCheck;

  /// Returns a shallow copy of this [ActionRequirementDraft]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ActionRequirementDraft copyWith({
    String? requirementKey,
    _iws572ni.ActionRequirementKind? kind,
    String? title,
    String? instructions,
    bool? isRequired,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    double? maxAccuracyMeters,
    String? verificationPrompt,
    int? minDurationSeconds,
    int? maxDurationSeconds,
    double? minConfidence,
    _i0pk7h0c.ActionVerificationPolicy? verificationPolicy,
    bool? spokenChallengeRequired,
    _idij3jhk.ActionMovementKind? movementKind,
    _iw0fdt08.ActionMotionType? motionType,
    _i2kywim4.ActionMotionAxis? motionAxis,
    int? targetRepetitions,
    double? minAngularSpeedRadiansPerSecond,
    double? maxAngularSpeedRadiansPerSecond,
    double? minAxisDominance,
    int? minFreeFallMilliseconds,
    int? maxFreeFallMilliseconds,
    double? minPeakAccelerationMetersPerSecondSquared,
    double? maxPeakAccelerationMetersPerSecondSquared,
    String? qrCode,
    _isc.UuidValue? appId,
    _is7dtawb.AppVerificationMode? appVerificationMode,
    _iyt6y350.ActionLocalCheck? localCheck,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActionRequirementDraft',
      'requirementKey': requirementKey,
      'kind': kind.toJson(),
      'title': title,
      'instructions': instructions,
      'isRequired': isRequired,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (radiusMeters != null) 'radiusMeters': radiusMeters,
      if (maxAccuracyMeters != null) 'maxAccuracyMeters': maxAccuracyMeters,
      if (verificationPrompt != null) 'verificationPrompt': verificationPrompt,
      if (minDurationSeconds != null) 'minDurationSeconds': minDurationSeconds,
      if (maxDurationSeconds != null) 'maxDurationSeconds': maxDurationSeconds,
      if (minConfidence != null) 'minConfidence': minConfidence,
      if (verificationPolicy != null)
        'verificationPolicy': verificationPolicy?.toJson(),
      if (spokenChallengeRequired != null)
        'spokenChallengeRequired': spokenChallengeRequired,
      if (movementKind != null) 'movementKind': movementKind?.toJson(),
      if (motionType != null) 'motionType': motionType?.toJson(),
      if (motionAxis != null) 'motionAxis': motionAxis?.toJson(),
      if (targetRepetitions != null) 'targetRepetitions': targetRepetitions,
      if (minAngularSpeedRadiansPerSecond != null)
        'minAngularSpeedRadiansPerSecond': minAngularSpeedRadiansPerSecond,
      if (maxAngularSpeedRadiansPerSecond != null)
        'maxAngularSpeedRadiansPerSecond': maxAngularSpeedRadiansPerSecond,
      if (minAxisDominance != null) 'minAxisDominance': minAxisDominance,
      if (minFreeFallMilliseconds != null)
        'minFreeFallMilliseconds': minFreeFallMilliseconds,
      if (maxFreeFallMilliseconds != null)
        'maxFreeFallMilliseconds': maxFreeFallMilliseconds,
      if (minPeakAccelerationMetersPerSecondSquared != null)
        'minPeakAccelerationMetersPerSecondSquared':
            minPeakAccelerationMetersPerSecondSquared,
      if (maxPeakAccelerationMetersPerSecondSquared != null)
        'maxPeakAccelerationMetersPerSecondSquared':
            maxPeakAccelerationMetersPerSecondSquared,
      if (qrCode != null) 'qrCode': qrCode,
      if (appId != null) 'appId': appId?.toJson(),
      if (appVerificationMode != null)
        'appVerificationMode': appVerificationMode?.toJson(),
      if (localCheck != null) 'localCheck': localCheck?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ActionRequirementDraft',
      'requirementKey': requirementKey,
      'kind': kind.toJson(),
      'title': title,
      'instructions': instructions,
      'isRequired': isRequired,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (radiusMeters != null) 'radiusMeters': radiusMeters,
      if (maxAccuracyMeters != null) 'maxAccuracyMeters': maxAccuracyMeters,
      if (verificationPrompt != null) 'verificationPrompt': verificationPrompt,
      if (minDurationSeconds != null) 'minDurationSeconds': minDurationSeconds,
      if (maxDurationSeconds != null) 'maxDurationSeconds': maxDurationSeconds,
      if (minConfidence != null) 'minConfidence': minConfidence,
      if (verificationPolicy != null)
        'verificationPolicy': verificationPolicy?.toJson(),
      if (spokenChallengeRequired != null)
        'spokenChallengeRequired': spokenChallengeRequired,
      if (movementKind != null) 'movementKind': movementKind?.toJson(),
      if (motionType != null) 'motionType': motionType?.toJson(),
      if (motionAxis != null) 'motionAxis': motionAxis?.toJson(),
      if (targetRepetitions != null) 'targetRepetitions': targetRepetitions,
      if (minAngularSpeedRadiansPerSecond != null)
        'minAngularSpeedRadiansPerSecond': minAngularSpeedRadiansPerSecond,
      if (maxAngularSpeedRadiansPerSecond != null)
        'maxAngularSpeedRadiansPerSecond': maxAngularSpeedRadiansPerSecond,
      if (minAxisDominance != null) 'minAxisDominance': minAxisDominance,
      if (minFreeFallMilliseconds != null)
        'minFreeFallMilliseconds': minFreeFallMilliseconds,
      if (maxFreeFallMilliseconds != null)
        'maxFreeFallMilliseconds': maxFreeFallMilliseconds,
      if (minPeakAccelerationMetersPerSecondSquared != null)
        'minPeakAccelerationMetersPerSecondSquared':
            minPeakAccelerationMetersPerSecondSquared,
      if (maxPeakAccelerationMetersPerSecondSquared != null)
        'maxPeakAccelerationMetersPerSecondSquared':
            maxPeakAccelerationMetersPerSecondSquared,
      if (qrCode != null) 'qrCode': qrCode,
      if (appId != null) 'appId': appId?.toJson(),
      if (appVerificationMode != null)
        'appVerificationMode': appVerificationMode?.toJson(),
      if (localCheck != null) 'localCheck': localCheck?.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ActionRequirementDraftImpl extends ActionRequirementDraft {
  _ActionRequirementDraftImpl({
    required String requirementKey,
    required _iws572ni.ActionRequirementKind kind,
    required String title,
    required String instructions,
    required bool isRequired,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    double? maxAccuracyMeters,
    String? verificationPrompt,
    int? minDurationSeconds,
    int? maxDurationSeconds,
    double? minConfidence,
    _i0pk7h0c.ActionVerificationPolicy? verificationPolicy,
    bool? spokenChallengeRequired,
    _idij3jhk.ActionMovementKind? movementKind,
    _iw0fdt08.ActionMotionType? motionType,
    _i2kywim4.ActionMotionAxis? motionAxis,
    int? targetRepetitions,
    double? minAngularSpeedRadiansPerSecond,
    double? maxAngularSpeedRadiansPerSecond,
    double? minAxisDominance,
    int? minFreeFallMilliseconds,
    int? maxFreeFallMilliseconds,
    double? minPeakAccelerationMetersPerSecondSquared,
    double? maxPeakAccelerationMetersPerSecondSquared,
    String? qrCode,
    _isc.UuidValue? appId,
    _is7dtawb.AppVerificationMode? appVerificationMode,
    _iyt6y350.ActionLocalCheck? localCheck,
  }) : super._(
         requirementKey: requirementKey,
         kind: kind,
         title: title,
         instructions: instructions,
         isRequired: isRequired,
         latitude: latitude,
         longitude: longitude,
         radiusMeters: radiusMeters,
         maxAccuracyMeters: maxAccuracyMeters,
         verificationPrompt: verificationPrompt,
         minDurationSeconds: minDurationSeconds,
         maxDurationSeconds: maxDurationSeconds,
         minConfidence: minConfidence,
         verificationPolicy: verificationPolicy,
         spokenChallengeRequired: spokenChallengeRequired,
         movementKind: movementKind,
         motionType: motionType,
         motionAxis: motionAxis,
         targetRepetitions: targetRepetitions,
         minAngularSpeedRadiansPerSecond: minAngularSpeedRadiansPerSecond,
         maxAngularSpeedRadiansPerSecond: maxAngularSpeedRadiansPerSecond,
         minAxisDominance: minAxisDominance,
         minFreeFallMilliseconds: minFreeFallMilliseconds,
         maxFreeFallMilliseconds: maxFreeFallMilliseconds,
         minPeakAccelerationMetersPerSecondSquared:
             minPeakAccelerationMetersPerSecondSquared,
         maxPeakAccelerationMetersPerSecondSquared:
             maxPeakAccelerationMetersPerSecondSquared,
         qrCode: qrCode,
         appId: appId,
         appVerificationMode: appVerificationMode,
         localCheck: localCheck,
       );

  /// Returns a shallow copy of this [ActionRequirementDraft]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ActionRequirementDraft copyWith({
    String? requirementKey,
    _iws572ni.ActionRequirementKind? kind,
    String? title,
    String? instructions,
    bool? isRequired,
    Object? latitude = _Undefined,
    Object? longitude = _Undefined,
    Object? radiusMeters = _Undefined,
    Object? maxAccuracyMeters = _Undefined,
    Object? verificationPrompt = _Undefined,
    Object? minDurationSeconds = _Undefined,
    Object? maxDurationSeconds = _Undefined,
    Object? minConfidence = _Undefined,
    Object? verificationPolicy = _Undefined,
    Object? spokenChallengeRequired = _Undefined,
    Object? movementKind = _Undefined,
    Object? motionType = _Undefined,
    Object? motionAxis = _Undefined,
    Object? targetRepetitions = _Undefined,
    Object? minAngularSpeedRadiansPerSecond = _Undefined,
    Object? maxAngularSpeedRadiansPerSecond = _Undefined,
    Object? minAxisDominance = _Undefined,
    Object? minFreeFallMilliseconds = _Undefined,
    Object? maxFreeFallMilliseconds = _Undefined,
    Object? minPeakAccelerationMetersPerSecondSquared = _Undefined,
    Object? maxPeakAccelerationMetersPerSecondSquared = _Undefined,
    Object? qrCode = _Undefined,
    Object? appId = _Undefined,
    Object? appVerificationMode = _Undefined,
    Object? localCheck = _Undefined,
  }) {
    return ActionRequirementDraft(
      requirementKey: requirementKey ?? this.requirementKey,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      instructions: instructions ?? this.instructions,
      isRequired: isRequired ?? this.isRequired,
      latitude: latitude is double? ? latitude : this.latitude,
      longitude: longitude is double? ? longitude : this.longitude,
      radiusMeters: radiusMeters is double? ? radiusMeters : this.radiusMeters,
      maxAccuracyMeters: maxAccuracyMeters is double?
          ? maxAccuracyMeters
          : this.maxAccuracyMeters,
      verificationPrompt: verificationPrompt is String?
          ? verificationPrompt
          : this.verificationPrompt,
      minDurationSeconds: minDurationSeconds is int?
          ? minDurationSeconds
          : this.minDurationSeconds,
      maxDurationSeconds: maxDurationSeconds is int?
          ? maxDurationSeconds
          : this.maxDurationSeconds,
      minConfidence: minConfidence is double?
          ? minConfidence
          : this.minConfidence,
      verificationPolicy:
          verificationPolicy is _i0pk7h0c.ActionVerificationPolicy?
          ? verificationPolicy
          : this.verificationPolicy,
      spokenChallengeRequired: spokenChallengeRequired is bool?
          ? spokenChallengeRequired
          : this.spokenChallengeRequired,
      movementKind: movementKind is _idij3jhk.ActionMovementKind?
          ? movementKind
          : this.movementKind,
      motionType: motionType is _iw0fdt08.ActionMotionType?
          ? motionType
          : this.motionType,
      motionAxis: motionAxis is _i2kywim4.ActionMotionAxis?
          ? motionAxis
          : this.motionAxis,
      targetRepetitions: targetRepetitions is int?
          ? targetRepetitions
          : this.targetRepetitions,
      minAngularSpeedRadiansPerSecond:
          minAngularSpeedRadiansPerSecond is double?
          ? minAngularSpeedRadiansPerSecond
          : this.minAngularSpeedRadiansPerSecond,
      maxAngularSpeedRadiansPerSecond:
          maxAngularSpeedRadiansPerSecond is double?
          ? maxAngularSpeedRadiansPerSecond
          : this.maxAngularSpeedRadiansPerSecond,
      minAxisDominance: minAxisDominance is double?
          ? minAxisDominance
          : this.minAxisDominance,
      minFreeFallMilliseconds: minFreeFallMilliseconds is int?
          ? minFreeFallMilliseconds
          : this.minFreeFallMilliseconds,
      maxFreeFallMilliseconds: maxFreeFallMilliseconds is int?
          ? maxFreeFallMilliseconds
          : this.maxFreeFallMilliseconds,
      minPeakAccelerationMetersPerSecondSquared:
          minPeakAccelerationMetersPerSecondSquared is double?
          ? minPeakAccelerationMetersPerSecondSquared
          : this.minPeakAccelerationMetersPerSecondSquared,
      maxPeakAccelerationMetersPerSecondSquared:
          maxPeakAccelerationMetersPerSecondSquared is double?
          ? maxPeakAccelerationMetersPerSecondSquared
          : this.maxPeakAccelerationMetersPerSecondSquared,
      qrCode: qrCode is String? ? qrCode : this.qrCode,
      appId: appId is _isc.UuidValue? ? appId : this.appId,
      appVerificationMode: appVerificationMode is _is7dtawb.AppVerificationMode?
          ? appVerificationMode
          : this.appVerificationMode,
      localCheck: localCheck is _iyt6y350.ActionLocalCheck?
          ? localCheck
          : this.localCheck?.copyWith(),
    );
  }
}
