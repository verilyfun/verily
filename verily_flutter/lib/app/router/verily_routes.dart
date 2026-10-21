/// Route names, paths, and locations.
///
/// Names identify a route for `goNamed`; paths are the URL patterns. The
/// helpers build concrete locations so a screen never assembles a URL by
/// hand.
abstract final class VerilyRouteNames {
  static const welcome = 'welcome';
  static const signIn = 'sign-in';
  static const doTab = 'do';
  static const create = 'create';
  static const me = 'me';
  static const actionNew = 'action-new';
  static const action = 'action';
  static const actionEdit = 'action-edit';
  static const reviews = 'reviews';
  static const appeals = 'appeals';
  static const apps = 'apps';
  static const app = 'app';
  static const settings = 'settings';
  static const verificationRequest = 'verification-request';
  static const link = 'link';
}

abstract final class VerilyRoutePaths {
  static const welcome = '/';
  static const signIn = '/sign-in';
  static const doTab = '/do';
  static const create = '/create';
  static const me = '/me';
  static const actionNew = '/actions/new';
  static const action = '/actions/:actionId';
  static const actionEdit = '/actions/:actionId/edit';
  static const reviews = '/reviews';
  static const appeals = '/appeals';
  static const apps = '/apps';
  static const app = '/apps/:appId';
  static const settings = '/settings';
  static const verificationRequest = '/r/:requestId';
  static const link = '/link';
}

abstract final class VerilyLocations {
  static String action(String actionId) =>
      '/actions/${Uri.encodeComponent(actionId)}';

  static String actionEdit(String actionId) =>
      '/actions/${Uri.encodeComponent(actionId)}/edit';

  static String app(String appId) => '/apps/${Uri.encodeComponent(appId)}';

  /// The sign-in page that returns to [from] afterwards.
  /// The account prompt. [from] is the page to return to; [returning]
  /// opens on signing in rather than signing up.
  static String signIn({String? from, bool returning = false}) {
    final query = {
      if (from != null && from.isNotEmpty) 'from': from,
      if (returning) signInAccountParameter: signInReturningAccount,
    };
    return query.isEmpty
        ? VerilyRoutePaths.signIn
        : Uri(path: VerilyRoutePaths.signIn, queryParameters: query).toString();
  }

  /// The sign-in query parameter that says which form to open first.
  static const signInAccountParameter = 'account';

  /// Its value for someone who already has an account.
  static const signInReturningAccount = 'returning';
}

/// Route names whose content a signed-out visitor may see.
///
/// Every server call needs an account, so only the front door is public.
/// Every other page, including the request and link pages other Apps open,
/// shows the account prompt in place and its own content once the person
/// has signed in. Route names are used rather than URL prefixes so a new
/// route cannot silently become public.
const guestAccessibleRouteNames = <String>{
  VerilyRouteNames.welcome,
  VerilyRouteNames.signIn,
};

bool isGuestAccessibleRoute(String? routeName) =>
    routeName != null && guestAccessibleRouteNames.contains(routeName);

/// The hosts whose `https` links open in the app (Android App Links and iOS
/// universal links for `verily.fun`).
const _appLinkHosts = {'verily.fun', 'www.verily.fun'};

/// Turns an incoming deep link into an in-app location, or returns null when
/// [uri] is already an in-app location.
///
/// - `verily://r/<requestId>` becomes `/r/<requestId>`; `verily://link?…`
///   becomes `/link?…`. Flutter hands the router the whole URI, and a custom
///   scheme's first segment arrives as the host, not the path.
/// - `https://verily.fun/r/…` and `/link…` keep their path and query.
/// - Anything else from outside the app lands on the front door.
String? deepLinkLocation(Uri uri) {
  if (!uri.hasScheme) return null;
  final query = uri.hasQuery ? '?${uri.query}' : '';
  if (uri.isScheme('verily')) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    return switch (uri.host) {
      'r' when segments.length == 1 =>
        '/r/${Uri.encodeComponent(segments.single)}$query',
      'link' when segments.isEmpty => '/link$query',
      _ => VerilyRoutePaths.welcome,
    };
  }
  if ((uri.isScheme('https') || uri.isScheme('http')) &&
      _appLinkHosts.contains(uri.host)) {
    final path = uri.path.isEmpty ? '/' : uri.path;
    return '$path$query';
  }
  return VerilyRoutePaths.welcome;
}
