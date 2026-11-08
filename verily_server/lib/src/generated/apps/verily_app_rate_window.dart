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

/// A fixed-window counter for one App and one rate-limited operation, such as
/// API action writes, link exchanges, or verification requests. The bucket
/// may include a pairwise subject for per-person limits.
abstract class VerilyAppRateWindow
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  VerilyAppRateWindow._({
    this.id,
    required this.appId,
    required this.bucket,
    required this.windowStartedAt,
    required this.requestCount,
  });

  factory VerilyAppRateWindow({
    _is.UuidValue? id,
    required _is.UuidValue appId,
    required String bucket,
    required DateTime windowStartedAt,
    required int requestCount,
  }) = _VerilyAppRateWindowImpl;

  factory VerilyAppRateWindow.fromJson(Map<String, dynamic> jsonSerialization) {
    return VerilyAppRateWindow(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      appId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['appId']),
      bucket: jsonSerialization['bucket'] as String,
      windowStartedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['windowStartedAt'],
      ),
      requestCount: jsonSerialization['requestCount'] as int,
    );
  }

  static final t = VerilyAppRateWindowTable();

  static const db = VerilyAppRateWindowRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue appId;

  String bucket;

  DateTime windowStartedAt;

  int requestCount;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [VerilyAppRateWindow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  VerilyAppRateWindow copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? appId,
    String? bucket,
    DateTime? windowStartedAt,
    int? requestCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'VerilyAppRateWindow',
      if (id != null) 'id': id?.toJson(),
      'appId': appId.toJson(),
      'bucket': bucket,
      'windowStartedAt': windowStartedAt.toJson(),
      'requestCount': requestCount,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static VerilyAppRateWindowInclude include() {
    return VerilyAppRateWindowInclude._();
  }

  static VerilyAppRateWindowIncludeList includeList({
    _is.WhereExpressionBuilder<VerilyAppRateWindowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VerilyAppRateWindowTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppRateWindowTable>? orderByList,
    VerilyAppRateWindowInclude? include,
  }) {
    return VerilyAppRateWindowIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(VerilyAppRateWindow.t),
      orderByList: orderByList?.call(VerilyAppRateWindow.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _VerilyAppRateWindowImpl extends VerilyAppRateWindow {
  _VerilyAppRateWindowImpl({
    _is.UuidValue? id,
    required _is.UuidValue appId,
    required String bucket,
    required DateTime windowStartedAt,
    required int requestCount,
  }) : super._(
         id: id,
         appId: appId,
         bucket: bucket,
         windowStartedAt: windowStartedAt,
         requestCount: requestCount,
       );

  /// Returns a shallow copy of this [VerilyAppRateWindow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  VerilyAppRateWindow copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? appId,
    String? bucket,
    DateTime? windowStartedAt,
    int? requestCount,
  }) {
    return VerilyAppRateWindow(
      id: id is _is.UndefinedSentinel ? this.id : id,
      appId: appId ?? this.appId,
      bucket: bucket ?? this.bucket,
      windowStartedAt: windowStartedAt ?? this.windowStartedAt,
      requestCount: requestCount ?? this.requestCount,
    );
  }
}

class VerilyAppRateWindowUpdateTable
    extends _is.UpdateTable<VerilyAppRateWindowTable> {
  VerilyAppRateWindowUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> appId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.appId,
        value,
      );

  _is.ColumnValue<String, String> bucket(String value) => _is.ColumnValue(
    table.bucket,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> windowStartedAt(DateTime value) =>
      _is.ColumnValue(
        table.windowStartedAt,
        value,
      );

  _is.ColumnValue<int, int> requestCount(int value) => _is.ColumnValue(
    table.requestCount,
    value,
  );
}

class VerilyAppRateWindowTable extends _is.Table<_is.UuidValue?> {
  VerilyAppRateWindowTable({super.tableRelation})
    : super(tableName: 'verily_app_rate_window') {
    updateTable = VerilyAppRateWindowUpdateTable(this);
    appId = _is.ColumnUuid(
      'appId',
      this,
    );
    bucket = _is.ColumnString(
      'bucket',
      this,
    );
    windowStartedAt = _is.ColumnDateTime(
      'windowStartedAt',
      this,
    );
    requestCount = _is.ColumnInt(
      'requestCount',
      this,
    );
  }

  late final VerilyAppRateWindowUpdateTable updateTable;

  late final _is.ColumnUuid appId;

  late final _is.ColumnString bucket;

  late final _is.ColumnDateTime windowStartedAt;

  late final _is.ColumnInt requestCount;

  @override
  List<_is.Column> get columns => [
    id,
    appId,
    bucket,
    windowStartedAt,
    requestCount,
  ];
}

class VerilyAppRateWindowInclude extends _is.IncludeObject {
  VerilyAppRateWindowInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<_is.UuidValue?> get table => VerilyAppRateWindow.t;
}

class VerilyAppRateWindowIncludeList extends _is.IncludeList {
  VerilyAppRateWindowIncludeList._({
    _is.WhereExpressionBuilder<VerilyAppRateWindowTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(VerilyAppRateWindow.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => VerilyAppRateWindow.t;
}

class VerilyAppRateWindowRepository {
  const VerilyAppRateWindowRepository._();

  /// Returns a list of [VerilyAppRateWindow]s matching the given query parameters.
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
  Future<List<VerilyAppRateWindow>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VerilyAppRateWindowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VerilyAppRateWindowTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppRateWindowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<VerilyAppRateWindow>(
      where: where?.call(VerilyAppRateWindow.t),
      orderBy: orderBy?.call(VerilyAppRateWindow.t),
      orderByList: orderByList?.call(VerilyAppRateWindow.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [VerilyAppRateWindow]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `VerilyAppRateWindow.t`.
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
  _ida.Stream<List<VerilyAppRateWindow>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VerilyAppRateWindowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VerilyAppRateWindowTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppRateWindowTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<VerilyAppRateWindow>(
      where: where?.call(VerilyAppRateWindow.t),
      orderBy: orderBy?.call(VerilyAppRateWindow.t),
      orderByList: orderByList?.call(VerilyAppRateWindow.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [VerilyAppRateWindow] matching the given query parameters.
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
  Future<VerilyAppRateWindow?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VerilyAppRateWindowTable>? where,
    int? offset,
    _is.OrderByBuilder<VerilyAppRateWindowTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppRateWindowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<VerilyAppRateWindow>(
      where: where?.call(VerilyAppRateWindow.t),
      orderBy: orderBy?.call(VerilyAppRateWindow.t),
      orderByList: orderByList?.call(VerilyAppRateWindow.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [VerilyAppRateWindow] by its [id] or null if no such row exists.
  Future<VerilyAppRateWindow?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<VerilyAppRateWindow>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [VerilyAppRateWindow]s in the list and returns the inserted rows.
  ///
  /// The returned [VerilyAppRateWindow]s will have their `id` fields set.
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
  Future<List<VerilyAppRateWindow>> insert(
    _is.DatabaseSession session,
    List<VerilyAppRateWindow> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<VerilyAppRateWindow>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [VerilyAppRateWindow] and returns the inserted row.
  ///
  /// The returned [VerilyAppRateWindow] will have its `id` field set.
  Future<VerilyAppRateWindow> insertRow(
    _is.DatabaseSession session,
    VerilyAppRateWindow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<VerilyAppRateWindow>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [VerilyAppRateWindow]s in the list and returns the resulting rows.
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
  /// The returned [VerilyAppRateWindow]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<VerilyAppRateWindow>> upsert(
    _is.DatabaseSession session,
    List<VerilyAppRateWindow> rows, {
    required _is.ColumnSelections<VerilyAppRateWindowTable> conflictColumns,
    _is.ColumnSelections<VerilyAppRateWindowTable>? updateColumns,
    _is.WhereExpressionBuilder<VerilyAppRateWindowTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<VerilyAppRateWindow>(
      rows,
      conflictColumns: conflictColumns(VerilyAppRateWindow.t),
      updateColumns: updateColumns?.call(VerilyAppRateWindow.t),
      updateWhere: updateWhere?.call(VerilyAppRateWindow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [VerilyAppRateWindow] and returns the resulting row.
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
  /// The returned [VerilyAppRateWindow] will have its `id` field set.
  Future<VerilyAppRateWindow?> upsertRow(
    _is.DatabaseSession session,
    VerilyAppRateWindow row, {
    required _is.ColumnSelections<VerilyAppRateWindowTable> conflictColumns,
    _is.ColumnSelections<VerilyAppRateWindowTable>? updateColumns,
    _is.WhereExpressionBuilder<VerilyAppRateWindowTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<VerilyAppRateWindow>(
      row,
      conflictColumns: conflictColumns(VerilyAppRateWindow.t),
      updateColumns: updateColumns?.call(VerilyAppRateWindow.t),
      updateWhere: updateWhere?.call(VerilyAppRateWindow.t),
      transaction: transaction,
    );
  }

  /// Updates all [VerilyAppRateWindow]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<VerilyAppRateWindow>> update(
    _is.DatabaseSession session,
    List<VerilyAppRateWindow> rows, {
    _is.ColumnSelections<VerilyAppRateWindowTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<VerilyAppRateWindow>(
      rows,
      columns: columns?.call(VerilyAppRateWindow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [VerilyAppRateWindow]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<VerilyAppRateWindow> updateRow(
    _is.DatabaseSession session,
    VerilyAppRateWindow row, {
    _is.ColumnSelections<VerilyAppRateWindowTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<VerilyAppRateWindow>(
      row,
      columns: columns?.call(VerilyAppRateWindow.t),
      transaction: transaction,
    );
  }

  /// Updates a single [VerilyAppRateWindow] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<VerilyAppRateWindow?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<VerilyAppRateWindowUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<VerilyAppRateWindow>(
      id,
      columnValues: columnValues(VerilyAppRateWindow.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [VerilyAppRateWindow]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<VerilyAppRateWindow>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<VerilyAppRateWindowUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<VerilyAppRateWindowTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VerilyAppRateWindowTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppRateWindowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<VerilyAppRateWindow>(
      columnValues: columnValues(VerilyAppRateWindow.t.updateTable),
      where: where(VerilyAppRateWindow.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(VerilyAppRateWindow.t),
      orderByList: orderByList?.call(VerilyAppRateWindow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [VerilyAppRateWindow]s in the list and returns the deleted rows.
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
  Future<List<VerilyAppRateWindow>> delete(
    _is.DatabaseSession session,
    List<VerilyAppRateWindow> rows, {
    _is.OrderByBuilder<VerilyAppRateWindowTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppRateWindowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<VerilyAppRateWindow>(
      rows,
      orderBy: orderBy?.call(VerilyAppRateWindow.t),
      orderByList: orderByList?.call(VerilyAppRateWindow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [VerilyAppRateWindow].
  Future<VerilyAppRateWindow> deleteRow(
    _is.DatabaseSession session,
    VerilyAppRateWindow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<VerilyAppRateWindow>(
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
  Future<List<VerilyAppRateWindow>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<VerilyAppRateWindowTable> where,
    _is.OrderByBuilder<VerilyAppRateWindowTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppRateWindowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<VerilyAppRateWindow>(
      where: where(VerilyAppRateWindow.t),
      orderBy: orderBy?.call(VerilyAppRateWindow.t),
      orderByList: orderByList?.call(VerilyAppRateWindow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VerilyAppRateWindowTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<VerilyAppRateWindow>(
      where: where?.call(VerilyAppRateWindow.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [VerilyAppRateWindow] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<VerilyAppRateWindowTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<VerilyAppRateWindow>(
      where: where(VerilyAppRateWindow.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
