import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/account/account_access.dart';
import 'package:verily_server/src/action_verification/action_authoring_service.dart';
import 'package:verily_server/src/action_verification/action_key_lock.dart';
import 'package:verily_server/src/action_verification/model_input_security.dart';
import 'package:verily_server/src/apps/api/app_api_action_request.dart';
import 'package:verily_server/src/apps/api/app_api_json.dart';
import 'package:verily_server/src/apps/app_api_auth.dart';
import 'package:verily_server/src/apps/app_confirmation_service.dart';
import 'package:verily_server/src/apps/app_rate_limiter.dart';
import 'package:verily_server/src/apps/webhooks/app_attempt_events.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// Requests per App per [AppApiActionService.rateWindow] across create,
/// publish, and pause.
const appApiActionRateLimit = 60;

/// `POST /api/v1/actions` and `/api/v1/actions/<id>/{publish,pause}`: Apps
/// create and manage actions owned by their creator, through the same
/// validation as the designer in the Verily app. See docs/platform.md.
///
/// One transaction covers each request. It locks the App row (re-checking
/// the key and App are active), takes a rate-limit slot, then the creator's
/// account, then the action key, then hands over to [ActionAuthoringService]
/// in a savepoint. A refused write rolls back to that savepoint while the
/// rate-limit slot stays spent, so invalid requests still count.
///
/// An App only ever touches actions bound to itself: a key its creator
/// already uses for anything else is refused, and publish or pause of an
/// action not bound to the App answers 404, exactly like a missing one.
class AppApiActionService {
  AppApiActionService({
    ActionAuthoringService? authoring,
    AppRateLimiter? rateLimiter,
    DateTime Function()? clock,
    this.rateLimit = appApiActionRateLimit,
    this.rateWindow = const Duration(minutes: 1),
  }) : clock = clock ?? (() => DateTime.now().toUtc()),
       authoring = authoring ?? ActionAuthoringService(clock: clock),
       rateLimiter = rateLimiter ?? const AppRateLimiter();

  final DateTime Function() clock;
  final ActionAuthoringService authoring;
  final AppRateLimiter rateLimiter;
  final int rateLimit;
  final Duration rateWindow;

  Future<AppDeliveryResponse> create(
    Session session, {
    required String? authorization,
    required String? timestamp,
    required String body,
  }) {
    return _authenticated(
      session,
      authorization: authorization,
      timestamp: timestamp,
      (app, transaction) async {
        final AppApiActionRequest request;
        try {
          request = parseAppApiActionRequest(body);
        } on AppApiSchemaException catch (error) {
          return _Done(appApiInvalid(error.code, error.message));
        }
        final creatorId = app.creatorAuthUserId;
        if (!await AccountAccess.isActive(
          session,
          creatorId,
          transaction: transaction,
        )) {
          return const _Done(_creatorInactive);
        }
        await ActionKeyLock.acquire(
          session,
          creatorAuthUserId: creatorId,
          actionKey: request.actionKey,
          transaction: transaction,
        );
        final latest = await ActionDefinition.db.findFirstRow(
          session,
          where: (table) =>
              table.creatorAuthUserId.equals(creatorId) &
              table.actionKey.equals(request.actionKey),
          orderBy: (table) => table.revision.desc(),
          transaction: transaction,
        );
        if (latest != null &&
            !await _boundToApp(session, latest, app, transaction)) {
          return const _Done(
            AppDeliveryResponse(409, {
              'error': 'action_key_taken',
              'message': "The app's creator already uses this action key.",
            }),
          );
        }
        final stored = await _refusable(
          () => authoring.saveActionDraftIn(
            session,
            authUserId: creatorId,
            request: request.toDefinitionRequest(app.id!),
            transaction: transaction,
          ),
        );
        return switch (stored) {
          _Stored(:final action) => _Pending(
            action.id!,
            status: latest == null || action.revision > latest.revision
                ? 201
                : 200,
          ),
          _Refused(:final response) => _Done(response),
        };
      },
    );
  }

  Future<AppDeliveryResponse> publish(
    Session session, {
    required String? authorization,
    required String? timestamp,
    required String actionId,
    required String body,
  }) => _lifecycle(
    session,
    authorization: authorization,
    timestamp: timestamp,
    actionId: actionId,
    body: body,
    publish: true,
  );

