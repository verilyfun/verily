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

/// A body or ball movement the app coaches live and verifiers count from video.
enum ActionMovementKind implements _is.SerializableModel {
  squats,
  pressUps,
  sitUps,
  lunges,
  starJumps,
  burpees,
  highKnees,
  lateralRaises,
  bicepsCurls,
  sideBends,
  footballKickUps,
  tableTennisBounces;

  static ActionMovementKind fromJson(String name) {
    switch (name) {
      case 'squats':
        return ActionMovementKind.squats;
      case 'pressUps':
        return ActionMovementKind.pressUps;
      case 'sitUps':
        return ActionMovementKind.sitUps;
      case 'lunges':
        return ActionMovementKind.lunges;
      case 'starJumps':
        return ActionMovementKind.starJumps;
      case 'burpees':
        return ActionMovementKind.burpees;
      case 'highKnees':
        return ActionMovementKind.highKnees;
      case 'lateralRaises':
        return ActionMovementKind.lateralRaises;
      case 'bicepsCurls':
        return ActionMovementKind.bicepsCurls;
      case 'sideBends':
        return ActionMovementKind.sideBends;
      case 'footballKickUps':
        return ActionMovementKind.footballKickUps;
      case 'tableTennisBounces':
        return ActionMovementKind.tableTennisBounces;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "ActionMovementKind"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
