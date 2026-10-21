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

import '../ai_usage/ai_usage_status.dart' as _ifrg4w9v;

/// Bounded AI-work reservation used to enforce quotas before external compute.
abstract class AiUsageRequest
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  AiUsageRequest._({
    this.id,
    required this.authUserId,
    required this.operation,
    _ifrg4w9v.AiUsageStatus? status,
    int? costUnits,
    DateTime? createdAt,
    this.completedAt,
  }) : status = status ?? _ifrg4w9v.AiUsageStatus.reserved,
       costUnits = costUnits ?? 1,
       createdAt = createdAt ?? DateTime.now();

  factory AiUsageRequest({
    _is.UuidValue? id,
    required _is.UuidValue authUserId,
    required String operation,
    _ifrg4w9v.AiUsageStatus? status,
    int? costUnits,
    DateTime? createdAt,
    DateTime? completedAt,
  }) = _AiUsageRequestImpl;

  factory AiUsageRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return AiUsageRequest(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      authUserId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['authUserId'],
      ),
      operation: jsonSerialization['operation'] as String,
      status: jsonSerialization['status'] == null
          ? null
          : _ifrg4w9v.AiUsageStatus.fromJson(
              (jsonSerialization['status'] as String),
            ),
      costUnits: jsonSerialization['costUnits'] as int?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      completedAt: jsonSerialization['completedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['completedAt'],
            ),
    );
  }

  static final t = AiUsageRequestTable();

  static const db = AiUsageRequestRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue authUserId;

  String operation;

  _ifrg4w9v.AiUsageStatus status;

  int costUnits;

  DateTime createdAt;

  DateTime? completedAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [AiUsageRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AiUsageRequest copyWith({
    _is.UuidValue? id,
    _is.UuidValue? authUserId,
    String? operation,
    _ifrg4w9v.AiUsageStatus? status,
    int? costUnits,
    DateTime? createdAt,
    DateTime? completedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AiUsageRequest',
      if (id != null) 'id': id?.toJson(),
      'authUserId': authUserId.toJson(),
      'operation': operation,
      'status': status.toJson(),
      'costUnits': costUnits,
      'createdAt': createdAt.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static AiUsageRequestInclude include() {
    return AiUsageRequestInclude._();
  }

  static AiUsageRequestIncludeList includeList({
    _is.WhereExpressionBuilder<AiUsageRequestTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AiUsageRequestTable>? orderBy,
    _is.OrderByListBuilder<AiUsageRequestTable>? orderByList,
    AiUsageRequestInclude? include,
  }) {
    return AiUsageRequestIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AiUsageRequest.t),
      orderByList: orderByList?.call(AiUsageRequest.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AiUsageRequestImpl extends AiUsageRequest {
  _AiUsageRequestImpl({
    _is.UuidValue? id,
    required _is.UuidValue authUserId,
    required String operation,
    _ifrg4w9v.AiUsageStatus? status,
    int? costUnits,
    DateTime? createdAt,
    DateTime? completedAt,
  }) : super._(
         id: id,
         authUserId: authUserId,
         operation: operation,
         status: status,
         costUnits: costUnits,
         createdAt: createdAt,
         completedAt: completedAt,
       );

  /// Returns a shallow copy of this [AiUsageRequest]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AiUsageRequest copyWith({
    Object? id = _Undefined,
    _is.UuidValue? authUserId,
    String? operation,
    _ifrg4w9v.AiUsageStatus? status,
    int? costUnits,
    DateTime? createdAt,
    Object? completedAt = _Undefined,
  }) {
    return AiUsageRequest(
      id: id is _is.UuidValue? ? id : this.id,
      authUserId: authUserId ?? this.authUserId,
      operation: operation ?? this.operation,
      status: status ?? this.status,
      costUnits: costUnits ?? this.costUnits,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt is DateTime? ? completedAt : this.completedAt,
    );
  }
}

class AiUsageRequestUpdateTable extends _is.UpdateTable<AiUsageRequestTable> {
  AiUsageRequestUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> authUserId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.authUserId,
    value,
  );

  _is.ColumnValue<String, String> operation(String value) => _is.ColumnValue(
    table.operation,
    value,
  );

  _is.ColumnValue<_ifrg4w9v.AiUsageStatus, _ifrg4w9v.AiUsageStatus> status(
    _ifrg4w9v.AiUsageStatus value,
  ) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<int, int> costUnits(int value) => _is.ColumnValue(
    table.costUnits,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> completedAt(DateTime? value) =>
      _is.ColumnValue(
        table.completedAt,
        value,
      );
}

class AiUsageRequestTable extends _is.Table<_is.UuidValue?> {
  AiUsageRequestTable({super.tableRelation})
    : super(tableName: 'verily_ai_usage_request') {
    updateTable = AiUsageRequestUpdateTable(this);
    authUserId = _is.ColumnUuid(
      'authUserId',
      this,
    );
    operation = _is.ColumnString(
      'operation',
      this,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    costUnits = _is.ColumnInt(
      'costUnits',
      this,
      hasDefault: true,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
    completedAt = _is.ColumnDateTime(
      'completedAt',
      this,
    );
  }

  late final AiUsageRequestUpdateTable updateTable;

  late final _is.ColumnUuid authUserId;

  late final _is.ColumnString operation;

  late final _is.ColumnEnum<_ifrg4w9v.AiUsageStatus> status;

  late final _is.ColumnInt costUnits;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime completedAt;

  @override
  List<_is.Column> get columns => [
    id,
    authUserId,
    operation,
    status,
    costUnits,
    createdAt,
    completedAt,
  ];
}

class AiUsageRequestInclude extends _is.IncludeObject {
  AiUsageRequestInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<_is.UuidValue?> get table => AiUsageRequest.t;
}

class AiUsageRequestIncludeList extends _is.IncludeList {
  AiUsageRequestIncludeList._({
    _is.WhereExpressionBuilder<AiUsageRequestTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AiUsageRequest.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => AiUsageRequest.t;
}

class AiUsageRequestRepository {
  const AiUsageRequestRepository._();

  /// Returns a list of [AiUsageRequest]s matching the given query parameters.
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
  Future<List<AiUsageRequest>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AiUsageRequestTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AiUsageRequestTable>? orderBy,
    _is.OrderByListBuilder<AiUsageRequestTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<AiUsageRequest>(
      where: where?.call(AiUsageRequest.t),
      orderBy: orderBy?.call(AiUsageRequest.t),
      orderByList: orderByList?.call(AiUsageRequest.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [AiUsageRequest] matching the given query parameters.
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
  Future<AiUsageRequest?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AiUsageRequestTable>? where,
    int? offset,
    _is.OrderByBuilder<AiUsageRequestTable>? orderBy,
    _is.OrderByListBuilder<AiUsageRequestTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<AiUsageRequest>(
      where: where?.call(AiUsageRequest.t),
      orderBy: orderBy?.call(AiUsageRequest.t),
      orderByList: orderByList?.call(AiUsageRequest.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [AiUsageRequest] by its [id] or null if no such row exists.
  Future<AiUsageRequest?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<AiUsageRequest>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [AiUsageRequest]s in the list and returns the inserted rows.
  ///
  /// The returned [AiUsageRequest]s will have their `id` fields set.
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
  Future<List<AiUsageRequest>> insert(
    _is.DatabaseSession session,
    List<AiUsageRequest> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<AiUsageRequest>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [AiUsageRequest] and returns the inserted row.
  ///
  /// The returned [AiUsageRequest] will have its `id` field set.
  Future<AiUsageRequest> insertRow(
    _is.DatabaseSession session,
    AiUsageRequest row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<AiUsageRequest>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [AiUsageRequest]s in the list and returns the resulting rows.
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
  /// The returned [AiUsageRequest]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AiUsageRequest>> upsert(
    _is.DatabaseSession session,
    List<AiUsageRequest> rows, {
    required _is.ColumnSelections<AiUsageRequestTable> conflictColumns,
    _is.ColumnSelections<AiUsageRequestTable>? updateColumns,
    _is.WhereExpressionBuilder<AiUsageRequestTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<AiUsageRequest>(
      rows,
      conflictColumns: conflictColumns(AiUsageRequest.t),
      updateColumns: updateColumns?.call(AiUsageRequest.t),
      updateWhere: updateWhere?.call(AiUsageRequest.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [AiUsageRequest] and returns the resulting row.
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
  /// The returned [AiUsageRequest] will have its `id` field set.
  Future<AiUsageRequest?> upsertRow(
    _is.DatabaseSession session,
    AiUsageRequest row, {
    required _is.ColumnSelections<AiUsageRequestTable> conflictColumns,
    _is.ColumnSelections<AiUsageRequestTable>? updateColumns,
    _is.WhereExpressionBuilder<AiUsageRequestTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<AiUsageRequest>(
      row,
      conflictColumns: conflictColumns(AiUsageRequest.t),
      updateColumns: updateColumns?.call(AiUsageRequest.t),
      updateWhere: updateWhere?.call(AiUsageRequest.t),
      transaction: transaction,
    );
  }

  /// Updates all [AiUsageRequest]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AiUsageRequest>> update(
    _is.DatabaseSession session,
    List<AiUsageRequest> rows, {
    _is.ColumnSelections<AiUsageRequestTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<AiUsageRequest>(
      rows,
      columns: columns?.call(AiUsageRequest.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [AiUsageRequest]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AiUsageRequest> updateRow(
    _is.DatabaseSession session,
    AiUsageRequest row, {
    _is.ColumnSelections<AiUsageRequestTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<AiUsageRequest>(
      row,
      columns: columns?.call(AiUsageRequest.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AiUsageRequest] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AiUsageRequest?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<AiUsageRequestUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<AiUsageRequest>(
      id,
      columnValues: columnValues(AiUsageRequest.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AiUsageRequest]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AiUsageRequest>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<AiUsageRequestUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<AiUsageRequestTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AiUsageRequestTable>? orderBy,
    _is.OrderByListBuilder<AiUsageRequestTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<AiUsageRequest>(
      columnValues: columnValues(AiUsageRequest.t.updateTable),
      where: where(AiUsageRequest.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AiUsageRequest.t),
      orderByList: orderByList?.call(AiUsageRequest.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [AiUsageRequest]s in the list and returns the deleted rows.
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
  Future<List<AiUsageRequest>> delete(
    _is.DatabaseSession session,
    List<AiUsageRequest> rows, {
    _is.OrderByBuilder<AiUsageRequestTable>? orderBy,
    _is.OrderByListBuilder<AiUsageRequestTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<AiUsageRequest>(
      rows,
      orderBy: orderBy?.call(AiUsageRequest.t),
      orderByList: orderByList?.call(AiUsageRequest.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [AiUsageRequest].
  Future<AiUsageRequest> deleteRow(
    _is.DatabaseSession session,
    AiUsageRequest row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AiUsageRequest>(
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
  Future<List<AiUsageRequest>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AiUsageRequestTable> where,
    _is.OrderByBuilder<AiUsageRequestTable>? orderBy,
    _is.OrderByListBuilder<AiUsageRequestTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<AiUsageRequest>(
      where: where(AiUsageRequest.t),
      orderBy: orderBy?.call(AiUsageRequest.t),
      orderByList: orderByList?.call(AiUsageRequest.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AiUsageRequestTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<AiUsageRequest>(
      where: where?.call(AiUsageRequest.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [AiUsageRequest] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AiUsageRequestTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<AiUsageRequest>(
      where: where(AiUsageRequest.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
