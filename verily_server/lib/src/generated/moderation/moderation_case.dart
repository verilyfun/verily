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

/// Human-reviewed safety report about one action and its pause/appeal state.
/// A hold applies to every revision of the reported action's key.
abstract class ModerationCase
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  ModerationCase._({
    this.id,
    required this.creatorAuthUserId,
    this.creatorAuthUser,
    required this.actionDefinitionId,
    this.reporterAuthUserId,
    this.reporterAuthUser,
    required this.idempotencyKey,
    required this.category,
    required this.details,
    required this.status,
    required this.pauseActive,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedByAuthUserId,
    this.reviewedByAuthUser,
    this.appealReason,
    this.appealedAt,
    this.appealResolvedAt,
  });

  factory ModerationCase({
    _is.UuidValue? id,
    required _is.UuidValue creatorAuthUserId,
    _iacs.AuthUser? creatorAuthUser,
    required _is.UuidValue actionDefinitionId,
    _is.UuidValue? reporterAuthUserId,
    _iacs.AuthUser? reporterAuthUser,
    required String idempotencyKey,
    required String category,
    required String details,
    required String status,
    required bool pauseActive,
    required DateTime createdAt,
    DateTime? reviewedAt,
    _is.UuidValue? reviewedByAuthUserId,
    _iacs.AuthUser? reviewedByAuthUser,
    String? appealReason,
    DateTime? appealedAt,
    DateTime? appealResolvedAt,
  }) = _ModerationCaseImpl;

  factory ModerationCase.fromJson(Map<String, dynamic> jsonSerialization) {
    return ModerationCase(
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
      actionDefinitionId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['actionDefinitionId'],
      ),
      reporterAuthUserId: jsonSerialization['reporterAuthUserId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['reporterAuthUserId'],
            ),
      reporterAuthUser: jsonSerialization['reporterAuthUser'] == null
          ? null
          : _itf691yl.Protocol().deserialize<_iacs.AuthUser>(
              jsonSerialization['reporterAuthUser'],
            ),
      idempotencyKey: jsonSerialization['idempotencyKey'] as String,
      category: jsonSerialization['category'] as String,
      details: jsonSerialization['details'] as String,
      status: jsonSerialization['status'] as String,
      pauseActive: _is.BoolJsonExtension.fromJson(
        jsonSerialization['pauseActive'],
      ),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      reviewedAt: jsonSerialization['reviewedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['reviewedAt']),
      reviewedByAuthUserId: jsonSerialization['reviewedByAuthUserId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['reviewedByAuthUserId'],
            ),
      reviewedByAuthUser: jsonSerialization['reviewedByAuthUser'] == null
          ? null
          : _itf691yl.Protocol().deserialize<_iacs.AuthUser>(
              jsonSerialization['reviewedByAuthUser'],
            ),
      appealReason: jsonSerialization['appealReason'] as String?,
      appealedAt: jsonSerialization['appealedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['appealedAt']),
      appealResolvedAt: jsonSerialization['appealResolvedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['appealResolvedAt'],
            ),
    );
  }

  static final t = ModerationCaseTable();

  static const db = ModerationCaseRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue creatorAuthUserId;

  _iacs.AuthUser? creatorAuthUser;

  _is.UuidValue actionDefinitionId;

  _is.UuidValue? reporterAuthUserId;

  _iacs.AuthUser? reporterAuthUser;

  String idempotencyKey;

  String category;

  String details;

  String status;

  bool pauseActive;

  DateTime createdAt;

  DateTime? reviewedAt;

  _is.UuidValue? reviewedByAuthUserId;

  _iacs.AuthUser? reviewedByAuthUser;

  String? appealReason;

  DateTime? appealedAt;

  DateTime? appealResolvedAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [ModerationCase]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ModerationCase copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? creatorAuthUserId,
    _iacs.AuthUser? creatorAuthUser =
        const _UndefinedModerationCase$creatorAuthUser(),
    _is.UuidValue? actionDefinitionId,
    _is.UuidValue? reporterAuthUserId = const _is.$UndefinedUuidValue(),
    _iacs.AuthUser? reporterAuthUser =
        const _UndefinedModerationCase$creatorAuthUser(),
    String? idempotencyKey,
    String? category,
    String? details,
    String? status,
    bool? pauseActive,
    DateTime? createdAt,
    DateTime? reviewedAt = const _is.$UndefinedDateTime(),
    _is.UuidValue? reviewedByAuthUserId = const _is.$UndefinedUuidValue(),
    _iacs.AuthUser? reviewedByAuthUser =
        const _UndefinedModerationCase$creatorAuthUser(),
    String? appealReason,
    DateTime? appealedAt = const _is.$UndefinedDateTime(),
    DateTime? appealResolvedAt = const _is.$UndefinedDateTime(),
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ModerationCase',
      if (id != null) 'id': id?.toJson(),
      'creatorAuthUserId': creatorAuthUserId.toJson(),
      if (creatorAuthUser != null) 'creatorAuthUser': creatorAuthUser?.toJson(),
      'actionDefinitionId': actionDefinitionId.toJson(),
      if (reporterAuthUserId != null)
        'reporterAuthUserId': reporterAuthUserId?.toJson(),
      if (reporterAuthUser != null)
        'reporterAuthUser': reporterAuthUser?.toJson(),
      'idempotencyKey': idempotencyKey,
      'category': category,
      'details': details,
      'status': status,
      'pauseActive': pauseActive,
      'createdAt': createdAt.toJson(),
      if (reviewedAt != null) 'reviewedAt': reviewedAt?.toJson(),
      if (reviewedByAuthUserId != null)
        'reviewedByAuthUserId': reviewedByAuthUserId?.toJson(),
      if (reviewedByAuthUser != null)
        'reviewedByAuthUser': reviewedByAuthUser?.toJson(),
      if (appealReason != null) 'appealReason': appealReason,
      if (appealedAt != null) 'appealedAt': appealedAt?.toJson(),
      if (appealResolvedAt != null)
        'appealResolvedAt': appealResolvedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ModerationCaseInclude include({
    _iacs.AuthUserInclude? creatorAuthUser,
    _iacs.AuthUserInclude? reporterAuthUser,
    _iacs.AuthUserInclude? reviewedByAuthUser,
  }) {
    return ModerationCaseInclude._(
      creatorAuthUser: creatorAuthUser,
      reporterAuthUser: reporterAuthUser,
      reviewedByAuthUser: reviewedByAuthUser,
    );
  }

  static ModerationCaseIncludeList includeList({
    _is.WhereExpressionBuilder<ModerationCaseTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ModerationCaseTable>? orderBy,
    _is.OrderByListBuilder<ModerationCaseTable>? orderByList,
    ModerationCaseInclude? include,
  }) {
    return ModerationCaseIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ModerationCase.t),
      orderByList: orderByList?.call(ModerationCase.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedModerationCase$creatorAuthUser extends _is.UndefinedSentinel
    implements _iacs.AuthUser {
  const _UndefinedModerationCase$creatorAuthUser();
}

class _ModerationCaseImpl extends ModerationCase {
  _ModerationCaseImpl({
    _is.UuidValue? id,
    required _is.UuidValue creatorAuthUserId,
    _iacs.AuthUser? creatorAuthUser,
    required _is.UuidValue actionDefinitionId,
    _is.UuidValue? reporterAuthUserId,
    _iacs.AuthUser? reporterAuthUser,
    required String idempotencyKey,
    required String category,
    required String details,
    required String status,
    required bool pauseActive,
    required DateTime createdAt,
    DateTime? reviewedAt,
    _is.UuidValue? reviewedByAuthUserId,
    _iacs.AuthUser? reviewedByAuthUser,
    String? appealReason,
    DateTime? appealedAt,
    DateTime? appealResolvedAt,
  }) : super._(
         id: id,
         creatorAuthUserId: creatorAuthUserId,
         creatorAuthUser: creatorAuthUser,
         actionDefinitionId: actionDefinitionId,
         reporterAuthUserId: reporterAuthUserId,
         reporterAuthUser: reporterAuthUser,
         idempotencyKey: idempotencyKey,
         category: category,
         details: details,
         status: status,
         pauseActive: pauseActive,
         createdAt: createdAt,
         reviewedAt: reviewedAt,
         reviewedByAuthUserId: reviewedByAuthUserId,
         reviewedByAuthUser: reviewedByAuthUser,
         appealReason: appealReason,
         appealedAt: appealedAt,
         appealResolvedAt: appealResolvedAt,
       );

  /// Returns a shallow copy of this [ModerationCase]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ModerationCase copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? creatorAuthUserId,
    _iacs.AuthUser? creatorAuthUser =
        const _UndefinedModerationCase$creatorAuthUser(),
    _is.UuidValue? actionDefinitionId,
    _is.UuidValue? reporterAuthUserId = const _is.$UndefinedUuidValue(),
    _iacs.AuthUser? reporterAuthUser =
        const _UndefinedModerationCase$creatorAuthUser(),
    String? idempotencyKey,
    String? category,
    String? details,
    String? status,
    bool? pauseActive,
    DateTime? createdAt,
    DateTime? reviewedAt = const _is.$UndefinedDateTime(),
    _is.UuidValue? reviewedByAuthUserId = const _is.$UndefinedUuidValue(),
    _iacs.AuthUser? reviewedByAuthUser =
        const _UndefinedModerationCase$creatorAuthUser(),
    Object? appealReason = _Undefined,
    DateTime? appealedAt = const _is.$UndefinedDateTime(),
    DateTime? appealResolvedAt = const _is.$UndefinedDateTime(),
  }) {
    return ModerationCase(
      id: id is _is.UndefinedSentinel ? this.id : id,
      creatorAuthUserId: creatorAuthUserId ?? this.creatorAuthUserId,
      creatorAuthUser: creatorAuthUser is _is.UndefinedSentinel
          ? this.creatorAuthUser?.copyWith()
          : creatorAuthUser,
      actionDefinitionId: actionDefinitionId ?? this.actionDefinitionId,
      reporterAuthUserId: reporterAuthUserId is _is.UndefinedSentinel
          ? this.reporterAuthUserId
          : reporterAuthUserId,
      reporterAuthUser: reporterAuthUser is _is.UndefinedSentinel
          ? this.reporterAuthUser?.copyWith()
          : reporterAuthUser,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      category: category ?? this.category,
      details: details ?? this.details,
      status: status ?? this.status,
      pauseActive: pauseActive ?? this.pauseActive,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt is _is.UndefinedSentinel
          ? this.reviewedAt
          : reviewedAt,
      reviewedByAuthUserId: reviewedByAuthUserId is _is.UndefinedSentinel
          ? this.reviewedByAuthUserId
          : reviewedByAuthUserId,
      reviewedByAuthUser: reviewedByAuthUser is _is.UndefinedSentinel
          ? this.reviewedByAuthUser?.copyWith()
          : reviewedByAuthUser,
      appealReason: appealReason is String? ? appealReason : this.appealReason,
      appealedAt: appealedAt is _is.UndefinedSentinel
          ? this.appealedAt
          : appealedAt,
      appealResolvedAt: appealResolvedAt is _is.UndefinedSentinel
          ? this.appealResolvedAt
          : appealResolvedAt,
    );
  }
}

