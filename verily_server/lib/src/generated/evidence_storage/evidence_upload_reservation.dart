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
import 'dart:async' as _ida;

import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:verily_server/src/generated/protocol.dart' as _itf691yl;

import '../action_verification/action_requirement_kind.dart' as _iws572ni;
import '../evidence_storage/evidence_upload_status.dart' as _iaqghu9u;

/// Bounded immutable evidence-upload binding; retention indexes drive private-media cleanup.
abstract class EvidenceUploadReservation
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  EvidenceUploadReservation._({
    this.id,
    required this.authUserId,
    this.authUser,
    required this.attemptId,
    required this.requirementId,
    required this.kind,
    required this.storagePath,
    required this.contentType,
    required this.byteLength,
    required this.status,
    this.spokenChallengeId,
    int? requestCount,
    int? confirmationAttemptCount,
    DateTime? reservedAt,
    DateTime? lastSignedAt,
    required this.uploadExpiresAt,
    required this.retainUntil,
    this.confirmationStartedAt,
    this.confirmedAt,
    this.storageVersionId,
  }) : requestCount = requestCount ?? 1,
       confirmationAttemptCount = confirmationAttemptCount ?? 0,
       reservedAt = reservedAt ?? DateTime.now(),
       lastSignedAt = lastSignedAt ?? DateTime.now();

  factory EvidenceUploadReservation({
    _is.UuidValue? id,
    required _is.UuidValue authUserId,
    _iacs.AuthUser? authUser,
    required _is.UuidValue attemptId,
    required _is.UuidValue requirementId,
    required _iws572ni.ActionRequirementKind kind,
    required String storagePath,
    required String contentType,
    required int byteLength,
    required _iaqghu9u.EvidenceUploadStatus status,
    _is.UuidValue? spokenChallengeId,
    int? requestCount,
    int? confirmationAttemptCount,
    DateTime? reservedAt,
    DateTime? lastSignedAt,
    required DateTime uploadExpiresAt,
    required DateTime retainUntil,
    DateTime? confirmationStartedAt,
    DateTime? confirmedAt,
    String? storageVersionId,
  }) = _EvidenceUploadReservationImpl;

  factory EvidenceUploadReservation.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return EvidenceUploadReservation(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      authUserId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['authUserId'],
      ),
      authUser: jsonSerialization['authUser'] == null
          ? null
          : _itf691yl.Protocol().deserialize<_iacs.AuthUser>(
              jsonSerialization['authUser'],
            ),
      attemptId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['attemptId'],
      ),
      requirementId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['requirementId'],
      ),
      kind: _iws572ni.ActionRequirementKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      storagePath: jsonSerialization['storagePath'] as String,
      contentType: jsonSerialization['contentType'] as String,
      byteLength: jsonSerialization['byteLength'] as int,
      status: _iaqghu9u.EvidenceUploadStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      spokenChallengeId: jsonSerialization['spokenChallengeId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['spokenChallengeId'],
            ),
      requestCount: jsonSerialization['requestCount'] as int?,
      confirmationAttemptCount:
          jsonSerialization['confirmationAttemptCount'] as int?,
      reservedAt: jsonSerialization['reservedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['reservedAt']),
      lastSignedAt: jsonSerialization['lastSignedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastSignedAt'],
            ),
      uploadExpiresAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['uploadExpiresAt'],
      ),
      retainUntil: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['retainUntil'],
      ),
      confirmationStartedAt: jsonSerialization['confirmationStartedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['confirmationStartedAt'],
            ),
      confirmedAt: jsonSerialization['confirmedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['confirmedAt'],
            ),
      storageVersionId: jsonSerialization['storageVersionId'] as String?,
    );
  }

  static final t = EvidenceUploadReservationTable();

  static const db = EvidenceUploadReservationRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue authUserId;

  _iacs.AuthUser? authUser;

  _is.UuidValue attemptId;

  _is.UuidValue requirementId;

  _iws572ni.ActionRequirementKind kind;

  String storagePath;

  String contentType;

  int byteLength;

  _iaqghu9u.EvidenceUploadStatus status;

  /// The live word bound to this recording when its rule requires one.
  _is.UuidValue? spokenChallengeId;

  int requestCount;

  int confirmationAttemptCount;

  DateTime reservedAt;

  DateTime lastSignedAt;

  DateTime uploadExpiresAt;

  DateTime retainUntil;

  DateTime? confirmationStartedAt;

  DateTime? confirmedAt;

  String? storageVersionId;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [EvidenceUploadReservation]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  EvidenceUploadReservation copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? authUserId,
    _iacs.AuthUser? authUser =
        const _UndefinedEvidenceUploadReservation$authUser(),
    _is.UuidValue? attemptId,
    _is.UuidValue? requirementId,
    _iws572ni.ActionRequirementKind? kind,
    String? storagePath,
    String? contentType,
    int? byteLength,
    _iaqghu9u.EvidenceUploadStatus? status,
    _is.UuidValue? spokenChallengeId = const _is.$UndefinedUuidValue(),
    int? requestCount,
    int? confirmationAttemptCount,
    DateTime? reservedAt,
    DateTime? lastSignedAt,
    DateTime? uploadExpiresAt,
    DateTime? retainUntil,
    DateTime? confirmationStartedAt = const _is.$UndefinedDateTime(),
    DateTime? confirmedAt = const _is.$UndefinedDateTime(),
    String? storageVersionId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'EvidenceUploadReservation',
      if (id != null) 'id': id?.toJson(),
      'authUserId': authUserId.toJson(),
      if (authUser != null) 'authUser': authUser?.toJson(),
      'attemptId': attemptId.toJson(),
      'requirementId': requirementId.toJson(),
      'kind': kind.toJson(),
      'storagePath': storagePath,
      'contentType': contentType,
      'byteLength': byteLength,
      'status': status.toJson(),
      if (spokenChallengeId != null)
        'spokenChallengeId': spokenChallengeId?.toJson(),
      'requestCount': requestCount,
      'confirmationAttemptCount': confirmationAttemptCount,
      'reservedAt': reservedAt.toJson(),
      'lastSignedAt': lastSignedAt.toJson(),
      'uploadExpiresAt': uploadExpiresAt.toJson(),
      'retainUntil': retainUntil.toJson(),
      if (confirmationStartedAt != null)
        'confirmationStartedAt': confirmationStartedAt?.toJson(),
      if (confirmedAt != null) 'confirmedAt': confirmedAt?.toJson(),
      if (storageVersionId != null) 'storageVersionId': storageVersionId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static EvidenceUploadReservationInclude include({
    _iacs.AuthUserInclude? authUser,
  }) {
    return EvidenceUploadReservationInclude._(authUser: authUser);
  }

  static EvidenceUploadReservationIncludeList includeList({
    _is.WhereExpressionBuilder<EvidenceUploadReservationTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EvidenceUploadReservationTable>? orderBy,
    _is.OrderByListBuilder<EvidenceUploadReservationTable>? orderByList,
    EvidenceUploadReservationInclude? include,
  }) {
    return EvidenceUploadReservationIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EvidenceUploadReservation.t),
      orderByList: orderByList?.call(EvidenceUploadReservation.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedEvidenceUploadReservation$authUser extends _is.UndefinedSentinel
    implements _iacs.AuthUser {
  const _UndefinedEvidenceUploadReservation$authUser();
}

class _EvidenceUploadReservationImpl extends EvidenceUploadReservation {
  _EvidenceUploadReservationImpl({
    _is.UuidValue? id,
    required _is.UuidValue authUserId,
    _iacs.AuthUser? authUser,
    required _is.UuidValue attemptId,
    required _is.UuidValue requirementId,
    required _iws572ni.ActionRequirementKind kind,
    required String storagePath,
    required String contentType,
    required int byteLength,
    required _iaqghu9u.EvidenceUploadStatus status,
    _is.UuidValue? spokenChallengeId,
    int? requestCount,
    int? confirmationAttemptCount,
    DateTime? reservedAt,
    DateTime? lastSignedAt,
    required DateTime uploadExpiresAt,
    required DateTime retainUntil,
    DateTime? confirmationStartedAt,
    DateTime? confirmedAt,
    String? storageVersionId,
  }) : super._(
         id: id,
         authUserId: authUserId,
         authUser: authUser,
         attemptId: attemptId,
         requirementId: requirementId,
         kind: kind,
         storagePath: storagePath,
         contentType: contentType,
         byteLength: byteLength,
         status: status,
         spokenChallengeId: spokenChallengeId,
         requestCount: requestCount,
         confirmationAttemptCount: confirmationAttemptCount,
         reservedAt: reservedAt,
         lastSignedAt: lastSignedAt,
         uploadExpiresAt: uploadExpiresAt,
         retainUntil: retainUntil,
         confirmationStartedAt: confirmationStartedAt,
         confirmedAt: confirmedAt,
         storageVersionId: storageVersionId,
       );

  /// Returns a shallow copy of this [EvidenceUploadReservation]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  EvidenceUploadReservation copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? authUserId,
    _iacs.AuthUser? authUser =
        const _UndefinedEvidenceUploadReservation$authUser(),
    _is.UuidValue? attemptId,
    _is.UuidValue? requirementId,
    _iws572ni.ActionRequirementKind? kind,
    String? storagePath,
    String? contentType,
    int? byteLength,
    _iaqghu9u.EvidenceUploadStatus? status,
    _is.UuidValue? spokenChallengeId = const _is.$UndefinedUuidValue(),
    int? requestCount,
    int? confirmationAttemptCount,
    DateTime? reservedAt,
    DateTime? lastSignedAt,
    DateTime? uploadExpiresAt,
    DateTime? retainUntil,
    DateTime? confirmationStartedAt = const _is.$UndefinedDateTime(),
    DateTime? confirmedAt = const _is.$UndefinedDateTime(),
    Object? storageVersionId = _Undefined,
  }) {
    return EvidenceUploadReservation(
      id: id is _is.UndefinedSentinel ? this.id : id,
      authUserId: authUserId ?? this.authUserId,
      authUser: authUser is _is.UndefinedSentinel
          ? this.authUser?.copyWith()
          : authUser,
      attemptId: attemptId ?? this.attemptId,
      requirementId: requirementId ?? this.requirementId,
      kind: kind ?? this.kind,
      storagePath: storagePath ?? this.storagePath,
      contentType: contentType ?? this.contentType,
      byteLength: byteLength ?? this.byteLength,
      status: status ?? this.status,
      spokenChallengeId: spokenChallengeId is _is.UndefinedSentinel
          ? this.spokenChallengeId
          : spokenChallengeId,
      requestCount: requestCount ?? this.requestCount,
      confirmationAttemptCount:
          confirmationAttemptCount ?? this.confirmationAttemptCount,
      reservedAt: reservedAt ?? this.reservedAt,
      lastSignedAt: lastSignedAt ?? this.lastSignedAt,
      uploadExpiresAt: uploadExpiresAt ?? this.uploadExpiresAt,
      retainUntil: retainUntil ?? this.retainUntil,
      confirmationStartedAt: confirmationStartedAt is _is.UndefinedSentinel
          ? this.confirmationStartedAt
          : confirmationStartedAt,
      confirmedAt: confirmedAt is _is.UndefinedSentinel
          ? this.confirmedAt
          : confirmedAt,
      storageVersionId: storageVersionId is String?
          ? storageVersionId
          : this.storageVersionId,
    );
  }
}

