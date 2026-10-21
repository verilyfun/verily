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

/// The pinned model the phone must download and verify before running a local
/// check. The server replays exactly this model.
abstract class LocalCheckModelView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  LocalCheckModelView._({
    required this.modelId,
    required this.url,
    required this.byteLength,
    required this.sha256,
  });

  factory LocalCheckModelView({
    required String modelId,
    required String url,
    required int byteLength,
    required String sha256,
  }) = _LocalCheckModelViewImpl;

  factory LocalCheckModelView.fromJson(Map<String, dynamic> jsonSerialization) {
    return LocalCheckModelView(
      modelId: jsonSerialization['modelId'] as String,
      url: jsonSerialization['url'] as String,
      byteLength: jsonSerialization['byteLength'] as int,
      sha256: jsonSerialization['sha256'] as String,
    );
  }

  String modelId;

  String url;

  int byteLength;

  String sha256;

  /// Returns a shallow copy of this [LocalCheckModelView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  LocalCheckModelView copyWith({
    String? modelId,
    String? url,
    int? byteLength,
    String? sha256,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LocalCheckModelView',
      'modelId': modelId,
      'url': url,
      'byteLength': byteLength,
      'sha256': sha256,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LocalCheckModelView',
      'modelId': modelId,
      'url': url,
      'byteLength': byteLength,
      'sha256': sha256,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _LocalCheckModelViewImpl extends LocalCheckModelView {
  _LocalCheckModelViewImpl({
    required String modelId,
    required String url,
    required int byteLength,
    required String sha256,
  }) : super._(
         modelId: modelId,
         url: url,
         byteLength: byteLength,
         sha256: sha256,
       );

  /// Returns a shallow copy of this [LocalCheckModelView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  LocalCheckModelView copyWith({
    String? modelId,
    String? url,
    int? byteLength,
    String? sha256,
  }) {
    return LocalCheckModelView(
      modelId: modelId ?? this.modelId,
      url: url ?? this.url,
      byteLength: byteLength ?? this.byteLength,
      sha256: sha256 ?? this.sha256,
    );
  }
}
