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

import '../action_verification/evidence_appeal_status.dart' as _i246oa84;

/// One appeal per evidence item, retaining actor and resolution provenance.
/// [creatorAuthUserId] is denormalized from the action so the creator's
/// pending-appeal queue is one indexed read.
abstract class EvidenceAppeal
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  EvidenceAppeal._({
    this.id,
    required this.evidenceId,
    required this.attemptId,
    required this.creatorAuthUserId,
    this.creatorAuthUser,
    required this.participantAuthUserId,
    this.participantAuthUser,
    required this.reason,
    required this.status,
    this.resolutionNote,
    this.resolvedByAuthUserId,
    this.resolvedByAuthUser,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.resolvedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory EvidenceAppeal({
    _is.UuidValue? id,
    required _is.UuidValue evidenceId,
    required _is.UuidValue attemptId,
    required _is.UuidValue creatorAuthUserId,
    _iacs.AuthUser? creatorAuthUser,
    required _is.UuidValue participantAuthUserId,
    _iacs.AuthUser? participantAuthUser,
    required String reason,
    required _i246oa84.EvidenceAppealStatus status,
    String? resolutionNote,
    _is.UuidValue? resolvedByAuthUserId,
    _iacs.AuthUser? resolvedByAuthUser,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
  }) = _EvidenceAppealImpl;

  factory EvidenceAppeal.fromJson(Map<String, dynamic> jsonSerialization) {
    return EvidenceAppeal(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      evidenceId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['evidenceId'],
      ),
      attemptId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['attemptId'],
      ),
      creatorAuthUserId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['creatorAuthUserId'],
      ),
      creatorAuthUser: jsonSerialization['creatorAuthUser'] == null
          ? null
          : _itf691yl.Protocol().deserialize<_iacs.AuthUser>(
              jsonSerialization['creatorAuthUser'],
            ),
      participantAuthUserId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['participantAuthUserId'],
      ),
      participantAuthUser: jsonSerialization['participantAuthUser'] == null
          ? null
          : _itf691yl.Protocol().deserialize<_iacs.AuthUser>(
              jsonSerialization['participantAuthUser'],
            ),
      reason: jsonSerialization['reason'] as String,
      status: _i246oa84.EvidenceAppealStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      resolutionNote: jsonSerialization['resolutionNote'] as String?,
      resolvedByAuthUserId: jsonSerialization['resolvedByAuthUserId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['resolvedByAuthUserId'],
            ),
      resolvedByAuthUser: jsonSerialization['resolvedByAuthUser'] == null
          ? null
          : _itf691yl.Protocol().deserialize<_iacs.AuthUser>(
              jsonSerialization['resolvedByAuthUser'],
            ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      resolvedAt: jsonSerialization['resolvedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['resolvedAt']),
    );
  }

  static final t = EvidenceAppealTable();

  static const db = EvidenceAppealRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue evidenceId;

  _is.UuidValue attemptId;

  _is.UuidValue creatorAuthUserId;

  _iacs.AuthUser? creatorAuthUser;

  _is.UuidValue participantAuthUserId;

  _iacs.AuthUser? participantAuthUser;

  String reason;

  _i246oa84.EvidenceAppealStatus status;

  String? resolutionNote;

  _is.UuidValue? resolvedByAuthUserId;

  _iacs.AuthUser? resolvedByAuthUser;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? resolvedAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [EvidenceAppeal]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  EvidenceAppeal copyWith({
    _is.UuidValue? id,
    _is.UuidValue? evidenceId,
    _is.UuidValue? attemptId,
    _is.UuidValue? creatorAuthUserId,
    _iacs.AuthUser? creatorAuthUser,
    _is.UuidValue? participantAuthUserId,
    _iacs.AuthUser? participantAuthUser,
    String? reason,
    _i246oa84.EvidenceAppealStatus? status,
    String? resolutionNote,
    _is.UuidValue? resolvedByAuthUserId,
    _iacs.AuthUser? resolvedByAuthUser,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'EvidenceAppeal',
      if (id != null) 'id': id?.toJson(),
      'evidenceId': evidenceId.toJson(),
      'attemptId': attemptId.toJson(),
      'creatorAuthUserId': creatorAuthUserId.toJson(),
      if (creatorAuthUser != null) 'creatorAuthUser': creatorAuthUser?.toJson(),
      'participantAuthUserId': participantAuthUserId.toJson(),
      if (participantAuthUser != null)
        'participantAuthUser': participantAuthUser?.toJson(),
      'reason': reason,
      'status': status.toJson(),
      if (resolutionNote != null) 'resolutionNote': resolutionNote,
      if (resolvedByAuthUserId != null)
        'resolvedByAuthUserId': resolvedByAuthUserId?.toJson(),
      if (resolvedByAuthUser != null)
        'resolvedByAuthUser': resolvedByAuthUser?.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (resolvedAt != null) 'resolvedAt': resolvedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static EvidenceAppealInclude include({
    _iacs.AuthUserInclude? creatorAuthUser,
    _iacs.AuthUserInclude? participantAuthUser,
    _iacs.AuthUserInclude? resolvedByAuthUser,
  }) {
    return EvidenceAppealInclude._(
      creatorAuthUser: creatorAuthUser,
      participantAuthUser: participantAuthUser,
      resolvedByAuthUser: resolvedByAuthUser,
    );
  }

  static EvidenceAppealIncludeList includeList({
    _is.WhereExpressionBuilder<EvidenceAppealTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EvidenceAppealTable>? orderBy,
    _is.OrderByListBuilder<EvidenceAppealTable>? orderByList,
    EvidenceAppealInclude? include,
  }) {
    return EvidenceAppealIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EvidenceAppeal.t),
      orderByList: orderByList?.call(EvidenceAppeal.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _EvidenceAppealImpl extends EvidenceAppeal {
  _EvidenceAppealImpl({
    _is.UuidValue? id,
    required _is.UuidValue evidenceId,
    required _is.UuidValue attemptId,
    required _is.UuidValue creatorAuthUserId,
    _iacs.AuthUser? creatorAuthUser,
    required _is.UuidValue participantAuthUserId,
    _iacs.AuthUser? participantAuthUser,
    required String reason,
    required _i246oa84.EvidenceAppealStatus status,
    String? resolutionNote,
    _is.UuidValue? resolvedByAuthUserId,
    _iacs.AuthUser? resolvedByAuthUser,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
  }) : super._(
         id: id,
         evidenceId: evidenceId,
         attemptId: attemptId,
         creatorAuthUserId: creatorAuthUserId,
         creatorAuthUser: creatorAuthUser,
         participantAuthUserId: participantAuthUserId,
         participantAuthUser: participantAuthUser,
         reason: reason,
         status: status,
         resolutionNote: resolutionNote,
         resolvedByAuthUserId: resolvedByAuthUserId,
         resolvedByAuthUser: resolvedByAuthUser,
         createdAt: createdAt,
         updatedAt: updatedAt,
         resolvedAt: resolvedAt,
       );

  /// Returns a shallow copy of this [EvidenceAppeal]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  EvidenceAppeal copyWith({
    Object? id = _Undefined,
    _is.UuidValue? evidenceId,
    _is.UuidValue? attemptId,
    _is.UuidValue? creatorAuthUserId,
    Object? creatorAuthUser = _Undefined,
    _is.UuidValue? participantAuthUserId,
    Object? participantAuthUser = _Undefined,
    String? reason,
    _i246oa84.EvidenceAppealStatus? status,
    Object? resolutionNote = _Undefined,
    Object? resolvedByAuthUserId = _Undefined,
    Object? resolvedByAuthUser = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? resolvedAt = _Undefined,
  }) {
    return EvidenceAppeal(
      id: id is _is.UuidValue? ? id : this.id,
      evidenceId: evidenceId ?? this.evidenceId,
      attemptId: attemptId ?? this.attemptId,
      creatorAuthUserId: creatorAuthUserId ?? this.creatorAuthUserId,
      creatorAuthUser: creatorAuthUser is _iacs.AuthUser?
          ? creatorAuthUser
          : this.creatorAuthUser?.copyWith(),
      participantAuthUserId:
          participantAuthUserId ?? this.participantAuthUserId,
      participantAuthUser: participantAuthUser is _iacs.AuthUser?
          ? participantAuthUser
          : this.participantAuthUser?.copyWith(),
      reason: reason ?? this.reason,
      status: status ?? this.status,
      resolutionNote: resolutionNote is String?
          ? resolutionNote
          : this.resolutionNote,
      resolvedByAuthUserId: resolvedByAuthUserId is _is.UuidValue?
          ? resolvedByAuthUserId
          : this.resolvedByAuthUserId,
      resolvedByAuthUser: resolvedByAuthUser is _iacs.AuthUser?
          ? resolvedByAuthUser
          : this.resolvedByAuthUser?.copyWith(),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt is DateTime? ? resolvedAt : this.resolvedAt,
    );
  }
}

class EvidenceAppealUpdateTable extends _is.UpdateTable<EvidenceAppealTable> {
  EvidenceAppealUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> evidenceId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.evidenceId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> attemptId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.attemptId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> creatorAuthUserId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.creatorAuthUserId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> participantAuthUserId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.participantAuthUserId,
    value,
  );

  _is.ColumnValue<String, String> reason(String value) => _is.ColumnValue(
    table.reason,
    value,
  );

  _is.ColumnValue<
    _i246oa84.EvidenceAppealStatus,
    _i246oa84.EvidenceAppealStatus
  >
  status(_i246oa84.EvidenceAppealStatus value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<String, String> resolutionNote(String? value) =>
      _is.ColumnValue(
        table.resolutionNote,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> resolvedByAuthUserId(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.resolvedByAuthUserId,
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

  _is.ColumnValue<DateTime, DateTime> resolvedAt(DateTime? value) =>
      _is.ColumnValue(
        table.resolvedAt,
        value,
      );
}

class EvidenceAppealTable extends _is.Table<_is.UuidValue?> {
  EvidenceAppealTable({super.tableRelation})
    : super(tableName: 'verily_evidence_appeal') {
    updateTable = EvidenceAppealUpdateTable(this);
    evidenceId = _is.ColumnUuid(
      'evidenceId',
      this,
    );
    attemptId = _is.ColumnUuid(
      'attemptId',
      this,
    );
    creatorAuthUserId = _is.ColumnUuid(
      'creatorAuthUserId',
      this,
    );
    participantAuthUserId = _is.ColumnUuid(
      'participantAuthUserId',
      this,
    );
    reason = _is.ColumnString(
      'reason',
      this,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
    );
    resolutionNote = _is.ColumnString(
      'resolutionNote',
      this,
    );
    resolvedByAuthUserId = _is.ColumnUuid(
      'resolvedByAuthUserId',
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
    resolvedAt = _is.ColumnDateTime(
      'resolvedAt',
      this,
    );
  }

  late final EvidenceAppealUpdateTable updateTable;

  late final _is.ColumnUuid evidenceId;

  late final _is.ColumnUuid attemptId;

  late final _is.ColumnUuid creatorAuthUserId;

  _iacs.AuthUserTable? _creatorAuthUser;

  late final _is.ColumnUuid participantAuthUserId;

  _iacs.AuthUserTable? _participantAuthUser;

  late final _is.ColumnString reason;

  late final _is.ColumnEnum<_i246oa84.EvidenceAppealStatus> status;

  late final _is.ColumnString resolutionNote;

  late final _is.ColumnUuid resolvedByAuthUserId;

  _iacs.AuthUserTable? _resolvedByAuthUser;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  late final _is.ColumnDateTime resolvedAt;

  _iacs.AuthUserTable get creatorAuthUser {
    if (_creatorAuthUser != null) return _creatorAuthUser!;
    _creatorAuthUser = _is.createRelationTable(
      relationFieldName: 'creatorAuthUser',
      field: EvidenceAppeal.t.creatorAuthUserId,
      foreignField: _iacs.AuthUser.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iacs.AuthUserTable(tableRelation: foreignTableRelation),
    );
    return _creatorAuthUser!;
  }

  _iacs.AuthUserTable get participantAuthUser {
    if (_participantAuthUser != null) return _participantAuthUser!;
    _participantAuthUser = _is.createRelationTable(
      relationFieldName: 'participantAuthUser',
      field: EvidenceAppeal.t.participantAuthUserId,
      foreignField: _iacs.AuthUser.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iacs.AuthUserTable(tableRelation: foreignTableRelation),
    );
    return _participantAuthUser!;
  }

  _iacs.AuthUserTable get resolvedByAuthUser {
    if (_resolvedByAuthUser != null) return _resolvedByAuthUser!;
    _resolvedByAuthUser = _is.createRelationTable(
      relationFieldName: 'resolvedByAuthUser',
      field: EvidenceAppeal.t.resolvedByAuthUserId,
      foreignField: _iacs.AuthUser.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iacs.AuthUserTable(tableRelation: foreignTableRelation),
    );
    return _resolvedByAuthUser!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    evidenceId,
    attemptId,
    creatorAuthUserId,
    participantAuthUserId,
    reason,
    status,
    resolutionNote,
    resolvedByAuthUserId,
    createdAt,
    updatedAt,
    resolvedAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'creatorAuthUser') {
      return creatorAuthUser;
    }
    if (relationField == 'participantAuthUser') {
      return participantAuthUser;
    }
    if (relationField == 'resolvedByAuthUser') {
      return resolvedByAuthUser;
    }
    return null;
  }
}

class EvidenceAppealInclude extends _is.IncludeObject {
  EvidenceAppealInclude._({
    _iacs.AuthUserInclude? creatorAuthUser,
    _iacs.AuthUserInclude? participantAuthUser,
    _iacs.AuthUserInclude? resolvedByAuthUser,
  }) {
    _creatorAuthUser = creatorAuthUser;
    _participantAuthUser = participantAuthUser;
    _resolvedByAuthUser = resolvedByAuthUser;
  }

  _iacs.AuthUserInclude? _creatorAuthUser;

  _iacs.AuthUserInclude? _participantAuthUser;

  _iacs.AuthUserInclude? _resolvedByAuthUser;

  @override
  Map<String, _is.Include?> get includes => {
    'creatorAuthUser': _creatorAuthUser,
    'participantAuthUser': _participantAuthUser,
    'resolvedByAuthUser': _resolvedByAuthUser,
  };

  @override
  _is.Table<_is.UuidValue?> get table => EvidenceAppeal.t;
}

class EvidenceAppealIncludeList extends _is.IncludeList {
  EvidenceAppealIncludeList._({
    _is.WhereExpressionBuilder<EvidenceAppealTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(EvidenceAppeal.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => EvidenceAppeal.t;
}

class EvidenceAppealRepository {
  const EvidenceAppealRepository._();

  final attachRow = const EvidenceAppealAttachRowRepository._();

  final detachRow = const EvidenceAppealDetachRowRepository._();

  /// Returns a list of [EvidenceAppeal]s matching the given query parameters.
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
  Future<List<EvidenceAppeal>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EvidenceAppealTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EvidenceAppealTable>? orderBy,
    _is.OrderByListBuilder<EvidenceAppealTable>? orderByList,
    _is.Transaction? transaction,
    EvidenceAppealInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<EvidenceAppeal>(
      where: where?.call(EvidenceAppeal.t),
      orderBy: orderBy?.call(EvidenceAppeal.t),
      orderByList: orderByList?.call(EvidenceAppeal.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [EvidenceAppeal] matching the given query parameters.
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
  Future<EvidenceAppeal?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EvidenceAppealTable>? where,
    int? offset,
    _is.OrderByBuilder<EvidenceAppealTable>? orderBy,
    _is.OrderByListBuilder<EvidenceAppealTable>? orderByList,
    _is.Transaction? transaction,
    EvidenceAppealInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<EvidenceAppeal>(
      where: where?.call(EvidenceAppeal.t),
      orderBy: orderBy?.call(EvidenceAppeal.t),
      orderByList: orderByList?.call(EvidenceAppeal.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [EvidenceAppeal] by its [id] or null if no such row exists.
  Future<EvidenceAppeal?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    EvidenceAppealInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<EvidenceAppeal>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [EvidenceAppeal]s in the list and returns the inserted rows.
  ///
  /// The returned [EvidenceAppeal]s will have their `id` fields set.
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
  Future<List<EvidenceAppeal>> insert(
    _is.DatabaseSession session,
    List<EvidenceAppeal> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<EvidenceAppeal>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [EvidenceAppeal] and returns the inserted row.
  ///
  /// The returned [EvidenceAppeal] will have its `id` field set.
  Future<EvidenceAppeal> insertRow(
    _is.DatabaseSession session,
    EvidenceAppeal row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<EvidenceAppeal>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [EvidenceAppeal]s in the list and returns the resulting rows.
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
  /// The returned [EvidenceAppeal]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<EvidenceAppeal>> upsert(
    _is.DatabaseSession session,
    List<EvidenceAppeal> rows, {
    required _is.ColumnSelections<EvidenceAppealTable> conflictColumns,
    _is.ColumnSelections<EvidenceAppealTable>? updateColumns,
    _is.WhereExpressionBuilder<EvidenceAppealTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<EvidenceAppeal>(
      rows,
      conflictColumns: conflictColumns(EvidenceAppeal.t),
      updateColumns: updateColumns?.call(EvidenceAppeal.t),
      updateWhere: updateWhere?.call(EvidenceAppeal.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [EvidenceAppeal] and returns the resulting row.
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
  /// The returned [EvidenceAppeal] will have its `id` field set.
  Future<EvidenceAppeal?> upsertRow(
    _is.DatabaseSession session,
    EvidenceAppeal row, {
    required _is.ColumnSelections<EvidenceAppealTable> conflictColumns,
    _is.ColumnSelections<EvidenceAppealTable>? updateColumns,
    _is.WhereExpressionBuilder<EvidenceAppealTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<EvidenceAppeal>(
      row,
      conflictColumns: conflictColumns(EvidenceAppeal.t),
      updateColumns: updateColumns?.call(EvidenceAppeal.t),
      updateWhere: updateWhere?.call(EvidenceAppeal.t),
      transaction: transaction,
    );
  }

  /// Updates all [EvidenceAppeal]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<EvidenceAppeal>> update(
    _is.DatabaseSession session,
    List<EvidenceAppeal> rows, {
    _is.ColumnSelections<EvidenceAppealTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<EvidenceAppeal>(
      rows,
      columns: columns?.call(EvidenceAppeal.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [EvidenceAppeal]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<EvidenceAppeal> updateRow(
    _is.DatabaseSession session,
    EvidenceAppeal row, {
    _is.ColumnSelections<EvidenceAppealTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<EvidenceAppeal>(
      row,
      columns: columns?.call(EvidenceAppeal.t),
      transaction: transaction,
    );
  }

  /// Updates a single [EvidenceAppeal] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<EvidenceAppeal?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<EvidenceAppealUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<EvidenceAppeal>(
      id,
      columnValues: columnValues(EvidenceAppeal.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [EvidenceAppeal]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<EvidenceAppeal>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<EvidenceAppealUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<EvidenceAppealTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EvidenceAppealTable>? orderBy,
    _is.OrderByListBuilder<EvidenceAppealTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<EvidenceAppeal>(
      columnValues: columnValues(EvidenceAppeal.t.updateTable),
      where: where(EvidenceAppeal.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EvidenceAppeal.t),
      orderByList: orderByList?.call(EvidenceAppeal.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [EvidenceAppeal]s in the list and returns the deleted rows.
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
  Future<List<EvidenceAppeal>> delete(
    _is.DatabaseSession session,
    List<EvidenceAppeal> rows, {
    _is.OrderByBuilder<EvidenceAppealTable>? orderBy,
    _is.OrderByListBuilder<EvidenceAppealTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<EvidenceAppeal>(
      rows,
      orderBy: orderBy?.call(EvidenceAppeal.t),
      orderByList: orderByList?.call(EvidenceAppeal.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [EvidenceAppeal].
  Future<EvidenceAppeal> deleteRow(
    _is.DatabaseSession session,
    EvidenceAppeal row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<EvidenceAppeal>(
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
  Future<List<EvidenceAppeal>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<EvidenceAppealTable> where,
    _is.OrderByBuilder<EvidenceAppealTable>? orderBy,
    _is.OrderByListBuilder<EvidenceAppealTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<EvidenceAppeal>(
      where: where(EvidenceAppeal.t),
      orderBy: orderBy?.call(EvidenceAppeal.t),
      orderByList: orderByList?.call(EvidenceAppeal.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EvidenceAppealTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<EvidenceAppeal>(
      where: where?.call(EvidenceAppeal.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [EvidenceAppeal] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<EvidenceAppealTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<EvidenceAppeal>(
      where: where(EvidenceAppeal.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class EvidenceAppealAttachRowRepository {
  const EvidenceAppealAttachRowRepository._();

  /// Creates a relation between the given [EvidenceAppeal] and [AuthUser]
  /// by setting the [EvidenceAppeal]'s foreign key `creatorAuthUserId` to refer to the [AuthUser].
  Future<void> creatorAuthUser(
    _is.DatabaseSession session,
    EvidenceAppeal evidenceAppeal,
    _iacs.AuthUser creatorAuthUser, {
    _is.Transaction? transaction,
  }) async {
    if (evidenceAppeal.id == null) {
      throw ArgumentError.notNull('evidenceAppeal.id');
    }
    if (creatorAuthUser.id == null) {
      throw ArgumentError.notNull('creatorAuthUser.id');
    }

    var $evidenceAppeal = evidenceAppeal.copyWith(
      creatorAuthUserId: creatorAuthUser.id,
    );
    await session.db.updateRow<EvidenceAppeal>(
      $evidenceAppeal,
      columns: [EvidenceAppeal.t.creatorAuthUserId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [EvidenceAppeal] and [AuthUser]
  /// by setting the [EvidenceAppeal]'s foreign key `participantAuthUserId` to refer to the [AuthUser].
  Future<void> participantAuthUser(
    _is.DatabaseSession session,
    EvidenceAppeal evidenceAppeal,
    _iacs.AuthUser participantAuthUser, {
    _is.Transaction? transaction,
  }) async {
    if (evidenceAppeal.id == null) {
      throw ArgumentError.notNull('evidenceAppeal.id');
    }
    if (participantAuthUser.id == null) {
      throw ArgumentError.notNull('participantAuthUser.id');
    }

    var $evidenceAppeal = evidenceAppeal.copyWith(
      participantAuthUserId: participantAuthUser.id,
    );
    await session.db.updateRow<EvidenceAppeal>(
      $evidenceAppeal,
      columns: [EvidenceAppeal.t.participantAuthUserId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [EvidenceAppeal] and [AuthUser]
  /// by setting the [EvidenceAppeal]'s foreign key `resolvedByAuthUserId` to refer to the [AuthUser].
  Future<void> resolvedByAuthUser(
    _is.DatabaseSession session,
    EvidenceAppeal evidenceAppeal,
    _iacs.AuthUser resolvedByAuthUser, {
    _is.Transaction? transaction,
  }) async {
    if (evidenceAppeal.id == null) {
      throw ArgumentError.notNull('evidenceAppeal.id');
    }
    if (resolvedByAuthUser.id == null) {
      throw ArgumentError.notNull('resolvedByAuthUser.id');
    }

    var $evidenceAppeal = evidenceAppeal.copyWith(
      resolvedByAuthUserId: resolvedByAuthUser.id,
    );
    await session.db.updateRow<EvidenceAppeal>(
      $evidenceAppeal,
      columns: [EvidenceAppeal.t.resolvedByAuthUserId],
      transaction: transaction,
    );
  }
}

class EvidenceAppealDetachRowRepository {
  const EvidenceAppealDetachRowRepository._();

  /// Detaches the relation between this [EvidenceAppeal] and the [AuthUser] set in `resolvedByAuthUser`
  /// by setting the [EvidenceAppeal]'s foreign key `resolvedByAuthUserId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> resolvedByAuthUser(
    _is.DatabaseSession session,
    EvidenceAppeal evidenceAppeal, {
    _is.Transaction? transaction,
  }) async {
    if (evidenceAppeal.id == null) {
      throw ArgumentError.notNull('evidenceAppeal.id');
    }

    var $evidenceAppeal = evidenceAppeal.copyWith(resolvedByAuthUserId: null);
    await session.db.updateRow<EvidenceAppeal>(
      $evidenceAppeal,
      columns: [EvidenceAppeal.t.resolvedByAuthUserId],
      transaction: transaction,
    );
  }
}
