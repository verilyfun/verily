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
import 'package:verily_server/src/generated/protocol.dart' as _itf691yl;

import '../action_verification/action_requirement.dart' as _id3goxt7;

/// The action's public place and its geofence. Participant check-ins are
/// stored on evidence rows, never here.
abstract class ActionLocationRule
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  ActionLocationRule._({
    this.id,
    required this.requirementId,
    this.requirement,
    required this.location,
    required this.radiusMeters,
    required this.maxAccuracyMeters,
  });

  factory ActionLocationRule({
    _is.UuidValue? id,
    required _is.UuidValue requirementId,
    _id3goxt7.ActionRequirement? requirement,
    required _is.GeographyPoint location,
    required double radiusMeters,
    required double maxAccuracyMeters,
  }) = _ActionLocationRuleImpl;

  factory ActionLocationRule.fromJson(Map<String, dynamic> jsonSerialization) {
    return ActionLocationRule(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      requirementId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['requirementId'],
      ),
      requirement: jsonSerialization['requirement'] == null
          ? null
          : _itf691yl.Protocol().deserialize<_id3goxt7.ActionRequirement>(
              jsonSerialization['requirement'],
            ),
      location: _is.GeographyPointJsonExtension.fromJson(
        jsonSerialization['location'],
      ),
      radiusMeters: (jsonSerialization['radiusMeters'] as num).toDouble(),
      maxAccuracyMeters: (jsonSerialization['maxAccuracyMeters'] as num)
          .toDouble(),
    );
  }

  static final t = ActionLocationRuleTable();

  static const db = ActionLocationRuleRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue requirementId;

  _id3goxt7.ActionRequirement? requirement;

  _is.GeographyPoint location;

  double radiusMeters;

  double maxAccuracyMeters;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [ActionLocationRule]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ActionLocationRule copyWith({
    _is.UuidValue? id,
    _is.UuidValue? requirementId,
    _id3goxt7.ActionRequirement? requirement,
    _is.GeographyPoint? location,
    double? radiusMeters,
    double? maxAccuracyMeters,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActionLocationRule',
      if (id != null) 'id': id?.toJson(),
      'requirementId': requirementId.toJson(),
      if (requirement != null) 'requirement': requirement?.toJson(),
      'location': location.toJson(),
      'radiusMeters': radiusMeters,
      'maxAccuracyMeters': maxAccuracyMeters,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ActionLocationRuleInclude include({
    _id3goxt7.ActionRequirementInclude? requirement,
  }) {
    return ActionLocationRuleInclude._(requirement: requirement);
  }

  static ActionLocationRuleIncludeList includeList({
    _is.WhereExpressionBuilder<ActionLocationRuleTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionLocationRuleTable>? orderBy,
    _is.OrderByListBuilder<ActionLocationRuleTable>? orderByList,
    ActionLocationRuleInclude? include,
  }) {
    return ActionLocationRuleIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ActionLocationRule.t),
      orderByList: orderByList?.call(ActionLocationRule.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ActionLocationRuleImpl extends ActionLocationRule {
  _ActionLocationRuleImpl({
    _is.UuidValue? id,
    required _is.UuidValue requirementId,
    _id3goxt7.ActionRequirement? requirement,
    required _is.GeographyPoint location,
    required double radiusMeters,
    required double maxAccuracyMeters,
  }) : super._(
         id: id,
         requirementId: requirementId,
         requirement: requirement,
         location: location,
         radiusMeters: radiusMeters,
         maxAccuracyMeters: maxAccuracyMeters,
       );

  /// Returns a shallow copy of this [ActionLocationRule]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ActionLocationRule copyWith({
    Object? id = _Undefined,
    _is.UuidValue? requirementId,
    Object? requirement = _Undefined,
    _is.GeographyPoint? location,
    double? radiusMeters,
    double? maxAccuracyMeters,
  }) {
    return ActionLocationRule(
      id: id is _is.UuidValue? ? id : this.id,
      requirementId: requirementId ?? this.requirementId,
      requirement: requirement is _id3goxt7.ActionRequirement?
          ? requirement
          : this.requirement?.copyWith(),
      location: location ?? this.location,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      maxAccuracyMeters: maxAccuracyMeters ?? this.maxAccuracyMeters,
    );
  }
}

class ActionLocationRuleUpdateTable
    extends _is.UpdateTable<ActionLocationRuleTable> {
  ActionLocationRuleUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> requirementId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.requirementId,
    value,
  );

  _is.ColumnValue<_is.GeographyPoint, _is.GeographyPoint> location(
    _is.GeographyPoint value,
  ) => _is.ColumnValue(
    table.location,
    value,
  );

  _is.ColumnValue<double, double> radiusMeters(double value) => _is.ColumnValue(
    table.radiusMeters,
    value,
  );

  _is.ColumnValue<double, double> maxAccuracyMeters(double value) =>
      _is.ColumnValue(
        table.maxAccuracyMeters,
        value,
      );
}

