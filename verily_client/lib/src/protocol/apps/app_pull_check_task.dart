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
import 'package:serverpod_client/serverpod_client.dart' as _isc;

abstract class AppPullCheckTask
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  AppPullCheckTask._({required this.checkId});

  factory AppPullCheckTask({required _isc.UuidValue checkId}) =
      _AppPullCheckTaskImpl;

  factory AppPullCheckTask.fromJson(Map<String, dynamic> jsonSerialization) {
    return AppPullCheckTask(
      checkId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['checkId'],
      ),
    );
  }

  _isc.UuidValue checkId;

  /// Returns a shallow copy of this [AppPullCheckTask]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  AppPullCheckTask copyWith({_isc.UuidValue? checkId});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AppPullCheckTask',
      'checkId': checkId.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AppPullCheckTask',
      'checkId': checkId.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _AppPullCheckTaskImpl extends AppPullCheckTask {
  _AppPullCheckTaskImpl({required _isc.UuidValue checkId})
    : super._(checkId: checkId);

  /// Returns a shallow copy of this [AppPullCheckTask]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  AppPullCheckTask copyWith({_isc.UuidValue? checkId}) {
    return AppPullCheckTask(checkId: checkId ?? this.checkId);
  }
}
