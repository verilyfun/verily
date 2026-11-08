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

/// Append-only record of each human moderation state transition.
abstract class ModerationAuditEntry
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  ModerationAuditEntry._({
    this.id,
    required this.caseId,
    this.actorAuthUserId,
    this.actorAuthUser,
    required this.event,
    required this.note,
    required this.pauseActive,
    required this.createdAt,
  });

  factory ModerationAuditEntry({
    _is.UuidValue? id,
    required _is.UuidValue caseId,
    _is.UuidValue? actorAuthUserId,
    _iacs.AuthUser? actorAuthUser,
    required String event,
    required String note,
    required bool pauseActive,
    required DateTime createdAt,
  }) = _ModerationAuditEntryImpl;

  factory ModerationAuditEntry.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ModerationAuditEntry(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      caseId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['caseId']),
      actorAuthUserId: jsonSerialization['actorAuthUserId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['actorAuthUserId'],
            ),
      actorAuthUser: jsonSerialization['actorAuthUser'] == null
          ? null
          : _itf691yl.Protocol().deserialize<_iacs.AuthUser>(
              jsonSerialization['actorAuthUser'],
            ),
      event: jsonSerialization['event'] as String,
      note: jsonSerialization['note'] as String,
      pauseActive: _is.BoolJsonExtension.fromJson(
        jsonSerialization['pauseActive'],
      ),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = ModerationAuditEntryTable();

  static const db = ModerationAuditEntryRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue caseId;

  _is.UuidValue? actorAuthUserId;

  _iacs.AuthUser? actorAuthUser;

  String event;

  String note;

  bool pauseActive;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [ModerationAuditEntry]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ModerationAuditEntry copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? caseId,
    _is.UuidValue? actorAuthUserId = const _is.$UndefinedUuidValue(),
    _iacs.AuthUser? actorAuthUser =
        const _UndefinedModerationAuditEntry$actorAuthUser(),
    String? event,
    String? note,
    bool? pauseActive,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ModerationAuditEntry',
      if (id != null) 'id': id?.toJson(),
      'caseId': caseId.toJson(),
      if (actorAuthUserId != null) 'actorAuthUserId': actorAuthUserId?.toJson(),
      if (actorAuthUser != null) 'actorAuthUser': actorAuthUser?.toJson(),
      'event': event,
      'note': note,
      'pauseActive': pauseActive,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ModerationAuditEntryInclude include({
    _iacs.AuthUserInclude? actorAuthUser,
  }) {
    return ModerationAuditEntryInclude._(actorAuthUser: actorAuthUser);
  }

  static ModerationAuditEntryIncludeList includeList({
    _is.WhereExpressionBuilder<ModerationAuditEntryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ModerationAuditEntryTable>? orderBy,
    _is.OrderByListBuilder<ModerationAuditEntryTable>? orderByList,
    ModerationAuditEntryInclude? include,
  }) {
    return ModerationAuditEntryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ModerationAuditEntry.t),
      orderByList: orderByList?.call(ModerationAuditEntry.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _UndefinedModerationAuditEntry$actorAuthUser extends _is.UndefinedSentinel
    implements _iacs.AuthUser {
  const _UndefinedModerationAuditEntry$actorAuthUser();
}

class _ModerationAuditEntryImpl extends ModerationAuditEntry {
  _ModerationAuditEntryImpl({
    _is.UuidValue? id,
    required _is.UuidValue caseId,
    _is.UuidValue? actorAuthUserId,
    _iacs.AuthUser? actorAuthUser,
    required String event,
    required String note,
    required bool pauseActive,
    required DateTime createdAt,
  }) : super._(
         id: id,
         caseId: caseId,
         actorAuthUserId: actorAuthUserId,
         actorAuthUser: actorAuthUser,
         event: event,
         note: note,
         pauseActive: pauseActive,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ModerationAuditEntry]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ModerationAuditEntry copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? caseId,
    _is.UuidValue? actorAuthUserId = const _is.$UndefinedUuidValue(),
    _iacs.AuthUser? actorAuthUser =
        const _UndefinedModerationAuditEntry$actorAuthUser(),
    String? event,
    String? note,
    bool? pauseActive,
    DateTime? createdAt,
  }) {
    return ModerationAuditEntry(
      id: id is _is.UndefinedSentinel ? this.id : id,
      caseId: caseId ?? this.caseId,
      actorAuthUserId: actorAuthUserId is _is.UndefinedSentinel
          ? this.actorAuthUserId
          : actorAuthUserId,
      actorAuthUser: actorAuthUser is _is.UndefinedSentinel
          ? this.actorAuthUser?.copyWith()
          : actorAuthUser,
      event: event ?? this.event,
      note: note ?? this.note,
      pauseActive: pauseActive ?? this.pauseActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ModerationAuditEntryUpdateTable
    extends _is.UpdateTable<ModerationAuditEntryTable> {
  ModerationAuditEntryUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> caseId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.caseId,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> actorAuthUserId(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.actorAuthUserId,
    value,
  );

  _is.ColumnValue<String, String> event(String value) => _is.ColumnValue(
    table.event,
    value,
  );

  _is.ColumnValue<String, String> note(String value) => _is.ColumnValue(
    table.note,
    value,
  );

  _is.ColumnValue<bool, bool> pauseActive(bool value) => _is.ColumnValue(
    table.pauseActive,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class ModerationAuditEntryTable extends _is.Table<_is.UuidValue?> {
  ModerationAuditEntryTable({super.tableRelation})
    : super(tableName: 'verily_moderation_audit_entry') {
    updateTable = ModerationAuditEntryUpdateTable(this);
    caseId = _is.ColumnUuid(
      'caseId',
      this,
    );
    actorAuthUserId = _is.ColumnUuid(
      'actorAuthUserId',
      this,
    );
    event = _is.ColumnString(
      'event',
      this,
    );
    note = _is.ColumnString(
      'note',
      this,
    );
    pauseActive = _is.ColumnBool(
      'pauseActive',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final ModerationAuditEntryUpdateTable updateTable;

  late final _is.ColumnUuid caseId;

  late final _is.ColumnUuid actorAuthUserId;

  _iacs.AuthUserTable? _actorAuthUser;

  late final _is.ColumnString event;

  late final _is.ColumnString note;

  late final _is.ColumnBool pauseActive;

  late final _is.ColumnDateTime createdAt;

  _iacs.AuthUserTable get actorAuthUser {
    if (_actorAuthUser != null) return _actorAuthUser!;
    _actorAuthUser = _is.createRelationTable(
      relationFieldName: 'actorAuthUser',
      field: ModerationAuditEntry.t.actorAuthUserId,
      foreignField: _iacs.AuthUser.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iacs.AuthUserTable(tableRelation: foreignTableRelation),
    );
    return _actorAuthUser!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    caseId,
    actorAuthUserId,
    event,
    note,
    pauseActive,
    createdAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'actorAuthUser') {
      return actorAuthUser;
    }
    return null;
  }
}

class ModerationAuditEntryInclude extends _is.IncludeObject {
  ModerationAuditEntryInclude._({_iacs.AuthUserInclude? actorAuthUser}) {
    _actorAuthUser = actorAuthUser;
  }

  _iacs.AuthUserInclude? _actorAuthUser;

  @override
  Map<String, _is.Include?> get includes => {'actorAuthUser': _actorAuthUser};

  @override
  _is.Table<_is.UuidValue?> get table => ModerationAuditEntry.t;
}

class ModerationAuditEntryIncludeList extends _is.IncludeList {
  ModerationAuditEntryIncludeList._({
    _is.WhereExpressionBuilder<ModerationAuditEntryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ModerationAuditEntry.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => ModerationAuditEntry.t;
}

class ModerationAuditEntryRepository {
  const ModerationAuditEntryRepository._();

  final attachRow = const ModerationAuditEntryAttachRowRepository._();

  final detachRow = const ModerationAuditEntryDetachRowRepository._();

  /// Returns a list of [ModerationAuditEntry]s matching the given query parameters.
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
  Future<List<ModerationAuditEntry>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ModerationAuditEntryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ModerationAuditEntryTable>? orderBy,
    _is.OrderByListBuilder<ModerationAuditEntryTable>? orderByList,
    _is.Transaction? transaction,
    ModerationAuditEntryInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ModerationAuditEntry>(
      where: where?.call(ModerationAuditEntry.t),
      orderBy: orderBy?.call(ModerationAuditEntry.t),
      orderByList: orderByList?.call(ModerationAuditEntry.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [ModerationAuditEntry]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `ModerationAuditEntry.t`.
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
  _ida.Stream<List<ModerationAuditEntry>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ModerationAuditEntryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ModerationAuditEntryTable>? orderBy,
    _is.OrderByListBuilder<ModerationAuditEntryTable>? orderByList,
    ModerationAuditEntryInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<ModerationAuditEntry>(
      where: where?.call(ModerationAuditEntry.t),
      orderBy: orderBy?.call(ModerationAuditEntry.t),
      orderByList: orderByList?.call(ModerationAuditEntry.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [ModerationAuditEntry] matching the given query parameters.
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
  Future<ModerationAuditEntry?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ModerationAuditEntryTable>? where,
    int? offset,
    _is.OrderByBuilder<ModerationAuditEntryTable>? orderBy,
    _is.OrderByListBuilder<ModerationAuditEntryTable>? orderByList,
    _is.Transaction? transaction,
    ModerationAuditEntryInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ModerationAuditEntry>(
      where: where?.call(ModerationAuditEntry.t),
      orderBy: orderBy?.call(ModerationAuditEntry.t),
      orderByList: orderByList?.call(ModerationAuditEntry.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ModerationAuditEntry] by its [id] or null if no such row exists.
  Future<ModerationAuditEntry?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    ModerationAuditEntryInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ModerationAuditEntry>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ModerationAuditEntry]s in the list and returns the inserted rows.
  ///
  /// The returned [ModerationAuditEntry]s will have their `id` fields set.
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
  Future<List<ModerationAuditEntry>> insert(
    _is.DatabaseSession session,
    List<ModerationAuditEntry> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ModerationAuditEntry>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ModerationAuditEntry] and returns the inserted row.
  ///
  /// The returned [ModerationAuditEntry] will have its `id` field set.
  Future<ModerationAuditEntry> insertRow(
    _is.DatabaseSession session,
    ModerationAuditEntry row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ModerationAuditEntry>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ModerationAuditEntry]s in the list and returns the resulting rows.
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
  /// The returned [ModerationAuditEntry]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ModerationAuditEntry>> upsert(
    _is.DatabaseSession session,
    List<ModerationAuditEntry> rows, {
    required _is.ColumnSelections<ModerationAuditEntryTable> conflictColumns,
    _is.ColumnSelections<ModerationAuditEntryTable>? updateColumns,
    _is.WhereExpressionBuilder<ModerationAuditEntryTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ModerationAuditEntry>(
      rows,
      conflictColumns: conflictColumns(ModerationAuditEntry.t),
      updateColumns: updateColumns?.call(ModerationAuditEntry.t),
      updateWhere: updateWhere?.call(ModerationAuditEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ModerationAuditEntry] and returns the resulting row.
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
  /// The returned [ModerationAuditEntry] will have its `id` field set.
  Future<ModerationAuditEntry?> upsertRow(
    _is.DatabaseSession session,
    ModerationAuditEntry row, {
    required _is.ColumnSelections<ModerationAuditEntryTable> conflictColumns,
    _is.ColumnSelections<ModerationAuditEntryTable>? updateColumns,
    _is.WhereExpressionBuilder<ModerationAuditEntryTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ModerationAuditEntry>(
      row,
      conflictColumns: conflictColumns(ModerationAuditEntry.t),
      updateColumns: updateColumns?.call(ModerationAuditEntry.t),
      updateWhere: updateWhere?.call(ModerationAuditEntry.t),
      transaction: transaction,
    );
  }

  /// Updates all [ModerationAuditEntry]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ModerationAuditEntry>> update(
    _is.DatabaseSession session,
    List<ModerationAuditEntry> rows, {
    _is.ColumnSelections<ModerationAuditEntryTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ModerationAuditEntry>(
      rows,
      columns: columns?.call(ModerationAuditEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ModerationAuditEntry]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ModerationAuditEntry> updateRow(
    _is.DatabaseSession session,
    ModerationAuditEntry row, {
    _is.ColumnSelections<ModerationAuditEntryTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ModerationAuditEntry>(
      row,
      columns: columns?.call(ModerationAuditEntry.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ModerationAuditEntry] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ModerationAuditEntry?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<ModerationAuditEntryUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ModerationAuditEntry>(
      id,
      columnValues: columnValues(ModerationAuditEntry.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ModerationAuditEntry]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ModerationAuditEntry>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ModerationAuditEntryUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<ModerationAuditEntryTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ModerationAuditEntryTable>? orderBy,
    _is.OrderByListBuilder<ModerationAuditEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ModerationAuditEntry>(
      columnValues: columnValues(ModerationAuditEntry.t.updateTable),
      where: where(ModerationAuditEntry.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ModerationAuditEntry.t),
      orderByList: orderByList?.call(ModerationAuditEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ModerationAuditEntry]s in the list and returns the deleted rows.
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
  Future<List<ModerationAuditEntry>> delete(
    _is.DatabaseSession session,
    List<ModerationAuditEntry> rows, {
    _is.OrderByBuilder<ModerationAuditEntryTable>? orderBy,
    _is.OrderByListBuilder<ModerationAuditEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ModerationAuditEntry>(
      rows,
      orderBy: orderBy?.call(ModerationAuditEntry.t),
      orderByList: orderByList?.call(ModerationAuditEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ModerationAuditEntry].
  Future<ModerationAuditEntry> deleteRow(
    _is.DatabaseSession session,
    ModerationAuditEntry row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ModerationAuditEntry>(
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
  Future<List<ModerationAuditEntry>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ModerationAuditEntryTable> where,
    _is.OrderByBuilder<ModerationAuditEntryTable>? orderBy,
    _is.OrderByListBuilder<ModerationAuditEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ModerationAuditEntry>(
      where: where(ModerationAuditEntry.t),
      orderBy: orderBy?.call(ModerationAuditEntry.t),
      orderByList: orderByList?.call(ModerationAuditEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ModerationAuditEntryTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ModerationAuditEntry>(
      where: where?.call(ModerationAuditEntry.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ModerationAuditEntry] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ModerationAuditEntryTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ModerationAuditEntry>(
      where: where(ModerationAuditEntry.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class ModerationAuditEntryAttachRowRepository {
  const ModerationAuditEntryAttachRowRepository._();

  /// Creates a relation between the given [ModerationAuditEntry] and [AuthUser]
  /// by setting the [ModerationAuditEntry]'s foreign key `actorAuthUserId` to refer to the [AuthUser].
  Future<void> actorAuthUser(
    _is.DatabaseSession session,
    ModerationAuditEntry moderationAuditEntry,
    _iacs.AuthUser actorAuthUser, {
    _is.Transaction? transaction,
  }) async {
    if (moderationAuditEntry.id == null) {
      throw ArgumentError.notNull('moderationAuditEntry.id');
    }
    if (actorAuthUser.id == null) {
      throw ArgumentError.notNull('actorAuthUser.id');
    }

    var $moderationAuditEntry = moderationAuditEntry.copyWith(
      actorAuthUserId: actorAuthUser.id,
    );
    await session.db.updateRow<ModerationAuditEntry>(
      $moderationAuditEntry,
      columns: [ModerationAuditEntry.t.actorAuthUserId],
      transaction: transaction,
    );
  }
}

class ModerationAuditEntryDetachRowRepository {
  const ModerationAuditEntryDetachRowRepository._();

  /// Detaches the relation between this [ModerationAuditEntry] and the [AuthUser] set in `actorAuthUser`
  /// by setting the [ModerationAuditEntry]'s foreign key `actorAuthUserId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> actorAuthUser(
    _is.DatabaseSession session,
    ModerationAuditEntry moderationAuditEntry, {
    _is.Transaction? transaction,
  }) async {
    if (moderationAuditEntry.id == null) {
      throw ArgumentError.notNull('moderationAuditEntry.id');
    }

    var $moderationAuditEntry = moderationAuditEntry.copyWith(
      actorAuthUserId: null,
    );
    await session.db.updateRow<ModerationAuditEntry>(
      $moderationAuditEntry,
      columns: [ModerationAuditEntry.t.actorAuthUserId],
      transaction: transaction,
    );
  }
}
