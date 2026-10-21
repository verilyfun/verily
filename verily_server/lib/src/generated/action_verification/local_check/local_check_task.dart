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

/// A simple on-device check, replayed on the server with the same pinned
/// MediaPipe model (`verifierType = mp-replay`).
enum LocalCheckTask implements _is.SerializableModel {
  /// MediaPipe gesture recognizer: a canned hand gesture in a photo or video.
  gesture,

  /// MediaPipe object detector: a COCO object in a photo or video.
  object,

  /// MediaPipe audio classifier (YAMNet): a sound in a recording.
  sound;

  static LocalCheckTask fromJson(String name) {
    switch (name) {
      case 'gesture':
        return LocalCheckTask.gesture;
      case 'object':
        return LocalCheckTask.object;
      case 'sound':
        return LocalCheckTask.sound;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "LocalCheckTask"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
