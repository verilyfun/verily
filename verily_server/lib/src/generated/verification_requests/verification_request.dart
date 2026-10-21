/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_null_comparison

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:verily_server/src/generated/protocol.dart' as _itf691yl;

import '../verification_requests/verification_request_check.dart' as _imw473lb;
import '../verification_requests/verification_request_kind.dart' as _ix1e7zpf;
import '../verification_requests/verification_request_status.dart' as _icvl19bi;

/// An App's request that one person prove something with the Verily app.
/// Accepting it creates a private, single-use action with one attempt that
/// runs through the normal capture and verification pipeline.
abstract class VerificationRequest
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  VerificationRequest._({
    this.id,
    required this.appId,
    required this.kind,
    this.instructions,
    required this.check,
    this.placeLatitude,
    this.placeLongitude,
    this.placeRadiusMeters,
    required this.spokenChallenge,
    required this.shareEvidence,
    required this.redirectUri,
    this.state,
    required this.status,
    required this.expiresAt,
    this.participantAuthUserId,
    this.participantAuthUser,
    this.subject,
    this.actionDefinitionId,
    this.attemptId,
    this.acceptedAt,
    bool? evidenceShared,
    this.codeHash,
    this.codeExpiresAt,
    this.codeUsedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  }) : evidenceShared = evidenceShared ?? false;

  factory VerificationRequest({
    _is.UuidValue? id,
    required _is.UuidValue appId,
    required _ix1e7zpf.VerificationRequestKind kind,
    String? instructions,
    required _imw473lb.VerificationRequestCheck check,
    double? placeLatitude,
    double? placeLongitude,
    double? placeRadiusMeters,
    required bool spokenChallenge,
    required bool shareEvidence,
    required String redirectUri,
    String? state,
    required _icvl19bi.VerificationRequestStatus status,
    required DateTime expiresAt,
    _is.UuidValue? participantAuthUserId,
    _iacs.AuthUser? participantAuthUser,
    String? subject,
    _is.UuidValue? actionDefinitionId,
    _is.UuidValue? attemptId,
    DateTime? acceptedAt,
    bool? evidenceShared,
    String? codeHash,
    DateTime? codeExpiresAt,
    DateTime? codeUsedAt,
    DateTime? completedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _VerificationRequestImpl;

  factory VerificationRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return VerificationRequest(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      appId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['appId']),
      kind: _ix1e7zpf.VerificationRequestKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      instructions: jsonSerialization['instructions'] as String?,
      check: _imw473lb.VerificationRequestCheck.fromJson(
        (jsonSerialization['check'] as String),
      ),
      placeLatitude: (jsonSerialization['placeLatitude'] as num?)?.toDouble(),
      placeLongitude: (jsonSerialization['placeLongitude'] as num?)?.toDouble(),
      placeRadiusMeters: (jsonSerialization['placeRadiusMeters'] as num?)
          ?.toDouble(),
      spokenChallenge: _is.BoolJsonExtension.fromJson(
        jsonSerialization['spokenChallenge'],
      ),
      shareEvidence: _is.BoolJsonExtension.fromJson(
        jsonSerialization['shareEvidence'],
      ),
      redirectUri: jsonSerialization['redirectUri'] as String,
      state: jsonSerialization['state'] as String?,
      status: _icvl19bi.VerificationRequestStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      expiresAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      participantAuthUserId: jsonSerialization['participantAuthUserId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['participantAuthUserId'],
            ),
      participantAuthUser: jsonSerialization['participantAuthUser'] == null
          ? null
          : _itf691yl.Protocol().deserialize<_iacs.AuthUser>(
              jsonSerialization['participantAuthUser'],
            ),
      subject: jsonSerialization['subject'] as String?,
      actionDefinitionId: jsonSerialization['actionDefinitionId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['actionDefinitionId'],
            ),
      attemptId: jsonSerialization['attemptId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['attemptId']),
      acceptedAt: jsonSerialization['acceptedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['acceptedAt']),
      evidenceShared: jsonSerialization['evidenceShared'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['evidenceShared']),
      codeHash: jsonSerialization['codeHash'] as String?,
      codeExpiresAt: jsonSerialization['codeExpiresAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['codeExpiresAt'],
            ),
      codeUsedAt: jsonSerialization['codeUsedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['codeUsedAt']),
      completedAt: jsonSerialization['completedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['completedAt'],
            ),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = VerificationRequestTable();

  static const db = VerificationRequestRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue appId;

  _ix1e7zpf.VerificationRequestKind kind;

  String? instructions;

  _imw473lb.VerificationRequestCheck check;

  /// The App's place, private to Verily; receipts say only inside or outside.
  double? placeLatitude;

  double? placeLongitude;

  double? placeRadiusMeters;

  bool spokenChallenge;

  bool shareEvidence;

  String redirectUri;

  String? state;

  _icvl19bi.VerificationRequestStatus status;

  DateTime expiresAt;

  _is.UuidValue? participantAuthUserId;

  _iacs.AuthUser? participantAuthUser;

  /// The participant's pairwise subject for this App, set on acceptance.
  String? subject;

  _is.UuidValue? actionDefinitionId;

  _is.UuidValue? attemptId;

  DateTime? acceptedAt;

  /// Whether the person agreed to let the App download the capture.
  bool evidenceShared;

  /// Hash of the one-time receipt code handed to the App's redirect.
  String? codeHash;

  DateTime? codeExpiresAt;

  DateTime? codeUsedAt;

  DateTime? completedAt;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [VerificationRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  VerificationRequest copyWith({
    _is.UuidValue? id,
    _is.UuidValue? appId,
    _ix1e7zpf.VerificationRequestKind? kind,
    String? instructions,
    _imw473lb.VerificationRequestCheck? check,
    double? placeLatitude,
    double? placeLongitude,
    double? placeRadiusMeters,
    bool? spokenChallenge,
    bool? shareEvidence,
    String? redirectUri,
    String? state,
    _icvl19bi.VerificationRequestStatus? status,
    DateTime? expiresAt,
    _is.UuidValue? participantAuthUserId,
    _iacs.AuthUser? participantAuthUser,
    String? subject,
    _is.UuidValue? actionDefinitionId,
    _is.UuidValue? attemptId,
    DateTime? acceptedAt,
    bool? evidenceShared,
    String? codeHash,
    DateTime? codeExpiresAt,
    DateTime? codeUsedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'VerificationRequest',
      if (id != null) 'id': id?.toJson(),
      'appId': appId.toJson(),
      'kind': kind.toJson(),
      if (instructions != null) 'instructions': instructions,
      'check': check.toJson(),
      if (placeLatitude != null) 'placeLatitude': placeLatitude,
      if (placeLongitude != null) 'placeLongitude': placeLongitude,
      if (placeRadiusMeters != null) 'placeRadiusMeters': placeRadiusMeters,
      'spokenChallenge': spokenChallenge,
      'shareEvidence': shareEvidence,
      'redirectUri': redirectUri,
      if (state != null) 'state': state,
      'status': status.toJson(),
      'expiresAt': expiresAt.toJson(),
      if (participantAuthUserId != null)
        'participantAuthUserId': participantAuthUserId?.toJson(),
      if (participantAuthUser != null)
        'participantAuthUser': participantAuthUser?.toJson(),
      if (subject != null) 'subject': subject,
      if (actionDefinitionId != null)
        'actionDefinitionId': actionDefinitionId?.toJson(),
      if (attemptId != null) 'attemptId': attemptId?.toJson(),
      if (acceptedAt != null) 'acceptedAt': acceptedAt?.toJson(),
      'evidenceShared': evidenceShared,
      if (codeHash != null) 'codeHash': codeHash,
      if (codeExpiresAt != null) 'codeExpiresAt': codeExpiresAt?.toJson(),
      if (codeUsedAt != null) 'codeUsedAt': codeUsedAt?.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static VerificationRequestInclude include({
    _iacs.AuthUserInclude? participantAuthUser,
  }) {
    return VerificationRequestInclude._(
      participantAuthUser: participantAuthUser,
    );
  }

  static VerificationRequestIncludeList includeList({
    _is.WhereExpressionBuilder<VerificationRequestTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VerificationRequestTable>? orderBy,
    _is.OrderByListBuilder<VerificationRequestTable>? orderByList,
    VerificationRequestInclude? include,
  }) {
    return VerificationRequestIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(VerificationRequest.t),
      orderByList: orderByList?.call(VerificationRequest.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _VerificationRequestImpl extends VerificationRequest {
  _VerificationRequestImpl({
    _is.UuidValue? id,
    required _is.UuidValue appId,
    required _ix1e7zpf.VerificationRequestKind kind,
    String? instructions,
    required _imw473lb.VerificationRequestCheck check,
    double? placeLatitude,
    double? placeLongitude,
    double? placeRadiusMeters,
    required bool spokenChallenge,
    required bool shareEvidence,
    required String redirectUri,
    String? state,
    required _icvl19bi.VerificationRequestStatus status,
    required DateTime expiresAt,
    _is.UuidValue? participantAuthUserId,
    _iacs.AuthUser? participantAuthUser,
    String? subject,
    _is.UuidValue? actionDefinitionId,
    _is.UuidValue? attemptId,
    DateTime? acceptedAt,
    bool? evidenceShared,
    String? codeHash,
    DateTime? codeExpiresAt,
    DateTime? codeUsedAt,
    DateTime? completedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         appId: appId,
         kind: kind,
         instructions: instructions,
         check: check,
         placeLatitude: placeLatitude,
         placeLongitude: placeLongitude,
         placeRadiusMeters: placeRadiusMeters,
         spokenChallenge: spokenChallenge,
         shareEvidence: shareEvidence,
         redirectUri: redirectUri,
         state: state,
         status: status,
         expiresAt: expiresAt,
         participantAuthUserId: participantAuthUserId,
         participantAuthUser: participantAuthUser,
         subject: subject,
         actionDefinitionId: actionDefinitionId,
         attemptId: attemptId,
         acceptedAt: acceptedAt,
         evidenceShared: evidenceShared,
         codeHash: codeHash,
         codeExpiresAt: codeExpiresAt,
         codeUsedAt: codeUsedAt,
         completedAt: completedAt,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [VerificationRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  VerificationRequest copyWith({
    Object? id = _Undefined,
    _is.UuidValue? appId,
    _ix1e7zpf.VerificationRequestKind? kind,
    Object? instructions = _Undefined,
    _imw473lb.VerificationRequestCheck? check,
    Object? placeLatitude = _Undefined,
    Object? placeLongitude = _Undefined,
    Object? placeRadiusMeters = _Undefined,
    bool? spokenChallenge,
    bool? shareEvidence,
    String? redirectUri,
    Object? state = _Undefined,
    _icvl19bi.VerificationRequestStatus? status,
    DateTime? expiresAt,
    Object? participantAuthUserId = _Undefined,
    Object? participantAuthUser = _Undefined,
    Object? subject = _Undefined,
    Object? actionDefinitionId = _Undefined,
    Object? attemptId = _Undefined,
    Object? acceptedAt = _Undefined,
    bool? evidenceShared,
    Object? codeHash = _Undefined,
    Object? codeExpiresAt = _Undefined,
    Object? codeUsedAt = _Undefined,
    Object? completedAt = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VerificationRequest(
      id: id is _is.UuidValue? ? id : this.id,
      appId: appId ?? this.appId,
      kind: kind ?? this.kind,
      instructions: instructions is String? ? instructions : this.instructions,
      check: check ?? this.check,
      placeLatitude: placeLatitude is double?
          ? placeLatitude
          : this.placeLatitude,
      placeLongitude: placeLongitude is double?
          ? placeLongitude
          : this.placeLongitude,
      placeRadiusMeters: placeRadiusMeters is double?
          ? placeRadiusMeters
          : this.placeRadiusMeters,
      spokenChallenge: spokenChallenge ?? this.spokenChallenge,
      shareEvidence: shareEvidence ?? this.shareEvidence,
      redirectUri: redirectUri ?? this.redirectUri,
      state: state is String? ? state : this.state,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      participantAuthUserId: participantAuthUserId is _is.UuidValue?
          ? participantAuthUserId
          : this.participantAuthUserId,
      participantAuthUser: participantAuthUser is _iacs.AuthUser?
          ? participantAuthUser
          : this.participantAuthUser?.copyWith(),
      subject: subject is String? ? subject : this.subject,
      actionDefinitionId: actionDefinitionId is _is.UuidValue?
          ? actionDefinitionId
          : this.actionDefinitionId,
      attemptId: attemptId is _is.UuidValue? ? attemptId : this.attemptId,
      acceptedAt: acceptedAt is DateTime? ? acceptedAt : this.acceptedAt,
      evidenceShared: evidenceShared ?? this.evidenceShared,
      codeHash: codeHash is String? ? codeHash : this.codeHash,
      codeExpiresAt: codeExpiresAt is DateTime?
          ? codeExpiresAt
          : this.codeExpiresAt,
      codeUsedAt: codeUsedAt is DateTime? ? codeUsedAt : this.codeUsedAt,
      completedAt: completedAt is DateTime? ? completedAt : this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class VerificationRequestUpdateTable
    extends _is.UpdateTable<VerificationRequestTable> {
  VerificationRequestUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> appId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.appId,
        value,
      );

  _is.ColumnValue<
    _ix1e7zpf.VerificationRequestKind,
    _ix1e7zpf.VerificationRequestKind
  >
  kind(_ix1e7zpf.VerificationRequestKind value) => _is.ColumnValue(
    table.kind,
    value,
  );

  _is.ColumnValue<String, String> instructions(String? value) =>
      _is.ColumnValue(
        table.instructions,
        value,
      );

  _is.ColumnValue<
    _imw473lb.VerificationRequestCheck,
    _imw473lb.VerificationRequestCheck
  >
  check(_imw473lb.VerificationRequestCheck value) => _is.ColumnValue(
    table.check,
    value,
  );

  _is.ColumnValue<double, double> placeLatitude(double? value) =>
      _is.ColumnValue(
        table.placeLatitude,
        value,
      );

  _is.ColumnValue<double, double> placeLongitude(double? value) =>
      _is.ColumnValue(
        table.placeLongitude,
        value,
      );

  _is.ColumnValue<double, double> placeRadiusMeters(double? value) =>
      _is.ColumnValue(
        table.placeRadiusMeters,
        value,
      );

  _is.ColumnValue<bool, bool> spokenChallenge(bool value) => _is.ColumnValue(
    table.spokenChallenge,
    value,
  );

  _is.ColumnValue<bool, bool> shareEvidence(bool value) => _is.ColumnValue(
    table.shareEvidence,
    value,
  );

  _is.ColumnValue<String, String> redirectUri(String value) => _is.ColumnValue(
    table.redirectUri,
    value,
  );

  _is.ColumnValue<String, String> state(String? value) => _is.ColumnValue(
    table.state,
    value,
  );

  _is.ColumnValue<
    _icvl19bi.VerificationRequestStatus,
    _icvl19bi.VerificationRequestStatus
  >
  status(_icvl19bi.VerificationRequestStatus value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> expiresAt(DateTime value) =>
      _is.ColumnValue(
        table.expiresAt,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> participantAuthUserId(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.participantAuthUserId,
    value,
  );

  _is.ColumnValue<String, String> subject(String? value) => _is.ColumnValue(
    table.subject,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> actionDefinitionId(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.actionDefinitionId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> attemptId(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.attemptId,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> acceptedAt(DateTime? value) =>
      _is.ColumnValue(
        table.acceptedAt,
        value,
      );

  _is.ColumnValue<bool, bool> evidenceShared(bool value) => _is.ColumnValue(
    table.evidenceShared,
    value,
  );

  _is.ColumnValue<String, String> codeHash(String? value) => _is.ColumnValue(
    table.codeHash,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> codeExpiresAt(DateTime? value) =>
      _is.ColumnValue(
        table.codeExpiresAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> codeUsedAt(DateTime? value) =>
      _is.ColumnValue(
        table.codeUsedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> completedAt(DateTime? value) =>
      _is.ColumnValue(
        table.completedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _is.ColumnValue(
        table.updatedAt,
        value,
      );
}

class VerificationRequestTable extends _is.Table<_is.UuidValue?> {
  VerificationRequestTable({super.tableRelation})
    : super(tableName: 'verily_verification_request') {
    updateTable = VerificationRequestUpdateTable(this);
    appId = _is.ColumnUuid(
      'appId',
      this,
    );
    kind = _is.ColumnEnum(
      'kind',
      this,
      _is.EnumSerialization.byName,
    );
    instructions = _is.ColumnString(
      'instructions',
      this,
    );
    check = _is.ColumnEnum(
      'check',
      this,
      _is.EnumSerialization.byName,
    );
    placeLatitude = _is.ColumnDouble(
      'placeLatitude',
      this,
    );
    placeLongitude = _is.ColumnDouble(
      'placeLongitude',
      this,
    );
    placeRadiusMeters = _is.ColumnDouble(
      'placeRadiusMeters',
      this,
    );
    spokenChallenge = _is.ColumnBool(
      'spokenChallenge',
      this,
    );
    shareEvidence = _is.ColumnBool(
      'shareEvidence',
      this,
    );
    redirectUri = _is.ColumnString(
      'redirectUri',
      this,
    );
    state = _is.ColumnString(
      'state',
      this,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
    );
    expiresAt = _is.ColumnDateTime(
      'expiresAt',
      this,
    );
    participantAuthUserId = _is.ColumnUuid(
      'participantAuthUserId',
      this,
    );
    subject = _is.ColumnString(
      'subject',
      this,
    );
    actionDefinitionId = _is.ColumnUuid(
      'actionDefinitionId',
      this,
    );
    attemptId = _is.ColumnUuid(
      'attemptId',
      this,
    );
    acceptedAt = _is.ColumnDateTime(
      'acceptedAt',
      this,
    );
    evidenceShared = _is.ColumnBool(
      'evidenceShared',
      this,
      hasDefault: true,
    );
    codeHash = _is.ColumnString(
      'codeHash',
      this,
    );
    codeExpiresAt = _is.ColumnDateTime(
      'codeExpiresAt',
      this,
    );
    codeUsedAt = _is.ColumnDateTime(
      'codeUsedAt',
      this,
    );
    completedAt = _is.ColumnDateTime(
      'completedAt',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    updatedAt = _is.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final VerificationRequestUpdateTable updateTable;

  late final _is.ColumnUuid appId;

  late final _is.ColumnEnum<_ix1e7zpf.VerificationRequestKind> kind;

  late final _is.ColumnString instructions;

  late final _is.ColumnEnum<_imw473lb.VerificationRequestCheck> check;

  /// The App's place, private to Verily; receipts say only inside or outside.
  late final _is.ColumnDouble placeLatitude;

  late final _is.ColumnDouble placeLongitude;

  late final _is.ColumnDouble placeRadiusMeters;

  late final _is.ColumnBool spokenChallenge;

  late final _is.ColumnBool shareEvidence;

  late final _is.ColumnString redirectUri;

  late final _is.ColumnString state;

  late final _is.ColumnEnum<_icvl19bi.VerificationRequestStatus> status;

  late final _is.ColumnDateTime expiresAt;

  late final _is.ColumnUuid participantAuthUserId;

  _iacs.AuthUserTable? _participantAuthUser;

  /// The participant's pairwise subject for this App, set on acceptance.
  late final _is.ColumnString subject;

  late final _is.ColumnUuid actionDefinitionId;

  late final _is.ColumnUuid attemptId;

  late final _is.ColumnDateTime acceptedAt;

  /// Whether the person agreed to let the App download the capture.
  late final _is.ColumnBool evidenceShared;

  /// Hash of the one-time receipt code handed to the App's redirect.
  late final _is.ColumnString codeHash;

  late final _is.ColumnDateTime codeExpiresAt;

  late final _is.ColumnDateTime codeUsedAt;

  late final _is.ColumnDateTime completedAt;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  _iacs.AuthUserTable get participantAuthUser {
    if (_participantAuthUser != null) return _participantAuthUser!;
    _participantAuthUser = _is.createRelationTable(
      relationFieldName: 'participantAuthUser',
      field: VerificationRequest.t.participantAuthUserId,
      foreignField: _iacs.AuthUser.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iacs.AuthUserTable(tableRelation: foreignTableRelation),
    );
    return _participantAuthUser!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    appId,
    kind,
    instructions,
    check,
    placeLatitude,
    placeLongitude,
    placeRadiusMeters,
    spokenChallenge,
    shareEvidence,
    redirectUri,
    state,
    status,
    expiresAt,
    participantAuthUserId,
    subject,
    actionDefinitionId,
    attemptId,
    acceptedAt,
    evidenceShared,
    codeHash,
    codeExpiresAt,
    codeUsedAt,
    completedAt,
    createdAt,
    updatedAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'participantAuthUser') {
      return participantAuthUser;
    }
    return null;
  }
}

class VerificationRequestInclude extends _is.IncludeObject {
  VerificationRequestInclude._({_iacs.AuthUserInclude? participantAuthUser}) {
    _participantAuthUser = participantAuthUser;
  }

  _iacs.AuthUserInclude? _participantAuthUser;

  @override
  Map<String, _is.Include?> get includes => {
    'participantAuthUser': _participantAuthUser,
  };

  @override
  _is.Table<_is.UuidValue?> get table => VerificationRequest.t;
}

class VerificationRequestIncludeList extends _is.IncludeList {
  VerificationRequestIncludeList._({
    _is.WhereExpressionBuilder<VerificationRequestTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(VerificationRequest.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => VerificationRequest.t;
}

class VerificationRequestRepository {
  const VerificationRequestRepository._();

  final attachRow = const VerificationRequestAttachRowRepository._();

  final detachRow = const VerificationRequestDetachRowRepository._();

  /// Returns a list of [VerificationRequest]s matching the given query parameters.
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
  Future<List<VerificationRequest>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VerificationRequestTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VerificationRequestTable>? orderBy,
    _is.OrderByListBuilder<VerificationRequestTable>? orderByList,
    _is.Transaction? transaction,
    VerificationRequestInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<VerificationRequest>(
      where: where?.call(VerificationRequest.t),
      orderBy: orderBy?.call(VerificationRequest.t),
      orderByList: orderByList?.call(VerificationRequest.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [VerificationRequest] matching the given query parameters.
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
  Future<VerificationRequest?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VerificationRequestTable>? where,
    int? offset,
    _is.OrderByBuilder<VerificationRequestTable>? orderBy,
    _is.OrderByListBuilder<VerificationRequestTable>? orderByList,
    _is.Transaction? transaction,
    VerificationRequestInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<VerificationRequest>(
      where: where?.call(VerificationRequest.t),
      orderBy: orderBy?.call(VerificationRequest.t),
      orderByList: orderByList?.call(VerificationRequest.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [VerificationRequest] by its [id] or null if no such row exists.
  Future<VerificationRequest?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    VerificationRequestInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<VerificationRequest>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [VerificationRequest]s in the list and returns the inserted rows.
  ///
  /// The returned [VerificationRequest]s will have their `id` fields set.
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
  Future<List<VerificationRequest>> insert(
    _is.DatabaseSession session,
    List<VerificationRequest> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<VerificationRequest>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [VerificationRequest] and returns the inserted row.
  ///
  /// The returned [VerificationRequest] will have its `id` field set.
  Future<VerificationRequest> insertRow(
    _is.DatabaseSession session,
    VerificationRequest row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<VerificationRequest>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [VerificationRequest]s in the list and returns the resulting rows.
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
  /// The returned [VerificationRequest]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<VerificationRequest>> upsert(
    _is.DatabaseSession session,
    List<VerificationRequest> rows, {
    required _is.ColumnSelections<VerificationRequestTable> conflictColumns,
    _is.ColumnSelections<VerificationRequestTable>? updateColumns,
    _is.WhereExpressionBuilder<VerificationRequestTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<VerificationRequest>(
      rows,
      conflictColumns: conflictColumns(VerificationRequest.t),
      updateColumns: updateColumns?.call(VerificationRequest.t),
      updateWhere: updateWhere?.call(VerificationRequest.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [VerificationRequest] and returns the resulting row.
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
  /// The returned [VerificationRequest] will have its `id` field set.
  Future<VerificationRequest?> upsertRow(
    _is.DatabaseSession session,
    VerificationRequest row, {
    required _is.ColumnSelections<VerificationRequestTable> conflictColumns,
    _is.ColumnSelections<VerificationRequestTable>? updateColumns,
    _is.WhereExpressionBuilder<VerificationRequestTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<VerificationRequest>(
      row,
      conflictColumns: conflictColumns(VerificationRequest.t),
      updateColumns: updateColumns?.call(VerificationRequest.t),
      updateWhere: updateWhere?.call(VerificationRequest.t),
      transaction: transaction,
    );
  }

  /// Updates all [VerificationRequest]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<VerificationRequest>> update(
    _is.DatabaseSession session,
    List<VerificationRequest> rows, {
    _is.ColumnSelections<VerificationRequestTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<VerificationRequest>(
      rows,
      columns: columns?.call(VerificationRequest.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [VerificationRequest]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<VerificationRequest> updateRow(
    _is.DatabaseSession session,
    VerificationRequest row, {
    _is.ColumnSelections<VerificationRequestTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<VerificationRequest>(
      row,
      columns: columns?.call(VerificationRequest.t),
      transaction: transaction,
    );
  }

  /// Updates a single [VerificationRequest] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<VerificationRequest?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<VerificationRequestUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<VerificationRequest>(
      id,
      columnValues: columnValues(VerificationRequest.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [VerificationRequest]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<VerificationRequest>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<VerificationRequestUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<VerificationRequestTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VerificationRequestTable>? orderBy,
    _is.OrderByListBuilder<VerificationRequestTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<VerificationRequest>(
      columnValues: columnValues(VerificationRequest.t.updateTable),
      where: where(VerificationRequest.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(VerificationRequest.t),
      orderByList: orderByList?.call(VerificationRequest.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [VerificationRequest]s in the list and returns the deleted rows.
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
  Future<List<VerificationRequest>> delete(
    _is.DatabaseSession session,
    List<VerificationRequest> rows, {
    _is.OrderByBuilder<VerificationRequestTable>? orderBy,
    _is.OrderByListBuilder<VerificationRequestTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<VerificationRequest>(
      rows,
      orderBy: orderBy?.call(VerificationRequest.t),
      orderByList: orderByList?.call(VerificationRequest.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [VerificationRequest].
  Future<VerificationRequest> deleteRow(
    _is.DatabaseSession session,
    VerificationRequest row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<VerificationRequest>(
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
  Future<List<VerificationRequest>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<VerificationRequestTable> where,
    _is.OrderByBuilder<VerificationRequestTable>? orderBy,
    _is.OrderByListBuilder<VerificationRequestTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<VerificationRequest>(
      where: where(VerificationRequest.t),
      orderBy: orderBy?.call(VerificationRequest.t),
      orderByList: orderByList?.call(VerificationRequest.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VerificationRequestTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<VerificationRequest>(
      where: where?.call(VerificationRequest.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [VerificationRequest] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<VerificationRequestTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<VerificationRequest>(
      where: where(VerificationRequest.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class VerificationRequestAttachRowRepository {
  const VerificationRequestAttachRowRepository._();

  /// Creates a relation between the given [VerificationRequest] and [AuthUser]
  /// by setting the [VerificationRequest]'s foreign key `participantAuthUserId` to refer to the [AuthUser].
  Future<void> participantAuthUser(
    _is.DatabaseSession session,
    VerificationRequest verificationRequest,
    _iacs.AuthUser participantAuthUser, {
    _is.Transaction? transaction,
  }) async {
    if (verificationRequest.id == null) {
      throw ArgumentError.notNull('verificationRequest.id');
    }
    if (participantAuthUser.id == null) {
      throw ArgumentError.notNull('participantAuthUser.id');
    }

    var $verificationRequest = verificationRequest.copyWith(
      participantAuthUserId: participantAuthUser.id,
    );
    await session.db.updateRow<VerificationRequest>(
      $verificationRequest,
      columns: [VerificationRequest.t.participantAuthUserId],
      transaction: transaction,
    );
  }
}

class VerificationRequestDetachRowRepository {
  const VerificationRequestDetachRowRepository._();

  /// Detaches the relation between this [VerificationRequest] and the [AuthUser] set in `participantAuthUser`
  /// by setting the [VerificationRequest]'s foreign key `participantAuthUserId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> participantAuthUser(
    _is.DatabaseSession session,
    VerificationRequest verificationRequest, {
    _is.Transaction? transaction,
  }) async {
    if (verificationRequest.id == null) {
      throw ArgumentError.notNull('verificationRequest.id');
    }

    var $verificationRequest = verificationRequest.copyWith(
      participantAuthUserId: null,
    );
    await session.db.updateRow<VerificationRequest>(
      $verificationRequest,
      columns: [VerificationRequest.t.participantAuthUserId],
      transaction: transaction,
    );
  }
}
