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

import '../apps/verily_app_status.dart' as _i0paxa5b;

/// A Verily App: software a creator registers to confirm their own
/// `external` requirements, and the anchor later platform features (API
/// action creation, verification requests, outbound webhooks) attach to.
/// Apps are revoked, never deleted, so confirmation receipts keep their trail.
abstract class VerilyApp
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  VerilyApp._({
    this.id,
    required this.creatorAuthUserId,
    this.creatorAuthUser,
    required this.name,
    this.websiteUrl,
    required this.status,
    this.rateWindowStartedAt,
    int? rateWindowCount,
    this.webhookUrl,
    int? webhookSecretVersion,
    this.previousWebhookSecretVersion,
    this.webhookSecretRotatedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.revokedAt,
  }) : rateWindowCount = rateWindowCount ?? 0,
       webhookSecretVersion = webhookSecretVersion ?? 0,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory VerilyApp({
    _is.UuidValue? id,
    required _is.UuidValue creatorAuthUserId,
    _iacs.AuthUser? creatorAuthUser,
    required String name,
    String? websiteUrl,
    required _i0paxa5b.VerilyAppStatus status,
    DateTime? rateWindowStartedAt,
    int? rateWindowCount,
    String? webhookUrl,
    int? webhookSecretVersion,
    int? previousWebhookSecretVersion,
    DateTime? webhookSecretRotatedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? revokedAt,
  }) = _VerilyAppImpl;

  factory VerilyApp.fromJson(Map<String, dynamic> jsonSerialization) {
    return VerilyApp(
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
      name: jsonSerialization['name'] as String,
      websiteUrl: jsonSerialization['websiteUrl'] as String?,
      status: _i0paxa5b.VerilyAppStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      rateWindowStartedAt: jsonSerialization['rateWindowStartedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['rateWindowStartedAt'],
            ),
      rateWindowCount: jsonSerialization['rateWindowCount'] as int?,
      webhookUrl: jsonSerialization['webhookUrl'] as String?,
      webhookSecretVersion: jsonSerialization['webhookSecretVersion'] as int?,
      previousWebhookSecretVersion:
          jsonSerialization['previousWebhookSecretVersion'] as int?,
      webhookSecretRotatedAt:
          jsonSerialization['webhookSecretRotatedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['webhookSecretRotatedAt'],
            ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      revokedAt: jsonSerialization['revokedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['revokedAt']),
    );
  }

  static final t = VerilyAppTable();

  static const db = VerilyAppRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue creatorAuthUserId;

  _iacs.AuthUser? creatorAuthUser;

  String name;

  /// Shown to participants beside the App's name; HTTPS only.
  String? websiteUrl;

  _i0paxa5b.VerilyAppStatus status;

  /// Start of the fixed rate-limit window, advanced under the App row lock.
  DateTime? rateWindowStartedAt;

  /// Authenticated deliveries counted in the current rate-limit window.
  int rateWindowCount;

  /// HTTPS endpoint for signed events and pull verification; null until set.
  String? webhookUrl;

  /// Version of the current `whsec_` signing secret; 0 means none issued.
  /// Secrets are derived from the server master key and this version, so no
  /// secret is stored.
  int webhookSecretVersion;

  /// The version replaced by the last rotation, still signed alongside the
  /// current one for 24 hours so the App can roll over.
  int? previousWebhookSecretVersion;

  DateTime? webhookSecretRotatedAt;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? revokedAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [VerilyApp]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  VerilyApp copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? creatorAuthUserId,
    _iacs.AuthUser? creatorAuthUser =
        const _UndefinedVerilyApp$creatorAuthUser(),
    String? name,
    String? websiteUrl,
    _i0paxa5b.VerilyAppStatus? status,
    DateTime? rateWindowStartedAt = const _is.$UndefinedDateTime(),
    int? rateWindowCount,
    String? webhookUrl,
    int? webhookSecretVersion,
    int? previousWebhookSecretVersion,
    DateTime? webhookSecretRotatedAt = const _is.$UndefinedDateTime(),
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? revokedAt = const _is.$UndefinedDateTime(),
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'VerilyApp',
      if (id != null) 'id': id?.toJson(),
      'creatorAuthUserId': creatorAuthUserId.toJson(),
      if (creatorAuthUser != null) 'creatorAuthUser': creatorAuthUser?.toJson(),
      'name': name,
      if (websiteUrl != null) 'websiteUrl': websiteUrl,
      'status': status.toJson(),
      if (rateWindowStartedAt != null)
        'rateWindowStartedAt': rateWindowStartedAt?.toJson(),
      'rateWindowCount': rateWindowCount,
      if (webhookUrl != null) 'webhookUrl': webhookUrl,
      'webhookSecretVersion': webhookSecretVersion,
      if (previousWebhookSecretVersion != null)
        'previousWebhookSecretVersion': previousWebhookSecretVersion,
      if (webhookSecretRotatedAt != null)
        'webhookSecretRotatedAt': webhookSecretRotatedAt?.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (revokedAt != null) 'revokedAt': revokedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static VerilyAppInclude include({_iacs.AuthUserInclude? creatorAuthUser}) {
    return VerilyAppInclude._(creatorAuthUser: creatorAuthUser);
  }

  static VerilyAppIncludeList includeList({
    _is.WhereExpressionBuilder<VerilyAppTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VerilyAppTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppTable>? orderByList,
    VerilyAppInclude? include,
  }) {
    return VerilyAppIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(VerilyApp.t),
      orderByList: orderByList?.call(VerilyApp.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedVerilyApp$creatorAuthUser extends _is.UndefinedSentinel
    implements _iacs.AuthUser {
  const _UndefinedVerilyApp$creatorAuthUser();
}

class _VerilyAppImpl extends VerilyApp {
  _VerilyAppImpl({
    _is.UuidValue? id,
    required _is.UuidValue creatorAuthUserId,
    _iacs.AuthUser? creatorAuthUser,
    required String name,
    String? websiteUrl,
    required _i0paxa5b.VerilyAppStatus status,
    DateTime? rateWindowStartedAt,
    int? rateWindowCount,
    String? webhookUrl,
    int? webhookSecretVersion,
    int? previousWebhookSecretVersion,
    DateTime? webhookSecretRotatedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? revokedAt,
  }) : super._(
         id: id,
         creatorAuthUserId: creatorAuthUserId,
         creatorAuthUser: creatorAuthUser,
         name: name,
         websiteUrl: websiteUrl,
         status: status,
         rateWindowStartedAt: rateWindowStartedAt,
         rateWindowCount: rateWindowCount,
         webhookUrl: webhookUrl,
         webhookSecretVersion: webhookSecretVersion,
         previousWebhookSecretVersion: previousWebhookSecretVersion,
         webhookSecretRotatedAt: webhookSecretRotatedAt,
         createdAt: createdAt,
         updatedAt: updatedAt,
         revokedAt: revokedAt,
       );

  /// Returns a shallow copy of this [VerilyApp]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  VerilyApp copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? creatorAuthUserId,
    _iacs.AuthUser? creatorAuthUser =
        const _UndefinedVerilyApp$creatorAuthUser(),
    String? name,
    Object? websiteUrl = _Undefined,
    _i0paxa5b.VerilyAppStatus? status,
    DateTime? rateWindowStartedAt = const _is.$UndefinedDateTime(),
    int? rateWindowCount,
    Object? webhookUrl = _Undefined,
    int? webhookSecretVersion,
    Object? previousWebhookSecretVersion = _Undefined,
    DateTime? webhookSecretRotatedAt = const _is.$UndefinedDateTime(),
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? revokedAt = const _is.$UndefinedDateTime(),
  }) {
    return VerilyApp(
      id: id is _is.UndefinedSentinel ? this.id : id,
      creatorAuthUserId: creatorAuthUserId ?? this.creatorAuthUserId,
      creatorAuthUser: creatorAuthUser is _is.UndefinedSentinel
          ? this.creatorAuthUser?.copyWith()
          : creatorAuthUser,
      name: name ?? this.name,
      websiteUrl: websiteUrl is String? ? websiteUrl : this.websiteUrl,
      status: status ?? this.status,
      rateWindowStartedAt: rateWindowStartedAt is _is.UndefinedSentinel
          ? this.rateWindowStartedAt
          : rateWindowStartedAt,
      rateWindowCount: rateWindowCount ?? this.rateWindowCount,
      webhookUrl: webhookUrl is String? ? webhookUrl : this.webhookUrl,
      webhookSecretVersion: webhookSecretVersion ?? this.webhookSecretVersion,
      previousWebhookSecretVersion: previousWebhookSecretVersion is int?
          ? previousWebhookSecretVersion
          : this.previousWebhookSecretVersion,
      webhookSecretRotatedAt: webhookSecretRotatedAt is _is.UndefinedSentinel
          ? this.webhookSecretRotatedAt
          : webhookSecretRotatedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      revokedAt: revokedAt is _is.UndefinedSentinel
          ? this.revokedAt
          : revokedAt,
    );
  }
}

class VerilyAppUpdateTable extends _is.UpdateTable<VerilyAppTable> {
  VerilyAppUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> creatorAuthUserId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.creatorAuthUserId,
    value,
  );

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<String, String> websiteUrl(String? value) => _is.ColumnValue(
    table.websiteUrl,
    value,
  );

  _is.ColumnValue<_i0paxa5b.VerilyAppStatus, _i0paxa5b.VerilyAppStatus> status(
    _i0paxa5b.VerilyAppStatus value,
  ) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> rateWindowStartedAt(DateTime? value) =>
      _is.ColumnValue(
        table.rateWindowStartedAt,
        value,
      );

  _is.ColumnValue<int, int> rateWindowCount(int value) => _is.ColumnValue(
    table.rateWindowCount,
    value,
  );

  _is.ColumnValue<String, String> webhookUrl(String? value) => _is.ColumnValue(
    table.webhookUrl,
    value,
  );

  _is.ColumnValue<int, int> webhookSecretVersion(int value) => _is.ColumnValue(
    table.webhookSecretVersion,
    value,
  );

  _is.ColumnValue<int, int> previousWebhookSecretVersion(int? value) =>
      _is.ColumnValue(
        table.previousWebhookSecretVersion,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> webhookSecretRotatedAt(DateTime? value) =>
      _is.ColumnValue(
        table.webhookSecretRotatedAt,
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

  _is.ColumnValue<DateTime, DateTime> revokedAt(DateTime? value) =>
      _is.ColumnValue(
        table.revokedAt,
        value,
      );
}

class VerilyAppTable extends _is.Table<_is.UuidValue?> {
  VerilyAppTable({super.tableRelation}) : super(tableName: 'verily_app') {
    updateTable = VerilyAppUpdateTable(this);
    creatorAuthUserId = _is.ColumnUuid(
      'creatorAuthUserId',
      this,
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    websiteUrl = _is.ColumnString(
      'websiteUrl',
      this,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
    );
    rateWindowStartedAt = _is.ColumnDateTime(
      'rateWindowStartedAt',
      this,
    );
    rateWindowCount = _is.ColumnInt(
      'rateWindowCount',
      this,
      hasDefault: true,
    );
    webhookUrl = _is.ColumnString(
      'webhookUrl',
      this,
    );
    webhookSecretVersion = _is.ColumnInt(
      'webhookSecretVersion',
      this,
      hasDefault: true,
    );
    previousWebhookSecretVersion = _is.ColumnInt(
      'previousWebhookSecretVersion',
      this,
    );
    webhookSecretRotatedAt = _is.ColumnDateTime(
      'webhookSecretRotatedAt',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    updatedAt = _is.ColumnDateTime(
      'updatedAt',
      this,
    );
    revokedAt = _is.ColumnDateTime(
      'revokedAt',
      this,
    );
  }

  late final VerilyAppUpdateTable updateTable;

  late final _is.ColumnUuid creatorAuthUserId;

  _iacs.AuthUserTable? _creatorAuthUser;

  late final _is.ColumnString name;

  /// Shown to participants beside the App's name; HTTPS only.
  late final _is.ColumnString websiteUrl;

  late final _is.ColumnEnum<_i0paxa5b.VerilyAppStatus> status;

  /// Start of the fixed rate-limit window, advanced under the App row lock.
  late final _is.ColumnDateTime rateWindowStartedAt;

  /// Authenticated deliveries counted in the current rate-limit window.
  late final _is.ColumnInt rateWindowCount;

  /// HTTPS endpoint for signed events and pull verification; null until set.
  late final _is.ColumnString webhookUrl;

  /// Version of the current `whsec_` signing secret; 0 means none issued.
  /// Secrets are derived from the server master key and this version, so no
  /// secret is stored.
  late final _is.ColumnInt webhookSecretVersion;

  /// The version replaced by the last rotation, still signed alongside the
  /// current one for 24 hours so the App can roll over.
  late final _is.ColumnInt previousWebhookSecretVersion;

  late final _is.ColumnDateTime webhookSecretRotatedAt;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  late final _is.ColumnDateTime revokedAt;

  _iacs.AuthUserTable get creatorAuthUser {
    if (_creatorAuthUser != null) return _creatorAuthUser!;
    _creatorAuthUser = _is.createRelationTable(
      relationFieldName: 'creatorAuthUser',
      field: VerilyApp.t.creatorAuthUserId,
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
    name,
    websiteUrl,
    status,
    rateWindowStartedAt,
    rateWindowCount,
    webhookUrl,
    webhookSecretVersion,
    previousWebhookSecretVersion,
    webhookSecretRotatedAt,
    createdAt,
    updatedAt,
    revokedAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'creatorAuthUser') {
      return creatorAuthUser;
    }
    return null;
  }
}

class VerilyAppInclude extends _is.IncludeObject {
  VerilyAppInclude._({_iacs.AuthUserInclude? creatorAuthUser}) {
    _creatorAuthUser = creatorAuthUser;
  }

  _iacs.AuthUserInclude? _creatorAuthUser;

  @override
  Map<String, _is.Include?> get includes => {
    'creatorAuthUser': _creatorAuthUser,
  };

  @override
  _is.Table<_is.UuidValue?> get table => VerilyApp.t;
}

class VerilyAppIncludeList extends _is.IncludeList {
  VerilyAppIncludeList._({
    _is.WhereExpressionBuilder<VerilyAppTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(VerilyApp.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => VerilyApp.t;
}

class VerilyAppRepository {
  const VerilyAppRepository._();

  final attachRow = const VerilyAppAttachRowRepository._();

  /// Returns a list of [VerilyApp]s matching the given query parameters.
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
  Future<List<VerilyApp>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VerilyAppTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VerilyAppTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppTable>? orderByList,
    _is.Transaction? transaction,
    VerilyAppInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<VerilyApp>(
      where: where?.call(VerilyApp.t),
      orderBy: orderBy?.call(VerilyApp.t),
      orderByList: orderByList?.call(VerilyApp.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [VerilyApp]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `VerilyApp.t`.
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
  _ida.Stream<List<VerilyApp>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VerilyAppTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VerilyAppTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppTable>? orderByList,
    VerilyAppInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<VerilyApp>(
      where: where?.call(VerilyApp.t),
      orderBy: orderBy?.call(VerilyApp.t),
      orderByList: orderByList?.call(VerilyApp.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [VerilyApp] matching the given query parameters.
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
  Future<VerilyApp?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VerilyAppTable>? where,
    int? offset,
    _is.OrderByBuilder<VerilyAppTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppTable>? orderByList,
    _is.Transaction? transaction,
    VerilyAppInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<VerilyApp>(
      where: where?.call(VerilyApp.t),
      orderBy: orderBy?.call(VerilyApp.t),
      orderByList: orderByList?.call(VerilyApp.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [VerilyApp] by its [id] or null if no such row exists.
  Future<VerilyApp?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    VerilyAppInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<VerilyApp>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [VerilyApp]s in the list and returns the inserted rows.
  ///
  /// The returned [VerilyApp]s will have their `id` fields set.
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
  Future<List<VerilyApp>> insert(
    _is.DatabaseSession session,
    List<VerilyApp> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<VerilyApp>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [VerilyApp] and returns the inserted row.
  ///
  /// The returned [VerilyApp] will have its `id` field set.
  Future<VerilyApp> insertRow(
    _is.DatabaseSession session,
    VerilyApp row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<VerilyApp>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [VerilyApp]s in the list and returns the resulting rows.
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
  /// The returned [VerilyApp]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<VerilyApp>> upsert(
    _is.DatabaseSession session,
    List<VerilyApp> rows, {
    required _is.ColumnSelections<VerilyAppTable> conflictColumns,
    _is.ColumnSelections<VerilyAppTable>? updateColumns,
    _is.WhereExpressionBuilder<VerilyAppTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<VerilyApp>(
      rows,
      conflictColumns: conflictColumns(VerilyApp.t),
      updateColumns: updateColumns?.call(VerilyApp.t),
      updateWhere: updateWhere?.call(VerilyApp.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [VerilyApp] and returns the resulting row.
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
  /// The returned [VerilyApp] will have its `id` field set.
  Future<VerilyApp?> upsertRow(
    _is.DatabaseSession session,
    VerilyApp row, {
    required _is.ColumnSelections<VerilyAppTable> conflictColumns,
    _is.ColumnSelections<VerilyAppTable>? updateColumns,
    _is.WhereExpressionBuilder<VerilyAppTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<VerilyApp>(
      row,
      conflictColumns: conflictColumns(VerilyApp.t),
      updateColumns: updateColumns?.call(VerilyApp.t),
      updateWhere: updateWhere?.call(VerilyApp.t),
      transaction: transaction,
    );
  }

  /// Updates all [VerilyApp]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<VerilyApp>> update(
    _is.DatabaseSession session,
    List<VerilyApp> rows, {
    _is.ColumnSelections<VerilyAppTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<VerilyApp>(
      rows,
      columns: columns?.call(VerilyApp.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [VerilyApp]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<VerilyApp> updateRow(
    _is.DatabaseSession session,
    VerilyApp row, {
    _is.ColumnSelections<VerilyAppTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<VerilyApp>(
      row,
      columns: columns?.call(VerilyApp.t),
      transaction: transaction,
    );
  }

  /// Updates a single [VerilyApp] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<VerilyApp?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<VerilyAppUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<VerilyApp>(
      id,
      columnValues: columnValues(VerilyApp.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [VerilyApp]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<VerilyApp>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<VerilyAppUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<VerilyAppTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<VerilyAppTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<VerilyApp>(
      columnValues: columnValues(VerilyApp.t.updateTable),
      where: where(VerilyApp.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(VerilyApp.t),
      orderByList: orderByList?.call(VerilyApp.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [VerilyApp]s in the list and returns the deleted rows.
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
  Future<List<VerilyApp>> delete(
    _is.DatabaseSession session,
    List<VerilyApp> rows, {
    _is.OrderByBuilder<VerilyAppTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<VerilyApp>(
      rows,
      orderBy: orderBy?.call(VerilyApp.t),
      orderByList: orderByList?.call(VerilyApp.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [VerilyApp].
  Future<VerilyApp> deleteRow(
    _is.DatabaseSession session,
    VerilyApp row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<VerilyApp>(
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
  Future<List<VerilyApp>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<VerilyAppTable> where,
    _is.OrderByBuilder<VerilyAppTable>? orderBy,
    _is.OrderByListBuilder<VerilyAppTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<VerilyApp>(
      where: where(VerilyApp.t),
      orderBy: orderBy?.call(VerilyApp.t),
      orderByList: orderByList?.call(VerilyApp.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<VerilyAppTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<VerilyApp>(
      where: where?.call(VerilyApp.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [VerilyApp] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<VerilyAppTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<VerilyApp>(
      where: where(VerilyApp.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class VerilyAppAttachRowRepository {
  const VerilyAppAttachRowRepository._();

  /// Creates a relation between the given [VerilyApp] and [AuthUser]
  /// by setting the [VerilyApp]'s foreign key `creatorAuthUserId` to refer to the [AuthUser].
  Future<void> creatorAuthUser(
    _is.DatabaseSession session,
    VerilyApp verilyApp,
    _iacs.AuthUser creatorAuthUser, {
    _is.Transaction? transaction,
  }) async {
    if (verilyApp.id == null) {
      throw ArgumentError.notNull('verilyApp.id');
    }
    if (creatorAuthUser.id == null) {
      throw ArgumentError.notNull('creatorAuthUser.id');
    }

    var $verilyApp = verilyApp.copyWith(creatorAuthUserId: creatorAuthUser.id);
    await session.db.updateRow<VerilyApp>(
      $verilyApp,
      columns: [VerilyApp.t.creatorAuthUserId],
      transaction: transaction,
    );
  }
}
