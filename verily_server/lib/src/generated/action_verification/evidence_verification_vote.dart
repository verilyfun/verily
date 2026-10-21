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

/// Individual model signals and cost diagnostics; no vote independently grants a payout.
abstract class EvidenceVerificationVote
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  EvidenceVerificationVote._({
    this.id,
    required this.decisionId,
    required this.evidenceId,
    required this.modelId,
    this.resolvedModelId,
    this.providerName,
    this.responseId,
    required this.verdict,
    this.spokenChallengeVerdict,
    this.confidence,
    required this.latencyMilliseconds,
    this.inputTokens,
    this.outputTokens,
    this.costCredits,
    this.errorCode,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory EvidenceVerificationVote({
    _is.UuidValue? id,
    required _is.UuidValue decisionId,
    required _is.UuidValue evidenceId,
    required String modelId,
    String? resolvedModelId,
    String? providerName,
    String? responseId,
    required String verdict,
    String? spokenChallengeVerdict,
    double? confidence,
    required int latencyMilliseconds,
    int? inputTokens,
    int? outputTokens,
    double? costCredits,
    String? errorCode,
    DateTime? createdAt,
  }) = _EvidenceVerificationVoteImpl;

  factory EvidenceVerificationVote.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return EvidenceVerificationVote(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      decisionId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['decisionId'],
      ),
      evidenceId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['evidenceId'],
      ),
      modelId: jsonSerialization['modelId'] as String,
      resolvedModelId: jsonSerialization['resolvedModelId'] as String?,
      providerName: jsonSerialization['providerName'] as String?,
      responseId: jsonSerialization['responseId'] as String?,
      verdict: jsonSerialization['verdict'] as String,
      spokenChallengeVerdict:
          jsonSerialization['spokenChallengeVerdict'] as String?,
      confidence: (jsonSerialization['confidence'] as num?)?.toDouble(),
      latencyMilliseconds: jsonSerialization['latencyMilliseconds'] as int,
      inputTokens: jsonSerialization['inputTokens'] as int?,
      outputTokens: jsonSerialization['outputTokens'] as int?,
      costCredits: (jsonSerialization['costCredits'] as num?)?.toDouble(),
      errorCode: jsonSerialization['errorCode'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = EvidenceVerificationVoteTable();

  static const db = EvidenceVerificationVoteRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue decisionId;

  _is.UuidValue evidenceId;

  String modelId;

  String? resolvedModelId;

  String? providerName;

  String? responseId;

  String verdict;

  /// heard, notHeard, unclear, or abstained; null when no word was asked.
  String? spokenChallengeVerdict;

  double? confidence;

  int latencyMilliseconds;

  int? inputTokens;

  int? outputTokens;

  double? costCredits;

  String? errorCode;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [EvidenceVerificationVote]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  EvidenceVerificationVote copyWith({
    _is.UuidValue? id,
    _is.UuidValue? decisionId,
    _is.UuidValue? evidenceId,
    String? modelId,
    String? resolvedModelId,
    String? providerName,
    String? responseId,
    String? verdict,
    String? spokenChallengeVerdict,
    double? confidence,
    int? latencyMilliseconds,
    int? inputTokens,
    int? outputTokens,
    double? costCredits,
    String? errorCode,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'EvidenceVerificationVote',
      if (id != null) 'id': id?.toJson(),
      'decisionId': decisionId.toJson(),
      'evidenceId': evidenceId.toJson(),
      'modelId': modelId,
      if (resolvedModelId != null) 'resolvedModelId': resolvedModelId,
      if (providerName != null) 'providerName': providerName,
      if (responseId != null) 'responseId': responseId,
      'verdict': verdict,
      if (spokenChallengeVerdict != null)
        'spokenChallengeVerdict': spokenChallengeVerdict,
      if (confidence != null) 'confidence': confidence,
      'latencyMilliseconds': latencyMilliseconds,
      if (inputTokens != null) 'inputTokens': inputTokens,
      if (outputTokens != null) 'outputTokens': outputTokens,
      if (costCredits != null) 'costCredits': costCredits,
      if (errorCode != null) 'errorCode': errorCode,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static EvidenceVerificationVoteInclude include() {
    return EvidenceVerificationVoteInclude._();
  }

  static EvidenceVerificationVoteIncludeList includeList({
    _is.WhereExpressionBuilder<EvidenceVerificationVoteTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EvidenceVerificationVoteTable>? orderBy,
    _is.OrderByListBuilder<EvidenceVerificationVoteTable>? orderByList,
    EvidenceVerificationVoteInclude? include,
  }) {
    return EvidenceVerificationVoteIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EvidenceVerificationVote.t),
      orderByList: orderByList?.call(EvidenceVerificationVote.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _EvidenceVerificationVoteImpl extends EvidenceVerificationVote {
  _EvidenceVerificationVoteImpl({
    _is.UuidValue? id,
    required _is.UuidValue decisionId,
    required _is.UuidValue evidenceId,
    required String modelId,
    String? resolvedModelId,
    String? providerName,
    String? responseId,
    required String verdict,
    String? spokenChallengeVerdict,
    double? confidence,
    required int latencyMilliseconds,
    int? inputTokens,
    int? outputTokens,
    double? costCredits,
    String? errorCode,
    DateTime? createdAt,
  }) : super._(
         id: id,
         decisionId: decisionId,
         evidenceId: evidenceId,
         modelId: modelId,
         resolvedModelId: resolvedModelId,
         providerName: providerName,
         responseId: responseId,
         verdict: verdict,
         spokenChallengeVerdict: spokenChallengeVerdict,
         confidence: confidence,
         latencyMilliseconds: latencyMilliseconds,
         inputTokens: inputTokens,
         outputTokens: outputTokens,
         costCredits: costCredits,
         errorCode: errorCode,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [EvidenceVerificationVote]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  EvidenceVerificationVote copyWith({
    Object? id = _Undefined,
    _is.UuidValue? decisionId,
    _is.UuidValue? evidenceId,
    String? modelId,
    Object? resolvedModelId = _Undefined,
    Object? providerName = _Undefined,
    Object? responseId = _Undefined,
    String? verdict,
    Object? spokenChallengeVerdict = _Undefined,
    Object? confidence = _Undefined,
    int? latencyMilliseconds,
    Object? inputTokens = _Undefined,
    Object? outputTokens = _Undefined,
    Object? costCredits = _Undefined,
    Object? errorCode = _Undefined,
    DateTime? createdAt,
  }) {
    return EvidenceVerificationVote(
      id: id is _is.UuidValue? ? id : this.id,
      decisionId: decisionId ?? this.decisionId,
      evidenceId: evidenceId ?? this.evidenceId,
      modelId: modelId ?? this.modelId,
      resolvedModelId: resolvedModelId is String?
          ? resolvedModelId
          : this.resolvedModelId,
      providerName: providerName is String? ? providerName : this.providerName,
      responseId: responseId is String? ? responseId : this.responseId,
      verdict: verdict ?? this.verdict,
      spokenChallengeVerdict: spokenChallengeVerdict is String?
          ? spokenChallengeVerdict
          : this.spokenChallengeVerdict,
      confidence: confidence is double? ? confidence : this.confidence,
      latencyMilliseconds: latencyMilliseconds ?? this.latencyMilliseconds,
      inputTokens: inputTokens is int? ? inputTokens : this.inputTokens,
      outputTokens: outputTokens is int? ? outputTokens : this.outputTokens,
      costCredits: costCredits is double? ? costCredits : this.costCredits,
      errorCode: errorCode is String? ? errorCode : this.errorCode,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class EvidenceVerificationVoteUpdateTable
    extends _is.UpdateTable<EvidenceVerificationVoteTable> {
  EvidenceVerificationVoteUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> decisionId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.decisionId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> evidenceId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.evidenceId,
    value,
  );

  _is.ColumnValue<String, String> modelId(String value) => _is.ColumnValue(
    table.modelId,
    value,
  );

  _is.ColumnValue<String, String> resolvedModelId(String? value) =>
      _is.ColumnValue(
        table.resolvedModelId,
        value,
      );

  _is.ColumnValue<String, String> providerName(String? value) =>
      _is.ColumnValue(
        table.providerName,
        value,
      );

  _is.ColumnValue<String, String> responseId(String? value) => _is.ColumnValue(
    table.responseId,
    value,
  );

  _is.ColumnValue<String, String> verdict(String value) => _is.ColumnValue(
    table.verdict,
    value,
  );

  _is.ColumnValue<String, String> spokenChallengeVerdict(String? value) =>
      _is.ColumnValue(
        table.spokenChallengeVerdict,
        value,
      );

  _is.ColumnValue<double, double> confidence(double? value) => _is.ColumnValue(
    table.confidence,
    value,
  );

  _is.ColumnValue<int, int> latencyMilliseconds(int value) => _is.ColumnValue(
    table.latencyMilliseconds,
    value,
  );

  _is.ColumnValue<int, int> inputTokens(int? value) => _is.ColumnValue(
    table.inputTokens,
    value,
  );

  _is.ColumnValue<int, int> outputTokens(int? value) => _is.ColumnValue(
    table.outputTokens,
    value,
  );

  _is.ColumnValue<double, double> costCredits(double? value) => _is.ColumnValue(
    table.costCredits,
    value,
  );

  _is.ColumnValue<String, String> errorCode(String? value) => _is.ColumnValue(
    table.errorCode,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class EvidenceVerificationVoteTable extends _is.Table<_is.UuidValue?> {
  EvidenceVerificationVoteTable({super.tableRelation})
    : super(tableName: 'verily_evidence_verification_vote') {
    updateTable = EvidenceVerificationVoteUpdateTable(this);
    decisionId = _is.ColumnUuid(
      'decisionId',
      this,
    );
    evidenceId = _is.ColumnUuid(
      'evidenceId',
      this,
    );
    modelId = _is.ColumnString(
      'modelId',
      this,
    );
    resolvedModelId = _is.ColumnString(
      'resolvedModelId',
      this,
    );
    providerName = _is.ColumnString(
      'providerName',
      this,
    );
    responseId = _is.ColumnString(
      'responseId',
      this,
    );
    verdict = _is.ColumnString(
      'verdict',
      this,
    );
    spokenChallengeVerdict = _is.ColumnString(
      'spokenChallengeVerdict',
      this,
    );
    confidence = _is.ColumnDouble(
      'confidence',
      this,
    );
    latencyMilliseconds = _is.ColumnInt(
      'latencyMilliseconds',
      this,
    );
    inputTokens = _is.ColumnInt(
      'inputTokens',
      this,
    );
    outputTokens = _is.ColumnInt(
      'outputTokens',
      this,
    );
    costCredits = _is.ColumnDouble(
      'costCredits',
      this,
    );
    errorCode = _is.ColumnString(
      'errorCode',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final EvidenceVerificationVoteUpdateTable updateTable;

  late final _is.ColumnUuid decisionId;

  late final _is.ColumnUuid evidenceId;

  late final _is.ColumnString modelId;

  late final _is.ColumnString resolvedModelId;

  late final _is.ColumnString providerName;

  late final _is.ColumnString responseId;

  late final _is.ColumnString verdict;

  /// heard, notHeard, unclear, or abstained; null when no word was asked.
  late final _is.ColumnString spokenChallengeVerdict;

  late final _is.ColumnDouble confidence;

  late final _is.ColumnInt latencyMilliseconds;

  late final _is.ColumnInt inputTokens;

  late final _is.ColumnInt outputTokens;

  late final _is.ColumnDouble costCredits;

  late final _is.ColumnString errorCode;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    decisionId,
    evidenceId,
    modelId,
    resolvedModelId,
    providerName,
    responseId,
    verdict,
    spokenChallengeVerdict,
    confidence,
    latencyMilliseconds,
    inputTokens,
    outputTokens,
    costCredits,
    errorCode,
    createdAt,
  ];
}

class EvidenceVerificationVoteInclude extends _is.IncludeObject {
  EvidenceVerificationVoteInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<_is.UuidValue?> get table => EvidenceVerificationVote.t;
}

class EvidenceVerificationVoteIncludeList extends _is.IncludeList {
  EvidenceVerificationVoteIncludeList._({
    _is.WhereExpressionBuilder<EvidenceVerificationVoteTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(EvidenceVerificationVote.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => EvidenceVerificationVote.t;
}

class EvidenceVerificationVoteRepository {
  const EvidenceVerificationVoteRepository._();

  /// Returns a list of [EvidenceVerificationVote]s matching the given query parameters.
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
  Future<List<EvidenceVerificationVote>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EvidenceVerificationVoteTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EvidenceVerificationVoteTable>? orderBy,
    _is.OrderByListBuilder<EvidenceVerificationVoteTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<EvidenceVerificationVote>(
      where: where?.call(EvidenceVerificationVote.t),
      orderBy: orderBy?.call(EvidenceVerificationVote.t),
      orderByList: orderByList?.call(EvidenceVerificationVote.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [EvidenceVerificationVote] matching the given query parameters.
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
  Future<EvidenceVerificationVote?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EvidenceVerificationVoteTable>? where,
    int? offset,
    _is.OrderByBuilder<EvidenceVerificationVoteTable>? orderBy,
    _is.OrderByListBuilder<EvidenceVerificationVoteTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<EvidenceVerificationVote>(
      where: where?.call(EvidenceVerificationVote.t),
      orderBy: orderBy?.call(EvidenceVerificationVote.t),
      orderByList: orderByList?.call(EvidenceVerificationVote.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [EvidenceVerificationVote] by its [id] or null if no such row exists.
  Future<EvidenceVerificationVote?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<EvidenceVerificationVote>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [EvidenceVerificationVote]s in the list and returns the inserted rows.
  ///
  /// The returned [EvidenceVerificationVote]s will have their `id` fields set.
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
  Future<List<EvidenceVerificationVote>> insert(
    _is.DatabaseSession session,
    List<EvidenceVerificationVote> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<EvidenceVerificationVote>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [EvidenceVerificationVote] and returns the inserted row.
  ///
  /// The returned [EvidenceVerificationVote] will have its `id` field set.
  Future<EvidenceVerificationVote> insertRow(
    _is.DatabaseSession session,
    EvidenceVerificationVote row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<EvidenceVerificationVote>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [EvidenceVerificationVote]s in the list and returns the resulting rows.
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
  /// The returned [EvidenceVerificationVote]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<EvidenceVerificationVote>> upsert(
    _is.DatabaseSession session,
    List<EvidenceVerificationVote> rows, {
    required _is.ColumnSelections<EvidenceVerificationVoteTable>
    conflictColumns,
    _is.ColumnSelections<EvidenceVerificationVoteTable>? updateColumns,
    _is.WhereExpressionBuilder<EvidenceVerificationVoteTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<EvidenceVerificationVote>(
      rows,
      conflictColumns: conflictColumns(EvidenceVerificationVote.t),
      updateColumns: updateColumns?.call(EvidenceVerificationVote.t),
      updateWhere: updateWhere?.call(EvidenceVerificationVote.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [EvidenceVerificationVote] and returns the resulting row.
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
  /// The returned [EvidenceVerificationVote] will have its `id` field set.
  Future<EvidenceVerificationVote?> upsertRow(
    _is.DatabaseSession session,
    EvidenceVerificationVote row, {
    required _is.ColumnSelections<EvidenceVerificationVoteTable>
    conflictColumns,
    _is.ColumnSelections<EvidenceVerificationVoteTable>? updateColumns,
    _is.WhereExpressionBuilder<EvidenceVerificationVoteTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<EvidenceVerificationVote>(
      row,
      conflictColumns: conflictColumns(EvidenceVerificationVote.t),
      updateColumns: updateColumns?.call(EvidenceVerificationVote.t),
      updateWhere: updateWhere?.call(EvidenceVerificationVote.t),
      transaction: transaction,
    );
  }

  /// Updates all [EvidenceVerificationVote]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<EvidenceVerificationVote>> update(
    _is.DatabaseSession session,
    List<EvidenceVerificationVote> rows, {
    _is.ColumnSelections<EvidenceVerificationVoteTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<EvidenceVerificationVote>(
      rows,
      columns: columns?.call(EvidenceVerificationVote.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [EvidenceVerificationVote]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<EvidenceVerificationVote> updateRow(
    _is.DatabaseSession session,
    EvidenceVerificationVote row, {
    _is.ColumnSelections<EvidenceVerificationVoteTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<EvidenceVerificationVote>(
      row,
      columns: columns?.call(EvidenceVerificationVote.t),
      transaction: transaction,
    );
  }

  /// Updates a single [EvidenceVerificationVote] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<EvidenceVerificationVote?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<EvidenceVerificationVoteUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<EvidenceVerificationVote>(
      id,
      columnValues: columnValues(EvidenceVerificationVote.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [EvidenceVerificationVote]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<EvidenceVerificationVote>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<EvidenceVerificationVoteUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<EvidenceVerificationVoteTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EvidenceVerificationVoteTable>? orderBy,
    _is.OrderByListBuilder<EvidenceVerificationVoteTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<EvidenceVerificationVote>(
      columnValues: columnValues(EvidenceVerificationVote.t.updateTable),
      where: where(EvidenceVerificationVote.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EvidenceVerificationVote.t),
      orderByList: orderByList?.call(EvidenceVerificationVote.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [EvidenceVerificationVote]s in the list and returns the deleted rows.
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
  Future<List<EvidenceVerificationVote>> delete(
    _is.DatabaseSession session,
    List<EvidenceVerificationVote> rows, {
    _is.OrderByBuilder<EvidenceVerificationVoteTable>? orderBy,
    _is.OrderByListBuilder<EvidenceVerificationVoteTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<EvidenceVerificationVote>(
      rows,
      orderBy: orderBy?.call(EvidenceVerificationVote.t),
      orderByList: orderByList?.call(EvidenceVerificationVote.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [EvidenceVerificationVote].
  Future<EvidenceVerificationVote> deleteRow(
    _is.DatabaseSession session,
    EvidenceVerificationVote row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<EvidenceVerificationVote>(
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
  Future<List<EvidenceVerificationVote>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<EvidenceVerificationVoteTable> where,
    _is.OrderByBuilder<EvidenceVerificationVoteTable>? orderBy,
    _is.OrderByListBuilder<EvidenceVerificationVoteTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<EvidenceVerificationVote>(
      where: where(EvidenceVerificationVote.t),
      orderBy: orderBy?.call(EvidenceVerificationVote.t),
      orderByList: orderByList?.call(EvidenceVerificationVote.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EvidenceVerificationVoteTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<EvidenceVerificationVote>(
      where: where?.call(EvidenceVerificationVote.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [EvidenceVerificationVote] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<EvidenceVerificationVoteTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<EvidenceVerificationVote>(
      where: where(EvidenceVerificationVote.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
