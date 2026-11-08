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

import '../action_verification/action_motion_axis.dart' as _i2kywim4;
import '../action_verification/action_motion_type.dart' as _iw0fdt08;
import '../action_verification/action_movement_kind.dart' as _idij3jhk;
import '../action_verification/action_requirement_kind.dart' as _iws572ni;
import '../action_verification/action_verification_policy.dart' as _i0pk7h0c;
import '../action_verification/local_check/action_local_check.dart'
    as _iyt6y350;
import '../action_verification/local_check/local_check_model_view.dart'
    as _ip3cz2wq;
import '../apps/app_verification_mode.dart' as _is7dtawb;

abstract class ActionRequirementView
    implements _is.SerializableModel, _is.ProtocolSerialization {
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
    this.verificationPrompt,
    this.minConfidence,
    this.venueCodeConfigured,
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
    this.appVerificationMode,
    this.localCheck,
    this.localCheckModel,
  }) : spokenChallengeRequired = spokenChallengeRequired ?? false;

  factory ActionRequirementView({
    required _is.UuidValue id,
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
    String? verificationPrompt,
    double? minConfidence,
    bool? venueCodeConfigured,
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
    _is.UuidValue? appId,
    String? appName,
    bool? appAvailable,
    _is7dtawb.AppVerificationMode? appVerificationMode,
    _iyt6y350.ActionLocalCheck? localCheck,
    _ip3cz2wq.LocalCheckModelView? localCheckModel,
  }) = _ActionRequirementViewImpl;

  factory ActionRequirementView.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ActionRequirementView(
      id: _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      requirementKey: jsonSerialization['requirementKey'] as String,
      kind: _iws572ni.ActionRequirementKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      title: jsonSerialization['title'] as String,
      instructions: jsonSerialization['instructions'] as String,
      position: jsonSerialization['position'] as int,
      isRequired: _is.BoolJsonExtension.fromJson(
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
      verificationPrompt: jsonSerialization['verificationPrompt'] as String?,
      minConfidence: (jsonSerialization['minConfidence'] as num?)?.toDouble(),
      venueCodeConfigured: jsonSerialization['venueCodeConfigured'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(
              jsonSerialization['venueCodeConfigured'],
            ),
      spokenChallengeRequired:
          jsonSerialization['spokenChallengeRequired'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(
              jsonSerialization['spokenChallengeRequired'],
            ),
      acceptedContentTypes: jsonSerialization['acceptedContentTypes'] == null
          ? null
          : _itf691yl.Protocol().deserialize<List<String>>(
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
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['appId']),
      appName: jsonSerialization['appName'] as String?,
      appAvailable: jsonSerialization['appAvailable'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['appAvailable']),
      appVerificationMode: jsonSerialization['appVerificationMode'] == null
          ? null
          : _is7dtawb.AppVerificationMode.fromJson(
              (jsonSerialization['appVerificationMode'] as String),
            ),
      localCheck: jsonSerialization['localCheck'] == null
          ? null
          : _itf691yl.Protocol().deserialize<_iyt6y350.ActionLocalCheck>(
              jsonSerialization['localCheck'],
            ),
      localCheckModel: jsonSerialization['localCheckModel'] == null
          ? null
          : _itf691yl.Protocol().deserialize<_ip3cz2wq.LocalCheckModelView>(
              jsonSerialization['localCheckModel'],
            ),
    );
  }

  _is.UuidValue id;

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

  /// Creator view only: the creator-written verifier text (null when the
  /// server writes it, for tracked movements and label-only local checks)
  /// and the confidence threshold, so a draft round-trips unchanged.
  String? verificationPrompt;

  double? minConfidence;

  /// Creator view only: whether a venue code secret is stored. Saving the
  /// draft with `qrCode: null` keeps it; sending a new code replaces it.
  bool? venueCodeConfigured;

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
  _is.UuidValue? appId;

  String? appName;

  /// Whether the App is still active; false blocks new attempts.
  bool? appAvailable;

  _is7dtawb.AppVerificationMode? appVerificationMode;

  _iyt6y350.ActionLocalCheck? localCheck;

  /// The pinned model the phone runs for [localCheck].
  _ip3cz2wq.LocalCheckModelView? localCheckModel;

  /// Returns a shallow copy of this [ActionRequirementView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ActionRequirementView copyWith({
    _is.UuidValue? id,
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
    String? verificationPrompt,
    double? minConfidence,
    bool? venueCodeConfigured,
    bool? spokenChallengeRequired,
    List<String>? acceptedContentTypes = const _is.$UndefinedList<String>(),
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
    _is.UuidValue? appId = const _is.$UndefinedUuidValue(),
    String? appName,
    bool? appAvailable,
    _is7dtawb.AppVerificationMode? appVerificationMode,
    _iyt6y350.ActionLocalCheck? localCheck =
        const _UndefinedActionRequirementView$localCheck(),
    _ip3cz2wq.LocalCheckModelView? localCheckModel =
        const _UndefinedActionRequirementView$localCheckModel(),
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
      if (verificationPrompt != null) 'verificationPrompt': verificationPrompt,
      if (minConfidence != null) 'minConfidence': minConfidence,
      if (venueCodeConfigured != null)
        'venueCodeConfigured': venueCodeConfigured,
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
      if (appVerificationMode != null)
        'appVerificationMode': appVerificationMode?.toJson(),
      if (localCheck != null) 'localCheck': localCheck?.toJson(),
      if (localCheckModel != null) 'localCheckModel': localCheckModel?.toJson(),
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
      if (verificationPrompt != null) 'verificationPrompt': verificationPrompt,
      if (minConfidence != null) 'minConfidence': minConfidence,
      if (venueCodeConfigured != null)
        'venueCodeConfigured': venueCodeConfigured,
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
      if (appVerificationMode != null)
        'appVerificationMode': appVerificationMode?.toJson(),
      if (localCheck != null) 'localCheck': localCheck?.toJsonForProtocol(),
      if (localCheckModel != null)
        'localCheckModel': localCheckModel?.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedActionRequirementView$localCheck extends _is.UndefinedSentinel
    implements _iyt6y350.ActionLocalCheck {
  const _UndefinedActionRequirementView$localCheck();
}

class _UndefinedActionRequirementView$localCheckModel
    extends _is.UndefinedSentinel
    implements _ip3cz2wq.LocalCheckModelView {
  const _UndefinedActionRequirementView$localCheckModel();
}

class _ActionRequirementViewImpl extends ActionRequirementView {
  _ActionRequirementViewImpl({
    required _is.UuidValue id,
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
    String? verificationPrompt,
    double? minConfidence,
    bool? venueCodeConfigured,
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
    _is.UuidValue? appId,
    String? appName,
    bool? appAvailable,
    _is7dtawb.AppVerificationMode? appVerificationMode,
    _iyt6y350.ActionLocalCheck? localCheck,
    _ip3cz2wq.LocalCheckModelView? localCheckModel,
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
         verificationPrompt: verificationPrompt,
         minConfidence: minConfidence,
         venueCodeConfigured: venueCodeConfigured,
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
         appVerificationMode: appVerificationMode,
         localCheck: localCheck,
         localCheckModel: localCheckModel,
       );

  /// Returns a shallow copy of this [ActionRequirementView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ActionRequirementView copyWith({
    _is.UuidValue? id,
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
    Object? verificationPrompt = _Undefined,
    Object? minConfidence = _Undefined,
    Object? venueCodeConfigured = _Undefined,
    bool? spokenChallengeRequired,
    List<String>? acceptedContentTypes = const _is.$UndefinedList<String>(),
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
    _is.UuidValue? appId = const _is.$UndefinedUuidValue(),
    Object? appName = _Undefined,
    Object? appAvailable = _Undefined,
    Object? appVerificationMode = _Undefined,
    _iyt6y350.ActionLocalCheck? localCheck =
        const _UndefinedActionRequirementView$localCheck(),
    _ip3cz2wq.LocalCheckModelView? localCheckModel =
        const _UndefinedActionRequirementView$localCheckModel(),
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
      verificationPrompt: verificationPrompt is String?
          ? verificationPrompt
          : this.verificationPrompt,
      minConfidence: minConfidence is double?
          ? minConfidence
          : this.minConfidence,
      venueCodeConfigured: venueCodeConfigured is bool?
          ? venueCodeConfigured
          : this.venueCodeConfigured,
      spokenChallengeRequired:
          spokenChallengeRequired ?? this.spokenChallengeRequired,
      acceptedContentTypes: acceptedContentTypes is _is.UndefinedSentinel
          ? this.acceptedContentTypes?.map((e0) => e0).toList()
          : acceptedContentTypes,
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
      appId: appId is _is.UndefinedSentinel ? this.appId : appId,
      appName: appName is String? ? appName : this.appName,
      appAvailable: appAvailable is bool? ? appAvailable : this.appAvailable,
      appVerificationMode: appVerificationMode is _is7dtawb.AppVerificationMode?
          ? appVerificationMode
          : this.appVerificationMode,
      localCheck: localCheck is _is.UndefinedSentinel
          ? this.localCheck?.copyWith()
          : localCheck,
      localCheckModel: localCheckModel is _is.UndefinedSentinel
          ? this.localCheckModel?.copyWith()
          : localCheckModel,
    );
  }
}
