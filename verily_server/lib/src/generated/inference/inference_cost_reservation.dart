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
import 'dart:async' as _ida;

import 'package:serverpod/serverpod.dart' as _is;

/// Append-only cost authorization committed before each external model call.
/// Calls and micro-cost are capped per attempt; an unknown outcome stays
/// charged so retries cannot buy free inference.
abstract class InferenceCostReservation
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  InferenceCostReservation._({
    this.id,
    required this.actionAttemptId,
    required this.callReference,
    required this.modelId,
    required this.policyVersion,
    required this.reservedMicros,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory InferenceCostReservation({
    _is.UuidValue? id,
    required _is.UuidValue actionAttemptId,
    required String callReference,
    required String modelId,
    required String policyVersion,
    required int reservedMicros,
    DateTime? createdAt,
  }) = _InferenceCostReservationImpl;

  factory InferenceCostReservation.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return InferenceCostReservation(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      actionAttemptId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['actionAttemptId'],
      ),
      callReference: jsonSerialization['callReference'] as String,
      modelId: jsonSerialization['modelId'] as String,
      policyVersion: jsonSerialization['policyVersion'] as String,
      reservedMicros: jsonSerialization['reservedMicros'] as int,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = InferenceCostReservationTable();

  static const db = InferenceCostReservationRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue actionAttemptId;

  String callReference;

  String modelId;

  String policyVersion;

  int reservedMicros;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [InferenceCostReservation]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  InferenceCostReservation copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? actionAttemptId,
    String? callReference,
    String? modelId,
    String? policyVersion,
    int? reservedMicros,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'InferenceCostReservation',
      if (id != null) 'id': id?.toJson(),
      'actionAttemptId': actionAttemptId.toJson(),
      'callReference': callReference,
      'modelId': modelId,
      'policyVersion': policyVersion,
      'reservedMicros': reservedMicros,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static InferenceCostReservationInclude include() {
    return InferenceCostReservationInclude._();
  }

  static InferenceCostReservationIncludeList includeList({
    _is.WhereExpressionBuilder<InferenceCostReservationTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<InferenceCostReservationTable>? orderBy,
    _is.OrderByListBuilder<InferenceCostReservationTable>? orderByList,
    InferenceCostReservationInclude? include,
  }) {
    return InferenceCostReservationIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(InferenceCostReservation.t),
      orderByList: orderByList?.call(InferenceCostReservation.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _InferenceCostReservationImpl extends InferenceCostReservation {
  _InferenceCostReservationImpl({
    _is.UuidValue? id,
    required _is.UuidValue actionAttemptId,
    required String callReference,
    required String modelId,
    required String policyVersion,
    required int reservedMicros,
    DateTime? createdAt,
  }) : super._(
         id: id,
         actionAttemptId: actionAttemptId,
         callReference: callReference,
         modelId: modelId,
         policyVersion: policyVersion,
         reservedMicros: reservedMicros,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [InferenceCostReservation]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  InferenceCostReservation copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? actionAttemptId,
    String? callReference,
    String? modelId,
    String? policyVersion,
    int? reservedMicros,
    DateTime? createdAt,
  }) {
    return InferenceCostReservation(
      id: id is _is.UndefinedSentinel ? this.id : id,
      actionAttemptId: actionAttemptId ?? this.actionAttemptId,
      callReference: callReference ?? this.callReference,
      modelId: modelId ?? this.modelId,
      policyVersion: policyVersion ?? this.policyVersion,
      reservedMicros: reservedMicros ?? this.reservedMicros,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class InferenceCostReservationUpdateTable
    extends _is.UpdateTable<InferenceCostReservationTable> {
  InferenceCostReservationUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> actionAttemptId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.actionAttemptId,
    value,
  );

  _is.ColumnValue<String, String> callReference(String value) =>
      _is.ColumnValue(
        table.callReference,
        value,
      );

  _is.ColumnValue<String, String> modelId(String value) => _is.ColumnValue(
    table.modelId,
    value,
  );

  _is.ColumnValue<String, String> policyVersion(String value) =>
      _is.ColumnValue(
        table.policyVersion,
        value,
      );

  _is.ColumnValue<int, int> reservedMicros(int value) => _is.ColumnValue(
    table.reservedMicros,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class InferenceCostReservationTable extends _is.Table<_is.UuidValue?> {
  InferenceCostReservationTable({super.tableRelation})
    : super(tableName: 'verily_inference_cost_reservation') {
    updateTable = InferenceCostReservationUpdateTable(this);
    actionAttemptId = _is.ColumnUuid(
      'actionAttemptId',
      this,
    );
    callReference = _is.ColumnString(
      'callReference',
      this,
    );
    modelId = _is.ColumnString(
      'modelId',
      this,
    );
    policyVersion = _is.ColumnString(
      'policyVersion',
      this,
    );
    reservedMicros = _is.ColumnInt(
      'reservedMicros',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final InferenceCostReservationUpdateTable updateTable;

  late final _is.ColumnUuid actionAttemptId;

  late final _is.ColumnString callReference;

  late final _is.ColumnString modelId;

  late final _is.ColumnString policyVersion;

  late final _is.ColumnInt reservedMicros;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    actionAttemptId,
    callReference,
    modelId,
    policyVersion,
    reservedMicros,
    createdAt,
  ];
}

class InferenceCostReservationInclude extends _is.IncludeObject {
  InferenceCostReservationInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<_is.UuidValue?> get table => InferenceCostReservation.t;
}

class InferenceCostReservationIncludeList extends _is.IncludeList {
  InferenceCostReservationIncludeList._({
    _is.WhereExpressionBuilder<InferenceCostReservationTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(InferenceCostReservation.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => InferenceCostReservation.t;
}

class InferenceCostReservationRepository {
  const InferenceCostReservationRepository._();

  /// Returns a list of [InferenceCostReservation]s matching the given query parameters.
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
  Future<List<InferenceCostReservation>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<InferenceCostReservationTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<InferenceCostReservationTable>? orderBy,
    _is.OrderByListBuilder<InferenceCostReservationTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<InferenceCostReservation>(
      where: where?.call(InferenceCostReservation.t),
      orderBy: orderBy?.call(InferenceCostReservation.t),
      orderByList: orderByList?.call(InferenceCostReservation.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [InferenceCostReservation]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `InferenceCostReservation.t`.
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
  _ida.Stream<List<InferenceCostReservation>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<InferenceCostReservationTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<InferenceCostReservationTable>? orderBy,
    _is.OrderByListBuilder<InferenceCostReservationTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<InferenceCostReservation>(
      where: where?.call(InferenceCostReservation.t),
      orderBy: orderBy?.call(InferenceCostReservation.t),
      orderByList: orderByList?.call(InferenceCostReservation.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [InferenceCostReservation] matching the given query parameters.
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
  Future<InferenceCostReservation?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<InferenceCostReservationTable>? where,
    int? offset,
    _is.OrderByBuilder<InferenceCostReservationTable>? orderBy,
    _is.OrderByListBuilder<InferenceCostReservationTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<InferenceCostReservation>(
      where: where?.call(InferenceCostReservation.t),
      orderBy: orderBy?.call(InferenceCostReservation.t),
      orderByList: orderByList?.call(InferenceCostReservation.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [InferenceCostReservation] by its [id] or null if no such row exists.
  Future<InferenceCostReservation?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<InferenceCostReservation>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [InferenceCostReservation]s in the list and returns the inserted rows.
  ///
  /// The returned [InferenceCostReservation]s will have their `id` fields set.
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
  Future<List<InferenceCostReservation>> insert(
    _is.DatabaseSession session,
    List<InferenceCostReservation> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<InferenceCostReservation>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [InferenceCostReservation] and returns the inserted row.
  ///
  /// The returned [InferenceCostReservation] will have its `id` field set.
  Future<InferenceCostReservation> insertRow(
    _is.DatabaseSession session,
    InferenceCostReservation row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<InferenceCostReservation>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [InferenceCostReservation]s in the list and returns the resulting rows.
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
  /// The returned [InferenceCostReservation]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<InferenceCostReservation>> upsert(
    _is.DatabaseSession session,
    List<InferenceCostReservation> rows, {
    required _is.ColumnSelections<InferenceCostReservationTable>
    conflictColumns,
    _is.ColumnSelections<InferenceCostReservationTable>? updateColumns,
    _is.WhereExpressionBuilder<InferenceCostReservationTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<InferenceCostReservation>(
      rows,
      conflictColumns: conflictColumns(InferenceCostReservation.t),
      updateColumns: updateColumns?.call(InferenceCostReservation.t),
      updateWhere: updateWhere?.call(InferenceCostReservation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [InferenceCostReservation] and returns the resulting row.
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
  /// The returned [InferenceCostReservation] will have its `id` field set.
  Future<InferenceCostReservation?> upsertRow(
    _is.DatabaseSession session,
    InferenceCostReservation row, {
    required _is.ColumnSelections<InferenceCostReservationTable>
    conflictColumns,
    _is.ColumnSelections<InferenceCostReservationTable>? updateColumns,
    _is.WhereExpressionBuilder<InferenceCostReservationTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<InferenceCostReservation>(
      row,
      conflictColumns: conflictColumns(InferenceCostReservation.t),
      updateColumns: updateColumns?.call(InferenceCostReservation.t),
      updateWhere: updateWhere?.call(InferenceCostReservation.t),
      transaction: transaction,
    );
  }

  /// Updates all [InferenceCostReservation]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<InferenceCostReservation>> update(
    _is.DatabaseSession session,
    List<InferenceCostReservation> rows, {
    _is.ColumnSelections<InferenceCostReservationTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<InferenceCostReservation>(
      rows,
      columns: columns?.call(InferenceCostReservation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [InferenceCostReservation]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<InferenceCostReservation> updateRow(
    _is.DatabaseSession session,
    InferenceCostReservation row, {
    _is.ColumnSelections<InferenceCostReservationTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<InferenceCostReservation>(
      row,
      columns: columns?.call(InferenceCostReservation.t),
      transaction: transaction,
    );
  }

  /// Updates a single [InferenceCostReservation] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<InferenceCostReservation?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<InferenceCostReservationUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<InferenceCostReservation>(
      id,
      columnValues: columnValues(InferenceCostReservation.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [InferenceCostReservation]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<InferenceCostReservation>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<InferenceCostReservationUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<InferenceCostReservationTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<InferenceCostReservationTable>? orderBy,
    _is.OrderByListBuilder<InferenceCostReservationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<InferenceCostReservation>(
      columnValues: columnValues(InferenceCostReservation.t.updateTable),
      where: where(InferenceCostReservation.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(InferenceCostReservation.t),
      orderByList: orderByList?.call(InferenceCostReservation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [InferenceCostReservation]s in the list and returns the deleted rows.
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
  Future<List<InferenceCostReservation>> delete(
    _is.DatabaseSession session,
    List<InferenceCostReservation> rows, {
    _is.OrderByBuilder<InferenceCostReservationTable>? orderBy,
    _is.OrderByListBuilder<InferenceCostReservationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<InferenceCostReservation>(
      rows,
      orderBy: orderBy?.call(InferenceCostReservation.t),
      orderByList: orderByList?.call(InferenceCostReservation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [InferenceCostReservation].
  Future<InferenceCostReservation> deleteRow(
    _is.DatabaseSession session,
    InferenceCostReservation row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<InferenceCostReservation>(
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
  Future<List<InferenceCostReservation>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<InferenceCostReservationTable> where,
    _is.OrderByBuilder<InferenceCostReservationTable>? orderBy,
    _is.OrderByListBuilder<InferenceCostReservationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<InferenceCostReservation>(
      where: where(InferenceCostReservation.t),
      orderBy: orderBy?.call(InferenceCostReservation.t),
      orderByList: orderByList?.call(InferenceCostReservation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<InferenceCostReservationTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<InferenceCostReservation>(
      where: where?.call(InferenceCostReservation.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [InferenceCostReservation] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<InferenceCostReservationTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<InferenceCostReservation>(
      where: where(InferenceCostReservation.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
