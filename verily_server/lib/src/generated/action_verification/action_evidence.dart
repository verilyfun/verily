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

import '../action_verification/action_requirement_kind.dart' as _iws572ni;
import '../action_verification/evidence_provenance_level.dart' as _ijbfcz4y;

/// Private proof facts bound to one attempt and requirement; never expose as a public feed.
abstract class ActionEvidence
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  ActionEvidence._({
    this.id,
    required this.attemptId,
    required this.requirementId,
    required this.kind,
    this.storagePath,
    this.storageVersionId,
    this.mimeType,
    this.sha256Digest,
    this.byteLength,
    this.durationSeconds,
    this.location,
    this.accuracyMeters,
    this.motionTraceJson,
    this.motionTraceSha256,
    this.motionSampleCount,
    this.motionDurationMilliseconds,
    this.motionAnalysisJson,
    this.deviceRepetitionCount,
    this.deviceTrackerVersion,
    this.spokenChallengeId,
    this.spokenChallengeWord,
    this.deviceLocalCheckModelId,
    this.deviceLocalCheckModelSha256,
    this.deviceLocalCheckLabel,
    this.deviceLocalCheckScore,
    this.deviceLocalCheckMatchedFrames,
    _ijbfcz4y.EvidenceProvenanceLevel? provenanceLevel,
    this.captureManifest,
    this.captureSignature,
    this.capturePublicKey,
    this.captureKeyId,
    this.captureKeyStorage,
    required this.capturedAt,
    DateTime? submittedAt,
  }) : provenanceLevel =
           provenanceLevel ?? _ijbfcz4y.EvidenceProvenanceLevel.basic,
       submittedAt = submittedAt ?? DateTime.now();

  factory ActionEvidence({
    _is.UuidValue? id,
    required _is.UuidValue attemptId,
    required _is.UuidValue requirementId,
    required _iws572ni.ActionRequirementKind kind,
    String? storagePath,
    String? storageVersionId,
    String? mimeType,
    String? sha256Digest,
    int? byteLength,
    int? durationSeconds,
    _is.GeographyPoint? location,
    double? accuracyMeters,
    String? motionTraceJson,
    String? motionTraceSha256,
    int? motionSampleCount,
    int? motionDurationMilliseconds,
    String? motionAnalysisJson,
    int? deviceRepetitionCount,
    String? deviceTrackerVersion,
    _is.UuidValue? spokenChallengeId,
    String? spokenChallengeWord,
    String? deviceLocalCheckModelId,
    String? deviceLocalCheckModelSha256,
    String? deviceLocalCheckLabel,
    double? deviceLocalCheckScore,
    int? deviceLocalCheckMatchedFrames,
    _ijbfcz4y.EvidenceProvenanceLevel? provenanceLevel,
    String? captureManifest,
    String? captureSignature,
    String? capturePublicKey,
    String? captureKeyId,
    String? captureKeyStorage,
    required DateTime capturedAt,
    DateTime? submittedAt,
  }) = _ActionEvidenceImpl;

  factory ActionEvidence.fromJson(Map<String, dynamic> jsonSerialization) {
    return ActionEvidence(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      attemptId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['attemptId'],
      ),
      requirementId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['requirementId'],
      ),
      kind: _iws572ni.ActionRequirementKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      storagePath: jsonSerialization['storagePath'] as String?,
      storageVersionId: jsonSerialization['storageVersionId'] as String?,
      mimeType: jsonSerialization['mimeType'] as String?,
      sha256Digest: jsonSerialization['sha256Digest'] as String?,
      byteLength: jsonSerialization['byteLength'] as int?,
      durationSeconds: jsonSerialization['durationSeconds'] as int?,
      location: jsonSerialization['location'] == null
          ? null
          : _is.GeographyPointJsonExtension.fromJson(
              jsonSerialization['location'],
            ),
      accuracyMeters: (jsonSerialization['accuracyMeters'] as num?)?.toDouble(),
      motionTraceJson: jsonSerialization['motionTraceJson'] as String?,
      motionTraceSha256: jsonSerialization['motionTraceSha256'] as String?,
      motionSampleCount: jsonSerialization['motionSampleCount'] as int?,
      motionDurationMilliseconds:
          jsonSerialization['motionDurationMilliseconds'] as int?,
      motionAnalysisJson: jsonSerialization['motionAnalysisJson'] as String?,
      deviceRepetitionCount: jsonSerialization['deviceRepetitionCount'] as int?,
      deviceTrackerVersion:
          jsonSerialization['deviceTrackerVersion'] as String?,
      spokenChallengeId: jsonSerialization['spokenChallengeId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['spokenChallengeId'],
            ),
      spokenChallengeWord: jsonSerialization['spokenChallengeWord'] as String?,
      deviceLocalCheckModelId:
          jsonSerialization['deviceLocalCheckModelId'] as String?,
      deviceLocalCheckModelSha256:
          jsonSerialization['deviceLocalCheckModelSha256'] as String?,
      deviceLocalCheckLabel:
          jsonSerialization['deviceLocalCheckLabel'] as String?,
      deviceLocalCheckScore:
          (jsonSerialization['deviceLocalCheckScore'] as num?)?.toDouble(),
      deviceLocalCheckMatchedFrames:
          jsonSerialization['deviceLocalCheckMatchedFrames'] as int?,
      provenanceLevel: jsonSerialization['provenanceLevel'] == null
          ? null
          : _ijbfcz4y.EvidenceProvenanceLevel.fromJson(
              (jsonSerialization['provenanceLevel'] as String),
            ),
      captureManifest: jsonSerialization['captureManifest'] as String?,
      captureSignature: jsonSerialization['captureSignature'] as String?,
      capturePublicKey: jsonSerialization['capturePublicKey'] as String?,
      captureKeyId: jsonSerialization['captureKeyId'] as String?,
      captureKeyStorage: jsonSerialization['captureKeyStorage'] as String?,
      capturedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['capturedAt'],
      ),
      submittedAt: jsonSerialization['submittedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['submittedAt'],
            ),
    );
  }

  static final t = ActionEvidenceTable();

  static const db = ActionEvidenceRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue attemptId;

  _is.UuidValue requirementId;

  _iws572ni.ActionRequirementKind kind;

  String? storagePath;

  String? storageVersionId;

  String? mimeType;

  String? sha256Digest;

  int? byteLength;

  int? durationSeconds;

  _is.GeographyPoint? location;

  double? accuracyMeters;

  String? motionTraceJson;

  String? motionTraceSha256;

  int? motionSampleCount;

  int? motionDurationMilliseconds;

  String? motionAnalysisJson;

  /// Advisory on-device count shown to the participant; never a decision input.
  int? deviceRepetitionCount;

  /// Identifies the on-device tracker and model that produced the count.
  String? deviceTrackerVersion;

  /// The live challenge this recording was bound to, and its word, kept with
  /// the proof so verifiers and reviewers check exactly what was asked.
  _is.UuidValue? spokenChallengeId;

  String? spokenChallengeWord;

  /// The phone's advisory local-check result, kept for calibration only.
  String? deviceLocalCheckModelId;

  String? deviceLocalCheckModelSha256;

  String? deviceLocalCheckLabel;

  double? deviceLocalCheckScore;

  int? deviceLocalCheckMatchedFrames;

  _ijbfcz4y.EvidenceProvenanceLevel provenanceLevel;

  String? captureManifest;

  String? captureSignature;

  String? capturePublicKey;

  String? captureKeyId;

  String? captureKeyStorage;

  DateTime capturedAt;

  DateTime submittedAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [ActionEvidence]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ActionEvidence copyWith({
    _is.UuidValue? id,
    _is.UuidValue? attemptId,
    _is.UuidValue? requirementId,
    _iws572ni.ActionRequirementKind? kind,
    String? storagePath,
    String? storageVersionId,
    String? mimeType,
    String? sha256Digest,
    int? byteLength,
    int? durationSeconds,
    _is.GeographyPoint? location,
    double? accuracyMeters,
    String? motionTraceJson,
    String? motionTraceSha256,
    int? motionSampleCount,
    int? motionDurationMilliseconds,
    String? motionAnalysisJson,
    int? deviceRepetitionCount,
    String? deviceTrackerVersion,
    _is.UuidValue? spokenChallengeId,
    String? spokenChallengeWord,
    String? deviceLocalCheckModelId,
    String? deviceLocalCheckModelSha256,
    String? deviceLocalCheckLabel,
    double? deviceLocalCheckScore,
    int? deviceLocalCheckMatchedFrames,
    _ijbfcz4y.EvidenceProvenanceLevel? provenanceLevel,
    String? captureManifest,
    String? captureSignature,
    String? capturePublicKey,
    String? captureKeyId,
    String? captureKeyStorage,
    DateTime? capturedAt,
    DateTime? submittedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActionEvidence',
      if (id != null) 'id': id?.toJson(),
      'attemptId': attemptId.toJson(),
      'requirementId': requirementId.toJson(),
      'kind': kind.toJson(),
      if (storagePath != null) 'storagePath': storagePath,
      if (storageVersionId != null) 'storageVersionId': storageVersionId,
      if (mimeType != null) 'mimeType': mimeType,
      if (sha256Digest != null) 'sha256Digest': sha256Digest,
      if (byteLength != null) 'byteLength': byteLength,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      if (location != null) 'location': location?.toJson(),
      if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
      if (motionTraceJson != null) 'motionTraceJson': motionTraceJson,
      if (motionTraceSha256 != null) 'motionTraceSha256': motionTraceSha256,
      if (motionSampleCount != null) 'motionSampleCount': motionSampleCount,
      if (motionDurationMilliseconds != null)
        'motionDurationMilliseconds': motionDurationMilliseconds,
      if (motionAnalysisJson != null) 'motionAnalysisJson': motionAnalysisJson,
      if (deviceRepetitionCount != null)
        'deviceRepetitionCount': deviceRepetitionCount,
      if (deviceTrackerVersion != null)
        'deviceTrackerVersion': deviceTrackerVersion,
      if (spokenChallengeId != null)
        'spokenChallengeId': spokenChallengeId?.toJson(),
      if (spokenChallengeWord != null)
        'spokenChallengeWord': spokenChallengeWord,
      if (deviceLocalCheckModelId != null)
        'deviceLocalCheckModelId': deviceLocalCheckModelId,
      if (deviceLocalCheckModelSha256 != null)
        'deviceLocalCheckModelSha256': deviceLocalCheckModelSha256,
      if (deviceLocalCheckLabel != null)
        'deviceLocalCheckLabel': deviceLocalCheckLabel,
      if (deviceLocalCheckScore != null)
        'deviceLocalCheckScore': deviceLocalCheckScore,
      if (deviceLocalCheckMatchedFrames != null)
        'deviceLocalCheckMatchedFrames': deviceLocalCheckMatchedFrames,
      'provenanceLevel': provenanceLevel.toJson(),
      if (captureManifest != null) 'captureManifest': captureManifest,
      if (captureSignature != null) 'captureSignature': captureSignature,
      if (capturePublicKey != null) 'capturePublicKey': capturePublicKey,
      if (captureKeyId != null) 'captureKeyId': captureKeyId,
      if (captureKeyStorage != null) 'captureKeyStorage': captureKeyStorage,
      'capturedAt': capturedAt.toJson(),
      'submittedAt': submittedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ActionEvidenceInclude include() {
    return ActionEvidenceInclude._();
  }

  static ActionEvidenceIncludeList includeList({
    _is.WhereExpressionBuilder<ActionEvidenceTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionEvidenceTable>? orderBy,
    _is.OrderByListBuilder<ActionEvidenceTable>? orderByList,
    ActionEvidenceInclude? include,
  }) {
    return ActionEvidenceIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ActionEvidence.t),
      orderByList: orderByList?.call(ActionEvidence.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ActionEvidenceImpl extends ActionEvidence {
  _ActionEvidenceImpl({
    _is.UuidValue? id,
    required _is.UuidValue attemptId,
    required _is.UuidValue requirementId,
    required _iws572ni.ActionRequirementKind kind,
    String? storagePath,
    String? storageVersionId,
    String? mimeType,
    String? sha256Digest,
    int? byteLength,
    int? durationSeconds,
    _is.GeographyPoint? location,
    double? accuracyMeters,
    String? motionTraceJson,
    String? motionTraceSha256,
    int? motionSampleCount,
    int? motionDurationMilliseconds,
    String? motionAnalysisJson,
    int? deviceRepetitionCount,
    String? deviceTrackerVersion,
    _is.UuidValue? spokenChallengeId,
    String? spokenChallengeWord,
    String? deviceLocalCheckModelId,
    String? deviceLocalCheckModelSha256,
    String? deviceLocalCheckLabel,
    double? deviceLocalCheckScore,
    int? deviceLocalCheckMatchedFrames,
    _ijbfcz4y.EvidenceProvenanceLevel? provenanceLevel,
    String? captureManifest,
    String? captureSignature,
    String? capturePublicKey,
    String? captureKeyId,
    String? captureKeyStorage,
    required DateTime capturedAt,
    DateTime? submittedAt,
  }) : super._(
         id: id,
         attemptId: attemptId,
         requirementId: requirementId,
         kind: kind,
         storagePath: storagePath,
         storageVersionId: storageVersionId,
         mimeType: mimeType,
         sha256Digest: sha256Digest,
         byteLength: byteLength,
         durationSeconds: durationSeconds,
         location: location,
         accuracyMeters: accuracyMeters,
         motionTraceJson: motionTraceJson,
         motionTraceSha256: motionTraceSha256,
         motionSampleCount: motionSampleCount,
         motionDurationMilliseconds: motionDurationMilliseconds,
         motionAnalysisJson: motionAnalysisJson,
         deviceRepetitionCount: deviceRepetitionCount,
         deviceTrackerVersion: deviceTrackerVersion,
         spokenChallengeId: spokenChallengeId,
         spokenChallengeWord: spokenChallengeWord,
         deviceLocalCheckModelId: deviceLocalCheckModelId,
         deviceLocalCheckModelSha256: deviceLocalCheckModelSha256,
         deviceLocalCheckLabel: deviceLocalCheckLabel,
         deviceLocalCheckScore: deviceLocalCheckScore,
         deviceLocalCheckMatchedFrames: deviceLocalCheckMatchedFrames,
         provenanceLevel: provenanceLevel,
         captureManifest: captureManifest,
         captureSignature: captureSignature,
         capturePublicKey: capturePublicKey,
         captureKeyId: captureKeyId,
         captureKeyStorage: captureKeyStorage,
         capturedAt: capturedAt,
         submittedAt: submittedAt,
       );

  /// Returns a shallow copy of this [ActionEvidence]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ActionEvidence copyWith({
    Object? id = _Undefined,
    _is.UuidValue? attemptId,
    _is.UuidValue? requirementId,
    _iws572ni.ActionRequirementKind? kind,
    Object? storagePath = _Undefined,
    Object? storageVersionId = _Undefined,
    Object? mimeType = _Undefined,
    Object? sha256Digest = _Undefined,
    Object? byteLength = _Undefined,
    Object? durationSeconds = _Undefined,
    Object? location = _Undefined,
    Object? accuracyMeters = _Undefined,
    Object? motionTraceJson = _Undefined,
    Object? motionTraceSha256 = _Undefined,
    Object? motionSampleCount = _Undefined,
    Object? motionDurationMilliseconds = _Undefined,
    Object? motionAnalysisJson = _Undefined,
    Object? deviceRepetitionCount = _Undefined,
    Object? deviceTrackerVersion = _Undefined,
    Object? spokenChallengeId = _Undefined,
    Object? spokenChallengeWord = _Undefined,
    Object? deviceLocalCheckModelId = _Undefined,
    Object? deviceLocalCheckModelSha256 = _Undefined,
    Object? deviceLocalCheckLabel = _Undefined,
    Object? deviceLocalCheckScore = _Undefined,
    Object? deviceLocalCheckMatchedFrames = _Undefined,
    _ijbfcz4y.EvidenceProvenanceLevel? provenanceLevel,
    Object? captureManifest = _Undefined,
    Object? captureSignature = _Undefined,
    Object? capturePublicKey = _Undefined,
    Object? captureKeyId = _Undefined,
    Object? captureKeyStorage = _Undefined,
    DateTime? capturedAt,
    DateTime? submittedAt,
  }) {
    return ActionEvidence(
      id: id is _is.UuidValue? ? id : this.id,
      attemptId: attemptId ?? this.attemptId,
      requirementId: requirementId ?? this.requirementId,
      kind: kind ?? this.kind,
      storagePath: storagePath is String? ? storagePath : this.storagePath,
      storageVersionId: storageVersionId is String?
          ? storageVersionId
          : this.storageVersionId,
      mimeType: mimeType is String? ? mimeType : this.mimeType,
      sha256Digest: sha256Digest is String? ? sha256Digest : this.sha256Digest,
      byteLength: byteLength is int? ? byteLength : this.byteLength,
      durationSeconds: durationSeconds is int?
          ? durationSeconds
          : this.durationSeconds,
      location: location is _is.GeographyPoint? ? location : this.location,
      accuracyMeters: accuracyMeters is double?
          ? accuracyMeters
          : this.accuracyMeters,
      motionTraceJson: motionTraceJson is String?
          ? motionTraceJson
          : this.motionTraceJson,
      motionTraceSha256: motionTraceSha256 is String?
          ? motionTraceSha256
          : this.motionTraceSha256,
      motionSampleCount: motionSampleCount is int?
          ? motionSampleCount
          : this.motionSampleCount,
      motionDurationMilliseconds: motionDurationMilliseconds is int?
          ? motionDurationMilliseconds
          : this.motionDurationMilliseconds,
      motionAnalysisJson: motionAnalysisJson is String?
          ? motionAnalysisJson
          : this.motionAnalysisJson,
      deviceRepetitionCount: deviceRepetitionCount is int?
          ? deviceRepetitionCount
          : this.deviceRepetitionCount,
      deviceTrackerVersion: deviceTrackerVersion is String?
          ? deviceTrackerVersion
          : this.deviceTrackerVersion,
      spokenChallengeId: spokenChallengeId is _is.UuidValue?
          ? spokenChallengeId
          : this.spokenChallengeId,
      spokenChallengeWord: spokenChallengeWord is String?
          ? spokenChallengeWord
          : this.spokenChallengeWord,
      deviceLocalCheckModelId: deviceLocalCheckModelId is String?
          ? deviceLocalCheckModelId
          : this.deviceLocalCheckModelId,
      deviceLocalCheckModelSha256: deviceLocalCheckModelSha256 is String?
          ? deviceLocalCheckModelSha256
          : this.deviceLocalCheckModelSha256,
      deviceLocalCheckLabel: deviceLocalCheckLabel is String?
          ? deviceLocalCheckLabel
          : this.deviceLocalCheckLabel,
      deviceLocalCheckScore: deviceLocalCheckScore is double?
          ? deviceLocalCheckScore
          : this.deviceLocalCheckScore,
      deviceLocalCheckMatchedFrames: deviceLocalCheckMatchedFrames is int?
          ? deviceLocalCheckMatchedFrames
          : this.deviceLocalCheckMatchedFrames,
      provenanceLevel: provenanceLevel ?? this.provenanceLevel,
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
      capturedAt: capturedAt ?? this.capturedAt,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }
}

class ActionEvidenceUpdateTable extends _is.UpdateTable<ActionEvidenceTable> {
  ActionEvidenceUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> attemptId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.attemptId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> requirementId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.requirementId,
    value,
  );

  _is.ColumnValue<
    _iws572ni.ActionRequirementKind,
    _iws572ni.ActionRequirementKind
  >
  kind(_iws572ni.ActionRequirementKind value) => _is.ColumnValue(
    table.kind,
    value,
  );

  _is.ColumnValue<String, String> storagePath(String? value) => _is.ColumnValue(
    table.storagePath,
    value,
  );

  _is.ColumnValue<String, String> storageVersionId(String? value) =>
      _is.ColumnValue(
        table.storageVersionId,
        value,
      );

  _is.ColumnValue<String, String> mimeType(String? value) => _is.ColumnValue(
    table.mimeType,
    value,
  );

  _is.ColumnValue<String, String> sha256Digest(String? value) =>
      _is.ColumnValue(
        table.sha256Digest,
        value,
      );

  _is.ColumnValue<int, int> byteLength(int? value) => _is.ColumnValue(
    table.byteLength,
    value,
  );

  _is.ColumnValue<int, int> durationSeconds(int? value) => _is.ColumnValue(
    table.durationSeconds,
    value,
  );

  _is.ColumnValue<_is.GeographyPoint, _is.GeographyPoint> location(
    _is.GeographyPoint? value,
  ) => _is.ColumnValue(
    table.location,
    value,
  );

  _is.ColumnValue<double, double> accuracyMeters(double? value) =>
      _is.ColumnValue(
        table.accuracyMeters,
        value,
      );

  _is.ColumnValue<String, String> motionTraceJson(String? value) =>
      _is.ColumnValue(
        table.motionTraceJson,
        value,
      );

  _is.ColumnValue<String, String> motionTraceSha256(String? value) =>
      _is.ColumnValue(
        table.motionTraceSha256,
        value,
      );

  _is.ColumnValue<int, int> motionSampleCount(int? value) => _is.ColumnValue(
    table.motionSampleCount,
    value,
  );

  _is.ColumnValue<int, int> motionDurationMilliseconds(int? value) =>
      _is.ColumnValue(
        table.motionDurationMilliseconds,
        value,
      );

  _is.ColumnValue<String, String> motionAnalysisJson(String? value) =>
      _is.ColumnValue(
        table.motionAnalysisJson,
        value,
      );

  _is.ColumnValue<int, int> deviceRepetitionCount(int? value) =>
      _is.ColumnValue(
        table.deviceRepetitionCount,
        value,
      );

  _is.ColumnValue<String, String> deviceTrackerVersion(String? value) =>
      _is.ColumnValue(
        table.deviceTrackerVersion,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> spokenChallengeId(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.spokenChallengeId,
    value,
  );

  _is.ColumnValue<String, String> spokenChallengeWord(String? value) =>
      _is.ColumnValue(
        table.spokenChallengeWord,
        value,
      );

  _is.ColumnValue<String, String> deviceLocalCheckModelId(String? value) =>
      _is.ColumnValue(
        table.deviceLocalCheckModelId,
        value,
      );

  _is.ColumnValue<String, String> deviceLocalCheckModelSha256(String? value) =>
      _is.ColumnValue(
        table.deviceLocalCheckModelSha256,
        value,
      );

  _is.ColumnValue<String, String> deviceLocalCheckLabel(String? value) =>
      _is.ColumnValue(
        table.deviceLocalCheckLabel,
        value,
      );

  _is.ColumnValue<double, double> deviceLocalCheckScore(double? value) =>
      _is.ColumnValue(
        table.deviceLocalCheckScore,
        value,
      );

  _is.ColumnValue<int, int> deviceLocalCheckMatchedFrames(int? value) =>
      _is.ColumnValue(
        table.deviceLocalCheckMatchedFrames,
        value,
      );

  _is.ColumnValue<
    _ijbfcz4y.EvidenceProvenanceLevel,
    _ijbfcz4y.EvidenceProvenanceLevel
  >
  provenanceLevel(_ijbfcz4y.EvidenceProvenanceLevel value) => _is.ColumnValue(
    table.provenanceLevel,
    value,
  );

  _is.ColumnValue<String, String> captureManifest(String? value) =>
      _is.ColumnValue(
        table.captureManifest,
        value,
      );

  _is.ColumnValue<String, String> captureSignature(String? value) =>
      _is.ColumnValue(
        table.captureSignature,
        value,
      );

  _is.ColumnValue<String, String> capturePublicKey(String? value) =>
      _is.ColumnValue(
        table.capturePublicKey,
        value,
      );

  _is.ColumnValue<String, String> captureKeyId(String? value) =>
      _is.ColumnValue(
        table.captureKeyId,
        value,
      );

  _is.ColumnValue<String, String> captureKeyStorage(String? value) =>
      _is.ColumnValue(
        table.captureKeyStorage,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> capturedAt(DateTime value) =>
      _is.ColumnValue(
        table.capturedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> submittedAt(DateTime value) =>
      _is.ColumnValue(
        table.submittedAt,
        value,
      );
}

class ActionEvidenceTable extends _is.Table<_is.UuidValue?> {
  ActionEvidenceTable({super.tableRelation})
    : super(tableName: 'verily_action_evidence') {
    updateTable = ActionEvidenceUpdateTable(this);
    attemptId = _is.ColumnUuid(
      'attemptId',
      this,
    );
    requirementId = _is.ColumnUuid(
      'requirementId',
      this,
    );
    kind = _is.ColumnEnum(
      'kind',
      this,
      _is.EnumSerialization.byName,
    );
    storagePath = _is.ColumnString(
      'storagePath',
      this,
    );
    storageVersionId = _is.ColumnString(
      'storageVersionId',
      this,
    );
    mimeType = _is.ColumnString(
      'mimeType',
      this,
    );
    sha256Digest = _is.ColumnString(
      'sha256Digest',
      this,
    );
    byteLength = _is.ColumnInt(
      'byteLength',
      this,
    );
    durationSeconds = _is.ColumnInt(
      'durationSeconds',
      this,
    );
    location = _is.ColumnGeographyPoint(
      'location',
      this,
    );
    accuracyMeters = _is.ColumnDouble(
      'accuracyMeters',
      this,
    );
    motionTraceJson = _is.ColumnString(
      'motionTraceJson',
      this,
    );
    motionTraceSha256 = _is.ColumnString(
      'motionTraceSha256',
      this,
    );
    motionSampleCount = _is.ColumnInt(
      'motionSampleCount',
      this,
    );
    motionDurationMilliseconds = _is.ColumnInt(
      'motionDurationMilliseconds',
      this,
    );
    motionAnalysisJson = _is.ColumnString(
      'motionAnalysisJson',
      this,
    );
    deviceRepetitionCount = _is.ColumnInt(
      'deviceRepetitionCount',
      this,
    );
    deviceTrackerVersion = _is.ColumnString(
      'deviceTrackerVersion',
      this,
    );
    spokenChallengeId = _is.ColumnUuid(
      'spokenChallengeId',
      this,
    );
    spokenChallengeWord = _is.ColumnString(
      'spokenChallengeWord',
      this,
    );
    deviceLocalCheckModelId = _is.ColumnString(
      'deviceLocalCheckModelId',
      this,
    );
    deviceLocalCheckModelSha256 = _is.ColumnString(
      'deviceLocalCheckModelSha256',
      this,
    );
    deviceLocalCheckLabel = _is.ColumnString(
      'deviceLocalCheckLabel',
      this,
    );
    deviceLocalCheckScore = _is.ColumnDouble(
      'deviceLocalCheckScore',
      this,
    );
    deviceLocalCheckMatchedFrames = _is.ColumnInt(
      'deviceLocalCheckMatchedFrames',
      this,
    );
    provenanceLevel = _is.ColumnEnum(
      'provenanceLevel',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    captureManifest = _is.ColumnString(
      'captureManifest',
      this,
    );
    captureSignature = _is.ColumnString(
      'captureSignature',
      this,
    );
    capturePublicKey = _is.ColumnString(
      'capturePublicKey',
      this,
    );
    captureKeyId = _is.ColumnString(
      'captureKeyId',
      this,
    );
    captureKeyStorage = _is.ColumnString(
      'captureKeyStorage',
      this,
    );
    capturedAt = _is.ColumnDateTime(
      'capturedAt',
      this,
    );
    submittedAt = _is.ColumnDateTime(
      'submittedAt',
      this,
    );
  }

  late final ActionEvidenceUpdateTable updateTable;

  late final _is.ColumnUuid attemptId;

  late final _is.ColumnUuid requirementId;

  late final _is.ColumnEnum<_iws572ni.ActionRequirementKind> kind;

  late final _is.ColumnString storagePath;

  late final _is.ColumnString storageVersionId;

  late final _is.ColumnString mimeType;

  late final _is.ColumnString sha256Digest;

  late final _is.ColumnInt byteLength;

  late final _is.ColumnInt durationSeconds;

  late final _is.ColumnGeographyPoint location;

  late final _is.ColumnDouble accuracyMeters;

  late final _is.ColumnString motionTraceJson;

  late final _is.ColumnString motionTraceSha256;

  late final _is.ColumnInt motionSampleCount;

  late final _is.ColumnInt motionDurationMilliseconds;

  late final _is.ColumnString motionAnalysisJson;

  /// Advisory on-device count shown to the participant; never a decision input.
  late final _is.ColumnInt deviceRepetitionCount;

  /// Identifies the on-device tracker and model that produced the count.
  late final _is.ColumnString deviceTrackerVersion;

  /// The live challenge this recording was bound to, and its word, kept with
  /// the proof so verifiers and reviewers check exactly what was asked.
  late final _is.ColumnUuid spokenChallengeId;

  late final _is.ColumnString spokenChallengeWord;

  /// The phone's advisory local-check result, kept for calibration only.
  late final _is.ColumnString deviceLocalCheckModelId;

  late final _is.ColumnString deviceLocalCheckModelSha256;

  late final _is.ColumnString deviceLocalCheckLabel;

  late final _is.ColumnDouble deviceLocalCheckScore;

  late final _is.ColumnInt deviceLocalCheckMatchedFrames;

  late final _is.ColumnEnum<_ijbfcz4y.EvidenceProvenanceLevel> provenanceLevel;

  late final _is.ColumnString captureManifest;

  late final _is.ColumnString captureSignature;

  late final _is.ColumnString capturePublicKey;

  late final _is.ColumnString captureKeyId;

  late final _is.ColumnString captureKeyStorage;

  late final _is.ColumnDateTime capturedAt;

  late final _is.ColumnDateTime submittedAt;

  @override
  List<_is.Column> get columns => [
    id,
    attemptId,
    requirementId,
    kind,
    storagePath,
    storageVersionId,
    mimeType,
    sha256Digest,
    byteLength,
    durationSeconds,
    location,
    accuracyMeters,
    motionTraceJson,
    motionTraceSha256,
    motionSampleCount,
    motionDurationMilliseconds,
    motionAnalysisJson,
    deviceRepetitionCount,
    deviceTrackerVersion,
    spokenChallengeId,
    spokenChallengeWord,
    deviceLocalCheckModelId,
    deviceLocalCheckModelSha256,
    deviceLocalCheckLabel,
    deviceLocalCheckScore,
    deviceLocalCheckMatchedFrames,
    provenanceLevel,
    captureManifest,
    captureSignature,
    capturePublicKey,
    captureKeyId,
    captureKeyStorage,
    capturedAt,
    submittedAt,
  ];
}

class ActionEvidenceInclude extends _is.IncludeObject {
  ActionEvidenceInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<_is.UuidValue?> get table => ActionEvidence.t;
}

class ActionEvidenceIncludeList extends _is.IncludeList {
  ActionEvidenceIncludeList._({
    _is.WhereExpressionBuilder<ActionEvidenceTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ActionEvidence.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => ActionEvidence.t;
}

class ActionEvidenceRepository {
  const ActionEvidenceRepository._();

  /// Returns a list of [ActionEvidence]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<ActionEvidence>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionEvidenceTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionEvidenceTable>? orderBy,
    _is.OrderByListBuilder<ActionEvidenceTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ActionEvidence>(
      where: where?.call(ActionEvidence.t),
      orderBy: orderBy?.call(ActionEvidence.t),
      orderByList: orderByList?.call(ActionEvidence.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ActionEvidence] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<ActionEvidence?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionEvidenceTable>? where,
    int? offset,
    _is.OrderByBuilder<ActionEvidenceTable>? orderBy,
    _is.OrderByListBuilder<ActionEvidenceTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ActionEvidence>(
      where: where?.call(ActionEvidence.t),
      orderBy: orderBy?.call(ActionEvidence.t),
      orderByList: orderByList?.call(ActionEvidence.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ActionEvidence] by its [id] or null if no such row exists.
  Future<ActionEvidence?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ActionEvidence>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ActionEvidence]s in the list and returns the inserted rows.
  ///
  /// The returned [ActionEvidence]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionEvidence>> insert(
    _is.DatabaseSession session,
    List<ActionEvidence> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ActionEvidence>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ActionEvidence] and returns the inserted row.
  ///
  /// The returned [ActionEvidence] will have its `id` field set.
  Future<ActionEvidence> insertRow(
    _is.DatabaseSession session,
    ActionEvidence row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ActionEvidence>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ActionEvidence]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [ActionEvidence]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionEvidence>> upsert(
    _is.DatabaseSession session,
    List<ActionEvidence> rows, {
    required _is.ColumnSelections<ActionEvidenceTable> conflictColumns,
    _is.ColumnSelections<ActionEvidenceTable>? updateColumns,
    _is.WhereExpressionBuilder<ActionEvidenceTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ActionEvidence>(
      rows,
      conflictColumns: conflictColumns(ActionEvidence.t),
      updateColumns: updateColumns?.call(ActionEvidence.t),
      updateWhere: updateWhere?.call(ActionEvidence.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ActionEvidence] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [ActionEvidence] will have its `id` field set.
  Future<ActionEvidence?> upsertRow(
    _is.DatabaseSession session,
    ActionEvidence row, {
    required _is.ColumnSelections<ActionEvidenceTable> conflictColumns,
    _is.ColumnSelections<ActionEvidenceTable>? updateColumns,
    _is.WhereExpressionBuilder<ActionEvidenceTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ActionEvidence>(
      row,
      conflictColumns: conflictColumns(ActionEvidence.t),
      updateColumns: updateColumns?.call(ActionEvidence.t),
      updateWhere: updateWhere?.call(ActionEvidence.t),
      transaction: transaction,
    );
  }

  /// Updates all [ActionEvidence]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionEvidence>> update(
    _is.DatabaseSession session,
    List<ActionEvidence> rows, {
    _is.ColumnSelections<ActionEvidenceTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ActionEvidence>(
      rows,
      columns: columns?.call(ActionEvidence.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ActionEvidence]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ActionEvidence> updateRow(
    _is.DatabaseSession session,
    ActionEvidence row, {
    _is.ColumnSelections<ActionEvidenceTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ActionEvidence>(
      row,
      columns: columns?.call(ActionEvidence.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ActionEvidence] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ActionEvidence?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<ActionEvidenceUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ActionEvidence>(
      id,
      columnValues: columnValues(ActionEvidence.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ActionEvidence]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionEvidence>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ActionEvidenceUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ActionEvidenceTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionEvidenceTable>? orderBy,
    _is.OrderByListBuilder<ActionEvidenceTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ActionEvidence>(
      columnValues: columnValues(ActionEvidence.t.updateTable),
      where: where(ActionEvidence.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ActionEvidence.t),
      orderByList: orderByList?.call(ActionEvidence.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ActionEvidence]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionEvidence>> delete(
    _is.DatabaseSession session,
    List<ActionEvidence> rows, {
    _is.OrderByBuilder<ActionEvidenceTable>? orderBy,
    _is.OrderByListBuilder<ActionEvidenceTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ActionEvidence>(
      rows,
      orderBy: orderBy?.call(ActionEvidence.t),
      orderByList: orderByList?.call(ActionEvidence.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ActionEvidence].
  Future<ActionEvidence> deleteRow(
    _is.DatabaseSession session,
    ActionEvidence row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ActionEvidence>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionEvidence>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ActionEvidenceTable> where,
    _is.OrderByBuilder<ActionEvidenceTable>? orderBy,
    _is.OrderByListBuilder<ActionEvidenceTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ActionEvidence>(
      where: where(ActionEvidence.t),
      orderBy: orderBy?.call(ActionEvidence.t),
      orderByList: orderByList?.call(ActionEvidence.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionEvidenceTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ActionEvidence>(
      where: where?.call(ActionEvidence.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ActionEvidence] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ActionEvidenceTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ActionEvidence>(
      where: where(ActionEvidence.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
