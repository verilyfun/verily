import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/core/config/server_config.dart';

/// The configured Serverpod client.
///
/// `main` overrides this with the one client the app talks to. Repositories
/// read it through their own providers, so tests replace a repository rather
/// than the client.
final verilyClientProvider = Provider<Client>(
  (ref) => throw StateError(
    'verilyClientProvider has no client. Override it in main or the test.',
  ),
);

/// Where the server is. Overridden in `main` next to [verilyClientProvider].
final serverConfigProvider = Provider<ServerConfig>(
  (ref) => serverConfigFrom(apiUrl: defaultServerUrl),
);

/// Creates the app's client with Flutter connectivity and session handling.
Client createVerilyClient(ServerConfig config) =>
    Client(config.apiUrl.toString())
      ..connectivityMonitor = FlutterConnectivityMonitor()
      ..authSessionManager = FlutterAuthSessionManager();
