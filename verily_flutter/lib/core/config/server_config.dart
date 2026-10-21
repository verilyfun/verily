import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Where the app finds the Verily server.
///
/// Local development runs the API on 8180 and the web server (which also
/// serves the public `/api/v1/...` routes for Verily Apps) on 8182, so they
/// never clash with other Serverpod projects on the default ports.
@immutable
class ServerConfig {
  const ServerConfig({required this.apiUrl, required this.publicWebUrl});

  /// The Serverpod RPC endpoint, with a trailing slash.
  final Uri apiUrl;

  /// The web server that answers public HTTP routes such as
  /// `POST /api/v1/confirmations`.
  final Uri publicWebUrl;

  /// The URL a Verily App posts confirmations to.
  Uri get confirmationsUrl => publicWebUrl.resolve('api/v1/confirmations');
}

const _serverUrlDefine = String.fromEnvironment('SERVER_URL');
const _publicWebUrlDefine = String.fromEnvironment('PUBLIC_WEB_URL');

/// The API address used when neither a `SERVER_URL` define nor
/// `assets/config.json` names one.
const defaultServerUrl = 'http://localhost:8180/';

/// Resolves the server from, in order: the `SERVER_URL` dart-define, the
/// `apiUrl` in `assets/config.json` (which the server rewrites for the web
/// build), then [defaultServerUrl].
///
/// A malformed URL is a build or deployment mistake, so it throws rather than
/// silently falling back to a server nobody configured.
Future<ServerConfig> resolveServerConfig({AssetBundle? bundle}) async {
  final apiUrl = _serverUrlDefine.isNotEmpty
      ? _serverUrlDefine
      : await _configuredApiUrl(bundle ?? rootBundle) ?? defaultServerUrl;
  final publicWebUrl = _publicWebUrlDefine.isNotEmpty
      ? _publicWebUrlDefine
      : null;
  return serverConfigFrom(apiUrl: apiUrl, publicWebUrl: publicWebUrl);
}

/// Builds a [ServerConfig] from raw strings. Exposed for tests.
ServerConfig serverConfigFrom({required String apiUrl, String? publicWebUrl}) {
  final api = _parseHttpUrl(apiUrl, 'SERVER_URL');
  final web = publicWebUrl == null
      ? _webServerFor(api)
      : _parseHttpUrl(publicWebUrl, 'PUBLIC_WEB_URL');
  return ServerConfig(apiUrl: api, publicWebUrl: web);
}

Future<String?> _configuredApiUrl(AssetBundle bundle) async {
  // The asset ships with every build; the server rewrites it for the web app.
  final raw = await bundle.loadString('assets/config.json');
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('assets/config.json must be a JSON object.');
  }
  final apiUrl = decoded['apiUrl'];
  if (apiUrl == null) return null;
  if (apiUrl is! String || apiUrl.trim().isEmpty) {
    throw const FormatException('assets/config.json apiUrl must be a URL.');
  }
  return apiUrl;
}

Uri _parseHttpUrl(String value, String name) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null ||
      !(uri.isScheme('http') || uri.isScheme('https')) ||
      uri.host.isEmpty) {
    throw FormatException('$name must be an http or https URL.', value);
  }
  // Serverpod resolves endpoint paths against the base, so it needs the slash.
  return uri.path.endsWith('/') ? uri : uri.replace(path: '${uri.path}/');
}

/// The local web server sits two ports above the API; anywhere else the
/// public routes share the API's origin unless PUBLIC_WEB_URL says otherwise.
Uri _webServerFor(Uri api) {
  final isLocal = api.host == 'localhost' || api.host == '127.0.0.1';
  if (isLocal && api.port == 8180) return api.replace(port: 8182);
  return api;
}
