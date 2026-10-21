import 'package:verily_server/src/generated/protocol.dart';

/// The most return addresses one App may register.
const maxAppRedirectUris = 10;

const _blockedSchemes = {
  'http',
  'javascript',
  'data',
  'file',
  'vbscript',
  'about',
  'blob',
  'ftp',
  'ws',
  'wss',
  'mailto',
  'tel',
  'sms',
  'intent',
  'content',
  'verily',
};

/// Validates one redirect URI an App registers for deep links and returns it
/// unchanged. Matching is always exact string equality, so the registered
/// form is the only form that will ever match.
///
/// Allowed: `https://host/path?query` without credentials, or a custom app
/// scheme such as `com.example.app://callback`. Refused: wildcards,
/// fragments, whitespace, plain `http`, script and file schemes, and Verily's
/// own scheme.
String validateRedirectUri(String value) {
  if (value != value.trim() ||
      value.length < 4 ||
      value.length > 512 ||
      value.contains('*') ||
      value.contains('#') ||
      RegExp(r'\s').hasMatch(value)) {
    throw _invalid();
  }
  final uri = Uri.tryParse(value);
  if (uri == null || uri.hasFragment || uri.userInfo.isNotEmpty) {
    throw _invalid();
  }
  final scheme = uri.scheme;
  if (!RegExp(r'^[a-z][a-z0-9+.-]{1,62}$').hasMatch(scheme) ||
      _blockedSchemes.contains(scheme)) {
    throw _invalid();
  }
  if (scheme == 'https') {
    if (uri.host.isEmpty) throw _invalid();
    return value;
  }
  // A custom scheme must name something after the colon.
  if (value.length <= scheme.length + 1 ||
      value.substring(scheme.length + 1).replaceAll('/', '').isEmpty) {
    throw _invalid();
  }
  return value;
}

/// Validates and de-duplicates a full replacement list.
List<String> validateRedirectUris(List<String> values) {
  if (values.length > maxAppRedirectUris) {
    throw AppPlatformException(
      problem: AppPlatformProblem.tooManyRedirectUris,
      message: 'An app can register at most $maxAppRedirectUris redirect URIs.',
    );
  }
  return {for (final value in values) validateRedirectUri(value)}.toList();
}

AppPlatformException _invalid() => AppPlatformException(
  problem: AppPlatformProblem.invalidRedirectUri,
  message:
      'Redirect URIs must be exact https URLs or custom app schemes, without '
      'wildcards or fragments.',
);
