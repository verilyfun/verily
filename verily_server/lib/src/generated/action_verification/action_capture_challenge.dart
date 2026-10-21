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

/// A capture window opened before anything is recorded. Its nonce derives the
/// per-capture key's attestation challenge, and with the evidence fingerprint
/// the Play Integrity request hash, so proof made before the window opened
/// cannot be vouched for.
abstract class ActionCaptureChallenge
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  ActionCaptureChallenge._({
    this.id,
    required this.attemptId,
    required this.requirementId,
    required this.participantAuthUserId,
    this.participantAuthUser,
    required this.nonce,
    this.requestHash,
    this.evidenceBindingHash,
    required this.expiresAt,
    this.usedAt,
    this.provider,
    this.verdict,
    this.tokenHash,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ActionCaptureChallenge({
    _is.UuidValue? id,
    required _is.UuidValue attemptId,
    required _is.UuidValue requirementId,
    required _is.UuidValue participantAuthUserId,
    _iacs.AuthUser? participantAuthUser,
    required String nonce,
    String? requestHash,
    String? evidenceBindingHash,
    required DateTime expiresAt,
    DateTime? usedAt,
    String? provider,
    String? verdict,
    String? tokenHash,
    DateTime? createdAt,
  }) = _ActionCaptureChallengeImpl;

  factory ActionCaptureChallenge.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ActionCaptureChallenge(
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
      nonce: jsonSerialization['nonce'] as String,
      requestHash: jsonSerialization['requestHash'] as String?,
      evidenceBindingHash: jsonSerialization['evidenceBindingHash'] as String?,
      expiresAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      usedAt: jsonSerialization['usedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['usedAt']),
      provider: jsonSerialization['provider'] as String?,
      verdict: jsonSerialization['verdict'] as String?,
      tokenHash: jsonSerialization['tokenHash'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = ActionCaptureChallengeTable();

  static const db = ActionCaptureChallengeRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue attemptId;

  _is.UuidValue requirementId;

  _is.UuidValue participantAuthUserId;

  _iacs.AuthUser? participantAuthUser;

  /// 32 random bytes, unpadded base64url.
  String nonce;

  /// Filled when the proof arrives: the request hash Play Integrity had to
  /// answer and the evidence fingerprint the server recomputed.
  String? requestHash;

  String? evidenceBindingHash;

  DateTime expiresAt;

  DateTime? usedAt;

  String? provider;

  String? verdict;

  String? tokenHash;

  /// When the window opened: proof captured before it is refused.
  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [ActionCaptureChallenge]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ActionCaptureChallenge copyWith({
    _is.UuidValue? id,
    _is.UuidValue? attemptId,
    _is.UuidValue? requirementId,
    _is.UuidValue? participantAuthUserId,
    _iacs.AuthUser? participantAuthUser,
    String? nonce,
    String? requestHash,
    String? evidenceBindingHash,
    DateTime? expiresAt,
    DateTime? usedAt,
    String? provider,
    String? verdict,
    String? tokenHash,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActionCaptureChallenge',
      if (id != null) 'id': id?.toJson(),
      'attemptId': attemptId.toJson(),
      'requirementId': requirementId.toJson(),
      'participantAuthUserId': participantAuthUserId.toJson(),
      if (participantAuthUser != null)
        'participantAuthUser': participantAuthUser?.toJson(),
      'nonce': nonce,
      if (requestHash != null) 'requestHash': requestHash,
      if (evidenceBindingHash != null)
        'evidenceBindingHash': evidenceBindingHash,
      'expiresAt': expiresAt.toJson(),
      if (usedAt != null) 'usedAt': usedAt?.toJson(),
      if (provider != null) 'provider': provider,
      if (verdict != null) 'verdict': verdict,
      if (tokenHash != null) 'tokenHash': tokenHash,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ActionCaptureChallengeInclude include({
    _iacs.AuthUserInclude? participantAuthUser,
  }) {
    return ActionCaptureChallengeInclude._(
      participantAuthUser: participantAuthUser,
    );
  }

  static ActionCaptureChallengeIncludeList includeList({
    _is.WhereExpressionBuilder<ActionCaptureChallengeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionCaptureChallengeTable>? orderBy,
    _is.OrderByListBuilder<ActionCaptureChallengeTable>? orderByList,
    ActionCaptureChallengeInclude? include,
  }) {
    return ActionCaptureChallengeIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ActionCaptureChallenge.t),
      orderByList: orderByList?.call(ActionCaptureChallenge.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ActionCaptureChallengeImpl extends ActionCaptureChallenge {
  _ActionCaptureChallengeImpl({
    _is.UuidValue? id,
    required _is.UuidValue attemptId,
    required _is.UuidValue requirementId,
    required _is.UuidValue participantAuthUserId,
    _iacs.AuthUser? participantAuthUser,
    required String nonce,
    String? requestHash,
    String? evidenceBindingHash,
    required DateTime expiresAt,
    DateTime? usedAt,
    String? provider,
    String? verdict,
    String? tokenHash,
    DateTime? createdAt,
  }) : super._(
         id: id,
         attemptId: attemptId,
         requirementId: requirementId,
         participantAuthUserId: participantAuthUserId,
         participantAuthUser: participantAuthUser,
         nonce: nonce,
         requestHash: requestHash,
         evidenceBindingHash: evidenceBindingHash,
         expiresAt: expiresAt,
         usedAt: usedAt,
         provider: provider,
         verdict: verdict,
         tokenHash: tokenHash,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ActionCaptureChallenge]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ActionCaptureChallenge copyWith({
    Object? id = _Undefined,
    _is.UuidValue? attemptId,
    _is.UuidValue? requirementId,
    _is.UuidValue? participantAuthUserId,
    Object? participantAuthUser = _Undefined,
    String? nonce,
    Object? requestHash = _Undefined,
    Object? evidenceBindingHash = _Undefined,
    DateTime? expiresAt,
    Object? usedAt = _Undefined,
    Object? provider = _Undefined,
    Object? verdict = _Undefined,
    Object? tokenHash = _Undefined,
    DateTime? createdAt,
  }) {
    return ActionCaptureChallenge(
      id: id is _is.UuidValue? ? id : this.id,
      attemptId: attemptId ?? this.attemptId,
      requirementId: requirementId ?? this.requirementId,
      participantAuthUserId:
          participantAuthUserId ?? this.participantAuthUserId,
      participantAuthUser: participantAuthUser is _iacs.AuthUser?
          ? participantAuthUser
          : this.participantAuthUser?.copyWith(),
      nonce: nonce ?? this.nonce,
      requestHash: requestHash is String? ? requestHash : this.requestHash,
      evidenceBindingHash: evidenceBindingHash is String?
          ? evidenceBindingHash
          : this.evidenceBindingHash,
      expiresAt: expiresAt ?? this.expiresAt,
      usedAt: usedAt is DateTime? ? usedAt : this.usedAt,
      provider: provider is String? ? provider : this.provider,
      verdict: verdict is String? ? verdict : this.verdict,
      tokenHash: tokenHash is String? ? tokenHash : this.tokenHash,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ActionCaptureChallengeUpdateTable
    extends _is.UpdateTable<ActionCaptureChallengeTable> {
  ActionCaptureChallengeUpdateTable(super.table);

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

  _is.ColumnValue<String, String> nonce(String value) => _is.ColumnValue(
    table.nonce,
    value,
  );

  _is.ColumnValue<String, String> requestHash(String? value) => _is.ColumnValue(
    table.requestHash,
    value,
  );

  _is.ColumnValue<String, String> evidenceBindingHash(String? value) =>
      _is.ColumnValue(
        table.evidenceBindingHash,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> expiresAt(DateTime value) =>
      _is.ColumnValue(
        table.expiresAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> usedAt(DateTime? value) =>
      _is.ColumnValue(
        table.usedAt,
        value,
      );

  _is.ColumnValue<String, String> provider(String? value) => _is.ColumnValue(
    table.provider,
    value,
  );

  _is.ColumnValue<String, String> verdict(String? value) => _is.ColumnValue(
    table.verdict,
    value,
  );

  _is.ColumnValue<String, String> tokenHash(String? value) => _is.ColumnValue(
    table.tokenHash,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class ActionCaptureChallengeTable extends _is.Table<_is.UuidValue?> {
  ActionCaptureChallengeTable({super.tableRelation})
    : super(tableName: 'verily_action_capture_challenge') {
    updateTable = ActionCaptureChallengeUpdateTable(this);
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
    nonce = _is.ColumnString(
      'nonce',
      this,
    );
    requestHash = _is.ColumnString(
      'requestHash',
      this,
    );
    evidenceBindingHash = _is.ColumnString(
      'evidenceBindingHash',
      this,
    );
    expiresAt = _is.ColumnDateTime(
      'expiresAt',
      this,
    );
    usedAt = _is.ColumnDateTime(
      'usedAt',
      this,
    );
    provider = _is.ColumnString(
      'provider',
      this,
    );
    verdict = _is.ColumnString(
      'verdict',
      this,
    );
    tokenHash = _is.ColumnString(
      'tokenHash',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final ActionCaptureChallengeUpdateTable updateTable;

  late final _is.ColumnUuid attemptId;

  late final _is.ColumnUuid requirementId;

  late final _is.ColumnUuid participantAuthUserId;

  _iacs.AuthUserTable? _participantAuthUser;

  /// 32 random bytes, unpadded base64url.
  late final _is.ColumnString nonce;

  /// Filled when the proof arrives: the request hash Play Integrity had to
  /// answer and the evidence fingerprint the server recomputed.
  late final _is.ColumnString requestHash;

  late final _is.ColumnString evidenceBindingHash;

  late final _is.ColumnDateTime expiresAt;

  late final _is.ColumnDateTime usedAt;

  late final _is.ColumnString provider;

  late final _is.ColumnString verdict;

  late final _is.ColumnString tokenHash;

  /// When the window opened: proof captured before it is refused.
  late final _is.ColumnDateTime createdAt;

  _iacs.AuthUserTable get participantAuthUser {
    if (_participantAuthUser != null) return _participantAuthUser!;
    _participantAuthUser = _is.createRelationTable(
      relationFieldName: 'participantAuthUser',
      field: ActionCaptureChallenge.t.participantAuthUserId,
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
    nonce,
    requestHash,
    evidenceBindingHash,
    expiresAt,
    usedAt,
    provider,
    verdict,
    tokenHash,
    createdAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'participantAuthUser') {
      return participantAuthUser;
    }
    return null;
  }
}

class ActionCaptureChallengeInclude extends _is.IncludeObject {
  ActionCaptureChallengeInclude._({
    _iacs.AuthUserInclude? participantAuthUser,
  }) {
    _participantAuthUser = participantAuthUser;
  }

  _iacs.AuthUserInclude? _participantAuthUser;

  @override
  Map<String, _is.Include?> get includes => {
    'participantAuthUser': _participantAuthUser,
  };

  @override
  _is.Table<_is.UuidValue?> get table => ActionCaptureChallenge.t;
}

class ActionCaptureChallengeIncludeList extends _is.IncludeList {
  ActionCaptureChallengeIncludeList._({
    _is.WhereExpressionBuilder<ActionCaptureChallengeTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ActionCaptureChallenge.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => ActionCaptureChallenge.t;
}

class ActionCaptureChallengeRepository {
  const ActionCaptureChallengeRepository._();

  final attachRow = const ActionCaptureChallengeAttachRowRepository._();

  /// Returns a list of [ActionCaptureChallenge]s matching the given query parameters.
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
  Future<List<ActionCaptureChallenge>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionCaptureChallengeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionCaptureChallengeTable>? orderBy,
    _is.OrderByListBuilder<ActionCaptureChallengeTable>? orderByList,
    _is.Transaction? transaction,
    ActionCaptureChallengeInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ActionCaptureChallenge>(
      where: where?.call(ActionCaptureChallenge.t),
      orderBy: orderBy?.call(ActionCaptureChallenge.t),
      orderByList: orderByList?.call(ActionCaptureChallenge.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ActionCaptureChallenge] matching the given query parameters.
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
  Future<ActionCaptureChallenge?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionCaptureChallengeTable>? where,
    int? offset,
    _is.OrderByBuilder<ActionCaptureChallengeTable>? orderBy,
    _is.OrderByListBuilder<ActionCaptureChallengeTable>? orderByList,
    _is.Transaction? transaction,
    ActionCaptureChallengeInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ActionCaptureChallenge>(
      where: where?.call(ActionCaptureChallenge.t),
      orderBy: orderBy?.call(ActionCaptureChallenge.t),
      orderByList: orderByList?.call(ActionCaptureChallenge.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ActionCaptureChallenge] by its [id] or null if no such row exists.
  Future<ActionCaptureChallenge?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    ActionCaptureChallengeInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ActionCaptureChallenge>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ActionCaptureChallenge]s in the list and returns the inserted rows.
  ///
  /// The returned [ActionCaptureChallenge]s will have their `id` fields set.
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
  Future<List<ActionCaptureChallenge>> insert(
    _is.DatabaseSession session,
    List<ActionCaptureChallenge> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ActionCaptureChallenge>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ActionCaptureChallenge] and returns the inserted row.
  ///
  /// The returned [ActionCaptureChallenge] will have its `id` field set.
  Future<ActionCaptureChallenge> insertRow(
    _is.DatabaseSession session,
    ActionCaptureChallenge row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ActionCaptureChallenge>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ActionCaptureChallenge]s in the list and returns the resulting rows.
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
  /// The returned [ActionCaptureChallenge]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionCaptureChallenge>> upsert(
    _is.DatabaseSession session,
    List<ActionCaptureChallenge> rows, {
    required _is.ColumnSelections<ActionCaptureChallengeTable> conflictColumns,
    _is.ColumnSelections<ActionCaptureChallengeTable>? updateColumns,
    _is.WhereExpressionBuilder<ActionCaptureChallengeTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ActionCaptureChallenge>(
      rows,
      conflictColumns: conflictColumns(ActionCaptureChallenge.t),
      updateColumns: updateColumns?.call(ActionCaptureChallenge.t),
      updateWhere: updateWhere?.call(ActionCaptureChallenge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ActionCaptureChallenge] and returns the resulting row.
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
  /// The returned [ActionCaptureChallenge] will have its `id` field set.
  Future<ActionCaptureChallenge?> upsertRow(
    _is.DatabaseSession session,
    ActionCaptureChallenge row, {
    required _is.ColumnSelections<ActionCaptureChallengeTable> conflictColumns,
    _is.ColumnSelections<ActionCaptureChallengeTable>? updateColumns,
    _is.WhereExpressionBuilder<ActionCaptureChallengeTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ActionCaptureChallenge>(
      row,
      conflictColumns: conflictColumns(ActionCaptureChallenge.t),
      updateColumns: updateColumns?.call(ActionCaptureChallenge.t),
      updateWhere: updateWhere?.call(ActionCaptureChallenge.t),
      transaction: transaction,
    );
  }

  /// Updates all [ActionCaptureChallenge]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionCaptureChallenge>> update(
    _is.DatabaseSession session,
    List<ActionCaptureChallenge> rows, {
    _is.ColumnSelections<ActionCaptureChallengeTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ActionCaptureChallenge>(
      rows,
      columns: columns?.call(ActionCaptureChallenge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ActionCaptureChallenge]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ActionCaptureChallenge> updateRow(
    _is.DatabaseSession session,
    ActionCaptureChallenge row, {
    _is.ColumnSelections<ActionCaptureChallengeTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ActionCaptureChallenge>(
      row,
      columns: columns?.call(ActionCaptureChallenge.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ActionCaptureChallenge] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ActionCaptureChallenge?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<ActionCaptureChallengeUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ActionCaptureChallenge>(
      id,
      columnValues: columnValues(ActionCaptureChallenge.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ActionCaptureChallenge]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionCaptureChallenge>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ActionCaptureChallengeUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<ActionCaptureChallengeTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionCaptureChallengeTable>? orderBy,
    _is.OrderByListBuilder<ActionCaptureChallengeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ActionCaptureChallenge>(
      columnValues: columnValues(ActionCaptureChallenge.t.updateTable),
      where: where(ActionCaptureChallenge.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ActionCaptureChallenge.t),
      orderByList: orderByList?.call(ActionCaptureChallenge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ActionCaptureChallenge]s in the list and returns the deleted rows.
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
  Future<List<ActionCaptureChallenge>> delete(
    _is.DatabaseSession session,
    List<ActionCaptureChallenge> rows, {
    _is.OrderByBuilder<ActionCaptureChallengeTable>? orderBy,
    _is.OrderByListBuilder<ActionCaptureChallengeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ActionCaptureChallenge>(
      rows,
      orderBy: orderBy?.call(ActionCaptureChallenge.t),
      orderByList: orderByList?.call(ActionCaptureChallenge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ActionCaptureChallenge].
  Future<ActionCaptureChallenge> deleteRow(
    _is.DatabaseSession session,
    ActionCaptureChallenge row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ActionCaptureChallenge>(
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
  Future<List<ActionCaptureChallenge>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ActionCaptureChallengeTable> where,
    _is.OrderByBuilder<ActionCaptureChallengeTable>? orderBy,
    _is.OrderByListBuilder<ActionCaptureChallengeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ActionCaptureChallenge>(
      where: where(ActionCaptureChallenge.t),
      orderBy: orderBy?.call(ActionCaptureChallenge.t),
      orderByList: orderByList?.call(ActionCaptureChallenge.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionCaptureChallengeTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ActionCaptureChallenge>(
      where: where?.call(ActionCaptureChallenge.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ActionCaptureChallenge] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ActionCaptureChallengeTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ActionCaptureChallenge>(
      where: where(ActionCaptureChallenge.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class ActionCaptureChallengeAttachRowRepository {
  const ActionCaptureChallengeAttachRowRepository._();

  /// Creates a relation between the given [ActionCaptureChallenge] and [AuthUser]
  /// by setting the [ActionCaptureChallenge]'s foreign key `participantAuthUserId` to refer to the [AuthUser].
  Future<void> participantAuthUser(
    _is.DatabaseSession session,
    ActionCaptureChallenge actionCaptureChallenge,
    _iacs.AuthUser participantAuthUser, {
    _is.Transaction? transaction,
  }) async {
    if (actionCaptureChallenge.id == null) {
      throw ArgumentError.notNull('actionCaptureChallenge.id');
    }
    if (participantAuthUser.id == null) {
      throw ArgumentError.notNull('participantAuthUser.id');
    }

    var $actionCaptureChallenge = actionCaptureChallenge.copyWith(
      participantAuthUserId: participantAuthUser.id,
    );
    await session.db.updateRow<ActionCaptureChallenge>(
      $actionCaptureChallenge,
      columns: [ActionCaptureChallenge.t.participantAuthUserId],
      transaction: transaction,
    );
  }
}
