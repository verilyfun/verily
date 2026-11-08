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
import 'dart:async' as _ida;

import 'package:serverpod/serverpod.dart' as _is;

import '../../apps/webhooks/app_event_status.dart' as _i9zhna0j;

/// Durable outbox for one signed event to one App. The body is stored exactly
/// as first signed, so every retry sends identical bytes with the same id.
abstract class AppEvent
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  AppEvent._({
    this.id,
    required this.appId,
    required this.eventId,
    required this.type,
    required this.dedupeKey,
    required this.body,
    required this.status,
    int? attemptCount,
    required this.nextAttemptAt,
    this.leaseExpiresAt,
    this.lastStatusCode,
    this.lastErrorCode,
    this.deliveredAt,
    required this.createdAt,
    required this.updatedAt,
  }) : attemptCount = attemptCount ?? 0;

  factory AppEvent({
    _is.UuidValue? id,
    required _is.UuidValue appId,
    required String eventId,
    required String type,
    required String dedupeKey,
    required String body,
    required _i9zhna0j.AppEventStatus status,
    int? attemptCount,
    required DateTime nextAttemptAt,
    DateTime? leaseExpiresAt,
    int? lastStatusCode,
    String? lastErrorCode,
    DateTime? deliveredAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _AppEventImpl;

  factory AppEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return AppEvent(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      appId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['appId']),
      eventId: jsonSerialization['eventId'] as String,
      type: jsonSerialization['type'] as String,
      dedupeKey: jsonSerialization['dedupeKey'] as String,
      body: jsonSerialization['body'] as String,
      status: _i9zhna0j.AppEventStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      attemptCount: jsonSerialization['attemptCount'] as int?,
      nextAttemptAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['nextAttemptAt'],
      ),
      leaseExpiresAt: jsonSerialization['leaseExpiresAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['leaseExpiresAt'],
            ),
      lastStatusCode: jsonSerialization['lastStatusCode'] as int?,
      lastErrorCode: jsonSerialization['lastErrorCode'] as String?,
      deliveredAt: jsonSerialization['deliveredAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['deliveredAt'],
            ),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = AppEventTable();

  static const db = AppEventRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue appId;

  /// Public event id (`vev_` + 22 base64url characters), also in the body.
  String eventId;

  /// Wire type, for example `attempt.verified`.
  String type;

  /// Server-owned idempotency key: one event per fact.
  String dedupeKey;

  String body;

  _i9zhna0j.AppEventStatus status;

  int attemptCount;

  DateTime nextAttemptAt;

  DateTime? leaseExpiresAt;

  int? lastStatusCode;

  String? lastErrorCode;

  DateTime? deliveredAt;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [AppEvent]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AppEvent copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? appId,
    String? eventId,
    String? type,
    String? dedupeKey,
    String? body,
    _i9zhna0j.AppEventStatus? status,
    int? attemptCount,
    DateTime? nextAttemptAt,
    DateTime? leaseExpiresAt = const _is.$UndefinedDateTime(),
    int? lastStatusCode,
    String? lastErrorCode,
    DateTime? deliveredAt = const _is.$UndefinedDateTime(),
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AppEvent',
      if (id != null) 'id': id?.toJson(),
      'appId': appId.toJson(),
      'eventId': eventId,
      'type': type,
      'dedupeKey': dedupeKey,
      'body': body,
      'status': status.toJson(),
      'attemptCount': attemptCount,
      'nextAttemptAt': nextAttemptAt.toJson(),
      if (leaseExpiresAt != null) 'leaseExpiresAt': leaseExpiresAt?.toJson(),
      if (lastStatusCode != null) 'lastStatusCode': lastStatusCode,
      if (lastErrorCode != null) 'lastErrorCode': lastErrorCode,
      if (deliveredAt != null) 'deliveredAt': deliveredAt?.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static AppEventInclude include() {
    return AppEventInclude._();
  }

  static AppEventIncludeList includeList({
    _is.WhereExpressionBuilder<AppEventTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AppEventTable>? orderBy,
    _is.OrderByListBuilder<AppEventTable>? orderByList,
    AppEventInclude? include,
  }) {
    return AppEventIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AppEvent.t),
      orderByList: orderByList?.call(AppEvent.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AppEventImpl extends AppEvent {
  _AppEventImpl({
    _is.UuidValue? id,
    required _is.UuidValue appId,
    required String eventId,
    required String type,
    required String dedupeKey,
    required String body,
    required _i9zhna0j.AppEventStatus status,
    int? attemptCount,
    required DateTime nextAttemptAt,
    DateTime? leaseExpiresAt,
    int? lastStatusCode,
    String? lastErrorCode,
    DateTime? deliveredAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         appId: appId,
         eventId: eventId,
         type: type,
         dedupeKey: dedupeKey,
         body: body,
         status: status,
         attemptCount: attemptCount,
         nextAttemptAt: nextAttemptAt,
         leaseExpiresAt: leaseExpiresAt,
         lastStatusCode: lastStatusCode,
         lastErrorCode: lastErrorCode,
         deliveredAt: deliveredAt,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [AppEvent]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AppEvent copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? appId,
    String? eventId,
    String? type,
    String? dedupeKey,
    String? body,
    _i9zhna0j.AppEventStatus? status,
    int? attemptCount,
    DateTime? nextAttemptAt,
    DateTime? leaseExpiresAt = const _is.$UndefinedDateTime(),
    Object? lastStatusCode = _Undefined,
    Object? lastErrorCode = _Undefined,
    DateTime? deliveredAt = const _is.$UndefinedDateTime(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppEvent(
      id: id is _is.UndefinedSentinel ? this.id : id,
      appId: appId ?? this.appId,
      eventId: eventId ?? this.eventId,
      type: type ?? this.type,
      dedupeKey: dedupeKey ?? this.dedupeKey,
      body: body ?? this.body,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      leaseExpiresAt: leaseExpiresAt is _is.UndefinedSentinel
          ? this.leaseExpiresAt
          : leaseExpiresAt,
      lastStatusCode: lastStatusCode is int?
          ? lastStatusCode
          : this.lastStatusCode,
      lastErrorCode: lastErrorCode is String?
          ? lastErrorCode
          : this.lastErrorCode,
      deliveredAt: deliveredAt is _is.UndefinedSentinel
          ? this.deliveredAt
          : deliveredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AppEventUpdateTable extends _is.UpdateTable<AppEventTable> {
  AppEventUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> appId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.appId,
        value,
      );

  _is.ColumnValue<String, String> eventId(String value) => _is.ColumnValue(
    table.eventId,
    value,
  );

  _is.ColumnValue<String, String> type(String value) => _is.ColumnValue(
    table.type,
    value,
  );

  _is.ColumnValue<String, String> dedupeKey(String value) => _is.ColumnValue(
    table.dedupeKey,
    value,
  );

  _is.ColumnValue<String, String> body(String value) => _is.ColumnValue(
    table.body,
    value,
  );

  _is.ColumnValue<_i9zhna0j.AppEventStatus, _i9zhna0j.AppEventStatus> status(
    _i9zhna0j.AppEventStatus value,
  ) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<int, int> attemptCount(int value) => _is.ColumnValue(
    table.attemptCount,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> nextAttemptAt(DateTime value) =>
      _is.ColumnValue(
        table.nextAttemptAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> leaseExpiresAt(DateTime? value) =>
      _is.ColumnValue(
        table.leaseExpiresAt,
        value,
      );

  _is.ColumnValue<int, int> lastStatusCode(int? value) => _is.ColumnValue(
    table.lastStatusCode,
    value,
  );

  _is.ColumnValue<String, String> lastErrorCode(String? value) =>
      _is.ColumnValue(
        table.lastErrorCode,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> deliveredAt(DateTime? value) =>
      _is.ColumnValue(
        table.deliveredAt,
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

class AppEventTable extends _is.Table<_is.UuidValue?> {
  AppEventTable({super.tableRelation}) : super(tableName: 'verily_app_event') {
    updateTable = AppEventUpdateTable(this);
    appId = _is.ColumnUuid(
      'appId',
      this,
    );
    eventId = _is.ColumnString(
      'eventId',
      this,
    );
    type = _is.ColumnString(
      'type',
      this,
    );
    dedupeKey = _is.ColumnString(
      'dedupeKey',
      this,
    );
    body = _is.ColumnString(
      'body',
      this,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
    );
    attemptCount = _is.ColumnInt(
      'attemptCount',
      this,
      hasDefault: true,
    );
    nextAttemptAt = _is.ColumnDateTime(
      'nextAttemptAt',
      this,
    );
    leaseExpiresAt = _is.ColumnDateTime(
      'leaseExpiresAt',
      this,
    );
    lastStatusCode = _is.ColumnInt(
      'lastStatusCode',
      this,
    );
    lastErrorCode = _is.ColumnString(
      'lastErrorCode',
      this,
    );
    deliveredAt = _is.ColumnDateTime(
      'deliveredAt',
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

  late final AppEventUpdateTable updateTable;

  late final _is.ColumnUuid appId;

  /// Public event id (`vev_` + 22 base64url characters), also in the body.
  late final _is.ColumnString eventId;

  /// Wire type, for example `attempt.verified`.
  late final _is.ColumnString type;

  /// Server-owned idempotency key: one event per fact.
  late final _is.ColumnString dedupeKey;

  late final _is.ColumnString body;

  late final _is.ColumnEnum<_i9zhna0j.AppEventStatus> status;

  late final _is.ColumnInt attemptCount;

  late final _is.ColumnDateTime nextAttemptAt;

  late final _is.ColumnDateTime leaseExpiresAt;

  late final _is.ColumnInt lastStatusCode;

  late final _is.ColumnString lastErrorCode;

  late final _is.ColumnDateTime deliveredAt;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  @override
  List<_is.Column> get columns => [
    id,
    appId,
    eventId,
    type,
    dedupeKey,
    body,
    status,
    attemptCount,
    nextAttemptAt,
    leaseExpiresAt,
    lastStatusCode,
    lastErrorCode,
    deliveredAt,
    createdAt,
    updatedAt,
  ];
}

class AppEventInclude extends _is.IncludeObject {
  AppEventInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<_is.UuidValue?> get table => AppEvent.t;
}

class AppEventIncludeList extends _is.IncludeList {
  AppEventIncludeList._({
    _is.WhereExpressionBuilder<AppEventTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AppEvent.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => AppEvent.t;
}

class AppEventRepository {
  const AppEventRepository._();

  /// Returns a list of [AppEvent]s matching the given query parameters.
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
  Future<List<AppEvent>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AppEventTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AppEventTable>? orderBy,
    _is.OrderByListBuilder<AppEventTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<AppEvent>(
      where: where?.call(AppEvent.t),
      orderBy: orderBy?.call(AppEvent.t),
      orderByList: orderByList?.call(AppEvent.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [AppEvent]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `AppEvent.t`.
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
  _ida.Stream<List<AppEvent>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AppEventTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AppEventTable>? orderBy,
    _is.OrderByListBuilder<AppEventTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<AppEvent>(
      where: where?.call(AppEvent.t),
      orderBy: orderBy?.call(AppEvent.t),
      orderByList: orderByList?.call(AppEvent.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [AppEvent] matching the given query parameters.
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
  Future<AppEvent?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AppEventTable>? where,
    int? offset,
    _is.OrderByBuilder<AppEventTable>? orderBy,
    _is.OrderByListBuilder<AppEventTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<AppEvent>(
      where: where?.call(AppEvent.t),
      orderBy: orderBy?.call(AppEvent.t),
      orderByList: orderByList?.call(AppEvent.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [AppEvent] by its [id] or null if no such row exists.
  Future<AppEvent?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<AppEvent>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [AppEvent]s in the list and returns the inserted rows.
  ///
  /// The returned [AppEvent]s will have their `id` fields set.
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
  Future<List<AppEvent>> insert(
    _is.DatabaseSession session,
    List<AppEvent> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<AppEvent>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [AppEvent] and returns the inserted row.
  ///
  /// The returned [AppEvent] will have its `id` field set.
  Future<AppEvent> insertRow(
    _is.DatabaseSession session,
    AppEvent row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<AppEvent>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [AppEvent]s in the list and returns the resulting rows.
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
  /// The returned [AppEvent]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AppEvent>> upsert(
    _is.DatabaseSession session,
    List<AppEvent> rows, {
    required _is.ColumnSelections<AppEventTable> conflictColumns,
    _is.ColumnSelections<AppEventTable>? updateColumns,
    _is.WhereExpressionBuilder<AppEventTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<AppEvent>(
      rows,
      conflictColumns: conflictColumns(AppEvent.t),
      updateColumns: updateColumns?.call(AppEvent.t),
      updateWhere: updateWhere?.call(AppEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [AppEvent] and returns the resulting row.
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
  /// The returned [AppEvent] will have its `id` field set.
  Future<AppEvent?> upsertRow(
    _is.DatabaseSession session,
    AppEvent row, {
    required _is.ColumnSelections<AppEventTable> conflictColumns,
    _is.ColumnSelections<AppEventTable>? updateColumns,
    _is.WhereExpressionBuilder<AppEventTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<AppEvent>(
      row,
      conflictColumns: conflictColumns(AppEvent.t),
      updateColumns: updateColumns?.call(AppEvent.t),
      updateWhere: updateWhere?.call(AppEvent.t),
      transaction: transaction,
    );
  }

  /// Updates all [AppEvent]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AppEvent>> update(
    _is.DatabaseSession session,
    List<AppEvent> rows, {
    _is.ColumnSelections<AppEventTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<AppEvent>(
      rows,
      columns: columns?.call(AppEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [AppEvent]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AppEvent> updateRow(
    _is.DatabaseSession session,
    AppEvent row, {
    _is.ColumnSelections<AppEventTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<AppEvent>(
      row,
      columns: columns?.call(AppEvent.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AppEvent] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AppEvent?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<AppEventUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<AppEvent>(
      id,
      columnValues: columnValues(AppEvent.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AppEvent]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AppEvent>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<AppEventUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<AppEventTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AppEventTable>? orderBy,
    _is.OrderByListBuilder<AppEventTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<AppEvent>(
      columnValues: columnValues(AppEvent.t.updateTable),
      where: where(AppEvent.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AppEvent.t),
      orderByList: orderByList?.call(AppEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [AppEvent]s in the list and returns the deleted rows.
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
  Future<List<AppEvent>> delete(
    _is.DatabaseSession session,
    List<AppEvent> rows, {
    _is.OrderByBuilder<AppEventTable>? orderBy,
    _is.OrderByListBuilder<AppEventTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<AppEvent>(
      rows,
      orderBy: orderBy?.call(AppEvent.t),
      orderByList: orderByList?.call(AppEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [AppEvent].
  Future<AppEvent> deleteRow(
    _is.DatabaseSession session,
    AppEvent row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AppEvent>(
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
  Future<List<AppEvent>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AppEventTable> where,
    _is.OrderByBuilder<AppEventTable>? orderBy,
    _is.OrderByListBuilder<AppEventTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<AppEvent>(
      where: where(AppEvent.t),
      orderBy: orderBy?.call(AppEvent.t),
      orderByList: orderByList?.call(AppEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AppEventTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<AppEvent>(
      where: where?.call(AppEvent.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [AppEvent] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AppEventTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<AppEvent>(
      where: where(AppEvent.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
