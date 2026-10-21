import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/apps/app_confirmation_payload.dart';
import 'package:verily_server/src/apps/app_confirmation_service.dart';
import 'package:verily_server/src/apps/app_credentials.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// The outcome of authenticating one App API request.
sealed class AppApiAuthentication {
  const AppApiAuthentication();
}

/// A valid, unrevoked key. The App itself is re-checked under its row lock
/// by [lockAuthenticatedApp] before anything is written.
final class AppApiAuthenticated extends AppApiAuthentication {
  const AppApiAuthenticated(this.key);

  final VerilyAppKey key;
}

/// The request is refused with [response]; nothing else may run.
final class AppApiRefused extends AppApiAuthentication {
  const AppApiRefused(this.response);

  final AppDeliveryResponse response;
}

/// Authenticates `Authorization: Bearer vly_…` plus a fresh
/// `Verily-Timestamp` (±300 s), the same contract as confirmations.
///
/// The key is checked on an unlocked read: the key id is public, so a caller
/// without the secret must never queue behind real requests for the App row
/// lock. Secrets are compared in constant time and never logged.
Future<AppApiAuthentication> authenticateAppRequest(
  Session session, {
  required String? authorization,
  required String? timestamp,
  required DateTime now,
}) async {
  final credential = parseAppAuthorization(authorization);
  if (credential == null) return const AppApiRefused(appApiUnauthorized);
  if (!appTimestampIsFresh(timestamp, now)) {
    return const AppApiRefused(appApiInvalidTimestamp);
  }
  final key = await VerilyAppKey.db.findFirstRow(
    session,
    where: (table) => table.keyId.equals(credential.keyId),
  );
  if (key == null ||
      key.revokedAt != null ||
      !credential.matches(key.secretHash)) {
    return const AppApiRefused(appApiUnauthorized);
  }
  return AppApiAuthenticated(key);
}

/// Locks the key's App row and re-checks that both are still active, then
/// records the key's use. Returns null when either was revoked meanwhile.
///
/// The App row lock comes first in every App request, ahead of account,
/// attempt, and action-key locks.
Future<VerilyApp?> lockAuthenticatedApp(
  Session session, {
  required VerilyAppKey key,
  required DateTime now,
  required Transaction transaction,
}) async {
  final app = await VerilyApp.db.findFirstRow(
    session,
    where: (table) => table.id.equals(key.appId),
    transaction: transaction,
    lockMode: LockMode.forUpdate,
  );
  final lockedKey = await VerilyAppKey.db.findById(
    session,
    key.id!,
    transaction: transaction,
  );
  if (app == null ||
      lockedKey == null ||
      app.status != VerilyAppStatus.active ||
      lockedKey.revokedAt != null) {
    return null;
  }
  await VerilyAppKey.db.updateRow(
    session,
    lockedKey.copyWith(lastUsedAt: now),
    transaction: transaction,
  );
  return app;
}

const appApiUnauthorized = AppDeliveryResponse(401, {
  'error': 'invalid_credentials',
  'message': 'Send a valid, active app key as a Bearer token.',
});

const appApiInvalidTimestamp = AppDeliveryResponse(401, {
  'error': 'invalid_timestamp',
  'message': 'Verily-Timestamp must be the current unix time in seconds.',
});

/// A 429 with `Retry-After`.
AppDeliveryResponse appApiRateLimited(Duration retryAfter) =>
    AppDeliveryResponse(
      429,
      const {
        'error': 'rate_limited',
        'message': 'Too many requests for this app. Retry later.',
      },
      retryAfter: retryAfter,
    );

/// A 422 for a body that fails strict validation. [code] is stable;
/// [message] is safe to show a developer and never echoes input.
AppDeliveryResponse appApiInvalid(String code, String message) =>
    AppDeliveryResponse(422, {'error': code, 'message': message});

const appApiNotFound = AppDeliveryResponse(404, {
  'error': 'not_found',
  'message': 'Nothing with that id belongs to this app.',
});
