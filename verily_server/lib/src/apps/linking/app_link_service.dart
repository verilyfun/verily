import 'dart:convert';
import 'dart:math';

import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/account/account_access.dart';
import 'package:verily_server/src/apps/api/app_api_json.dart';
import 'package:verily_server/src/apps/app_api_auth.dart';
import 'package:verily_server/src/apps/app_confirmation_service.dart';
import 'package:verily_server/src/apps/app_rate_limiter.dart';
import 'package:verily_server/src/apps/app_subjects.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/security/secret_digest.dart';

/// How long a link code works after approval.
const appLinkCodeLifetime = Duration(minutes: 5);

/// Approvals per account per App in each [appLinkApprovalWindow].
const appLinkApprovalLimit = 20;
const appLinkApprovalWindow = Duration(hours: 1);

/// Exchanges per App in each [appLinkExchangeWindow].
const appLinkExchangeLimit = 60;
const appLinkExchangeWindow = Duration(minutes: 1);

final RegExp _statePattern = RegExp(r'^[\x20-\x7E]{1,256}$');
final RegExp _codePattern = RegExp(r'^[A-Za-z0-9_-]{43}$');

/// Deep-link account linking, OAuth-shaped so nothing in a URL is trusted.
///
/// The Verily app opens
/// `https://verily.fun/link?app=<appId>&state=…&redirect_uri=…`, shows
/// [describe], and on consent calls [approve], which returns the App's
/// exact registered redirect with a one-time, five-minute
/// code bound to (App, account, redirect URI, state). The App's backend then
/// trades the code for the pairwise `vls_` subject with [exchange]. Only the
/// code's SHA-256 is stored, and account ids never leave Verily.
class AppLinkService {
  AppLinkService({
    DateTime Function()? clock,
    Random? random,
    AppRateLimiter? rateLimiter,
  }) : clock = clock ?? (() => DateTime.now().toUtc()),
       _random = random ?? Random.secure(),
       rateLimiter = rateLimiter ?? const AppRateLimiter();

  final DateTime Function() clock;
  final Random _random;
  final AppRateLimiter rateLimiter;

  /// Who is asking and where the person returns. Throws when the App, the
  /// redirect URI, or the state is not valid for this App.
  Future<AppLinkRequestView> describe(
    Session session, {
    required UuidValue authUserId,
    required UuidValue appId,
    required String redirectUri,
    String? state,
  }) async {
    await AccountAccess.requireActive(session, authUserId);
    final request = await _validated(
      session,
      appId: appId,
      redirectUri: redirectUri,
      state: state,
    );
    final link = await VerilyAppLink.db.findFirstRow(
      session,
      where: (table) =>
          table.appId.equals(appId) & table.authUserId.equals(authUserId),
    );
    return AppLinkRequestView(
      appId: appId,
      appName: request.app.name,
      websiteUrl: request.app.websiteUrl,
      redirectUri: redirectUri,
      alreadyLinked: link != null,
    );
  }

