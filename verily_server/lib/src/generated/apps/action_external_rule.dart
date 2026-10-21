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

import '../apps/app_verification_mode.dart' as _is7dtawb;

/// Binds one `external` requirement to the creator's App that may confirm it.
abstract class ActionExternalRule
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  ActionExternalRule._({
    this.id,
    required this.requirementId,
    required this.appId,
    _is7dtawb.AppVerificationMode? verificationMode,
  }) : verificationMode =
           verificationMode ?? _is7dtawb.AppVerificationMode.push;

  factory ActionExternalRule({
    _is.UuidValue? id,
    required _is.UuidValue requirementId,
    required _is.UuidValue appId,
    _is7dtawb.AppVerificationMode? verificationMode,
  }) = _ActionExternalRuleImpl;

  factory ActionExternalRule.fromJson(Map<String, dynamic> jsonSerialization) {
    return ActionExternalRule(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      requirementId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['requirementId'],
      ),
      appId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['appId']),
      verificationMode: jsonSerialization['verificationMode'] == null
          ? null
          : _is7dtawb.AppVerificationMode.fromJson(
              (jsonSerialization['verificationMode'] as String),
            ),
    );
  }

  static final t = ActionExternalRuleTable();

  static const db = ActionExternalRuleRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue requirementId;

  _is.UuidValue appId;

  _is7dtawb.AppVerificationMode verificationMode;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [ActionExternalRule]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ActionExternalRule copyWith({
    _is.UuidValue? id,
    _is.UuidValue? requirementId,
    _is.UuidValue? appId,
    _is7dtawb.AppVerificationMode? verificationMode,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActionExternalRule',
      if (id != null) 'id': id?.toJson(),
      'requirementId': requirementId.toJson(),
      'appId': appId.toJson(),
      'verificationMode': verificationMode.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ActionExternalRuleInclude include() {
    return ActionExternalRuleInclude._();
  }

  static ActionExternalRuleIncludeList includeList({
    _is.WhereExpressionBuilder<ActionExternalRuleTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionExternalRuleTable>? orderBy,
    _is.OrderByListBuilder<ActionExternalRuleTable>? orderByList,
    ActionExternalRuleInclude? include,
  }) {
    return ActionExternalRuleIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ActionExternalRule.t),
      orderByList: orderByList?.call(ActionExternalRule.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ActionExternalRuleImpl extends ActionExternalRule {
  _ActionExternalRuleImpl({
    _is.UuidValue? id,
    required _is.UuidValue requirementId,
    required _is.UuidValue appId,
    _is7dtawb.AppVerificationMode? verificationMode,
  }) : super._(
         id: id,
         requirementId: requirementId,
         appId: appId,
         verificationMode: verificationMode,
       );

  /// Returns a shallow copy of this [ActionExternalRule]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ActionExternalRule copyWith({
    Object? id = _Undefined,
    _is.UuidValue? requirementId,
    _is.UuidValue? appId,
    _is7dtawb.AppVerificationMode? verificationMode,
  }) {
    return ActionExternalRule(
      id: id is _is.UuidValue? ? id : this.id,
      requirementId: requirementId ?? this.requirementId,
      appId: appId ?? this.appId,
      verificationMode: verificationMode ?? this.verificationMode,
    );
  }
}

class ActionExternalRuleUpdateTable
    extends _is.UpdateTable<ActionExternalRuleTable> {
  ActionExternalRuleUpdateTable(super.table);

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

  _is.ColumnValue<_is7dtawb.AppVerificationMode, _is7dtawb.AppVerificationMode>
  verificationMode(_is7dtawb.AppVerificationMode value) => _is.ColumnValue(
    table.verificationMode,
    value,
  );
}

class ActionExternalRuleTable extends _is.Table<_is.UuidValue?> {
  ActionExternalRuleTable({super.tableRelation})
    : super(tableName: 'verily_action_external_rule') {
    updateTable = ActionExternalRuleUpdateTable(this);
    requirementId = _is.ColumnUuid(
      'requirementId',
      this,
    );
    appId = _is.ColumnUuid(
      'appId',
      this,
    );
    verificationMode = _is.ColumnEnum(
      'verificationMode',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
  }

  late final ActionExternalRuleUpdateTable updateTable;

  late final _is.ColumnUuid requirementId;

  late final _is.ColumnUuid appId;

  late final _is.ColumnEnum<_is7dtawb.AppVerificationMode> verificationMode;

  @override
  List<_is.Column> get columns => [
    id,
    requirementId,
    appId,
    verificationMode,
  ];
}

class ActionExternalRuleInclude extends _is.IncludeObject {
  ActionExternalRuleInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<_is.UuidValue?> get table => ActionExternalRule.t;
}

class ActionExternalRuleIncludeList extends _is.IncludeList {
  ActionExternalRuleIncludeList._({
    _is.WhereExpressionBuilder<ActionExternalRuleTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ActionExternalRule.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => ActionExternalRule.t;
}

class ActionExternalRuleRepository {
  const ActionExternalRuleRepository._();

  /// Returns a list of [ActionExternalRule]s matching the given query parameters.
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
  Future<List<ActionExternalRule>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionExternalRuleTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionExternalRuleTable>? orderBy,
    _is.OrderByListBuilder<ActionExternalRuleTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ActionExternalRule>(
      where: where?.call(ActionExternalRule.t),
      orderBy: orderBy?.call(ActionExternalRule.t),
      orderByList: orderByList?.call(ActionExternalRule.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ActionExternalRule] matching the given query parameters.
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
  Future<ActionExternalRule?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionExternalRuleTable>? where,
    int? offset,
    _is.OrderByBuilder<ActionExternalRuleTable>? orderBy,
    _is.OrderByListBuilder<ActionExternalRuleTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ActionExternalRule>(
      where: where?.call(ActionExternalRule.t),
      orderBy: orderBy?.call(ActionExternalRule.t),
      orderByList: orderByList?.call(ActionExternalRule.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ActionExternalRule] by its [id] or null if no such row exists.
  Future<ActionExternalRule?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ActionExternalRule>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ActionExternalRule]s in the list and returns the inserted rows.
  ///
  /// The returned [ActionExternalRule]s will have their `id` fields set.
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
  Future<List<ActionExternalRule>> insert(
    _is.DatabaseSession session,
    List<ActionExternalRule> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ActionExternalRule>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ActionExternalRule] and returns the inserted row.
  ///
  /// The returned [ActionExternalRule] will have its `id` field set.
  Future<ActionExternalRule> insertRow(
    _is.DatabaseSession session,
    ActionExternalRule row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ActionExternalRule>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ActionExternalRule]s in the list and returns the resulting rows.
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
  /// The returned [ActionExternalRule]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionExternalRule>> upsert(
    _is.DatabaseSession session,
    List<ActionExternalRule> rows, {
    required _is.ColumnSelections<ActionExternalRuleTable> conflictColumns,
    _is.ColumnSelections<ActionExternalRuleTable>? updateColumns,
    _is.WhereExpressionBuilder<ActionExternalRuleTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ActionExternalRule>(
      rows,
      conflictColumns: conflictColumns(ActionExternalRule.t),
      updateColumns: updateColumns?.call(ActionExternalRule.t),
      updateWhere: updateWhere?.call(ActionExternalRule.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ActionExternalRule] and returns the resulting row.
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
  /// The returned [ActionExternalRule] will have its `id` field set.
  Future<ActionExternalRule?> upsertRow(
    _is.DatabaseSession session,
    ActionExternalRule row, {
    required _is.ColumnSelections<ActionExternalRuleTable> conflictColumns,
    _is.ColumnSelections<ActionExternalRuleTable>? updateColumns,
    _is.WhereExpressionBuilder<ActionExternalRuleTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ActionExternalRule>(
      row,
      conflictColumns: conflictColumns(ActionExternalRule.t),
      updateColumns: updateColumns?.call(ActionExternalRule.t),
      updateWhere: updateWhere?.call(ActionExternalRule.t),
      transaction: transaction,
    );
  }

  /// Updates all [ActionExternalRule]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionExternalRule>> update(
    _is.DatabaseSession session,
    List<ActionExternalRule> rows, {
    _is.ColumnSelections<ActionExternalRuleTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ActionExternalRule>(
      rows,
      columns: columns?.call(ActionExternalRule.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ActionExternalRule]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ActionExternalRule> updateRow(
    _is.DatabaseSession session,
    ActionExternalRule row, {
    _is.ColumnSelections<ActionExternalRuleTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ActionExternalRule>(
      row,
      columns: columns?.call(ActionExternalRule.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ActionExternalRule] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ActionExternalRule?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<ActionExternalRuleUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ActionExternalRule>(
      id,
      columnValues: columnValues(ActionExternalRule.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ActionExternalRule]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionExternalRule>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ActionExternalRuleUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<ActionExternalRuleTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionExternalRuleTable>? orderBy,
    _is.OrderByListBuilder<ActionExternalRuleTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ActionExternalRule>(
      columnValues: columnValues(ActionExternalRule.t.updateTable),
      where: where(ActionExternalRule.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ActionExternalRule.t),
      orderByList: orderByList?.call(ActionExternalRule.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ActionExternalRule]s in the list and returns the deleted rows.
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
  Future<List<ActionExternalRule>> delete(
    _is.DatabaseSession session,
    List<ActionExternalRule> rows, {
    _is.OrderByBuilder<ActionExternalRuleTable>? orderBy,
    _is.OrderByListBuilder<ActionExternalRuleTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ActionExternalRule>(
      rows,
      orderBy: orderBy?.call(ActionExternalRule.t),
      orderByList: orderByList?.call(ActionExternalRule.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ActionExternalRule].
  Future<ActionExternalRule> deleteRow(
    _is.DatabaseSession session,
    ActionExternalRule row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ActionExternalRule>(
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
  Future<List<ActionExternalRule>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ActionExternalRuleTable> where,
    _is.OrderByBuilder<ActionExternalRuleTable>? orderBy,
    _is.OrderByListBuilder<ActionExternalRuleTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ActionExternalRule>(
      where: where(ActionExternalRule.t),
      orderBy: orderBy?.call(ActionExternalRule.t),
      orderByList: orderByList?.call(ActionExternalRule.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionExternalRuleTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ActionExternalRule>(
      where: where?.call(ActionExternalRule.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ActionExternalRule] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ActionExternalRuleTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ActionExternalRule>(
      where: where(ActionExternalRule.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
