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

/// Durable intent and completion record for an operator's Apple bit update.
abstract class DeviceCheckAudit
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  DeviceCheckAudit._({
    this.id,
    required this.operatorAuthUserId,
    required this.tokenHash,
    required this.banned,
    required this.reviewRequired,
    required this.note,
    required this.createdAt,
    this.completedAt,
  });

  factory DeviceCheckAudit({
    _is.UuidValue? id,
    required _is.UuidValue operatorAuthUserId,
    required String tokenHash,
    required bool banned,
    required bool reviewRequired,
    required String note,
    required DateTime createdAt,
    DateTime? completedAt,
  }) = _DeviceCheckAuditImpl;

  factory DeviceCheckAudit.fromJson(Map<String, dynamic> jsonSerialization) {
    return DeviceCheckAudit(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      operatorAuthUserId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['operatorAuthUserId'],
      ),
      tokenHash: jsonSerialization['tokenHash'] as String,
      banned: _is.BoolJsonExtension.fromJson(jsonSerialization['banned']),
      reviewRequired: _is.BoolJsonExtension.fromJson(
        jsonSerialization['reviewRequired'],
      ),
      note: jsonSerialization['note'] as String,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      completedAt: jsonSerialization['completedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['completedAt'],
            ),
    );
  }

  static final t = DeviceCheckAuditTable();

  static const db = DeviceCheckAuditRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue operatorAuthUserId;

  /// Hash of the ephemeral token, for audit correlation only; not a device ID.
  String tokenHash;

  bool banned;

  bool reviewRequired;

  String note;

  DateTime createdAt;

  DateTime? completedAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [DeviceCheckAudit]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DeviceCheckAudit copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? operatorAuthUserId,
    String? tokenHash,
    bool? banned,
    bool? reviewRequired,
    String? note,
    DateTime? createdAt,
    DateTime? completedAt = const _is.$UndefinedDateTime(),
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeviceCheckAudit',
      if (id != null) 'id': id?.toJson(),
      'operatorAuthUserId': operatorAuthUserId.toJson(),
      'tokenHash': tokenHash,
      'banned': banned,
      'reviewRequired': reviewRequired,
      'note': note,
      'createdAt': createdAt.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static DeviceCheckAuditInclude include() {
    return DeviceCheckAuditInclude._();
  }

  static DeviceCheckAuditIncludeList includeList({
    _is.WhereExpressionBuilder<DeviceCheckAuditTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DeviceCheckAuditTable>? orderBy,
    _is.OrderByListBuilder<DeviceCheckAuditTable>? orderByList,
    DeviceCheckAuditInclude? include,
  }) {
    return DeviceCheckAuditIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DeviceCheckAudit.t),
      orderByList: orderByList?.call(DeviceCheckAudit.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _DeviceCheckAuditImpl extends DeviceCheckAudit {
  _DeviceCheckAuditImpl({
    _is.UuidValue? id,
    required _is.UuidValue operatorAuthUserId,
    required String tokenHash,
    required bool banned,
    required bool reviewRequired,
    required String note,
    required DateTime createdAt,
    DateTime? completedAt,
  }) : super._(
         id: id,
         operatorAuthUserId: operatorAuthUserId,
         tokenHash: tokenHash,
         banned: banned,
         reviewRequired: reviewRequired,
         note: note,
         createdAt: createdAt,
         completedAt: completedAt,
       );

  /// Returns a shallow copy of this [DeviceCheckAudit]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DeviceCheckAudit copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? operatorAuthUserId,
    String? tokenHash,
    bool? banned,
    bool? reviewRequired,
    String? note,
    DateTime? createdAt,
    DateTime? completedAt = const _is.$UndefinedDateTime(),
  }) {
    return DeviceCheckAudit(
      id: id is _is.UndefinedSentinel ? this.id : id,
      operatorAuthUserId: operatorAuthUserId ?? this.operatorAuthUserId,
      tokenHash: tokenHash ?? this.tokenHash,
      banned: banned ?? this.banned,
      reviewRequired: reviewRequired ?? this.reviewRequired,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt is _is.UndefinedSentinel
          ? this.completedAt
          : completedAt,
    );
  }
}

