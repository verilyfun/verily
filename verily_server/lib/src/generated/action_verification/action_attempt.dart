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

import '../action_verification/action_attempt_status.dart' as _i8xrgke5;
import '../rewards/reward_outcome.dart' as _ilgf73sw;

/// One account attempt per action period; retries reuse the same attempt.
abstract class ActionAttempt
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  ActionAttempt._({
    this.id,
    required this.actionDefinitionId,
    required this.participantAuthUserId,
    this.participantAuthUser,
    required this.periodKey,
    required this.idempotencyKey,
    required this.status,
    this.verificationScore,
    this.verifiedRank,
    this.rejectionCode,
    this.rewardOutcome,
    DateTime? startedAt,
    this.submittedAt,
    this.verifiedAt,
    DateTime? updatedAt,
  }) : startedAt = startedAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory ActionAttempt({
    _is.UuidValue? id,
    required _is.UuidValue actionDefinitionId,
    required _is.UuidValue participantAuthUserId,
    _iacs.AuthUser? participantAuthUser,
    required String periodKey,
    required String idempotencyKey,
    required _i8xrgke5.ActionAttemptStatus status,
    double? verificationScore,
    int? verifiedRank,
    String? rejectionCode,
    _ilgf73sw.RewardOutcome? rewardOutcome,
    DateTime? startedAt,
    DateTime? submittedAt,
    DateTime? verifiedAt,
    DateTime? updatedAt,
  }) = _ActionAttemptImpl;

  factory ActionAttempt.fromJson(Map<String, dynamic> jsonSerialization) {
    return ActionAttempt(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      actionDefinitionId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['actionDefinitionId'],
      ),
      participantAuthUserId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['participantAuthUserId'],
      ),
      participantAuthUser: jsonSerialization['participantAuthUser'] == null
          ? null
          : _itf691yl.Protocol().deserialize<_iacs.AuthUser>(
              jsonSerialization['participantAuthUser'],
            ),
      periodKey: jsonSerialization['periodKey'] as String,
      idempotencyKey: jsonSerialization['idempotencyKey'] as String,
      status: _i8xrgke5.ActionAttemptStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      verificationScore: (jsonSerialization['verificationScore'] as num?)
          ?.toDouble(),
      verifiedRank: jsonSerialization['verifiedRank'] as int?,
      rejectionCode: jsonSerialization['rejectionCode'] as String?,
      rewardOutcome: jsonSerialization['rewardOutcome'] == null
          ? null
          : _ilgf73sw.RewardOutcome.fromJson(
              (jsonSerialization['rewardOutcome'] as String),
            ),
      startedAt: jsonSerialization['startedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['startedAt']),
      submittedAt: jsonSerialization['submittedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['submittedAt'],
            ),
      verifiedAt: jsonSerialization['verifiedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['verifiedAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  static final t = ActionAttemptTable();

  static const db = ActionAttemptRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue actionDefinitionId;

  _is.UuidValue participantAuthUserId;

  _iacs.AuthUser? participantAuthUser;

  String periodKey;

  String idempotencyKey;

  _i8xrgke5.ActionAttemptStatus status;

  double? verificationScore;

  int? verifiedRank;

  String? rejectionCode;

  /// Set when a verified attempt met an action with a reward pool: whether it
  /// won a payout, or why not. The proof counts either way.
  _ilgf73sw.RewardOutcome? rewardOutcome;

  DateTime startedAt;

  DateTime? submittedAt;

  DateTime? verifiedAt;

  DateTime updatedAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [ActionAttempt]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ActionAttempt copyWith({
    _is.UuidValue? id,
    _is.UuidValue? actionDefinitionId,
    _is.UuidValue? participantAuthUserId,
    _iacs.AuthUser? participantAuthUser,
    String? periodKey,
    String? idempotencyKey,
    _i8xrgke5.ActionAttemptStatus? status,
    double? verificationScore,
    int? verifiedRank,
    String? rejectionCode,
    _ilgf73sw.RewardOutcome? rewardOutcome,
    DateTime? startedAt,
    DateTime? submittedAt,
    DateTime? verifiedAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActionAttempt',
      if (id != null) 'id': id?.toJson(),
      'actionDefinitionId': actionDefinitionId.toJson(),
      'participantAuthUserId': participantAuthUserId.toJson(),
      if (participantAuthUser != null)
        'participantAuthUser': participantAuthUser?.toJson(),
      'periodKey': periodKey,
      'idempotencyKey': idempotencyKey,
      'status': status.toJson(),
      if (verificationScore != null) 'verificationScore': verificationScore,
      if (verifiedRank != null) 'verifiedRank': verifiedRank,
      if (rejectionCode != null) 'rejectionCode': rejectionCode,
      if (rewardOutcome != null) 'rewardOutcome': rewardOutcome?.toJson(),
      'startedAt': startedAt.toJson(),
      if (submittedAt != null) 'submittedAt': submittedAt?.toJson(),
      if (verifiedAt != null) 'verifiedAt': verifiedAt?.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ActionAttemptInclude include({
    _iacs.AuthUserInclude? participantAuthUser,
  }) {
    return ActionAttemptInclude._(participantAuthUser: participantAuthUser);
  }

  static ActionAttemptIncludeList includeList({
    _is.WhereExpressionBuilder<ActionAttemptTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionAttemptTable>? orderBy,
    _is.OrderByListBuilder<ActionAttemptTable>? orderByList,
    ActionAttemptInclude? include,
  }) {
    return ActionAttemptIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ActionAttempt.t),
      orderByList: orderByList?.call(ActionAttempt.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ActionAttemptImpl extends ActionAttempt {
  _ActionAttemptImpl({
    _is.UuidValue? id,
    required _is.UuidValue actionDefinitionId,
    required _is.UuidValue participantAuthUserId,
    _iacs.AuthUser? participantAuthUser,
    required String periodKey,
    required String idempotencyKey,
    required _i8xrgke5.ActionAttemptStatus status,
    double? verificationScore,
    int? verifiedRank,
    String? rejectionCode,
    _ilgf73sw.RewardOutcome? rewardOutcome,
    DateTime? startedAt,
    DateTime? submittedAt,
    DateTime? verifiedAt,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         actionDefinitionId: actionDefinitionId,
         participantAuthUserId: participantAuthUserId,
         participantAuthUser: participantAuthUser,
         periodKey: periodKey,
         idempotencyKey: idempotencyKey,
         status: status,
         verificationScore: verificationScore,
         verifiedRank: verifiedRank,
         rejectionCode: rejectionCode,
         rewardOutcome: rewardOutcome,
         startedAt: startedAt,
         submittedAt: submittedAt,
         verifiedAt: verifiedAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ActionAttempt]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ActionAttempt copyWith({
    Object? id = _Undefined,
    _is.UuidValue? actionDefinitionId,
    _is.UuidValue? participantAuthUserId,
    Object? participantAuthUser = _Undefined,
    String? periodKey,
    String? idempotencyKey,
    _i8xrgke5.ActionAttemptStatus? status,
    Object? verificationScore = _Undefined,
    Object? verifiedRank = _Undefined,
    Object? rejectionCode = _Undefined,
    Object? rewardOutcome = _Undefined,
    DateTime? startedAt,
    Object? submittedAt = _Undefined,
    Object? verifiedAt = _Undefined,
    DateTime? updatedAt,
  }) {
    return ActionAttempt(
      id: id is _is.UuidValue? ? id : this.id,
      actionDefinitionId: actionDefinitionId ?? this.actionDefinitionId,
      participantAuthUserId:
          participantAuthUserId ?? this.participantAuthUserId,
      participantAuthUser: participantAuthUser is _iacs.AuthUser?
          ? participantAuthUser
          : this.participantAuthUser?.copyWith(),
      periodKey: periodKey ?? this.periodKey,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      status: status ?? this.status,
      verificationScore: verificationScore is double?
          ? verificationScore
          : this.verificationScore,
      verifiedRank: verifiedRank is int? ? verifiedRank : this.verifiedRank,
      rejectionCode: rejectionCode is String?
          ? rejectionCode
          : this.rejectionCode,
      rewardOutcome: rewardOutcome is _ilgf73sw.RewardOutcome?
          ? rewardOutcome
          : this.rewardOutcome,
      startedAt: startedAt ?? this.startedAt,
      submittedAt: submittedAt is DateTime? ? submittedAt : this.submittedAt,
      verifiedAt: verifiedAt is DateTime? ? verifiedAt : this.verifiedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ActionAttemptUpdateTable extends _is.UpdateTable<ActionAttemptTable> {
  ActionAttemptUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> actionDefinitionId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.actionDefinitionId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> participantAuthUserId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.participantAuthUserId,
    value,
  );

  _is.ColumnValue<String, String> periodKey(String value) => _is.ColumnValue(
    table.periodKey,
    value,
  );

  _is.ColumnValue<String, String> idempotencyKey(String value) =>
      _is.ColumnValue(
        table.idempotencyKey,
        value,
      );

  _is.ColumnValue<_i8xrgke5.ActionAttemptStatus, _i8xrgke5.ActionAttemptStatus>
  status(_i8xrgke5.ActionAttemptStatus value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<double, double> verificationScore(double? value) =>
      _is.ColumnValue(
        table.verificationScore,
        value,
      );

  _is.ColumnValue<int, int> verifiedRank(int? value) => _is.ColumnValue(
    table.verifiedRank,
    value,
  );

  _is.ColumnValue<String, String> rejectionCode(String? value) =>
      _is.ColumnValue(
        table.rejectionCode,
        value,
      );

  _is.ColumnValue<_ilgf73sw.RewardOutcome, _ilgf73sw.RewardOutcome>
  rewardOutcome(_ilgf73sw.RewardOutcome? value) => _is.ColumnValue(
    table.rewardOutcome,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> startedAt(DateTime value) =>
      _is.ColumnValue(
        table.startedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> submittedAt(DateTime? value) =>
      _is.ColumnValue(
        table.submittedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> verifiedAt(DateTime? value) =>
      _is.ColumnValue(
        table.verifiedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _is.ColumnValue(
        table.updatedAt,
        value,
      );
}

class ActionAttemptTable extends _is.Table<_is.UuidValue?> {
  ActionAttemptTable({super.tableRelation})
    : super(tableName: 'verily_action_attempt') {
    updateTable = ActionAttemptUpdateTable(this);
    actionDefinitionId = _is.ColumnUuid(
      'actionDefinitionId',
      this,
    );
    participantAuthUserId = _is.ColumnUuid(
      'participantAuthUserId',
      this,
    );
    periodKey = _is.ColumnString(
      'periodKey',
      this,
    );
    idempotencyKey = _is.ColumnString(
      'idempotencyKey',
      this,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
    );
    verificationScore = _is.ColumnDouble(
      'verificationScore',
      this,
    );
    verifiedRank = _is.ColumnInt(
      'verifiedRank',
      this,
    );
    rejectionCode = _is.ColumnString(
      'rejectionCode',
      this,
    );
    rewardOutcome = _is.ColumnEnum(
      'rewardOutcome',
      this,
      _is.EnumSerialization.byName,
    );
    startedAt = _is.ColumnDateTime(
      'startedAt',
      this,
    );
    submittedAt = _is.ColumnDateTime(
      'submittedAt',
      this,
    );
    verifiedAt = _is.ColumnDateTime(
      'verifiedAt',
      this,
    );
    updatedAt = _is.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final ActionAttemptUpdateTable updateTable;

  late final _is.ColumnUuid actionDefinitionId;

  late final _is.ColumnUuid participantAuthUserId;

  _iacs.AuthUserTable? _participantAuthUser;

  late final _is.ColumnString periodKey;

  late final _is.ColumnString idempotencyKey;

  late final _is.ColumnEnum<_i8xrgke5.ActionAttemptStatus> status;

  late final _is.ColumnDouble verificationScore;

  late final _is.ColumnInt verifiedRank;

  late final _is.ColumnString rejectionCode;

  /// Set when a verified attempt met an action with a reward pool: whether it
  /// won a payout, or why not. The proof counts either way.
  late final _is.ColumnEnum<_ilgf73sw.RewardOutcome> rewardOutcome;

  late final _is.ColumnDateTime startedAt;

  late final _is.ColumnDateTime submittedAt;

  late final _is.ColumnDateTime verifiedAt;

  late final _is.ColumnDateTime updatedAt;

  _iacs.AuthUserTable get participantAuthUser {
    if (_participantAuthUser != null) return _participantAuthUser!;
    _participantAuthUser = _is.createRelationTable(
      relationFieldName: 'participantAuthUser',
      field: ActionAttempt.t.participantAuthUserId,
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
    actionDefinitionId,
    participantAuthUserId,
    periodKey,
    idempotencyKey,
    status,
    verificationScore,
    verifiedRank,
    rejectionCode,
    rewardOutcome,
    startedAt,
    submittedAt,
    verifiedAt,
    updatedAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'participantAuthUser') {
      return participantAuthUser;
    }
    return null;
  }
}

class ActionAttemptInclude extends _is.IncludeObject {
  ActionAttemptInclude._({_iacs.AuthUserInclude? participantAuthUser}) {
    _participantAuthUser = participantAuthUser;
  }

  _iacs.AuthUserInclude? _participantAuthUser;

  @override
  Map<String, _is.Include?> get includes => {
    'participantAuthUser': _participantAuthUser,
  };

  @override
  _is.Table<_is.UuidValue?> get table => ActionAttempt.t;
}

class ActionAttemptIncludeList extends _is.IncludeList {
  ActionAttemptIncludeList._({
    _is.WhereExpressionBuilder<ActionAttemptTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ActionAttempt.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => ActionAttempt.t;
}

class ActionAttemptRepository {
  const ActionAttemptRepository._();

  final attachRow = const ActionAttemptAttachRowRepository._();

  /// Returns a list of [ActionAttempt]s matching the given query parameters.
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
  Future<List<ActionAttempt>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionAttemptTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionAttemptTable>? orderBy,
    _is.OrderByListBuilder<ActionAttemptTable>? orderByList,
    _is.Transaction? transaction,
    ActionAttemptInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ActionAttempt>(
      where: where?.call(ActionAttempt.t),
      orderBy: orderBy?.call(ActionAttempt.t),
      orderByList: orderByList?.call(ActionAttempt.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ActionAttempt] matching the given query parameters.
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
  Future<ActionAttempt?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionAttemptTable>? where,
    int? offset,
    _is.OrderByBuilder<ActionAttemptTable>? orderBy,
    _is.OrderByListBuilder<ActionAttemptTable>? orderByList,
    _is.Transaction? transaction,
    ActionAttemptInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ActionAttempt>(
      where: where?.call(ActionAttempt.t),
      orderBy: orderBy?.call(ActionAttempt.t),
      orderByList: orderByList?.call(ActionAttempt.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ActionAttempt] by its [id] or null if no such row exists.
  Future<ActionAttempt?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    ActionAttemptInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ActionAttempt>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ActionAttempt]s in the list and returns the inserted rows.
  ///
  /// The returned [ActionAttempt]s will have their `id` fields set.
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
  Future<List<ActionAttempt>> insert(
    _is.DatabaseSession session,
    List<ActionAttempt> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ActionAttempt>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ActionAttempt] and returns the inserted row.
  ///
  /// The returned [ActionAttempt] will have its `id` field set.
  Future<ActionAttempt> insertRow(
    _is.DatabaseSession session,
    ActionAttempt row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ActionAttempt>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ActionAttempt]s in the list and returns the resulting rows.
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
  /// The returned [ActionAttempt]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionAttempt>> upsert(
    _is.DatabaseSession session,
    List<ActionAttempt> rows, {
    required _is.ColumnSelections<ActionAttemptTable> conflictColumns,
    _is.ColumnSelections<ActionAttemptTable>? updateColumns,
    _is.WhereExpressionBuilder<ActionAttemptTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ActionAttempt>(
      rows,
      conflictColumns: conflictColumns(ActionAttempt.t),
      updateColumns: updateColumns?.call(ActionAttempt.t),
      updateWhere: updateWhere?.call(ActionAttempt.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ActionAttempt] and returns the resulting row.
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
  /// The returned [ActionAttempt] will have its `id` field set.
  Future<ActionAttempt?> upsertRow(
    _is.DatabaseSession session,
    ActionAttempt row, {
    required _is.ColumnSelections<ActionAttemptTable> conflictColumns,
    _is.ColumnSelections<ActionAttemptTable>? updateColumns,
    _is.WhereExpressionBuilder<ActionAttemptTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ActionAttempt>(
      row,
      conflictColumns: conflictColumns(ActionAttempt.t),
      updateColumns: updateColumns?.call(ActionAttempt.t),
      updateWhere: updateWhere?.call(ActionAttempt.t),
      transaction: transaction,
    );
  }

  /// Updates all [ActionAttempt]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionAttempt>> update(
    _is.DatabaseSession session,
    List<ActionAttempt> rows, {
    _is.ColumnSelections<ActionAttemptTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ActionAttempt>(
      rows,
      columns: columns?.call(ActionAttempt.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ActionAttempt]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ActionAttempt> updateRow(
    _is.DatabaseSession session,
    ActionAttempt row, {
    _is.ColumnSelections<ActionAttemptTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ActionAttempt>(
      row,
      columns: columns?.call(ActionAttempt.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ActionAttempt] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ActionAttempt?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<ActionAttemptUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ActionAttempt>(
      id,
      columnValues: columnValues(ActionAttempt.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ActionAttempt]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionAttempt>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ActionAttemptUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ActionAttemptTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionAttemptTable>? orderBy,
    _is.OrderByListBuilder<ActionAttemptTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ActionAttempt>(
      columnValues: columnValues(ActionAttempt.t.updateTable),
      where: where(ActionAttempt.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ActionAttempt.t),
      orderByList: orderByList?.call(ActionAttempt.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ActionAttempt]s in the list and returns the deleted rows.
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
  Future<List<ActionAttempt>> delete(
    _is.DatabaseSession session,
    List<ActionAttempt> rows, {
    _is.OrderByBuilder<ActionAttemptTable>? orderBy,
    _is.OrderByListBuilder<ActionAttemptTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ActionAttempt>(
      rows,
      orderBy: orderBy?.call(ActionAttempt.t),
      orderByList: orderByList?.call(ActionAttempt.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ActionAttempt].
  Future<ActionAttempt> deleteRow(
    _is.DatabaseSession session,
    ActionAttempt row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ActionAttempt>(
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
  Future<List<ActionAttempt>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ActionAttemptTable> where,
    _is.OrderByBuilder<ActionAttemptTable>? orderBy,
    _is.OrderByListBuilder<ActionAttemptTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ActionAttempt>(
      where: where(ActionAttempt.t),
      orderBy: orderBy?.call(ActionAttempt.t),
      orderByList: orderByList?.call(ActionAttempt.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionAttemptTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ActionAttempt>(
      where: where?.call(ActionAttempt.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ActionAttempt] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ActionAttemptTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ActionAttempt>(
      where: where(ActionAttempt.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class ActionAttemptAttachRowRepository {
  const ActionAttemptAttachRowRepository._();

  /// Creates a relation between the given [ActionAttempt] and [AuthUser]
  /// by setting the [ActionAttempt]'s foreign key `participantAuthUserId` to refer to the [AuthUser].
  Future<void> participantAuthUser(
    _is.DatabaseSession session,
    ActionAttempt actionAttempt,
    _iacs.AuthUser participantAuthUser, {
    _is.Transaction? transaction,
  }) async {
    if (actionAttempt.id == null) {
      throw ArgumentError.notNull('actionAttempt.id');
    }
    if (participantAuthUser.id == null) {
      throw ArgumentError.notNull('participantAuthUser.id');
    }

    var $actionAttempt = actionAttempt.copyWith(
      participantAuthUserId: participantAuthUser.id,
    );
    await session.db.updateRow<ActionAttempt>(
      $actionAttempt,
      columns: [ActionAttempt.t.participantAuthUserId],
      transaction: transaction,
    );
  }
}
