import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/core/api_client.dart';

/// The caller's Verily Apps: software that confirms actions on its own.
abstract interface class AppsRepository {
  Future<List<VerilyAppView>> listApps();

  /// Registers an App. The returned credential carries its first key's
  /// secret, which the server never shows again.
  Future<VerilyAppCredential> createApp({
    required String name,
    String? websiteUrl,
  });

  /// A new key, shown once. An App holds at most two active keys.
  Future<VerilyAppCredential> createKey(UuidValue appId);
  Future<VerilyAppView> revokeKey({
    required UuidValue appId,
    required String keyId,
  });

  /// Revokes the App and its keys, and pauses its actions.
  Future<VerilyAppView> revokeApp(UuidValue appId);

  /// Append-only confirmation receipts, newest first.
  Future<List<AppConfirmationView>> listConfirmations(
    UuidValue appId, {
    UuidValue? beforeId,
  });

  /// The caller's own pairwise `vls_` subject for an App with a live action:
  /// the code a participant gives the App so it can confirm them.
  Future<VerilyAppLinkView> linkApp(UuidValue appId);
}

class ServerpodAppsRepository implements AppsRepository {
  const ServerpodAppsRepository(this._client);

  final Client _client;

  @override
  Future<List<VerilyAppView>> listApps() => _client.verilyApp.listApps();

  @override
  Future<VerilyAppCredential> createApp({
    required String name,
    String? websiteUrl,
  }) => _client.verilyApp.createApp(name: name, websiteUrl: websiteUrl);

  @override
  Future<VerilyAppCredential> createKey(UuidValue appId) =>
      _client.verilyApp.createKey(appId: appId);

  @override
  Future<VerilyAppView> revokeKey({
    required UuidValue appId,
    required String keyId,
  }) => _client.verilyApp.revokeKey(appId: appId, keyId: keyId);

  @override
  Future<VerilyAppView> revokeApp(UuidValue appId) =>
      _client.verilyApp.revokeApp(appId: appId);

  @override
  Future<List<AppConfirmationView>> listConfirmations(
    UuidValue appId, {
    UuidValue? beforeId,
  }) => _client.verilyApp.listConfirmations(
    appId: appId,
    limit: 50,
    beforeId: beforeId,
  );

  @override
  Future<VerilyAppLinkView> linkApp(UuidValue appId) =>
      _client.verilyApp.linkApp(appId: appId);
}

final appsRepositoryProvider = Provider<AppsRepository>(
  (ref) => ServerpodAppsRepository(ref.watch(verilyClientProvider)),
);
