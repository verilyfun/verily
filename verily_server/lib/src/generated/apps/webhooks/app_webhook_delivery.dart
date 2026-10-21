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

/// Append-only log of every outbound call to an App webhook: event deliveries
/// and pull verification calls. The creator sees it on the App page. Response
/// bodies are never stored.
abstract class AppWebhookDelivery
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  AppWebhookDelivery._({
    this.id,
    required this.appId,
    required this.eventId,
    required this.eventType,
    required this.attemptNumber,
    required this.requestedAt,
    required this.durationMilliseconds,
    this.statusCode,
    this.errorCode,
    required this.succeeded,
  });

  factory AppWebhookDelivery({
    _is.UuidValue? id,
    required _is.UuidValue appId,
    required String eventId,
    required String eventType,
    required int attemptNumber,
    required DateTime requestedAt,
    required int durationMilliseconds,
    int? statusCode,
    String? errorCode,
    required bool succeeded,
  }) = _AppWebhookDeliveryImpl;

  factory AppWebhookDelivery.fromJson(Map<String, dynamic> jsonSerialization) {
    return AppWebhookDelivery(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      appId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['appId']),
      eventId: jsonSerialization['eventId'] as String,
      eventType: jsonSerialization['eventType'] as String,
      attemptNumber: jsonSerialization['attemptNumber'] as int,
      requestedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['requestedAt'],
      ),
      durationMilliseconds: jsonSerialization['durationMilliseconds'] as int,
      statusCode: jsonSerialization['statusCode'] as int?,
      errorCode: jsonSerialization['errorCode'] as String?,
      succeeded: _is.BoolJsonExtension.fromJson(jsonSerialization['succeeded']),
    );
  }

  static final t = AppWebhookDeliveryTable();

  static const db = AppWebhookDeliveryRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue appId;

  String eventId;

  String eventType;

  int attemptNumber;

  DateTime requestedAt;

  int durationMilliseconds;

  /// HTTP status, when the App answered at all.
  int? statusCode;

  /// Stable failure code, for example `timeout` or `blocked_address`.
  String? errorCode;

  bool succeeded;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [AppWebhookDelivery]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AppWebhookDelivery copyWith({
    _is.UuidValue? id,
    _is.UuidValue? appId,
    String? eventId,
    String? eventType,
    int? attemptNumber,
    DateTime? requestedAt,
    int? durationMilliseconds,
    int? statusCode,
    String? errorCode,
    bool? succeeded,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AppWebhookDelivery',
      if (id != null) 'id': id?.toJson(),
      'appId': appId.toJson(),
      'eventId': eventId,
      'eventType': eventType,
      'attemptNumber': attemptNumber,
      'requestedAt': requestedAt.toJson(),
      'durationMilliseconds': durationMilliseconds,
      if (statusCode != null) 'statusCode': statusCode,
      if (errorCode != null) 'errorCode': errorCode,
      'succeeded': succeeded,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static AppWebhookDeliveryInclude include() {
    return AppWebhookDeliveryInclude._();
  }

  static AppWebhookDeliveryIncludeList includeList({
    _is.WhereExpressionBuilder<AppWebhookDeliveryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AppWebhookDeliveryTable>? orderBy,
    _is.OrderByListBuilder<AppWebhookDeliveryTable>? orderByList,
    AppWebhookDeliveryInclude? include,
  }) {
    return AppWebhookDeliveryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AppWebhookDelivery.t),
      orderByList: orderByList?.call(AppWebhookDelivery.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AppWebhookDeliveryImpl extends AppWebhookDelivery {
  _AppWebhookDeliveryImpl({
    _is.UuidValue? id,
    required _is.UuidValue appId,
    required String eventId,
    required String eventType,
    required int attemptNumber,
    required DateTime requestedAt,
    required int durationMilliseconds,
    int? statusCode,
    String? errorCode,
    required bool succeeded,
  }) : super._(
         id: id,
         appId: appId,
         eventId: eventId,
         eventType: eventType,
         attemptNumber: attemptNumber,
         requestedAt: requestedAt,
         durationMilliseconds: durationMilliseconds,
         statusCode: statusCode,
         errorCode: errorCode,
         succeeded: succeeded,
       );

  /// Returns a shallow copy of this [AppWebhookDelivery]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AppWebhookDelivery copyWith({
    Object? id = _Undefined,
    _is.UuidValue? appId,
    String? eventId,
    String? eventType,
    int? attemptNumber,
    DateTime? requestedAt,
    int? durationMilliseconds,
    Object? statusCode = _Undefined,
    Object? errorCode = _Undefined,
    bool? succeeded,
  }) {
    return AppWebhookDelivery(
      id: id is _is.UuidValue? ? id : this.id,
      appId: appId ?? this.appId,
      eventId: eventId ?? this.eventId,
      eventType: eventType ?? this.eventType,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      requestedAt: requestedAt ?? this.requestedAt,
      durationMilliseconds: durationMilliseconds ?? this.durationMilliseconds,
      statusCode: statusCode is int? ? statusCode : this.statusCode,
      errorCode: errorCode is String? ? errorCode : this.errorCode,
      succeeded: succeeded ?? this.succeeded,
    );
  }
}

class AppWebhookDeliveryUpdateTable
    extends _is.UpdateTable<AppWebhookDeliveryTable> {
  AppWebhookDeliveryUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> appId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.appId,
        value,
      );

  _is.ColumnValue<String, String> eventId(String value) => _is.ColumnValue(
    table.eventId,
    value,
  );

  _is.ColumnValue<String, String> eventType(String value) => _is.ColumnValue(
    table.eventType,
    value,
  );

  _is.ColumnValue<int, int> attemptNumber(int value) => _is.ColumnValue(
    table.attemptNumber,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> requestedAt(DateTime value) =>
      _is.ColumnValue(
        table.requestedAt,
        value,
      );

  _is.ColumnValue<int, int> durationMilliseconds(int value) => _is.ColumnValue(
    table.durationMilliseconds,
    value,
  );

  _is.ColumnValue<int, int> statusCode(int? value) => _is.ColumnValue(
    table.statusCode,
    value,
  );

  _is.ColumnValue<String, String> errorCode(String? value) => _is.ColumnValue(
    table.errorCode,
    value,
  );

  _is.ColumnValue<bool, bool> succeeded(bool value) => _is.ColumnValue(
    table.succeeded,
    value,
  );
}

class AppWebhookDeliveryTable extends _is.Table<_is.UuidValue?> {
  AppWebhookDeliveryTable({super.tableRelation})
    : super(tableName: 'verily_app_webhook_delivery') {
    updateTable = AppWebhookDeliveryUpdateTable(this);
    appId = _is.ColumnUuid(
      'appId',
      this,
    );
    eventId = _is.ColumnString(
      'eventId',
      this,
    );
    eventType = _is.ColumnString(
      'eventType',
      this,
    );
    attemptNumber = _is.ColumnInt(
      'attemptNumber',
      this,
    );
    requestedAt = _is.ColumnDateTime(
      'requestedAt',
      this,
    );
    durationMilliseconds = _is.ColumnInt(
      'durationMilliseconds',
      this,
    );
    statusCode = _is.ColumnInt(
      'statusCode',
      this,
    );
    errorCode = _is.ColumnString(
      'errorCode',
      this,
    );
    succeeded = _is.ColumnBool(
      'succeeded',
      this,
    );
  }

  late final AppWebhookDeliveryUpdateTable updateTable;

  late final _is.ColumnUuid appId;

  late final _is.ColumnString eventId;

  late final _is.ColumnString eventType;

  late final _is.ColumnInt attemptNumber;

  late final _is.ColumnDateTime requestedAt;

  late final _is.ColumnInt durationMilliseconds;

  /// HTTP status, when the App answered at all.
  late final _is.ColumnInt statusCode;

  /// Stable failure code, for example `timeout` or `blocked_address`.
  late final _is.ColumnString errorCode;

  late final _is.ColumnBool succeeded;

  @override
  List<_is.Column> get columns => [
    id,
    appId,
    eventId,
    eventType,
    attemptNumber,
    requestedAt,
    durationMilliseconds,
    statusCode,
    errorCode,
    succeeded,
  ];
}

class AppWebhookDeliveryInclude extends _is.IncludeObject {
  AppWebhookDeliveryInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<_is.UuidValue?> get table => AppWebhookDelivery.t;
}

class AppWebhookDeliveryIncludeList extends _is.IncludeList {
  AppWebhookDeliveryIncludeList._({
    _is.WhereExpressionBuilder<AppWebhookDeliveryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AppWebhookDelivery.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => AppWebhookDelivery.t;
}

class AppWebhookDeliveryRepository {
  const AppWebhookDeliveryRepository._();

  /// Returns a list of [AppWebhookDelivery]s matching the given query parameters.
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
  Future<List<AppWebhookDelivery>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AppWebhookDeliveryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AppWebhookDeliveryTable>? orderBy,
    _is.OrderByListBuilder<AppWebhookDeliveryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<AppWebhookDelivery>(
      where: where?.call(AppWebhookDelivery.t),
      orderBy: orderBy?.call(AppWebhookDelivery.t),
      orderByList: orderByList?.call(AppWebhookDelivery.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [AppWebhookDelivery] matching the given query parameters.
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
  Future<AppWebhookDelivery?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AppWebhookDeliveryTable>? where,
    int? offset,
    _is.OrderByBuilder<AppWebhookDeliveryTable>? orderBy,
    _is.OrderByListBuilder<AppWebhookDeliveryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<AppWebhookDelivery>(
      where: where?.call(AppWebhookDelivery.t),
      orderBy: orderBy?.call(AppWebhookDelivery.t),
      orderByList: orderByList?.call(AppWebhookDelivery.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [AppWebhookDelivery] by its [id] or null if no such row exists.
  Future<AppWebhookDelivery?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<AppWebhookDelivery>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [AppWebhookDelivery]s in the list and returns the inserted rows.
  ///
  /// The returned [AppWebhookDelivery]s will have their `id` fields set.
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
  Future<List<AppWebhookDelivery>> insert(
    _is.DatabaseSession session,
    List<AppWebhookDelivery> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<AppWebhookDelivery>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [AppWebhookDelivery] and returns the inserted row.
  ///
  /// The returned [AppWebhookDelivery] will have its `id` field set.
  Future<AppWebhookDelivery> insertRow(
    _is.DatabaseSession session,
    AppWebhookDelivery row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<AppWebhookDelivery>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [AppWebhookDelivery]s in the list and returns the resulting rows.
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
  /// The returned [AppWebhookDelivery]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AppWebhookDelivery>> upsert(
    _is.DatabaseSession session,
    List<AppWebhookDelivery> rows, {
    required _is.ColumnSelections<AppWebhookDeliveryTable> conflictColumns,
    _is.ColumnSelections<AppWebhookDeliveryTable>? updateColumns,
    _is.WhereExpressionBuilder<AppWebhookDeliveryTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<AppWebhookDelivery>(
      rows,
      conflictColumns: conflictColumns(AppWebhookDelivery.t),
      updateColumns: updateColumns?.call(AppWebhookDelivery.t),
      updateWhere: updateWhere?.call(AppWebhookDelivery.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [AppWebhookDelivery] and returns the resulting row.
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
  /// The returned [AppWebhookDelivery] will have its `id` field set.
  Future<AppWebhookDelivery?> upsertRow(
    _is.DatabaseSession session,
    AppWebhookDelivery row, {
    required _is.ColumnSelections<AppWebhookDeliveryTable> conflictColumns,
    _is.ColumnSelections<AppWebhookDeliveryTable>? updateColumns,
    _is.WhereExpressionBuilder<AppWebhookDeliveryTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<AppWebhookDelivery>(
      row,
      conflictColumns: conflictColumns(AppWebhookDelivery.t),
      updateColumns: updateColumns?.call(AppWebhookDelivery.t),
      updateWhere: updateWhere?.call(AppWebhookDelivery.t),
      transaction: transaction,
    );
  }

  /// Updates all [AppWebhookDelivery]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AppWebhookDelivery>> update(
    _is.DatabaseSession session,
    List<AppWebhookDelivery> rows, {
    _is.ColumnSelections<AppWebhookDeliveryTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<AppWebhookDelivery>(
      rows,
      columns: columns?.call(AppWebhookDelivery.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [AppWebhookDelivery]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AppWebhookDelivery> updateRow(
    _is.DatabaseSession session,
    AppWebhookDelivery row, {
    _is.ColumnSelections<AppWebhookDeliveryTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<AppWebhookDelivery>(
      row,
      columns: columns?.call(AppWebhookDelivery.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AppWebhookDelivery] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AppWebhookDelivery?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<AppWebhookDeliveryUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<AppWebhookDelivery>(
      id,
      columnValues: columnValues(AppWebhookDelivery.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AppWebhookDelivery]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AppWebhookDelivery>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<AppWebhookDeliveryUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<AppWebhookDeliveryTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AppWebhookDeliveryTable>? orderBy,
    _is.OrderByListBuilder<AppWebhookDeliveryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<AppWebhookDelivery>(
      columnValues: columnValues(AppWebhookDelivery.t.updateTable),
      where: where(AppWebhookDelivery.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AppWebhookDelivery.t),
      orderByList: orderByList?.call(AppWebhookDelivery.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [AppWebhookDelivery]s in the list and returns the deleted rows.
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
  Future<List<AppWebhookDelivery>> delete(
    _is.DatabaseSession session,
    List<AppWebhookDelivery> rows, {
    _is.OrderByBuilder<AppWebhookDeliveryTable>? orderBy,
    _is.OrderByListBuilder<AppWebhookDeliveryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<AppWebhookDelivery>(
      rows,
      orderBy: orderBy?.call(AppWebhookDelivery.t),
      orderByList: orderByList?.call(AppWebhookDelivery.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [AppWebhookDelivery].
  Future<AppWebhookDelivery> deleteRow(
    _is.DatabaseSession session,
    AppWebhookDelivery row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AppWebhookDelivery>(
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
  Future<List<AppWebhookDelivery>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AppWebhookDeliveryTable> where,
    _is.OrderByBuilder<AppWebhookDeliveryTable>? orderBy,
    _is.OrderByListBuilder<AppWebhookDeliveryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<AppWebhookDelivery>(
      where: where(AppWebhookDelivery.t),
      orderBy: orderBy?.call(AppWebhookDelivery.t),
      orderByList: orderByList?.call(AppWebhookDelivery.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AppWebhookDeliveryTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<AppWebhookDelivery>(
      where: where?.call(AppWebhookDelivery.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [AppWebhookDelivery] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AppWebhookDeliveryTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<AppWebhookDelivery>(
      where: where(AppWebhookDelivery.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