class ModerationCaseUpdateTable extends _is.UpdateTable<ModerationCaseTable> {
  ModerationCaseUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> creatorAuthUserId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.creatorAuthUserId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> actionDefinitionId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.actionDefinitionId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> reporterAuthUserId(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.reporterAuthUserId,
    value,
  );

  _is.ColumnValue<String, String> idempotencyKey(String value) =>
      _is.ColumnValue(
        table.idempotencyKey,
        value,
      );

  _is.ColumnValue<String, String> category(String value) => _is.ColumnValue(
    table.category,
    value,
  );

  _is.ColumnValue<String, String> details(String value) => _is.ColumnValue(
    table.details,
    value,
  );

  _is.ColumnValue<String, String> status(String value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<bool, bool> pauseActive(bool value) => _is.ColumnValue(
    table.pauseActive,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> reviewedAt(DateTime? value) =>
      _is.ColumnValue(
        table.reviewedAt,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> reviewedByAuthUserId(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.reviewedByAuthUserId,
    value,
  );

  _is.ColumnValue<String, String> appealReason(String? value) =>
      _is.ColumnValue(
        table.appealReason,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> appealedAt(DateTime? value) =>
      _is.ColumnValue(
        table.appealedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> appealResolvedAt(DateTime? value) =>
      _is.ColumnValue(
        table.appealResolvedAt,
        value,
      );
}

class ModerationCaseTable extends _is.Table<_is.UuidValue?> {
  ModerationCaseTable({super.tableRelation})
    : super(tableName: 'verily_moderation_case') {
    updateTable = ModerationCaseUpdateTable(this);
    creatorAuthUserId = _is.ColumnUuid(
      'creatorAuthUserId',
      this,
    );
    actionDefinitionId = _is.ColumnUuid(
      'actionDefinitionId',
      this,
    );
    reporterAuthUserId = _is.ColumnUuid(
      'reporterAuthUserId',
      this,
    );
    idempotencyKey = _is.ColumnString(
      'idempotencyKey',
      this,
    );
    category = _is.ColumnString(
      'category',
      this,
    );
    details = _is.ColumnString(
      'details',
      this,
    );
    status = _is.ColumnString(
      'status',
      this,
    );
    pauseActive = _is.ColumnBool(
      'pauseActive',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    reviewedAt = _is.ColumnDateTime(
      'reviewedAt',
      this,
    );
    reviewedByAuthUserId = _is.ColumnUuid(
      'reviewedByAuthUserId',
      this,
    );
    appealReason = _is.ColumnString(
      'appealReason',
      this,
    );
    appealedAt = _is.ColumnDateTime(
      'appealedAt',
      this,
    );
    appealResolvedAt = _is.ColumnDateTime(
      'appealResolvedAt',
      this,
    );
  }

  late final ModerationCaseUpdateTable updateTable;

  late final _is.ColumnUuid creatorAuthUserId;

  _iacs.AuthUserTable? _creatorAuthUser;

  late final _is.ColumnUuid actionDefinitionId;

  late final _is.ColumnUuid reporterAuthUserId;

  _iacs.AuthUserTable? _reporterAuthUser;

  late final _is.ColumnString idempotencyKey;

  late final _is.ColumnString category;

  late final _is.ColumnString details;

  late final _is.ColumnString status;

  late final _is.ColumnBool pauseActive;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime reviewedAt;

  late final _is.ColumnUuid reviewedByAuthUserId;

  _iacs.AuthUserTable? _reviewedByAuthUser;

  late final _is.ColumnString appealReason;

  late final _is.ColumnDateTime appealedAt;

  late final _is.ColumnDateTime appealResolvedAt;

  _iacs.AuthUserTable get creatorAuthUser {
    if (_creatorAuthUser != null) return _creatorAuthUser!;
    _creatorAuthUser = _is.createRelationTable(
      relationFieldName: 'creatorAuthUser',
      field: ModerationCase.t.creatorAuthUserId,
      foreignField: _iacs.AuthUser.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iacs.AuthUserTable(tableRelation: foreignTableRelation),
    );
    return _creatorAuthUser!;
  }

  _iacs.AuthUserTable get reporterAuthUser {
    if (_reporterAuthUser != null) return _reporterAuthUser!;
    _reporterAuthUser = _is.createRelationTable(
      relationFieldName: 'reporterAuthUser',
      field: ModerationCase.t.reporterAuthUserId,
      foreignField: _iacs.AuthUser.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iacs.AuthUserTable(tableRelation: foreignTableRelation),
    );
    return _reporterAuthUser!;
  }

  _iacs.AuthUserTable get reviewedByAuthUser {
    if (_reviewedByAuthUser != null) return _reviewedByAuthUser!;
    _reviewedByAuthUser = _is.createRelationTable(
      relationFieldName: 'reviewedByAuthUser',
      field: ModerationCase.t.reviewedByAuthUserId,
      foreignField: _iacs.AuthUser.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iacs.AuthUserTable(tableRelation: foreignTableRelation),
    );
    return _reviewedByAuthUser!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    creatorAuthUserId,
    actionDefinitionId,
    reporterAuthUserId,
    idempotencyKey,
    category,
    details,
    status,
    pauseActive,
    createdAt,
    reviewedAt,
    reviewedByAuthUserId,
    appealReason,
    appealedAt,
    appealResolvedAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'creatorAuthUser') {
      return creatorAuthUser;
    }
    if (relationField == 'reporterAuthUser') {
      return reporterAuthUser;
    }
    if (relationField == 'reviewedByAuthUser') {
      return reviewedByAuthUser;
    }
    return null;
  }
}

class ModerationCaseInclude extends _is.IncludeObject {
  ModerationCaseInclude._({
    _iacs.AuthUserInclude? creatorAuthUser,
    _iacs.AuthUserInclude? reporterAuthUser,
    _iacs.AuthUserInclude? reviewedByAuthUser,
  }) {
    _creatorAuthUser = creatorAuthUser;
    _reporterAuthUser = reporterAuthUser;
    _reviewedByAuthUser = reviewedByAuthUser;
  }

  _iacs.AuthUserInclude? _creatorAuthUser;

  _iacs.AuthUserInclude? _reporterAuthUser;

  _iacs.AuthUserInclude? _reviewedByAuthUser;

  @override
  Map<String, _is.Include?> get includes => {
    'creatorAuthUser': _creatorAuthUser,
    'reporterAuthUser': _reporterAuthUser,
    'reviewedByAuthUser': _reviewedByAuthUser,
  };

  @override
  _is.Table<_is.UuidValue?> get table => ModerationCase.t;
}

class ModerationCaseIncludeList extends _is.IncludeList {
  ModerationCaseIncludeList._({
    _is.WhereExpressionBuilder<ModerationCaseTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ModerationCase.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => ModerationCase.t;
}

class ModerationCaseRepository {
  const ModerationCaseRepository._();

  final attachRow = const ModerationCaseAttachRowRepository._();

  final detachRow = const ModerationCaseDetachRowRepository._();

  /// Returns a list of [ModerationCase]s matching the given query parameters.
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
  Future<List<ModerationCase>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ModerationCaseTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ModerationCaseTable>? orderBy,
    _is.OrderByListBuilder<ModerationCaseTable>? orderByList,
    _is.Transaction? transaction,
    ModerationCaseInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ModerationCase>(
      where: where?.call(ModerationCase.t),
      orderBy: orderBy?.call(ModerationCase.t),
      orderByList: orderByList?.call(ModerationCase.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [ModerationCase]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `ModerationCase.t`.
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
  _ida.Stream<List<ModerationCase>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ModerationCaseTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ModerationCaseTable>? orderBy,
    _is.OrderByListBuilder<ModerationCaseTable>? orderByList,
    ModerationCaseInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<ModerationCase>(
      where: where?.call(ModerationCase.t),
      orderBy: orderBy?.call(ModerationCase.t),
      orderByList: orderByList?.call(ModerationCase.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [ModerationCase] matching the given query parameters.
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
  Future<ModerationCase?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ModerationCaseTable>? where,
    int? offset,
    _is.OrderByBuilder<ModerationCaseTable>? orderBy,
    _is.OrderByListBuilder<ModerationCaseTable>? orderByList,
    _is.Transaction? transaction,
    ModerationCaseInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ModerationCase>(
      where: where?.call(ModerationCase.t),
      orderBy: orderBy?.call(ModerationCase.t),
      orderByList: orderByList?.call(ModerationCase.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ModerationCase] by its [id] or null if no such row exists.
  Future<ModerationCase?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    ModerationCaseInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ModerationCase>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ModerationCase]s in the list and returns the inserted rows.
  ///
  /// The returned [ModerationCase]s will have their `id` fields set.
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
  Future<List<ModerationCase>> insert(
    _is.DatabaseSession session,
    List<ModerationCase> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ModerationCase>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ModerationCase] and returns the inserted row.
  ///
  /// The returned [ModerationCase] will have its `id` field set.
  Future<ModerationCase> insertRow(
    _is.DatabaseSession session,
    ModerationCase row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ModerationCase>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ModerationCase]s in the list and returns the resulting rows.
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
  /// The returned [ModerationCase]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ModerationCase>> upsert(
    _is.DatabaseSession session,
    List<ModerationCase> rows, {
    required _is.ColumnSelections<ModerationCaseTable> conflictColumns,
    _is.ColumnSelections<ModerationCaseTable>? updateColumns,
    _is.WhereExpressionBuilder<ModerationCaseTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ModerationCase>(
      rows,
      conflictColumns: conflictColumns(ModerationCase.t),
      updateColumns: updateColumns?.call(ModerationCase.t),
      updateWhere: updateWhere?.call(ModerationCase.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ModerationCase] and returns the resulting row.
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
  /// The returned [ModerationCase] will have its `id` field set.
  Future<ModerationCase?> upsertRow(
    _is.DatabaseSession session,
    ModerationCase row, {
    required _is.ColumnSelections<ModerationCaseTable> conflictColumns,
    _is.ColumnSelections<ModerationCaseTable>? updateColumns,
    _is.WhereExpressionBuilder<ModerationCaseTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ModerationCase>(
      row,
      conflictColumns: conflictColumns(ModerationCase.t),
      updateColumns: updateColumns?.call(ModerationCase.t),
      updateWhere: updateWhere?.call(ModerationCase.t),
      transaction: transaction,
    );
  }

  /// Updates all [ModerationCase]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ModerationCase>> update(
    _is.DatabaseSession session,
    List<ModerationCase> rows, {
    _is.ColumnSelections<ModerationCaseTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ModerationCase>(
      rows,
      columns: columns?.call(ModerationCase.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ModerationCase]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ModerationCase> updateRow(
    _is.DatabaseSession session,
    ModerationCase row, {
    _is.ColumnSelections<ModerationCaseTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ModerationCase>(
      row,
      columns: columns?.call(ModerationCase.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ModerationCase] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ModerationCase?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<ModerationCaseUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ModerationCase>(
      id,
      columnValues: columnValues(ModerationCase.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ModerationCase]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ModerationCase>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ModerationCaseUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ModerationCaseTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ModerationCaseTable>? orderBy,
    _is.OrderByListBuilder<ModerationCaseTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ModerationCase>(
      columnValues: columnValues(ModerationCase.t.updateTable),
      where: where(ModerationCase.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ModerationCase.t),
      orderByList: orderByList?.call(ModerationCase.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ModerationCase]s in the list and returns the deleted rows.
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
  Future<List<ModerationCase>> delete(
    _is.DatabaseSession session,
    List<ModerationCase> rows, {
    _is.OrderByBuilder<ModerationCaseTable>? orderBy,
    _is.OrderByListBuilder<ModerationCaseTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ModerationCase>(
      rows,
      orderBy: orderBy?.call(ModerationCase.t),
      orderByList: orderByList?.call(ModerationCase.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ModerationCase].
  Future<ModerationCase> deleteRow(
    _is.DatabaseSession session,
    ModerationCase row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ModerationCase>(
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
  Future<List<ModerationCase>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ModerationCaseTable> where,
    _is.OrderByBuilder<ModerationCaseTable>? orderBy,
    _is.OrderByListBuilder<ModerationCaseTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ModerationCase>(
      where: where(ModerationCase.t),
      orderBy: orderBy?.call(ModerationCase.t),
      orderByList: orderByList?.call(ModerationCase.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ModerationCaseTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ModerationCase>(
      where: where?.call(ModerationCase.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ModerationCase] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ModerationCaseTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ModerationCase>(
      where: where(ModerationCase.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class ModerationCaseAttachRowRepository {
  const ModerationCaseAttachRowRepository._();

  /// Creates a relation between the given [ModerationCase] and [AuthUser]
  /// by setting the [ModerationCase]'s foreign key `creatorAuthUserId` to refer to the [AuthUser].
  Future<void> creatorAuthUser(
    _is.DatabaseSession session,
    ModerationCase moderationCase,
    _iacs.AuthUser creatorAuthUser, {
    _is.Transaction? transaction,
  }) async {
    if (moderationCase.id == null) {
      throw ArgumentError.notNull('moderationCase.id');
    }
    if (creatorAuthUser.id == null) {
      throw ArgumentError.notNull('creatorAuthUser.id');
    }

    var $moderationCase = moderationCase.copyWith(
      creatorAuthUserId: creatorAuthUser.id,
    );
    await session.db.updateRow<ModerationCase>(
      $moderationCase,
      columns: [ModerationCase.t.creatorAuthUserId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [ModerationCase] and [AuthUser]
  /// by setting the [ModerationCase]'s foreign key `reporterAuthUserId` to refer to the [AuthUser].
  Future<void> reporterAuthUser(
    _is.DatabaseSession session,
    ModerationCase moderationCase,
    _iacs.AuthUser reporterAuthUser, {
    _is.Transaction? transaction,
  }) async {
    if (moderationCase.id == null) {
      throw ArgumentError.notNull('moderationCase.id');
    }
    if (reporterAuthUser.id == null) {
      throw ArgumentError.notNull('reporterAuthUser.id');
    }

    var $moderationCase = moderationCase.copyWith(
      reporterAuthUserId: reporterAuthUser.id,
    );
    await session.db.updateRow<ModerationCase>(
      $moderationCase,
      columns: [ModerationCase.t.reporterAuthUserId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [ModerationCase] and [AuthUser]
  /// by setting the [ModerationCase]'s foreign key `reviewedByAuthUserId` to refer to the [AuthUser].
  Future<void> reviewedByAuthUser(
    _is.DatabaseSession session,
    ModerationCase moderationCase,
    _iacs.AuthUser reviewedByAuthUser, {
    _is.Transaction? transaction,
  }) async {
    if (moderationCase.id == null) {
      throw ArgumentError.notNull('moderationCase.id');
    }
    if (reviewedByAuthUser.id == null) {
      throw ArgumentError.notNull('reviewedByAuthUser.id');
    }

    var $moderationCase = moderationCase.copyWith(
      reviewedByAuthUserId: reviewedByAuthUser.id,
    );
    await session.db.updateRow<ModerationCase>(
      $moderationCase,
      columns: [ModerationCase.t.reviewedByAuthUserId],
      transaction: transaction,
    );
  }
}

class ModerationCaseDetachRowRepository {
  const ModerationCaseDetachRowRepository._();

  /// Detaches the relation between this [ModerationCase] and the [AuthUser] set in `reporterAuthUser`
  /// by setting the [ModerationCase]'s foreign key `reporterAuthUserId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> reporterAuthUser(
    _is.DatabaseSession session,
    ModerationCase moderationCase, {
    _is.Transaction? transaction,
  }) async {
    if (moderationCase.id == null) {
      throw ArgumentError.notNull('moderationCase.id');
    }

    var $moderationCase = moderationCase.copyWith(reporterAuthUserId: null);
    await session.db.updateRow<ModerationCase>(
      $moderationCase,
      columns: [ModerationCase.t.reporterAuthUserId],
      transaction: transaction,
    );
  }

  /// Detaches the relation between this [ModerationCase] and the [AuthUser] set in `reviewedByAuthUser`
  /// by setting the [ModerationCase]'s foreign key `reviewedByAuthUserId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> reviewedByAuthUser(
    _is.DatabaseSession session,
    ModerationCase moderationCase, {
    _is.Transaction? transaction,
  }) async {
    if (moderationCase.id == null) {
      throw ArgumentError.notNull('moderationCase.id');
    }

    var $moderationCase = moderationCase.copyWith(reviewedByAuthUserId: null);
    await session.db.updateRow<ModerationCase>(
      $moderationCase,
      columns: [ModerationCase.t.reviewedByAuthUserId],
      transaction: transaction,
    );
  }
}
