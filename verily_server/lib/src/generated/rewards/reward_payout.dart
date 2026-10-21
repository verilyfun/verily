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

import '../rewards/reward_payout_status.dart' as _i8tvbfry;

/// One fixed payout reserved for one verified attempt, under the pool row
/// lock, so two completions never share an index. The row is also the durable
/// release job: a retry of the same index is safe because the escrow pays each
/// index at most once.
abstract class RewardPayout
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  RewardPayout._({
    this.id,
    required this.poolId,
    required this.attemptId,
    required this.recipientAuthUserId,
    this.recipientAuthUser,
    required this.payoutIndex,
    required this.amount,
    this.recipientWallet,
    required this.status,
    this.releaseSignature,
    int? attemptCount,
    this.lastErrorCode,
    this.releaseStartedAt,
    this.releasedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : attemptCount = attemptCount ?? 0,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory RewardPayout({
    _is.UuidValue? id,
    required _is.UuidValue poolId,
    required _is.UuidValue attemptId,
    required _is.UuidValue recipientAuthUserId,
    _iacs.AuthUser? recipientAuthUser,
    required int payoutIndex,
    required int amount,
    String? recipientWallet,
    required _i8tvbfry.RewardPayoutStatus status,
    String? releaseSignature,
    int? attemptCount,
    String? lastErrorCode,
    DateTime? releaseStartedAt,
    DateTime? releasedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _RewardPayoutImpl;

  factory RewardPayout.fromJson(Map<String, dynamic> jsonSerialization) {
    return RewardPayout(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      poolId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['poolId']),
      attemptId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['attemptId'],
      ),
      recipientAuthUserId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['recipientAuthUserId'],
      ),
      recipientAuthUser: jsonSerialization['recipientAuthUser'] == null
          ? null
          : _itf691yl.Protocol().deserialize<_iacs.AuthUser>(
              jsonSerialization['recipientAuthUser'],
            ),
      payoutIndex: jsonSerialization['payoutIndex'] as int,
      amount: jsonSerialization['amount'] as int,
      recipientWallet: jsonSerialization['recipientWallet'] as String?,
      status: _i8tvbfry.RewardPayoutStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      releaseSignature: jsonSerialization['releaseSignature'] as String?,
      attemptCount: jsonSerialization['attemptCount'] as int?,
      lastErrorCode: jsonSerialization['lastErrorCode'] as String?,
      releaseStartedAt: jsonSerialization['releaseStartedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['releaseStartedAt'],
            ),
      releasedAt: jsonSerialization['releasedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['releasedAt']),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  static final t = RewardPayoutTable();

  static const db = RewardPayoutRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue poolId;

  _is.UuidValue attemptId;

  _is.UuidValue recipientAuthUserId;

  _iacs.AuthUser? recipientAuthUser;

  int payoutIndex;

  int amount;

  /// Frozen when a release starts; every retry pays the same wallet.
  String? recipientWallet;

  _i8tvbfry.RewardPayoutStatus status;

  String? releaseSignature;

  int attemptCount;

  /// Stable code for operators; never raw provider text.
  String? lastErrorCode;

  DateTime? releaseStartedAt;

  DateTime? releasedAt;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [RewardPayout]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  RewardPayout copyWith({
    _is.UuidValue? id,
    _is.UuidValue? poolId,
    _is.UuidValue? attemptId,
    _is.UuidValue? recipientAuthUserId,
    _iacs.AuthUser? recipientAuthUser,
    int? payoutIndex,
    int? amount,
    String? recipientWallet,
    _i8tvbfry.RewardPayoutStatus? status,
    String? releaseSignature,
    int? attemptCount,
    String? lastErrorCode,
    DateTime? releaseStartedAt,
    DateTime? releasedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RewardPayout',
      if (id != null) 'id': id?.toJson(),
      'poolId': poolId.toJson(),
      'attemptId': attemptId.toJson(),
      'recipientAuthUserId': recipientAuthUserId.toJson(),
      if (recipientAuthUser != null)
        'recipientAuthUser': recipientAuthUser?.toJson(),
      'payoutIndex': payoutIndex,
      'amount': amount,
      if (recipientWallet != null) 'recipientWallet': recipientWallet,
      'status': status.toJson(),
      if (releaseSignature != null) 'releaseSignature': releaseSignature,
      'attemptCount': attemptCount,
      if (lastErrorCode != null) 'lastErrorCode': lastErrorCode,
      if (releaseStartedAt != null)
        'releaseStartedAt': releaseStartedAt?.toJson(),
      if (releasedAt != null) 'releasedAt': releasedAt?.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static RewardPayoutInclude include({
    _iacs.AuthUserInclude? recipientAuthUser,
  }) {
    return RewardPayoutInclude._(recipientAuthUser: recipientAuthUser);
  }

  static RewardPayoutIncludeList includeList({
    _is.WhereExpressionBuilder<RewardPayoutTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RewardPayoutTable>? orderBy,
    _is.OrderByListBuilder<RewardPayoutTable>? orderByList,
    RewardPayoutInclude? include,
  }) {
    return RewardPayoutIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(RewardPayout.t),
      orderByList: orderByList?.call(RewardPayout.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RewardPayoutImpl extends RewardPayout {
  _RewardPayoutImpl({
    _is.UuidValue? id,
    required _is.UuidValue poolId,
    required _is.UuidValue attemptId,
    required _is.UuidValue recipientAuthUserId,
    _iacs.AuthUser? recipientAuthUser,
    required int payoutIndex,
    required int amount,
    String? recipientWallet,
    required _i8tvbfry.RewardPayoutStatus status,
    String? releaseSignature,
    int? attemptCount,
    String? lastErrorCode,
    DateTime? releaseStartedAt,
    DateTime? releasedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         poolId: poolId,
         attemptId: attemptId,
         recipientAuthUserId: recipientAuthUserId,
         recipientAuthUser: recipientAuthUser,
         payoutIndex: payoutIndex,
         amount: amount,
         recipientWallet: recipientWallet,
         status: status,
         releaseSignature: releaseSignature,
         attemptCount: attemptCount,
         lastErrorCode: lastErrorCode,
         releaseStartedAt: releaseStartedAt,
         releasedAt: releasedAt,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [RewardPayout]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  RewardPayout copyWith({
    Object? id = _Undefined,
    _is.UuidValue? poolId,
    _is.UuidValue? attemptId,
    _is.UuidValue? recipientAuthUserId,
    Object? recipientAuthUser = _Undefined,
    int? payoutIndex,
    int? amount,
    Object? recipientWallet = _Undefined,
    _i8tvbfry.RewardPayoutStatus? status,
    Object? releaseSignature = _Undefined,
    int? attemptCount,
    Object? lastErrorCode = _Undefined,
    Object? releaseStartedAt = _Undefined,
    Object? releasedAt = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RewardPayout(
      id: id is _is.UuidValue? ? id : this.id,
      poolId: poolId ?? this.poolId,
      attemptId: attemptId ?? this.attemptId,
      recipientAuthUserId: recipientAuthUserId ?? this.recipientAuthUserId,
      recipientAuthUser: recipientAuthUser is _iacs.AuthUser?
          ? recipientAuthUser
          : this.recipientAuthUser?.copyWith(),
      payoutIndex: payoutIndex ?? this.payoutIndex,
      amount: amount ?? this.amount,
      recipientWallet: recipientWallet is String?
          ? recipientWallet
          : this.recipientWallet,
      status: status ?? this.status,
      releaseSignature: releaseSignature is String?
          ? releaseSignature
          : this.releaseSignature,
      attemptCount: attemptCount ?? this.attemptCount,
      lastErrorCode: lastErrorCode is String?
          ? lastErrorCode
          : this.lastErrorCode,
      releaseStartedAt: releaseStartedAt is DateTime?
          ? releaseStartedAt
          : this.releaseStartedAt,
      releasedAt: releasedAt is DateTime? ? releasedAt : this.releasedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class RewardPayoutUpdateTable extends _is.UpdateTable<RewardPayoutTable> {
  RewardPayoutUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> poolId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.poolId,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> attemptId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.attemptId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> recipientAuthUserId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.recipientAuthUserId,
    value,
  );

  _is.ColumnValue<int, int> payoutIndex(int value) => _is.ColumnValue(
    table.payoutIndex,
    value,
  );

  _is.ColumnValue<int, int> amount(int value) => _is.ColumnValue(
    table.amount,
    value,
  );

  _is.ColumnValue<String, String> recipientWallet(String? value) =>
      _is.ColumnValue(
        table.recipientWallet,
        value,
      );

  _is.ColumnValue<_i8tvbfry.RewardPayoutStatus, _i8tvbfry.RewardPayoutStatus>
  status(_i8tvbfry.RewardPayoutStatus value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<String, String> releaseSignature(String? value) =>
      _is.ColumnValue(
        table.releaseSignature,
        value,
      );

  _is.ColumnValue<int, int> attemptCount(int value) => _is.ColumnValue(
    table.attemptCount,
    value,
  );

  _is.ColumnValue<String, String> lastErrorCode(String? value) =>
      _is.ColumnValue(
        table.lastErrorCode,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> releaseStartedAt(DateTime? value) =>
      _is.ColumnValue(
        table.releaseStartedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> releasedAt(DateTime? value) =>
      _is.ColumnValue(
        table.releasedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _is.ColumnValue(
        table.updatedAt,
        value,
      );
}

class RewardPayoutTable extends _is.Table<_is.UuidValue?> {
  RewardPayoutTable({super.tableRelation})
    : super(tableName: 'verily_reward_payout') {
    updateTable = RewardPayoutUpdateTable(this);
    poolId = _is.ColumnUuid(
      'poolId',
      this,
    );
    attemptId = _is.ColumnUuid(
      'attemptId',
      this,
    );
    recipientAuthUserId = _is.ColumnUuid(
      'recipientAuthUserId',
      this,
    );
    payoutIndex = _is.ColumnInt(
      'payoutIndex',
      this,
    );
    amount = _is.ColumnInt(
      'amount',
      this,
    );
    recipientWallet = _is.ColumnString(
      'recipientWallet',
      this,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
    );
    releaseSignature = _is.ColumnString(
      'releaseSignature',
      this,
    );
    attemptCount = _is.ColumnInt(
      'attemptCount',
      this,
      hasDefault: true,
    );
    lastErrorCode = _is.ColumnString(
      'lastErrorCode',
      this,
    );
    releaseStartedAt = _is.ColumnDateTime(
      'releaseStartedAt',
      this,
    );
    releasedAt = _is.ColumnDateTime(
      'releasedAt',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    updatedAt = _is.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final RewardPayoutUpdateTable updateTable;

  late final _is.ColumnUuid poolId;

  late final _is.ColumnUuid attemptId;

  late final _is.ColumnUuid recipientAuthUserId;

  _iacs.AuthUserTable? _recipientAuthUser;

  late final _is.ColumnInt payoutIndex;

  late final _is.ColumnInt amount;

  /// Frozen when a release starts; every retry pays the same wallet.
  late final _is.ColumnString recipientWallet;

  late final _is.ColumnEnum<_i8tvbfry.RewardPayoutStatus> status;

  late final _is.ColumnString releaseSignature;

  late final _is.ColumnInt attemptCount;

  /// Stable code for operators; never raw provider text.
  late final _is.ColumnString lastErrorCode;

  late final _is.ColumnDateTime releaseStartedAt;

  late final _is.ColumnDateTime releasedAt;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  _iacs.AuthUserTable get recipientAuthUser {
    if (_recipientAuthUser != null) return _recipientAuthUser!;
    _recipientAuthUser = _is.createRelationTable(
      relationFieldName: 'recipientAuthUser',
      field: RewardPayout.t.recipientAuthUserId,
      foreignField: _iacs.AuthUser.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iacs.AuthUserTable(tableRelation: foreignTableRelation),
    );
    return _recipientAuthUser!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    poolId,
    attemptId,
    recipientAuthUserId,
    payoutIndex,
    amount,
    recipientWallet,
    status,
    releaseSignature,
    attemptCount,
    lastErrorCode,
    releaseStartedAt,
    releasedAt,
    createdAt,
    updatedAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'recipientAuthUser') {
      return recipientAuthUser;
    }
    return null;
  }
}

class RewardPayoutInclude extends _is.IncludeObject {
  RewardPayoutInclude._({_iacs.AuthUserInclude? recipientAuthUser}) {
    _recipientAuthUser = recipientAuthUser;
  }

  _iacs.AuthUserInclude? _recipientAuthUser;

  @override
  Map<String, _is.Include?> get includes => {
    'recipientAuthUser': _recipientAuthUser,
  };

  @override
  _is.Table<_is.UuidValue?> get table => RewardPayout.t;
}

class RewardPayoutIncludeList extends _is.IncludeList {
  RewardPayoutIncludeList._({
    _is.WhereExpressionBuilder<RewardPayoutTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(RewardPayout.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => RewardPayout.t;
}

class RewardPayoutRepository {
  const RewardPayoutRepository._();

  final attachRow = const RewardPayoutAttachRowRepository._();

  /// Returns a list of [RewardPayout]s matching the given query parameters.
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
  Future<List<RewardPayout>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RewardPayoutTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RewardPayoutTable>? orderBy,
    _is.OrderByListBuilder<RewardPayoutTable>? orderByList,
    _is.Transaction? transaction,
    RewardPayoutInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<RewardPayout>(
      where: where?.call(RewardPayout.t),
      orderBy: orderBy?.call(RewardPayout.t),
      orderByList: orderByList?.call(RewardPayout.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [RewardPayout] matching the given query parameters.
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
  Future<RewardPayout?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RewardPayoutTable>? where,
    int? offset,
    _is.OrderByBuilder<RewardPayoutTable>? orderBy,
    _is.OrderByListBuilder<RewardPayoutTable>? orderByList,
    _is.Transaction? transaction,
    RewardPayoutInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<RewardPayout>(
      where: where?.call(RewardPayout.t),
      orderBy: orderBy?.call(RewardPayout.t),
      orderByList: orderByList?.call(RewardPayout.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [RewardPayout] by its [id] or null if no such row exists.
  Future<RewardPayout?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    RewardPayoutInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<RewardPayout>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [RewardPayout]s in the list and returns the inserted rows.
  ///
  /// The returned [RewardPayout]s will have their `id` fields set.
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
  Future<List<RewardPayout>> insert(
    _is.DatabaseSession session,
    List<RewardPayout> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<RewardPayout>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [RewardPayout] and returns the inserted row.
  ///
  /// The returned [RewardPayout] will have its `id` field set.
  Future<RewardPayout> insertRow(
    _is.DatabaseSession session,
    RewardPayout row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<RewardPayout>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [RewardPayout]s in the list and returns the resulting rows.
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
  /// The returned [RewardPayout]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<RewardPayout>> upsert(
    _is.DatabaseSession session,
    List<RewardPayout> rows, {
    required _is.ColumnSelections<RewardPayoutTable> conflictColumns,
    _is.ColumnSelections<RewardPayoutTable>? updateColumns,
    _is.WhereExpressionBuilder<RewardPayoutTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<RewardPayout>(
      rows,
      conflictColumns: conflictColumns(RewardPayout.t),
      updateColumns: updateColumns?.call(RewardPayout.t),
      updateWhere: updateWhere?.call(RewardPayout.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [RewardPayout] and returns the resulting row.
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
  /// The returned [RewardPayout] will have its `id` field set.
  Future<RewardPayout?> upsertRow(
    _is.DatabaseSession session,
    RewardPayout row, {
    required _is.ColumnSelections<RewardPayoutTable> conflictColumns,
    _is.ColumnSelections<RewardPayoutTable>? updateColumns,
    _is.WhereExpressionBuilder<RewardPayoutTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<RewardPayout>(
      row,
      conflictColumns: conflictColumns(RewardPayout.t),
      updateColumns: updateColumns?.call(RewardPayout.t),
      updateWhere: updateWhere?.call(RewardPayout.t),
      transaction: transaction,
    );
  }

  /// Updates all [RewardPayout]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<RewardPayout>> update(
    _is.DatabaseSession session,
    List<RewardPayout> rows, {
    _is.ColumnSelections<RewardPayoutTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<RewardPayout>(
      rows,
      columns: columns?.call(RewardPayout.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [RewardPayout]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<RewardPayout> updateRow(
    _is.DatabaseSession session,
    RewardPayout row, {
    _is.ColumnSelections<RewardPayoutTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<RewardPayout>(
      row,
      columns: columns?.call(RewardPayout.t),
      transaction: transaction,
    );
  }

  /// Updates a single [RewardPayout] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<RewardPayout?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<RewardPayoutUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<RewardPayout>(
      id,
      columnValues: columnValues(RewardPayout.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [RewardPayout]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<RewardPayout>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<RewardPayoutUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<RewardPayoutTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RewardPayoutTable>? orderBy,
    _is.OrderByListBuilder<RewardPayoutTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<RewardPayout>(
      columnValues: columnValues(RewardPayout.t.updateTable),
      where: where(RewardPayout.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(RewardPayout.t),
      orderByList: orderByList?.call(RewardPayout.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [RewardPayout]s in the list and returns the deleted rows.
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
  Future<List<RewardPayout>> delete(
    _is.DatabaseSession session,
    List<RewardPayout> rows, {
    _is.OrderByBuilder<RewardPayoutTable>? orderBy,
    _is.OrderByListBuilder<RewardPayoutTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<RewardPayout>(
      rows,
      orderBy: orderBy?.call(RewardPayout.t),
      orderByList: orderByList?.call(RewardPayout.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [RewardPayout].
  Future<RewardPayout> deleteRow(
    _is.DatabaseSession session,
    RewardPayout row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<RewardPayout>(
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
  Future<List<RewardPayout>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<RewardPayoutTable> where,
    _is.OrderByBuilder<RewardPayoutTable>? orderBy,
    _is.OrderByListBuilder<RewardPayoutTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<RewardPayout>(
      where: where(RewardPayout.t),
      orderBy: orderBy?.call(RewardPayout.t),
      orderByList: orderByList?.call(RewardPayout.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RewardPayoutTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<RewardPayout>(
      where: where?.call(RewardPayout.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [RewardPayout] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<RewardPayoutTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<RewardPayout>(
      where: where(RewardPayout.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class RewardPayoutAttachRowRepository {
  const RewardPayoutAttachRowRepository._();

  /// Creates a relation between the given [RewardPayout] and [AuthUser]
  /// by setting the [RewardPayout]'s foreign key `recipientAuthUserId` to refer to the [AuthUser].
  Future<void> recipientAuthUser(
    _is.DatabaseSession session,
    RewardPayout rewardPayout,
    _iacs.AuthUser recipientAuthUser, {
    _is.Transaction? transaction,
  }) async {
    if (rewardPayout.id == null) {
      throw ArgumentError.notNull('rewardPayout.id');
    }
    if (recipientAuthUser.id == null) {
      throw ArgumentError.notNull('recipientAuthUser.id');
    }

    var $rewardPayout = rewardPayout.copyWith(
      recipientAuthUserId: recipientAuthUser.id,
    );
    await session.db.updateRow<RewardPayout>(
      $rewardPayout,
      columns: [RewardPayout.t.recipientAuthUserId],
      transaction: transaction,
    );
  }
}
