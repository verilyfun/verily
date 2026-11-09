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

/// A one-time, five-minute code from a deep-link approval, bound to the App,
/// the account, the exact redirect URI, and the App's state. Only its hash is
/// stored.
abstract class VerilyAppLinkCode
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  VerilyAppLinkCode._({
    this.id,
    required this.appId,
    required this.authUserId,
    this.authUser,
    required this.codeHash,
    required this.redirectUri,
    this.state,
    required this.expiresAt,
    this.usedAt,
    required this.createdAt,
  });

  factory VerilyAppLinkCode({
    _is.UuidValue? id,
    required _is.UuidValue appId,
    required _is.UuidValue authUserId,
    _iacs.AuthUser? authUser,
    required String codeHash,
    required String redirectUri,
    String? state,
    required DateTime expiresAt,
    DateTime? usedAt,
    required DateTime createdAt,
  }) = _VerilyAppLinkCodeImpl;

  factory VerilyAppLinkCode.fromJson(Map<String, dynamic> jsonSerialization) {
    return VerilyAppLinkCode(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      appId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['appId']),
      authUserId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['authUserId'],
      ),
      authUser: jsonSerialization['authUser'] == null
          ? null
          : _itf691yl.Protocol().deserialize<_iacs.AuthUser>(
              jsonSerialization['authUser'],
            ),
      codeHash: jsonSerialization['codeHash'] as String,
      redirectUri: jsonSerialization['redirectUri'] as String,
      state: jsonSerialization['state'] as String?,
      expiresAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      usedAt: jsonSerialization['usedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['usedAt']),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = VerilyAppLinkCodeTable();

  static const db = VerilyAppLinkCodeRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue appId;

  _is.UuidValue authUserId;

  _iacs.AuthUser? authUser;

  String codeHash;

  String redirectUri;

  String? state;

  DateTime expiresAt;

  DateTime? usedAt;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [VerilyAppLinkCode]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  VerilyAppLinkCode copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? appId,
    _is.UuidValue? authUserId,
    _iacs.AuthUser? authUser = const _UndefinedVerilyAppLinkCode$authUser(),
    String? codeHash,
    String? redirectUri,
    String? state,
    DateTime? expiresAt,
    DateTime? usedAt = const _is.$UndefinedDateTime(),
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'VerilyAppLinkCode',
      if (id != null) 'id': id?.toJson(),
      'appId': appId.toJson(),
      'authUserId': authUserId.toJson(),
      if (authUser != null) 'authUser': authUser?.toJson(),
      'codeHash': codeHash,
      'redirectUri': redirectUri,
      if (state != null) 'state': state,
      'expiresAt': expiresAt.toJson(),
      if (usedAt != null) 'usedAt': usedAt?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static VerilyAppLinkCodeInclude include({_iacs.AuthUserInclude? authUser}) {
    return VerilyAppLinkCodeInclude._(authUser: authUser);
  }

  static VerilyAppLinkCodeIncludeList includeList({
    _is.WhereExpressionBuilder<VerilyAppLinkCodeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VerilyAppLinkCodeTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppLinkCodeTable>? orderByList,
    VerilyAppLinkCodeInclude? include,
  }) {
    return VerilyAppLinkCodeIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(VerilyAppLinkCode.t),
      orderByList: orderByList?.call(VerilyAppLinkCode.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedVerilyAppLinkCode$authUser extends _is.UndefinedSentinel
    implements _iacs.AuthUser {
  const _UndefinedVerilyAppLinkCode$authUser();
}

class _VerilyAppLinkCodeImpl extends VerilyAppLinkCode {
  _VerilyAppLinkCodeImpl({
    _is.UuidValue? id,
    required _is.UuidValue appId,
    required _is.UuidValue authUserId,
    _iacs.AuthUser? authUser,
    required String codeHash,
    required String redirectUri,
    String? state,
    required DateTime expiresAt,
    DateTime? usedAt,
    required DateTime createdAt,
  }) : super._(
         id: id,
         appId: appId,
         authUserId: authUserId,
         authUser: authUser,
         codeHash: codeHash,
         redirectUri: redirectUri,
         state: state,
         expiresAt: expiresAt,
         usedAt: usedAt,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [VerilyAppLinkCode]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  VerilyAppLinkCode copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? appId,
    _is.UuidValue? authUserId,
    _iacs.AuthUser? authUser = const _UndefinedVerilyAppLinkCode$authUser(),
    String? codeHash,
    String? redirectUri,
    Object? state = _Undefined,
    DateTime? expiresAt,
    DateTime? usedAt = const _is.$UndefinedDateTime(),
    DateTime? createdAt,
  }) {
    return VerilyAppLinkCode(
      id: id is _is.UndefinedSentinel ? this.id : id,
      appId: appId ?? this.appId,
      authUserId: authUserId ?? this.authUserId,
      authUser: authUser is _is.UndefinedSentinel
          ? this.authUser?.copyWith()
          : authUser,
      codeHash: codeHash ?? this.codeHash,
      redirectUri: redirectUri ?? this.redirectUri,
      state: state is String? ? state : this.state,
      expiresAt: expiresAt ?? this.expiresAt,
      usedAt: usedAt is _is.UndefinedSentinel ? this.usedAt : usedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class VerilyAppLinkCodeUpdateTable
    extends _is.UpdateTable<VerilyAppLinkCodeTable> {
  VerilyAppLinkCodeUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> appId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.appId,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> authUserId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.authUserId,
    value,
  );

  _is.ColumnValue<String, String> codeHash(String value) => _is.ColumnValue(
    table.codeHash,
    value,
  );

  _is.ColumnValue<String, String> redirectUri(String value) => _is.ColumnValue(
    table.redirectUri,
    value,
  );

  _is.ColumnValue<String, String> state(String? value) => _is.ColumnValue(
    table.state,
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

class VerilyAppLinkCodeTable extends _is.Table<_is.UuidValue?> {
  VerilyAppLinkCodeTable({super.tableRelation})
    : super(tableName: 'verily_app_link_code') {
    updateTable = VerilyAppLinkCodeUpdateTable(this);
    appId = _is.ColumnUuid(
      'appId',
      this,
    );
    authUserId = _is.ColumnUuid(
      'authUserId',
      this,
    );
    codeHash = _is.ColumnString(
      'codeHash',
      this,
    );
    redirectUri = _is.ColumnString(
      'redirectUri',
      this,
    );
    state = _is.ColumnString(
      'state',
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

  late final VerilyAppLinkCodeUpdateTable updateTable;

  late final _is.ColumnUuid appId;

  late final _is.ColumnUuid authUserId;

  _iacs.AuthUserTable? _authUser;

  late final _is.ColumnString codeHash;

  late final _is.ColumnString redirectUri;

  late final _is.ColumnString state;

  late final _is.ColumnDateTime expiresAt;

  late final _is.ColumnDateTime usedAt;

  late final _is.ColumnDateTime createdAt;

  _iacs.AuthUserTable get authUser {
    if (_authUser != null) return _authUser!;
    _authUser = _is.createRelationTable(
      relationFieldName: 'authUser',
      field: VerilyAppLinkCode.t.authUserId,
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
    appId,
    authUserId,
    codeHash,
    redirectUri,
    state,
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

class VerilyAppLinkCodeInclude extends _is.IncludeObject {
  VerilyAppLinkCodeInclude._({_iacs.AuthUserInclude? authUser}) {
    _authUser = authUser;
  }

  _iacs.AuthUserInclude? _authUser;

  @override
  Map<String, _is.Include?> get includes => {'authUser': _authUser};

  @override
  _is.Table<_is.UuidValue?> get table => VerilyAppLinkCode.t;
}

class VerilyAppLinkCodeIncludeList extends _is.IncludeList {
  VerilyAppLinkCodeIncludeList._({
    _is.WhereExpressionBuilder<VerilyAppLinkCodeTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(VerilyAppLinkCode.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => VerilyAppLinkCode.t;
}

class VerilyAppLinkCodeRepository {
  const VerilyAppLinkCodeRepository._();

  final attachRow = const VerilyAppLinkCodeAttachRowRepository._();

  /// Returns a list of [VerilyAppLinkCode]s matching the given query parameters.
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
  Future<List<VerilyAppLinkCode>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VerilyAppLinkCodeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VerilyAppLinkCodeTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppLinkCodeTable>? orderByList,
    _is.Transaction? transaction,
    VerilyAppLinkCodeInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<VerilyAppLinkCode>(
      where: where?.call(VerilyAppLinkCode.t),
      orderBy: orderBy?.call(VerilyAppLinkCode.t),
      orderByList: orderByList?.call(VerilyAppLinkCode.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [VerilyAppLinkCode]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `VerilyAppLinkCode.t`.
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
  _ida.Stream<List<VerilyAppLinkCode>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VerilyAppLinkCodeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VerilyAppLinkCodeTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppLinkCodeTable>? orderByList,
    VerilyAppLinkCodeInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<VerilyAppLinkCode>(
      where: where?.call(VerilyAppLinkCode.t),
      orderBy: orderBy?.call(VerilyAppLinkCode.t),
      orderByList: orderByList?.call(VerilyAppLinkCode.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [VerilyAppLinkCode] matching the given query parameters.
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
  Future<VerilyAppLinkCode?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VerilyAppLinkCodeTable>? where,
    int? offset,
    _is.OrderByBuilder<VerilyAppLinkCodeTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppLinkCodeTable>? orderByList,
    _is.Transaction? transaction,
    VerilyAppLinkCodeInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<VerilyAppLinkCode>(
      where: where?.call(VerilyAppLinkCode.t),
      orderBy: orderBy?.call(VerilyAppLinkCode.t),
      orderByList: orderByList?.call(VerilyAppLinkCode.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [VerilyAppLinkCode] by its [id] or null if no such row exists.
  Future<VerilyAppLinkCode?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    VerilyAppLinkCodeInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<VerilyAppLinkCode>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [VerilyAppLinkCode]s in the list and returns the inserted rows.
  ///
  /// The returned [VerilyAppLinkCode]s will have their `id` fields set.
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
  Future<List<VerilyAppLinkCode>> insert(
    _is.DatabaseSession session,
    List<VerilyAppLinkCode> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<VerilyAppLinkCode>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [VerilyAppLinkCode] and returns the inserted row.
  ///
  /// The returned [VerilyAppLinkCode] will have its `id` field set.
  Future<VerilyAppLinkCode> insertRow(
    _is.DatabaseSession session,
    VerilyAppLinkCode row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<VerilyAppLinkCode>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [VerilyAppLinkCode]s in the list and returns the resulting rows.
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
  /// The returned [VerilyAppLinkCode]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<VerilyAppLinkCode>> upsert(
    _is.DatabaseSession session,
    List<VerilyAppLinkCode> rows, {
    required _is.ColumnSelections<VerilyAppLinkCodeTable> conflictColumns,
    _is.ColumnSelections<VerilyAppLinkCodeTable>? updateColumns,
    _is.WhereExpressionBuilder<VerilyAppLinkCodeTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<VerilyAppLinkCode>(
      rows,
      conflictColumns: conflictColumns(VerilyAppLinkCode.t),
      updateColumns: updateColumns?.call(VerilyAppLinkCode.t),
      updateWhere: updateWhere?.call(VerilyAppLinkCode.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [VerilyAppLinkCode] and returns the resulting row.
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
  /// The returned [VerilyAppLinkCode] will have its `id` field set.
  Future<VerilyAppLinkCode?> upsertRow(
    _is.DatabaseSession session,
    VerilyAppLinkCode row, {
    required _is.ColumnSelections<VerilyAppLinkCodeTable> conflictColumns,
    _is.ColumnSelections<VerilyAppLinkCodeTable>? updateColumns,
    _is.WhereExpressionBuilder<VerilyAppLinkCodeTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<VerilyAppLinkCode>(
      row,
      conflictColumns: conflictColumns(VerilyAppLinkCode.t),
      updateColumns: updateColumns?.call(VerilyAppLinkCode.t),
      updateWhere: updateWhere?.call(VerilyAppLinkCode.t),
      transaction: transaction,
    );
  }

  /// Updates all [VerilyAppLinkCode]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<VerilyAppLinkCode>> update(
    _is.DatabaseSession session,
    List<VerilyAppLinkCode> rows, {
    _is.ColumnSelections<VerilyAppLinkCodeTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<VerilyAppLinkCode>(
      rows,
      columns: columns?.call(VerilyAppLinkCode.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [VerilyAppLinkCode]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<VerilyAppLinkCode> updateRow(
    _is.DatabaseSession session,
    VerilyAppLinkCode row, {
    _is.ColumnSelections<VerilyAppLinkCodeTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<VerilyAppLinkCode>(
      row,
      columns: columns?.call(VerilyAppLinkCode.t),
      transaction: transaction,
    );
  }

  /// Updates a single [VerilyAppLinkCode] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<VerilyAppLinkCode?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<VerilyAppLinkCodeUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<VerilyAppLinkCode>(
      id,
      columnValues: columnValues(VerilyAppLinkCode.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [VerilyAppLinkCode]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<VerilyAppLinkCode>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<VerilyAppLinkCodeUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<VerilyAppLinkCodeTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VerilyAppLinkCodeTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppLinkCodeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<VerilyAppLinkCode>(
      columnValues: columnValues(VerilyAppLinkCode.t.updateTable),
      where: where(VerilyAppLinkCode.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(VerilyAppLinkCode.t),
      orderByList: orderByList?.call(VerilyAppLinkCode.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [VerilyAppLinkCode]s in the list and returns the deleted rows.
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
  Future<List<VerilyAppLinkCode>> delete(
    _is.DatabaseSession session,
    List<VerilyAppLinkCode> rows, {
    _is.OrderByBuilder<VerilyAppLinkCodeTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppLinkCodeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<VerilyAppLinkCode>(
      rows,
      orderBy: orderBy?.call(VerilyAppLinkCode.t),
      orderByList: orderByList?.call(VerilyAppLinkCode.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [VerilyAppLinkCode].
  Future<VerilyAppLinkCode> deleteRow(
    _is.DatabaseSession session,
    VerilyAppLinkCode row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<VerilyAppLinkCode>(
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
  Future<List<VerilyAppLinkCode>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<VerilyAppLinkCodeTable> where,
    _is.OrderByBuilder<VerilyAppLinkCodeTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppLinkCodeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<VerilyAppLinkCode>(
      where: where(VerilyAppLinkCode.t),
      orderBy: orderBy?.call(VerilyAppLinkCode.t),
      orderByList: orderByList?.call(VerilyAppLinkCode.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VerilyAppLinkCodeTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<VerilyAppLinkCode>(
      where: where?.call(VerilyAppLinkCode.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [VerilyAppLinkCode] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<VerilyAppLinkCodeTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<VerilyAppLinkCode>(
      where: where(VerilyAppLinkCode.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class VerilyAppLinkCodeAttachRowRepository {
  const VerilyAppLinkCodeAttachRowRepository._();

  /// Creates a relation between the given [VerilyAppLinkCode] and [AuthUser]
  /// by setting the [VerilyAppLinkCode]'s foreign key `authUserId` to refer to the [AuthUser].
  Future<void> authUser(
    _is.DatabaseSession session,
    VerilyAppLinkCode verilyAppLinkCode,
    _iacs.AuthUser authUser, {
    _is.Transaction? transaction,
  }) async {
    if (verilyAppLinkCode.id == null) {
      throw ArgumentError.notNull('verilyAppLinkCode.id');
    }
    if (authUser.id == null) {
      throw ArgumentError.notNull('authUser.id');
    }

    var $verilyAppLinkCode = verilyAppLinkCode.copyWith(
      authUserId: authUser.id,
    );
    await session.db.updateRow<VerilyAppLinkCode>(
      $verilyAppLinkCode,
      columns: [VerilyAppLinkCode.t.authUserId],
      transaction: transaction,
    );
  }
}
