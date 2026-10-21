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

import '../action_verification/action_movement_kind.dart' as _idij3jhk;
import '../action_verification/action_requirement_kind.dart' as _iws572ni;
import '../action_verification/action_verification_policy.dart' as _i0pk7h0c;
import '../action_verification/local_check/local_check_task.dart' as _it4e837y;

/// Server-validated verification policy for one video, photo, or audio
/// requirement. Creator text and model output are never instructions.
///
/// [kind] repeats the requirement's kind so database checks can enforce the
/// per-kind shape (durations only for recordings, a spoken challenge never on
/// a photo, movements only on video); a trigger keeps the two equal.
abstract class ActionMediaRule
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  ActionMediaRule._({
    this.id,
    required this.requirementId,
    required this.kind,
    required this.verificationPrompt,
    this.minDurationSeconds,
    this.maxDurationSeconds,
    required this.minConfidence,
    _i0pk7h0c.ActionVerificationPolicy? verificationPolicy,
    bool? spokenChallengeRequired,
    this.movementKind,
    this.targetRepetitions,
    this.localCheckTask,
    this.localCheckLabel,
    this.localCheckMinScore,
    this.localCheckMinFrames,
  }) : verificationPolicy =
           verificationPolicy ?? _i0pk7h0c.ActionVerificationPolicy.singleModel,
       spokenChallengeRequired = spokenChallengeRequired ?? false;

  factory ActionMediaRule({
    _is.UuidValue? id,
    required _is.UuidValue requirementId,
    required _iws572ni.ActionRequirementKind kind,
    required String verificationPrompt,
    int? minDurationSeconds,
    int? maxDurationSeconds,
    required double minConfidence,
    _i0pk7h0c.ActionVerificationPolicy? verificationPolicy,
    bool? spokenChallengeRequired,
    _idij3jhk.ActionMovementKind? movementKind,
    int? targetRepetitions,
    _it4e837y.LocalCheckTask? localCheckTask,
    String? localCheckLabel,
    double? localCheckMinScore,
    int? localCheckMinFrames,
  }) = _ActionMediaRuleImpl;

  factory ActionMediaRule.fromJson(Map<String, dynamic> jsonSerialization) {
    return ActionMediaRule(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      requirementId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['requirementId'],
      ),
      kind: _iws572ni.ActionRequirementKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      verificationPrompt: jsonSerialization['verificationPrompt'] as String,
      minDurationSeconds: jsonSerialization['minDurationSeconds'] as int?,
      maxDurationSeconds: jsonSerialization['maxDurationSeconds'] as int?,
      minConfidence: (jsonSerialization['minConfidence'] as num).toDouble(),
      verificationPolicy: jsonSerialization['verificationPolicy'] == null
          ? null
          : _i0pk7h0c.ActionVerificationPolicy.fromJson(
              (jsonSerialization['verificationPolicy'] as String),
            ),
      spokenChallengeRequired:
          jsonSerialization['spokenChallengeRequired'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(
              jsonSerialization['spokenChallengeRequired'],
            ),
      movementKind: jsonSerialization['movementKind'] == null
          ? null
          : _idij3jhk.ActionMovementKind.fromJson(
              (jsonSerialization['movementKind'] as String),
            ),
      targetRepetitions: jsonSerialization['targetRepetitions'] as int?,
      localCheckTask: jsonSerialization['localCheckTask'] == null
          ? null
          : _it4e837y.LocalCheckTask.fromJson(
              (jsonSerialization['localCheckTask'] as String),
            ),
      localCheckLabel: jsonSerialization['localCheckLabel'] as String?,
      localCheckMinScore: (jsonSerialization['localCheckMinScore'] as num?)
          ?.toDouble(),
      localCheckMinFrames: jsonSerialization['localCheckMinFrames'] as int?,
    );
  }

  static final t = ActionMediaRuleTable();

  static const db = ActionMediaRuleRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue requirementId;

  _iws572ni.ActionRequirementKind kind;

  String verificationPrompt;

  /// Recording bounds; null for photos.
  int? minDurationSeconds;

  int? maxDurationSeconds;

  double minConfidence;

  _i0pk7h0c.ActionVerificationPolicy verificationPolicy;

  /// Video and audio only: the participant says a server-issued word while
  /// recording, so a recording made before the attempt cannot pass.
  bool spokenChallengeRequired;

  /// Set for tracked movement challenges; the prompt is then server-generated.
  _idij3jhk.ActionMovementKind? movementKind;

  /// Complete repetitions or consecutive touches required by [movementKind].
  int? targetRepetitions;

  /// Optional on-device check replayed on the server (`mp-replay`).
  _it4e837y.LocalCheckTask? localCheckTask;

  String? localCheckLabel;

  double? localCheckMinScore;

  int? localCheckMinFrames;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [ActionMediaRule]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ActionMediaRule copyWith({
    _is.UuidValue? id,
    _is.UuidValue? requirementId,
    _iws572ni.ActionRequirementKind? kind,
    String? verificationPrompt,
    int? minDurationSeconds,
    int? maxDurationSeconds,
    double? minConfidence,
    _i0pk7h0c.ActionVerificationPolicy? verificationPolicy,
    bool? spokenChallengeRequired,
    _idij3jhk.ActionMovementKind? movementKind,
    int? targetRepetitions,
    _it4e837y.LocalCheckTask? localCheckTask,
    String? localCheckLabel,
    double? localCheckMinScore,
    int? localCheckMinFrames,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActionMediaRule',
      if (id != null) 'id': id?.toJson(),
      'requirementId': requirementId.toJson(),
      'kind': kind.toJson(),
      'verificationPrompt': verificationPrompt,
      if (minDurationSeconds != null) 'minDurationSeconds': minDurationSeconds,
      if (maxDurationSeconds != null) 'maxDurationSeconds': maxDurationSeconds,
      'minConfidence': minConfidence,
      'verificationPolicy': verificationPolicy.toJson(),
      'spokenChallengeRequired': spokenChallengeRequired,
      if (movementKind != null) 'movementKind': movementKind?.toJson(),
      if (targetRepetitions != null) 'targetRepetitions': targetRepetitions,
      if (localCheckTask != null) 'localCheckTask': localCheckTask?.toJson(),
      if (localCheckLabel != null) 'localCheckLabel': localCheckLabel,
      if (localCheckMinScore != null) 'localCheckMinScore': localCheckMinScore,
      if (localCheckMinFrames != null)
        'localCheckMinFrames': localCheckMinFrames,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ActionMediaRuleInclude include() {
    return ActionMediaRuleInclude._();
  }

  static ActionMediaRuleIncludeList includeList({
    _is.WhereExpressionBuilder<ActionMediaRuleTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionMediaRuleTable>? orderBy,
    _is.OrderByListBuilder<ActionMediaRuleTable>? orderByList,
    ActionMediaRuleInclude? include,
  }) {
    return ActionMediaRuleIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ActionMediaRule.t),
      orderByList: orderByList?.call(ActionMediaRule.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ActionMediaRuleImpl extends ActionMediaRule {
  _ActionMediaRuleImpl({
    _is.UuidValue? id,
    required _is.UuidValue requirementId,
    required _iws572ni.ActionRequirementKind kind,
    required String verificationPrompt,
    int? minDurationSeconds,
    int? maxDurationSeconds,
    required double minConfidence,
    _i0pk7h0c.ActionVerificationPolicy? verificationPolicy,
    bool? spokenChallengeRequired,
    _idij3jhk.ActionMovementKind? movementKind,
    int? targetRepetitions,
    _it4e837y.LocalCheckTask? localCheckTask,
    String? localCheckLabel,
    double? localCheckMinScore,
    int? localCheckMinFrames,
  }) : super._(
         id: id,
         requirementId: requirementId,
         kind: kind,
         verificationPrompt: verificationPrompt,
         minDurationSeconds: minDurationSeconds,
         maxDurationSeconds: maxDurationSeconds,
         minConfidence: minConfidence,
         verificationPolicy: verificationPolicy,
         spokenChallengeRequired: spokenChallengeRequired,
         movementKind: movementKind,
         targetRepetitions: targetRepetitions,
         localCheckTask: localCheckTask,
         localCheckLabel: localCheckLabel,
         localCheckMinScore: localCheckMinScore,
         localCheckMinFrames: localCheckMinFrames,
       );

  /// Returns a shallow copy of this [ActionMediaRule]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ActionMediaRule copyWith({
    Object? id = _Undefined,
    _is.UuidValue? requirementId,
    _iws572ni.ActionRequirementKind? kind,
    String? verificationPrompt,
    Object? minDurationSeconds = _Undefined,
    Object? maxDurationSeconds = _Undefined,
    double? minConfidence,
    _i0pk7h0c.ActionVerificationPolicy? verificationPolicy,
    bool? spokenChallengeRequired,
    Object? movementKind = _Undefined,
    Object? targetRepetitions = _Undefined,
    Object? localCheckTask = _Undefined,
    Object? localCheckLabel = _Undefined,
    Object? localCheckMinScore = _Undefined,
    Object? localCheckMinFrames = _Undefined,
  }) {
    return ActionMediaRule(
      id: id is _is.UuidValue? ? id : this.id,
      requirementId: requirementId ?? this.requirementId,
      kind: kind ?? this.kind,
      verificationPrompt: verificationPrompt ?? this.verificationPrompt,
      minDurationSeconds: minDurationSeconds is int?
          ? minDurationSeconds
          : this.minDurationSeconds,
      maxDurationSeconds: maxDurationSeconds is int?
          ? maxDurationSeconds
          : this.maxDurationSeconds,
      minConfidence: minConfidence ?? this.minConfidence,
      verificationPolicy: verificationPolicy ?? this.verificationPolicy,
      spokenChallengeRequired:
          spokenChallengeRequired ?? this.spokenChallengeRequired,
      movementKind: movementKind is _idij3jhk.ActionMovementKind?
          ? movementKind
          : this.movementKind,
      targetRepetitions: targetRepetitions is int?
          ? targetRepetitions
          : this.targetRepetitions,
      localCheckTask: localCheckTask is _it4e837y.LocalCheckTask?
          ? localCheckTask
          : this.localCheckTask,
      localCheckLabel: localCheckLabel is String?
          ? localCheckLabel
          : this.localCheckLabel,
      localCheckMinScore: localCheckMinScore is double?
          ? localCheckMinScore
          : this.localCheckMinScore,
      localCheckMinFrames: localCheckMinFrames is int?
          ? localCheckMinFrames
          : this.localCheckMinFrames,
    );
  }
}

class ActionMediaRuleUpdateTable extends _is.UpdateTable<ActionMediaRuleTable> {
  ActionMediaRuleUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> requirementId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.requirementId,
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

  _is.ColumnValue<String, String> verificationPrompt(String value) =>
      _is.ColumnValue(
        table.verificationPrompt,
        value,
      );

  _is.ColumnValue<int, int> minDurationSeconds(int? value) => _is.ColumnValue(
    table.minDurationSeconds,
    value,
  );

  _is.ColumnValue<int, int> maxDurationSeconds(int? value) => _is.ColumnValue(
    table.maxDurationSeconds,
    value,
  );

  _is.ColumnValue<double, double> minConfidence(double value) =>
      _is.ColumnValue(
        table.minConfidence,
        value,
      );

  _is.ColumnValue<
    _i0pk7h0c.ActionVerificationPolicy,
    _i0pk7h0c.ActionVerificationPolicy
  >
  verificationPolicy(_i0pk7h0c.ActionVerificationPolicy value) =>
      _is.ColumnValue(
        table.verificationPolicy,
        value,
      );

  _is.ColumnValue<bool, bool> spokenChallengeRequired(bool value) =>
      _is.ColumnValue(
        table.spokenChallengeRequired,
        value,
      );

  _is.ColumnValue<_idij3jhk.ActionMovementKind, _idij3jhk.ActionMovementKind>
  movementKind(_idij3jhk.ActionMovementKind? value) => _is.ColumnValue(
    table.movementKind,
    value,
  );

  _is.ColumnValue<int, int> targetRepetitions(int? value) => _is.ColumnValue(
    table.targetRepetitions,
    value,
  );

  _is.ColumnValue<_it4e837y.LocalCheckTask, _it4e837y.LocalCheckTask>
  localCheckTask(_it4e837y.LocalCheckTask? value) => _is.ColumnValue(
    table.localCheckTask,
    value,
  );

  _is.ColumnValue<String, String> localCheckLabel(String? value) =>
      _is.ColumnValue(
        table.localCheckLabel,
        value,
      );

  _is.ColumnValue<double, double> localCheckMinScore(double? value) =>
      _is.ColumnValue(
        table.localCheckMinScore,
        value,
      );

  _is.ColumnValue<int, int> localCheckMinFrames(int? value) => _is.ColumnValue(
    table.localCheckMinFrames,
    value,
  );
}

class ActionMediaRuleTable extends _is.Table<_is.UuidValue?> {
  ActionMediaRuleTable({super.tableRelation})
    : super(tableName: 'verily_action_media_rule') {
    updateTable = ActionMediaRuleUpdateTable(this);
    requirementId = _is.ColumnUuid(
      'requirementId',
      this,
    );
    kind = _is.ColumnEnum(
      'kind',
      this,
      _is.EnumSerialization.byName,
    );
    verificationPrompt = _is.ColumnString(
      'verificationPrompt',
      this,
    );
    minDurationSeconds = _is.ColumnInt(
      'minDurationSeconds',
      this,
    );
    maxDurationSeconds = _is.ColumnInt(
      'maxDurationSeconds',
      this,
    );
    minConfidence = _is.ColumnDouble(
      'minConfidence',
      this,
    );
    verificationPolicy = _is.ColumnEnum(
      'verificationPolicy',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    spokenChallengeRequired = _is.ColumnBool(
      'spokenChallengeRequired',
      this,
      hasDefault: true,
    );
    movementKind = _is.ColumnEnum(
      'movementKind',
      this,
      _is.EnumSerialization.byName,
    );
    targetRepetitions = _is.ColumnInt(
      'targetRepetitions',
      this,
    );
    localCheckTask = _is.ColumnEnum(
      'localCheckTask',
      this,
      _is.EnumSerialization.byName,
    );
    localCheckLabel = _is.ColumnString(
      'localCheckLabel',
      this,
    );
    localCheckMinScore = _is.ColumnDouble(
      'localCheckMinScore',
      this,
    );
    localCheckMinFrames = _is.ColumnInt(
      'localCheckMinFrames',
      this,
    );
  }

  late final ActionMediaRuleUpdateTable updateTable;

  late final _is.ColumnUuid requirementId;

  late final _is.ColumnEnum<_iws572ni.ActionRequirementKind> kind;

  late final _is.ColumnString verificationPrompt;

  /// Recording bounds; null for photos.
  late final _is.ColumnInt minDurationSeconds;

  late final _is.ColumnInt maxDurationSeconds;

  late final _is.ColumnDouble minConfidence;

  late final _is.ColumnEnum<_i0pk7h0c.ActionVerificationPolicy>
  verificationPolicy;

  /// Video and audio only: the participant says a server-issued word while
  /// recording, so a recording made before the attempt cannot pass.
  late final _is.ColumnBool spokenChallengeRequired;

  /// Set for tracked movement challenges; the prompt is then server-generated.
  late final _is.ColumnEnum<_idij3jhk.ActionMovementKind> movementKind;

  /// Complete repetitions or consecutive touches required by [movementKind].
  late final _is.ColumnInt targetRepetitions;

  /// Optional on-device check replayed on the server (`mp-replay`).
  late final _is.ColumnEnum<_it4e837y.LocalCheckTask> localCheckTask;

  late final _is.ColumnString localCheckLabel;

  late final _is.ColumnDouble localCheckMinScore;

  late final _is.ColumnInt localCheckMinFrames;

  @override
  List<_is.Column> get columns => [
    id,
    requirementId,
    kind,
    verificationPrompt,
    minDurationSeconds,
    maxDurationSeconds,
    minConfidence,
    verificationPolicy,
    spokenChallengeRequired,
    movementKind,
    targetRepetitions,
    localCheckTask,
    localCheckLabel,
    localCheckMinScore,
    localCheckMinFrames,
  ];
}

class ActionMediaRuleInclude extends _is.IncludeObject {
  ActionMediaRuleInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<_is.UuidValue?> get table => ActionMediaRule.t;
}

class ActionMediaRuleIncludeList extends _is.IncludeList {
  ActionMediaRuleIncludeList._({
    _is.WhereExpressionBuilder<ActionMediaRuleTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ActionMediaRule.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => ActionMediaRule.t;
}

class ActionMediaRuleRepository {
  const ActionMediaRuleRepository._();

  /// Returns a list of [ActionMediaRule]s matching the given query parameters.
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
  Future<List<ActionMediaRule>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionMediaRuleTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionMediaRuleTable>? orderBy,
    _is.OrderByListBuilder<ActionMediaRuleTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ActionMediaRule>(
      where: where?.call(ActionMediaRule.t),
      orderBy: orderBy?.call(ActionMediaRule.t),
      orderByList: orderByList?.call(ActionMediaRule.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ActionMediaRule] matching the given query parameters.
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
  Future<ActionMediaRule?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionMediaRuleTable>? where,
    int? offset,
    _is.OrderByBuilder<ActionMediaRuleTable>? orderBy,
    _is.OrderByListBuilder<ActionMediaRuleTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ActionMediaRule>(
      where: where?.call(ActionMediaRule.t),
      orderBy: orderBy?.call(ActionMediaRule.t),
      orderByList: orderByList?.call(ActionMediaRule.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ActionMediaRule] by its [id] or null if no such row exists.
  Future<ActionMediaRule?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ActionMediaRule>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ActionMediaRule]s in the list and returns the inserted rows.
  ///
  /// The returned [ActionMediaRule]s will have their `id` fields set.
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
  Future<List<ActionMediaRule>> insert(
    _is.DatabaseSession session,
    List<ActionMediaRule> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ActionMediaRule>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ActionMediaRule] and returns the inserted row.
  ///
  /// The returned [ActionMediaRule] will have its `id` field set.
  Future<ActionMediaRule> insertRow(
    _is.DatabaseSession session,
    ActionMediaRule row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ActionMediaRule>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ActionMediaRule]s in the list and returns the resulting rows.
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
  /// The returned [ActionMediaRule]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionMediaRule>> upsert(
    _is.DatabaseSession session,
    List<ActionMediaRule> rows, {
    required _is.ColumnSelections<ActionMediaRuleTable> conflictColumns,
    _is.ColumnSelections<ActionMediaRuleTable>? updateColumns,
    _is.WhereExpressionBuilder<ActionMediaRuleTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ActionMediaRule>(
      rows,
      conflictColumns: conflictColumns(ActionMediaRule.t),
      updateColumns: updateColumns?.call(ActionMediaRule.t),
      updateWhere: updateWhere?.call(ActionMediaRule.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ActionMediaRule] and returns the resulting row.
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
  /// The returned [ActionMediaRule] will have its `id` field set.
  Future<ActionMediaRule?> upsertRow(
    _is.DatabaseSession session,
    ActionMediaRule row, {
    required _is.ColumnSelections<ActionMediaRuleTable> conflictColumns,
    _is.ColumnSelections<ActionMediaRuleTable>? updateColumns,
    _is.WhereExpressionBuilder<ActionMediaRuleTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ActionMediaRule>(
      row,
      conflictColumns: conflictColumns(ActionMediaRule.t),
      updateColumns: updateColumns?.call(ActionMediaRule.t),
      updateWhere: updateWhere?.call(ActionMediaRule.t),
      transaction: transaction,
    );
  }

  /// Updates all [ActionMediaRule]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionMediaRule>> update(
    _is.DatabaseSession session,
    List<ActionMediaRule> rows, {
    _is.ColumnSelections<ActionMediaRuleTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ActionMediaRule>(
      rows,
      columns: columns?.call(ActionMediaRule.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ActionMediaRule]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ActionMediaRule> updateRow(
    _is.DatabaseSession session,
    ActionMediaRule row, {
    _is.ColumnSelections<ActionMediaRuleTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ActionMediaRule>(
      row,
      columns: columns?.call(ActionMediaRule.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ActionMediaRule] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ActionMediaRule?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<ActionMediaRuleUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ActionMediaRule>(
      id,
      columnValues: columnValues(ActionMediaRule.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ActionMediaRule]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionMediaRule>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ActionMediaRuleUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<ActionMediaRuleTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionMediaRuleTable>? orderBy,
    _is.OrderByListBuilder<ActionMediaRuleTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ActionMediaRule>(
      columnValues: columnValues(ActionMediaRule.t.updateTable),
      where: where(ActionMediaRule.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ActionMediaRule.t),
      orderByList: orderByList?.call(ActionMediaRule.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ActionMediaRule]s in the list and returns the deleted rows.
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
  Future<List<ActionMediaRule>> delete(
    _is.DatabaseSession session,
    List<ActionMediaRule> rows, {
    _is.OrderByBuilder<ActionMediaRuleTable>? orderBy,
    _is.OrderByListBuilder<ActionMediaRuleTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ActionMediaRule>(
      rows,
      orderBy: orderBy?.call(ActionMediaRule.t),
      orderByList: orderByList?.call(ActionMediaRule.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ActionMediaRule].
  Future<ActionMediaRule> deleteRow(
    _is.DatabaseSession session,
    ActionMediaRule row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ActionMediaRule>(
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
  Future<List<ActionMediaRule>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ActionMediaRuleTable> where,
    _is.OrderByBuilder<ActionMediaRuleTable>? orderBy,
    _is.OrderByListBuilder<ActionMediaRuleTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ActionMediaRule>(
      where: where(ActionMediaRule.t),
      orderBy: orderBy?.call(ActionMediaRule.t),
      orderByList: orderByList?.call(ActionMediaRule.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionMediaRuleTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ActionMediaRule>(
      where: where?.call(ActionMediaRule.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ActionMediaRule] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ActionMediaRuleTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ActionMediaRule>(
      where: where(ActionMediaRule.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