class ActionLocationRuleTable extends _is.Table<_is.UuidValue?> {
  ActionLocationRuleTable({super.tableRelation})
    : super(tableName: 'verily_action_location_rule') {
    updateTable = ActionLocationRuleUpdateTable(this);
    requirementId = _is.ColumnUuid(
      'requirementId',
      this,
    );
    location = _is.ColumnGeographyPoint(
      'location',
      this,
    );
    radiusMeters = _is.ColumnDouble(
      'radiusMeters',
      this,
    );
    maxAccuracyMeters = _is.ColumnDouble(
      'maxAccuracyMeters',
      this,
    );
  }

  late final ActionLocationRuleUpdateTable updateTable;

  late final _is.ColumnUuid requirementId;

  _id3goxt7.ActionRequirementTable? _requirement;

  late final _is.ColumnGeographyPoint location;

  late final _is.ColumnDouble radiusMeters;

  late final _is.ColumnDouble maxAccuracyMeters;

  _id3goxt7.ActionRequirementTable get requirement {
    if (_requirement != null) return _requirement!;
    _requirement = _is.createRelationTable(
      relationFieldName: 'requirement',
      field: ActionLocationRule.t.requirementId,
      foreignField: _id3goxt7.ActionRequirement.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _id3goxt7.ActionRequirementTable(tableRelation: foreignTableRelation),
    );
    return _requirement!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    requirementId,
    location,
    radiusMeters,
    maxAccuracyMeters,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'requirement') {
      return requirement;
    }
    return null;
  }
}

class ActionLocationRuleInclude extends _is.IncludeObject {
  ActionLocationRuleInclude._({
    _id3goxt7.ActionRequirementInclude? requirement,
  }) {
    _requirement = requirement;
  }

  _id3goxt7.ActionRequirementInclude? _requirement;

  @override
  Map<String, _is.Include?> get includes => {'requirement': _requirement};

  @override
  _is.Table<_is.UuidValue?> get table => ActionLocationRule.t;
}

