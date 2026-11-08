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

/// One exact-match return address for deep links. No wildcards, no fragments.
abstract class VerilyAppRedirectUri
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  VerilyAppRedirectUri._({
    this.id,
    required this.appId,
    required this.uri,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory VerilyAppRedirectUri({
    _is.UuidValue? id,
    required _is.UuidValue appId,
    required String uri,
    DateTime? createdAt,
  }) = _VerilyAppRedirectUriImpl;

  factory VerilyAppRedirectUri.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return VerilyAppRedirectUri(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      appId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['appId']),
      uri: jsonSerialization['uri'] as String,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = VerilyAppRedirectUriTable();

  static const db = VerilyAppRedirectUriRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue appId;

  String uri;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [VerilyAppRedirectUri]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  VerilyAppRedirectUri copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? appId,
    String? uri,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'VerilyAppRedirectUri',
      if (id != null) 'id': id?.toJson(),
      'appId': appId.toJson(),
      'uri': uri,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static VerilyAppRedirectUriInclude include() {
    return VerilyAppRedirectUriInclude._();
  }

  static VerilyAppRedirectUriIncludeList includeList({
    _is.WhereExpressionBuilder<VerilyAppRedirectUriTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VerilyAppRedirectUriTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppRedirectUriTable>? orderByList,
    VerilyAppRedirectUriInclude? include,
  }) {
    return VerilyAppRedirectUriIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(VerilyAppRedirectUri.t),
      orderByList: orderByList?.call(VerilyAppRedirectUri.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _VerilyAppRedirectUriImpl extends VerilyAppRedirectUri {
  _VerilyAppRedirectUriImpl({
    _is.UuidValue? id,
    required _is.UuidValue appId,
    required String uri,
    DateTime? createdAt,
  }) : super._(
         id: id,
         appId: appId,
         uri: uri,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [VerilyAppRedirectUri]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  VerilyAppRedirectUri copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? appId,
    String? uri,
    DateTime? createdAt,
  }) {
    return VerilyAppRedirectUri(
      id: id is _is.UndefinedSentinel ? this.id : id,
      appId: appId ?? this.appId,
      uri: uri ?? this.uri,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class VerilyAppRedirectUriUpdateTable
    extends _is.UpdateTable<VerilyAppRedirectUriTable> {
  VerilyAppRedirectUriUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> appId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.appId,
        value,
      );

  _is.ColumnValue<String, String> uri(String value) => _is.ColumnValue(
    table.uri,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class VerilyAppRedirectUriTable extends _is.Table<_is.UuidValue?> {
  VerilyAppRedirectUriTable({super.tableRelation})
    : super(tableName: 'verily_app_redirect_uri') {
    updateTable = VerilyAppRedirectUriUpdateTable(this);
    appId = _is.ColumnUuid(
      'appId',
      this,
    );
    uri = _is.ColumnString(
      'uri',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final VerilyAppRedirectUriUpdateTable updateTable;

  late final _is.ColumnUuid appId;

  late final _is.ColumnString uri;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    appId,
    uri,
    createdAt,
  ];
}

class VerilyAppRedirectUriInclude extends _is.IncludeObject {
  VerilyAppRedirectUriInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<_is.UuidValue?> get table => VerilyAppRedirectUri.t;
}

class VerilyAppRedirectUriIncludeList extends _is.IncludeList {
  VerilyAppRedirectUriIncludeList._({
    _is.WhereExpressionBuilder<VerilyAppRedirectUriTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(VerilyAppRedirectUri.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => VerilyAppRedirectUri.t;
}

class VerilyAppRedirectUriRepository {
  const VerilyAppRedirectUriRepository._();

  /// Returns a list of [VerilyAppRedirectUri]s matching the given query parameters.
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
  Future<List<VerilyAppRedirectUri>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VerilyAppRedirectUriTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VerilyAppRedirectUriTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppRedirectUriTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<VerilyAppRedirectUri>(
      where: where?.call(VerilyAppRedirectUri.t),
      orderBy: orderBy?.call(VerilyAppRedirectUri.t),
      orderByList: orderByList?.call(VerilyAppRedirectUri.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [VerilyAppRedirectUri]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `VerilyAppRedirectUri.t`.
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
  _ida.Stream<List<VerilyAppRedirectUri>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VerilyAppRedirectUriTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VerilyAppRedirectUriTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppRedirectUriTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<VerilyAppRedirectUri>(
      where: where?.call(VerilyAppRedirectUri.t),
      orderBy: orderBy?.call(VerilyAppRedirectUri.t),
      orderByList: orderByList?.call(VerilyAppRedirectUri.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [VerilyAppRedirectUri] matching the given query parameters.
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
  Future<VerilyAppRedirectUri?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VerilyAppRedirectUriTable>? where,
    int? offset,
    _is.OrderByBuilder<VerilyAppRedirectUriTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppRedirectUriTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<VerilyAppRedirectUri>(
      where: where?.call(VerilyAppRedirectUri.t),
      orderBy: orderBy?.call(VerilyAppRedirectUri.t),
      orderByList: orderByList?.call(VerilyAppRedirectUri.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [VerilyAppRedirectUri] by its [id] or null if no such row exists.
  Future<VerilyAppRedirectUri?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<VerilyAppRedirectUri>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [VerilyAppRedirectUri]s in the list and returns the inserted rows.
  ///
  /// The returned [VerilyAppRedirectUri]s will have their `id` fields set.
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
  Future<List<VerilyAppRedirectUri>> insert(
    _is.DatabaseSession session,
    List<VerilyAppRedirectUri> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<VerilyAppRedirectUri>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [VerilyAppRedirectUri] and returns the inserted row.
  ///
  /// The returned [VerilyAppRedirectUri] will have its `id` field set.
  Future<VerilyAppRedirectUri> insertRow(
    _is.DatabaseSession session,
    VerilyAppRedirectUri row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<VerilyAppRedirectUri>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [VerilyAppRedirectUri]s in the list and returns the resulting rows.
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
  /// The returned [VerilyAppRedirectUri]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<VerilyAppRedirectUri>> upsert(
    _is.DatabaseSession session,
    List<VerilyAppRedirectUri> rows, {
    required _is.ColumnSelections<VerilyAppRedirectUriTable> conflictColumns,
    _is.ColumnSelections<VerilyAppRedirectUriTable>? updateColumns,
    _is.WhereExpressionBuilder<VerilyAppRedirectUriTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<VerilyAppRedirectUri>(
      rows,
      conflictColumns: conflictColumns(VerilyAppRedirectUri.t),
      updateColumns: updateColumns?.call(VerilyAppRedirectUri.t),
      updateWhere: updateWhere?.call(VerilyAppRedirectUri.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [VerilyAppRedirectUri] and returns the resulting row.
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
  /// The returned [VerilyAppRedirectUri] will have its `id` field set.
  Future<VerilyAppRedirectUri?> upsertRow(
    _is.DatabaseSession session,
    VerilyAppRedirectUri row, {
    required _is.ColumnSelections<VerilyAppRedirectUriTable> conflictColumns,
    _is.ColumnSelections<VerilyAppRedirectUriTable>? updateColumns,
    _is.WhereExpressionBuilder<VerilyAppRedirectUriTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<VerilyAppRedirectUri>(
      row,
      conflictColumns: conflictColumns(VerilyAppRedirectUri.t),
      updateColumns: updateColumns?.call(VerilyAppRedirectUri.t),
      updateWhere: updateWhere?.call(VerilyAppRedirectUri.t),
      transaction: transaction,
    );
  }

  /// Updates all [VerilyAppRedirectUri]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<VerilyAppRedirectUri>> update(
    _is.DatabaseSession session,
    List<VerilyAppRedirectUri> rows, {
    _is.ColumnSelections<VerilyAppRedirectUriTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<VerilyAppRedirectUri>(
      rows,
      columns: columns?.call(VerilyAppRedirectUri.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [VerilyAppRedirectUri]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<VerilyAppRedirectUri> updateRow(
    _is.DatabaseSession session,
    VerilyAppRedirectUri row, {
    _is.ColumnSelections<VerilyAppRedirectUriTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<VerilyAppRedirectUri>(
      row,
      columns: columns?.call(VerilyAppRedirectUri.t),
      transaction: transaction,
    );
  }

  /// Updates a single [VerilyAppRedirectUri] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<VerilyAppRedirectUri?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<VerilyAppRedirectUriUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<VerilyAppRedirectUri>(
      id,
      columnValues: columnValues(VerilyAppRedirectUri.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [VerilyAppRedirectUri]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<VerilyAppRedirectUri>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<VerilyAppRedirectUriUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<VerilyAppRedirectUriTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VerilyAppRedirectUriTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppRedirectUriTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<VerilyAppRedirectUri>(
      columnValues: columnValues(VerilyAppRedirectUri.t.updateTable),
      where: where(VerilyAppRedirectUri.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(VerilyAppRedirectUri.t),
      orderByList: orderByList?.call(VerilyAppRedirectUri.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [VerilyAppRedirectUri]s in the list and returns the deleted rows.
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
  Future<List<VerilyAppRedirectUri>> delete(
    _is.DatabaseSession session,
    List<VerilyAppRedirectUri> rows, {
    _is.OrderByBuilder<VerilyAppRedirectUriTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppRedirectUriTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<VerilyAppRedirectUri>(
      rows,
      orderBy: orderBy?.call(VerilyAppRedirectUri.t),
      orderByList: orderByList?.call(VerilyAppRedirectUri.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [VerilyAppRedirectUri].
  Future<VerilyAppRedirectUri> deleteRow(
    _is.DatabaseSession session,
    VerilyAppRedirectUri row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<VerilyAppRedirectUri>(
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
  Future<List<VerilyAppRedirectUri>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<VerilyAppRedirectUriTable> where,
    _is.OrderByBuilder<VerilyAppRedirectUriTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppRedirectUriTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<VerilyAppRedirectUri>(
      where: where(VerilyAppRedirectUri.t),
      orderBy: orderBy?.call(VerilyAppRedirectUri.t),
      orderByList: orderByList?.call(VerilyAppRedirectUri.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VerilyAppRedirectUriTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<VerilyAppRedirectUri>(
      where: where?.call(VerilyAppRedirectUri.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [VerilyAppRedirectUri] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<VerilyAppRedirectUriTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<VerilyAppRedirectUri>(
      where: where(VerilyAppRedirectUri.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
