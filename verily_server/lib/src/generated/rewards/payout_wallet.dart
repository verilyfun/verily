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

/// The one Solana wallet an account is paid to, proven by a signed message.
/// Re-linking replaces it; payouts already releasing keep their frozen wallet.
abstract class PayoutWallet
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  PayoutWallet._({
    this.id,
    required this.authUserId,
    this.authUser,
    required this.walletAddress,
    required this.linkedAt,
    required this.updatedAt,
  });

  factory PayoutWallet({
    _is.UuidValue? id,
    required _is.UuidValue authUserId,
    _iacs.AuthUser? authUser,
    required String walletAddress,
    required DateTime linkedAt,
    required DateTime updatedAt,
  }) = _PayoutWalletImpl;

  factory PayoutWallet.fromJson(Map<String, dynamic> jsonSerialization) {
    return PayoutWallet(
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
      walletAddress: jsonSerialization['walletAddress'] as String,
      linkedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['linkedAt'],
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = PayoutWalletTable();

  static const db = PayoutWalletRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue authUserId;

  _iacs.AuthUser? authUser;

  String walletAddress;

  DateTime linkedAt;

  DateTime updatedAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [PayoutWallet]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PayoutWallet copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? authUserId,
    _iacs.AuthUser? authUser = const _UndefinedPayoutWallet$authUser(),
    String? walletAddress,
    DateTime? linkedAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PayoutWallet',
      if (id != null) 'id': id?.toJson(),
      'authUserId': authUserId.toJson(),
      if (authUser != null) 'authUser': authUser?.toJson(),
      'walletAddress': walletAddress,
      'linkedAt': linkedAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static PayoutWalletInclude include({_iacs.AuthUserInclude? authUser}) {
    return PayoutWalletInclude._(authUser: authUser);
  }

  static PayoutWalletIncludeList includeList({
    _is.WhereExpressionBuilder<PayoutWalletTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PayoutWalletTable>? orderBy,
    _is.OrderByListBuilder<PayoutWalletTable>? orderByList,
    PayoutWalletInclude? include,
  }) {
    return PayoutWalletIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PayoutWallet.t),
      orderByList: orderByList?.call(PayoutWallet.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _UndefinedPayoutWallet$authUser extends _is.UndefinedSentinel
    implements _iacs.AuthUser {
  const _UndefinedPayoutWallet$authUser();
}

class _PayoutWalletImpl extends PayoutWallet {
  _PayoutWalletImpl({
    _is.UuidValue? id,
    required _is.UuidValue authUserId,
    _iacs.AuthUser? authUser,
    required String walletAddress,
    required DateTime linkedAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         authUserId: authUserId,
         authUser: authUser,
         walletAddress: walletAddress,
         linkedAt: linkedAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [PayoutWallet]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PayoutWallet copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? authUserId,
    _iacs.AuthUser? authUser = const _UndefinedPayoutWallet$authUser(),
    String? walletAddress,
    DateTime? linkedAt,
    DateTime? updatedAt,
  }) {
    return PayoutWallet(
      id: id is _is.UndefinedSentinel ? this.id : id,
      authUserId: authUserId ?? this.authUserId,
      authUser: authUser is _is.UndefinedSentinel
          ? this.authUser?.copyWith()
          : authUser,
      walletAddress: walletAddress ?? this.walletAddress,
      linkedAt: linkedAt ?? this.linkedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PayoutWalletUpdateTable extends _is.UpdateTable<PayoutWalletTable> {
  PayoutWalletUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> authUserId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.authUserId,
    value,
  );

  _is.ColumnValue<String, String> walletAddress(String value) =>
      _is.ColumnValue(
        table.walletAddress,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> linkedAt(DateTime value) =>
      _is.ColumnValue(
        table.linkedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _is.ColumnValue(
        table.updatedAt,
        value,
      );
}

class PayoutWalletTable extends _is.Table<_is.UuidValue?> {
  PayoutWalletTable({super.tableRelation})
    : super(tableName: 'verily_payout_wallet') {
    updateTable = PayoutWalletUpdateTable(this);
    authUserId = _is.ColumnUuid(
      'authUserId',
      this,
    );
    walletAddress = _is.ColumnString(
      'walletAddress',
      this,
    );
    linkedAt = _is.ColumnDateTime(
      'linkedAt',
      this,
    );
    updatedAt = _is.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final PayoutWalletUpdateTable updateTable;

  late final _is.ColumnUuid authUserId;

  _iacs.AuthUserTable? _authUser;

  late final _is.ColumnString walletAddress;

  late final _is.ColumnDateTime linkedAt;

  late final _is.ColumnDateTime updatedAt;

  _iacs.AuthUserTable get authUser {
    if (_authUser != null) return _authUser!;
    _authUser = _is.createRelationTable(
      relationFieldName: 'authUser',
      field: PayoutWallet.t.authUserId,
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
    walletAddress,
    linkedAt,
    updatedAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'authUser') {
      return authUser;
    }
    return null;
  }
}

class PayoutWalletInclude extends _is.IncludeObject {
  PayoutWalletInclude._({_iacs.AuthUserInclude? authUser}) {
    _authUser = authUser;
  }

  _iacs.AuthUserInclude? _authUser;

  @override
  Map<String, _is.Include?> get includes => {'authUser': _authUser};

  @override
  _is.Table<_is.UuidValue?> get table => PayoutWallet.t;
}

class PayoutWalletIncludeList extends _is.IncludeList {
  PayoutWalletIncludeList._({
    _is.WhereExpressionBuilder<PayoutWalletTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PayoutWallet.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => PayoutWallet.t;
}

class PayoutWalletRepository {
  const PayoutWalletRepository._();

  final attachRow = const PayoutWalletAttachRowRepository._();

  /// Returns a list of [PayoutWallet]s matching the given query parameters.
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
  Future<List<PayoutWallet>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PayoutWalletTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PayoutWalletTable>? orderBy,
    _is.OrderByListBuilder<PayoutWalletTable>? orderByList,
    _is.Transaction? transaction,
    PayoutWalletInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<PayoutWallet>(
      where: where?.call(PayoutWallet.t),
      orderBy: orderBy?.call(PayoutWallet.t),
      orderByList: orderByList?.call(PayoutWallet.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [PayoutWallet]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `PayoutWallet.t`.
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
  _ida.Stream<List<PayoutWallet>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PayoutWalletTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PayoutWalletTable>? orderBy,
    _is.OrderByListBuilder<PayoutWalletTable>? orderByList,
    PayoutWalletInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<PayoutWallet>(
      where: where?.call(PayoutWallet.t),
      orderBy: orderBy?.call(PayoutWallet.t),
      orderByList: orderByList?.call(PayoutWallet.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [PayoutWallet] matching the given query parameters.
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
  Future<PayoutWallet?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PayoutWalletTable>? where,
    int? offset,
    _is.OrderByBuilder<PayoutWalletTable>? orderBy,
    _is.OrderByListBuilder<PayoutWalletTable>? orderByList,
    _is.Transaction? transaction,
    PayoutWalletInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<PayoutWallet>(
      where: where?.call(PayoutWallet.t),
      orderBy: orderBy?.call(PayoutWallet.t),
      orderByList: orderByList?.call(PayoutWallet.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [PayoutWallet] by its [id] or null if no such row exists.
  Future<PayoutWallet?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    PayoutWalletInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<PayoutWallet>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [PayoutWallet]s in the list and returns the inserted rows.
  ///
  /// The returned [PayoutWallet]s will have their `id` fields set.
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
  Future<List<PayoutWallet>> insert(
    _is.DatabaseSession session,
    List<PayoutWallet> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<PayoutWallet>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [PayoutWallet] and returns the inserted row.
  ///
  /// The returned [PayoutWallet] will have its `id` field set.
  Future<PayoutWallet> insertRow(
    _is.DatabaseSession session,
    PayoutWallet row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<PayoutWallet>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [PayoutWallet]s in the list and returns the resulting rows.
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
  /// The returned [PayoutWallet]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PayoutWallet>> upsert(
    _is.DatabaseSession session,
    List<PayoutWallet> rows, {
    required _is.ColumnSelections<PayoutWalletTable> conflictColumns,
    _is.ColumnSelections<PayoutWalletTable>? updateColumns,
    _is.WhereExpressionBuilder<PayoutWalletTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<PayoutWallet>(
      rows,
      conflictColumns: conflictColumns(PayoutWallet.t),
      updateColumns: updateColumns?.call(PayoutWallet.t),
      updateWhere: updateWhere?.call(PayoutWallet.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [PayoutWallet] and returns the resulting row.
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
  /// The returned [PayoutWallet] will have its `id` field set.
  Future<PayoutWallet?> upsertRow(
    _is.DatabaseSession session,
    PayoutWallet row, {
    required _is.ColumnSelections<PayoutWalletTable> conflictColumns,
    _is.ColumnSelections<PayoutWalletTable>? updateColumns,
    _is.WhereExpressionBuilder<PayoutWalletTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<PayoutWallet>(
      row,
      conflictColumns: conflictColumns(PayoutWallet.t),
      updateColumns: updateColumns?.call(PayoutWallet.t),
      updateWhere: updateWhere?.call(PayoutWallet.t),
      transaction: transaction,
    );
  }

  /// Updates all [PayoutWallet]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PayoutWallet>> update(
    _is.DatabaseSession session,
    List<PayoutWallet> rows, {
    _is.ColumnSelections<PayoutWalletTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<PayoutWallet>(
      rows,
      columns: columns?.call(PayoutWallet.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [PayoutWallet]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PayoutWallet> updateRow(
    _is.DatabaseSession session,
    PayoutWallet row, {
    _is.ColumnSelections<PayoutWalletTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<PayoutWallet>(
      row,
      columns: columns?.call(PayoutWallet.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PayoutWallet] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<PayoutWallet?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<PayoutWalletUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<PayoutWallet>(
      id,
      columnValues: columnValues(PayoutWallet.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [PayoutWallet]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PayoutWallet>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<PayoutWalletUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<PayoutWalletTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PayoutWalletTable>? orderBy,
    _is.OrderByListBuilder<PayoutWalletTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<PayoutWallet>(
      columnValues: columnValues(PayoutWallet.t.updateTable),
      where: where(PayoutWallet.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PayoutWallet.t),
      orderByList: orderByList?.call(PayoutWallet.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [PayoutWallet]s in the list and returns the deleted rows.
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
  Future<List<PayoutWallet>> delete(
    _is.DatabaseSession session,
    List<PayoutWallet> rows, {
    _is.OrderByBuilder<PayoutWalletTable>? orderBy,
    _is.OrderByListBuilder<PayoutWalletTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<PayoutWallet>(
      rows,
      orderBy: orderBy?.call(PayoutWallet.t),
      orderByList: orderByList?.call(PayoutWallet.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [PayoutWallet].
  Future<PayoutWallet> deleteRow(
    _is.DatabaseSession session,
    PayoutWallet row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PayoutWallet>(
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
  Future<List<PayoutWallet>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PayoutWalletTable> where,
    _is.OrderByBuilder<PayoutWalletTable>? orderBy,
    _is.OrderByListBuilder<PayoutWalletTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<PayoutWallet>(
      where: where(PayoutWallet.t),
      orderBy: orderBy?.call(PayoutWallet.t),
      orderByList: orderByList?.call(PayoutWallet.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PayoutWalletTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<PayoutWallet>(
      where: where?.call(PayoutWallet.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [PayoutWallet] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PayoutWalletTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<PayoutWallet>(
      where: where(PayoutWallet.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class PayoutWalletAttachRowRepository {
  const PayoutWalletAttachRowRepository._();

  /// Creates a relation between the given [PayoutWallet] and [AuthUser]
  /// by setting the [PayoutWallet]'s foreign key `authUserId` to refer to the [AuthUser].
  Future<void> authUser(
    _is.DatabaseSession session,
    PayoutWallet payoutWallet,
    _iacs.AuthUser authUser, {
    _is.Transaction? transaction,
  }) async {
    if (payoutWallet.id == null) {
      throw ArgumentError.notNull('payoutWallet.id');
    }
    if (authUser.id == null) {
      throw ArgumentError.notNull('authUser.id');
    }

    var $payoutWallet = payoutWallet.copyWith(authUserId: authUser.id);
    await session.db.updateRow<PayoutWallet>(
      $payoutWallet,
      columns: [PayoutWallet.t.authUserId],
      transaction: transaction,
    );
  }
}
