import 'dart:convert';
import 'dart:math';

import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/account/account_access.dart';
import 'package:verily_server/src/apps/app_credentials.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// Creator management of Verily Apps and participant linking.
///
/// Every creator operation re-derives ownership from the authenticated
/// account; an App id alone never grants access. Operations on one App lock
/// its row before the creator's account row, matching the confirmation
/// path's lock order (App first) so the two cannot deadlock.
class VerilyAppService {
  VerilyAppService({DateTime Function()? clock, Random? random})
    : clock = clock ?? (() => DateTime.now().toUtc()),
      _random = random ?? Random.secure();

  final DateTime Function() clock;
  final Random _random;

  static const maxActiveApps = 10;
  static const maxActiveKeys = 2;
  static const maxNameLength = 80;
  static const maxConfirmationPageSize = 50;

  Future<List<VerilyAppView>> listApps(
    Session session, {
    required UuidValue authUserId,
  }) async {
    final apps = await VerilyApp.db.find(
      session,
      where: (table) => table.creatorAuthUserId.equals(authUserId),
      orderBy: (table) => table.createdAt.desc(),
      limit: 100,
    );
    return _views(session, apps);
  }

  /// Creates an App and its first key, returned exactly once.
  Future<VerilyAppCredential> createApp(
    Session session, {
    required UuidValue authUserId,
    required String name,
    String? websiteUrl,
  }) async {
    final normalizedName = _appName(name);
    final normalizedWebsite = _websiteUrl(websiteUrl);
    final now = clock().toUtc();
    final issued = issueAppCredential(random: _random);
    final app = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        // The creator's account row serializes App creation per creator.
        await AccountAccess.requireActive(
          session,
          authUserId,
          transaction: transaction,
        );
        final active = await VerilyApp.db.find(
          session,
          where: (table) =>
              table.creatorAuthUserId.equals(authUserId) &
              table.status.equals(VerilyAppStatus.active),
          transaction: transaction,
        );
        if (active.length >= maxActiveApps) {
          throw StateError(
            'An account can have up to $maxActiveApps active apps.',
          );
        }
        final lowerName = normalizedName.toLowerCase();
        if (active.any((item) => item.name.toLowerCase() == lowerName)) {
          throw StateError('An active app already uses that name.');
        }
        final inserted = await VerilyApp.db.insertRow(
          session,
          VerilyApp(
            creatorAuthUserId: authUserId,
            name: normalizedName,
            websiteUrl: normalizedWebsite,
            status: VerilyAppStatus.active,
            createdAt: now,
            updatedAt: now,
          ),
          transaction: transaction,
        );
        await VerilyAppKey.db.insertRow(
          session,
          VerilyAppKey(
            appId: inserted.id!,
            keyId: issued.keyId,
            secretHash: issued.credentialHash,
            createdAt: now,
          ),
          transaction: transaction,
        );
        return inserted;
      },
    );
    return VerilyAppCredential(
      app: (await _views(session, [app])).single,
      keyId: issued.keyId,
      secret: issued.credential,
    );
  }

  /// Adds a second key for rotation. At most [maxActiveKeys] are active, so
  /// a creator revokes the old key once the App has switched.
  Future<VerilyAppCredential> createKey(
    Session session, {
    required UuidValue authUserId,
    required UuidValue appId,
  }) async {
    final now = clock().toUtc();
    final issued = issueAppCredential(random: _random);
    final app = await _mutateOwnedApp(
      session,
      authUserId: authUserId,
      appId: appId,
      (app, transaction) async {
        if (app.status != VerilyAppStatus.active) {
          throw StateError('This app has been revoked.');
        }
        final activeKeys = await VerilyAppKey.db.count(
          session,
          where: (table) =>
              table.appId.equals(appId) & table.revokedAt.equals(null),
          transaction: transaction,
        );
        if (activeKeys >= maxActiveKeys) {
          throw StateError(
            'Revoke an older key before creating another one.',
          );
        }
        await VerilyAppKey.db.insertRow(
          session,
          VerilyAppKey(
            appId: appId,
            keyId: issued.keyId,
            secretHash: issued.credentialHash,
            createdAt: now,
          ),
          transaction: transaction,
        );
        return app;
      },
    );
    return VerilyAppCredential(
      app: (await _views(session, [app])).single,
      keyId: issued.keyId,
      secret: issued.credential,
    );
  }

  Future<VerilyAppView> revokeKey(
    Session session, {
    required UuidValue authUserId,
    required UuidValue appId,
    required String keyId,
  }) async {
    final now = clock().toUtc();
    final app = await _mutateOwnedApp(
      session,
      authUserId: authUserId,
      appId: appId,
      (app, transaction) async {
        final key = await VerilyAppKey.db.findFirstRow(
          session,
          where: (table) =>
              table.appId.equals(appId) & table.keyId.equals(keyId.trim()),
          transaction: transaction,
        );
        if (key == null) throw StateError('That key was not found.');
        if (key.revokedAt == null) {
          await VerilyAppKey.db.updateRow(
            session,
            key.copyWith(revokedAt: now),
            transaction: transaction,
          );
        }
        return app;
      },
    );
    return (await _views(session, [app])).single;
  }

  /// Revokes the App and every key, and pauses the live actions it confirms.
  /// Confirmations stop immediately; those actions need a new revision bound
  /// to another App before they can run again.
  Future<VerilyAppView> revokeApp(
    Session session, {
    required UuidValue authUserId,
    required UuidValue appId,
  }) async {
    final now = clock().toUtc();
    final app = await _mutateOwnedApp(
      session,
      authUserId: authUserId,
      appId: appId,
      (app, transaction) async {
        if (app.status == VerilyAppStatus.revoked) return app;
        await VerilyAppKey.db.updateWhere(
          session,
          columnValues: (table) => [table.revokedAt(now)],
          where: (table) =>
              table.appId.equals(appId) & table.revokedAt.equals(null),
          transaction: transaction,
          noReturn: true,
        );
        final boundActionIds = await _boundActionIds(
          session,
          appId: appId,
          transaction: transaction,
        );
        if (boundActionIds.isNotEmpty) {
          await ActionDefinition.db.updateWhere(
            session,
            columnValues: (table) => [
              table.status(ActionDefinitionStatus.paused),
              table.pausedAt(now),
              table.updatedAt(now),
            ],
            where: (table) =>
                table.id.inSet(boundActionIds) &
                table.status.equals(ActionDefinitionStatus.active),
            transaction: transaction,
            noReturn: true,
          );
        }
        return VerilyApp.db.updateRow(
          session,
          app.copyWith(
            status: VerilyAppStatus.revoked,
            revokedAt: now,
            updatedAt: now,
          ),
          transaction: transaction,
        );
      },
    );
    return (await _views(session, [app])).single;
  }

  /// Newest confirmations first. Pass the last row's id as [beforeId] for
  /// the next page; ids are time-ordered UUID v7 values.
  Future<List<AppConfirmationView>> listConfirmations(
    Session session, {
    required UuidValue authUserId,
    required UuidValue appId,
    int limit = 25,
    UuidValue? beforeId,
  }) async {
    await _ownedApp(session, authUserId: authUserId, appId: appId);
    final confirmations = await AppConfirmation.db.find(
      session,
      where: (table) => beforeId == null
          ? table.appId.equals(appId)
          : table.appId.equals(appId) & (table.id < beforeId),
      orderBy: (table) => table.id.desc(),
      limit: limit.clamp(1, maxConfirmationPageSize),
    );
    final attemptIds = {
      for (final confirmation in confirmations) ?confirmation.attemptId,
    };
    final attempts = attemptIds.isEmpty
        ? const <ActionAttempt>[]
        : await ActionAttempt.db.find(
            session,
            where: (table) => table.id.inSet(attemptIds),
          );
    final statusByAttempt = {
      for (final attempt in attempts) attempt.id!: attempt.status,
    };
    return [
      for (final confirmation in confirmations)
        AppConfirmationView(
          id: confirmation.id!,
          eventId: confirmation.eventId,
          actionKey: confirmation.actionKey,
          outcome: confirmation.outcome,
          reasonCode: confirmation.reasonCode,
          occurredAt: confirmation.occurredAt,
          receivedAt: confirmation.receivedAt,
          attemptStatus: confirmation.attemptId == null
              ? null
              : statusByAttempt[confirmation.attemptId],
        ),
    ];
  }

  /// Returns the caller's subject for [appId], creating it once.
  ///
  /// A participant can link only an active App that confirms a live action,
  /// which is exactly what the participant feed already shows.
  Future<VerilyAppLinkView> linkApp(
    Session session, {
    required UuidValue authUserId,
    required UuidValue appId,
  }) async {
    await AccountAccess.requireActive(session, authUserId);
    final app = await VerilyApp.db.findById(session, appId);
    if (app != null && app.status == VerilyAppStatus.revoked) {
      throw AppUnavailableException(
        appName: app.name,
        message: 'This app was revoked by its creator.',
      );
    }
    if (app == null || !await _confirmsLiveAction(session, appId)) {
      throw StateError('That app is not available.');
    }
    final existing = await _link(session, appId, authUserId);
    if (existing != null) return _linkView(app, existing);

    await VerilyAppLink.db.insert(
      session,
      [
        VerilyAppLink(
          appId: appId,
          authUserId: authUserId,
          subject: _subject(),
          createdAt: clock().toUtc(),
        ),
      ],
      ignoreConflicts: true,
    );
    final link = await _link(session, appId, authUserId);
    if (link == null) throw StateError('The app link was not saved.');
    return _linkView(app, link);
  }

  Future<VerilyAppLink?> _link(
    Session session,
    UuidValue appId,
    UuidValue authUserId,
  ) {
    return VerilyAppLink.db.findFirstRow(
      session,
      where: (table) =>
          table.appId.equals(appId) & table.authUserId.equals(authUserId),
    );
  }

  Future<bool> _confirmsLiveAction(Session session, UuidValue appId) async {
    final rows = await session.db.unsafeQuery(
      '''
SELECT 1
FROM "verily_action_external_rule" AS r
JOIN "verily_action_requirement" AS q ON q."id" = r."requirementId"
JOIN "verily_action_definition" AS d ON d."id" = q."actionDefinitionId"
WHERE r."appId" = CAST(@appId AS uuid) AND d."status" = @active
LIMIT 1;
''',
      parameters: QueryParameters.named({
        'appId': appId.toString(),
        'active': ActionDefinitionStatus.active.name,
      }),
    );
    return rows.isNotEmpty;
  }

  Future<Set<UuidValue>> _boundActionIds(
    Session session, {
    required UuidValue appId,
    required Transaction transaction,
  }) async {
    final rows = await session.db.unsafeQuery(
      '''
SELECT DISTINCT q."actionDefinitionId"::text
FROM "verily_action_external_rule" AS r
JOIN "verily_action_requirement" AS q ON q."id" = r."requirementId"
WHERE r."appId" = CAST(@appId AS uuid);
''',
      parameters: QueryParameters.named({'appId': appId.toString()}),
      transaction: transaction,
    );
    return {
      for (final row in rows) UuidValue.withValidation(row[0]! as String),
    };
  }

  /// A new 128-bit pairwise subject: `vls_` plus 22 base64url characters.
  String _subject() {
    final bytes = [
      for (var index = 0; index < 16; index += 1) _random.nextInt(256),
    ];
    return 'vls_${base64Url.encode(bytes).replaceAll('=', '')}';
  }

  Future<VerilyApp> _ownedApp(
    Session session, {
    required UuidValue authUserId,
    required UuidValue appId,
    Transaction? transaction,
    LockMode? lockMode,
  }) async {
    final app = await VerilyApp.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(appId) & table.creatorAuthUserId.equals(authUserId),
      transaction: transaction,
      lockMode: lockMode,
    );
    if (app == null) throw StateError('That app was not found.');
    return app;
  }

  /// Locks the App row, then the creator's account, then runs [mutate].
  Future<VerilyApp> _mutateOwnedApp(
    Session session,
    Future<VerilyApp> Function(
      VerilyApp app,
      Transaction transaction,
    )
    mutate, {
    required UuidValue authUserId,
    required UuidValue appId,
  }) {
    return DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        final app = await _ownedApp(
          session,
          authUserId: authUserId,
          appId: appId,
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        await AccountAccess.requireActive(
          session,
          authUserId,
          transaction: transaction,
        );
        return mutate(app, transaction);
      },
    );
  }

  Future<List<VerilyAppView>> _views(
    Session session,
    List<VerilyApp> apps,
  ) async {
    if (apps.isEmpty) return const [];
    final appIds = {for (final app in apps) app.id!};
    final keys = await VerilyAppKey.db.find(
      session,
      where: (table) => table.appId.inSet(appIds),
      orderBy: (table) => table.createdAt,
    );
    final boundCounts = await _boundActionCounts(session, appIds);
    return [
      for (final app in apps)
        VerilyAppView(
          id: app.id!,
          name: app.name,
          websiteUrl: app.websiteUrl,
          status: app.status,
          keys: [
            for (final key in keys)
              if (key.appId == app.id)
                VerilyAppKeyView(
                  keyId: key.keyId,
                  createdAt: key.createdAt,
                  lastUsedAt: key.lastUsedAt,
                  revokedAt: key.revokedAt,
                ),
          ],
          boundActionCount: boundCounts[app.id] ?? 0,
          createdAt: app.createdAt,
          revokedAt: app.revokedAt,
        ),
    ];
  }

  Future<Map<UuidValue, int>> _boundActionCounts(
    Session session,
    Set<UuidValue> appIds,
  ) async {
    final rows = await session.db.unsafeQuery(
      '''
SELECT r."appId"::text, count(DISTINCT d."id")::int
FROM "verily_action_external_rule" AS r
JOIN "verily_action_requirement" AS q ON q."id" = r."requirementId"
JOIN "verily_action_definition" AS d ON d."id" = q."actionDefinitionId"
WHERE r."appId" = ANY(CAST(@appIds AS uuid[]))
  AND d."status" <> @completed
GROUP BY r."appId";
''',
      parameters: QueryParameters.named({
        'appIds': [for (final id in appIds) id.toString()],
        'completed': ActionDefinitionStatus.completed.name,
      }),
    );
    return {
      for (final row in rows)
        UuidValue.withValidation(row[0]! as String): row[1]! as int,
    };
  }
}

VerilyAppLinkView _linkView(VerilyApp app, VerilyAppLink link) {
  return VerilyAppLinkView(
    appId: app.id!,
    appName: app.name,
    subject: link.subject,
    createdAt: link.createdAt,
  );
}

String _appName(String value) {
  final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.isEmpty) throw ArgumentError('Name the app.');
  if (normalized.length > VerilyAppService.maxNameLength) {
    throw ArgumentError(
      'App names must be ${VerilyAppService.maxNameLength} characters or '
      'fewer.',
    );
  }
  return normalized;
}

String? _websiteUrl(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  final uri = Uri.tryParse(normalized);
  if (normalized.length > 200 ||
      uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.fragment.isNotEmpty) {
    throw ArgumentError('An app website must be an https:// address.');
  }
  return uri.toString();
}
