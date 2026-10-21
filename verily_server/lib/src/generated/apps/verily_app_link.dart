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

/// Maps a Verily-issued, App-scoped subject to one participant account. The
/// subject is opaque and differs per App, so two Apps cannot correlate people.
abstract class VerilyAppLink
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  VerilyAppLink._({
    this.id,
    required this.appId,
    required this.authUserId,
    this.authUser,
    required this.subject,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory VerilyAppLink({
    _is.UuidValue? id,
    required _is.UuidValue appId,
    required _is.UuidValue authUserId,
    _iacs.AuthUser? authUser,
    required String subject,
    DateTime? createdAt,
  }) = _VerilyAppLinkImpl;

  factory VerilyAppLink.fromJson(Map<String, dynamic> jsonSerialization) {
    return VerilyAppLink(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      appId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['appId']),
      authUserId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['authUserId'],
      ),
      authUser: jsonSerialization['authUser'] == null
          ? null
          : _itf691yl.Protocol().deserialize<_iacs.AuthUser>(
              jsonSerialization['authUser'],
            ),
      subject: jsonSerialization['subject'] as String,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = VerilyAppLinkTable();

  static const db = VerilyAppLinkRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue appId;

  _is.UuidValue authUserId;

  _iacs.AuthUser? authUser;

  String subject;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [VerilyAppLink]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  VerilyAppLink copyWith({
    _is.UuidValue? id,
    _is.UuidValue? appId,
    _is.UuidValue? authUserId,
    _iacs.AuthUser? authUser,
    String? subject,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'VerilyAppLink',
      if (id != null) 'id': id?.toJson(),
      'appId': appId.toJson(),
      'authUserId': authUserId.toJson(),
      if (authUser != null) 'authUser': authUser?.toJson(),
      'subject': subject,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static VerilyAppLinkInclude include({_iacs.AuthUserInclude? authUser}) {
    return VerilyAppLinkInclude._(authUser: authUser);
  }

  static VerilyAppLinkIncludeList includeList({
    _is.WhereExpressionBuilder<VerilyAppLinkTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VerilyAppLinkTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppLinkTable>? orderByList,
    VerilyAppLinkInclude? include,
  }) {
    return VerilyAppLinkIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(VerilyAppLink.t),
      orderByList: orderByList?.call(VerilyAppLink.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _VerilyAppLinkImpl extends VerilyAppLink {
  _VerilyAppLinkImpl({
    _is.UuidValue? id,
    required _is.UuidValue appId,
    required _is.UuidValue authUserId,
    _iacs.AuthUser? authUser,
    required String subject,
    DateTime? createdAt,
  }) : super._(
         id: id,
         appId: appId,
         authUserId: authUserId,
         authUser: authUser,
         subject: subject,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [VerilyAppLink]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  VerilyAppLink copyWith({
    Object? id = _Undefined,
    _is.UuidValue? appId,
    _is.UuidValue? authUserId,
    Object? authUser = _Undefined,
    String? subject,
    DateTime? createdAt,
  }) {
    return VerilyAppLink(
      id: id is _is.UuidValue? ? id : this.id,
      appId: appId ?? this.appId,
      authUserId: authUserId ?? this.authUserId,
      authUser: authUser is _iacs.AuthUser?
          ? authUser
          : this.authUser?.copyWith(),
      subject: subject ?? this.subject,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class VerilyAppLinkUpdateTable extends _is.UpdateTable<VerilyAppLinkTable> {
  VerilyAppLinkUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> appId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.appId,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> authUserId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.authUserId,
    value,
  );

  _is.ColumnValue<String, String> subject(String value) => _is.ColumnValue(
    table.subject,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class VerilyAppLinkTable extends _is.Table<_is.UuidValue?> {
  VerilyAppLinkTable({super.tableRelation})
    : super(tableName: 'verily_app_link') {
    updateTable = VerilyAppLinkUpdateTable(this);
    appId = _is.ColumnUuid(
      'appId',
      this,
    );
    authUserId = _is.ColumnUuid(
      'authUserId',
      this,
    );
    subject = _is.ColumnString(
      'subject',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final VerilyAppLinkUpdateTable updateTable;

  late final _is.ColumnUuid appId;

  late final _is.ColumnUuid authUserId;

  _iacs.AuthUserTable? _authUser;

  late final _is.ColumnString subject;

  late final _is.ColumnDateTime createdAt;

  _iacs.AuthUserTable get authUser {
    if (_authUser != null) return _authUser!;
    _authUser = _is.createRelationTable(
      relationFieldName: 'authUser',
      field: VerilyAppLink.t.authUserId,
      foreignField: _iacs.AuthUser.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iacs.AuthUserTable(tableRelation: foreignTableRelation),
    );
    return _authUser!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    appId,
    authUserId,
    subject,
    createdAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'authUser') {
      return authUser;
    }
    return null;
  }
}

class VerilyAppLinkInclude extends _is.IncludeObject {
  VerilyAppLinkInclude._({_iacs.AuthUserInclude? authUser}) {
    _authUser = authUser;
  }

  _iacs.AuthUserInclude? _authUser;

  @override
  Map<String, _is.Include?> get includes => {'authUser': _authUser};

  @override
  _is.Table<_is.UuidValue?> get table => VerilyAppLink.t;
}

class VerilyAppLinkIncludeList extends _is.IncludeList {
  VerilyAppLinkIncludeList._({
    _is.WhereExpressionBuilder<VerilyAppLinkTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(VerilyAppLink.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => VerilyAppLink.t;
}

class VerilyAppLinkRepository {
  const VerilyAppLinkRepository._();

  final attachRow = const VerilyAppLinkAttachRowRepository._();

  /// Returns a list of [VerilyAppLink]s matching the given query parameters.
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
  Future<List<VerilyAppLink>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VerilyAppLinkTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VerilyAppLinkTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppLinkTable>? orderByList,
    _is.Transaction? transaction,
    VerilyAppLinkInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<VerilyAppLink>(
      where: where?.call(VerilyAppLink.t),
      orderBy: orderBy?.call(VerilyAppLink.t),
      orderByList: orderByList?.call(VerilyAppLink.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [VerilyAppLink] matching the given query parameters.
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
  Future<VerilyAppLink?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VerilyAppLinkTable>? where,
    int? offset,
    _is.OrderByBuilder<VerilyAppLinkTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppLinkTable>? orderByList,
    _is.Transaction? transaction,
    VerilyAppLinkInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<VerilyAppLink>(
      where: where?.call(VerilyAppLink.t),
      orderBy: orderBy?.call(VerilyAppLink.t),
      orderByList: orderByList?.call(VerilyAppLink.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [VerilyAppLink] by its [id] or null if no such row exists.
  Future<VerilyAppLink?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    VerilyAppLinkInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<VerilyAppLink>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [VerilyAppLink]s in the list and returns the inserted rows.
  ///
  /// The returned [VerilyAppLink]s will have their `id` fields set.
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
  Future<List<VerilyAppLink>> insert(
    _is.DatabaseSession session,
    List<VerilyAppLink> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<VerilyAppLink>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [VerilyAppLink] and returns the inserted row.
  ///
  /// The returned [VerilyAppLink] will have its `id` field set.
  Future<VerilyAppLink> insertRow(
    _is.DatabaseSession session,
    VerilyAppLink row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<VerilyAppLink>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [VerilyAppLink]s in the list and returns the resulting rows.
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
  /// The returned [VerilyAppLink]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<VerilyAppLink>> upsert(
    _is.DatabaseSession session,
    List<VerilyAppLink> rows, {
    required _is.ColumnSelections<VerilyAppLinkTable> conflictColumns,
    _is.ColumnSelections<VerilyAppLinkTable>? updateColumns,
    _is.WhereExpressionBuilder<VerilyAppLinkTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<VerilyAppLink>(
      rows,
      conflictColumns: conflictColumns(VerilyAppLink.t),
      updateColumns: updateColumns?.call(VerilyAppLink.t),
      updateWhere: updateWhere?.call(VerilyAppLink.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [VerilyAppLink] and returns the resulting row.
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
  /// The returned [VerilyAppLink] will have its `id` field set.
  Future<VerilyAppLink?> upsertRow(
    _is.DatabaseSession session,
    VerilyAppLink row, {
    required _is.ColumnSelections<VerilyAppLinkTable> conflictColumns,
    _is.ColumnSelections<VerilyAppLinkTable>? updateColumns,
    _is.WhereExpressionBuilder<VerilyAppLinkTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<VerilyAppLink>(
      row,
      conflictColumns: conflictColumns(VerilyAppLink.t),
      updateColumns: updateColumns?.call(VerilyAppLink.t),
      updateWhere: updateWhere?.call(VerilyAppLink.t),
      transaction: transaction,
    );
  }

  /// Updates all [VerilyAppLink]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<VerilyAppLink>> update(
    _is.DatabaseSession session,
    List<VerilyAppLink> rows, {
    _is.ColumnSelections<VerilyAppLinkTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<VerilyAppLink>(
      rows,
      columns: columns?.call(VerilyAppLink.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [VerilyAppLink]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<VerilyAppLink> updateRow(
    _is.DatabaseSession session,
    VerilyAppLink row, {
    _is.ColumnSelections<VerilyAppLinkTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<VerilyAppLink>(
      row,
      columns: columns?.call(VerilyAppLink.t),
      transaction: transaction,
    );
  }

  /// Updates a single [VerilyAppLink] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<VerilyAppLink?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<VerilyAppLinkUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<VerilyAppLink>(
      id,
      columnValues: columnValues(VerilyAppLink.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [VerilyAppLink]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<VerilyAppLink>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<VerilyAppLinkUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<VerilyAppLinkTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VerilyAppLinkTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppLinkTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<VerilyAppLink>(
      columnValues: columnValues(VerilyAppLink.t.updateTable),
      where: where(VerilyAppLink.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(VerilyAppLink.t),
      orderByList: orderByList?.call(VerilyAppLink.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [VerilyAppLink]s in the list and returns the deleted rows.
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
  Future<List<VerilyAppLink>> delete(
    _is.DatabaseSession session,
    List<VerilyAppLink> rows, {
    _is.OrderByBuilder<VerilyAppLinkTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppLinkTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<VerilyAppLink>(
      rows,
      orderBy: orderBy?.call(VerilyAppLink.t),
      orderByList: orderByList?.call(VerilyAppLink.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [VerilyAppLink].
  Future<VerilyAppLink> deleteRow(
    _is.DatabaseSession session,
    VerilyAppLink row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<VerilyAppLink>(
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
  Future<List<VerilyAppLink>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<VerilyAppLinkTable> where,
    _is.OrderByBuilder<VerilyAppLinkTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppLinkTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<VerilyAppLink>(
      where: where(VerilyAppLink.t),
      orderBy: orderBy?.call(VerilyAppLink.t),
      orderByList: orderByList?.call(VerilyAppLink.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VerilyAppLinkTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<VerilyAppLink>(
      where: where?.call(VerilyAppLink.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [VerilyAppLink] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<VerilyAppLinkTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<VerilyAppLink>(
      where: where(VerilyAppLink.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class VerilyAppLinkAttachRowRepository {
  const VerilyAppLinkAttachRowRepository._();

  /// Creates a relation between the given [VerilyAppLink] and [AuthUser]
  /// by setting the [VerilyAppLink]'s foreign key `authUserId` to refer to the [AuthUser].
  Future<void> authUser(
    _is.DatabaseSession session,
    VerilyAppLink verilyAppLink,
    _iacs.AuthUser authUser, {
    _is.Transaction? transaction,
  }) async {
    if (verilyAppLink.id == null) {
      throw ArgumentError.notNull('verilyAppLink.id');
    }
    if (authUser.id == null) {
      throw ArgumentError.notNull('authUser.id');
    }

    var $verilyAppLink = verilyAppLink.copyWith(authUserId: authUser.id);
    await session.db.updateRow<VerilyAppLink>(
      $verilyAppLink,
      columns: [VerilyAppLink.t.authUserId],
      transaction: transaction,
    );
  }
}
