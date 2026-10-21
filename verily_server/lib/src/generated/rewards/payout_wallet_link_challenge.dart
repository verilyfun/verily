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

/// Expiring, single-use message an account's wallet signs to prove ownership.
abstract class PayoutWalletLinkChallenge
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  PayoutWalletLinkChallenge._({
    this.id,
    required this.authUserId,
    this.authUser,
    required this.walletAddress,
    required this.nonce,
    required this.message,
    required this.createdAt,
    required this.expiresAt,
    this.usedAt,
  });

  factory PayoutWalletLinkChallenge({
    _is.UuidValue? id,
    required _is.UuidValue authUserId,
    _iacs.AuthUser? authUser,
    required String walletAddress,
    required String nonce,
    required String message,
    required DateTime createdAt,
    required DateTime expiresAt,
    DateTime? usedAt,
  }) = _PayoutWalletLinkChallengeImpl;

  factory PayoutWalletLinkChallenge.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PayoutWalletLinkChallenge(
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
      nonce: jsonSerialization['nonce'] as String,
      message: jsonSerialization['message'] as String,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      expiresAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      usedAt: jsonSerialization['usedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['usedAt']),
    );
  }

  static final t = PayoutWalletLinkChallengeTable();

  static const db = PayoutWalletLinkChallengeRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue authUserId;

  _iacs.AuthUser? authUser;

  String walletAddress;

  String nonce;

  String message;

  DateTime createdAt;

  DateTime expiresAt;

  DateTime? usedAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [PayoutWalletLinkChallenge]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PayoutWalletLinkChallenge copyWith({
    _is.UuidValue? id,
    _is.UuidValue? authUserId,
    _iacs.AuthUser? authUser,
    String? walletAddress,
    String? nonce,
    String? message,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? usedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PayoutWalletLinkChallenge',
      if (id != null) 'id': id?.toJson(),
      'authUserId': authUserId.toJson(),
      if (authUser != null) 'authUser': authUser?.toJson(),
      'walletAddress': walletAddress,
      'nonce': nonce,
      'message': message,
      'createdAt': createdAt.toJson(),
      'expiresAt': expiresAt.toJson(),
      if (usedAt != null) 'usedAt': usedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static PayoutWalletLinkChallengeInclude include({
    _iacs.AuthUserInclude? authUser,
  }) {
    return PayoutWalletLinkChallengeInclude._(authUser: authUser);
  }

  static PayoutWalletLinkChallengeIncludeList includeList({
    _is.WhereExpressionBuilder<PayoutWalletLinkChallengeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PayoutWalletLinkChallengeTable>? orderBy,
    _is.OrderByListBuilder<PayoutWalletLinkChallengeTable>? orderByList,
    PayoutWalletLinkChallengeInclude? include,
  }) {
    return PayoutWalletLinkChallengeIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PayoutWalletLinkChallenge.t),
      orderByList: orderByList?.call(PayoutWalletLinkChallenge.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PayoutWalletLinkChallengeImpl extends PayoutWalletLinkChallenge {
  _PayoutWalletLinkChallengeImpl({
    _is.UuidValue? id,
    required _is.UuidValue authUserId,
    _iacs.AuthUser? authUser,
    required String walletAddress,
    required String nonce,
    required String message,
    required DateTime createdAt,
    required DateTime expiresAt,
    DateTime? usedAt,
  }) : super._(
         id: id,
         authUserId: authUserId,
         authUser: authUser,
         walletAddress: walletAddress,
         nonce: nonce,
         message: message,
         createdAt: createdAt,
         expiresAt: expiresAt,
         usedAt: usedAt,
       );

  /// Returns a shallow copy of this [PayoutWalletLinkChallenge]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PayoutWalletLinkChallenge copyWith({
    Object? id = _Undefined,
    _is.UuidValue? authUserId,
    Object? authUser = _Undefined,
    String? walletAddress,
    String? nonce,
    String? message,
    DateTime? createdAt,
    DateTime? expiresAt,
    Object? usedAt = _Undefined,
  }) {
    return PayoutWalletLinkChallenge(
      id: id is _is.UuidValue? ? id : this.id,
      authUserId: authUserId ?? this.authUserId,
      authUser: authUser is _iacs.AuthUser?
          ? authUser
          : this.authUser?.copyWith(),
      walletAddress: walletAddress ?? this.walletAddress,
      nonce: nonce ?? this.nonce,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      usedAt: usedAt is DateTime? ? usedAt : this.usedAt,
    );
  }
}

class PayoutWalletLinkChallengeUpdateTable
    extends _is.UpdateTable<PayoutWalletLinkChallengeTable> {
  PayoutWalletLinkChallengeUpdateTable(super.table);

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

  _is.ColumnValue<String, String> nonce(String value) => _is.ColumnValue(
    table.nonce,
    value,
  );

  _is.ColumnValue<String, String> message(String value) => _is.ColumnValue(
    table.message,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> expiresAt(DateTime value) =>
      _is.ColumnValue(
        table.expiresAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> usedAt(DateTime? value) =>
      _is.ColumnValue(
        table.usedAt,
        value,
      );
}

class PayoutWalletLinkChallengeTable extends _is.Table<_is.UuidValue?> {
  PayoutWalletLinkChallengeTable({super.tableRelation})
    : super(tableName: 'verily_payout_wallet_link_challenge') {
    updateTable = PayoutWalletLinkChallengeUpdateTable(this);
    authUserId = _is.ColumnUuid(
      'authUserId',
      this,
    );
    walletAddress = _is.ColumnString(
      'walletAddress',
      this,
    );
    nonce = _is.ColumnString(
      'nonce',
      this,
    );
    message = _is.ColumnString(
      'message',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    expiresAt = _is.ColumnDateTime(
      'expiresAt',
      this,
    );
    usedAt = _is.ColumnDateTime(
      'usedAt',
      this,
    );
  }

  late final PayoutWalletLinkChallengeUpdateTable updateTable;

  late final _is.ColumnUuid authUserId;

  _iacs.AuthUserTable? _authUser;

  late final _is.ColumnString walletAddress;

  late final _is.ColumnString nonce;

  late final _is.ColumnString message;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime expiresAt;

  late final _is.ColumnDateTime usedAt;

  _iacs.AuthUserTable get authUser {
    if (_authUser != null) return _authUser!;
    _authUser = _is.createRelationTable(
      relationFieldName: 'authUser',
      field: PayoutWalletLinkChallenge.t.authUserId,
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
    nonce,
    message,
    createdAt,
    expiresAt,
    usedAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'authUser') {
      return authUser;
    }
    return null;
  }
}

class PayoutWalletLinkChallengeInclude extends _is.IncludeObject {
  PayoutWalletLinkChallengeInclude._({_iacs.AuthUserInclude? authUser}) {
    _authUser = authUser;
  }

  _iacs.AuthUserInclude? _authUser;

  @override
  Map<String, _is.Include?> get includes => {'authUser': _authUser};

  @override
  _is.Table<_is.UuidValue?> get table => PayoutWalletLinkChallenge.t;
}

class PayoutWalletLinkChallengeIncludeList extends _is.IncludeList {
  PayoutWalletLinkChallengeIncludeList._({
    _is.WhereExpressionBuilder<PayoutWalletLinkChallengeTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PayoutWalletLinkChallenge.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => PayoutWalletLinkChallenge.t;
}

class PayoutWalletLinkChallengeRepository {
  const PayoutWalletLinkChallengeRepository._();

  final attachRow = const PayoutWalletLinkChallengeAttachRowRepository._();

  /// Returns a list of [PayoutWalletLinkChallenge]s matching the given query parameters.
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
  Future<List<PayoutWalletLinkChallenge>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PayoutWalletLinkChallengeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PayoutWalletLinkChallengeTable>? orderBy,
    _is.OrderByListBuilder<PayoutWalletLinkChallengeTable>? orderByList,
    _is.Transaction? transaction,
    PayoutWalletLinkChallengeInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<PayoutWalletLinkChallenge>(
      where: where?.call(PayoutWalletLinkChallenge.t),
      orderBy: orderBy?.call(PayoutWalletLinkChallenge.t),
      orderByList: orderByList?.call(PayoutWalletLinkChallenge.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [PayoutWalletLinkChallenge] matching the given query parameters.
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
  Future<PayoutWalletLinkChallenge?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PayoutWalletLinkChallengeTable>? where,
    int? offset,
    _is.OrderByBuilder<PayoutWalletLinkChallengeTable>? orderBy,
    _is.OrderByListBuilder<PayoutWalletLinkChallengeTable>? orderByList,
    _is.Transaction? transaction,
    PayoutWalletLinkChallengeInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<PayoutWalletLinkChallenge>(
      where: where?.call(PayoutWalletLinkChallenge.t),
      orderBy: orderBy?.call(PayoutWalletLinkChallenge.t),
      orderByList: orderByList?.call(PayoutWalletLinkChallenge.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [PayoutWalletLinkChallenge] by its [id] or null if no such row exists.
  Future<PayoutWalletLinkChallenge?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    PayoutWalletLinkChallengeInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<PayoutWalletLinkChallenge>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [PayoutWalletLinkChallenge]s in the list and returns the inserted rows.
  ///
  /// The returned [PayoutWalletLinkChallenge]s will have their `id` fields set.
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
  Future<List<PayoutWalletLinkChallenge>> insert(
    _is.DatabaseSession session,
    List<PayoutWalletLinkChallenge> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<PayoutWalletLinkChallenge>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [PayoutWalletLinkChallenge] and returns the inserted row.
  ///
  /// The returned [PayoutWalletLinkChallenge] will have its `id` field set.
  Future<PayoutWalletLinkChallenge> insertRow(
    _is.DatabaseSession session,
    PayoutWalletLinkChallenge row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<PayoutWalletLinkChallenge>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [PayoutWalletLinkChallenge]s in the list and returns the resulting rows.
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
  /// The returned [PayoutWalletLinkChallenge]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PayoutWalletLinkChallenge>> upsert(
    _is.DatabaseSession session,
    List<PayoutWalletLinkChallenge> rows, {
    required _is.ColumnSelections<PayoutWalletLinkChallengeTable>
    conflictColumns,
    _is.ColumnSelections<PayoutWalletLinkChallengeTable>? updateColumns,
    _is.WhereExpressionBuilder<PayoutWalletLinkChallengeTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<PayoutWalletLinkChallenge>(
      rows,
      conflictColumns: conflictColumns(PayoutWalletLinkChallenge.t),
      updateColumns: updateColumns?.call(PayoutWalletLinkChallenge.t),
      updateWhere: updateWhere?.call(PayoutWalletLinkChallenge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [PayoutWalletLinkChallenge] and returns the resulting row.
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
  /// The returned [PayoutWalletLinkChallenge] will have its `id` field set.
  Future<PayoutWalletLinkChallenge?> upsertRow(
    _is.DatabaseSession session,
    PayoutWalletLinkChallenge row, {
    required _is.ColumnSelections<PayoutWalletLinkChallengeTable>
    conflictColumns,
    _is.ColumnSelections<PayoutWalletLinkChallengeTable>? updateColumns,
    _is.WhereExpressionBuilder<PayoutWalletLinkChallengeTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<PayoutWalletLinkChallenge>(
      row,
      conflictColumns: conflictColumns(PayoutWalletLinkChallenge.t),
      updateColumns: updateColumns?.call(PayoutWalletLinkChallenge.t),
      updateWhere: updateWhere?.call(PayoutWalletLinkChallenge.t),
      transaction: transaction,
    );
  }

  /// Updates all [PayoutWalletLinkChallenge]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PayoutWalletLinkChallenge>> update(
    _is.DatabaseSession session,
    List<PayoutWalletLinkChallenge> rows, {
    _is.ColumnSelections<PayoutWalletLinkChallengeTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<PayoutWalletLinkChallenge>(
      rows,
      columns: columns?.call(PayoutWalletLinkChallenge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [PayoutWalletLinkChallenge]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PayoutWalletLinkChallenge> updateRow(
    _is.DatabaseSession session,
    PayoutWalletLinkChallenge row, {
    _is.ColumnSelections<PayoutWalletLinkChallengeTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<PayoutWalletLinkChallenge>(
      row,
      columns: columns?.call(PayoutWalletLinkChallenge.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PayoutWalletLinkChallenge] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<PayoutWalletLinkChallenge?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<PayoutWalletLinkChallengeUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<PayoutWalletLinkChallenge>(
      id,
      columnValues: columnValues(PayoutWalletLinkChallenge.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [PayoutWalletLinkChallenge]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PayoutWalletLinkChallenge>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<PayoutWalletLinkChallengeUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<PayoutWalletLinkChallengeTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PayoutWalletLinkChallengeTable>? orderBy,
    _is.OrderByListBuilder<PayoutWalletLinkChallengeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<PayoutWalletLinkChallenge>(
      columnValues: columnValues(PayoutWalletLinkChallenge.t.updateTable),
      where: where(PayoutWalletLinkChallenge.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PayoutWalletLinkChallenge.t),
      orderByList: orderByList?.call(PayoutWalletLinkChallenge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [PayoutWalletLinkChallenge]s in the list and returns the deleted rows.
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
  Future<List<PayoutWalletLinkChallenge>> delete(
    _is.DatabaseSession session,
    List<PayoutWalletLinkChallenge> rows, {
    _is.OrderByBuilder<PayoutWalletLinkChallengeTable>? orderBy,
    _is.OrderByListBuilder<PayoutWalletLinkChallengeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<PayoutWalletLinkChallenge>(
      rows,
      orderBy: orderBy?.call(PayoutWalletLinkChallenge.t),
      orderByList: orderByList?.call(PayoutWalletLinkChallenge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [PayoutWalletLinkChallenge].
  Future<PayoutWalletLinkChallenge> deleteRow(
    _is.DatabaseSession session,
    PayoutWalletLinkChallenge row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PayoutWalletLinkChallenge>(
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
  Future<List<PayoutWalletLinkChallenge>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PayoutWalletLinkChallengeTable> where,
    _is.OrderByBuilder<PayoutWalletLinkChallengeTable>? orderBy,
    _is.OrderByListBuilder<PayoutWalletLinkChallengeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<PayoutWalletLinkChallenge>(
      where: where(PayoutWalletLinkChallenge.t),
      orderBy: orderBy?.call(PayoutWalletLinkChallenge.t),
      orderByList: orderByList?.call(PayoutWalletLinkChallenge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PayoutWalletLinkChallengeTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<PayoutWalletLinkChallenge>(
      where: where?.call(PayoutWalletLinkChallenge.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [PayoutWalletLinkChallenge] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PayoutWalletLinkChallengeTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<PayoutWalletLinkChallenge>(
      where: where(PayoutWalletLinkChallenge.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class PayoutWalletLinkChallengeAttachRowRepository {
  const PayoutWalletLinkChallengeAttachRowRepository._();

  /// Creates a relation between the given [PayoutWalletLinkChallenge] and [AuthUser]
  /// by setting the [PayoutWalletLinkChallenge]'s foreign key `authUserId` to refer to the [AuthUser].
  Future<void> authUser(
    _is.DatabaseSession session,
    PayoutWalletLinkChallenge payoutWalletLinkChallenge,
    _iacs.AuthUser authUser, {
    _is.Transaction? transaction,
  }) async {
    if (payoutWalletLinkChallenge.id == null) {
      throw ArgumentError.notNull('payoutWalletLinkChallenge.id');
    }
    if (authUser.id == null) {
      throw ArgumentError.notNull('authUser.id');
    }

    var $payoutWalletLinkChallenge = payoutWalletLinkChallenge.copyWith(
      authUserId: authUser.id,
    );
    await session.db.updateRow<PayoutWalletLinkChallenge>(
      $payoutWalletLinkChallenge,
      columns: [PayoutWalletLinkChallenge.t.authUserId],
      transaction: transaction,
    );
  }
}
