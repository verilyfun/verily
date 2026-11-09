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

import '../account/account_closure_status.dart' as _ig2l302v;

/// Identity-purge receipt retained after sign-in is blocked; never a public profile.
abstract class AccountClosure
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  AccountClosure._({
    this.id,
    required this.authUserId,
    _ig2l302v.AccountClosureStatus? status,
    DateTime? requestedAt,
    DateTime? identityPurgedAt,
  }) : status = status ?? _ig2l302v.AccountClosureStatus.closed,
       requestedAt = requestedAt ?? DateTime.now(),
       identityPurgedAt = identityPurgedAt ?? DateTime.now();

  factory AccountClosure({
    _is.UuidValue? id,
    required _is.UuidValue authUserId,
    _ig2l302v.AccountClosureStatus? status,
    DateTime? requestedAt,
    DateTime? identityPurgedAt,
  }) = _AccountClosureImpl;

  factory AccountClosure.fromJson(Map<String, dynamic> jsonSerialization) {
    return AccountClosure(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      authUserId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['authUserId'],
      ),
      status: jsonSerialization['status'] == null
          ? null
          : _ig2l302v.AccountClosureStatus.fromJson(
              (jsonSerialization['status'] as String),
            ),
      requestedAt: jsonSerialization['requestedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['requestedAt'],
            ),
      identityPurgedAt: jsonSerialization['identityPurgedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['identityPurgedAt'],
            ),
    );
  }

  static final t = AccountClosureTable();

  static const db = AccountClosureRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue authUserId;

  _ig2l302v.AccountClosureStatus status;

  DateTime requestedAt;

  DateTime identityPurgedAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [AccountClosure]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AccountClosure copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? authUserId,
    _ig2l302v.AccountClosureStatus? status,
    DateTime? requestedAt,
    DateTime? identityPurgedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AccountClosure',
      if (id != null) 'id': id?.toJson(),
      'authUserId': authUserId.toJson(),
      'status': status.toJson(),
      'requestedAt': requestedAt.toJson(),
      'identityPurgedAt': identityPurgedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static AccountClosureInclude include() {
    return AccountClosureInclude._();
  }

  static AccountClosureIncludeList includeList({
    _is.WhereExpressionBuilder<AccountClosureTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AccountClosureTable>? orderBy,
    _is.OrderByListBuilder<AccountClosureTable>? orderByList,
    AccountClosureInclude? include,
  }) {
    return AccountClosureIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AccountClosure.t),
      orderByList: orderByList?.call(AccountClosure.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _AccountClosureImpl extends AccountClosure {
  _AccountClosureImpl({
    _is.UuidValue? id,
    required _is.UuidValue authUserId,
    _ig2l302v.AccountClosureStatus? status,
    DateTime? requestedAt,
    DateTime? identityPurgedAt,
  }) : super._(
         id: id,
         authUserId: authUserId,
         status: status,
         requestedAt: requestedAt,
         identityPurgedAt: identityPurgedAt,
       );

  /// Returns a shallow copy of this [AccountClosure]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AccountClosure copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? authUserId,
    _ig2l302v.AccountClosureStatus? status,
    DateTime? requestedAt,
    DateTime? identityPurgedAt,
  }) {
    return AccountClosure(
      id: id is _is.UndefinedSentinel ? this.id : id,
      authUserId: authUserId ?? this.authUserId,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      identityPurgedAt: identityPurgedAt ?? this.identityPurgedAt,
    );
  }
}

