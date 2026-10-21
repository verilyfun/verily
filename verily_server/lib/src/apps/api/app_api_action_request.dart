import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/apps/api/app_api_json.dart';
import 'package:verily_server/src/generated/protocol.dart';

final RegExp _slugPattern = RegExp(r'^[a-z0-9][a-z0-9-]{1,62}[a-z0-9]$');

/// One `externalApp` requirement an App declares for its own action. The App
/// never names an app id: the requirement is bound to the calling App.
final class AppApiRequirement {
  const AppApiRequirement({
    required this.requirementKey,
    required this.title,
    required this.instructions,
    required this.isRequired,
    required this.verification,
  });

  final String requirementKey;
  final String title;
  final String instructions;
  final bool isRequired;
  final AppVerificationMode verification;
}

/// A validated `POST /api/v1/actions` body.
///
/// ```json
/// {"actionKey": "daily-situps", "title": "…", "description": "…",
///  "recurrence": "once" | "daily", "timeZone": "Europe/London",
///  "maxVerifiedCompletions": 100, "opensAt": "…", "closesAt": "…",
///  "requirements": [{"requirementKey": "situps", "title": "…",
///    "instructions": "…", "isRequired": true, "verification": "push" | "pull"}]}
/// ```
///
/// `maxVerifiedCompletions`, `opensAt`, `closesAt`, `isRequired` (default
/// true), and `verification` (default `push`) are optional. An action takes
/// exactly one requirement in v1, because each App confirms at most one
/// proof per action. Rewards are attached in the Verily app, never here.
final class AppApiActionRequest {
  const AppApiActionRequest({
    required this.actionKey,
    required this.title,
    required this.description,
    required this.recurrence,
    required this.timeZone,
    required this.maxVerifiedCompletions,
    required this.opensAt,
    required this.closesAt,
    required this.requirements,
  });

  final String actionKey;
  final String title;
  final String description;
  final ActionRecurrence recurrence;
  final String timeZone;
  final int? maxVerifiedCompletions;
  final DateTime? opensAt;
  final DateTime? closesAt;
  final List<AppApiRequirement> requirements;

  /// The designer's request for the same action, bound to [appId].
  CreateActionDefinitionRequest toDefinitionRequest(UuidValue appId) =>
      CreateActionDefinitionRequest(
        actionKey: actionKey,
        title: title,
        description: description,
        recurrence: recurrence,
        timeZone: timeZone,
        maxVerifiedCompletions: maxVerifiedCompletions,
        opensAt: opensAt,
        closesAt: closesAt,
        requirements: [
          for (final requirement in requirements)
            ActionRequirementDraft(
              requirementKey: requirement.requirementKey,
              kind: ActionRequirementKind.externalApp,
              title: requirement.title,
              instructions: requirement.instructions,
              isRequired: requirement.isRequired,
              appId: appId,
              appVerificationMode: requirement.verification,
            ),
        ],
      );
}

/// Parses an action body strictly. Throws [AppApiSchemaException].
AppApiActionRequest parseAppApiActionRequest(String body) {
  final json = StrictJsonObject.parse(
    body,
    allowed: const {
      'actionKey',
      'title',
      'description',
      'recurrence',
      'timeZone',
      'maxVerifiedCompletions',
      'opensAt',
      'closesAt',
      'requirements',
    },
  );
  final requirements = json.list('requirements', minLength: 1, maxLength: 1);
  return AppApiActionRequest(
    actionKey: json.string('actionKey', maxLength: 64, pattern: _slugPattern),
    title: json.string('title', maxLength: 120),
    description: json.string('description', maxLength: 1000),
    recurrence: ActionRecurrence.fromJson(
      json.choice('recurrence', const {'once', 'daily'}),
    ),
    timeZone: json.string('timeZone', maxLength: 64),
    maxVerifiedCompletions: json.optionalInteger(
      'maxVerifiedCompletions',
      min: 1,
      max: 1000000,
    ),
    opensAt: json.optionalDateTime('opensAt'),
    closesAt: json.optionalDateTime('closesAt'),
    requirements: [
      for (var index = 0; index < requirements.length; index += 1)
        _requirement(
          StrictJsonObject.of(
            requirements[index],
            allowed: const {
              'requirementKey',
              'title',
              'instructions',
              'isRequired',
              'verification',
            },
            path: 'requirements[$index].',
          ),
        ),
    ],
  );
}

AppApiRequirement _requirement(StrictJsonObject json) => AppApiRequirement(
  requirementKey: json.string(
    'requirementKey',
    maxLength: 64,
    pattern: _slugPattern,
  ),
  title: json.string('title', maxLength: 120),
  instructions: json.string('instructions', maxLength: 1000),
  isRequired: json.optionalBoolean('isRequired') ?? true,
  verification: AppVerificationMode.fromJson(
    json.optionalChoice('verification', const {'push', 'pull'}) ?? 'push',
  ),
);

/// Parses `{"expectedRevision": n}` for publish and pause.
int parseAppApiLifecycleRequest(String body) {
  final json = StrictJsonObject.parse(
    body,
    allowed: const {'expectedRevision'},
  );
  return json.integer('expectedRevision', min: 1, max: 1 << 31);
}
