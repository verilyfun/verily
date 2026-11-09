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
import 'dart:async' as _ida;

import 'package:serverpod/serverpod.dart' as _is;
import 'package:verily_server/src/generated/protocol.dart' as _itf691yl;

import '../action_verification/action_definition.dart' as _ioz52zfd;
import '../action_verification/action_requirement_kind.dart' as _iws572ni;

/// Ordered requirement identity shared by proof and rule tables.
abstract class ActionRequirement
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  ActionRequirement._({
    this.id,
    required this.actionDefinitionId,
    this.actionDefinition,
    required this.requirementKey,
    required this.kind,
    required this.title,
    required this.instructions,
    required this.position,
    bool? isRequired,
    DateTime? createdAt,
  }) : isRequired = isRequired ?? true,
       createdAt = createdAt ?? DateTime.now();

  factory ActionRequirement({
    _is.UuidValue? id,
    required _is.UuidValue actionDefinitionId,
    _ioz52zfd.ActionDefinition? actionDefinition,
    required String requirementKey,
    required _iws572ni.ActionRequirementKind kind,
    required String title,
    required String instructions,
    required int position,
    bool? isRequired,
    DateTime? createdAt,
  }) = _ActionRequirementImpl;

  factory ActionRequirement.fromJson(Map<String, dynamic> jsonSerialization) {
    return ActionRequirement(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      actionDefinitionId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['actionDefinitionId'],
      ),
      actionDefinition: jsonSerialization['actionDefinition'] == null
          ? null
          : _itf691yl.Protocol().deserialize<_ioz52zfd.ActionDefinition>(
              jsonSerialization['actionDefinition'],
            ),
      requirementKey: jsonSerialization['requirementKey'] as String,
      kind: _iws572ni.ActionRequirementKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      title: jsonSerialization['title'] as String,
      instructions: jsonSerialization['instructions'] as String,
      position: jsonSerialization['position'] as int,
      isRequired: jsonSerialization['isRequired'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['isRequired']),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = ActionRequirementTable();

  static const db = ActionRequirementRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue actionDefinitionId;

  _ioz52zfd.ActionDefinition? actionDefinition;

  String requirementKey;

  _iws572ni.ActionRequirementKind kind;

  String title;

  String instructions;

  int position;

  bool isRequired;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [ActionRequirement]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ActionRequirement copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? actionDefinitionId,
    _ioz52zfd.ActionDefinition? actionDefinition =
        const _UndefinedActionRequirement$actionDefinition(),
    String? requirementKey,
    _iws572ni.ActionRequirementKind? kind,
    String? title,
    String? instructions,
    int? position,
    bool? isRequired,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActionRequirement',
      if (id != null) 'id': id?.toJson(),
      'actionDefinitionId': actionDefinitionId.toJson(),
      if (actionDefinition != null)
        'actionDefinition': actionDefinition?.toJson(),
      'requirementKey': requirementKey,
      'kind': kind.toJson(),
      'title': title,
      'instructions': instructions,
      'position': position,
      'isRequired': isRequired,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ActionRequirementInclude include({
    _ioz52zfd.ActionDefinitionInclude? actionDefinition,
  }) {
    return ActionRequirementInclude._(actionDefinition: actionDefinition);
  }

  static ActionRequirementIncludeList includeList({
    _is.WhereExpressionBuilder<ActionRequirementTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionRequirementTable>? orderBy,
    _is.OrderByListBuilder<ActionRequirementTable>? orderByList,
    ActionRequirementInclude? include,
  }) {
    return ActionRequirementIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ActionRequirement.t),
      orderByList: orderByList?.call(ActionRequirement.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _UndefinedActionRequirement$actionDefinition extends _is.UndefinedSentinel
    implements _ioz52zfd.ActionDefinition {
  const _UndefinedActionRequirement$actionDefinition();
}

class _ActionRequirementImpl extends ActionRequirement {
  _ActionRequirementImpl({
    _is.UuidValue? id,
    required _is.UuidValue actionDefinitionId,
    _ioz52zfd.ActionDefinition? actionDefinition,
    required String requirementKey,
    required _iws572ni.ActionRequirementKind kind,
    required String title,
    required String instructions,
    required int position,
    bool? isRequired,
    DateTime? createdAt,
  }) : super._(
         id: id,
         actionDefinitionId: actionDefinitionId,
         actionDefinition: actionDefinition,
         requirementKey: requirementKey,
         kind: kind,
         title: title,
         instructions: instructions,
         position: position,
         isRequired: isRequired,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ActionRequirement]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ActionRequirement copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? actionDefinitionId,
    _ioz52zfd.ActionDefinition? actionDefinition =
        const _UndefinedActionRequirement$actionDefinition(),
    String? requirementKey,
    _iws572ni.ActionRequirementKind? kind,
    String? title,
    String? instructions,
    int? position,
    bool? isRequired,
    DateTime? createdAt,
  }) {
    return ActionRequirement(
      id: id is _is.UndefinedSentinel ? this.id : id,
      actionDefinitionId: actionDefinitionId ?? this.actionDefinitionId,
      actionDefinition: actionDefinition is _is.UndefinedSentinel
          ? this.actionDefinition?.copyWith()
          : actionDefinition,
      requirementKey: requirementKey ?? this.requirementKey,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      instructions: instructions ?? this.instructions,
      position: position ?? this.position,
      isRequired: isRequired ?? this.isRequired,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ActionRequirementUpdateTable
    extends _is.UpdateTable<ActionRequirementTable> {
  ActionRequirementUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> actionDefinitionId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.actionDefinitionId,
    value,
  );

  _is.ColumnValue<String, String> requirementKey(String value) =>
      _is.ColumnValue(
        table.requirementKey,
        value,
      );

  _is.ColumnValue<
    _iws572ni.ActionRequirementKind,
    _iws572ni.ActionRequirementKind
  >
  kind(_iws572ni.ActionRequirementKind value) => _is.ColumnValue(
    table.kind,
    value,
  );

  _is.ColumnValue<String, String> title(String value) => _is.ColumnValue(
    table.title,
    value,
  );

  _is.ColumnValue<String, String> instructions(String value) => _is.ColumnValue(
    table.instructions,
    value,
  );

  _is.ColumnValue<int, int> position(int value) => _is.ColumnValue(
    table.position,
    value,
  );

  _is.ColumnValue<bool, bool> isRequired(bool value) => _is.ColumnValue(
    table.isRequired,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class ActionRequirementTable extends _is.Table<_is.UuidValue?> {
  ActionRequirementTable({super.tableRelation})
    : super(tableName: 'verily_action_requirement') {
    updateTable = ActionRequirementUpdateTable(this);
    actionDefinitionId = _is.ColumnUuid(
      'actionDefinitionId',
      this,
    );
    requirementKey = _is.ColumnString(
      'requirementKey',
      this,
    );
    kind = _is.ColumnEnum(
      'kind',
      this,
      _is.EnumSerialization.byName,
    );
    title = _is.ColumnString(
      'title',
      this,
    );
    instructions = _is.ColumnString(
      'instructions',
      this,
    );
    position = _is.ColumnInt(
      'position',
      this,
    );
    isRequired = _is.ColumnBool(
      'isRequired',
      this,
      hasDefault: true,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final ActionRequirementUpdateTable updateTable;

  late final _is.ColumnUuid actionDefinitionId;

  _ioz52zfd.ActionDefinitionTable? _actionDefinition;

  late final _is.ColumnString requirementKey;

  late final _is.ColumnEnum<_iws572ni.ActionRequirementKind> kind;

  late final _is.ColumnString title;

  late final _is.ColumnString instructions;

  late final _is.ColumnInt position;

  late final _is.ColumnBool isRequired;

  late final _is.ColumnDateTime createdAt;

  _ioz52zfd.ActionDefinitionTable get actionDefinition {
    if (_actionDefinition != null) return _actionDefinition!;
    _actionDefinition = _is.createRelationTable(
      relationFieldName: 'actionDefinition',
      field: ActionRequirement.t.actionDefinitionId,
      foreignField: _ioz52zfd.ActionDefinition.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _ioz52zfd.ActionDefinitionTable(tableRelation: foreignTableRelation),
    );
    return _actionDefinition!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    actionDefinitionId,
    requirementKey,
    kind,
    title,
    instructions,
    position,
    isRequired,
    createdAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'actionDefinition') {
      return actionDefinition;
    }
    return null;
  }
}

class ActionRequirementInclude extends _is.IncludeObject {
  ActionRequirementInclude._({
    _ioz52zfd.ActionDefinitionInclude? actionDefinition,
  }) {
    _actionDefinition = actionDefinition;
  }

  _ioz52zfd.ActionDefinitionInclude? _actionDefinition;

  @override
  Map<String, _is.Include?> get includes => {
    'actionDefinition': _actionDefinition,
  };

  @override
  _is.Table<_is.UuidValue?> get table => ActionRequirement.t;
}

class ActionRequirementIncludeList extends _is.IncludeList {
  ActionRequirementIncludeList._({
    _is.WhereExpressionBuilder<ActionRequirementTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ActionRequirement.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => ActionRequirement.t;
}

class ActionRequirementRepository {
  const ActionRequirementRepository._();

  final attachRow = const ActionRequirementAttachRowRepository._();

  /// Returns a list of [ActionRequirement]s matching the given query parameters.
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
  Future<List<ActionRequirement>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionRequirementTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionRequirementTable>? orderBy,
    _is.OrderByListBuilder<ActionRequirementTable>? orderByList,
    _is.Transaction? transaction,
    ActionRequirementInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ActionRequirement>(
      where: where?.call(ActionRequirement.t),
      orderBy: orderBy?.call(ActionRequirement.t),
      orderByList: orderByList?.call(ActionRequirement.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [ActionRequirement]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `ActionRequirement.t`.
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
  _ida.Stream<List<ActionRequirement>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionRequirementTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionRequirementTable>? orderBy,
    _is.OrderByListBuilder<ActionRequirementTable>? orderByList,
    ActionRequirementInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<ActionRequirement>(
      where: where?.call(ActionRequirement.t),
      orderBy: orderBy?.call(ActionRequirement.t),
      orderByList: orderByList?.call(ActionRequirement.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [ActionRequirement] matching the given query parameters.
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
  Future<ActionRequirement?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionRequirementTable>? where,
    int? offset,
    _is.OrderByBuilder<ActionRequirementTable>? orderBy,
    _is.OrderByListBuilder<ActionRequirementTable>? orderByList,
    _is.Transaction? transaction,
    ActionRequirementInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ActionRequirement>(
      where: where?.call(ActionRequirement.t),
      orderBy: orderBy?.call(ActionRequirement.t),
      orderByList: orderByList?.call(ActionRequirement.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ActionRequirement] by its [id] or null if no such row exists.
  Future<ActionRequirement?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    ActionRequirementInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ActionRequirement>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ActionRequirement]s in the list and returns the inserted rows.
  ///
  /// The returned [ActionRequirement]s will have their `id` fields set.
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
  Future<List<ActionRequirement>> insert(
    _is.DatabaseSession session,
    List<ActionRequirement> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ActionRequirement>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ActionRequirement] and returns the inserted row.
  ///
  /// The returned [ActionRequirement] will have its `id` field set.
  Future<ActionRequirement> insertRow(
    _is.DatabaseSession session,
    ActionRequirement row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ActionRequirement>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ActionRequirement]s in the list and returns the resulting rows.
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
  /// The returned [ActionRequirement]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionRequirement>> upsert(
    _is.DatabaseSession session,
    List<ActionRequirement> rows, {
    required _is.ColumnSelections<ActionRequirementTable> conflictColumns,
    _is.ColumnSelections<ActionRequirementTable>? updateColumns,
    _is.WhereExpressionBuilder<ActionRequirementTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ActionRequirement>(
      rows,
      conflictColumns: conflictColumns(ActionRequirement.t),
      updateColumns: updateColumns?.call(ActionRequirement.t),
      updateWhere: updateWhere?.call(ActionRequirement.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ActionRequirement] and returns the resulting row.
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
  /// The returned [ActionRequirement] will have its `id` field set.
  Future<ActionRequirement?> upsertRow(
    _is.DatabaseSession session,
    ActionRequirement row, {
    required _is.ColumnSelections<ActionRequirementTable> conflictColumns,
    _is.ColumnSelections<ActionRequirementTable>? updateColumns,
    _is.WhereExpressionBuilder<ActionRequirementTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ActionRequirement>(
      row,
      conflictColumns: conflictColumns(ActionRequirement.t),
      updateColumns: updateColumns?.call(ActionRequirement.t),
      updateWhere: updateWhere?.call(ActionRequirement.t),
      transaction: transaction,
    );
  }

  /// Updates all [ActionRequirement]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionRequirement>> update(
    _is.DatabaseSession session,
    List<ActionRequirement> rows, {
    _is.ColumnSelections<ActionRequirementTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ActionRequirement>(
      rows,
      columns: columns?.call(ActionRequirement.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ActionRequirement]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ActionRequirement> updateRow(
    _is.DatabaseSession session,
    ActionRequirement row, {
    _is.ColumnSelections<ActionRequirementTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ActionRequirement>(
      row,
      columns: columns?.call(ActionRequirement.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ActionRequirement] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ActionRequirement?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<ActionRequirementUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ActionRequirement>(
      id,
      columnValues: columnValues(ActionRequirement.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ActionRequirement]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionRequirement>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ActionRequirementUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<ActionRequirementTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionRequirementTable>? orderBy,
    _is.OrderByListBuilder<ActionRequirementTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ActionRequirement>(
      columnValues: columnValues(ActionRequirement.t.updateTable),
      where: where(ActionRequirement.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ActionRequirement.t),
      orderByList: orderByList?.call(ActionRequirement.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ActionRequirement]s in the list and returns the deleted rows.
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
  Future<List<ActionRequirement>> delete(
    _is.DatabaseSession session,
    List<ActionRequirement> rows, {
    _is.OrderByBuilder<ActionRequirementTable>? orderBy,
    _is.OrderByListBuilder<ActionRequirementTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ActionRequirement>(
      rows,
      orderBy: orderBy?.call(ActionRequirement.t),
      orderByList: orderByList?.call(ActionRequirement.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ActionRequirement].
  Future<ActionRequirement> deleteRow(
    _is.DatabaseSession session,
    ActionRequirement row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ActionRequirement>(
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
  Future<List<ActionRequirement>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ActionRequirementTable> where,
    _is.OrderByBuilder<ActionRequirementTable>? orderBy,
    _is.OrderByListBuilder<ActionRequirementTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ActionRequirement>(
      where: where(ActionRequirement.t),
      orderBy: orderBy?.call(ActionRequirement.t),
      orderByList: orderByList?.call(ActionRequirement.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionRequirementTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ActionRequirement>(
      where: where?.call(ActionRequirement.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ActionRequirement] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ActionRequirementTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ActionRequirement>(
      where: where(ActionRequirement.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class ActionRequirementAttachRowRepository {
  const ActionRequirementAttachRowRepository._();

  /// Creates a relation between the given [ActionRequirement] and [ActionDefinition]
  /// by setting the [ActionRequirement]'s foreign key `actionDefinitionId` to refer to the [ActionDefinition].
  Future<void> actionDefinition(
    _is.DatabaseSession session,
    ActionRequirement actionRequirement,
    _ioz52zfd.ActionDefinition actionDefinition, {
    _is.Transaction? transaction,
  }) async {
    if (actionRequirement.id == null) {
      throw ArgumentError.notNull('actionRequirement.id');
    }
    if (actionDefinition.id == null) {
      throw ArgumentError.notNull('actionDefinition.id');
    }

    var $actionRequirement = actionRequirement.copyWith(
      actionDefinitionId: actionDefinition.id,
    );
    await session.db.updateRow<ActionRequirement>(
      $actionRequirement,
      columns: [ActionRequirement.t.actionDefinitionId],
      transaction: transaction,
    );
  }
}
