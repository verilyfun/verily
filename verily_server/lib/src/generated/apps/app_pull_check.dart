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
import 'package:serverpod/serverpod.dart' as _is;

import '../apps/app_pull_check_status.dart' as _ig9crdfi;

/// One participant's "I did it" on a pull-verified `externalApp` requirement,
/// and the App's answer to Verily's `attempt.verify` calls.
abstract class AppPullCheck
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  AppPullCheck._({
    this.id,
    required this.attemptId,
    required this.requirementId,
    required this.appId,
    required this.eventId,
    this.reference,
    required this.status,
    int? callCount,
    this.nextCallAt,
    this.leaseExpiresAt,
    this.lastErrorCode,
    this.reasonCode,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  }) : callCount = callCount ?? 0;

  factory AppPullCheck({
    _is.UuidValue? id,
    required _is.UuidValue attemptId,
    required _is.UuidValue requirementId,
    required _is.UuidValue appId,
    required String eventId,
    String? reference,
    required _ig9crdfi.AppPullCheckStatus status,
    int? callCount,
    DateTime? nextCallAt,
    DateTime? leaseExpiresAt,
    String? lastErrorCode,
    String? reasonCode,
    required DateTime expiresAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _AppPullCheckImpl;

  factory AppPullCheck.fromJson(Map<String, dynamic> jsonSerialization) {
    return AppPullCheck(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      attemptId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['attemptId'],
      ),
      requirementId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['requirementId'],
      ),
      appId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['appId']),
      eventId: jsonSerialization['eventId'] as String,
      reference: jsonSerialization['reference'] as String?,
      status: _ig9crdfi.AppPullCheckStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      callCount: jsonSerialization['callCount'] as int?,
      nextCallAt: jsonSerialization['nextCallAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['nextCallAt']),
      leaseExpiresAt: jsonSerialization['leaseExpiresAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['leaseExpiresAt'],
            ),
      lastErrorCode: jsonSerialization['lastErrorCode'] as String?,
      reasonCode: jsonSerialization['reasonCode'] as String?,
      expiresAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = AppPullCheckTable();

  static const db = AppPullCheckRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue attemptId;

  _is.UuidValue requirementId;

  _is.UuidValue appId;

  /// The `vev_` id sent with every call for this check.
  String eventId;

  /// Optional text the participant typed, validated server-side.
  String? reference;

  _ig9crdfi.AppPullCheckStatus status;

  int callCount;

  DateTime? nextCallAt;

  DateTime? leaseExpiresAt;

  String? lastErrorCode;

  /// The App's short reason code from its last decisive answer.
  String? reasonCode;

  DateTime expiresAt;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [AppPullCheck]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AppPullCheck copyWith({
    _is.UuidValue? id,
    _is.UuidValue? attemptId,
    _is.UuidValue? requirementId,
    _is.UuidValue? appId,
    String? eventId,
    String? reference,
    _ig9crdfi.AppPullCheckStatus? status,
    int? callCount,
    DateTime? nextCallAt,
    DateTime? leaseExpiresAt,
    String? lastErrorCode,
    String? reasonCode,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AppPullCheck',
      if (id != null) 'id': id?.toJson(),
      'attemptId': attemptId.toJson(),
      'requirementId': requirementId.toJson(),
      'appId': appId.toJson(),
      'eventId': eventId,
      if (reference != null) 'reference': reference,
      'status': status.toJson(),
      'callCount': callCount,
      if (nextCallAt != null) 'nextCallAt': nextCallAt?.toJson(),
      if (leaseExpiresAt != null) 'leaseExpiresAt': leaseExpiresAt?.toJson(),
      if (lastErrorCode != null) 'lastErrorCode': lastErrorCode,
      if (reasonCode != null) 'reasonCode': reasonCode,
      'expiresAt': expiresAt.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static AppPullCheckInclude include() {
    return AppPullCheckInclude._();
  }

  static AppPullCheckIncludeList includeList({
    _is.WhereExpressionBuilder<AppPullCheckTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AppPullCheckTable>? orderBy,
    _is.OrderByListBuilder<AppPullCheckTable>? orderByList,
    AppPullCheckInclude? include,
  }) {
    return AppPullCheckIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AppPullCheck.t),
      orderByList: orderByList?.call(AppPullCheck.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AppPullCheckImpl extends AppPullCheck {
  _AppPullCheckImpl({
    _is.UuidValue? id,
    required _is.UuidValue attemptId,
    required _is.UuidValue requirementId,
    required _is.UuidValue appId,
    required String eventId,
    String? reference,
    required _ig9crdfi.AppPullCheckStatus status,
    int? callCount,
    DateTime? nextCallAt,
    DateTime? leaseExpiresAt,
    String? lastErrorCode,
    String? reasonCode,
    required DateTime expiresAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         attemptId: attemptId,
         requirementId: requirementId,
         appId: appId,
         eventId: eventId,
         reference: reference,
         status: status,
         callCount: callCount,
         nextCallAt: nextCallAt,
         leaseExpiresAt: leaseExpiresAt,
         lastErrorCode: lastErrorCode,
         reasonCode: reasonCode,
         expiresAt: expiresAt,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [AppPullCheck]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AppPullCheck copyWith({
    Object? id = _Undefined,
    _is.UuidValue? attemptId,
    _is.UuidValue? requirementId,
    _is.UuidValue? appId,
    String? eventId,
    Object? reference = _Undefined,
    _ig9crdfi.AppPullCheckStatus? status,
    int? callCount,
    Object? nextCallAt = _Undefined,
    Object? leaseExpiresAt = _Undefined,
    Object? lastErrorCode = _Undefined,
    Object? reasonCode = _Undefined,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppPullCheck(
      id: id is _is.UuidValue? ? id : this.id,
      attemptId: attemptId ?? this.attemptId,
      requirementId: requirementId ?? this.requirementId,
      appId: appId ?? this.appId,
      eventId: eventId ?? this.eventId,
      reference: reference is String? ? reference : this.reference,
      status: status ?? this.status,
      callCount: callCount ?? this.callCount,
      nextCallAt: nextCallAt is DateTime? ? nextCallAt : this.nextCallAt,
      leaseExpiresAt: leaseExpiresAt is DateTime?
          ? leaseExpiresAt
          : this.leaseExpiresAt,
      lastErrorCode: lastErrorCode is String?
          ? lastErrorCode
          : this.lastErrorCode,
      reasonCode: reasonCode is String? ? reasonCode : this.reasonCode,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AppPullCheckUpdateTable extends _is.UpdateTable<AppPullCheckTable> {
  AppPullCheckUpdateTable(super.table);

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

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> appId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.appId,
        value,
      );

  _is.ColumnValue<String, String> eventId(String value) => _is.ColumnValue(
    table.eventId,
    value,
  );

  _is.ColumnValue<String, String> reference(String? value) => _is.ColumnValue(
    table.reference,
    value,
  );

  _is.ColumnValue<_ig9crdfi.AppPullCheckStatus, _ig9crdfi.AppPullCheckStatus>
  status(_ig9crdfi.AppPullCheckStatus value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<int, int> callCount(int value) => _is.ColumnValue(
    table.callCount,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> nextCallAt(DateTime? value) =>
      _is.ColumnValue(
        table.nextCallAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> leaseExpiresAt(DateTime? value) =>
      _is.ColumnValue(
        table.leaseExpiresAt,
        value,
      );

  _is.ColumnValue<String, String> lastErrorCode(String? value) =>
      _is.ColumnValue(
        table.lastErrorCode,
        value,
      );

  _is.ColumnValue<String, String> reasonCode(String? value) => _is.ColumnValue(
    table.reasonCode,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> expiresAt(DateTime value) =>
      _is.ColumnValue(
        table.expiresAt,
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

class AppPullCheckTable extends _is.Table<_is.UuidValue?> {
  AppPullCheckTable({super.tableRelation})
    : super(tableName: 'verily_app_pull_check') {
    updateTable = AppPullCheckUpdateTable(this);
    attemptId = _is.ColumnUuid(
      'attemptId',
      this,
    );
    requirementId = _is.ColumnUuid(
      'requirementId',
      this,
    );
    appId = _is.ColumnUuid(
      'appId',
      this,
    );
    eventId = _is.ColumnString(
      'eventId',
      this,
    );
    reference = _is.ColumnString(
      'reference',
      this,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
    );
    callCount = _is.ColumnInt(
      'callCount',
      this,
      hasDefault: true,
    );
    nextCallAt = _is.ColumnDateTime(
      'nextCallAt',
      this,
    );
    leaseExpiresAt = _is.ColumnDateTime(
      'leaseExpiresAt',
      this,
    );
    lastErrorCode = _is.ColumnString(
      'lastErrorCode',
      this,
    );
    reasonCode = _is.ColumnString(
      'reasonCode',
      this,
    );
    expiresAt = _is.ColumnDateTime(
      'expiresAt',
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

  late final AppPullCheckUpdateTable updateTable;

  late final _is.ColumnUuid attemptId;

  late final _is.ColumnUuid requirementId;

  late final _is.ColumnUuid appId;

  /// The `vev_` id sent with every call for this check.
  late final _is.ColumnString eventId;

  /// Optional text the participant typed, validated server-side.
  late final _is.ColumnString reference;

  late final _is.ColumnEnum<_ig9crdfi.AppPullCheckStatus> status;

  late final _is.ColumnInt callCount;

  late final _is.ColumnDateTime nextCallAt;

  late final _is.ColumnDateTime leaseExpiresAt;

  late final _is.ColumnString lastErrorCode;

  /// The App's short reason code from its last decisive answer.
  late final _is.ColumnString reasonCode;

  late final _is.ColumnDateTime expiresAt;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  @override
  List<_is.Column> get columns => [
    id,
    attemptId,
    requirementId,
    appId,
    eventId,
    reference,
    status,
    callCount,
    nextCallAt,
    leaseExpiresAt,
    lastErrorCode,
    reasonCode,
    expiresAt,
    createdAt,
    updatedAt,
  ];
}

class AppPullCheckInclude extends _is.IncludeObject {
  AppPullCheckInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<_is.UuidValue?> get table => AppPullCheck.t;
}

class AppPullCheckIncludeList extends _is.IncludeList {
  AppPullCheckIncludeList._({
    _is.WhereExpressionBuilder<AppPullCheckTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AppPullCheck.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => AppPullCheck.t;
}

class AppPullCheckRepository {
  const AppPullCheckRepository._();

  /// Returns a list of [AppPullCheck]s matching the given query parameters.
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
  Future<List<AppPullCheck>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AppPullCheckTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AppPullCheckTable>? orderBy,
    _is.OrderByListBuilder<AppPullCheckTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<AppPullCheck>(
      where: where?.call(AppPullCheck.t),
      orderBy: orderBy?.call(AppPullCheck.t),
      orderByList: orderByList?.call(AppPullCheck.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [AppPullCheck] matching the given query parameters.
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
  Future<AppPullCheck?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AppPullCheckTable>? where,
    int? offset,
    _is.OrderByBuilder<AppPullCheckTable>? orderBy,
    _is.OrderByListBuilder<AppPullCheckTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<AppPullCheck>(
      where: where?.call(AppPullCheck.t),
      orderBy: orderBy?.call(AppPullCheck.t),
      orderByList: orderByList?.call(AppPullCheck.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [AppPullCheck] by its [id] or null if no such row exists.
  Future<AppPullCheck?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<AppPullCheck>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [AppPullCheck]s in the list and returns the inserted rows.
  ///
  /// The returned [AppPullCheck]s will have their `id` fields set.
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
  Future<List<AppPullCheck>> insert(
    _is.DatabaseSession session,
    List<AppPullCheck> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<AppPullCheck>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [AppPullCheck] and returns the inserted row.
  ///
  /// The returned [AppPullCheck] will have its `id` field set.
  Future<AppPullCheck> insertRow(
    _is.DatabaseSession session,
    AppPullCheck row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<AppPullCheck>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [AppPullCheck]s in the list and returns the resulting rows.
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
  /// The returned [AppPullCheck]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AppPullCheck>> upsert(
    _is.DatabaseSession session,
    List<AppPullCheck> rows, {
    required _is.ColumnSelections<AppPullCheckTable> conflictColumns,
    _is.ColumnSelections<AppPullCheckTable>? updateColumns,
    _is.WhereExpressionBuilder<AppPullCheckTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<AppPullCheck>(
      rows,
      conflictColumns: conflictColumns(AppPullCheck.t),
      updateColumns: updateColumns?.call(AppPullCheck.t),
      updateWhere: updateWhere?.call(AppPullCheck.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [AppPullCheck] and returns the resulting row.
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
  /// The returned [AppPullCheck] will have its `id` field set.
  Future<AppPullCheck?> upsertRow(
    _is.DatabaseSession session,
    AppPullCheck row, {
    required _is.ColumnSelections<AppPullCheckTable> conflictColumns,
    _is.ColumnSelections<AppPullCheckTable>? updateColumns,
    _is.WhereExpressionBuilder<AppPullCheckTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<AppPullCheck>(
      row,
      conflictColumns: conflictColumns(AppPullCheck.t),
      updateColumns: updateColumns?.call(AppPullCheck.t),
      updateWhere: updateWhere?.call(AppPullCheck.t),
      transaction: transaction,
    );
  }

  /// Updates all [AppPullCheck]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AppPullCheck>> update(
    _is.DatabaseSession session,
    List<AppPullCheck> rows, {
    _is.ColumnSelections<AppPullCheckTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<AppPullCheck>(
      rows,
      columns: columns?.call(AppPullCheck.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [AppPullCheck]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AppPullCheck> updateRow(
    _is.DatabaseSession session,
    AppPullCheck row, {
    _is.ColumnSelections<AppPullCheckTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<AppPullCheck>(
      row,
      columns: columns?.call(AppPullCheck.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AppPullCheck] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AppPullCheck?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<AppPullCheckUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<AppPullCheck>(
      id,
      columnValues: columnValues(AppPullCheck.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AppPullCheck]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AppPullCheck>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<AppPullCheckUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<AppPullCheckTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AppPullCheckTable>? orderBy,
    _is.OrderByListBuilder<AppPullCheckTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<AppPullCheck>(
      columnValues: columnValues(AppPullCheck.t.updateTable),
      where: where(AppPullCheck.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AppPullCheck.t),
      orderByList: orderByList?.call(AppPullCheck.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [AppPullCheck]s in the list and returns the deleted rows.
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
  Future<List<AppPullCheck>> delete(
    _is.DatabaseSession session,
    List<AppPullCheck> rows, {
    _is.OrderByBuilder<AppPullCheckTable>? orderBy,
    _is.OrderByListBuilder<AppPullCheckTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<AppPullCheck>(
      rows,
      orderBy: orderBy?.call(AppPullCheck.t),
      orderByList: orderByList?.call(AppPullCheck.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [AppPullCheck].
  Future<AppPullCheck> deleteRow(
    _is.DatabaseSession session,
    AppPullCheck row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AppPullCheck>(
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
  Future<List<AppPullCheck>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AppPullCheckTable> where,
    _is.OrderByBuilder<AppPullCheckTable>? orderBy,
    _is.OrderByListBuilder<AppPullCheckTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<AppPullCheck>(
      where: where(AppPullCheck.t),
      orderBy: orderBy?.call(AppPullCheck.t),
      orderByList: orderByList?.call(AppPullCheck.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AppPullCheckTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<AppPullCheck>(
      where: where?.call(AppPullCheck.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [AppPullCheck] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AppPullCheckTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<AppPullCheck>(
      where: where(AppPullCheck.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