  /// The person consented: issue a one-time code and return the redirect.
  Future<AppLinkRedirect> approve(
    Session session, {
    required UuidValue authUserId,
    required UuidValue appId,
    required String redirectUri,
    String? state,
  }) async {
    final request = await _validated(
      session,
      appId: appId,
      redirectUri: redirectUri,
      state: state,
    );
    final code = _newCode();
    final expiresAt = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        final now = clock().toUtc();
        await AccountAccess.requireActive(
          session,
          authUserId,
          transaction: transaction,
        );
        final link = await appLinkFor(
          session,
          appId: appId,
          authUserId: authUserId,
          now: now,
          transaction: transaction,
        );
        final retryAfter = await rateLimiter.consume(
          session,
          appId: appId,
          bucket: 'link-approve:${link.subject}',
          limit: appLinkApprovalLimit,
          window: appLinkApprovalWindow,
          now: now,
          transaction: transaction,
        );
        if (retryAfter != null) {
          throw AppPlatformException(
            problem: AppPlatformProblem.rateLimited,
            message: 'Too many link approvals for this app. Try again later.',
          );
        }
        // Codes this account left unused expire for good; keep the table
        // bounded without a separate sweep.
        await VerilyAppLinkCode.db.deleteWhere(
          session,
          where: (table) =>
              table.appId.equals(appId) &
              table.authUserId.equals(authUserId) &
              (table.expiresAt < now),
          transaction: transaction,
        );
        final expiresAt = now.add(appLinkCodeLifetime);
        await VerilyAppLinkCode.db.insertRow(
          session,
          VerilyAppLinkCode(
            appId: appId,
            authUserId: authUserId,
            codeHash: secretSha256Hex(code),
            redirectUri: redirectUri,
            state: request.state,
            expiresAt: expiresAt,
            createdAt: now,
          ),
          transaction: transaction,
        );
        return expiresAt;
      },
    );
    return AppLinkRedirect(
      redirectUrl: appendRedirectQuery(redirectUri, {
        'code': code,
        'state': ?request.state,
      }),
      codeExpiresAt: expiresAt,
    );
  }

  /// The person declined: return to the App with `error=access_denied`.
  Future<AppLinkRedirect> decline(
    Session session, {
    required UuidValue authUserId,
    required UuidValue appId,
    required String redirectUri,
    String? state,
  }) async {
    final request = await _validated(
      session,
      appId: appId,
      redirectUri: redirectUri,
      state: state,
    );
    return AppLinkRedirect(
      redirectUrl: appendRedirectQuery(redirectUri, {
        'error': 'access_denied',
        'state': ?request.state,
      }),
    );
  }

  /// `POST /api/v1/links/exchange` with `{"code", "redirectUri"}`.
  ///
  /// The code must belong to the calling App, be unused and unexpired, and
  /// carry exactly this redirect URI, and its account must still be active.
  /// It is consumed under its row lock, so it works once. Every grant
  /// failure answers the same `invalid_grant`.
  Future<AppDeliveryResponse> exchange(
    Session session, {
    required String? authorization,
    required String? timestamp,
    required String body,
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
    return DatabaseUtil.runInTransactionOrSavepoint(
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
        if (app == null) return appApiUnauthorized;
        final retryAfter = await rateLimiter.consume(
          session,
          appId: app.id!,
          bucket: 'link-exchange',
          limit: appLinkExchangeLimit,
          window: appLinkExchangeWindow,
          now: now,
          transaction: transaction,
        );
        if (retryAfter != null) return appApiRateLimited(retryAfter);

        final String code;
        final String redirectUri;
        try {
          final json = StrictJsonObject.parse(
            body,
            allowed: const {'code', 'redirectUri'},
          );
          code = json.string('code', maxLength: 128);
          redirectUri = json.string('redirectUri', maxLength: 512);
        } on AppApiSchemaException catch (error) {
          return appApiInvalid(error.code, error.message);
        }
        if (!_codePattern.hasMatch(code)) return _invalidGrant;
        final stored = await VerilyAppLinkCode.db.findFirstRow(
          session,
          where: (table) => table.codeHash.equals(secretSha256Hex(code)),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (stored == null ||
            stored.appId != app.id ||
            stored.usedAt != null ||
            !stored.expiresAt.isAfter(now) ||
            !constantTimeEquals(stored.redirectUri, redirectUri)) {
          return _invalidGrant;
        }
        if (!await AccountAccess.isActive(
          session,
          stored.authUserId,
          transaction: transaction,
        )) {
          return _invalidGrant;
        }
        await VerilyAppLinkCode.db.updateRow(
          session,
          stored.copyWith(usedAt: now),
          transaction: transaction,
        );
        final link = await appLinkFor(
          session,
          appId: app.id!,
          authUserId: stored.authUserId,
          now: now,
          transaction: transaction,
        );
        return AppDeliveryResponse(200, {'subject': link.subject});
      },
    );
  }

  /// The App, exact redirect URI, and state of one deep link.
  Future<({VerilyApp app, String? state})> _validated(
    Session session, {
    required UuidValue appId,
    required String redirectUri,
    required String? state,
  }) async {
    final normalizedState = state == null || state.isEmpty ? null : state;
    if (normalizedState != null && !_statePattern.hasMatch(normalizedState)) {
      throw _linkRequestInvalid;
    }
    if (redirectUri.isEmpty || redirectUri.length > 512) {
      throw _linkRequestInvalid;
    }
    final app = await VerilyApp.db.findById(session, appId);
    if (app == null) throw _linkRequestInvalid;
    if (app.status != VerilyAppStatus.active) {
      throw AppUnavailableException(
        appName: app.name,
        message: 'This app was revoked by its creator.',
      );
    }
    // Exact, case-sensitive string equality: no prefixes, normalization, or
    // wildcards. The registered form is the only form that matches.
    final registered = await VerilyAppRedirectUri.db.findFirstRow(
      session,
      where: (table) =>
          table.appId.equals(appId) & table.uri.equals(redirectUri),
    );
    if (registered == null || registered.uri != redirectUri) {
      throw _linkRequestInvalid;
    }
    return (app: app, state: normalizedState);
  }

  /// 32 random bytes, unpadded base64url (43 characters).
  String _newCode() => base64Url
      .encode([
        for (var index = 0; index < 32; index += 1) _random.nextInt(256),
      ])
      .replaceAll('=', '');
}

/// Appends query parameters to an exact registered redirect URI, keeping
/// the registered text as an unchanged prefix (registered URIs never carry
/// a fragment).
String appendRedirectQuery(String redirectUri, Map<String, String> query) {
  final encoded = [
    for (final entry in query.entries)
      '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
  ].join('&');
  if (!redirectUri.contains('?')) return '$redirectUri?$encoded';
  if (redirectUri.endsWith('?') || redirectUri.endsWith('&')) {
    return '$redirectUri$encoded';
  }
  return '$redirectUri&$encoded';
}

final _linkRequestInvalid = AppPlatformException(
  problem: AppPlatformProblem.linkRequestInvalid,
  message: 'This link request is not valid for that app.',
);

const _invalidGrant = AppDeliveryResponse(400, {
  'error': 'invalid_grant',
  'message': 'The code is invalid, expired, or already used.',
});
