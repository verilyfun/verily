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

/// A live, server-chosen word the participant says while recording one video
/// or audio proof. It is issued before recording and bound to the upload, so a
/// recording made earlier cannot contain it. The word never comes from a
/// client or creator.
abstract class ActionSpokenChallenge
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  ActionSpokenChallenge._({
    this.id,
    required this.attemptId,
    required this.requirementId,
    required this.participantAuthUserId,
    this.participantAuthUser,
    required this.word,
    required this.issuedAt,
    required this.expiresAt,
    this.boundAt,
  });

  factory ActionSpokenChallenge({
    _is.UuidValue? id,
    required _is.UuidValue attemptId,
    required _is.UuidValue requirementId,
    required _is.UuidValue participantAuthUserId,
    _iacs.AuthUser? participantAuthUser,
    required String word,
    required DateTime issuedAt,
    required DateTime expiresAt,
    DateTime? boundAt,
  }) = _ActionSpokenChallengeImpl;

  factory ActionSpokenChallenge.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ActionSpokenChallenge(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      attemptId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['attemptId'],
      ),
      requirementId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['requirementId'],
      ),
      participantAuthUserId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['participantAuthUserId'],
      ),
      participantAuthUser: jsonSerialization['participantAuthUser'] == null
          ? null
          : _itf691yl.Protocol().deserialize<_iacs.AuthUser>(
              jsonSerialization['participantAuthUser'],
            ),
      word: jsonSerialization['word'] as String,
      issuedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['issuedAt'],
      ),
      expiresAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      boundAt: jsonSerialization['boundAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['boundAt']),
    );
  }

  static final t = ActionSpokenChallengeTable();

  static const db = ActionSpokenChallengeRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue attemptId;

  _is.UuidValue requirementId;

  _is.UuidValue participantAuthUserId;

  _iacs.AuthUser? participantAuthUser;

  String word;

  DateTime issuedAt;

  DateTime expiresAt;

  /// Set when an upload reservation binds this word to a recording.
  DateTime? boundAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [ActionSpokenChallenge]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ActionSpokenChallenge copyWith({
    _is.UuidValue? id,
    _is.UuidValue? attemptId,
    _is.UuidValue? requirementId,
    _is.UuidValue? participantAuthUserId,
    _iacs.AuthUser? participantAuthUser,
    String? word,
    DateTime? issuedAt,
    DateTime? expiresAt,
    DateTime? boundAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActionSpokenChallenge',
      if (id != null) 'id': id?.toJson(),
      'attemptId': attemptId.toJson(),
      'requirementId': requirementId.toJson(),
      'participantAuthUserId': participantAuthUserId.toJson(),
      if (participantAuthUser != null)
        'participantAuthUser': participantAuthUser?.toJson(),
      'word': word,
      'issuedAt': issuedAt.toJson(),
      'expiresAt': expiresAt.toJson(),
      if (boundAt != null) 'boundAt': boundAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ActionSpokenChallengeInclude include({
    _iacs.AuthUserInclude? participantAuthUser,
  }) {
    return ActionSpokenChallengeInclude._(
      participantAuthUser: participantAuthUser,
    );
  }

  static ActionSpokenChallengeIncludeList includeList({
    _is.WhereExpressionBuilder<ActionSpokenChallengeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionSpokenChallengeTable>? orderBy,
    _is.OrderByListBuilder<ActionSpokenChallengeTable>? orderByList,
    ActionSpokenChallengeInclude? include,
  }) {
    return ActionSpokenChallengeIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ActionSpokenChallenge.t),
      orderByList: orderByList?.call(ActionSpokenChallenge.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ActionSpokenChallengeImpl extends ActionSpokenChallenge {
  _ActionSpokenChallengeImpl({
    _is.UuidValue? id,
    required _is.UuidValue attemptId,
    required _is.UuidValue requirementId,
    required _is.UuidValue participantAuthUserId,
    _iacs.AuthUser? participantAuthUser,
    required String word,
    required DateTime issuedAt,
    required DateTime expiresAt,
    DateTime? boundAt,
  }) : super._(
         id: id,
         attemptId: attemptId,
         requirementId: requirementId,
         participantAuthUserId: participantAuthUserId,
         participantAuthUser: participantAuthUser,
         word: word,
         issuedAt: issuedAt,
         expiresAt: expiresAt,
         boundAt: boundAt,
       );

  /// Returns a shallow copy of this [ActionSpokenChallenge]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ActionSpokenChallenge copyWith({
    Object? id = _Undefined,
    _is.UuidValue? attemptId,
    _is.UuidValue? requirementId,
    _is.UuidValue? participantAuthUserId,
    Object? participantAuthUser = _Undefined,
    String? word,
    DateTime? issuedAt,
    DateTime? expiresAt,
    Object? boundAt = _Undefined,
  }) {
    return ActionSpokenChallenge(
      id: id is _is.UuidValue? ? id : this.id,
      attemptId: attemptId ?? this.attemptId,
      requirementId: requirementId ?? this.requirementId,
      participantAuthUserId:
          participantAuthUserId ?? this.participantAuthUserId,
      participantAuthUser: participantAuthUser is _iacs.AuthUser?
          ? participantAuthUser
          : this.participantAuthUser?.copyWith(),
      word: word ?? this.word,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      boundAt: boundAt is DateTime? ? boundAt : this.boundAt,
    );
  }
}

class ActionSpokenChallengeUpdateTable
    extends _is.UpdateTable<ActionSpokenChallengeTable> {
  ActionSpokenChallengeUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> attemptId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.attemptId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> requirementId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.requirementId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> participantAuthUserId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.participantAuthUserId,
    value,
  );

  _is.ColumnValue<String, String> word(String value) => _is.ColumnValue(
    table.word,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> issuedAt(DateTime value) =>
      _is.ColumnValue(
        table.issuedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> expiresAt(DateTime value) =>
      _is.ColumnValue(
        table.expiresAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> boundAt(DateTime? value) =>
      _is.ColumnValue(
        table.boundAt,
        value,
      );
}

class ActionSpokenChallengeTable extends _is.Table<_is.UuidValue?> {
  ActionSpokenChallengeTable({super.tableRelation})
    : super(tableName: 'verily_action_spoken_challenge') {
    updateTable = ActionSpokenChallengeUpdateTable(this);
    attemptId = _is.ColumnUuid(
      'attemptId',
      this,
    );
    requirementId = _is.ColumnUuid(
      'requirementId',
      this,
    );
    participantAuthUserId = _is.ColumnUuid(
      'participantAuthUserId',
      this,
    );
    word = _is.ColumnString(
      'word',
      this,
    );
    issuedAt = _is.ColumnDateTime(
      'issuedAt',
      this,
    );
    expiresAt = _is.ColumnDateTime(
      'expiresAt',
      this,
    );
    boundAt = _is.ColumnDateTime(
      'boundAt',
      this,
    );
  }

  late final ActionSpokenChallengeUpdateTable updateTable;

  late final _is.ColumnUuid attemptId;

  late final _is.ColumnUuid requirementId;

  late final _is.ColumnUuid participantAuthUserId;

  _iacs.AuthUserTable? _participantAuthUser;

  late final _is.ColumnString word;

  late final _is.ColumnDateTime issuedAt;

  late final _is.ColumnDateTime expiresAt;

  /// Set when an upload reservation binds this word to a recording.
  late final _is.ColumnDateTime boundAt;

  _iacs.AuthUserTable get participantAuthUser {
    if (_participantAuthUser != null) return _participantAuthUser!;
    _participantAuthUser = _is.createRelationTable(
      relationFieldName: 'participantAuthUser',
      field: ActionSpokenChallenge.t.participantAuthUserId,
      foreignField: _iacs.AuthUser.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iacs.AuthUserTable(tableRelation: foreignTableRelation),
    );
    return _participantAuthUser!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    attemptId,
    requirementId,
    participantAuthUserId,
    word,
    issuedAt,
    expiresAt,
    boundAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'participantAuthUser') {
      return participantAuthUser;
    }
    return null;
  }
}

class ActionSpokenChallengeInclude extends _is.IncludeObject {
  ActionSpokenChallengeInclude._({_iacs.AuthUserInclude? participantAuthUser}) {
    _participantAuthUser = participantAuthUser;
  }

  _iacs.AuthUserInclude? _participantAuthUser;

  @override
  Map<String, _is.Include?> get includes => {
    'participantAuthUser': _participantAuthUser,
  };

  @override
  _is.Table<_is.UuidValue?> get table => ActionSpokenChallenge.t;
}

class ActionSpokenChallengeIncludeList extends _is.IncludeList {
  ActionSpokenChallengeIncludeList._({
    _is.WhereExpressionBuilder<ActionSpokenChallengeTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ActionSpokenChallenge.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => ActionSpokenChallenge.t;
}

class ActionSpokenChallengeRepository {
  const ActionSpokenChallengeRepository._();

  final attachRow = const ActionSpokenChallengeAttachRowRepository._();

  /// Returns a list of [ActionSpokenChallenge]s matching the given query parameters.
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
  Future<List<ActionSpokenChallenge>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionSpokenChallengeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionSpokenChallengeTable>? orderBy,
    _is.OrderByListBuilder<ActionSpokenChallengeTable>? orderByList,
    _is.Transaction? transaction,
    ActionSpokenChallengeInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ActionSpokenChallenge>(
      where: where?.call(ActionSpokenChallenge.t),
      orderBy: orderBy?.call(ActionSpokenChallenge.t),
      orderByList: orderByList?.call(ActionSpokenChallenge.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ActionSpokenChallenge] matching the given query parameters.
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
  Future<ActionSpokenChallenge?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionSpokenChallengeTable>? where,
    int? offset,
    _is.OrderByBuilder<ActionSpokenChallengeTable>? orderBy,
    _is.OrderByListBuilder<ActionSpokenChallengeTable>? orderByList,
    _is.Transaction? transaction,
    ActionSpokenChallengeInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ActionSpokenChallenge>(
      where: where?.call(ActionSpokenChallenge.t),
      orderBy: orderBy?.call(ActionSpokenChallenge.t),
      orderByList: orderByList?.call(ActionSpokenChallenge.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ActionSpokenChallenge] by its [id] or null if no such row exists.
  Future<ActionSpokenChallenge?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    ActionSpokenChallengeInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ActionSpokenChallenge>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ActionSpokenChallenge]s in the list and returns the inserted rows.
  ///
  /// The returned [ActionSpokenChallenge]s will have their `id` fields set.
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
  Future<List<ActionSpokenChallenge>> insert(
    _is.DatabaseSession session,
    List<ActionSpokenChallenge> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ActionSpokenChallenge>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ActionSpokenChallenge] and returns the inserted row.
  ///
  /// The returned [ActionSpokenChallenge] will have its `id` field set.
  Future<ActionSpokenChallenge> insertRow(
    _is.DatabaseSession session,
    ActionSpokenChallenge row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ActionSpokenChallenge>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ActionSpokenChallenge]s in the list and returns the resulting rows.
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
  /// The returned [ActionSpokenChallenge]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionSpokenChallenge>> upsert(
    _is.DatabaseSession session,
    List<ActionSpokenChallenge> rows, {
    required _is.ColumnSelections<ActionSpokenChallengeTable> conflictColumns,
    _is.ColumnSelections<ActionSpokenChallengeTable>? updateColumns,
    _is.WhereExpressionBuilder<ActionSpokenChallengeTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ActionSpokenChallenge>(
      rows,
      conflictColumns: conflictColumns(ActionSpokenChallenge.t),
      updateColumns: updateColumns?.call(ActionSpokenChallenge.t),
      updateWhere: updateWhere?.call(ActionSpokenChallenge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ActionSpokenChallenge] and returns the resulting row.
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
  /// The returned [ActionSpokenChallenge] will have its `id` field set.
  Future<ActionSpokenChallenge?> upsertRow(
    _is.DatabaseSession session,
    ActionSpokenChallenge row, {
    required _is.ColumnSelections<ActionSpokenChallengeTable> conflictColumns,
    _is.ColumnSelections<ActionSpokenChallengeTable>? updateColumns,
    _is.WhereExpressionBuilder<ActionSpokenChallengeTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ActionSpokenChallenge>(
      row,
      conflictColumns: conflictColumns(ActionSpokenChallenge.t),
      updateColumns: updateColumns?.call(ActionSpokenChallenge.t),
      updateWhere: updateWhere?.call(ActionSpokenChallenge.t),
      transaction: transaction,
    );
  }

  /// Updates all [ActionSpokenChallenge]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionSpokenChallenge>> update(
    _is.DatabaseSession session,
    List<ActionSpokenChallenge> rows, {
    _is.ColumnSelections<ActionSpokenChallengeTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ActionSpokenChallenge>(
      rows,
      columns: columns?.call(ActionSpokenChallenge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ActionSpokenChallenge]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ActionSpokenChallenge> updateRow(
    _is.DatabaseSession session,
    ActionSpokenChallenge row, {
    _is.ColumnSelections<ActionSpokenChallengeTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ActionSpokenChallenge>(
      row,
      columns: columns?.call(ActionSpokenChallenge.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ActionSpokenChallenge] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ActionSpokenChallenge?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<ActionSpokenChallengeUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ActionSpokenChallenge>(
      id,
      columnValues: columnValues(ActionSpokenChallenge.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ActionSpokenChallenge]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionSpokenChallenge>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ActionSpokenChallengeUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<ActionSpokenChallengeTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionSpokenChallengeTable>? orderBy,
    _is.OrderByListBuilder<ActionSpokenChallengeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ActionSpokenChallenge>(
      columnValues: columnValues(ActionSpokenChallenge.t.updateTable),
      where: where(ActionSpokenChallenge.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ActionSpokenChallenge.t),
      orderByList: orderByList?.call(ActionSpokenChallenge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ActionSpokenChallenge]s in the list and returns the deleted rows.
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
  Future<List<ActionSpokenChallenge>> delete(
    _is.DatabaseSession session,
    List<ActionSpokenChallenge> rows, {
    _is.OrderByBuilder<ActionSpokenChallengeTable>? orderBy,
    _is.OrderByListBuilder<ActionSpokenChallengeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ActionSpokenChallenge>(
      rows,
      orderBy: orderBy?.call(ActionSpokenChallenge.t),
      orderByList: orderByList?.call(ActionSpokenChallenge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ActionSpokenChallenge].
  Future<ActionSpokenChallenge> deleteRow(
    _is.DatabaseSession session,
    ActionSpokenChallenge row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ActionSpokenChallenge>(
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
  Future<List<ActionSpokenChallenge>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ActionSpokenChallengeTable> where,
    _is.OrderByBuilder<ActionSpokenChallengeTable>? orderBy,
    _is.OrderByListBuilder<ActionSpokenChallengeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ActionSpokenChallenge>(
      where: where(ActionSpokenChallenge.t),
      orderBy: orderBy?.call(ActionSpokenChallenge.t),
      orderByList: orderByList?.call(ActionSpokenChallenge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionSpokenChallengeTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ActionSpokenChallenge>(
      where: where?.call(ActionSpokenChallenge.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ActionSpokenChallenge] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ActionSpokenChallengeTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ActionSpokenChallenge>(
      where: where(ActionSpokenChallenge.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class ActionSpokenChallengeAttachRowRepository {
  const ActionSpokenChallengeAttachRowRepository._();

  /// Creates a relation between the given [ActionSpokenChallenge] and [AuthUser]
  /// by setting the [ActionSpokenChallenge]'s foreign key `participantAuthUserId` to refer to the [AuthUser].
  Future<void> participantAuthUser(
    _is.DatabaseSession session,
    ActionSpokenChallenge actionSpokenChallenge,
    _iacs.AuthUser participantAuthUser, {
    _is.Transaction? transaction,
  }) async {
    if (actionSpokenChallenge.id == null) {
      throw ArgumentError.notNull('actionSpokenChallenge.id');
    }
    if (participantAuthUser.id == null) {
      throw ArgumentError.notNull('participantAuthUser.id');
    }

    var $actionSpokenChallenge = actionSpokenChallenge.copyWith(
      participantAuthUserId: participantAuthUser.id,
    );
    await session.db.updateRow<ActionSpokenChallenge>(
      $actionSpokenChallenge,
      columns: [ActionSpokenChallenge.t.participantAuthUserId],
      transaction: transaction,
    );
  }
}
