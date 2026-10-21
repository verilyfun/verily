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

import '../apps/app_confirmation_outcome.dart' as _isxmw90h;

/// Append-only receipt for one well-formed, authenticated confirmation.
/// The first delivery of an event id decides its outcome; retries replay it.
abstract class AppConfirmation
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  AppConfirmation._({
    this.id,
    required this.appId,
    required this.keyId,
    required this.eventId,
    required this.payloadDigest,
    required this.actionKey,
    required this.subject,
    this.actionDefinitionId,
    this.attemptId,
    required this.occurredAt,
    required this.receivedAt,
    required this.outcome,
    required this.reasonCode,
  });

  factory AppConfirmation({
    _is.UuidValue? id,
    required _is.UuidValue appId,
    required String keyId,
    required String eventId,
    required String payloadDigest,
    required String actionKey,
    required String subject,
    _is.UuidValue? actionDefinitionId,
    _is.UuidValue? attemptId,
    required DateTime occurredAt,
    required DateTime receivedAt,
    required _isxmw90h.AppConfirmationOutcome outcome,
    required String reasonCode,
  }) = _AppConfirmationImpl;

  factory AppConfirmation.fromJson(Map<String, dynamic> jsonSerialization) {
    return AppConfirmation(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      appId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['appId']),
      keyId: jsonSerialization['keyId'] as String,
      eventId: jsonSerialization['eventId'] as String,
      payloadDigest: jsonSerialization['payloadDigest'] as String,
      actionKey: jsonSerialization['actionKey'] as String,
      subject: jsonSerialization['subject'] as String,
      actionDefinitionId: jsonSerialization['actionDefinitionId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['actionDefinitionId'],
            ),
      attemptId: jsonSerialization['attemptId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['attemptId']),
      occurredAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['occurredAt'],
      ),
      receivedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['receivedAt'],
      ),
      outcome: _isxmw90h.AppConfirmationOutcome.fromJson(
        (jsonSerialization['outcome'] as String),
      ),
      reasonCode: jsonSerialization['reasonCode'] as String,
    );
  }

  static final t = AppConfirmationTable();

  static const db = AppConfirmationRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue appId;

  /// Public key id that authenticated the delivery.
  String keyId;

  String eventId;

  /// SHA-256 of the normalized event fields; a reused event id must match it.
  String payloadDigest;

  String actionKey;

  String subject;

  _is.UuidValue? actionDefinitionId;

  _is.UuidValue? attemptId;

  DateTime occurredAt;

  DateTime receivedAt;

  _isxmw90h.AppConfirmationOutcome outcome;

  String reasonCode;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [AppConfirmation]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AppConfirmation copyWith({
    _is.UuidValue? id,
    _is.UuidValue? appId,
    String? keyId,
    String? eventId,
    String? payloadDigest,
    String? actionKey,
    String? subject,
    _is.UuidValue? actionDefinitionId,
    _is.UuidValue? attemptId,
    DateTime? occurredAt,
    DateTime? receivedAt,
    _isxmw90h.AppConfirmationOutcome? outcome,
    String? reasonCode,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AppConfirmation',
      if (id != null) 'id': id?.toJson(),
      'appId': appId.toJson(),
      'keyId': keyId,
      'eventId': eventId,
      'payloadDigest': payloadDigest,
      'actionKey': actionKey,
      'subject': subject,
      if (actionDefinitionId != null)
        'actionDefinitionId': actionDefinitionId?.toJson(),
      if (attemptId != null) 'attemptId': attemptId?.toJson(),
      'occurredAt': occurredAt.toJson(),
      'receivedAt': receivedAt.toJson(),
      'outcome': outcome.toJson(),
      'reasonCode': reasonCode,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static AppConfirmationInclude include() {
    return AppConfirmationInclude._();
  }

  static AppConfirmationIncludeList includeList({
    _is.WhereExpressionBuilder<AppConfirmationTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AppConfirmationTable>? orderBy,
    _is.OrderByListBuilder<AppConfirmationTable>? orderByList,
    AppConfirmationInclude? include,
  }) {
    return AppConfirmationIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AppConfirmation.t),
      orderByList: orderByList?.call(AppConfirmation.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AppConfirmationImpl extends AppConfirmation {
  _AppConfirmationImpl({
    _is.UuidValue? id,
    required _is.UuidValue appId,
    required String keyId,
    required String eventId,
    required String payloadDigest,
    required String actionKey,
    required String subject,
    _is.UuidValue? actionDefinitionId,
    _is.UuidValue? attemptId,
    required DateTime occurredAt,
    required DateTime receivedAt,
    required _isxmw90h.AppConfirmationOutcome outcome,
    required String reasonCode,
  }) : super._(
         id: id,
         appId: appId,
         keyId: keyId,
         eventId: eventId,
         payloadDigest: payloadDigest,
         actionKey: actionKey,
         subject: subject,
         actionDefinitionId: actionDefinitionId,
         attemptId: attemptId,
         occurredAt: occurredAt,
         receivedAt: receivedAt,
         outcome: outcome,
         reasonCode: reasonCode,
       );

  /// Returns a shallow copy of this [AppConfirmation]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AppConfirmation copyWith({
    Object? id = _Undefined,
    _is.UuidValue? appId,
    String? keyId,
    String? eventId,
    String? payloadDigest,
    String? actionKey,
    String? subject,
    Object? actionDefinitionId = _Undefined,
    Object? attemptId = _Undefined,
    DateTime? occurredAt,
    DateTime? receivedAt,
    _isxmw90h.AppConfirmationOutcome? outcome,
    String? reasonCode,
  }) {
    return AppConfirmation(
      id: id is _is.UuidValue? ? id : this.id,
      appId: appId ?? this.appId,
      keyId: keyId ?? this.keyId,
      eventId: eventId ?? this.eventId,
      payloadDigest: payloadDigest ?? this.payloadDigest,
      actionKey: actionKey ?? this.actionKey,
      subject: subject ?? this.subject,
      actionDefinitionId: actionDefinitionId is _is.UuidValue?
          ? actionDefinitionId
          : this.actionDefinitionId,
      attemptId: attemptId is _is.UuidValue? ? attemptId : this.attemptId,
      occurredAt: occurredAt ?? this.occurredAt,
      receivedAt: receivedAt ?? this.receivedAt,
      outcome: outcome ?? this.outcome,
      reasonCode: reasonCode ?? this.reasonCode,
    );
  }
}

class AppConfirmationUpdateTable extends _is.UpdateTable<AppConfirmationTable> {
  AppConfirmationUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> appId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.appId,
        value,
      );

  _is.ColumnValue<String, String> keyId(String value) => _is.ColumnValue(
    table.keyId,
    value,
  );

  _is.ColumnValue<String, String> eventId(String value) => _is.ColumnValue(
    table.eventId,
    value,
  );

  _is.ColumnValue<String, String> payloadDigest(String value) =>
      _is.ColumnValue(
        table.payloadDigest,
        value,
      );

  _is.ColumnValue<String, String> actionKey(String value) => _is.ColumnValue(
    table.actionKey,
    value,
  );

  _is.ColumnValue<String, String> subject(String value) => _is.ColumnValue(
    table.subject,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> actionDefinitionId(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.actionDefinitionId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> attemptId(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.attemptId,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> occurredAt(DateTime value) =>
      _is.ColumnValue(
        table.occurredAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> receivedAt(DateTime value) =>
      _is.ColumnValue(
        table.receivedAt,
        value,
      );

  _is.ColumnValue<
    _isxmw90h.AppConfirmationOutcome,
    _isxmw90h.AppConfirmationOutcome
  >
  outcome(_isxmw90h.AppConfirmationOutcome value) => _is.ColumnValue(
    table.outcome,
    value,
  );

  _is.ColumnValue<String, String> reasonCode(String value) => _is.ColumnValue(
    table.reasonCode,
    value,
  );
}

class AppConfirmationTable extends _is.Table<_is.UuidValue?> {
  AppConfirmationTable({super.tableRelation})
    : super(tableName: 'verily_app_confirmation') {
    updateTable = AppConfirmationUpdateTable(this);
    appId = _is.ColumnUuid(
      'appId',
      this,
    );
    keyId = _is.ColumnString(
      'keyId',
      this,
    );
    eventId = _is.ColumnString(
      'eventId',
      this,
    );
    payloadDigest = _is.ColumnString(
      'payloadDigest',
      this,
    );
    actionKey = _is.ColumnString(
      'actionKey',
      this,
    );
    subject = _is.ColumnString(
      'subject',
      this,
    );
    actionDefinitionId = _is.ColumnUuid(
      'actionDefinitionId',
      this,
    );
    attemptId = _is.ColumnUuid(
      'attemptId',
      this,
    );
    occurredAt = _is.ColumnDateTime(
      'occurredAt',
      this,
    );
    receivedAt = _is.ColumnDateTime(
      'receivedAt',
      this,
    );
    outcome = _is.ColumnEnum(
      'outcome',
      this,
      _is.EnumSerialization.byName,
    );
    reasonCode = _is.ColumnString(
      'reasonCode',
      this,
    );
  }

  late final AppConfirmationUpdateTable updateTable;

  late final _is.ColumnUuid appId;

  /// Public key id that authenticated the delivery.
  late final _is.ColumnString keyId;

  late final _is.ColumnString eventId;

  /// SHA-256 of the normalized event fields; a reused event id must match it.
  late final _is.ColumnString payloadDigest;

  late final _is.ColumnString actionKey;

  late final _is.ColumnString subject;

  late final _is.ColumnUuid actionDefinitionId;

  late final _is.ColumnUuid attemptId;

  late final _is.ColumnDateTime occurredAt;

  late final _is.ColumnDateTime receivedAt;

  late final _is.ColumnEnum<_isxmw90h.AppConfirmationOutcome> outcome;

  late final _is.ColumnString reasonCode;

  @override
  List<_is.Column> get columns => [
    id,
    appId,
    keyId,
    eventId,
    payloadDigest,
    actionKey,
    subject,
    actionDefinitionId,
    attemptId,
    occurredAt,
    receivedAt,
    outcome,
    reasonCode,
  ];
}

class AppConfirmationInclude extends _is.IncludeObject {
  AppConfirmationInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<_is.UuidValue?> get table => AppConfirmation.t;
}

class AppConfirmationIncludeList extends _is.IncludeList {
  AppConfirmationIncludeList._({
    _is.WhereExpressionBuilder<AppConfirmationTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AppConfirmation.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => AppConfirmation.t;
}

class AppConfirmationRepository {
  const AppConfirmationRepository._();

  /// Returns a list of [AppConfirmation]s matching the given query parameters.
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
  Future<List<AppConfirmation>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AppConfirmationTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AppConfirmationTable>? orderBy,
    _is.OrderByListBuilder<AppConfirmationTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<AppConfirmation>(
      where: where?.call(AppConfirmation.t),
      orderBy: orderBy?.call(AppConfirmation.t),
      orderByList: orderByList?.call(AppConfirmation.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [AppConfirmation] matching the given query parameters.
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
  Future<AppConfirmation?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AppConfirmationTable>? where,
    int? offset,
    _is.OrderByBuilder<AppConfirmationTable>? orderBy,
    _is.OrderByListBuilder<AppConfirmationTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<AppConfirmation>(
      where: where?.call(AppConfirmation.t),
      orderBy: orderBy?.call(AppConfirmation.t),
      orderByList: orderByList?.call(AppConfirmation.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [AppConfirmation] by its [id] or null if no such row exists.
  Future<AppConfirmation?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<AppConfirmation>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [AppConfirmation]s in the list and returns the inserted rows.
  ///
  /// The returned [AppConfirmation]s will have their `id` fields set.
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
  Future<List<AppConfirmation>> insert(
    _is.DatabaseSession session,
    List<AppConfirmation> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<AppConfirmation>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [AppConfirmation] and returns the inserted row.
  ///
  /// The returned [AppConfirmation] will have its `id` field set.
  Future<AppConfirmation> insertRow(
    _is.DatabaseSession session,
    AppConfirmation row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<AppConfirmation>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [AppConfirmation]s in the list and returns the resulting rows.
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
  /// The returned [AppConfirmation]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AppConfirmation>> upsert(
    _is.DatabaseSession session,
    List<AppConfirmation> rows, {
    required _is.ColumnSelections<AppConfirmationTable> conflictColumns,
    _is.ColumnSelections<AppConfirmationTable>? updateColumns,
    _is.WhereExpressionBuilder<AppConfirmationTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<AppConfirmation>(
      rows,
      conflictColumns: conflictColumns(AppConfirmation.t),
      updateColumns: updateColumns?.call(AppConfirmation.t),
      updateWhere: updateWhere?.call(AppConfirmation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [AppConfirmation] and returns the resulting row.
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
  /// The returned [AppConfirmation] will have its `id` field set.
  Future<AppConfirmation?> upsertRow(
    _is.DatabaseSession session,
    AppConfirmation row, {
    required _is.ColumnSelections<AppConfirmationTable> conflictColumns,
    _is.ColumnSelections<AppConfirmationTable>? updateColumns,
    _is.WhereExpressionBuilder<AppConfirmationTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<AppConfirmation>(
      row,
      conflictColumns: conflictColumns(AppConfirmation.t),
      updateColumns: updateColumns?.call(AppConfirmation.t),
      updateWhere: updateWhere?.call(AppConfirmation.t),
      transaction: transaction,
    );
  }

  /// Updates all [AppConfirmation]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AppConfirmation>> update(
    _is.DatabaseSession session,
    List<AppConfirmation> rows, {
    _is.ColumnSelections<AppConfirmationTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<AppConfirmation>(
      rows,
      columns: columns?.call(AppConfirmation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [AppConfirmation]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AppConfirmation> updateRow(
    _is.DatabaseSession session,
    AppConfirmation row, {
    _is.ColumnSelections<AppConfirmationTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<AppConfirmation>(
      row,
      columns: columns?.call(AppConfirmation.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AppConfirmation] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AppConfirmation?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<AppConfirmationUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<AppConfirmation>(
      id,
      columnValues: columnValues(AppConfirmation.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AppConfirmation]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AppConfirmation>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<AppConfirmationUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<AppConfirmationTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AppConfirmationTable>? orderBy,
    _is.OrderByListBuilder<AppConfirmationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<AppConfirmation>(
      columnValues: columnValues(AppConfirmation.t.updateTable),
      where: where(AppConfirmation.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AppConfirmation.t),
      orderByList: orderByList?.call(AppConfirmation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [AppConfirmation]s in the list and returns the deleted rows.
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
  Future<List<AppConfirmation>> delete(
    _is.DatabaseSession session,
    List<AppConfirmation> rows, {
    _is.OrderByBuilder<AppConfirmationTable>? orderBy,
    _is.OrderByListBuilder<AppConfirmationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<AppConfirmation>(
      rows,
      orderBy: orderBy?.call(AppConfirmation.t),
      orderByList: orderByList?.call(AppConfirmation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [AppConfirmation].
  Future<AppConfirmation> deleteRow(
    _is.DatabaseSession session,
    AppConfirmation row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AppConfirmation>(
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
  Future<List<AppConfirmation>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AppConfirmationTable> where,
    _is.OrderByBuilder<AppConfirmationTable>? orderBy,
    _is.OrderByListBuilder<AppConfirmationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<AppConfirmation>(
      where: where(AppConfirmation.t),
      orderBy: orderBy?.call(AppConfirmation.t),
      orderByList: orderByList?.call(AppConfirmation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AppConfirmationTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<AppConfirmation>(
      where: where?.call(AppConfirmation.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [AppConfirmation] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AppConfirmationTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<AppConfirmation>(
      where: where(AppConfirmation.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