class DeviceCheckAuditUpdateTable
    extends _is.UpdateTable<DeviceCheckAuditTable> {
  DeviceCheckAuditUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> operatorAuthUserId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.operatorAuthUserId,
    value,
  );

  _is.ColumnValue<String, String> tokenHash(String value) => _is.ColumnValue(
    table.tokenHash,
    value,
  );

  _is.ColumnValue<bool, bool> banned(bool value) => _is.ColumnValue(
    table.banned,
    value,
  );

  _is.ColumnValue<bool, bool> reviewRequired(bool value) => _is.ColumnValue(
    table.reviewRequired,
    value,
  );

  _is.ColumnValue<String, String> note(String value) => _is.ColumnValue(
    table.note,
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

class DeviceCheckAuditTable extends _is.Table<_is.UuidValue?> {
  DeviceCheckAuditTable({super.tableRelation})
    : super(tableName: 'verily_device_check_audit') {
    updateTable = DeviceCheckAuditUpdateTable(this);
    operatorAuthUserId = _is.ColumnUuid(
      'operatorAuthUserId',
      this,
    );
    tokenHash = _is.ColumnString(
      'tokenHash',
      this,
    );
    banned = _is.ColumnBool(
      'banned',
      this,
    );
    reviewRequired = _is.ColumnBool(
      'reviewRequired',
      this,
    );
    note = _is.ColumnString(
      'note',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    completedAt = _is.ColumnDateTime(
      'completedAt',
      this,
    );
  }

  late final DeviceCheckAuditUpdateTable updateTable;

  late final _is.ColumnUuid operatorAuthUserId;

  /// Hash of the ephemeral token, for audit correlation only; not a device ID.
  late final _is.ColumnString tokenHash;

  late final _is.ColumnBool banned;

  late final _is.ColumnBool reviewRequired;

  late final _is.ColumnString note;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime completedAt;

  @override
  List<_is.Column> get columns => [
    id,
    operatorAuthUserId,
    tokenHash,
    banned,
    reviewRequired,
    note,
    createdAt,
    completedAt,
  ];
}

class DeviceCheckAuditInclude extends _is.IncludeObject {
  DeviceCheckAuditInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<_is.UuidValue?> get table => DeviceCheckAudit.t;
}

class DeviceCheckAuditIncludeList extends _is.IncludeList {
  DeviceCheckAuditIncludeList._({
    _is.WhereExpressionBuilder<DeviceCheckAuditTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DeviceCheckAudit.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => DeviceCheckAudit.t;
}

class DeviceCheckAuditRepository {
  const DeviceCheckAuditRepository._();

  /// Returns a list of [DeviceCheckAudit]s matching the given query parameters.
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
  Future<List<DeviceCheckAudit>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DeviceCheckAuditTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DeviceCheckAuditTable>? orderBy,
    _is.OrderByListBuilder<DeviceCheckAuditTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<DeviceCheckAudit>(
      where: where?.call(DeviceCheckAudit.t),
      orderBy: orderBy?.call(DeviceCheckAudit.t),
      orderByList: orderByList?.call(DeviceCheckAudit.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [DeviceCheckAudit]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `DeviceCheckAudit.t`.
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
  _ida.Stream<List<DeviceCheckAudit>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DeviceCheckAuditTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DeviceCheckAuditTable>? orderBy,
    _is.OrderByListBuilder<DeviceCheckAuditTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<DeviceCheckAudit>(
      where: where?.call(DeviceCheckAudit.t),
      orderBy: orderBy?.call(DeviceCheckAudit.t),
      orderByList: orderByList?.call(DeviceCheckAudit.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [DeviceCheckAudit] matching the given query parameters.
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
  Future<DeviceCheckAudit?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DeviceCheckAuditTable>? where,
    int? offset,
    _is.OrderByBuilder<DeviceCheckAuditTable>? orderBy,
    _is.OrderByListBuilder<DeviceCheckAuditTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<DeviceCheckAudit>(
      where: where?.call(DeviceCheckAudit.t),
      orderBy: orderBy?.call(DeviceCheckAudit.t),
      orderByList: orderByList?.call(DeviceCheckAudit.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [DeviceCheckAudit] by its [id] or null if no such row exists.
  Future<DeviceCheckAudit?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<DeviceCheckAudit>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [DeviceCheckAudit]s in the list and returns the inserted rows.
  ///
  /// The returned [DeviceCheckAudit]s will have their `id` fields set.
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
  Future<List<DeviceCheckAudit>> insert(
    _is.DatabaseSession session,
    List<DeviceCheckAudit> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<DeviceCheckAudit>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [DeviceCheckAudit] and returns the inserted row.
  ///
  /// The returned [DeviceCheckAudit] will have its `id` field set.
  Future<DeviceCheckAudit> insertRow(
    _is.DatabaseSession session,
    DeviceCheckAudit row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<DeviceCheckAudit>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [DeviceCheckAudit]s in the list and returns the resulting rows.
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
  /// The returned [DeviceCheckAudit]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DeviceCheckAudit>> upsert(
    _is.DatabaseSession session,
    List<DeviceCheckAudit> rows, {
    required _is.ColumnSelections<DeviceCheckAuditTable> conflictColumns,
    _is.ColumnSelections<DeviceCheckAuditTable>? updateColumns,
    _is.WhereExpressionBuilder<DeviceCheckAuditTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<DeviceCheckAudit>(
      rows,
      conflictColumns: conflictColumns(DeviceCheckAudit.t),
      updateColumns: updateColumns?.call(DeviceCheckAudit.t),
      updateWhere: updateWhere?.call(DeviceCheckAudit.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [DeviceCheckAudit] and returns the resulting row.
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
  /// The returned [DeviceCheckAudit] will have its `id` field set.
  Future<DeviceCheckAudit?> upsertRow(
    _is.DatabaseSession session,
    DeviceCheckAudit row, {
    required _is.ColumnSelections<DeviceCheckAuditTable> conflictColumns,
    _is.ColumnSelections<DeviceCheckAuditTable>? updateColumns,
    _is.WhereExpressionBuilder<DeviceCheckAuditTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<DeviceCheckAudit>(
      row,
      conflictColumns: conflictColumns(DeviceCheckAudit.t),
      updateColumns: updateColumns?.call(DeviceCheckAudit.t),
      updateWhere: updateWhere?.call(DeviceCheckAudit.t),
      transaction: transaction,
    );
  }

  /// Updates all [DeviceCheckAudit]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DeviceCheckAudit>> update(
    _is.DatabaseSession session,
    List<DeviceCheckAudit> rows, {
    _is.ColumnSelections<DeviceCheckAuditTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<DeviceCheckAudit>(
      rows,
      columns: columns?.call(DeviceCheckAudit.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [DeviceCheckAudit]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DeviceCheckAudit> updateRow(
    _is.DatabaseSession session,
    DeviceCheckAudit row, {
    _is.ColumnSelections<DeviceCheckAuditTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<DeviceCheckAudit>(
      row,
      columns: columns?.call(DeviceCheckAudit.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DeviceCheckAudit] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DeviceCheckAudit?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<DeviceCheckAuditUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<DeviceCheckAudit>(
      id,
      columnValues: columnValues(DeviceCheckAudit.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DeviceCheckAudit]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DeviceCheckAudit>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<DeviceCheckAuditUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<DeviceCheckAuditTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DeviceCheckAuditTable>? orderBy,
    _is.OrderByListBuilder<DeviceCheckAuditTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<DeviceCheckAudit>(
      columnValues: columnValues(DeviceCheckAudit.t.updateTable),
      where: where(DeviceCheckAudit.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DeviceCheckAudit.t),
      orderByList: orderByList?.call(DeviceCheckAudit.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [DeviceCheckAudit]s in the list and returns the deleted rows.
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
  Future<List<DeviceCheckAudit>> delete(
    _is.DatabaseSession session,
    List<DeviceCheckAudit> rows, {
    _is.OrderByBuilder<DeviceCheckAuditTable>? orderBy,
    _is.OrderByListBuilder<DeviceCheckAuditTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<DeviceCheckAudit>(
      rows,
      orderBy: orderBy?.call(DeviceCheckAudit.t),
      orderByList: orderByList?.call(DeviceCheckAudit.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [DeviceCheckAudit].
  Future<DeviceCheckAudit> deleteRow(
    _is.DatabaseSession session,
    DeviceCheckAudit row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DeviceCheckAudit>(
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
  Future<List<DeviceCheckAudit>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DeviceCheckAuditTable> where,
    _is.OrderByBuilder<DeviceCheckAuditTable>? orderBy,
    _is.OrderByListBuilder<DeviceCheckAuditTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<DeviceCheckAudit>(
      where: where(DeviceCheckAudit.t),
      orderBy: orderBy?.call(DeviceCheckAudit.t),
      orderByList: orderByList?.call(DeviceCheckAudit.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DeviceCheckAuditTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<DeviceCheckAudit>(
      where: where?.call(DeviceCheckAudit.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [DeviceCheckAudit] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DeviceCheckAuditTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<DeviceCheckAudit>(
      where: where(DeviceCheckAudit.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
