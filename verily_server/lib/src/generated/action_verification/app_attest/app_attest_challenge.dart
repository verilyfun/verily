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

/// A single-use challenge an iPhone attests its App Attest key against, so the
/// attestation proves it was made for this registration.
abstract class AppAttestChallenge
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  AppAttestChallenge._({
    this.id,
    required this.authUserId,
    this.authUser,
    required this.nonce,
    required this.expiresAt,
    this.usedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AppAttestChallenge({
    _is.UuidValue? id,
    required _is.UuidValue authUserId,
    _iacs.AuthUser? authUser,
    required String nonce,
    required DateTime expiresAt,
    DateTime? usedAt,
    DateTime? createdAt,
  }) = _AppAttestChallengeImpl;

  factory AppAttestChallenge.fromJson(Map<String, dynamic> jsonSerialization) {
    return AppAttestChallenge(
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
      nonce: jsonSerialization['nonce'] as String,
      expiresAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      usedAt: jsonSerialization['usedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['usedAt']),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = AppAttestChallengeTable();

  static const db = AppAttestChallengeRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue authUserId;

  _iacs.AuthUser? authUser;

  /// 32 random bytes, unpadded base64url. The phone attests with
  /// `clientDataHash = SHA-256(these bytes)`.
  String nonce;

  DateTime expiresAt;

  DateTime? usedAt;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [AppAttestChallenge]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AppAttestChallenge copyWith({
    _is.UuidValue? id,
    _is.UuidValue? authUserId,
    _iacs.AuthUser? authUser,
    String? nonce,
    DateTime? expiresAt,
    DateTime? usedAt,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AppAttestChallenge',
      if (id != null) 'id': id?.toJson(),
      'authUserId': authUserId.toJson(),
      if (authUser != null) 'authUser': authUser?.toJson(),
      'nonce': nonce,
      'expiresAt': expiresAt.toJson(),
      if (usedAt != null) 'usedAt': usedAt?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static AppAttestChallengeInclude include({_iacs.AuthUserInclude? authUser}) {
    return AppAttestChallengeInclude._(authUser: authUser);
  }

  static AppAttestChallengeIncludeList includeList({
    _is.WhereExpressionBuilder<AppAttestChallengeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AppAttestChallengeTable>? orderBy,
    _is.OrderByListBuilder<AppAttestChallengeTable>? orderByList,
    AppAttestChallengeInclude? include,
  }) {
    return AppAttestChallengeIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AppAttestChallenge.t),
      orderByList: orderByList?.call(AppAttestChallenge.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AppAttestChallengeImpl extends AppAttestChallenge {
  _AppAttestChallengeImpl({
    _is.UuidValue? id,
    required _is.UuidValue authUserId,
    _iacs.AuthUser? authUser,
    required String nonce,
    required DateTime expiresAt,
    DateTime? usedAt,
    DateTime? createdAt,
  }) : super._(
         id: id,
         authUserId: authUserId,
         authUser: authUser,
         nonce: nonce,
         expiresAt: expiresAt,
         usedAt: usedAt,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [AppAttestChallenge]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AppAttestChallenge copyWith({
    Object? id = _Undefined,
    _is.UuidValue? authUserId,
    Object? authUser = _Undefined,
    String? nonce,
    DateTime? expiresAt,
    Object? usedAt = _Undefined,
    DateTime? createdAt,
  }) {
    return AppAttestChallenge(
      id: id is _is.UuidValue? ? id : this.id,
      authUserId: authUserId ?? this.authUserId,
      authUser: authUser is _iacs.AuthUser?
          ? authUser
          : this.authUser?.copyWith(),
      nonce: nonce ?? this.nonce,
      expiresAt: expiresAt ?? this.expiresAt,
      usedAt: usedAt is DateTime? ? usedAt : this.usedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AppAttestChallengeUpdateTable
    extends _is.UpdateTable<AppAttestChallengeTable> {
  AppAttestChallengeUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> authUserId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.authUserId,
    value,
  );

  _is.ColumnValue<String, String> nonce(String value) => _is.ColumnValue(
    table.nonce,
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

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class AppAttestChallengeTable extends _is.Table<_is.UuidValue?> {
  AppAttestChallengeTable({super.tableRelation})
    : super(tableName: 'verily_app_attest_challenge') {
    updateTable = AppAttestChallengeUpdateTable(this);
    authUserId = _is.ColumnUuid(
      'authUserId',
      this,
    );
    nonce = _is.ColumnString(
      'nonce',
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
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final AppAttestChallengeUpdateTable updateTable;

  late final _is.ColumnUuid authUserId;

  _iacs.AuthUserTable? _authUser;

  /// 32 random bytes, unpadded base64url. The phone attests with
  /// `clientDataHash = SHA-256(these bytes)`.
  late final _is.ColumnString nonce;

  late final _is.ColumnDateTime expiresAt;

  late final _is.ColumnDateTime usedAt;

  late final _is.ColumnDateTime createdAt;

  _iacs.AuthUserTable get authUser {
    if (_authUser != null) return _authUser!;
    _authUser = _is.createRelationTable(
      relationFieldName: 'authUser',
      field: AppAttestChallenge.t.authUserId,
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
    nonce,
    expiresAt,
    usedAt,
    createdAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'authUser') {
      return authUser;
    }
    return null;
  }
}

class AppAttestChallengeInclude extends _is.IncludeObject {
  AppAttestChallengeInclude._({_iacs.AuthUserInclude? authUser}) {
    _authUser = authUser;
  }

  _iacs.AuthUserInclude? _authUser;

  @override
  Map<String, _is.Include?> get includes => {'authUser': _authUser};

  @override
  _is.Table<_is.UuidValue?> get table => AppAttestChallenge.t;
}

class AppAttestChallengeIncludeList extends _is.IncludeList {
  AppAttestChallengeIncludeList._({
    _is.WhereExpressionBuilder<AppAttestChallengeTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AppAttestChallenge.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => AppAttestChallenge.t;
}

class AppAttestChallengeRepository {
  const AppAttestChallengeRepository._();

  final attachRow = const AppAttestChallengeAttachRowRepository._();

  /// Returns a list of [AppAttestChallenge]s matching the given query parameters.
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
  Future<List<AppAttestChallenge>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AppAttestChallengeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AppAttestChallengeTable>? orderBy,
    _is.OrderByListBuilder<AppAttestChallengeTable>? orderByList,
    _is.Transaction? transaction,
    AppAttestChallengeInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<AppAttestChallenge>(
      where: where?.call(AppAttestChallenge.t),
      orderBy: orderBy?.call(AppAttestChallenge.t),
      orderByList: orderByList?.call(AppAttestChallenge.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [AppAttestChallenge] matching the given query parameters.
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
  Future<AppAttestChallenge?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AppAttestChallengeTable>? where,
    int? offset,
    _is.OrderByBuilder<AppAttestChallengeTable>? orderBy,
    _is.OrderByListBuilder<AppAttestChallengeTable>? orderByList,
    _is.Transaction? transaction,
    AppAttestChallengeInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<AppAttestChallenge>(
      where: where?.call(AppAttestChallenge.t),
      orderBy: orderBy?.call(AppAttestChallenge.t),
      orderByList: orderByList?.call(AppAttestChallenge.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [AppAttestChallenge] by its [id] or null if no such row exists.
  Future<AppAttestChallenge?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    AppAttestChallengeInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<AppAttestChallenge>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [AppAttestChallenge]s in the list and returns the inserted rows.
  ///
  /// The returned [AppAttestChallenge]s will have their `id` fields set.
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
  Future<List<AppAttestChallenge>> insert(
    _is.DatabaseSession session,
    List<AppAttestChallenge> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<AppAttestChallenge>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [AppAttestChallenge] and returns the inserted row.
  ///
  /// The returned [AppAttestChallenge] will have its `id` field set.
  Future<AppAttestChallenge> insertRow(
    _is.DatabaseSession session,
    AppAttestChallenge row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<AppAttestChallenge>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [AppAttestChallenge]s in the list and returns the resulting rows.
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
  /// The returned [AppAttestChallenge]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AppAttestChallenge>> upsert(
    _is.DatabaseSession session,
    List<AppAttestChallenge> rows, {
    required _is.ColumnSelections<AppAttestChallengeTable> conflictColumns,
    _is.ColumnSelections<AppAttestChallengeTable>? updateColumns,
    _is.WhereExpressionBuilder<AppAttestChallengeTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<AppAttestChallenge>(
      rows,
      conflictColumns: conflictColumns(AppAttestChallenge.t),
      updateColumns: updateColumns?.call(AppAttestChallenge.t),
      updateWhere: updateWhere?.call(AppAttestChallenge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [AppAttestChallenge] and returns the resulting row.
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
  /// The returned [AppAttestChallenge] will have its `id` field set.
  Future<AppAttestChallenge?> upsertRow(
    _is.DatabaseSession session,
    AppAttestChallenge row, {
    required _is.ColumnSelections<AppAttestChallengeTable> conflictColumns,
    _is.ColumnSelections<AppAttestChallengeTable>? updateColumns,
    _is.WhereExpressionBuilder<AppAttestChallengeTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<AppAttestChallenge>(
      row,
      conflictColumns: conflictColumns(AppAttestChallenge.t),
      updateColumns: updateColumns?.call(AppAttestChallenge.t),
      updateWhere: updateWhere?.call(AppAttestChallenge.t),
      transaction: transaction,
    );
  }

  /// Updates all [AppAttestChallenge]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AppAttestChallenge>> update(
    _is.DatabaseSession session,
    List<AppAttestChallenge> rows, {
    _is.ColumnSelections<AppAttestChallengeTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<AppAttestChallenge>(
      rows,
      columns: columns?.call(AppAttestChallenge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [AppAttestChallenge]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AppAttestChallenge> updateRow(
    _is.DatabaseSession session,
    AppAttestChallenge row, {
    _is.ColumnSelections<AppAttestChallengeTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<AppAttestChallenge>(
      row,
      columns: columns?.call(AppAttestChallenge.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AppAttestChallenge] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AppAttestChallenge?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<AppAttestChallengeUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<AppAttestChallenge>(
      id,
      columnValues: columnValues(AppAttestChallenge.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AppAttestChallenge]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AppAttestChallenge>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<AppAttestChallengeUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<AppAttestChallengeTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AppAttestChallengeTable>? orderBy,
    _is.OrderByListBuilder<AppAttestChallengeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<AppAttestChallenge>(
      columnValues: columnValues(AppAttestChallenge.t.updateTable),
      where: where(AppAttestChallenge.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AppAttestChallenge.t),
      orderByList: orderByList?.call(AppAttestChallenge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [AppAttestChallenge]s in the list and returns the deleted rows.
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
  Future<List<AppAttestChallenge>> delete(
    _is.DatabaseSession session,
    List<AppAttestChallenge> rows, {
    _is.OrderByBuilder<AppAttestChallengeTable>? orderBy,
    _is.OrderByListBuilder<AppAttestChallengeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<AppAttestChallenge>(
      rows,
      orderBy: orderBy?.call(AppAttestChallenge.t),
      orderByList: orderByList?.call(AppAttestChallenge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [AppAttestChallenge].
  Future<AppAttestChallenge> deleteRow(
    _is.DatabaseSession session,
    AppAttestChallenge row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AppAttestChallenge>(
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
  Future<List<AppAttestChallenge>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AppAttestChallengeTable> where,
    _is.OrderByBuilder<AppAttestChallengeTable>? orderBy,
    _is.OrderByListBuilder<AppAttestChallengeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<AppAttestChallenge>(
      where: where(AppAttestChallenge.t),
      orderBy: orderBy?.call(AppAttestChallenge.t),
      orderByList: orderByList?.call(AppAttestChallenge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AppAttestChallengeTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<AppAttestChallenge>(
      where: where?.call(AppAttestChallenge.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [AppAttestChallenge] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AppAttestChallengeTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<AppAttestChallenge>(
      where: where(AppAttestChallenge.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class AppAttestChallengeAttachRowRepository {
  const AppAttestChallengeAttachRowRepository._();

  /// Creates a relation between the given [AppAttestChallenge] and [AuthUser]
  /// by setting the [AppAttestChallenge]'s foreign key `authUserId` to refer to the [AuthUser].
  Future<void> authUser(
    _is.DatabaseSession session,
    AppAttestChallenge appAttestChallenge,
    _iacs.AuthUser authUser, {
    _is.Transaction? transaction,
  }) async {
    if (appAttestChallenge.id == null) {
      throw ArgumentError.notNull('appAttestChallenge.id');
    }
    if (authUser.id == null) {
      throw ArgumentError.notNull('authUser.id');
    }

    var $appAttestChallenge = appAttestChallenge.copyWith(
      authUserId: authUser.id,
    );
    await session.db.updateRow<AppAttestChallenge>(
      $appAttestChallenge,
      columns: [AppAttestChallenge.t.authUserId],
      transaction: transaction,
    );
  }
}
