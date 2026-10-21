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

import '../action_verification/evidence_decision_status.dart' as _ir3rpfcs;

/// Append-only verdict history; a new review never erases an earlier decision.
abstract class EvidenceDecision
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  EvidenceDecision._({
    this.id,
    required this.evidenceId,
    required this.status,
    required this.verifierType,
    this.modelName,
    this.modelVersion,
    this.confidence,
    required this.reasonCode,
    required this.summary,
    this.reviewedByAuthUserId,
    this.reviewedByAuthUser,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory EvidenceDecision({
    _is.UuidValue? id,
    required _is.UuidValue evidenceId,
    required _ir3rpfcs.EvidenceDecisionStatus status,
    required String verifierType,
    String? modelName,
    String? modelVersion,
    double? confidence,
    required String reasonCode,
    required String summary,
    _is.UuidValue? reviewedByAuthUserId,
    _iacs.AuthUser? reviewedByAuthUser,
    DateTime? createdAt,
  }) = _EvidenceDecisionImpl;

  factory EvidenceDecision.fromJson(Map<String, dynamic> jsonSerialization) {
    return EvidenceDecision(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      evidenceId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['evidenceId'],
      ),
      status: _ir3rpfcs.EvidenceDecisionStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      verifierType: jsonSerialization['verifierType'] as String,
      modelName: jsonSerialization['modelName'] as String?,
      modelVersion: jsonSerialization['modelVersion'] as String?,
      confidence: (jsonSerialization['confidence'] as num?)?.toDouble(),
      reasonCode: jsonSerialization['reasonCode'] as String,
      summary: jsonSerialization['summary'] as String,
      reviewedByAuthUserId: jsonSerialization['reviewedByAuthUserId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['reviewedByAuthUserId'],
            ),
      reviewedByAuthUser: jsonSerialization['reviewedByAuthUser'] == null
          ? null
          : _itf691yl.Protocol().deserialize<_iacs.AuthUser>(
              jsonSerialization['reviewedByAuthUser'],
            ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = EvidenceDecisionTable();

  static const db = EvidenceDecisionRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue evidenceId;

  _ir3rpfcs.EvidenceDecisionStatus status;

  String verifierType;

  String? modelName;

  String? modelVersion;

  double? confidence;

  String reasonCode;

  String summary;

  _is.UuidValue? reviewedByAuthUserId;

  _iacs.AuthUser? reviewedByAuthUser;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [EvidenceDecision]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  EvidenceDecision copyWith({
    _is.UuidValue? id,
    _is.UuidValue? evidenceId,
    _ir3rpfcs.EvidenceDecisionStatus? status,
    String? verifierType,
    String? modelName,
    String? modelVersion,
    double? confidence,
    String? reasonCode,
    String? summary,
    _is.UuidValue? reviewedByAuthUserId,
    _iacs.AuthUser? reviewedByAuthUser,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'EvidenceDecision',
      if (id != null) 'id': id?.toJson(),
      'evidenceId': evidenceId.toJson(),
      'status': status.toJson(),
      'verifierType': verifierType,
      if (modelName != null) 'modelName': modelName,
      if (modelVersion != null) 'modelVersion': modelVersion,
      if (confidence != null) 'confidence': confidence,
      'reasonCode': reasonCode,
      'summary': summary,
      if (reviewedByAuthUserId != null)
        'reviewedByAuthUserId': reviewedByAuthUserId?.toJson(),
      if (reviewedByAuthUser != null)
        'reviewedByAuthUser': reviewedByAuthUser?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static EvidenceDecisionInclude include({
    _iacs.AuthUserInclude? reviewedByAuthUser,
  }) {
    return EvidenceDecisionInclude._(reviewedByAuthUser: reviewedByAuthUser);
  }

  static EvidenceDecisionIncludeList includeList({
    _is.WhereExpressionBuilder<EvidenceDecisionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EvidenceDecisionTable>? orderBy,
    _is.OrderByListBuilder<EvidenceDecisionTable>? orderByList,
    EvidenceDecisionInclude? include,
  }) {
    return EvidenceDecisionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EvidenceDecision.t),
      orderByList: orderByList?.call(EvidenceDecision.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _EvidenceDecisionImpl extends EvidenceDecision {
  _EvidenceDecisionImpl({
    _is.UuidValue? id,
    required _is.UuidValue evidenceId,
    required _ir3rpfcs.EvidenceDecisionStatus status,
    required String verifierType,
    String? modelName,
    String? modelVersion,
    double? confidence,
    required String reasonCode,
    required String summary,
    _is.UuidValue? reviewedByAuthUserId,
    _iacs.AuthUser? reviewedByAuthUser,
    DateTime? createdAt,
  }) : super._(
         id: id,
         evidenceId: evidenceId,
         status: status,
         verifierType: verifierType,
         modelName: modelName,
         modelVersion: modelVersion,
         confidence: confidence,
         reasonCode: reasonCode,
         summary: summary,
         reviewedByAuthUserId: reviewedByAuthUserId,
         reviewedByAuthUser: reviewedByAuthUser,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [EvidenceDecision]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  EvidenceDecision copyWith({
    Object? id = _Undefined,
    _is.UuidValue? evidenceId,
    _ir3rpfcs.EvidenceDecisionStatus? status,
    String? verifierType,
    Object? modelName = _Undefined,
    Object? modelVersion = _Undefined,
    Object? confidence = _Undefined,
    String? reasonCode,
    String? summary,
    Object? reviewedByAuthUserId = _Undefined,
    Object? reviewedByAuthUser = _Undefined,
    DateTime? createdAt,
  }) {
    return EvidenceDecision(
      id: id is _is.UuidValue? ? id : this.id,
      evidenceId: evidenceId ?? this.evidenceId,
      status: status ?? this.status,
      verifierType: verifierType ?? this.verifierType,
      modelName: modelName is String? ? modelName : this.modelName,
      modelVersion: modelVersion is String? ? modelVersion : this.modelVersion,
      confidence: confidence is double? ? confidence : this.confidence,
      reasonCode: reasonCode ?? this.reasonCode,
      summary: summary ?? this.summary,
      reviewedByAuthUserId: reviewedByAuthUserId is _is.UuidValue?
          ? reviewedByAuthUserId
          : this.reviewedByAuthUserId,
      reviewedByAuthUser: reviewedByAuthUser is _iacs.AuthUser?
          ? reviewedByAuthUser
          : this.reviewedByAuthUser?.copyWith(),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class EvidenceDecisionUpdateTable
    extends _is.UpdateTable<EvidenceDecisionTable> {
  EvidenceDecisionUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> evidenceId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.evidenceId,
    value,
  );

  _is.ColumnValue<
    _ir3rpfcs.EvidenceDecisionStatus,
    _ir3rpfcs.EvidenceDecisionStatus
  >
  status(_ir3rpfcs.EvidenceDecisionStatus value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<String, String> verifierType(String value) => _is.ColumnValue(
    table.verifierType,
    value,
  );

  _is.ColumnValue<String, String> modelName(String? value) => _is.ColumnValue(
    table.modelName,
    value,
  );

  _is.ColumnValue<String, String> modelVersion(String? value) =>
      _is.ColumnValue(
        table.modelVersion,
        value,
      );

  _is.ColumnValue<double, double> confidence(double? value) => _is.ColumnValue(
    table.confidence,
    value,
  );

  _is.ColumnValue<String, String> reasonCode(String value) => _is.ColumnValue(
    table.reasonCode,
    value,
  );

  _is.ColumnValue<String, String> summary(String value) => _is.ColumnValue(
    table.summary,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> reviewedByAuthUserId(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.reviewedByAuthUserId,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class EvidenceDecisionTable extends _is.Table<_is.UuidValue?> {
  EvidenceDecisionTable({super.tableRelation})
    : super(tableName: 'verily_evidence_decision') {
    updateTable = EvidenceDecisionUpdateTable(this);
    evidenceId = _is.ColumnUuid(
      'evidenceId',
      this,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
    );
    verifierType = _is.ColumnString(
      'verifierType',
      this,
    );
    modelName = _is.ColumnString(
      'modelName',
      this,
    );
    modelVersion = _is.ColumnString(
      'modelVersion',
      this,
    );
    confidence = _is.ColumnDouble(
      'confidence',
      this,
    );
    reasonCode = _is.ColumnString(
      'reasonCode',
      this,
    );
    summary = _is.ColumnString(
      'summary',
      this,
    );
    reviewedByAuthUserId = _is.ColumnUuid(
      'reviewedByAuthUserId',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final EvidenceDecisionUpdateTable updateTable;

  late final _is.ColumnUuid evidenceId;

  late final _is.ColumnEnum<_ir3rpfcs.EvidenceDecisionStatus> status;

  late final _is.ColumnString verifierType;

  late final _is.ColumnString modelName;

  late final _is.ColumnString modelVersion;

  late final _is.ColumnDouble confidence;

  late final _is.ColumnString reasonCode;

  late final _is.ColumnString summary;

  late final _is.ColumnUuid reviewedByAuthUserId;

  _iacs.AuthUserTable? _reviewedByAuthUser;

  late final _is.ColumnDateTime createdAt;

  _iacs.AuthUserTable get reviewedByAuthUser {
    if (_reviewedByAuthUser != null) return _reviewedByAuthUser!;
    _reviewedByAuthUser = _is.createRelationTable(
      relationFieldName: 'reviewedByAuthUser',
      field: EvidenceDecision.t.reviewedByAuthUserId,
      foreignField: _iacs.AuthUser.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iacs.AuthUserTable(tableRelation: foreignTableRelation),
    );
    return _reviewedByAuthUser!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    evidenceId,
    status,
    verifierType,
    modelName,
    modelVersion,
    confidence,
    reasonCode,
    summary,
    reviewedByAuthUserId,
    createdAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'reviewedByAuthUser') {
      return reviewedByAuthUser;
    }
    return null;
  }
}

class EvidenceDecisionInclude extends _is.IncludeObject {
  EvidenceDecisionInclude._({_iacs.AuthUserInclude? reviewedByAuthUser}) {
    _reviewedByAuthUser = reviewedByAuthUser;
  }

  _iacs.AuthUserInclude? _reviewedByAuthUser;

  @override
  Map<String, _is.Include?> get includes => {
    'reviewedByAuthUser': _reviewedByAuthUser,
  };

  @override
  _is.Table<_is.UuidValue?> get table => EvidenceDecision.t;
}

class EvidenceDecisionIncludeList extends _is.IncludeList {
  EvidenceDecisionIncludeList._({
    _is.WhereExpressionBuilder<EvidenceDecisionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(EvidenceDecision.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => EvidenceDecision.t;
}

class EvidenceDecisionRepository {
  const EvidenceDecisionRepository._();

  final attachRow = const EvidenceDecisionAttachRowRepository._();

  final detachRow = const EvidenceDecisionDetachRowRepository._();

  /// Returns a list of [EvidenceDecision]s matching the given query parameters.
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
  Future<List<EvidenceDecision>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EvidenceDecisionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EvidenceDecisionTable>? orderBy,
    _is.OrderByListBuilder<EvidenceDecisionTable>? orderByList,
    _is.Transaction? transaction,
    EvidenceDecisionInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<EvidenceDecision>(
      where: where?.call(EvidenceDecision.t),
      orderBy: orderBy?.call(EvidenceDecision.t),
      orderByList: orderByList?.call(EvidenceDecision.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [EvidenceDecision] matching the given query parameters.
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
  Future<EvidenceDecision?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EvidenceDecisionTable>? where,
    int? offset,
    _is.OrderByBuilder<EvidenceDecisionTable>? orderBy,
    _is.OrderByListBuilder<EvidenceDecisionTable>? orderByList,
    _is.Transaction? transaction,
    EvidenceDecisionInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<EvidenceDecision>(
      where: where?.call(EvidenceDecision.t),
      orderBy: orderBy?.call(EvidenceDecision.t),
      orderByList: orderByList?.call(EvidenceDecision.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [EvidenceDecision] by its [id] or null if no such row exists.
  Future<EvidenceDecision?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    EvidenceDecisionInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<EvidenceDecision>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [EvidenceDecision]s in the list and returns the inserted rows.
  ///
  /// The returned [EvidenceDecision]s will have their `id` fields set.
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
  Future<List<EvidenceDecision>> insert(
    _is.DatabaseSession session,
    List<EvidenceDecision> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<EvidenceDecision>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [EvidenceDecision] and returns the inserted row.
  ///
  /// The returned [EvidenceDecision] will have its `id` field set.
  Future<EvidenceDecision> insertRow(
    _is.DatabaseSession session,
    EvidenceDecision row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<EvidenceDecision>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [EvidenceDecision]s in the list and returns the resulting rows.
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
  /// The returned [EvidenceDecision]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<EvidenceDecision>> upsert(
    _is.DatabaseSession session,
    List<EvidenceDecision> rows, {
    required _is.ColumnSelections<EvidenceDecisionTable> conflictColumns,
    _is.ColumnSelections<EvidenceDecisionTable>? updateColumns,
    _is.WhereExpressionBuilder<EvidenceDecisionTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<EvidenceDecision>(
      rows,
      conflictColumns: conflictColumns(EvidenceDecision.t),
      updateColumns: updateColumns?.call(EvidenceDecision.t),
      updateWhere: updateWhere?.call(EvidenceDecision.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [EvidenceDecision] and returns the resulting row.
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
  /// The returned [EvidenceDecision] will have its `id` field set.
  Future<EvidenceDecision?> upsertRow(
    _is.DatabaseSession session,
    EvidenceDecision row, {
    required _is.ColumnSelections<EvidenceDecisionTable> conflictColumns,
    _is.ColumnSelections<EvidenceDecisionTable>? updateColumns,
    _is.WhereExpressionBuilder<EvidenceDecisionTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<EvidenceDecision>(
      row,
      conflictColumns: conflictColumns(EvidenceDecision.t),
      updateColumns: updateColumns?.call(EvidenceDecision.t),
      updateWhere: updateWhere?.call(EvidenceDecision.t),
      transaction: transaction,
    );
  }

  /// Updates all [EvidenceDecision]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<EvidenceDecision>> update(
    _is.DatabaseSession session,
    List<EvidenceDecision> rows, {
    _is.ColumnSelections<EvidenceDecisionTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<EvidenceDecision>(
      rows,
      columns: columns?.call(EvidenceDecision.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [EvidenceDecision]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<EvidenceDecision> updateRow(
    _is.DatabaseSession session,
    EvidenceDecision row, {
    _is.ColumnSelections<EvidenceDecisionTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<EvidenceDecision>(
      row,
      columns: columns?.call(EvidenceDecision.t),
      transaction: transaction,
    );
  }

  /// Updates a single [EvidenceDecision] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<EvidenceDecision?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<EvidenceDecisionUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<EvidenceDecision>(
      id,
      columnValues: columnValues(EvidenceDecision.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [EvidenceDecision]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<EvidenceDecision>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<EvidenceDecisionUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<EvidenceDecisionTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EvidenceDecisionTable>? orderBy,
    _is.OrderByListBuilder<EvidenceDecisionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<EvidenceDecision>(
      columnValues: columnValues(EvidenceDecision.t.updateTable),
      where: where(EvidenceDecision.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EvidenceDecision.t),
      orderByList: orderByList?.call(EvidenceDecision.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [EvidenceDecision]s in the list and returns the deleted rows.
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
  Future<List<EvidenceDecision>> delete(
    _is.DatabaseSession session,
    List<EvidenceDecision> rows, {
    _is.OrderByBuilder<EvidenceDecisionTable>? orderBy,
    _is.OrderByListBuilder<EvidenceDecisionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<EvidenceDecision>(
      rows,
      orderBy: orderBy?.call(EvidenceDecision.t),
      orderByList: orderByList?.call(EvidenceDecision.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [EvidenceDecision].
  Future<EvidenceDecision> deleteRow(
    _is.DatabaseSession session,
    EvidenceDecision row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<EvidenceDecision>(
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
  Future<List<EvidenceDecision>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<EvidenceDecisionTable> where,
    _is.OrderByBuilder<EvidenceDecisionTable>? orderBy,
    _is.OrderByListBuilder<EvidenceDecisionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<EvidenceDecision>(
      where: where(EvidenceDecision.t),
      orderBy: orderBy?.call(EvidenceDecision.t),
      orderByList: orderByList?.call(EvidenceDecision.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EvidenceDecisionTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<EvidenceDecision>(
      where: where?.call(EvidenceDecision.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [EvidenceDecision] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<EvidenceDecisionTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<EvidenceDecision>(
      where: where(EvidenceDecision.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class EvidenceDecisionAttachRowRepository {
  const EvidenceDecisionAttachRowRepository._();

  /// Creates a relation between the given [EvidenceDecision] and [AuthUser]
  /// by setting the [EvidenceDecision]'s foreign key `reviewedByAuthUserId` to refer to the [AuthUser].
  Future<void> reviewedByAuthUser(
    _is.DatabaseSession session,
    EvidenceDecision evidenceDecision,
    _iacs.AuthUser reviewedByAuthUser, {
    _is.Transaction? transaction,
  }) async {
    if (evidenceDecision.id == null) {
      throw ArgumentError.notNull('evidenceDecision.id');
    }
    if (reviewedByAuthUser.id == null) {
      throw ArgumentError.notNull('reviewedByAuthUser.id');
    }

    var $evidenceDecision = evidenceDecision.copyWith(
      reviewedByAuthUserId: reviewedByAuthUser.id,
    );
    await session.db.updateRow<EvidenceDecision>(
      $evidenceDecision,
      columns: [EvidenceDecision.t.reviewedByAuthUserId],
      transaction: transaction,
    );
  }
}

class EvidenceDecisionDetachRowRepository {
  const EvidenceDecisionDetachRowRepository._();

  /// Detaches the relation between this [EvidenceDecision] and the [AuthUser] set in `reviewedByAuthUser`
  /// by setting the [EvidenceDecision]'s foreign key `reviewedByAuthUserId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> reviewedByAuthUser(
    _is.DatabaseSession session,
    EvidenceDecision evidenceDecision, {
    _is.Transaction? transaction,
  }) async {
    if (evidenceDecision.id == null) {
      throw ArgumentError.notNull('evidenceDecision.id');
    }

    var $evidenceDecision = evidenceDecision.copyWith(
      reviewedByAuthUserId: null,
    );
    await session.db.updateRow<EvidenceDecision>(
      $evidenceDecision,
      columns: [EvidenceDecision.t.reviewedByAuthUserId],
      transaction: transaction,
    );
  }
}
