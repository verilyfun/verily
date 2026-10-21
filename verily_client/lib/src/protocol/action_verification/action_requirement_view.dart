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

abstract class ActionRequirementView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ActionRequirementView._({
    required this.id,
    required this.requirementKey,
    required this.kind,
    required this.title,
    required this.instructions,
    required this.position,
    required this.isRequired,
    this.latitude,
    this.longitude,
    this.radiusMeters,
    this.maxAccuracyMeters,
    this.minDurationSeconds,
    this.maxDurationSeconds,
    this.verificationPolicy,
    bool? spokenChallengeRequired,
    this.acceptedContentTypes,
    this.maxByteLength,
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
    this.appId,
    this.appName,
    this.appAvailable,
  }) : spokenChallengeRequired = spokenChallengeRequired ?? false;

  factory ActionRequirementView({
    required _isc.UuidValue id,
    required String requirementKey,
    required _iws572ni.ActionRequirementKind kind,
    required String title,
    required String instructions,
    required int position,
    required bool isRequired,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    double? maxAccuracyMeters,
    int? minDurationSeconds,
    int? maxDurationSeconds,
    _i0pk7h0c.ActionVerificationPolicy? verificationPolicy,
    bool? spokenChallengeRequired,
    List<String>? acceptedContentTypes,
    int? maxByteLength,
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
    _isc.UuidValue? appId,
    String? appName,
    bool? appAvailable,
  }) = _ActionRequirementViewImpl;

  factory ActionRequirementView.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ActionRequirementView(
      id: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      requirementKey: jsonSerialization['requirementKey'] as String,
      kind: _iws572ni.ActionRequirementKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      title: jsonSerialization['title'] as String,
      instructions: jsonSerialization['instructions'] as String,
      position: jsonSerialization['position'] as int,
      isRequired: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['isRequired'],
      ),
      latitude: (jsonSerialization['latitude'] as num?)?.toDouble(),
      longitude: (jsonSerialization['longitude'] as num?)?.toDouble(),
      radiusMeters: (jsonSerialization['radiusMeters'] as num?)?.toDouble(),
      maxAccuracyMeters: (jsonSerialization['maxAccuracyMeters'] as num?)
          ?.toDouble(),
      minDurationSeconds: jsonSerialization['minDurationSeconds'] as int?,
      maxDurationSeconds: jsonSerialization['maxDurationSeconds'] as int?,
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
      acceptedContentTypes: jsonSerialization['acceptedContentTypes'] == null
          ? null
          : _iop4qpu5.Protocol().deserialize<List<String>>(
              jsonSerialization['acceptedContentTypes'],
            ),
      maxByteLength: jsonSerialization['maxByteLength'] as int?,
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
      appId: jsonSerialization['appId'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['appId']),
      appName: jsonSerialization['appName'] as String?,
      appAvailable: jsonSerialization['appAvailable'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['appAvailable']),
    );
  }

  _isc.UuidValue id;

  String requirementKey;

  _iws572ni.ActionRequirementKind kind;

  String title;

  String instructions;

  int position;

  bool isRequired;

  /// The action's public place, for location requirements.
  double? latitude;

  double? longitude;

  double? radiusMeters;

  double? maxAccuracyMeters;

  int? minDurationSeconds;

  int? maxDurationSeconds;

  _i0pk7h0c.ActionVerificationPolicy? verificationPolicy;

  /// Whether the app must fetch a challenge word before recording.
  bool spokenChallengeRequired;

  /// Media types and size the upload flow accepts for this proof.
  List<String>? acceptedContentTypes;

  int? maxByteLength;

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

  /// The App that confirms an `external` requirement, shown as
  /// "Confirmed by <App>".
  _isc.UuidValue? appId;

  String? appName;

  /// Whether the App is still active; false blocks new attempts.
  bool? appAvailable;

  /// Returns a shallow copy of this [ActionRequirementView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ActionRequirementView copyWith({
    _isc.UuidValue? id,
    String? requirementKey,
    _iws572ni.ActionRequirementKind? kind,
    String? title,
    String? instructions,
    int? position,
    bool? isRequired,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    double? maxAccuracyMeters,
    int? minDurationSeconds,
    int? maxDurationSeconds,
    _i0pk7h0c.ActionVerificationPolicy? verificationPolicy,
    bool? spokenChallengeRequired,
    List<String>? acceptedContentTypes,
    int? maxByteLength,
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
    _isc.UuidValue? appId,
    String? appName,
    bool? appAvailable,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActionRequirementView',
      'id': id.toJson(),
      'requirementKey': requirementKey,
      'kind': kind.toJson(),
      'title': title,
      'instructions': instructions,
      'position': position,
      'isRequired': isRequired,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (radiusMeters != null) 'radiusMeters': radiusMeters,
      if (maxAccuracyMeters != null) 'maxAccuracyMeters': maxAccuracyMeters,
      if (minDurationSeconds != null) 'minDurationSeconds': minDurationSeconds,
      if (maxDurationSeconds != null) 'maxDurationSeconds': maxDurationSeconds,
      if (verificationPolicy != null)
        'verificationPolicy': verificationPolicy?.toJson(),
      'spokenChallengeRequired': spokenChallengeRequired,
      if (acceptedContentTypes != null)
        'acceptedContentTypes': acceptedContentTypes?.toJson(),
      if (maxByteLength != null) 'maxByteLength': maxByteLength,
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
      if (appId != null) 'appId': appId?.toJson(),
      if (appName != null) 'appName': appName,
      if (appAvailable != null) 'appAvailable': appAvailable,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ActionRequirementView',
      'id': id.toJson(),
      'requirementKey': requirementKey,
      'kind': kind.toJson(),
      'title': title,
      'instructions': instructions,
      'position': position,
      'isRequired': isRequired,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (radiusMeters != null) 'radiusMeters': radiusMeters,
      if (maxAccuracyMeters != null) 'maxAccuracyMeters': maxAccuracyMeters,
      if (minDurationSeconds != null) 'minDurationSeconds': minDurationSeconds,
      if (maxDurationSeconds != null) 'maxDurationSeconds': maxDurationSeconds,
      if (verificationPolicy != null)
        'verificationPolicy': verificationPolicy?.toJson(),
      'spokenChallengeRequired': spokenChallengeRequired,
      if (acceptedContentTypes != null)
        'acceptedContentTypes': acceptedContentTypes?.toJson(),
      if (maxByteLength != null) 'maxByteLength': maxByteLength,
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
      if (appId != null) 'appId': appId?.toJson(),
      if (appName != null) 'appName': appName,
      if (appAvailable != null) 'appAvailable': appAvailable,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ActionRequirementViewImpl extends ActionRequirementView {
  _ActionRequirementViewImpl({
    required _isc.UuidValue id,
    required String requirementKey,
    required _iws572ni.ActionRequirementKind kind,
    required String title,
    required String instructions,
    required int position,
    required bool isRequired,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    double? maxAccuracyMeters,
    int? minDurationSeconds,
    int? maxDurationSeconds,
    _i0pk7h0c.ActionVerificationPolicy? verificationPolicy,
    bool? spokenChallengeRequired,
    List<String>? acceptedContentTypes,
    int? maxByteLength,
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
    _isc.UuidValue? appId,
    String? appName,
    bool? appAvailable,
  }) : super._(
         id: id,
         requirementKey: requirementKey,
         kind: kind,
         title: title,
         instructions: instructions,
         position: position,
         isRequired: isRequired,
         latitude: latitude,
         longitude: longitude,
         radiusMeters: radiusMeters,
         maxAccuracyMeters: maxAccuracyMeters,
         minDurationSeconds: minDurationSeconds,
         maxDurationSeconds: maxDurationSeconds,
         verificationPolicy: verificationPolicy,
         spokenChallengeRequired: spokenChallengeRequired,
         acceptedContentTypes: acceptedContentTypes,
         maxByteLength: maxByteLength,
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
         appId: appId,
         appName: appName,
         appAvailable: appAvailable,
       );

  /// Returns a shallow copy of this [ActionRequirementView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ActionRequirementView copyWith({
    _isc.UuidValue? id,
    String? requirementKey,
    _iws572ni.ActionRequirementKind? kind,
    String? title,
    String? instructions,
    int? position,
    bool? isRequired,
    Object? latitude = _Undefined,
    Object? longitude = _Undefined,
    Object? radiusMeters = _Undefined,
    Object? maxAccuracyMeters = _Undefined,
    Object? minDurationSeconds = _Undefined,
    Object? maxDurationSeconds = _Undefined,
    Object? verificationPolicy = _Undefined,
    bool? spokenChallengeRequired,
    Object? acceptedContentTypes = _Undefined,
    Object? maxByteLength = _Undefined,
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
    Object? appId = _Undefined,
    Object? appName = _Undefined,
    Object? appAvailable = _Undefined,
  }) {
    return ActionRequirementView(
      id: id ?? this.id,
      requirementKey: requirementKey ?? this.requirementKey,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      instructions: instructions ?? this.instructions,
      position: position ?? this.position,
      isRequired: isRequired ?? this.isRequired,
      latitude: latitude is double? ? latitude : this.latitude,
      longitude: longitude is double? ? longitude : this.longitude,
      radiusMeters: radiusMeters is double? ? radiusMeters : this.radiusMeters,
      maxAccuracyMeters: maxAccuracyMeters is double?
          ? maxAccuracyMeters
          : this.maxAccuracyMeters,
      minDurationSeconds: minDurationSeconds is int?
          ? minDurationSeconds
          : this.minDurationSeconds,
      maxDurationSeconds: maxDurationSeconds is int?
          ? maxDurationSeconds
          : this.maxDurationSeconds,
      verificationPolicy:
          verificationPolicy is _i0pk7h0c.ActionVerificationPolicy?
          ? verificationPolicy
          : this.verificationPolicy,
      spokenChallengeRequired:
          spokenChallengeRequired ?? this.spokenChallengeRequired,
      acceptedContentTypes: acceptedContentTypes is List<String>?
          ? acceptedContentTypes
          : this.acceptedContentTypes?.map((e0) => e0).toList(),
      maxByteLength: maxByteLength is int? ? maxByteLength : this.maxByteLength,
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
      appId: appId is _isc.UuidValue? ? appId : this.appId,
      appName: appName is String? ? appName : this.appName,
      appAvailable: appAvailable is bool? ? appAvailable : this.appAvailable,
    );
  }
}