  Future<AppDeliveryResponse> pause(
    Session session, {
    required String? authorization,
    required String? timestamp,
    required String actionId,
    required String body,
  }) => _lifecycle(
    session,
    authorization: authorization,
    timestamp: timestamp,
    actionId: actionId,
    body: body,
    publish: false,
  );

  Future<AppDeliveryResponse> _lifecycle(
    Session session, {
    required String? authorization,
    required String? timestamp,
    required String actionId,
    required String body,
    required bool publish,
  }) {
    return _authenticated(
      session,
      authorization: authorization,
      timestamp: timestamp,
      (app, transaction) async {
        final id = _uuidOrNull(actionId);
        if (id == null) return const _Done(appApiNotFound);
        final int expectedRevision;
        try {
          expectedRevision = parseAppApiLifecycleRequest(body);
        } on AppApiSchemaException catch (error) {
          return _Done(appApiInvalid(error.code, error.message));
        }
        final creatorId = app.creatorAuthUserId;
        if (!await AccountAccess.isActive(
          session,
          creatorId,
          transaction: transaction,
        )) {
          return const _Done(_creatorInactive);
        }
        final action = await ActionDefinition.db.findFirstRow(
          session,
          where: (table) =>
              table.id.equals(id) &
              table.creatorAuthUserId.equals(creatorId) &
              table.visibility.equals(ActionVisibility.public),
          transaction: transaction,
        );
        if (action == null ||
            !await _boundToApp(session, action, app, transaction)) {
          return const _Done(appApiNotFound);
        }
        if (action.revision != expectedRevision) {
          return const _Done(
            AppDeliveryResponse(409, {
              'error': 'revision_conflict',
              'message': 'expectedRevision is not the revision of this action.',
            }),
          );
        }
        final conflict = _lifecycleConflict(action, publish: publish);
        if (conflict != null) return _Done(conflict);
        final changed = await _refusable(
          () => authoring.setPublicationIn(
            session,
            authUserId: creatorId,
            actionId: id,
            expectedRevision: expectedRevision,
            publish: publish,
            transaction: transaction,
          ),
        );
        return switch (changed) {
          _Stored(:final action) => _Pending(action.id!, status: 200),
          _Refused(:final response) => _Done(response),
        };
      },
    );
  }

  /// Authenticates, locks the App, takes a rate-limit slot, and runs [body]
  /// in one transaction. A [_Pending] result is rendered as the action view
  /// after commit, so the response always reflects committed state.
  Future<AppDeliveryResponse> _authenticated(
    Session session,
    Future<_Outcome> Function(VerilyApp app, Transaction transaction) body, {
    required String? authorization,
    required String? timestamp,
  }) async {
    final authentication = await authenticateAppRequest(
      session,
      authorization: authorization,
      timestamp: timestamp,
      now: clock().toUtc(),
    );
    final VerilyAppKey key;
    switch (authentication) {
      case AppApiAuthenticated(key: final authenticated):
        key = authenticated;
      case AppApiRefused(:final response):
        return response;
    }
    final outcome = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        final now = clock().toUtc();
        final app = await lockAuthenticatedApp(
          session,
          key: key,
          now: now,
          transaction: transaction,
        );
        if (app == null) return const _Done(appApiUnauthorized);
        final retryAfter = await rateLimiter.consume(
          session,
          appId: app.id!,
          bucket: 'api-actions',
          limit: rateLimit,
          window: rateWindow,
          now: now,
          transaction: transaction,
        );
        if (retryAfter != null) return _Done(appApiRateLimited(retryAfter));
        return body(app, transaction);
      },
    );
    return switch (outcome) {
      _Done(:final response) => response,
      _Pending(:final actionId, :final status) => AppDeliveryResponse(status, {
        'action': await appApiActionJson(session, actionId),
      }),
    };
  }

  /// Runs one authoring write, turning its product-safe refusals into typed
  /// responses. Anything else propagates and rolls the request back.
  Future<_Write> _refusable(Future<ActionDefinition> Function() write) async {
    try {
      return _Stored(await write());
    } on ActionAuthoringException catch (error) {
      return _Refused(
        AppDeliveryResponse(422, {
          'error': _snakeCase(error.reason.name),
          'message': error.message,
        }),
      );
    } on RewardException catch (error) {
      return _Refused(
        AppDeliveryResponse(422, {
          'error': _snakeCase(error.problem.name),
          'message': error.message,
        }),
      );
    } on ModelInputSecurityException {
      return const _Refused(
        AppDeliveryResponse(422, {
          'error': 'unsafe_text',
          'message': 'Some of this text cannot be used. Rephrase it.',
        }),
      );
      // Authoring validation reports with ArgumentError, as for the designer.
      // ignore: avoid_catching_errors
    } on ArgumentError catch (error) {
      final message = error.message;
      return _Refused(
        appApiInvalid(
          'invalid_request',
          message is String && message.isNotEmpty
              ? message
              : 'The action is not valid.',
        ),
      );
      // Business-rule refusals are StateErrors in this codebase.
      // ignore: avoid_catching_errors
    } on StateError {
      return const _Refused(_invalidState);
    }
  }

  /// A clear 409 for a lifecycle change that cannot apply to [action].
  AppDeliveryResponse? _lifecycleConflict(
    ActionDefinition action, {
    required bool publish,
  }) {
    if (publish && action.status == ActionDefinitionStatus.completed) {
      return const AppDeliveryResponse(409, {
        'error': 'revision_completed',
        'message': 'A newer revision replaced this one. Publish that one.',
      });
    }
    if (!publish && action.status != ActionDefinitionStatus.active) {
      return const AppDeliveryResponse(409, {
        'error': 'not_live',
        'message': 'Only a live action can be paused.',
      });
    }
    return null;
  }

  Future<bool> _boundToApp(
    Session session,
    ActionDefinition action,
    VerilyApp app,
    Transaction transaction,
  ) async {
    final bound = await appForAction(
      session,
      actionDefinitionId: action.id!,
      transaction: transaction,
    );
    return bound?.id == app.id;
  }
}