class EvidenceUploadReservationUpdateTable
    extends _is.UpdateTable<EvidenceUploadReservationTable> {
  EvidenceUploadReservationUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> authUserId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.authUserId,
    value,
  );

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

  _is.ColumnValue<String, String> storagePath(String value) => _is.ColumnValue(
    table.storagePath,
    value,
  );

  _is.ColumnValue<String, String> contentType(String value) => _is.ColumnValue(
    table.contentType,
    value,
  );

  _is.ColumnValue<int, int> byteLength(int value) => _is.ColumnValue(
    table.byteLength,
    value,
  );

  _is.ColumnValue<
    _iaqghu9u.EvidenceUploadStatus,
    _iaqghu9u.EvidenceUploadStatus
  >
  status(_iaqghu9u.EvidenceUploadStatus value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> spokenChallengeId(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.spokenChallengeId,
    value,
  );

  _is.ColumnValue<int, int> requestCount(int value) => _is.ColumnValue(
    table.requestCount,
    value,
  );

  _is.ColumnValue<int, int> confirmationAttemptCount(int value) =>
      _is.ColumnValue(
        table.confirmationAttemptCount,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> reservedAt(DateTime value) =>
      _is.ColumnValue(
        table.reservedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> lastSignedAt(DateTime value) =>
      _is.ColumnValue(
        table.lastSignedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> uploadExpiresAt(DateTime value) =>
      _is.ColumnValue(
        table.uploadExpiresAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> retainUntil(DateTime value) =>
      _is.ColumnValue(
        table.retainUntil,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> confirmationStartedAt(DateTime? value) =>
      _is.ColumnValue(
        table.confirmationStartedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> confirmedAt(DateTime? value) =>
      _is.ColumnValue(
        table.confirmedAt,
        value,
      );

  _is.ColumnValue<String, String> storageVersionId(String? value) =>
      _is.ColumnValue(
        table.storageVersionId,
        value,
      );
}

class EvidenceUploadReservationTable extends _is.Table<_is.UuidValue?> {
  EvidenceUploadReservationTable({super.tableRelation})
    : super(tableName: 'verily_evidence_upload_reservation') {
    updateTable = EvidenceUploadReservationUpdateTable(this);
    authUserId = _is.ColumnUuid(
      'authUserId',
      this,
    );
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
    contentType = _is.ColumnString(
      'contentType',
      this,
    );
    byteLength = _is.ColumnInt(
      'byteLength',
      this,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
    );
    spokenChallengeId = _is.ColumnUuid(
      'spokenChallengeId',
      this,
    );
    requestCount = _is.ColumnInt(
      'requestCount',
      this,
      hasDefault: true,
    );
    confirmationAttemptCount = _is.ColumnInt(
      'confirmationAttemptCount',
      this,
      hasDefault: true,
    );
    reservedAt = _is.ColumnDateTime(
      'reservedAt',
      this,
    );
    lastSignedAt = _is.ColumnDateTime(
      'lastSignedAt',
      this,
    );
    uploadExpiresAt = _is.ColumnDateTime(
      'uploadExpiresAt',
      this,
    );
    retainUntil = _is.ColumnDateTime(
      'retainUntil',
      this,
    );
    confirmationStartedAt = _is.ColumnDateTime(
      'confirmationStartedAt',
      this,
    );
    confirmedAt = _is.ColumnDateTime(
      'confirmedAt',
      this,
    );
    storageVersionId = _is.ColumnString(
      'storageVersionId',
      this,
    );
  }

  late final EvidenceUploadReservationUpdateTable updateTable;

  late final _is.ColumnUuid authUserId;

  _iacs.AuthUserTable? _authUser;

  late final _is.ColumnUuid attemptId;

  late final _is.ColumnUuid requirementId;

  late final _is.ColumnEnum<_iws572ni.ActionRequirementKind> kind;

  late final _is.ColumnString storagePath;

  late final _is.ColumnString contentType;

  late final _is.ColumnInt byteLength;

  late final _is.ColumnEnum<_iaqghu9u.EvidenceUploadStatus> status;

  /// The live word bound to this recording when its rule requires one.
  late final _is.ColumnUuid spokenChallengeId;

  late final _is.ColumnInt requestCount;

  late final _is.ColumnInt confirmationAttemptCount;

  late final _is.ColumnDateTime reservedAt;

  late final _is.ColumnDateTime lastSignedAt;

  late final _is.ColumnDateTime uploadExpiresAt;

  late final _is.ColumnDateTime retainUntil;

  late final _is.ColumnDateTime confirmationStartedAt;

  late final _is.ColumnDateTime confirmedAt;

  late final _is.ColumnString storageVersionId;

  _iacs.AuthUserTable get authUser {
    if (_authUser != null) return _authUser!;
    _authUser = _is.createRelationTable(
      relationFieldName: 'authUser',
      field: EvidenceUploadReservation.t.authUserId,
      foreignField: _iacs.AuthUser.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iacs.AuthUserTable(tableRelation: foreignTableRelation),
    );
    return _authUser!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    authUserId,
    attemptId,
    requirementId,
    kind,
    storagePath,
    contentType,
    byteLength,
    status,
    spokenChallengeId,
    requestCount,
    confirmationAttemptCount,
    reservedAt,
    lastSignedAt,
    uploadExpiresAt,
    retainUntil,
    confirmationStartedAt,
    confirmedAt,
    storageVersionId,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'authUser') {
      return authUser;
    }
    return null;
  }
}

class EvidenceUploadReservationInclude extends _is.IncludeObject {
  EvidenceUploadReservationInclude._({_iacs.AuthUserInclude? authUser}) {
    _authUser = authUser;
  }

  _iacs.AuthUserInclude? _authUser;

  @override
  Map<String, _is.Include?> get includes => {'authUser': _authUser};

  @override
  _is.Table<_is.UuidValue?> get table => EvidenceUploadReservation.t;
}

class EvidenceUploadReservationIncludeList extends _is.IncludeList {
  EvidenceUploadReservationIncludeList._({
    _is.WhereExpressionBuilder<EvidenceUploadReservationTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(EvidenceUploadReservation.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => EvidenceUploadReservation.t;
}

class EvidenceUploadReservationRepository {
  const EvidenceUploadReservationRepository._();

  final attachRow = const EvidenceUploadReservationAttachRowRepository._();

  /// Returns a list of [EvidenceUploadReservation]s matching the given query parameters.
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
  Future<List<EvidenceUploadReservation>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EvidenceUploadReservationTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EvidenceUploadReservationTable>? orderBy,
    _is.OrderByListBuilder<EvidenceUploadReservationTable>? orderByList,
    _is.Transaction? transaction,
    EvidenceUploadReservationInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<EvidenceUploadReservation>(
      where: where?.call(EvidenceUploadReservation.t),
      orderBy: orderBy?.call(EvidenceUploadReservation.t),
      orderByList: orderByList?.call(EvidenceUploadReservation.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [EvidenceUploadReservation]s matching the given query parameters every time the
  /// source tables are modified.
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
  /// Use [throttle] to specify the minimum interval between queries. It can
  /// also be set to `null`, in which case the stream will only be throttled
  /// when its subscription is paused.
  ///
  /// Source tables are collected from the queried table, [where], [orderBy],
  /// [orderByList], and the [include] graph. [alsoTriggerOnTables] is added
  /// to that set. Pass [Table] instances such as `EvidenceUploadReservation.t`.
  ///
  /// Raw [Expression] SQL is not inspected. Tables referenced only in raw
  /// SQL must be passed via [alsoTriggerOnTables].
  ///
  /// The stream always reads committed state and never joins an ambient
  /// [Transaction]. Emissions for a write fire after that write commits.
  ///
  /// Currently only supported on SQLite. Calling this method on PostgreSQL
  /// throws an [UnsupportedError].
  ///
  /// ```dart
  /// var subscription = Persons.db.watch(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// ).listen((persons) {
  ///   // Handle the latest matching rows.
  /// });
  /// ```
  _ida.Stream<List<EvidenceUploadReservation>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EvidenceUploadReservationTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EvidenceUploadReservationTable>? orderBy,
    _is.OrderByListBuilder<EvidenceUploadReservationTable>? orderByList,
    EvidenceUploadReservationInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<EvidenceUploadReservation>(
      where: where?.call(EvidenceUploadReservation.t),
      orderBy: orderBy?.call(EvidenceUploadReservation.t),
      orderByList: orderByList?.call(EvidenceUploadReservation.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [EvidenceUploadReservation] matching the given query parameters.
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
  Future<EvidenceUploadReservation?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EvidenceUploadReservationTable>? where,
    int? offset,
    _is.OrderByBuilder<EvidenceUploadReservationTable>? orderBy,
    _is.OrderByListBuilder<EvidenceUploadReservationTable>? orderByList,
    _is.Transaction? transaction,
    EvidenceUploadReservationInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<EvidenceUploadReservation>(
      where: where?.call(EvidenceUploadReservation.t),
      orderBy: orderBy?.call(EvidenceUploadReservation.t),
      orderByList: orderByList?.call(EvidenceUploadReservation.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [EvidenceUploadReservation] by its [id] or null if no such row exists.
  Future<EvidenceUploadReservation?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    EvidenceUploadReservationInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<EvidenceUploadReservation>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [EvidenceUploadReservation]s in the list and returns the inserted rows.
  ///
  /// The returned [EvidenceUploadReservation]s will have their `id` fields set.
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
  Future<List<EvidenceUploadReservation>> insert(
    _is.DatabaseSession session,
    List<EvidenceUploadReservation> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<EvidenceUploadReservation>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [EvidenceUploadReservation] and returns the inserted row.
  ///
  /// The returned [EvidenceUploadReservation] will have its `id` field set.
  Future<EvidenceUploadReservation> insertRow(
    _is.DatabaseSession session,
    EvidenceUploadReservation row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<EvidenceUploadReservation>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [EvidenceUploadReservation]s in the list and returns the resulting rows.
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
  /// The returned [EvidenceUploadReservation]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<EvidenceUploadReservation>> upsert(
    _is.DatabaseSession session,
    List<EvidenceUploadReservation> rows, {
    required _is.ColumnSelections<EvidenceUploadReservationTable>
    conflictColumns,
    _is.ColumnSelections<EvidenceUploadReservationTable>? updateColumns,
    _is.WhereExpressionBuilder<EvidenceUploadReservationTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<EvidenceUploadReservation>(
      rows,
      conflictColumns: conflictColumns(EvidenceUploadReservation.t),
      updateColumns: updateColumns?.call(EvidenceUploadReservation.t),
      updateWhere: updateWhere?.call(EvidenceUploadReservation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [EvidenceUploadReservation] and returns the resulting row.
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
  /// The returned [EvidenceUploadReservation] will have its `id` field set.
  Future<EvidenceUploadReservation?> upsertRow(
    _is.DatabaseSession session,
    EvidenceUploadReservation row, {
    required _is.ColumnSelections<EvidenceUploadReservationTable>
    conflictColumns,
    _is.ColumnSelections<EvidenceUploadReservationTable>? updateColumns,
    _is.WhereExpressionBuilder<EvidenceUploadReservationTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<EvidenceUploadReservation>(
      row,
      conflictColumns: conflictColumns(EvidenceUploadReservation.t),
      updateColumns: updateColumns?.call(EvidenceUploadReservation.t),
      updateWhere: updateWhere?.call(EvidenceUploadReservation.t),
      transaction: transaction,
    );
  }

  /// Updates all [EvidenceUploadReservation]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<EvidenceUploadReservation>> update(
    _is.DatabaseSession session,
    List<EvidenceUploadReservation> rows, {
    _is.ColumnSelections<EvidenceUploadReservationTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<EvidenceUploadReservation>(
      rows,
      columns: columns?.call(EvidenceUploadReservation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [EvidenceUploadReservation]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<EvidenceUploadReservation> updateRow(
    _is.DatabaseSession session,
    EvidenceUploadReservation row, {
    _is.ColumnSelections<EvidenceUploadReservationTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<EvidenceUploadReservation>(
      row,
      columns: columns?.call(EvidenceUploadReservation.t),
      transaction: transaction,
    );
  }

  /// Updates a single [EvidenceUploadReservation] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<EvidenceUploadReservation?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<EvidenceUploadReservationUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<EvidenceUploadReservation>(
      id,
      columnValues: columnValues(EvidenceUploadReservation.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [EvidenceUploadReservation]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<EvidenceUploadReservation>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<EvidenceUploadReservationUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<EvidenceUploadReservationTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EvidenceUploadReservationTable>? orderBy,
    _is.OrderByListBuilder<EvidenceUploadReservationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<EvidenceUploadReservation>(
      columnValues: columnValues(EvidenceUploadReservation.t.updateTable),
      where: where(EvidenceUploadReservation.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EvidenceUploadReservation.t),
      orderByList: orderByList?.call(EvidenceUploadReservation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [EvidenceUploadReservation]s in the list and returns the deleted rows.
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
  Future<List<EvidenceUploadReservation>> delete(
    _is.DatabaseSession session,
    List<EvidenceUploadReservation> rows, {
    _is.OrderByBuilder<EvidenceUploadReservationTable>? orderBy,
    _is.OrderByListBuilder<EvidenceUploadReservationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<EvidenceUploadReservation>(
      rows,
      orderBy: orderBy?.call(EvidenceUploadReservation.t),
      orderByList: orderByList?.call(EvidenceUploadReservation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [EvidenceUploadReservation].
  Future<EvidenceUploadReservation> deleteRow(
    _is.DatabaseSession session,
    EvidenceUploadReservation row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<EvidenceUploadReservation>(
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
  Future<List<EvidenceUploadReservation>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<EvidenceUploadReservationTable> where,
    _is.OrderByBuilder<EvidenceUploadReservationTable>? orderBy,
    _is.OrderByListBuilder<EvidenceUploadReservationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<EvidenceUploadReservation>(
      where: where(EvidenceUploadReservation.t),
      orderBy: orderBy?.call(EvidenceUploadReservation.t),
      orderByList: orderByList?.call(EvidenceUploadReservation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EvidenceUploadReservationTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<EvidenceUploadReservation>(
      where: where?.call(EvidenceUploadReservation.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [EvidenceUploadReservation] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<EvidenceUploadReservationTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<EvidenceUploadReservation>(
      where: where(EvidenceUploadReservation.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class EvidenceUploadReservationAttachRowRepository {
  const EvidenceUploadReservationAttachRowRepository._();

  /// Creates a relation between the given [EvidenceUploadReservation] and [AuthUser]
  /// by setting the [EvidenceUploadReservation]'s foreign key `authUserId` to refer to the [AuthUser].
  Future<void> authUser(
    _is.DatabaseSession session,
    EvidenceUploadReservation evidenceUploadReservation,
    _iacs.AuthUser authUser, {
    _is.Transaction? transaction,
  }) async {
    if (evidenceUploadReservation.id == null) {
      throw ArgumentError.notNull('evidenceUploadReservation.id');
    }
    if (authUser.id == null) {
      throw ArgumentError.notNull('authUser.id');
    }

    var $evidenceUploadReservation = evidenceUploadReservation.copyWith(
      authUserId: authUser.id,
    );
    await session.db.updateRow<EvidenceUploadReservation>(
      $evidenceUploadReservation,
      columns: [EvidenceUploadReservation.t.authUserId],
      transaction: transaction,
    );
  }
}
