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
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:verily_server/src/generated/protocol.dart' as _itf691yl;

import '../action_verification/action_definition_status.dart' as _irpnjpe3;
import '../action_verification/action_recurrence.dart' as _ivhzgwse;
import '../action_verification/action_visibility.dart' as _izz63myo;

/// Versioned, creator-owned proof contract. Published revisions are immutable;
/// historical attempts stay tied to the rules they accepted.
abstract class ActionDefinition
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  ActionDefinition._({
    this.id,
    required this.creatorAuthUserId,
    this.creatorAuthUser,
    required this.actionKey,
    int? revision,
    required this.title,
    required this.description,
    required this.status,
    required this.recurrence,
    required this.timeZone,
    this.maxVerifiedCompletions,
    int? verifiedCompletions,
    this.opensAt,
    this.closesAt,
    this.publishedAt,
    this.pausedAt,
    _izz63myo.ActionVisibility? visibility,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : revision = revision ?? 1,
       verifiedCompletions = verifiedCompletions ?? 0,
       visibility = visibility ?? _izz63myo.ActionVisibility.public,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory ActionDefinition({
    _is.UuidValue? id,
    required _is.UuidValue creatorAuthUserId,
    _iacs.AuthUser? creatorAuthUser,
    required String actionKey,
    int? revision,
    required String title,
    required String description,
    required _irpnjpe3.ActionDefinitionStatus status,
    required _ivhzgwse.ActionRecurrence recurrence,
    required String timeZone,
    int? maxVerifiedCompletions,
    int? verifiedCompletions,
    DateTime? opensAt,
    DateTime? closesAt,
    DateTime? publishedAt,
    DateTime? pausedAt,
    _izz63myo.ActionVisibility? visibility,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ActionDefinitionImpl;

  factory ActionDefinition.fromJson(Map<String, dynamic> jsonSerialization) {
    return ActionDefinition(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      creatorAuthUserId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['creatorAuthUserId'],
      ),
      creatorAuthUser: jsonSerialization['creatorAuthUser'] == null
          ? null
          : _itf691yl.Protocol().deserialize<_iacs.AuthUser>(
              jsonSerialization['creatorAuthUser'],
            ),
      actionKey: jsonSerialization['actionKey'] as String,
      revision: jsonSerialization['revision'] as int?,
      title: jsonSerialization['title'] as String,
      description: jsonSerialization['description'] as String,
      status: _irpnjpe3.ActionDefinitionStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      recurrence: _ivhzgwse.ActionRecurrence.fromJson(
        (jsonSerialization['recurrence'] as String),
      ),
      timeZone: jsonSerialization['timeZone'] as String,
      maxVerifiedCompletions:
          jsonSerialization['maxVerifiedCompletions'] as int?,
      verifiedCompletions: jsonSerialization['verifiedCompletions'] as int?,
      opensAt: jsonSerialization['opensAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['opensAt']),
      closesAt: jsonSerialization['closesAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['closesAt']),
      publishedAt: jsonSerialization['publishedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['publishedAt'],
            ),
      pausedAt: jsonSerialization['pausedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['pausedAt']),
      visibility: jsonSerialization['visibility'] == null
          ? null
          : _izz63myo.ActionVisibility.fromJson(
              (jsonSerialization['visibility'] as String),
            ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  static final t = ActionDefinitionTable();

  static const db = ActionDefinitionRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue creatorAuthUserId;

  _iacs.AuthUser? creatorAuthUser;

  String actionKey;

  int revision;

  String title;

  String description;

  _irpnjpe3.ActionDefinitionStatus status;

  _ivhzgwse.ActionRecurrence recurrence;

  String timeZone;

  int? maxVerifiedCompletions;

  int verifiedCompletions;

  DateTime? opensAt;

  DateTime? closesAt;

  DateTime? publishedAt;

  DateTime? pausedAt;

  _izz63myo.ActionVisibility visibility;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [ActionDefinition]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ActionDefinition copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? creatorAuthUserId,
    _iacs.AuthUser? creatorAuthUser =
        const _UndefinedActionDefinition$creatorAuthUser(),
    String? actionKey,
    int? revision,
    String? title,
    String? description,
    _irpnjpe3.ActionDefinitionStatus? status,
    _ivhzgwse.ActionRecurrence? recurrence,
    String? timeZone,
    int? maxVerifiedCompletions,
    int? verifiedCompletions,
    DateTime? opensAt = const _is.$UndefinedDateTime(),
    DateTime? closesAt = const _is.$UndefinedDateTime(),
    DateTime? publishedAt = const _is.$UndefinedDateTime(),
    DateTime? pausedAt = const _is.$UndefinedDateTime(),
    _izz63myo.ActionVisibility? visibility,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActionDefinition',
      if (id != null) 'id': id?.toJson(),
      'creatorAuthUserId': creatorAuthUserId.toJson(),
      if (creatorAuthUser != null) 'creatorAuthUser': creatorAuthUser?.toJson(),
      'actionKey': actionKey,
      'revision': revision,
      'title': title,
      'description': description,
      'status': status.toJson(),
      'recurrence': recurrence.toJson(),
      'timeZone': timeZone,
      if (maxVerifiedCompletions != null)
        'maxVerifiedCompletions': maxVerifiedCompletions,
      'verifiedCompletions': verifiedCompletions,
      if (opensAt != null) 'opensAt': opensAt?.toJson(),
      if (closesAt != null) 'closesAt': closesAt?.toJson(),
      if (publishedAt != null) 'publishedAt': publishedAt?.toJson(),
      if (pausedAt != null) 'pausedAt': pausedAt?.toJson(),
      'visibility': visibility.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ActionDefinitionInclude include({
    _iacs.AuthUserInclude? creatorAuthUser,
  }) {
    return ActionDefinitionInclude._(creatorAuthUser: creatorAuthUser);
  }

  static ActionDefinitionIncludeList includeList({
    _is.WhereExpressionBuilder<ActionDefinitionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionDefinitionTable>? orderBy,
    _is.OrderByListBuilder<ActionDefinitionTable>? orderByList,
    ActionDefinitionInclude? include,
  }) {
    return ActionDefinitionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ActionDefinition.t),
      orderByList: orderByList?.call(ActionDefinition.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedActionDefinition$creatorAuthUser extends _is.UndefinedSentinel
    implements _iacs.AuthUser {
  const _UndefinedActionDefinition$creatorAuthUser();
}

class _ActionDefinitionImpl extends ActionDefinition {
  _ActionDefinitionImpl({
    _is.UuidValue? id,
    required _is.UuidValue creatorAuthUserId,
    _iacs.AuthUser? creatorAuthUser,
    required String actionKey,
    int? revision,
    required String title,
    required String description,
    required _irpnjpe3.ActionDefinitionStatus status,
    required _ivhzgwse.ActionRecurrence recurrence,
    required String timeZone,
    int? maxVerifiedCompletions,
    int? verifiedCompletions,
    DateTime? opensAt,
    DateTime? closesAt,
    DateTime? publishedAt,
    DateTime? pausedAt,
    _izz63myo.ActionVisibility? visibility,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         creatorAuthUserId: creatorAuthUserId,
         creatorAuthUser: creatorAuthUser,
         actionKey: actionKey,
         revision: revision,
         title: title,
         description: description,
         status: status,
         recurrence: recurrence,
         timeZone: timeZone,
         maxVerifiedCompletions: maxVerifiedCompletions,
         verifiedCompletions: verifiedCompletions,
         opensAt: opensAt,
         closesAt: closesAt,
         publishedAt: publishedAt,
         pausedAt: pausedAt,
         visibility: visibility,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ActionDefinition]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ActionDefinition copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? creatorAuthUserId,
    _iacs.AuthUser? creatorAuthUser =
        const _UndefinedActionDefinition$creatorAuthUser(),
    String? actionKey,
    int? revision,
    String? title,
    String? description,
    _irpnjpe3.ActionDefinitionStatus? status,
    _ivhzgwse.ActionRecurrence? recurrence,
    String? timeZone,
    Object? maxVerifiedCompletions = _Undefined,
    int? verifiedCompletions,
    DateTime? opensAt = const _is.$UndefinedDateTime(),
    DateTime? closesAt = const _is.$UndefinedDateTime(),
    DateTime? publishedAt = const _is.$UndefinedDateTime(),
    DateTime? pausedAt = const _is.$UndefinedDateTime(),
    _izz63myo.ActionVisibility? visibility,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ActionDefinition(
      id: id is _is.UndefinedSentinel ? this.id : id,
      creatorAuthUserId: creatorAuthUserId ?? this.creatorAuthUserId,
      creatorAuthUser: creatorAuthUser is _is.UndefinedSentinel
          ? this.creatorAuthUser?.copyWith()
          : creatorAuthUser,
      actionKey: actionKey ?? this.actionKey,
      revision: revision ?? this.revision,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      recurrence: recurrence ?? this.recurrence,
      timeZone: timeZone ?? this.timeZone,
      maxVerifiedCompletions: maxVerifiedCompletions is int?
          ? maxVerifiedCompletions
          : this.maxVerifiedCompletions,
      verifiedCompletions: verifiedCompletions ?? this.verifiedCompletions,
      opensAt: opensAt is _is.UndefinedSentinel ? this.opensAt : opensAt,
      closesAt: closesAt is _is.UndefinedSentinel ? this.closesAt : closesAt,
      publishedAt: publishedAt is _is.UndefinedSentinel
          ? this.publishedAt
          : publishedAt,
      pausedAt: pausedAt is _is.UndefinedSentinel ? this.pausedAt : pausedAt,
      visibility: visibility ?? this.visibility,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ActionDefinitionUpdateTable
    extends _is.UpdateTable<ActionDefinitionTable> {
  ActionDefinitionUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> creatorAuthUserId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.creatorAuthUserId,
    value,
  );

  _is.ColumnValue<String, String> actionKey(String value) => _is.ColumnValue(
    table.actionKey,
    value,
  );

  _is.ColumnValue<int, int> revision(int value) => _is.ColumnValue(
    table.revision,
    value,
  );

  _is.ColumnValue<String, String> title(String value) => _is.ColumnValue(
    table.title,
    value,
  );

  _is.ColumnValue<String, String> description(String value) => _is.ColumnValue(
    table.description,
    value,
  );

  _is.ColumnValue<
    _irpnjpe3.ActionDefinitionStatus,
    _irpnjpe3.ActionDefinitionStatus
  >
  status(_irpnjpe3.ActionDefinitionStatus value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<_ivhzgwse.ActionRecurrence, _ivhzgwse.ActionRecurrence>
  recurrence(_ivhzgwse.ActionRecurrence value) => _is.ColumnValue(
    table.recurrence,
    value,
  );

  _is.ColumnValue<String, String> timeZone(String value) => _is.ColumnValue(
    table.timeZone,
    value,
  );

  _is.ColumnValue<int, int> maxVerifiedCompletions(int? value) =>
      _is.ColumnValue(
        table.maxVerifiedCompletions,
        value,
      );

  _is.ColumnValue<int, int> verifiedCompletions(int value) => _is.ColumnValue(
    table.verifiedCompletions,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> opensAt(DateTime? value) =>
      _is.ColumnValue(
        table.opensAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> closesAt(DateTime? value) =>
      _is.ColumnValue(
        table.closesAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> publishedAt(DateTime? value) =>
      _is.ColumnValue(
        table.publishedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> pausedAt(DateTime? value) =>
      _is.ColumnValue(
        table.pausedAt,
        value,
      );

  _is.ColumnValue<_izz63myo.ActionVisibility, _izz63myo.ActionVisibility>
  visibility(_izz63myo.ActionVisibility value) => _is.ColumnValue(
    table.visibility,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _is.ColumnValue(
        table.updatedAt,
        value,
      );
}

class ActionDefinitionTable extends _is.Table<_is.UuidValue?> {
  ActionDefinitionTable({super.tableRelation})
    : super(tableName: 'verily_action_definition') {
    updateTable = ActionDefinitionUpdateTable(this);
    creatorAuthUserId = _is.ColumnUuid(
      'creatorAuthUserId',
      this,
    );
    actionKey = _is.ColumnString(
      'actionKey',
      this,
    );
    revision = _is.ColumnInt(
      'revision',
      this,
      hasDefault: true,
    );
    title = _is.ColumnString(
      'title',
      this,
    );
    description = _is.ColumnString(
      'description',
      this,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
    );
    recurrence = _is.ColumnEnum(
      'recurrence',
      this,
      _is.EnumSerialization.byName,
    );
    timeZone = _is.ColumnString(
      'timeZone',
      this,
    );
    maxVerifiedCompletions = _is.ColumnInt(
      'maxVerifiedCompletions',
      this,
    );
    verifiedCompletions = _is.ColumnInt(
      'verifiedCompletions',
      this,
      hasDefault: true,
    );
    opensAt = _is.ColumnDateTime(
      'opensAt',
      this,
    );
    closesAt = _is.ColumnDateTime(
      'closesAt',
      this,
    );
    publishedAt = _is.ColumnDateTime(
      'publishedAt',
      this,
    );
    pausedAt = _is.ColumnDateTime(
      'pausedAt',
      this,
    );
    visibility = _is.ColumnEnum(
      'visibility',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    updatedAt = _is.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final ActionDefinitionUpdateTable updateTable;

  late final _is.ColumnUuid creatorAuthUserId;

  _iacs.AuthUserTable? _creatorAuthUser;

  late final _is.ColumnString actionKey;

  late final _is.ColumnInt revision;

  late final _is.ColumnString title;

  late final _is.ColumnString description;

  late final _is.ColumnEnum<_irpnjpe3.ActionDefinitionStatus> status;

  late final _is.ColumnEnum<_ivhzgwse.ActionRecurrence> recurrence;

  late final _is.ColumnString timeZone;

  late final _is.ColumnInt maxVerifiedCompletions;

  late final _is.ColumnInt verifiedCompletions;

  late final _is.ColumnDateTime opensAt;

  late final _is.ColumnDateTime closesAt;

  late final _is.ColumnDateTime publishedAt;

  late final _is.ColumnDateTime pausedAt;

  late final _is.ColumnEnum<_izz63myo.ActionVisibility> visibility;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  _iacs.AuthUserTable get creatorAuthUser {
    if (_creatorAuthUser != null) return _creatorAuthUser!;
    _creatorAuthUser = _is.createRelationTable(
      relationFieldName: 'creatorAuthUser',
      field: ActionDefinition.t.creatorAuthUserId,
      foreignField: _iacs.AuthUser.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iacs.AuthUserTable(tableRelation: foreignTableRelation),
    );
    return _creatorAuthUser!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    creatorAuthUserId,
    actionKey,
    revision,
    title,
    description,
    status,
    recurrence,
    timeZone,
    maxVerifiedCompletions,
    verifiedCompletions,
    opensAt,
    closesAt,
    publishedAt,
    pausedAt,
    visibility,
    createdAt,
    updatedAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'creatorAuthUser') {
      return creatorAuthUser;
    }
    return null;
  }
}

class ActionDefinitionInclude extends _is.IncludeObject {
  ActionDefinitionInclude._({_iacs.AuthUserInclude? creatorAuthUser}) {
    _creatorAuthUser = creatorAuthUser;
  }

  _iacs.AuthUserInclude? _creatorAuthUser;

  @override
  Map<String, _is.Include?> get includes => {
    'creatorAuthUser': _creatorAuthUser,
  };

  @override
  _is.Table<_is.UuidValue?> get table => ActionDefinition.t;
}

class ActionDefinitionIncludeList extends _is.IncludeList {
  ActionDefinitionIncludeList._({
    _is.WhereExpressionBuilder<ActionDefinitionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ActionDefinition.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => ActionDefinition.t;
}

class ActionDefinitionRepository {
  const ActionDefinitionRepository._();

  final attachRow = const ActionDefinitionAttachRowRepository._();

  /// Returns a list of [ActionDefinition]s matching the given query parameters.
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
  Future<List<ActionDefinition>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionDefinitionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionDefinitionTable>? orderBy,
    _is.OrderByListBuilder<ActionDefinitionTable>? orderByList,
    _is.Transaction? transaction,
    ActionDefinitionInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ActionDefinition>(
      where: where?.call(ActionDefinition.t),
      orderBy: orderBy?.call(ActionDefinition.t),
      orderByList: orderByList?.call(ActionDefinition.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [ActionDefinition]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `ActionDefinition.t`.
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
  _ida.Stream<List<ActionDefinition>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionDefinitionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionDefinitionTable>? orderBy,
    _is.OrderByListBuilder<ActionDefinitionTable>? orderByList,
    ActionDefinitionInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<ActionDefinition>(
      where: where?.call(ActionDefinition.t),
      orderBy: orderBy?.call(ActionDefinition.t),
      orderByList: orderByList?.call(ActionDefinition.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [ActionDefinition] matching the given query parameters.
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
  Future<ActionDefinition?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionDefinitionTable>? where,
    int? offset,
    _is.OrderByBuilder<ActionDefinitionTable>? orderBy,
    _is.OrderByListBuilder<ActionDefinitionTable>? orderByList,
    _is.Transaction? transaction,
    ActionDefinitionInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ActionDefinition>(
      where: where?.call(ActionDefinition.t),
      orderBy: orderBy?.call(ActionDefinition.t),
      orderByList: orderByList?.call(ActionDefinition.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ActionDefinition] by its [id] or null if no such row exists.
  Future<ActionDefinition?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    ActionDefinitionInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ActionDefinition>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ActionDefinition]s in the list and returns the inserted rows.
  ///
  /// The returned [ActionDefinition]s will have their `id` fields set.
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
  Future<List<ActionDefinition>> insert(
    _is.DatabaseSession session,
    List<ActionDefinition> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ActionDefinition>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ActionDefinition] and returns the inserted row.
  ///
  /// The returned [ActionDefinition] will have its `id` field set.
  Future<ActionDefinition> insertRow(
    _is.DatabaseSession session,
    ActionDefinition row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ActionDefinition>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ActionDefinition]s in the list and returns the resulting rows.
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
  /// The returned [ActionDefinition]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionDefinition>> upsert(
    _is.DatabaseSession session,
    List<ActionDefinition> rows, {
    required _is.ColumnSelections<ActionDefinitionTable> conflictColumns,
    _is.ColumnSelections<ActionDefinitionTable>? updateColumns,
    _is.WhereExpressionBuilder<ActionDefinitionTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ActionDefinition>(
      rows,
      conflictColumns: conflictColumns(ActionDefinition.t),
      updateColumns: updateColumns?.call(ActionDefinition.t),
      updateWhere: updateWhere?.call(ActionDefinition.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ActionDefinition] and returns the resulting row.
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
  /// The returned [ActionDefinition] will have its `id` field set.
  Future<ActionDefinition?> upsertRow(
    _is.DatabaseSession session,
    ActionDefinition row, {
    required _is.ColumnSelections<ActionDefinitionTable> conflictColumns,
    _is.ColumnSelections<ActionDefinitionTable>? updateColumns,
    _is.WhereExpressionBuilder<ActionDefinitionTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ActionDefinition>(
      row,
      conflictColumns: conflictColumns(ActionDefinition.t),
      updateColumns: updateColumns?.call(ActionDefinition.t),
      updateWhere: updateWhere?.call(ActionDefinition.t),
      transaction: transaction,
    );
  }

  /// Updates all [ActionDefinition]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionDefinition>> update(
    _is.DatabaseSession session,
    List<ActionDefinition> rows, {
    _is.ColumnSelections<ActionDefinitionTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ActionDefinition>(
      rows,
      columns: columns?.call(ActionDefinition.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ActionDefinition]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ActionDefinition> updateRow(
    _is.DatabaseSession session,
    ActionDefinition row, {
    _is.ColumnSelections<ActionDefinitionTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ActionDefinition>(
      row,
      columns: columns?.call(ActionDefinition.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ActionDefinition] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ActionDefinition?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<ActionDefinitionUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ActionDefinition>(
      id,
      columnValues: columnValues(ActionDefinition.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ActionDefinition]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActionDefinition>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ActionDefinitionUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<ActionDefinitionTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActionDefinitionTable>? orderBy,
    _is.OrderByListBuilder<ActionDefinitionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ActionDefinition>(
      columnValues: columnValues(ActionDefinition.t.updateTable),
      where: where(ActionDefinition.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ActionDefinition.t),
      orderByList: orderByList?.call(ActionDefinition.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ActionDefinition]s in the list and returns the deleted rows.
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
  Future<List<ActionDefinition>> delete(
    _is.DatabaseSession session,
    List<ActionDefinition> rows, {
    _is.OrderByBuilder<ActionDefinitionTable>? orderBy,
    _is.OrderByListBuilder<ActionDefinitionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ActionDefinition>(
      rows,
      orderBy: orderBy?.call(ActionDefinition.t),
      orderByList: orderByList?.call(ActionDefinition.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ActionDefinition].
  Future<ActionDefinition> deleteRow(
    _is.DatabaseSession session,
    ActionDefinition row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ActionDefinition>(
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
  Future<List<ActionDefinition>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ActionDefinitionTable> where,
    _is.OrderByBuilder<ActionDefinitionTable>? orderBy,
    _is.OrderByListBuilder<ActionDefinitionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ActionDefinition>(
      where: where(ActionDefinition.t),
      orderBy: orderBy?.call(ActionDefinition.t),
      orderByList: orderByList?.call(ActionDefinition.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActionDefinitionTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ActionDefinition>(
      where: where?.call(ActionDefinition.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ActionDefinition] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ActionDefinitionTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ActionDefinition>(
      where: where(ActionDefinition.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class ActionDefinitionAttachRowRepository {
  const ActionDefinitionAttachRowRepository._();

  /// Creates a relation between the given [ActionDefinition] and [AuthUser]
  /// by setting the [ActionDefinition]'s foreign key `creatorAuthUserId` to refer to the [AuthUser].
  Future<void> creatorAuthUser(
    _is.DatabaseSession session,
    ActionDefinition actionDefinition,
    _iacs.AuthUser creatorAuthUser, {
    _is.Transaction? transaction,
  }) async {
    if (actionDefinition.id == null) {
      throw ArgumentError.notNull('actionDefinition.id');
    }
    if (creatorAuthUser.id == null) {
      throw ArgumentError.notNull('creatorAuthUser.id');
    }

    var $actionDefinition = actionDefinition.copyWith(
      creatorAuthUserId: creatorAuthUser.id,
    );
    await session.db.updateRow<ActionDefinition>(
      $actionDefinition,
      columns: [ActionDefinition.t.creatorAuthUserId],
      transaction: transaction,
    );
  }
}
