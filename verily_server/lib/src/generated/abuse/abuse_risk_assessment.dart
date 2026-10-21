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
import 'package:verily_server/src/generated/protocol.dart' as _itf691yl;

/// Append-only, privacy-safe abuse decision recorded before proof acceptance or payout.
abstract class AbuseRiskAssessment
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  AbuseRiskAssessment._({
    this.id,
    required this.actionDefinitionId,
    required this.assessmentKey,
    required this.phase,
    required this.policyVersion,
    required this.disposition,
    required this.tier,
    required this.score,
    required this.signalCodes,
    required this.correlationWindowStartsAt,
    required this.createdAt,
  });

  factory AbuseRiskAssessment({
    _is.UuidValue? id,
    required _is.UuidValue actionDefinitionId,
    required String assessmentKey,
    required String phase,
    required String policyVersion,
    required String disposition,
    required String tier,
    required int score,
    required List<String> signalCodes,
    required DateTime correlationWindowStartsAt,
    required DateTime createdAt,
  }) = _AbuseRiskAssessmentImpl;

  factory AbuseRiskAssessment.fromJson(Map<String, dynamic> jsonSerialization) {
    return AbuseRiskAssessment(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      actionDefinitionId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['actionDefinitionId'],
      ),
      assessmentKey: jsonSerialization['assessmentKey'] as String,
      phase: jsonSerialization['phase'] as String,
      policyVersion: jsonSerialization['policyVersion'] as String,
      disposition: jsonSerialization['disposition'] as String,
      tier: jsonSerialization['tier'] as String,
      score: jsonSerialization['score'] as int,
      signalCodes: _itf691yl.Protocol().deserialize<List<String>>(
        jsonSerialization['signalCodes'],
      ),
      correlationWindowStartsAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['correlationWindowStartsAt'],
      ),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = AbuseRiskAssessmentTable();

  static const db = AbuseRiskAssessmentRepository._();

  @override
  _is.UuidValue? id;

  /// Retains the affected action for aggregate monitoring without storing an account or attempt identifier.
  _is.UuidValue actionDefinitionId;

  /// SHA-256 key derived from phase, policy, pseudonymized attempt, and immutable proof identity.
  String assessmentKey;

  String phase;

  String policyVersion;

  String disposition;

  String tier;

  int score;

  List<String> signalCodes;

  DateTime correlationWindowStartsAt;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [AbuseRiskAssessment]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AbuseRiskAssessment copyWith({
    _is.UuidValue? id,
    _is.UuidValue? actionDefinitionId,
    String? assessmentKey,
    String? phase,
    String? policyVersion,
    String? disposition,
    String? tier,
    int? score,
    List<String>? signalCodes,
    DateTime? correlationWindowStartsAt,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AbuseRiskAssessment',
      if (id != null) 'id': id?.toJson(),
      'actionDefinitionId': actionDefinitionId.toJson(),
      'assessmentKey': assessmentKey,
      'phase': phase,
      'policyVersion': policyVersion,
      'disposition': disposition,
      'tier': tier,
      'score': score,
      'signalCodes': signalCodes.toJson(),
      'correlationWindowStartsAt': correlationWindowStartsAt.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static AbuseRiskAssessmentInclude include() {
    return AbuseRiskAssessmentInclude._();
  }

  static AbuseRiskAssessmentIncludeList includeList({
    _is.WhereExpressionBuilder<AbuseRiskAssessmentTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AbuseRiskAssessmentTable>? orderBy,
    _is.OrderByListBuilder<AbuseRiskAssessmentTable>? orderByList,
    AbuseRiskAssessmentInclude? include,
  }) {
    return AbuseRiskAssessmentIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AbuseRiskAssessment.t),
      orderByList: orderByList?.call(AbuseRiskAssessment.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AbuseRiskAssessmentImpl extends AbuseRiskAssessment {
  _AbuseRiskAssessmentImpl({
    _is.UuidValue? id,
    required _is.UuidValue actionDefinitionId,
    required String assessmentKey,
    required String phase,
    required String policyVersion,
    required String disposition,
    required String tier,
    required int score,
    required List<String> signalCodes,
    required DateTime correlationWindowStartsAt,
    required DateTime createdAt,
  }) : super._(
         id: id,
         actionDefinitionId: actionDefinitionId,
         assessmentKey: assessmentKey,
         phase: phase,
         policyVersion: policyVersion,
         disposition: disposition,
         tier: tier,
         score: score,
         signalCodes: signalCodes,
         correlationWindowStartsAt: correlationWindowStartsAt,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [AbuseRiskAssessment]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AbuseRiskAssessment copyWith({
    Object? id = _Undefined,
    _is.UuidValue? actionDefinitionId,
    String? assessmentKey,
    String? phase,
    String? policyVersion,
    String? disposition,
    String? tier,
    int? score,
    List<String>? signalCodes,
    DateTime? correlationWindowStartsAt,
    DateTime? createdAt,
  }) {
    return AbuseRiskAssessment(
      id: id is _is.UuidValue? ? id : this.id,
      actionDefinitionId: actionDefinitionId ?? this.actionDefinitionId,
      assessmentKey: assessmentKey ?? this.assessmentKey,
      phase: phase ?? this.phase,
      policyVersion: policyVersion ?? this.policyVersion,
      disposition: disposition ?? this.disposition,
      tier: tier ?? this.tier,
      score: score ?? this.score,
      signalCodes: signalCodes ?? this.signalCodes.map((e0) => e0).toList(),
      correlationWindowStartsAt:
          correlationWindowStartsAt ?? this.correlationWindowStartsAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AbuseRiskAssessmentUpdateTable
    extends _is.UpdateTable<AbuseRiskAssessmentTable> {
  AbuseRiskAssessmentUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> actionDefinitionId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.actionDefinitionId,
    value,
  );

  _is.ColumnValue<String, String> assessmentKey(String value) =>
      _is.ColumnValue(
        table.assessmentKey,
        value,
      );

  _is.ColumnValue<String, String> phase(String value) => _is.ColumnValue(
    table.phase,
    value,
  );

  _is.ColumnValue<String, String> policyVersion(String value) =>
      _is.ColumnValue(
        table.policyVersion,
        value,
      );

  _is.ColumnValue<String, String> disposition(String value) => _is.ColumnValue(
    table.disposition,
    value,
  );

  _is.ColumnValue<String, String> tier(String value) => _is.ColumnValue(
    table.tier,
    value,
  );

  _is.ColumnValue<int, int> score(int value) => _is.ColumnValue(
    table.score,
    value,
  );

  _is.ColumnValue<List<String>, List<String>> signalCodes(List<String> value) =>
      _is.ColumnValue(
        table.signalCodes,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> correlationWindowStartsAt(
    DateTime value,
  ) => _is.ColumnValue(
    table.correlationWindowStartsAt,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class AbuseRiskAssessmentTable extends _is.Table<_is.UuidValue?> {
  AbuseRiskAssessmentTable({super.tableRelation})
    : super(tableName: 'verily_abuse_risk_assessment') {
    updateTable = AbuseRiskAssessmentUpdateTable(this);
    actionDefinitionId = _is.ColumnUuid(
      'actionDefinitionId',
      this,
    );
    assessmentKey = _is.ColumnString(
      'assessmentKey',
      this,
    );
    phase = _is.ColumnString(
      'phase',
      this,
    );
    policyVersion = _is.ColumnString(
      'policyVersion',
      this,
    );
    disposition = _is.ColumnString(
      'disposition',
      this,
    );
    tier = _is.ColumnString(
      'tier',
      this,
    );
    score = _is.ColumnInt(
      'score',
      this,
    );
    signalCodes = _is.ColumnSerializable<List<String>>(
      'signalCodes',
      this,
    );
    correlationWindowStartsAt = _is.ColumnDateTime(
      'correlationWindowStartsAt',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final AbuseRiskAssessmentUpdateTable updateTable;

  /// Retains the affected action for aggregate monitoring without storing an account or attempt identifier.
  late final _is.ColumnUuid actionDefinitionId;

  /// SHA-256 key derived from phase, policy, pseudonymized attempt, and immutable proof identity.
  late final _is.ColumnString assessmentKey;

  late final _is.ColumnString phase;

  late final _is.ColumnString policyVersion;

  late final _is.ColumnString disposition;

  late final _is.ColumnString tier;

  late final _is.ColumnInt score;

  late final _is.ColumnSerializable<List<String>> signalCodes;

  late final _is.ColumnDateTime correlationWindowStartsAt;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    actionDefinitionId,
    assessmentKey,
    phase,
    policyVersion,
    disposition,
    tier,
    score,
    signalCodes,
    correlationWindowStartsAt,
    createdAt,
  ];
}

class AbuseRiskAssessmentInclude extends _is.IncludeObject {
  AbuseRiskAssessmentInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<_is.UuidValue?> get table => AbuseRiskAssessment.t;
}

class AbuseRiskAssessmentIncludeList extends _is.IncludeList {
  AbuseRiskAssessmentIncludeList._({
    _is.WhereExpressionBuilder<AbuseRiskAssessmentTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AbuseRiskAssessment.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => AbuseRiskAssessment.t;
}

class AbuseRiskAssessmentRepository {
  const AbuseRiskAssessmentRepository._();

  /// Returns a list of [AbuseRiskAssessment]s matching the given query parameters.
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
  Future<List<AbuseRiskAssessment>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AbuseRiskAssessmentTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AbuseRiskAssessmentTable>? orderBy,
    _is.OrderByListBuilder<AbuseRiskAssessmentTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<AbuseRiskAssessment>(
      where: where?.call(AbuseRiskAssessment.t),
      orderBy: orderBy?.call(AbuseRiskAssessment.t),
      orderByList: orderByList?.call(AbuseRiskAssessment.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [AbuseRiskAssessment] matching the given query parameters.
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
  Future<AbuseRiskAssessment?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AbuseRiskAssessmentTable>? where,
    int? offset,
    _is.OrderByBuilder<AbuseRiskAssessmentTable>? orderBy,
    _is.OrderByListBuilder<AbuseRiskAssessmentTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<AbuseRiskAssessment>(
      where: where?.call(AbuseRiskAssessment.t),
      orderBy: orderBy?.call(AbuseRiskAssessment.t),
      orderByList: orderByList?.call(AbuseRiskAssessment.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [AbuseRiskAssessment] by its [id] or null if no such row exists.
  Future<AbuseRiskAssessment?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<AbuseRiskAssessment>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [AbuseRiskAssessment]s in the list and returns the inserted rows.
  ///
  /// The returned [AbuseRiskAssessment]s will have their `id` fields set.
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
  Future<List<AbuseRiskAssessment>> insert(
    _is.DatabaseSession session,
    List<AbuseRiskAssessment> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<AbuseRiskAssessment>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [AbuseRiskAssessment] and returns the inserted row.
  ///
  /// The returned [AbuseRiskAssessment] will have its `id` field set.
  Future<AbuseRiskAssessment> insertRow(
    _is.DatabaseSession session,
    AbuseRiskAssessment row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<AbuseRiskAssessment>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [AbuseRiskAssessment]s in the list and returns the resulting rows.
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
  /// The returned [AbuseRiskAssessment]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AbuseRiskAssessment>> upsert(
    _is.DatabaseSession session,
    List<AbuseRiskAssessment> rows, {
    required _is.ColumnSelections<AbuseRiskAssessmentTable> conflictColumns,
    _is.ColumnSelections<AbuseRiskAssessmentTable>? updateColumns,
    _is.WhereExpressionBuilder<AbuseRiskAssessmentTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<AbuseRiskAssessment>(
      rows,
      conflictColumns: conflictColumns(AbuseRiskAssessment.t),
      updateColumns: updateColumns?.call(AbuseRiskAssessment.t),
      updateWhere: updateWhere?.call(AbuseRiskAssessment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [AbuseRiskAssessment] and returns the resulting row.
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
  /// The returned [AbuseRiskAssessment] will have its `id` field set.
  Future<AbuseRiskAssessment?> upsertRow(
    _is.DatabaseSession session,
    AbuseRiskAssessment row, {
    required _is.ColumnSelections<AbuseRiskAssessmentTable> conflictColumns,
    _is.ColumnSelections<AbuseRiskAssessmentTable>? updateColumns,
    _is.WhereExpressionBuilder<AbuseRiskAssessmentTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<AbuseRiskAssessment>(
      row,
      conflictColumns: conflictColumns(AbuseRiskAssessment.t),
      updateColumns: updateColumns?.call(AbuseRiskAssessment.t),
      updateWhere: updateWhere?.call(AbuseRiskAssessment.t),
      transaction: transaction,
    );
  }

  /// Updates all [AbuseRiskAssessment]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AbuseRiskAssessment>> update(
    _is.DatabaseSession session,
    List<AbuseRiskAssessment> rows, {
    _is.ColumnSelections<AbuseRiskAssessmentTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<AbuseRiskAssessment>(
      rows,
      columns: columns?.call(AbuseRiskAssessment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [AbuseRiskAssessment]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AbuseRiskAssessment> updateRow(
    _is.DatabaseSession session,
    AbuseRiskAssessment row, {
    _is.ColumnSelections<AbuseRiskAssessmentTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<AbuseRiskAssessment>(
      row,
      columns: columns?.call(AbuseRiskAssessment.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AbuseRiskAssessment] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AbuseRiskAssessment?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<AbuseRiskAssessmentUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<AbuseRiskAssessment>(
      id,
      columnValues: columnValues(AbuseRiskAssessment.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AbuseRiskAssessment]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AbuseRiskAssessment>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<AbuseRiskAssessmentUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<AbuseRiskAssessmentTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AbuseRiskAssessmentTable>? orderBy,
    _is.OrderByListBuilder<AbuseRiskAssessmentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<AbuseRiskAssessment>(
      columnValues: columnValues(AbuseRiskAssessment.t.updateTable),
      where: where(AbuseRiskAssessment.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AbuseRiskAssessment.t),
      orderByList: orderByList?.call(AbuseRiskAssessment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [AbuseRiskAssessment]s in the list and returns the deleted rows.
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
  Future<List<AbuseRiskAssessment>> delete(
    _is.DatabaseSession session,
    List<AbuseRiskAssessment> rows, {
    _is.OrderByBuilder<AbuseRiskAssessmentTable>? orderBy,
    _is.OrderByListBuilder<AbuseRiskAssessmentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<AbuseRiskAssessment>(
      rows,
      orderBy: orderBy?.call(AbuseRiskAssessment.t),
      orderByList: orderByList?.call(AbuseRiskAssessment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [AbuseRiskAssessment].
  Future<AbuseRiskAssessment> deleteRow(
    _is.DatabaseSession session,
    AbuseRiskAssessment row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AbuseRiskAssessment>(
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
  Future<List<AbuseRiskAssessment>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AbuseRiskAssessmentTable> where,
    _is.OrderByBuilder<AbuseRiskAssessmentTable>? orderBy,
    _is.OrderByListBuilder<AbuseRiskAssessmentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<AbuseRiskAssessment>(
      where: where(AbuseRiskAssessment.t),
      orderBy: orderBy?.call(AbuseRiskAssessment.t),
      orderByList: orderByList?.call(AbuseRiskAssessment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AbuseRiskAssessmentTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<AbuseRiskAssessment>(
      where: where?.call(AbuseRiskAssessment.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [AbuseRiskAssessment] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AbuseRiskAssessmentTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<AbuseRiskAssessment>(
      where: where(AbuseRiskAssessment.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