class ActionLocationRuleIncludeList extends _is.IncludeList {
  ActionLocationRuleIncludeList._({
    _is.WhereExpressionBuilder<ActionLocationRuleTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ActionLocationRule.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => ActionLocationRule.t;
}

class ActionLocationRuleRepository {
  const ActionLocationRuleRepository._();

  final attachRow = const ActionLocationRuleAttachRowRepository._();

  /// Returns a list of [ActionLocationRule]s matching the given query parameters.
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
  Future<List<ActionLocationRule>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionLocationRuleTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionLocationRuleTable>? orderBy,
    _is.OrderByListBuilder<ActionLocationRuleTable>? orderByList,
    _is.Transaction? transaction,
    ActionLocationRuleInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ActionLocationRule>(
      where: where?.call(ActionLocationRule.t),
      orderBy: orderBy?.call(ActionLocationRule.t),
      orderByList: orderByList?.call(ActionLocationRule.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ActionLocationRule] matching the given query parameters.
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
  Future<ActionLocationRule?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionLocationRuleTable>? where,
    int? offset,
    _is.OrderByBuilder<ActionLocationRuleTable>? orderBy,
    _is.OrderByListBuilder<ActionLocationRuleTable>? orderByList,
    _is.Transaction? transaction,
    ActionLocationRuleInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ActionLocationRule>(
      where: where?.call(ActionLocationRule.t),
      orderBy: orderBy?.call(ActionLocationRule.t),
      orderByList: orderByList?.call(ActionLocationRule.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ActionLocationRule] by its [id] or null if no such row exists.
  Future<ActionLocationRule?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    ActionLocationRuleInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ActionLocationRule>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ActionLocationRule]s in the list and returns the inserted rows.
  ///
  /// The returned [ActionLocationRule]s will have their `id` fields set.
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
  Future<List<ActionLocationRule>> insert(
    _is.DatabaseSession session,
    List<ActionLocationRule> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ActionLocationRule>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ActionLocationRule] and returns the inserted row.
  ///
  /// The returned [ActionLocationRule] will have its `id` field set.
  Future<ActionLocationRule> insertRow(
    _is.DatabaseSession session,
    ActionLocationRule row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ActionLocationRule>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ActionLocationRule]s in the list and returns the resulting rows.
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
  /// The returned [ActionLocationRule]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionLocationRule>> upsert(
    _is.DatabaseSession session,
    List<ActionLocationRule> rows, {
    required _is.ColumnSelections<ActionLocationRuleTable> conflictColumns,
    _is.ColumnSelections<ActionLocationRuleTable>? updateColumns,
    _is.WhereExpressionBuilder<ActionLocationRuleTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ActionLocationRule>(
      rows,
      conflictColumns: conflictColumns(ActionLocationRule.t),
      updateColumns: updateColumns?.call(ActionLocationRule.t),
      updateWhere: updateWhere?.call(ActionLocationRule.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ActionLocationRule] and returns the resulting row.
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
  /// The returned [ActionLocationRule] will have its `id` field set.
  Future<ActionLocationRule?> upsertRow(
    _is.DatabaseSession session,
    ActionLocationRule row, {
    required _is.ColumnSelections<ActionLocationRuleTable> conflictColumns,
    _is.ColumnSelections<ActionLocationRuleTable>? updateColumns,
    _is.WhereExpressionBuilder<ActionLocationRuleTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ActionLocationRule>(
      row,
      conflictColumns: conflictColumns(ActionLocationRule.t),
      updateColumns: updateColumns?.call(ActionLocationRule.t),
      updateWhere: updateWhere?.call(ActionLocationRule.t),
      transaction: transaction,
    );
  }

  /// Updates all [ActionLocationRule]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionLocationRule>> update(
    _is.DatabaseSession session,
    List<ActionLocationRule> rows, {
    _is.ColumnSelections<ActionLocationRuleTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ActionLocationRule>(
      rows,
      columns: columns?.call(ActionLocationRule.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ActionLocationRule]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ActionLocationRule> updateRow(
    _is.DatabaseSession session,
    ActionLocationRule row, {
    _is.ColumnSelections<ActionLocationRuleTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ActionLocationRule>(
      row,
      columns: columns?.call(ActionLocationRule.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ActionLocationRule] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ActionLocationRule?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<ActionLocationRuleUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ActionLocationRule>(
      id,
      columnValues: columnValues(ActionLocationRule.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ActionLocationRule]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionLocationRule>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ActionLocationRuleUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<ActionLocationRuleTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionLocationRuleTable>? orderBy,
    _is.OrderByListBuilder<ActionLocationRuleTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ActionLocationRule>(
      columnValues: columnValues(ActionLocationRule.t.updateTable),
      where: where(ActionLocationRule.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ActionLocationRule.t),
      orderByList: orderByList?.call(ActionLocationRule.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ActionLocationRule]s in the list and returns the deleted rows.
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
  Future<List<ActionLocationRule>> delete(
    _is.DatabaseSession session,
    List<ActionLocationRule> rows, {
    _is.OrderByBuilder<ActionLocationRuleTable>? orderBy,
    _is.OrderByListBuilder<ActionLocationRuleTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ActionLocationRule>(
      rows,
      orderBy: orderBy?.call(ActionLocationRule.t),
      orderByList: orderByList?.call(ActionLocationRule.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ActionLocationRule].
  Future<ActionLocationRule> deleteRow(
    _is.DatabaseSession session,
    ActionLocationRule row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ActionLocationRule>(
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
  Future<List<ActionLocationRule>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ActionLocationRuleTable> where,
    _is.OrderByBuilder<ActionLocationRuleTable>? orderBy,
    _is.OrderByListBuilder<ActionLocationRuleTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ActionLocationRule>(
      where: where(ActionLocationRule.t),
      orderBy: orderBy?.call(ActionLocationRule.t),
      orderByList: orderByList?.call(ActionLocationRule.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionLocationRuleTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ActionLocationRule>(
      where: where?.call(ActionLocationRule.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ActionLocationRule] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ActionLocationRuleTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ActionLocationRule>(
      where: where(ActionLocationRule.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class ActionLocationRuleAttachRowRepository {
  const ActionLocationRuleAttachRowRepository._();

  /// Creates a relation between the given [ActionLocationRule] and [ActionRequirement]
  /// by setting the [ActionLocationRule]'s foreign key `requirementId` to refer to the [ActionRequirement].
  Future<void> requirement(
    _is.DatabaseSession session,
    ActionLocationRule actionLocationRule,
    _id3goxt7.ActionRequirement requirement, {
    _is.Transaction? transaction,
  }) async {
    if (actionLocationRule.id == null) {
      throw ArgumentError.notNull('actionLocationRule.id');
    }
    if (requirement.id == null) {
      throw ArgumentError.notNull('requirement.id');
    }

    var $actionLocationRule = actionLocationRule.copyWith(
      requirementId: requirement.id,
    );
    await session.db.updateRow<ActionLocationRule>(
      $actionLocationRule,
      columns: [ActionLocationRule.t.requirementId],
      transaction: transaction,
    );
  }
}