class AccountClosureUpdateTable extends _is.UpdateTable<AccountClosureTable> {
  AccountClosureUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> authUserId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.authUserId,
    value,
  );

  _is.ColumnValue<
    _ig2l302v.AccountClosureStatus,
    _ig2l302v.AccountClosureStatus
  >
  status(_ig2l302v.AccountClosureStatus value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> requestedAt(DateTime value) =>
      _is.ColumnValue(
        table.requestedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> identityPurgedAt(DateTime value) =>
      _is.ColumnValue(
        table.identityPurgedAt,
        value,
      );
}

class AccountClosureTable extends _is.Table<_is.UuidValue?> {
  AccountClosureTable({super.tableRelation})
    : super(tableName: 'verily_account_closure') {
    updateTable = AccountClosureUpdateTable(this);
    authUserId = _is.ColumnUuid(
      'authUserId',
      this,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    requestedAt = _is.ColumnDateTime(
      'requestedAt',
      this,
      hasDefault: true,
    );
    identityPurgedAt = _is.ColumnDateTime(
      'identityPurgedAt',
      this,
      hasDefault: true,
    );
  }

  late final AccountClosureUpdateTable updateTable;

  late final _is.ColumnUuid authUserId;

  late final _is.ColumnEnum<_ig2l302v.AccountClosureStatus> status;

  late final _is.ColumnDateTime requestedAt;

  late final _is.ColumnDateTime identityPurgedAt;

  @override
  List<_is.Column> get columns => [
    id,
    authUserId,
    status,
    requestedAt,
    identityPurgedAt,
  ];
}

class AccountClosureInclude extends _is.IncludeObject {
  AccountClosureInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<_is.UuidValue?> get table => AccountClosure.t;
}

class AccountClosureIncludeList extends _is.IncludeList {
  AccountClosureIncludeList._({
    _is.WhereExpressionBuilder<AccountClosureTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AccountClosure.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => AccountClosure.t;
}

class AccountClosureRepository {
  const AccountClosureRepository._();

  /// Returns a list of [AccountClosure]s matching the given query parameters.
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
  Future<List<AccountClosure>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AccountClosureTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AccountClosureTable>? orderBy,
    _is.OrderByListBuilder<AccountClosureTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<AccountClosure>(
      where: where?.call(AccountClosure.t),
      orderBy: orderBy?.call(AccountClosure.t),
      orderByList: orderByList?.call(AccountClosure.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [AccountClosure]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `AccountClosure.t`.
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
  _ida.Stream<List<AccountClosure>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AccountClosureTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AccountClosureTable>? orderBy,
    _is.OrderByListBuilder<AccountClosureTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<AccountClosure>(
      where: where?.call(AccountClosure.t),
      orderBy: orderBy?.call(AccountClosure.t),
      orderByList: orderByList?.call(AccountClosure.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [AccountClosure] matching the given query parameters.
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
  Future<AccountClosure?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AccountClosureTable>? where,
    int? offset,
    _is.OrderByBuilder<AccountClosureTable>? orderBy,
    _is.OrderByListBuilder<AccountClosureTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<AccountClosure>(
      where: where?.call(AccountClosure.t),
      orderBy: orderBy?.call(AccountClosure.t),
      orderByList: orderByList?.call(AccountClosure.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [AccountClosure] by its [id] or null if no such row exists.
  Future<AccountClosure?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<AccountClosure>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [AccountClosure]s in the list and returns the inserted rows.
  ///
  /// The returned [AccountClosure]s will have their `id` fields set.
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
  Future<List<AccountClosure>> insert(
    _is.DatabaseSession session,
    List<AccountClosure> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<AccountClosure>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [AccountClosure] and returns the inserted row.
  ///
  /// The returned [AccountClosure] will have its `id` field set.
  Future<AccountClosure> insertRow(
    _is.DatabaseSession session,
    AccountClosure row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<AccountClosure>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [AccountClosure]s in the list and returns the resulting rows.
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
  /// The returned [AccountClosure]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AccountClosure>> upsert(
    _is.DatabaseSession session,
    List<AccountClosure> rows, {
    required _is.ColumnSelections<AccountClosureTable> conflictColumns,
    _is.ColumnSelections<AccountClosureTable>? updateColumns,
    _is.WhereExpressionBuilder<AccountClosureTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<AccountClosure>(
      rows,
      conflictColumns: conflictColumns(AccountClosure.t),
      updateColumns: updateColumns?.call(AccountClosure.t),
      updateWhere: updateWhere?.call(AccountClosure.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [AccountClosure] and returns the resulting row.
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
  /// The returned [AccountClosure] will have its `id` field set.
  Future<AccountClosure?> upsertRow(
    _is.DatabaseSession session,
    AccountClosure row, {
    required _is.ColumnSelections<AccountClosureTable> conflictColumns,
    _is.ColumnSelections<AccountClosureTable>? updateColumns,
    _is.WhereExpressionBuilder<AccountClosureTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<AccountClosure>(
      row,
      conflictColumns: conflictColumns(AccountClosure.t),
      updateColumns: updateColumns?.call(AccountClosure.t),
      updateWhere: updateWhere?.call(AccountClosure.t),
      transaction: transaction,
    );
  }

  /// Updates all [AccountClosure]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AccountClosure>> update(
    _is.DatabaseSession session,
    List<AccountClosure> rows, {
    _is.ColumnSelections<AccountClosureTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<AccountClosure>(
      rows,
      columns: columns?.call(AccountClosure.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [AccountClosure]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AccountClosure> updateRow(
    _is.DatabaseSession session,
    AccountClosure row, {
    _is.ColumnSelections<AccountClosureTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<AccountClosure>(
      row,
      columns: columns?.call(AccountClosure.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AccountClosure] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AccountClosure?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<AccountClosureUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<AccountClosure>(
      id,
      columnValues: columnValues(AccountClosure.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AccountClosure]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AccountClosure>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<AccountClosureUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<AccountClosureTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AccountClosureTable>? orderBy,
    _is.OrderByListBuilder<AccountClosureTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<AccountClosure>(
      columnValues: columnValues(AccountClosure.t.updateTable),
      where: where(AccountClosure.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AccountClosure.t),
      orderByList: orderByList?.call(AccountClosure.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [AccountClosure]s in the list and returns the deleted rows.
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
  Future<List<AccountClosure>> delete(
    _is.DatabaseSession session,
    List<AccountClosure> rows, {
    _is.OrderByBuilder<AccountClosureTable>? orderBy,
    _is.OrderByListBuilder<AccountClosureTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<AccountClosure>(
      rows,
      orderBy: orderBy?.call(AccountClosure.t),
      orderByList: orderByList?.call(AccountClosure.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [AccountClosure].
  Future<AccountClosure> deleteRow(
    _is.DatabaseSession session,
    AccountClosure row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AccountClosure>(
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
  Future<List<AccountClosure>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AccountClosureTable> where,
    _is.OrderByBuilder<AccountClosureTable>? orderBy,
    _is.OrderByListBuilder<AccountClosureTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<AccountClosure>(
      where: where(AccountClosure.t),
      orderBy: orderBy?.call(AccountClosure.t),
      orderByList: orderByList?.call(AccountClosure.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AccountClosureTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<AccountClosure>(
      where: where?.call(AccountClosure.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [AccountClosure] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AccountClosureTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<AccountClosure>(
      where: where(AccountClosure.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
