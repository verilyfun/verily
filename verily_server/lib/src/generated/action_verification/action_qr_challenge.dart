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

/// Single-use expiring venue code; atomic consumption prevents replay across attempts.
abstract class ActionQrChallenge
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  ActionQrChallenge._({
    this.id,
    required this.requirementId,
    required this.createdByAuthUserId,
    this.createdByAuthUser,
    required this.secretHash,
    required this.expiresAt,
    this.usedAt,
    this.usedByAttemptId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ActionQrChallenge({
    _is.UuidValue? id,
    required _is.UuidValue requirementId,
    required _is.UuidValue createdByAuthUserId,
    _iacs.AuthUser? createdByAuthUser,
    required String secretHash,
    required DateTime expiresAt,
    DateTime? usedAt,
    _is.UuidValue? usedByAttemptId,
    DateTime? createdAt,
  }) = _ActionQrChallengeImpl;

  factory ActionQrChallenge.fromJson(Map<String, dynamic> jsonSerialization) {
    return ActionQrChallenge(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      requirementId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['requirementId'],
      ),
      createdByAuthUserId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['createdByAuthUserId'],
      ),
      createdByAuthUser: jsonSerialization['createdByAuthUser'] == null
          ? null
          : _itf691yl.Protocol().deserialize<_iacs.AuthUser>(
              jsonSerialization['createdByAuthUser'],
            ),
      secretHash: jsonSerialization['secretHash'] as String,
      expiresAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      usedAt: jsonSerialization['usedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['usedAt']),
      usedByAttemptId: jsonSerialization['usedByAttemptId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['usedByAttemptId'],
            ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = ActionQrChallengeTable();

  static const db = ActionQrChallengeRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue requirementId;

  _is.UuidValue createdByAuthUserId;

  _iacs.AuthUser? createdByAuthUser;

  String secretHash;

  DateTime expiresAt;

  DateTime? usedAt;

  _is.UuidValue? usedByAttemptId;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [ActionQrChallenge]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ActionQrChallenge copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? requirementId,
    _is.UuidValue? createdByAuthUserId,
    _iacs.AuthUser? createdByAuthUser =
        const _UndefinedActionQrChallenge$createdByAuthUser(),
    String? secretHash,
    DateTime? expiresAt,
    DateTime? usedAt = const _is.$UndefinedDateTime(),
    _is.UuidValue? usedByAttemptId = const _is.$UndefinedUuidValue(),
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActionQrChallenge',
      if (id != null) 'id': id?.toJson(),
      'requirementId': requirementId.toJson(),
      'createdByAuthUserId': createdByAuthUserId.toJson(),
      if (createdByAuthUser != null)
        'createdByAuthUser': createdByAuthUser?.toJson(),
      'secretHash': secretHash,
      'expiresAt': expiresAt.toJson(),
      if (usedAt != null) 'usedAt': usedAt?.toJson(),
      if (usedByAttemptId != null) 'usedByAttemptId': usedByAttemptId?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ActionQrChallengeInclude include({
    _iacs.AuthUserInclude? createdByAuthUser,
  }) {
    return ActionQrChallengeInclude._(createdByAuthUser: createdByAuthUser);
  }

  static ActionQrChallengeIncludeList includeList({
    _is.WhereExpressionBuilder<ActionQrChallengeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionQrChallengeTable>? orderBy,
    _is.OrderByListBuilder<ActionQrChallengeTable>? orderByList,
    ActionQrChallengeInclude? include,
  }) {
    return ActionQrChallengeIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ActionQrChallenge.t),
      orderByList: orderByList?.call(ActionQrChallenge.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _UndefinedActionQrChallenge$createdByAuthUser
    extends _is.UndefinedSentinel
    implements _iacs.AuthUser {
  const _UndefinedActionQrChallenge$createdByAuthUser();
}

class _ActionQrChallengeImpl extends ActionQrChallenge {
  _ActionQrChallengeImpl({
    _is.UuidValue? id,
    required _is.UuidValue requirementId,
    required _is.UuidValue createdByAuthUserId,
    _iacs.AuthUser? createdByAuthUser,
    required String secretHash,
    required DateTime expiresAt,
    DateTime? usedAt,
    _is.UuidValue? usedByAttemptId,
    DateTime? createdAt,
  }) : super._(
         id: id,
         requirementId: requirementId,
         createdByAuthUserId: createdByAuthUserId,
         createdByAuthUser: createdByAuthUser,
         secretHash: secretHash,
         expiresAt: expiresAt,
         usedAt: usedAt,
         usedByAttemptId: usedByAttemptId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ActionQrChallenge]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ActionQrChallenge copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? requirementId,
    _is.UuidValue? createdByAuthUserId,
    _iacs.AuthUser? createdByAuthUser =
        const _UndefinedActionQrChallenge$createdByAuthUser(),
    String? secretHash,
    DateTime? expiresAt,
    DateTime? usedAt = const _is.$UndefinedDateTime(),
    _is.UuidValue? usedByAttemptId = const _is.$UndefinedUuidValue(),
    DateTime? createdAt,
  }) {
    return ActionQrChallenge(
      id: id is _is.UndefinedSentinel ? this.id : id,
      requirementId: requirementId ?? this.requirementId,
      createdByAuthUserId: createdByAuthUserId ?? this.createdByAuthUserId,
      createdByAuthUser: createdByAuthUser is _is.UndefinedSentinel
          ? this.createdByAuthUser?.copyWith()
          : createdByAuthUser,
      secretHash: secretHash ?? this.secretHash,
      expiresAt: expiresAt ?? this.expiresAt,
      usedAt: usedAt is _is.UndefinedSentinel ? this.usedAt : usedAt,
      usedByAttemptId: usedByAttemptId is _is.UndefinedSentinel
          ? this.usedByAttemptId
          : usedByAttemptId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ActionQrChallengeUpdateTable
    extends _is.UpdateTable<ActionQrChallengeTable> {
  ActionQrChallengeUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> requirementId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.requirementId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> createdByAuthUserId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.createdByAuthUserId,
    value,
  );

  _is.ColumnValue<String, String> secretHash(String value) => _is.ColumnValue(
    table.secretHash,
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

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> usedByAttemptId(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.usedByAttemptId,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class ActionQrChallengeTable extends _is.Table<_is.UuidValue?> {
  ActionQrChallengeTable({super.tableRelation})
    : super(tableName: 'verily_action_qr_challenge') {
    updateTable = ActionQrChallengeUpdateTable(this);
    requirementId = _is.ColumnUuid(
      'requirementId',
      this,
    );
    createdByAuthUserId = _is.ColumnUuid(
      'createdByAuthUserId',
      this,
    );
    secretHash = _is.ColumnString(
      'secretHash',
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
    usedByAttemptId = _is.ColumnUuid(
      'usedByAttemptId',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final ActionQrChallengeUpdateTable updateTable;

  late final _is.ColumnUuid requirementId;

  late final _is.ColumnUuid createdByAuthUserId;

  _iacs.AuthUserTable? _createdByAuthUser;

  late final _is.ColumnString secretHash;

  late final _is.ColumnDateTime expiresAt;

  late final _is.ColumnDateTime usedAt;

  late final _is.ColumnUuid usedByAttemptId;

  late final _is.ColumnDateTime createdAt;

  _iacs.AuthUserTable get createdByAuthUser {
    if (_createdByAuthUser != null) return _createdByAuthUser!;
    _createdByAuthUser = _is.createRelationTable(
      relationFieldName: 'createdByAuthUser',
      field: ActionQrChallenge.t.createdByAuthUserId,
      foreignField: _iacs.AuthUser.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iacs.AuthUserTable(tableRelation: foreignTableRelation),
    );
    return _createdByAuthUser!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    requirementId,
    createdByAuthUserId,
    secretHash,
    expiresAt,
    usedAt,
    usedByAttemptId,
    createdAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'createdByAuthUser') {
      return createdByAuthUser;
    }
    return null;
  }
}

class ActionQrChallengeInclude extends _is.IncludeObject {
  ActionQrChallengeInclude._({_iacs.AuthUserInclude? createdByAuthUser}) {
    _createdByAuthUser = createdByAuthUser;
  }

  _iacs.AuthUserInclude? _createdByAuthUser;

  @override
  Map<String, _is.Include?> get includes => {
    'createdByAuthUser': _createdByAuthUser,
  };

  @override
  _is.Table<_is.UuidValue?> get table => ActionQrChallenge.t;
}

class ActionQrChallengeIncludeList extends _is.IncludeList {
  ActionQrChallengeIncludeList._({
    _is.WhereExpressionBuilder<ActionQrChallengeTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ActionQrChallenge.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => ActionQrChallenge.t;
}

class ActionQrChallengeRepository {
  const ActionQrChallengeRepository._();

  final attachRow = const ActionQrChallengeAttachRowRepository._();

  /// Returns a list of [ActionQrChallenge]s matching the given query parameters.
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
  Future<List<ActionQrChallenge>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionQrChallengeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionQrChallengeTable>? orderBy,
    _is.OrderByListBuilder<ActionQrChallengeTable>? orderByList,
    _is.Transaction? transaction,
    ActionQrChallengeInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ActionQrChallenge>(
      where: where?.call(ActionQrChallenge.t),
      orderBy: orderBy?.call(ActionQrChallenge.t),
      orderByList: orderByList?.call(ActionQrChallenge.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [ActionQrChallenge]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `ActionQrChallenge.t`.
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
  _ida.Stream<List<ActionQrChallenge>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionQrChallengeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionQrChallengeTable>? orderBy,
    _is.OrderByListBuilder<ActionQrChallengeTable>? orderByList,
    ActionQrChallengeInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<ActionQrChallenge>(
      where: where?.call(ActionQrChallenge.t),
      orderBy: orderBy?.call(ActionQrChallenge.t),
      orderByList: orderByList?.call(ActionQrChallenge.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [ActionQrChallenge] matching the given query parameters.
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
  Future<ActionQrChallenge?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionQrChallengeTable>? where,
    int? offset,
    _is.OrderByBuilder<ActionQrChallengeTable>? orderBy,
    _is.OrderByListBuilder<ActionQrChallengeTable>? orderByList,
    _is.Transaction? transaction,
    ActionQrChallengeInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ActionQrChallenge>(
      where: where?.call(ActionQrChallenge.t),
      orderBy: orderBy?.call(ActionQrChallenge.t),
      orderByList: orderByList?.call(ActionQrChallenge.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ActionQrChallenge] by its [id] or null if no such row exists.
  Future<ActionQrChallenge?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    ActionQrChallengeInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ActionQrChallenge>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ActionQrChallenge]s in the list and returns the inserted rows.
  ///
  /// The returned [ActionQrChallenge]s will have their `id` fields set.
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
  Future<List<ActionQrChallenge>> insert(
    _is.DatabaseSession session,
    List<ActionQrChallenge> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ActionQrChallenge>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ActionQrChallenge] and returns the inserted row.
  ///
  /// The returned [ActionQrChallenge] will have its `id` field set.
  Future<ActionQrChallenge> insertRow(
    _is.DatabaseSession session,
    ActionQrChallenge row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ActionQrChallenge>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ActionQrChallenge]s in the list and returns the resulting rows.
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
  /// The returned [ActionQrChallenge]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionQrChallenge>> upsert(
    _is.DatabaseSession session,
    List<ActionQrChallenge> rows, {
    required _is.ColumnSelections<ActionQrChallengeTable> conflictColumns,
    _is.ColumnSelections<ActionQrChallengeTable>? updateColumns,
    _is.WhereExpressionBuilder<ActionQrChallengeTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ActionQrChallenge>(
      rows,
      conflictColumns: conflictColumns(ActionQrChallenge.t),
      updateColumns: updateColumns?.call(ActionQrChallenge.t),
      updateWhere: updateWhere?.call(ActionQrChallenge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ActionQrChallenge] and returns the resulting row.
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
  /// The returned [ActionQrChallenge] will have its `id` field set.
  Future<ActionQrChallenge?> upsertRow(
    _is.DatabaseSession session,
    ActionQrChallenge row, {
    required _is.ColumnSelections<ActionQrChallengeTable> conflictColumns,
    _is.ColumnSelections<ActionQrChallengeTable>? updateColumns,
    _is.WhereExpressionBuilder<ActionQrChallengeTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ActionQrChallenge>(
      row,
      conflictColumns: conflictColumns(ActionQrChallenge.t),
      updateColumns: updateColumns?.call(ActionQrChallenge.t),
      updateWhere: updateWhere?.call(ActionQrChallenge.t),
      transaction: transaction,
    );
  }

  /// Updates all [ActionQrChallenge]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionQrChallenge>> update(
    _is.DatabaseSession session,
    List<ActionQrChallenge> rows, {
    _is.ColumnSelections<ActionQrChallengeTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ActionQrChallenge>(
      rows,
      columns: columns?.call(ActionQrChallenge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ActionQrChallenge]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ActionQrChallenge> updateRow(
    _is.DatabaseSession session,
    ActionQrChallenge row, {
    _is.ColumnSelections<ActionQrChallengeTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ActionQrChallenge>(
      row,
      columns: columns?.call(ActionQrChallenge.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ActionQrChallenge] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ActionQrChallenge?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<ActionQrChallengeUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ActionQrChallenge>(
      id,
      columnValues: columnValues(ActionQrChallenge.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ActionQrChallenge]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionQrChallenge>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ActionQrChallengeUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<ActionQrChallengeTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionQrChallengeTable>? orderBy,
    _is.OrderByListBuilder<ActionQrChallengeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ActionQrChallenge>(
      columnValues: columnValues(ActionQrChallenge.t.updateTable),
      where: where(ActionQrChallenge.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ActionQrChallenge.t),
      orderByList: orderByList?.call(ActionQrChallenge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ActionQrChallenge]s in the list and returns the deleted rows.
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
  Future<List<ActionQrChallenge>> delete(
    _is.DatabaseSession session,
    List<ActionQrChallenge> rows, {
    _is.OrderByBuilder<ActionQrChallengeTable>? orderBy,
    _is.OrderByListBuilder<ActionQrChallengeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ActionQrChallenge>(
      rows,
      orderBy: orderBy?.call(ActionQrChallenge.t),
      orderByList: orderByList?.call(ActionQrChallenge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ActionQrChallenge].
  Future<ActionQrChallenge> deleteRow(
    _is.DatabaseSession session,
    ActionQrChallenge row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ActionQrChallenge>(
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
  Future<List<ActionQrChallenge>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ActionQrChallengeTable> where,
    _is.OrderByBuilder<ActionQrChallengeTable>? orderBy,
    _is.OrderByListBuilder<ActionQrChallengeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ActionQrChallenge>(
      where: where(ActionQrChallenge.t),
      orderBy: orderBy?.call(ActionQrChallenge.t),
      orderByList: orderByList?.call(ActionQrChallenge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionQrChallengeTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ActionQrChallenge>(
      where: where?.call(ActionQrChallenge.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ActionQrChallenge] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ActionQrChallengeTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ActionQrChallenge>(
      where: where(ActionQrChallenge.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class ActionQrChallengeAttachRowRepository {
  const ActionQrChallengeAttachRowRepository._();

  /// Creates a relation between the given [ActionQrChallenge] and [AuthUser]
  /// by setting the [ActionQrChallenge]'s foreign key `createdByAuthUserId` to refer to the [AuthUser].
  Future<void> createdByAuthUser(
    _is.DatabaseSession session,
    ActionQrChallenge actionQrChallenge,
    _iacs.AuthUser createdByAuthUser, {
    _is.Transaction? transaction,
  }) async {
    if (actionQrChallenge.id == null) {
      throw ArgumentError.notNull('actionQrChallenge.id');
    }
    if (createdByAuthUser.id == null) {
      throw ArgumentError.notNull('createdByAuthUser.id');
    }

    var $actionQrChallenge = actionQrChallenge.copyWith(
      createdByAuthUserId: createdByAuthUser.id,
    );
    await session.db.updateRow<ActionQrChallenge>(
      $actionQrChallenge,
      columns: [ActionQrChallenge.t.createdByAuthUserId],
      transaction: transaction,
    );
  }
}
