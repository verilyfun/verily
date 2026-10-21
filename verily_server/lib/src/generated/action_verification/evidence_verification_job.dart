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

import '../action_verification/evidence_verification_job_status.dart'
    as _iaoupa99;

/// Durable verification outbox; unique evidence binding makes worker retries converge.
abstract class EvidenceVerificationJob
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  EvidenceVerificationJob._({
    this.id,
    required this.evidenceId,
    _iaoupa99.EvidenceVerificationJobStatus? status,
    int? attemptCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.startedAt,
    this.completedAt,
    this.lastErrorCode,
  }) : status = status ?? _iaoupa99.EvidenceVerificationJobStatus.queued,
       attemptCount = attemptCount ?? 0,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory EvidenceVerificationJob({
    _is.UuidValue? id,
    required _is.UuidValue evidenceId,
    _iaoupa99.EvidenceVerificationJobStatus? status,
    int? attemptCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? lastErrorCode,
  }) = _EvidenceVerificationJobImpl;

  factory EvidenceVerificationJob.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return EvidenceVerificationJob(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      evidenceId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['evidenceId'],
      ),
      status: jsonSerialization['status'] == null
          ? null
          : _iaoupa99.EvidenceVerificationJobStatus.fromJson(
              (jsonSerialization['status'] as String),
            ),
      attemptCount: jsonSerialization['attemptCount'] as int?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      startedAt: jsonSerialization['startedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['startedAt']),
      completedAt: jsonSerialization['completedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['completedAt'],
            ),
      lastErrorCode: jsonSerialization['lastErrorCode'] as String?,
    );
  }

  static final t = EvidenceVerificationJobTable();

  static const db = EvidenceVerificationJobRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue evidenceId;

  _iaoupa99.EvidenceVerificationJobStatus status;

  int attemptCount;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? startedAt;

  DateTime? completedAt;

  String? lastErrorCode;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [EvidenceVerificationJob]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  EvidenceVerificationJob copyWith({
    _is.UuidValue? id,
    _is.UuidValue? evidenceId,
    _iaoupa99.EvidenceVerificationJobStatus? status,
    int? attemptCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? lastErrorCode,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'EvidenceVerificationJob',
      if (id != null) 'id': id?.toJson(),
      'evidenceId': evidenceId.toJson(),
      'status': status.toJson(),
      'attemptCount': attemptCount,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (startedAt != null) 'startedAt': startedAt?.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
      if (lastErrorCode != null) 'lastErrorCode': lastErrorCode,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static EvidenceVerificationJobInclude include() {
    return EvidenceVerificationJobInclude._();
  }

  static EvidenceVerificationJobIncludeList includeList({
    _is.WhereExpressionBuilder<EvidenceVerificationJobTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EvidenceVerificationJobTable>? orderBy,
    _is.OrderByListBuilder<EvidenceVerificationJobTable>? orderByList,
    EvidenceVerificationJobInclude? include,
  }) {
    return EvidenceVerificationJobIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EvidenceVerificationJob.t),
      orderByList: orderByList?.call(EvidenceVerificationJob.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _EvidenceVerificationJobImpl extends EvidenceVerificationJob {
  _EvidenceVerificationJobImpl({
    _is.UuidValue? id,
    required _is.UuidValue evidenceId,
    _iaoupa99.EvidenceVerificationJobStatus? status,
    int? attemptCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? lastErrorCode,
  }) : super._(
         id: id,
         evidenceId: evidenceId,
         status: status,
         attemptCount: attemptCount,
         createdAt: createdAt,
         updatedAt: updatedAt,
         startedAt: startedAt,
         completedAt: completedAt,
         lastErrorCode: lastErrorCode,
       );

  /// Returns a shallow copy of this [EvidenceVerificationJob]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  EvidenceVerificationJob copyWith({
    Object? id = _Undefined,
    _is.UuidValue? evidenceId,
    _iaoupa99.EvidenceVerificationJobStatus? status,
    int? attemptCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? startedAt = _Undefined,
    Object? completedAt = _Undefined,
    Object? lastErrorCode = _Undefined,
  }) {
    return EvidenceVerificationJob(
      id: id is _is.UuidValue? ? id : this.id,
      evidenceId: evidenceId ?? this.evidenceId,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startedAt: startedAt is DateTime? ? startedAt : this.startedAt,
      completedAt: completedAt is DateTime? ? completedAt : this.completedAt,
      lastErrorCode: lastErrorCode is String?
          ? lastErrorCode
          : this.lastErrorCode,
    );
  }
}

class EvidenceVerificationJobUpdateTable
    extends _is.UpdateTable<EvidenceVerificationJobTable> {
  EvidenceVerificationJobUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> evidenceId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.evidenceId,
    value,
  );

  _is.ColumnValue<
    _iaoupa99.EvidenceVerificationJobStatus,
    _iaoupa99.EvidenceVerificationJobStatus
  >
  status(_iaoupa99.EvidenceVerificationJobStatus value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<int, int> attemptCount(int value) => _is.ColumnValue(
    table.attemptCount,
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

  _is.ColumnValue<DateTime, DateTime> startedAt(DateTime? value) =>
      _is.ColumnValue(
        table.startedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> completedAt(DateTime? value) =>
      _is.ColumnValue(
        table.completedAt,
        value,
      );

  _is.ColumnValue<String, String> lastErrorCode(String? value) =>
      _is.ColumnValue(
        table.lastErrorCode,
        value,
      );
}

class EvidenceVerificationJobTable extends _is.Table<_is.UuidValue?> {
  EvidenceVerificationJobTable({super.tableRelation})
    : super(tableName: 'verily_evidence_verification_job') {
    updateTable = EvidenceVerificationJobUpdateTable(this);
    evidenceId = _is.ColumnUuid(
      'evidenceId',
      this,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    attemptCount = _is.ColumnInt(
      'attemptCount',
      this,
      hasDefault: true,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    updatedAt = _is.ColumnDateTime(
      'updatedAt',
      this,
    );
    startedAt = _is.ColumnDateTime(
      'startedAt',
      this,
    );
    completedAt = _is.ColumnDateTime(
      'completedAt',
      this,
    );
    lastErrorCode = _is.ColumnString(
      'lastErrorCode',
      this,
    );
  }

  late final EvidenceVerificationJobUpdateTable updateTable;

  late final _is.ColumnUuid evidenceId;

  late final _is.ColumnEnum<_iaoupa99.EvidenceVerificationJobStatus> status;

  late final _is.ColumnInt attemptCount;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  late final _is.ColumnDateTime startedAt;

  late final _is.ColumnDateTime completedAt;

  late final _is.ColumnString lastErrorCode;

  @override
  List<_is.Column> get columns => [
    id,
    evidenceId,
    status,
    attemptCount,
    createdAt,
    updatedAt,
    startedAt,
    completedAt,
    lastErrorCode,
  ];
}

class EvidenceVerificationJobInclude extends _is.IncludeObject {
  EvidenceVerificationJobInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<_is.UuidValue?> get table => EvidenceVerificationJob.t;
}

class EvidenceVerificationJobIncludeList extends _is.IncludeList {
  EvidenceVerificationJobIncludeList._({
    _is.WhereExpressionBuilder<EvidenceVerificationJobTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(EvidenceVerificationJob.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => EvidenceVerificationJob.t;
}

class EvidenceVerificationJobRepository {
  const EvidenceVerificationJobRepository._();

  /// Returns a list of [EvidenceVerificationJob]s matching the given query parameters.
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
  Future<List<EvidenceVerificationJob>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EvidenceVerificationJobTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EvidenceVerificationJobTable>? orderBy,
    _is.OrderByListBuilder<EvidenceVerificationJobTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<EvidenceVerificationJob>(
      where: where?.call(EvidenceVerificationJob.t),
      orderBy: orderBy?.call(EvidenceVerificationJob.t),
      orderByList: orderByList?.call(EvidenceVerificationJob.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [EvidenceVerificationJob] matching the given query parameters.
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
  Future<EvidenceVerificationJob?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EvidenceVerificationJobTable>? where,
    int? offset,
    _is.OrderByBuilder<EvidenceVerificationJobTable>? orderBy,
    _is.OrderByListBuilder<EvidenceVerificationJobTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<EvidenceVerificationJob>(
      where: where?.call(EvidenceVerificationJob.t),
      orderBy: orderBy?.call(EvidenceVerificationJob.t),
      orderByList: orderByList?.call(EvidenceVerificationJob.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [EvidenceVerificationJob] by its [id] or null if no such row exists.
  Future<EvidenceVerificationJob?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<EvidenceVerificationJob>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [EvidenceVerificationJob]s in the list and returns the inserted rows.
  ///
  /// The returned [EvidenceVerificationJob]s will have their `id` fields set.
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
  Future<List<EvidenceVerificationJob>> insert(
    _is.DatabaseSession session,
    List<EvidenceVerificationJob> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<EvidenceVerificationJob>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [EvidenceVerificationJob] and returns the inserted row.
  ///
  /// The returned [EvidenceVerificationJob] will have its `id` field set.
  Future<EvidenceVerificationJob> insertRow(
    _is.DatabaseSession session,
    EvidenceVerificationJob row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<EvidenceVerificationJob>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [EvidenceVerificationJob]s in the list and returns the resulting rows.
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
  /// The returned [EvidenceVerificationJob]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<EvidenceVerificationJob>> upsert(
    _is.DatabaseSession session,
    List<EvidenceVerificationJob> rows, {
    required _is.ColumnSelections<EvidenceVerificationJobTable> conflictColumns,
    _is.ColumnSelections<EvidenceVerificationJobTable>? updateColumns,
    _is.WhereExpressionBuilder<EvidenceVerificationJobTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<EvidenceVerificationJob>(
      rows,
      conflictColumns: conflictColumns(EvidenceVerificationJob.t),
      updateColumns: updateColumns?.call(EvidenceVerificationJob.t),
      updateWhere: updateWhere?.call(EvidenceVerificationJob.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [EvidenceVerificationJob] and returns the resulting row.
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
  /// The returned [EvidenceVerificationJob] will have its `id` field set.
  Future<EvidenceVerificationJob?> upsertRow(
    _is.DatabaseSession session,
    EvidenceVerificationJob row, {
    required _is.ColumnSelections<EvidenceVerificationJobTable> conflictColumns,
    _is.ColumnSelections<EvidenceVerificationJobTable>? updateColumns,
    _is.WhereExpressionBuilder<EvidenceVerificationJobTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<EvidenceVerificationJob>(
      row,
      conflictColumns: conflictColumns(EvidenceVerificationJob.t),
      updateColumns: updateColumns?.call(EvidenceVerificationJob.t),
      updateWhere: updateWhere?.call(EvidenceVerificationJob.t),
      transaction: transaction,
    );
  }

  /// Updates all [EvidenceVerificationJob]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<EvidenceVerificationJob>> update(
    _is.DatabaseSession session,
    List<EvidenceVerificationJob> rows, {
    _is.ColumnSelections<EvidenceVerificationJobTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<EvidenceVerificationJob>(
      rows,
      columns: columns?.call(EvidenceVerificationJob.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [EvidenceVerificationJob]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<EvidenceVerificationJob> updateRow(
    _is.DatabaseSession session,
    EvidenceVerificationJob row, {
    _is.ColumnSelections<EvidenceVerificationJobTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<EvidenceVerificationJob>(
      row,
      columns: columns?.call(EvidenceVerificationJob.t),
      transaction: transaction,
    );
  }

  /// Updates a single [EvidenceVerificationJob] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<EvidenceVerificationJob?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<EvidenceVerificationJobUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<EvidenceVerificationJob>(
      id,
      columnValues: columnValues(EvidenceVerificationJob.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [EvidenceVerificationJob]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<EvidenceVerificationJob>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<EvidenceVerificationJobUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<EvidenceVerificationJobTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EvidenceVerificationJobTable>? orderBy,
    _is.OrderByListBuilder<EvidenceVerificationJobTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<EvidenceVerificationJob>(
      columnValues: columnValues(EvidenceVerificationJob.t.updateTable),
      where: where(EvidenceVerificationJob.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EvidenceVerificationJob.t),
      orderByList: orderByList?.call(EvidenceVerificationJob.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [EvidenceVerificationJob]s in the list and returns the deleted rows.
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
  Future<List<EvidenceVerificationJob>> delete(
    _is.DatabaseSession session,
    List<EvidenceVerificationJob> rows, {
    _is.OrderByBuilder<EvidenceVerificationJobTable>? orderBy,
    _is.OrderByListBuilder<EvidenceVerificationJobTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<EvidenceVerificationJob>(
      rows,
      orderBy: orderBy?.call(EvidenceVerificationJob.t),
      orderByList: orderByList?.call(EvidenceVerificationJob.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [EvidenceVerificationJob].
  Future<EvidenceVerificationJob> deleteRow(
    _is.DatabaseSession session,
    EvidenceVerificationJob row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<EvidenceVerificationJob>(
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
  Future<List<EvidenceVerificationJob>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<EvidenceVerificationJobTable> where,
    _is.OrderByBuilder<EvidenceVerificationJobTable>? orderBy,
    _is.OrderByListBuilder<EvidenceVerificationJobTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<EvidenceVerificationJob>(
      where: where(EvidenceVerificationJob.t),
      orderBy: orderBy?.call(EvidenceVerificationJob.t),
      orderByList: orderByList?.call(EvidenceVerificationJob.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EvidenceVerificationJobTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<EvidenceVerificationJob>(
      where: where?.call(EvidenceVerificationJob.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [EvidenceVerificationJob] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<EvidenceVerificationJobTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<EvidenceVerificationJob>(
      where: where(EvidenceVerificationJob.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