/// The App-facing JSON view of one action and its requirements, read after
/// commit. Only what the App itself declared is returned.
Future<Map<String, Object?>> appApiActionJson(
  Session session,
  UuidValue actionId,
) async {
  final action = await ActionDefinition.db.findById(session, actionId);
  if (action == null) throw StateError('The stored action is missing.');
  final requirements = await ActionRequirement.db.find(
    session,
    where: (table) => table.actionDefinitionId.equals(actionId),
    orderBy: (table) => table.position,
  );
  final rules = requirements.isEmpty
      ? const <ActionExternalRule>[]
      : await ActionExternalRule.db.find(
          session,
          where: (table) => table.requirementId.inSet(<UuidValue>{
            for (final requirement in requirements) requirement.id!,
          }),
        );
  final modeByRequirement = {
    for (final rule in rules) rule.requirementId: rule.verificationMode,
  };
  return {
    'id': action.id.toString(),
    'actionKey': action.actionKey,
    'revision': action.revision,
    'status': action.status.name,
    'title': action.title,
    'recurrence': action.recurrence.name,
    'timeZone': action.timeZone,
    'maxVerifiedCompletions': action.maxVerifiedCompletions,
    'opensAt': action.opensAt?.toUtc().toIso8601String(),
    'closesAt': action.closesAt?.toUtc().toIso8601String(),
    'publishedAt': action.publishedAt?.toUtc().toIso8601String(),
    'requirements': [
      for (final requirement in requirements)
        {
          'id': requirement.id.toString(),
          'requirementKey': requirement.requirementKey,
          'verification':
              (modeByRequirement[requirement.id] ?? AppVerificationMode.push)
                  .name,
        },
    ],
  };
}

UuidValue? _uuidOrNull(String value) {
  try {
    return UuidValue.withValidation(value);
  } on FormatException {
    return null;
  }
}

String _snakeCase(String name) => name.replaceAllMapped(
  RegExp('[A-Z]'),
  (match) => '_${match[0]!.toLowerCase()}',
);

const _creatorInactive = AppDeliveryResponse(403, {
  'error': 'creator_inactive',
  'message': "The app's creator account is not active.",
});

const _invalidState = AppDeliveryResponse(409, {
  'error': 'invalid_state',
  'message': 'The action cannot change to that state right now.',
});

/// What a request transaction decided.
sealed class _Outcome {
  const _Outcome();
}

/// A finished response, committed as is.
final class _Done extends _Outcome {
  const _Done(this.response);

  final AppDeliveryResponse response;
}

/// A successful write, rendered from committed state after the transaction.
final class _Pending extends _Outcome {
  const _Pending(this.actionId, {required this.status});

  final UuidValue actionId;
  final int status;
}

sealed class _Write {
  const _Write();
}

final class _Stored extends _Write {
  const _Stored(this.action);

  final ActionDefinition action;
}

final class _Refused extends _Write {
  const _Refused(this.response);

  final AppDeliveryResponse response;
}
