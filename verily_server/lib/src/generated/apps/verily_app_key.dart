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

/// Hashed API key. The plaintext credential is shown once and never stored.
abstract class VerilyAppKey
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  VerilyAppKey._({
    this.id,
    required this.appId,
    required this.keyId,
    required this.secretHash,
    DateTime? createdAt,
    this.lastUsedAt,
    this.revokedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory VerilyAppKey({
    _is.UuidValue? id,
    required _is.UuidValue appId,
    required String keyId,
    required String secretHash,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    DateTime? revokedAt,
  }) = _VerilyAppKeyImpl;

  factory VerilyAppKey.fromJson(Map<String, dynamic> jsonSerialization) {
    return VerilyAppKey(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      appId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['appId']),
      keyId: jsonSerialization['keyId'] as String,
      secretHash: jsonSerialization['secretHash'] as String,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      lastUsedAt: jsonSerialization['lastUsedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['lastUsedAt']),
      revokedAt: jsonSerialization['revokedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['revokedAt']),
    );
  }

  static final t = VerilyAppKeyTable();

  static const db = VerilyAppKeyRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue appId;

  /// Public lookup handle embedded in the credential (`vly_<keyId>.<secret>`).
  String keyId;

  /// SHA-256 of the complete credential string.
  String secretHash;

  DateTime createdAt;

  DateTime? lastUsedAt;

  DateTime? revokedAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [VerilyAppKey]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  VerilyAppKey copyWith({
    _is.UuidValue? id,
    _is.UuidValue? appId,
    String? keyId,
    String? secretHash,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    DateTime? revokedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'VerilyAppKey',
      if (id != null) 'id': id?.toJson(),
      'appId': appId.toJson(),
      'keyId': keyId,
      'secretHash': secretHash,
      'createdAt': createdAt.toJson(),
      if (lastUsedAt != null) 'lastUsedAt': lastUsedAt?.toJson(),
      if (revokedAt != null) 'revokedAt': revokedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static VerilyAppKeyInclude include() {
    return VerilyAppKeyInclude._();
  }

  static VerilyAppKeyIncludeList includeList({
    _is.WhereExpressionBuilder<VerilyAppKeyTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VerilyAppKeyTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppKeyTable>? orderByList,
    VerilyAppKeyInclude? include,
  }) {
    return VerilyAppKeyIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(VerilyAppKey.t),
      orderByList: orderByList?.call(VerilyAppKey.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _VerilyAppKeyImpl extends VerilyAppKey {
  _VerilyAppKeyImpl({
    _is.UuidValue? id,
    required _is.UuidValue appId,
    required String keyId,
    required String secretHash,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    DateTime? revokedAt,
  }) : super._(
         id: id,
         appId: appId,
         keyId: keyId,
         secretHash: secretHash,
         createdAt: createdAt,
         lastUsedAt: lastUsedAt,
         revokedAt: revokedAt,
       );

  /// Returns a shallow copy of this [VerilyAppKey]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  VerilyAppKey copyWith({
    Object? id = _Undefined,
    _is.UuidValue? appId,
    String? keyId,
    String? secretHash,
    DateTime? createdAt,
    Object? lastUsedAt = _Undefined,
    Object? revokedAt = _Undefined,
  }) {
    return VerilyAppKey(
      id: id is _is.UuidValue? ? id : this.id,
      appId: appId ?? this.appId,
      keyId: keyId ?? this.keyId,
      secretHash: secretHash ?? this.secretHash,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt is DateTime? ? lastUsedAt : this.lastUsedAt,
      revokedAt: revokedAt is DateTime? ? revokedAt : this.revokedAt,
    );
  }
}

class VerilyAppKeyUpdateTable extends _is.UpdateTable<VerilyAppKeyTable> {
  VerilyAppKeyUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> appId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.appId,
        value,
      );

  _is.ColumnValue<String, String> keyId(String value) => _is.ColumnValue(
    table.keyId,
    value,
  );

  _is.ColumnValue<String, String> secretHash(String value) => _is.ColumnValue(
    table.secretHash,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> lastUsedAt(DateTime? value) =>
      _is.ColumnValue(
        table.lastUsedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> revokedAt(DateTime? value) =>
      _is.ColumnValue(
        table.revokedAt,
        value,
      );
}

class VerilyAppKeyTable extends _is.Table<_is.UuidValue?> {
  VerilyAppKeyTable({super.tableRelation})
    : super(tableName: 'verily_app_key') {
    updateTable = VerilyAppKeyUpdateTable(this);
    appId = _is.ColumnUuid(
      'appId',
      this,
    );
    keyId = _is.ColumnString(
      'keyId',
      this,
    );
    secretHash = _is.ColumnString(
      'secretHash',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    lastUsedAt = _is.ColumnDateTime(
      'lastUsedAt',
      this,
    );
    revokedAt = _is.ColumnDateTime(
      'revokedAt',
      this,
    );
  }

  late final VerilyAppKeyUpdateTable updateTable;

  late final _is.ColumnUuid appId;

  /// Public lookup handle embedded in the credential (`vly_<keyId>.<secret>`).
  late final _is.ColumnString keyId;

  /// SHA-256 of the complete credential string.
  late final _is.ColumnString secretHash;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime lastUsedAt;

  late final _is.ColumnDateTime revokedAt;

  @override
  List<_is.Column> get columns => [
    id,
    appId,
    keyId,
    secretHash,
    createdAt,
    lastUsedAt,
    revokedAt,
  ];
}

class VerilyAppKeyInclude extends _is.IncludeObject {
  VerilyAppKeyInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<_is.UuidValue?> get table => VerilyAppKey.t;
}

class VerilyAppKeyIncludeList extends _is.IncludeList {
  VerilyAppKeyIncludeList._({
    _is.WhereExpressionBuilder<VerilyAppKeyTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(VerilyAppKey.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => VerilyAppKey.t;
}

class VerilyAppKeyRepository {
  const VerilyAppKeyRepository._();

  /// Returns a list of [VerilyAppKey]s matching the given query parameters.
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
  Future<List<VerilyAppKey>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VerilyAppKeyTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VerilyAppKeyTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppKeyTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<VerilyAppKey>(
      where: where?.call(VerilyAppKey.t),
      orderBy: orderBy?.call(VerilyAppKey.t),
      orderByList: orderByList?.call(VerilyAppKey.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [VerilyAppKey] matching the given query parameters.
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
  Future<VerilyAppKey?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VerilyAppKeyTable>? where,
    int? offset,
    _is.OrderByBuilder<VerilyAppKeyTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppKeyTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<VerilyAppKey>(
      where: where?.call(VerilyAppKey.t),
      orderBy: orderBy?.call(VerilyAppKey.t),
      orderByList: orderByList?.call(VerilyAppKey.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [VerilyAppKey] by its [id] or null if no such row exists.
  Future<VerilyAppKey?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<VerilyAppKey>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [VerilyAppKey]s in the list and returns the inserted rows.
  ///
  /// The returned [VerilyAppKey]s will have their `id` fields set.
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
  Future<List<VerilyAppKey>> insert(
    _is.DatabaseSession session,
    List<VerilyAppKey> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<VerilyAppKey>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [VerilyAppKey] and returns the inserted row.
  ///
  /// The returned [VerilyAppKey] will have its `id` field set.
  Future<VerilyAppKey> insertRow(
    _is.DatabaseSession session,
    VerilyAppKey row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<VerilyAppKey>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [VerilyAppKey]s in the list and returns the resulting rows.
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
  /// The returned [VerilyAppKey]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<VerilyAppKey>> upsert(
    _is.DatabaseSession session,
    List<VerilyAppKey> rows, {
    required _is.ColumnSelections<VerilyAppKeyTable> conflictColumns,
    _is.ColumnSelections<VerilyAppKeyTable>? updateColumns,
    _is.WhereExpressionBuilder<VerilyAppKeyTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<VerilyAppKey>(
      rows,
      conflictColumns: conflictColumns(VerilyAppKey.t),
      updateColumns: updateColumns?.call(VerilyAppKey.t),
      updateWhere: updateWhere?.call(VerilyAppKey.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [VerilyAppKey] and returns the resulting row.
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
  /// The returned [VerilyAppKey] will have its `id` field set.
  Future<VerilyAppKey?> upsertRow(
    _is.DatabaseSession session,
    VerilyAppKey row, {
    required _is.ColumnSelections<VerilyAppKeyTable> conflictColumns,
    _is.ColumnSelections<VerilyAppKeyTable>? updateColumns,
    _is.WhereExpressionBuilder<VerilyAppKeyTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<VerilyAppKey>(
      row,
      conflictColumns: conflictColumns(VerilyAppKey.t),
      updateColumns: updateColumns?.call(VerilyAppKey.t),
      updateWhere: updateWhere?.call(VerilyAppKey.t),
      transaction: transaction,
    );
  }

  /// Updates all [VerilyAppKey]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<VerilyAppKey>> update(
    _is.DatabaseSession session,
    List<VerilyAppKey> rows, {
    _is.ColumnSelections<VerilyAppKeyTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<VerilyAppKey>(
      rows,
      columns: columns?.call(VerilyAppKey.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [VerilyAppKey]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<VerilyAppKey> updateRow(
    _is.DatabaseSession session,
    VerilyAppKey row, {
    _is.ColumnSelections<VerilyAppKeyTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<VerilyAppKey>(
      row,
      columns: columns?.call(VerilyAppKey.t),
      transaction: transaction,
    );
  }

  /// Updates a single [VerilyAppKey] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<VerilyAppKey?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<VerilyAppKeyUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<VerilyAppKey>(
      id,
      columnValues: columnValues(VerilyAppKey.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [VerilyAppKey]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<VerilyAppKey>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<VerilyAppKeyUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<VerilyAppKeyTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VerilyAppKeyTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppKeyTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<VerilyAppKey>(
      columnValues: columnValues(VerilyAppKey.t.updateTable),
      where: where(VerilyAppKey.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(VerilyAppKey.t),
      orderByList: orderByList?.call(VerilyAppKey.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [VerilyAppKey]s in the list and returns the deleted rows.
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
  Future<List<VerilyAppKey>> delete(
    _is.DatabaseSession session,
    List<VerilyAppKey> rows, {
    _is.OrderByBuilder<VerilyAppKeyTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppKeyTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<VerilyAppKey>(
      rows,
      orderBy: orderBy?.call(VerilyAppKey.t),
      orderByList: orderByList?.call(VerilyAppKey.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [VerilyAppKey].
  Future<VerilyAppKey> deleteRow(
    _is.DatabaseSession session,
    VerilyAppKey row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<VerilyAppKey>(
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
  Future<List<VerilyAppKey>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<VerilyAppKeyTable> where,
    _is.OrderByBuilder<VerilyAppKeyTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppKeyTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<VerilyAppKey>(
      where: where(VerilyAppKey.t),
      orderBy: orderBy?.call(VerilyAppKey.t),
      orderByList: orderByList?.call(VerilyAppKey.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VerilyAppKeyTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<VerilyAppKey>(
      where: where?.call(VerilyAppKey.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [VerilyAppKey] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<VerilyAppKeyTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<VerilyAppKey>(
      where: where(VerilyAppKey.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
