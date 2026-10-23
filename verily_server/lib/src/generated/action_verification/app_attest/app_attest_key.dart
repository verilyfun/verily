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

import '../../action_verification/app_attest/app_attest_environment.dart'
    as _i2fus16r;

/// One account's App Attest key on one iPhone install, registered once with an
/// attestation Apple signed. Captures from that install are then signed with
/// assertions this key makes, each with a larger counter than the last.
abstract class AppAttestKey
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  AppAttestKey._({
    this.id,
    required this.authUserId,
    this.authUser,
    required this.keyId,
    required this.publicKey,
    required this.environment,
    required this.signCount,
    required this.certificateChain,
    required this.receipt,
    required this.receiptCreatedAt,
    required this.receiptRefreshAfter,
    required this.receiptNotBefore,
    required this.receiptExpiresAt,
    this.riskMetric,
    this.validationCategory,
    this.bundleVersion,
    required this.registeredAt,
    this.lastAssertedAt,
  });

  factory AppAttestKey({
    _is.UuidValue? id,
    required _is.UuidValue authUserId,
    _iacs.AuthUser? authUser,
    required String keyId,
    required String publicKey,
    required _i2fus16r.AppAttestEnvironment environment,
    required int signCount,
    required List<String> certificateChain,
    required String receipt,
    required DateTime receiptCreatedAt,
    required DateTime receiptRefreshAfter,
    required DateTime receiptNotBefore,
    required DateTime receiptExpiresAt,
    int? riskMetric,
    int? validationCategory,
    String? bundleVersion,
    required DateTime registeredAt,
    DateTime? lastAssertedAt,
  }) = _AppAttestKeyImpl;

  factory AppAttestKey.fromJson(Map<String, dynamic> jsonSerialization) {
    return AppAttestKey(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      authUserId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['authUserId'],
      ),
      authUser: jsonSerialization['authUser'] == null
          ? null
          : _itf691yl.Protocol().deserialize<_iacs.AuthUser>(
              jsonSerialization['authUser'],
            ),
      keyId: jsonSerialization['keyId'] as String,
      publicKey: jsonSerialization['publicKey'] as String,
      environment: _i2fus16r.AppAttestEnvironment.fromJson(
        (jsonSerialization['environment'] as String),
      ),
      signCount: jsonSerialization['signCount'] as int,
      certificateChain: _itf691yl.Protocol().deserialize<List<String>>(
        jsonSerialization['certificateChain'],
      ),
      receipt: jsonSerialization['receipt'] as String,
      receiptCreatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['receiptCreatedAt'],
      ),
      receiptRefreshAfter: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['receiptRefreshAfter'],
      ),
      receiptNotBefore: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['receiptNotBefore'],
      ),
      receiptExpiresAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['receiptExpiresAt'],
      ),
      riskMetric: jsonSerialization['riskMetric'] as int?,
      validationCategory: jsonSerialization['validationCategory'] as int?,
      bundleVersion: jsonSerialization['bundleVersion'] as String?,
      registeredAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['registeredAt'],
      ),
      lastAssertedAt: jsonSerialization['lastAssertedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastAssertedAt'],
            ),
    );
  }

  static final t = AppAttestKeyTable();

  static const db = AppAttestKeyRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue authUserId;

  /// The account that registered the key. Apple's guidance is one key per
  /// account per install, so a key never moves to another account.
  _iacs.AuthUser? authUser;

  /// SHA-256 of the public key, hex: the id evidence rows carry as
  /// `captureKeyId`. Apple's key identifier is the same digest in base64.
  String keyId;

  /// The attested P-256 key, `0x04 ‖ X ‖ Y`, base64.
  String publicKey;

  _i2fus16r.AppAttestEnvironment environment;

  /// The counter of the last accepted assertion; zero after registration.
  int signCount;

  /// The attestation's certificate chain (base64 DER, credential certificate
  /// first) and Apple's receipt (base64), kept for audit and for the
  /// fraud-risk metric. Both initial and refreshed receipts are verified.
  List<String> certificateChain;

  String receipt;

  DateTime receiptCreatedAt;

  /// Next refresh attempt (signed not-before, or one-hour outage backoff).
  DateTime receiptRefreshAfter;

  DateTime receiptNotBefore;

  DateTime receiptExpiresAt;

  /// Verified 30-day attested-key count from Apple's refreshed receipt.
  int? riskMetric;

  /// Apple's validation category and bundle version from the attestation;
  /// null on iOS versions that do not report them.
  int? validationCategory;

  String? bundleVersion;

  DateTime registeredAt;

  DateTime? lastAssertedAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [AppAttestKey]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AppAttestKey copyWith({
    _is.UuidValue? id,
    _is.UuidValue? authUserId,
    _iacs.AuthUser? authUser,
    String? keyId,
    String? publicKey,
    _i2fus16r.AppAttestEnvironment? environment,
    int? signCount,
    List<String>? certificateChain,
    String? receipt,
    DateTime? receiptCreatedAt,
    DateTime? receiptRefreshAfter,
    DateTime? receiptNotBefore,
    DateTime? receiptExpiresAt,
    int? riskMetric,
    int? validationCategory,
    String? bundleVersion,
    DateTime? registeredAt,
    DateTime? lastAssertedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AppAttestKey',
      if (id != null) 'id': id?.toJson(),
      'authUserId': authUserId.toJson(),
      if (authUser != null) 'authUser': authUser?.toJson(),
      'keyId': keyId,
      'publicKey': publicKey,
      'environment': environment.toJson(),
      'signCount': signCount,
      'certificateChain': certificateChain.toJson(),
      'receipt': receipt,
      'receiptCreatedAt': receiptCreatedAt.toJson(),
      'receiptRefreshAfter': receiptRefreshAfter.toJson(),
      'receiptNotBefore': receiptNotBefore.toJson(),
      'receiptExpiresAt': receiptExpiresAt.toJson(),
      if (riskMetric != null) 'riskMetric': riskMetric,
      if (validationCategory != null) 'validationCategory': validationCategory,
      if (bundleVersion != null) 'bundleVersion': bundleVersion,
      'registeredAt': registeredAt.toJson(),
      if (lastAssertedAt != null) 'lastAssertedAt': lastAssertedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static AppAttestKeyInclude include({_iacs.AuthUserInclude? authUser}) {
    return AppAttestKeyInclude._(authUser: authUser);
  }

  static AppAttestKeyIncludeList includeList({
    _is.WhereExpressionBuilder<AppAttestKeyTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AppAttestKeyTable>? orderBy,
    _is.OrderByListBuilder<AppAttestKeyTable>? orderByList,
    AppAttestKeyInclude? include,
  }) {
    return AppAttestKeyIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AppAttestKey.t),
      orderByList: orderByList?.call(AppAttestKey.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AppAttestKeyImpl extends AppAttestKey {
  _AppAttestKeyImpl({
    _is.UuidValue? id,
    required _is.UuidValue authUserId,
    _iacs.AuthUser? authUser,
    required String keyId,
    required String publicKey,
    required _i2fus16r.AppAttestEnvironment environment,
    required int signCount,
    required List<String> certificateChain,
    required String receipt,
    required DateTime receiptCreatedAt,
    required DateTime receiptRefreshAfter,
    required DateTime receiptNotBefore,
    required DateTime receiptExpiresAt,
    int? riskMetric,
    int? validationCategory,
    String? bundleVersion,
    required DateTime registeredAt,
    DateTime? lastAssertedAt,
  }) : super._(
         id: id,
         authUserId: authUserId,
         authUser: authUser,
         keyId: keyId,
         publicKey: publicKey,
         environment: environment,
         signCount: signCount,
         certificateChain: certificateChain,
         receipt: receipt,
         receiptCreatedAt: receiptCreatedAt,
         receiptRefreshAfter: receiptRefreshAfter,
         receiptNotBefore: receiptNotBefore,
         receiptExpiresAt: receiptExpiresAt,
         riskMetric: riskMetric,
         validationCategory: validationCategory,
         bundleVersion: bundleVersion,
         registeredAt: registeredAt,
         lastAssertedAt: lastAssertedAt,
       );

  /// Returns a shallow copy of this [AppAttestKey]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AppAttestKey copyWith({
    Object? id = _Undefined,
    _is.UuidValue? authUserId,
    Object? authUser = _Undefined,
    String? keyId,
    String? publicKey,
    _i2fus16r.AppAttestEnvironment? environment,
    int? signCount,
    List<String>? certificateChain,
    String? receipt,
    DateTime? receiptCreatedAt,
    DateTime? receiptRefreshAfter,
    DateTime? receiptNotBefore,
    DateTime? receiptExpiresAt,
    Object? riskMetric = _Undefined,
    Object? validationCategory = _Undefined,
    Object? bundleVersion = _Undefined,
    DateTime? registeredAt,
    Object? lastAssertedAt = _Undefined,
  }) {
    return AppAttestKey(
      id: id is _is.UuidValue? ? id : this.id,
      authUserId: authUserId ?? this.authUserId,
      authUser: authUser is _iacs.AuthUser?
          ? authUser
          : this.authUser?.copyWith(),
      keyId: keyId ?? this.keyId,
      publicKey: publicKey ?? this.publicKey,
      environment: environment ?? this.environment,
      signCount: signCount ?? this.signCount,
      certificateChain:
          certificateChain ?? this.certificateChain.map((e0) => e0).toList(),
      receipt: receipt ?? this.receipt,
      receiptCreatedAt: receiptCreatedAt ?? this.receiptCreatedAt,
      receiptRefreshAfter: receiptRefreshAfter ?? this.receiptRefreshAfter,
      receiptNotBefore: receiptNotBefore ?? this.receiptNotBefore,
      receiptExpiresAt: receiptExpiresAt ?? this.receiptExpiresAt,
      riskMetric: riskMetric is int? ? riskMetric : this.riskMetric,
      validationCategory: validationCategory is int?
          ? validationCategory
          : this.validationCategory,
      bundleVersion: bundleVersion is String?
          ? bundleVersion
          : this.bundleVersion,
      registeredAt: registeredAt ?? this.registeredAt,
      lastAssertedAt: lastAssertedAt is DateTime?
          ? lastAssertedAt
          : this.lastAssertedAt,
    );
  }
}

class AppAttestKeyUpdateTable extends _is.UpdateTable<AppAttestKeyTable> {
  AppAttestKeyUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> authUserId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.authUserId,
    value,
  );

  _is.ColumnValue<String, String> keyId(String value) => _is.ColumnValue(
    table.keyId,
    value,
  );

  _is.ColumnValue<String, String> publicKey(String value) => _is.ColumnValue(
    table.publicKey,
    value,
  );

  _is.ColumnValue<
    _i2fus16r.AppAttestEnvironment,
    _i2fus16r.AppAttestEnvironment
  >
  environment(_i2fus16r.AppAttestEnvironment value) => _is.ColumnValue(
    table.environment,
    value,
  );

  _is.ColumnValue<int, int> signCount(int value) => _is.ColumnValue(
    table.signCount,
    value,
  );

  _is.ColumnValue<List<String>, List<String>> certificateChain(
    List<String> value,
  ) => _is.ColumnValue(
    table.certificateChain,
    value,
  );

  _is.ColumnValue<String, String> receipt(String value) => _is.ColumnValue(
    table.receipt,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> receiptCreatedAt(DateTime value) =>
      _is.ColumnValue(
        table.receiptCreatedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> receiptRefreshAfter(DateTime value) =>
      _is.ColumnValue(
        table.receiptRefreshAfter,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> receiptNotBefore(DateTime value) =>
      _is.ColumnValue(
        table.receiptNotBefore,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> receiptExpiresAt(DateTime value) =>
      _is.ColumnValue(
        table.receiptExpiresAt,
        value,
      );

  _is.ColumnValue<int, int> riskMetric(int? value) => _is.ColumnValue(
    table.riskMetric,
    value,
  );

  _is.ColumnValue<int, int> validationCategory(int? value) => _is.ColumnValue(
    table.validationCategory,
    value,
  );

  _is.ColumnValue<String, String> bundleVersion(String? value) =>
      _is.ColumnValue(
        table.bundleVersion,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> registeredAt(DateTime value) =>
      _is.ColumnValue(
        table.registeredAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> lastAssertedAt(DateTime? value) =>
      _is.ColumnValue(
        table.lastAssertedAt,
        value,
      );
}

class AppAttestKeyTable extends _is.Table<_is.UuidValue?> {
  AppAttestKeyTable({super.tableRelation})
    : super(tableName: 'verily_app_attest_key') {
    updateTable = AppAttestKeyUpdateTable(this);
    authUserId = _is.ColumnUuid(
      'authUserId',
      this,
    );
    keyId = _is.ColumnString(
      'keyId',
      this,
    );
    publicKey = _is.ColumnString(
      'publicKey',
      this,
    );
    environment = _is.ColumnEnum(
      'environment',
      this,
      _is.EnumSerialization.byName,
    );
    signCount = _is.ColumnInt(
      'signCount',
      this,
    );
    certificateChain = _is.ColumnSerializable<List<String>>(
      'certificateChain',
      this,
    );
    receipt = _is.ColumnString(
      'receipt',
      this,
    );
    receiptCreatedAt = _is.ColumnDateTime(
      'receiptCreatedAt',
      this,
    );
    receiptRefreshAfter = _is.ColumnDateTime(
      'receiptRefreshAfter',
      this,
    );
    receiptNotBefore = _is.ColumnDateTime(
      'receiptNotBefore',
      this,
    );
    receiptExpiresAt = _is.ColumnDateTime(
      'receiptExpiresAt',
      this,
    );
    riskMetric = _is.ColumnInt(
      'riskMetric',
      this,
    );
    validationCategory = _is.ColumnInt(
      'validationCategory',
      this,
    );
    bundleVersion = _is.ColumnString(
      'bundleVersion',
      this,
    );
    registeredAt = _is.ColumnDateTime(
      'registeredAt',
      this,
    );
    lastAssertedAt = _is.ColumnDateTime(
      'lastAssertedAt',
      this,
    );
  }

  late final AppAttestKeyUpdateTable updateTable;

  late final _is.ColumnUuid authUserId;

  /// The account that registered the key. Apple's guidance is one key per
  /// account per install, so a key never moves to another account.
  _iacs.AuthUserTable? _authUser;

  /// SHA-256 of the public key, hex: the id evidence rows carry as
  /// `captureKeyId`. Apple's key identifier is the same digest in base64.
  late final _is.ColumnString keyId;

  /// The attested P-256 key, `0x04 ‖ X ‖ Y`, base64.
  late final _is.ColumnString publicKey;

  late final _is.ColumnEnum<_i2fus16r.AppAttestEnvironment> environment;

  /// The counter of the last accepted assertion; zero after registration.
  late final _is.ColumnInt signCount;

  /// The attestation's certificate chain (base64 DER, credential certificate
  /// first) and Apple's receipt (base64), kept for audit and for the
  /// fraud-risk metric. Both initial and refreshed receipts are verified.
  late final _is.ColumnSerializable<List<String>> certificateChain;

  late final _is.ColumnString receipt;

  late final _is.ColumnDateTime receiptCreatedAt;

  /// Next refresh attempt (signed not-before, or one-hour outage backoff).
  late final _is.ColumnDateTime receiptRefreshAfter;

  late final _is.ColumnDateTime receiptNotBefore;

  late final _is.ColumnDateTime receiptExpiresAt;

  /// Verified 30-day attested-key count from Apple's refreshed receipt.
  late final _is.ColumnInt riskMetric;

  /// Apple's validation category and bundle version from the attestation;
  /// null on iOS versions that do not report them.
  late final _is.ColumnInt validationCategory;

  late final _is.ColumnString bundleVersion;

  late final _is.ColumnDateTime registeredAt;

  late final _is.ColumnDateTime lastAssertedAt;

  _iacs.AuthUserTable get authUser {
    if (_authUser != null) return _authUser!;
    _authUser = _is.createRelationTable(
      relationFieldName: 'authUser',
      field: AppAttestKey.t.authUserId,
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
    authUserId,
    keyId,
    publicKey,
    environment,
    signCount,
    certificateChain,
    receipt,
    receiptCreatedAt,
    receiptRefreshAfter,
    receiptNotBefore,
    receiptExpiresAt,
    riskMetric,
    validationCategory,
    bundleVersion,
    registeredAt,
    lastAssertedAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'authUser') {
      return authUser;
    }
    return null;
  }
}

class AppAttestKeyInclude extends _is.IncludeObject {
  AppAttestKeyInclude._({_iacs.AuthUserInclude? authUser}) {
    _authUser = authUser;
  }

  _iacs.AuthUserInclude? _authUser;

  @override
  Map<String, _is.Include?> get includes => {'authUser': _authUser};

  @override
  _is.Table<_is.UuidValue?> get table => AppAttestKey.t;
}

class AppAttestKeyIncludeList extends _is.IncludeList {
  AppAttestKeyIncludeList._({
    _is.WhereExpressionBuilder<AppAttestKeyTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AppAttestKey.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => AppAttestKey.t;
}

class AppAttestKeyRepository {
  const AppAttestKeyRepository._();

  final attachRow = const AppAttestKeyAttachRowRepository._();

  /// Returns a list of [AppAttestKey]s matching the given query parameters.
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
  Future<List<AppAttestKey>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AppAttestKeyTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AppAttestKeyTable>? orderBy,
    _is.OrderByListBuilder<AppAttestKeyTable>? orderByList,
    _is.Transaction? transaction,
    AppAttestKeyInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<AppAttestKey>(
      where: where?.call(AppAttestKey.t),
      orderBy: orderBy?.call(AppAttestKey.t),
      orderByList: orderByList?.call(AppAttestKey.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [AppAttestKey] matching the given query parameters.
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
  Future<AppAttestKey?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AppAttestKeyTable>? where,
    int? offset,
    _is.OrderByBuilder<AppAttestKeyTable>? orderBy,
    _is.OrderByListBuilder<AppAttestKeyTable>? orderByList,
    _is.Transaction? transaction,
    AppAttestKeyInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<AppAttestKey>(
      where: where?.call(AppAttestKey.t),
      orderBy: orderBy?.call(AppAttestKey.t),
      orderByList: orderByList?.call(AppAttestKey.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [AppAttestKey] by its [id] or null if no such row exists.
  Future<AppAttestKey?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    AppAttestKeyInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<AppAttestKey>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [AppAttestKey]s in the list and returns the inserted rows.
  ///
  /// The returned [AppAttestKey]s will have their `id` fields set.
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
  Future<List<AppAttestKey>> insert(
    _is.DatabaseSession session,
    List<AppAttestKey> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<AppAttestKey>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [AppAttestKey] and returns the inserted row.
  ///
  /// The returned [AppAttestKey] will have its `id` field set.
  Future<AppAttestKey> insertRow(
    _is.DatabaseSession session,
    AppAttestKey row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<AppAttestKey>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [AppAttestKey]s in the list and returns the resulting rows.
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
  /// The returned [AppAttestKey]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AppAttestKey>> upsert(
    _is.DatabaseSession session,
    List<AppAttestKey> rows, {
    required _is.ColumnSelections<AppAttestKeyTable> conflictColumns,
    _is.ColumnSelections<AppAttestKeyTable>? updateColumns,
    _is.WhereExpressionBuilder<AppAttestKeyTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<AppAttestKey>(
      rows,
      conflictColumns: conflictColumns(AppAttestKey.t),
      updateColumns: updateColumns?.call(AppAttestKey.t),
      updateWhere: updateWhere?.call(AppAttestKey.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [AppAttestKey] and returns the resulting row.
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
  /// The returned [AppAttestKey] will have its `id` field set.
  Future<AppAttestKey?> upsertRow(
    _is.DatabaseSession session,
    AppAttestKey row, {
    required _is.ColumnSelections<AppAttestKeyTable> conflictColumns,
    _is.ColumnSelections<AppAttestKeyTable>? updateColumns,
    _is.WhereExpressionBuilder<AppAttestKeyTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<AppAttestKey>(
      row,
      conflictColumns: conflictColumns(AppAttestKey.t),
      updateColumns: updateColumns?.call(AppAttestKey.t),
      updateWhere: updateWhere?.call(AppAttestKey.t),
      transaction: transaction,
    );
  }

  /// Updates all [AppAttestKey]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AppAttestKey>> update(
    _is.DatabaseSession session,
    List<AppAttestKey> rows, {
    _is.ColumnSelections<AppAttestKeyTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<AppAttestKey>(
      rows,
      columns: columns?.call(AppAttestKey.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [AppAttestKey]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AppAttestKey> updateRow(
    _is.DatabaseSession session,
    AppAttestKey row, {
    _is.ColumnSelections<AppAttestKeyTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<AppAttestKey>(
      row,
      columns: columns?.call(AppAttestKey.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AppAttestKey] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AppAttestKey?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<AppAttestKeyUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<AppAttestKey>(
      id,
      columnValues: columnValues(AppAttestKey.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AppAttestKey]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AppAttestKey>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<AppAttestKeyUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<AppAttestKeyTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AppAttestKeyTable>? orderBy,
    _is.OrderByListBuilder<AppAttestKeyTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<AppAttestKey>(
      columnValues: columnValues(AppAttestKey.t.updateTable),
      where: where(AppAttestKey.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AppAttestKey.t),
      orderByList: orderByList?.call(AppAttestKey.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [AppAttestKey]s in the list and returns the deleted rows.
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
  Future<List<AppAttestKey>> delete(
    _is.DatabaseSession session,
    List<AppAttestKey> rows, {
    _is.OrderByBuilder<AppAttestKeyTable>? orderBy,
    _is.OrderByListBuilder<AppAttestKeyTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<AppAttestKey>(
      rows,
      orderBy: orderBy?.call(AppAttestKey.t),
      orderByList: orderByList?.call(AppAttestKey.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [AppAttestKey].
  Future<AppAttestKey> deleteRow(
    _is.DatabaseSession session,
    AppAttestKey row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AppAttestKey>(
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
  Future<List<AppAttestKey>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AppAttestKeyTable> where,
    _is.OrderByBuilder<AppAttestKeyTable>? orderBy,
    _is.OrderByListBuilder<AppAttestKeyTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<AppAttestKey>(
      where: where(AppAttestKey.t),
      orderBy: orderBy?.call(AppAttestKey.t),
      orderByList: orderByList?.call(AppAttestKey.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AppAttestKeyTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<AppAttestKey>(
      where: where?.call(AppAttestKey.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [AppAttestKey] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AppAttestKeyTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<AppAttestKey>(
      where: where(AppAttestKey.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class AppAttestKeyAttachRowRepository {
  const AppAttestKeyAttachRowRepository._();

  /// Creates a relation between the given [AppAttestKey] and [AuthUser]
  /// by setting the [AppAttestKey]'s foreign key `authUserId` to refer to the [AuthUser].
  Future<void> authUser(
    _is.DatabaseSession session,
    AppAttestKey appAttestKey,
    _iacs.AuthUser authUser, {
    _is.Transaction? transaction,
  }) async {
    if (appAttestKey.id == null) {
      throw ArgumentError.notNull('appAttestKey.id');
    }
    if (authUser.id == null) {
      throw ArgumentError.notNull('authUser.id');
    }

    var $appAttestKey = appAttestKey.copyWith(authUserId: authUser.id);
    await session.db.updateRow<AppAttestKey>(
      $appAttestKey,
      columns: [AppAttestKey.t.authUserId],
      transaction: transaction,
    );
  }
}
