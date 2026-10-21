import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/validation.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/core/api_client.dart';

/// What an App asked for when it opened `/link`: its id, the exact redirect
/// it registered, and the opaque state it wants back.
class AppLinkRequest {
  const AppLinkRequest({
    required this.appId,
    required this.redirectUri,
    this.state,
  });

  final UuidValue appId;
  final String redirectUri;
  final String? state;

  /// Reads the request from `/link?app=…&redirect_uri=…&state=…`, or null
  /// when the link is missing a part or names no valid App. Nothing in it is
  /// trusted: the server checks the redirect against the App's own list.
  static AppLinkRequest? fromQuery(Map<String, String> query) {
    final app = query['app'];
    final redirectUri = query['redirect_uri'];
    if (app == null ||
        !UuidValidation.isValidUUIDFormat(fromString: app) ||
        redirectUri == null ||
        redirectUri.isEmpty) {
      return null;
    }
    final state = query['state'];
    return AppLinkRequest(
      appId: UuidValue.fromString(app),
      redirectUri: redirectUri,
      state: state == null || state.isEmpty ? null : state,
    );
  }
}

/// Linking a Verily account to another App by deep link.
abstract interface class AppLinkRepository {
  /// What to show before linking: the App and whether it is linked already.
  Future<AppLinkRequestView> describe(AppLinkRequest request);

  /// Links and returns the App's redirect with a one-time code.
  Future<AppLinkRedirect> approve(AppLinkRequest request);

  /// Returns the App's redirect with `error=access_denied`.
  Future<AppLinkRedirect> decline(AppLinkRequest request);
}

class ServerpodAppLinkRepository implements AppLinkRepository {
  const ServerpodAppLinkRepository(this._client);

  final Client _client;

  @override
  Future<AppLinkRequestView> describe(AppLinkRequest request) =>
      _client.verilyApp.describeLinkRequest(
        appId: request.appId,
        redirectUri: request.redirectUri,
        state: request.state,
      );

  @override
  Future<AppLinkRedirect> approve(AppLinkRequest request) =>
      _client.verilyApp.approveLink(
        appId: request.appId,
        redirectUri: request.redirectUri,
        state: request.state,
      );

  @override
  Future<AppLinkRedirect> decline(AppLinkRequest request) =>
      _client.verilyApp.declineLink(
        appId: request.appId,
        redirectUri: request.redirectUri,
        state: request.state,
      );
}

final appLinkRepositoryProvider = Provider<AppLinkRepository>(
  (ref) => ServerpodAppLinkRepository(ref.watch(verilyClientProvider)),
);
