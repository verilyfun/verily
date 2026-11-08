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

import '../rewards/reward_cluster.dart' as _ifrvw135;
import '../rewards/reward_pool_status.dart' as _i2n7u226;

/// One escrowed reward per creator and action key, spanning revisions. The
/// id is the on-chain pool id. Terms are immutable once funding starts, and
/// funding is verified from chain state, never from the client.
abstract class RewardPool
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  RewardPool._({
    this.id,
    required this.creatorAuthUserId,
    this.creatorAuthUser,
    required this.actionKey,
    required this.cluster,
    required this.mint,
    required this.tokenSymbol,
    required this.decimals,
    required this.amountPerPayout,
    required this.maxPayouts,
    int? maxWinsPerAccount,
    int? payoutsReserved,
    int? payoutsReleased,
    this.creatorWallet,
    this.escrowAddress,
    this.arbiterAddress,
    required this.expiresAt,
    required this.refundDelaySeconds,
    required this.refundAfter,
    required this.status,
    this.fundingSignature,
    this.fundedAt,
    this.endedAt,
    this.closedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : maxWinsPerAccount = maxWinsPerAccount ?? 1,
       payoutsReserved = payoutsReserved ?? 0,
       payoutsReleased = payoutsReleased ?? 0,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory RewardPool({
    _is.UuidValue? id,
    required _is.UuidValue creatorAuthUserId,
    _iacs.AuthUser? creatorAuthUser,
    required String actionKey,
    required _ifrvw135.RewardCluster cluster,
    required String mint,
    required String tokenSymbol,
    required int decimals,
    required int amountPerPayout,
    required int maxPayouts,
    int? maxWinsPerAccount,
    int? payoutsReserved,
    int? payoutsReleased,
    String? creatorWallet,
    String? escrowAddress,
    String? arbiterAddress,
    required DateTime expiresAt,
    required int refundDelaySeconds,
    required DateTime refundAfter,
    required _i2n7u226.RewardPoolStatus status,
    String? fundingSignature,
    DateTime? fundedAt,
    DateTime? endedAt,
    DateTime? closedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _RewardPoolImpl;

  factory RewardPool.fromJson(Map<String, dynamic> jsonSerialization) {
    return RewardPool(
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
      cluster: _ifrvw135.RewardCluster.fromJson(
        (jsonSerialization['cluster'] as String),
      ),
      mint: jsonSerialization['mint'] as String,
      tokenSymbol: jsonSerialization['tokenSymbol'] as String,
      decimals: jsonSerialization['decimals'] as int,
      amountPerPayout: jsonSerialization['amountPerPayout'] as int,
      maxPayouts: jsonSerialization['maxPayouts'] as int,
      maxWinsPerAccount: jsonSerialization['maxWinsPerAccount'] as int?,
      payoutsReserved: jsonSerialization['payoutsReserved'] as int?,
      payoutsReleased: jsonSerialization['payoutsReleased'] as int?,
      creatorWallet: jsonSerialization['creatorWallet'] as String?,
      escrowAddress: jsonSerialization['escrowAddress'] as String?,
      arbiterAddress: jsonSerialization['arbiterAddress'] as String?,
      expiresAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      refundDelaySeconds: jsonSerialization['refundDelaySeconds'] as int,
      refundAfter: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['refundAfter'],
      ),
      status: _i2n7u226.RewardPoolStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      fundingSignature: jsonSerialization['fundingSignature'] as String?,
      fundedAt: jsonSerialization['fundedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['fundedAt']),
      endedAt: jsonSerialization['endedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['endedAt']),
      closedAt: jsonSerialization['closedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['closedAt']),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  static final t = RewardPoolTable();

  static const db = RewardPoolRepository._();

  @override
  _is.UuidValue? id;

  _is.UuidValue creatorAuthUserId;

  _iacs.AuthUser? creatorAuthUser;

  String actionKey;

  _ifrvw135.RewardCluster cluster;

  String mint;

  String tokenSymbol;

  int decimals;

  /// Token atoms per verified completion.
  int amountPerPayout;

  int maxPayouts;

  int maxWinsPerAccount;

  int payoutsReserved;

  int payoutsReleased;

  /// Frozen when funding starts; refunds return here.
  String? creatorWallet;

  String? escrowAddress;

  String? arbiterAddress;

  DateTime expiresAt;

  int refundDelaySeconds;

  /// expiresAt + refundDelaySeconds; moves earlier when the creator ends early.
  DateTime refundAfter;

  _i2n7u226.RewardPoolStatus status;

  String? fundingSignature;

  DateTime? fundedAt;

  DateTime? endedAt;

  DateTime? closedAt;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [RewardPool]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  RewardPool copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? creatorAuthUserId,
    _iacs.AuthUser? creatorAuthUser =
        const _UndefinedRewardPool$creatorAuthUser(),
    String? actionKey,
    _ifrvw135.RewardCluster? cluster,
    String? mint,
    String? tokenSymbol,
    int? decimals,
    int? amountPerPayout,
    int? maxPayouts,
    int? maxWinsPerAccount,
    int? payoutsReserved,
    int? payoutsReleased,
    String? creatorWallet,
    String? escrowAddress,
    String? arbiterAddress,
    DateTime? expiresAt,
    int? refundDelaySeconds,
    DateTime? refundAfter,
    _i2n7u226.RewardPoolStatus? status,
    String? fundingSignature,
    DateTime? fundedAt = const _is.$UndefinedDateTime(),
    DateTime? endedAt = const _is.$UndefinedDateTime(),
    DateTime? closedAt = const _is.$UndefinedDateTime(),
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RewardPool',
      if (id != null) 'id': id?.toJson(),
      'creatorAuthUserId': creatorAuthUserId.toJson(),
      if (creatorAuthUser != null) 'creatorAuthUser': creatorAuthUser?.toJson(),
      'actionKey': actionKey,
      'cluster': cluster.toJson(),
      'mint': mint,
      'tokenSymbol': tokenSymbol,
      'decimals': decimals,
      'amountPerPayout': amountPerPayout,
      'maxPayouts': maxPayouts,
      'maxWinsPerAccount': maxWinsPerAccount,
      'payoutsReserved': payoutsReserved,
      'payoutsReleased': payoutsReleased,
      if (creatorWallet != null) 'creatorWallet': creatorWallet,
      if (escrowAddress != null) 'escrowAddress': escrowAddress,
      if (arbiterAddress != null) 'arbiterAddress': arbiterAddress,
      'expiresAt': expiresAt.toJson(),
      'refundDelaySeconds': refundDelaySeconds,
      'refundAfter': refundAfter.toJson(),
      'status': status.toJson(),
      if (fundingSignature != null) 'fundingSignature': fundingSignature,
      if (fundedAt != null) 'fundedAt': fundedAt?.toJson(),
      if (endedAt != null) 'endedAt': endedAt?.toJson(),
      if (closedAt != null) 'closedAt': closedAt?.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static RewardPoolInclude include({_iacs.AuthUserInclude? creatorAuthUser}) {
    return RewardPoolInclude._(creatorAuthUser: creatorAuthUser);
  }

  static RewardPoolIncludeList includeList({
    _is.WhereExpressionBuilder<RewardPoolTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RewardPoolTable>? orderBy,
    _is.OrderByListBuilder<RewardPoolTable>? orderByList,
    RewardPoolInclude? include,
  }) {
    return RewardPoolIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(RewardPool.t),
      orderByList: orderByList?.call(RewardPool.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedRewardPool$creatorAuthUser extends _is.UndefinedSentinel
    implements _iacs.AuthUser {
  const _UndefinedRewardPool$creatorAuthUser();
}

class _RewardPoolImpl extends RewardPool {
  _RewardPoolImpl({
    _is.UuidValue? id,
    required _is.UuidValue creatorAuthUserId,
    _iacs.AuthUser? creatorAuthUser,
    required String actionKey,
    required _ifrvw135.RewardCluster cluster,
    required String mint,
    required String tokenSymbol,
    required int decimals,
    required int amountPerPayout,
    required int maxPayouts,
    int? maxWinsPerAccount,
    int? payoutsReserved,
    int? payoutsReleased,
    String? creatorWallet,
    String? escrowAddress,
    String? arbiterAddress,
    required DateTime expiresAt,
    required int refundDelaySeconds,
    required DateTime refundAfter,
    required _i2n7u226.RewardPoolStatus status,
    String? fundingSignature,
    DateTime? fundedAt,
    DateTime? endedAt,
    DateTime? closedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         creatorAuthUserId: creatorAuthUserId,
         creatorAuthUser: creatorAuthUser,
         actionKey: actionKey,
         cluster: cluster,
         mint: mint,
         tokenSymbol: tokenSymbol,
         decimals: decimals,
         amountPerPayout: amountPerPayout,
         maxPayouts: maxPayouts,
         maxWinsPerAccount: maxWinsPerAccount,
         payoutsReserved: payoutsReserved,
         payoutsReleased: payoutsReleased,
         creatorWallet: creatorWallet,
         escrowAddress: escrowAddress,
         arbiterAddress: arbiterAddress,
         expiresAt: expiresAt,
         refundDelaySeconds: refundDelaySeconds,
         refundAfter: refundAfter,
         status: status,
         fundingSignature: fundingSignature,
         fundedAt: fundedAt,
         endedAt: endedAt,
         closedAt: closedAt,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [RewardPool]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  RewardPool copyWith({
    _is.UuidValue? id = const _is.$UndefinedUuidValue(),
    _is.UuidValue? creatorAuthUserId,
    _iacs.AuthUser? creatorAuthUser =
        const _UndefinedRewardPool$creatorAuthUser(),
    String? actionKey,
    _ifrvw135.RewardCluster? cluster,
    String? mint,
    String? tokenSymbol,
    int? decimals,
    int? amountPerPayout,
    int? maxPayouts,
    int? maxWinsPerAccount,
    int? payoutsReserved,
    int? payoutsReleased,
    Object? creatorWallet = _Undefined,
    Object? escrowAddress = _Undefined,
    Object? arbiterAddress = _Undefined,
    DateTime? expiresAt,
    int? refundDelaySeconds,
    DateTime? refundAfter,
    _i2n7u226.RewardPoolStatus? status,
    Object? fundingSignature = _Undefined,
    DateTime? fundedAt = const _is.$UndefinedDateTime(),
    DateTime? endedAt = const _is.$UndefinedDateTime(),
    DateTime? closedAt = const _is.$UndefinedDateTime(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RewardPool(
      id: id is _is.UndefinedSentinel ? this.id : id,
      creatorAuthUserId: creatorAuthUserId ?? this.creatorAuthUserId,
      creatorAuthUser: creatorAuthUser is _is.UndefinedSentinel
          ? this.creatorAuthUser?.copyWith()
          : creatorAuthUser,
      actionKey: actionKey ?? this.actionKey,
      cluster: cluster ?? this.cluster,
      mint: mint ?? this.mint,
      tokenSymbol: tokenSymbol ?? this.tokenSymbol,
      decimals: decimals ?? this.decimals,
      amountPerPayout: amountPerPayout ?? this.amountPerPayout,
      maxPayouts: maxPayouts ?? this.maxPayouts,
      maxWinsPerAccount: maxWinsPerAccount ?? this.maxWinsPerAccount,
      payoutsReserved: payoutsReserved ?? this.payoutsReserved,
      payoutsReleased: payoutsReleased ?? this.payoutsReleased,
      creatorWallet: creatorWallet is String?
          ? creatorWallet
          : this.creatorWallet,
      escrowAddress: escrowAddress is String?
          ? escrowAddress
          : this.escrowAddress,
      arbiterAddress: arbiterAddress is String?
          ? arbiterAddress
          : this.arbiterAddress,
      expiresAt: expiresAt ?? this.expiresAt,
      refundDelaySeconds: refundDelaySeconds ?? this.refundDelaySeconds,
      refundAfter: refundAfter ?? this.refundAfter,
      status: status ?? this.status,
      fundingSignature: fundingSignature is String?
          ? fundingSignature
          : this.fundingSignature,
      fundedAt: fundedAt is _is.UndefinedSentinel ? this.fundedAt : fundedAt,
      endedAt: endedAt is _is.UndefinedSentinel ? this.endedAt : endedAt,
      closedAt: closedAt is _is.UndefinedSentinel ? this.closedAt : closedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class RewardPoolUpdateTable extends _is.UpdateTable<RewardPoolTable> {
  RewardPoolUpdateTable(super.table);

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

  _is.ColumnValue<_ifrvw135.RewardCluster, _ifrvw135.RewardCluster> cluster(
    _ifrvw135.RewardCluster value,
  ) => _is.ColumnValue(
    table.cluster,
    value,
  );

  _is.ColumnValue<String, String> mint(String value) => _is.ColumnValue(
    table.mint,
    value,
  );

  _is.ColumnValue<String, String> tokenSymbol(String value) => _is.ColumnValue(
    table.tokenSymbol,
    value,
  );

  _is.ColumnValue<int, int> decimals(int value) => _is.ColumnValue(
    table.decimals,
    value,
  );

  _is.ColumnValue<int, int> amountPerPayout(int value) => _is.ColumnValue(
    table.amountPerPayout,
    value,
  );

  _is.ColumnValue<int, int> maxPayouts(int value) => _is.ColumnValue(
    table.maxPayouts,
    value,
  );

  _is.ColumnValue<int, int> maxWinsPerAccount(int value) => _is.ColumnValue(
    table.maxWinsPerAccount,
    value,
  );

  _is.ColumnValue<int, int> payoutsReserved(int value) => _is.ColumnValue(
    table.payoutsReserved,
    value,
  );

  _is.ColumnValue<int, int> payoutsReleased(int value) => _is.ColumnValue(
    table.payoutsReleased,
    value,
  );

  _is.ColumnValue<String, String> creatorWallet(String? value) =>
      _is.ColumnValue(
        table.creatorWallet,
        value,
      );

  _is.ColumnValue<String, String> escrowAddress(String? value) =>
      _is.ColumnValue(
        table.escrowAddress,
        value,
      );

  _is.ColumnValue<String, String> arbiterAddress(String? value) =>
      _is.ColumnValue(
        table.arbiterAddress,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> expiresAt(DateTime value) =>
      _is.ColumnValue(
        table.expiresAt,
        value,
      );

  _is.ColumnValue<int, int> refundDelaySeconds(int value) => _is.ColumnValue(
    table.refundDelaySeconds,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> refundAfter(DateTime value) =>
      _is.ColumnValue(
        table.refundAfter,
        value,
      );

  _is.ColumnValue<_i2n7u226.RewardPoolStatus, _i2n7u226.RewardPoolStatus>
  status(_i2n7u226.RewardPoolStatus value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<String, String> fundingSignature(String? value) =>
      _is.ColumnValue(
        table.fundingSignature,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> fundedAt(DateTime? value) =>
      _is.ColumnValue(
        table.fundedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> endedAt(DateTime? value) =>
      _is.ColumnValue(
        table.endedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> closedAt(DateTime? value) =>
      _is.ColumnValue(
        table.closedAt,
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

class RewardPoolTable extends _is.Table<_is.UuidValue?> {
  RewardPoolTable({super.tableRelation})
    : super(tableName: 'verily_reward_pool') {
    updateTable = RewardPoolUpdateTable(this);
    creatorAuthUserId = _is.ColumnUuid(
      'creatorAuthUserId',
      this,
    );
    actionKey = _is.ColumnString(
      'actionKey',
      this,
    );
    cluster = _is.ColumnEnum(
      'cluster',
      this,
      _is.EnumSerialization.byName,
    );
    mint = _is.ColumnString(
      'mint',
      this,
    );
    tokenSymbol = _is.ColumnString(
      'tokenSymbol',
      this,
    );
    decimals = _is.ColumnInt(
      'decimals',
      this,
    );
    amountPerPayout = _is.ColumnInt(
      'amountPerPayout',
      this,
    );
    maxPayouts = _is.ColumnInt(
      'maxPayouts',
      this,
    );
    maxWinsPerAccount = _is.ColumnInt(
      'maxWinsPerAccount',
      this,
      hasDefault: true,
    );
    payoutsReserved = _is.ColumnInt(
      'payoutsReserved',
      this,
      hasDefault: true,
    );
    payoutsReleased = _is.ColumnInt(
      'payoutsReleased',
      this,
      hasDefault: true,
    );
    creatorWallet = _is.ColumnString(
      'creatorWallet',
      this,
    );
    escrowAddress = _is.ColumnString(
      'escrowAddress',
      this,
    );
    arbiterAddress = _is.ColumnString(
      'arbiterAddress',
      this,
    );
    expiresAt = _is.ColumnDateTime(
      'expiresAt',
      this,
    );
    refundDelaySeconds = _is.ColumnInt(
      'refundDelaySeconds',
      this,
    );
    refundAfter = _is.ColumnDateTime(
      'refundAfter',
      this,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
    );
    fundingSignature = _is.ColumnString(
      'fundingSignature',
      this,
    );
    fundedAt = _is.ColumnDateTime(
      'fundedAt',
      this,
    );
    endedAt = _is.ColumnDateTime(
      'endedAt',
      this,
    );
    closedAt = _is.ColumnDateTime(
      'closedAt',
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
  }

  late final RewardPoolUpdateTable updateTable;

  late final _is.ColumnUuid creatorAuthUserId;

  _iacs.AuthUserTable? _creatorAuthUser;

  late final _is.ColumnString actionKey;

  late final _is.ColumnEnum<_ifrvw135.RewardCluster> cluster;

  late final _is.ColumnString mint;

  late final _is.ColumnString tokenSymbol;

  late final _is.ColumnInt decimals;

  /// Token atoms per verified completion.
  late final _is.ColumnInt amountPerPayout;

  late final _is.ColumnInt maxPayouts;

  late final _is.ColumnInt maxWinsPerAccount;

  late final _is.ColumnInt payoutsReserved;

  late final _is.ColumnInt payoutsReleased;

  /// Frozen when funding starts; refunds return here.
  late final _is.ColumnString creatorWallet;

  late final _is.ColumnString escrowAddress;

  late final _is.ColumnString arbiterAddress;

  late final _is.ColumnDateTime expiresAt;

  late final _is.ColumnInt refundDelaySeconds;

  /// expiresAt + refundDelaySeconds; moves earlier when the creator ends early.
  late final _is.ColumnDateTime refundAfter;

  late final _is.ColumnEnum<_i2n7u226.RewardPoolStatus> status;

  late final _is.ColumnString fundingSignature;

  late final _is.ColumnDateTime fundedAt;

  late final _is.ColumnDateTime endedAt;

  late final _is.ColumnDateTime closedAt;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  _iacs.AuthUserTable get creatorAuthUser {
    if (_creatorAuthUser != null) return _creatorAuthUser!;
    _creatorAuthUser = _is.createRelationTable(
      relationFieldName: 'creatorAuthUser',
      field: RewardPool.t.creatorAuthUserId,
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
    cluster,
    mint,
    tokenSymbol,
    decimals,
    amountPerPayout,
    maxPayouts,
    maxWinsPerAccount,
    payoutsReserved,
    payoutsReleased,
    creatorWallet,
    escrowAddress,
    arbiterAddress,
    expiresAt,
    refundDelaySeconds,
    refundAfter,
    status,
    fundingSignature,
    fundedAt,
    endedAt,
    closedAt,
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

class RewardPoolInclude extends _is.IncludeObject {
  RewardPoolInclude._({_iacs.AuthUserInclude? creatorAuthUser}) {
    _creatorAuthUser = creatorAuthUser;
  }

  _iacs.AuthUserInclude? _creatorAuthUser;

  @override
  Map<String, _is.Include?> get includes => {
    'creatorAuthUser': _creatorAuthUser,
  };

  @override
  _is.Table<_is.UuidValue?> get table => RewardPool.t;
}

class RewardPoolIncludeList extends _is.IncludeList {
  RewardPoolIncludeList._({
    _is.WhereExpressionBuilder<RewardPoolTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(RewardPool.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => RewardPool.t;
}

class RewardPoolRepository {
  const RewardPoolRepository._();

  final attachRow = const RewardPoolAttachRowRepository._();

  /// Returns a list of [RewardPool]s matching the given query parameters.
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
  Future<List<RewardPool>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RewardPoolTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RewardPoolTable>? orderBy,
    _is.OrderByListBuilder<RewardPoolTable>? orderByList,
    _is.Transaction? transaction,
    RewardPoolInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<RewardPool>(
      where: where?.call(RewardPool.t),
      orderBy: orderBy?.call(RewardPool.t),
      orderByList: orderByList?.call(RewardPool.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [RewardPool]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `RewardPool.t`.
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
  _ida.Stream<List<RewardPool>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RewardPoolTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RewardPoolTable>? orderBy,
    _is.OrderByListBuilder<RewardPoolTable>? orderByList,
    RewardPoolInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<RewardPool>(
      where: where?.call(RewardPool.t),
      orderBy: orderBy?.call(RewardPool.t),
      orderByList: orderByList?.call(RewardPool.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [RewardPool] matching the given query parameters.
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
  Future<RewardPool?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RewardPoolTable>? where,
    int? offset,
    _is.OrderByBuilder<RewardPoolTable>? orderBy,
    _is.OrderByListBuilder<RewardPoolTable>? orderByList,
    _is.Transaction? transaction,
    RewardPoolInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<RewardPool>(
      where: where?.call(RewardPool.t),
      orderBy: orderBy?.call(RewardPool.t),
      orderByList: orderByList?.call(RewardPool.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [RewardPool] by its [id] or null if no such row exists.
  Future<RewardPool?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    RewardPoolInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<RewardPool>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [RewardPool]s in the list and returns the inserted rows.
  ///
  /// The returned [RewardPool]s will have their `id` fields set.
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
  Future<List<RewardPool>> insert(
    _is.DatabaseSession session,
    List<RewardPool> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<RewardPool>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [RewardPool] and returns the inserted row.
  ///
  /// The returned [RewardPool] will have its `id` field set.
  Future<RewardPool> insertRow(
    _is.DatabaseSession session,
    RewardPool row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<RewardPool>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [RewardPool]s in the list and returns the resulting rows.
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
  /// The returned [RewardPool]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<RewardPool>> upsert(
    _is.DatabaseSession session,
    List<RewardPool> rows, {
    required _is.ColumnSelections<RewardPoolTable> conflictColumns,
    _is.ColumnSelections<RewardPoolTable>? updateColumns,
    _is.WhereExpressionBuilder<RewardPoolTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<RewardPool>(
      rows,
      conflictColumns: conflictColumns(RewardPool.t),
      updateColumns: updateColumns?.call(RewardPool.t),
      updateWhere: updateWhere?.call(RewardPool.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [RewardPool] and returns the resulting row.
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
  /// The returned [RewardPool] will have its `id` field set.
  Future<RewardPool?> upsertRow(
    _is.DatabaseSession session,
    RewardPool row, {
    required _is.ColumnSelections<RewardPoolTable> conflictColumns,
    _is.ColumnSelections<RewardPoolTable>? updateColumns,
    _is.WhereExpressionBuilder<RewardPoolTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<RewardPool>(
      row,
      conflictColumns: conflictColumns(RewardPool.t),
      updateColumns: updateColumns?.call(RewardPool.t),
      updateWhere: updateWhere?.call(RewardPool.t),
      transaction: transaction,
    );
  }

  /// Updates all [RewardPool]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<RewardPool>> update(
    _is.DatabaseSession session,
    List<RewardPool> rows, {
    _is.ColumnSelections<RewardPoolTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<RewardPool>(
      rows,
      columns: columns?.call(RewardPool.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [RewardPool]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<RewardPool> updateRow(
    _is.DatabaseSession session,
    RewardPool row, {
    _is.ColumnSelections<RewardPoolTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<RewardPool>(
      row,
      columns: columns?.call(RewardPool.t),
      transaction: transaction,
    );
  }

  /// Updates a single [RewardPool] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<RewardPool?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<RewardPoolUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<RewardPool>(
      id,
      columnValues: columnValues(RewardPool.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [RewardPool]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<RewardPool>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<RewardPoolUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<RewardPoolTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RewardPoolTable>? orderBy,
    _is.OrderByListBuilder<RewardPoolTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<RewardPool>(
      columnValues: columnValues(RewardPool.t.updateTable),
      where: where(RewardPool.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(RewardPool.t),
      orderByList: orderByList?.call(RewardPool.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [RewardPool]s in the list and returns the deleted rows.
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
  Future<List<RewardPool>> delete(
    _is.DatabaseSession session,
    List<RewardPool> rows, {
    _is.OrderByBuilder<RewardPoolTable>? orderBy,
    _is.OrderByListBuilder<RewardPoolTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<RewardPool>(
      rows,
      orderBy: orderBy?.call(RewardPool.t),
      orderByList: orderByList?.call(RewardPool.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [RewardPool].
  Future<RewardPool> deleteRow(
    _is.DatabaseSession session,
    RewardPool row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<RewardPool>(
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
  Future<List<RewardPool>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<RewardPoolTable> where,
    _is.OrderByBuilder<RewardPoolTable>? orderBy,
    _is.OrderByListBuilder<RewardPoolTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<RewardPool>(
      where: where(RewardPool.t),
      orderBy: orderBy?.call(RewardPool.t),
      orderByList: orderByList?.call(RewardPool.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RewardPoolTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<RewardPool>(
      where: where?.call(RewardPool.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [RewardPool] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<RewardPoolTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<RewardPool>(
      where: where(RewardPool.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class RewardPoolAttachRowRepository {
  const RewardPoolAttachRowRepository._();

  /// Creates a relation between the given [RewardPool] and [AuthUser]
  /// by setting the [RewardPool]'s foreign key `creatorAuthUserId` to refer to the [AuthUser].
  Future<void> creatorAuthUser(
    _is.DatabaseSession session,
    RewardPool rewardPool,
    _iacs.AuthUser creatorAuthUser, {
    _is.Transaction? transaction,
  }) async {
    if (rewardPool.id == null) {
      throw ArgumentError.notNull('rewardPool.id');
    }
    if (creatorAuthUser.id == null) {
      throw ArgumentError.notNull('creatorAuthUser.id');
    }

    var $rewardPool = rewardPool.copyWith(
      creatorAuthUserId: creatorAuthUser.id,
    );
    await session.db.updateRow<RewardPool>(
      $rewardPool,
      columns: [RewardPool.t.creatorAuthUserId],
      transaction: transaction,
    );
  }
}
