import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/core/api_client.dart';

/// The caller's Verily Apps: software that confirms actions on its own.
abstract interface class AppsRepository {
  Future<List<VerilyAppView>> listApps();

  /// One of the caller's Apps. Throws [ResourceNotFoundException] for an App
  /// that does not exist or belongs to someone else.
  Future<VerilyAppView> getApp(UuidValue appId);

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

  /// Sets the https address that receives the App's events and pull checks,
  /// or clears it with null. The server refuses private and local hosts.
  Future<VerilyAppView> setWebhookUrl({
    required UuidValue appId,
    required String? webhookUrl,
  });

  /// Issues the App's next `whsec_` signing secret, shown once. The previous
  /// secret keeps signing alongside it for 24 hours.
  Future<VerilyAppWebhookSecret> rotateWebhookSecret(UuidValue appId);

  /// Replaces the App's exact-match deep-link return addresses.
  Future<VerilyAppView> setRedirectUris({
    required UuidValue appId,
    required List<String> redirectUris,
  });

  /// The append-only log of calls Verily made to the App's webhook, newest
  /// first.
  Future<List<AppWebhookDeliveryView>> listWebhookDeliveries(
    UuidValue appId, {
    UuidValue? beforeId,
  });
}

class ServerpodAppsRepository implements AppsRepository {
  const ServerpodAppsRepository(this._client);

  final Client _client;

  @override
  Future<List<VerilyAppView>> listApps() => _client.verilyApp.listApps();

  @override
  Future<VerilyAppView> getApp(UuidValue appId) =>
      _client.verilyApp.getApp(appId: appId);

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
    limit: AppPageSizes.confirmations,
    beforeId: beforeId,
  );

  @override
  Future<VerilyAppLinkView> linkApp(UuidValue appId) =>
      _client.verilyApp.linkApp(appId: appId);

  @override
  Future<VerilyAppView> setWebhookUrl({
    required UuidValue appId,
    required String? webhookUrl,
  }) => _client.verilyApp.setWebhookUrl(appId: appId, webhookUrl: webhookUrl);

  @override
  Future<VerilyAppWebhookSecret> rotateWebhookSecret(UuidValue appId) =>
      _client.verilyApp.rotateWebhookSecret(appId: appId);

  @override
  Future<VerilyAppView> setRedirectUris({
    required UuidValue appId,
    required List<String> redirectUris,
  }) => _client.verilyApp.setRedirectUris(
    appId: appId,
    redirectUris: redirectUris,
  );

  @override
  Future<List<AppWebhookDeliveryView>> listWebhookDeliveries(
    UuidValue appId, {
    UuidValue? beforeId,
  }) => _client.verilyApp.listWebhookDeliveries(
    appId: appId,
    limit: AppPageSizes.deliveries,
    beforeId: beforeId,
  );
}

/// How many log rows one request asks for.
abstract final class AppPageSizes {
  static const confirmations = 50;
  static const deliveries = 50;
}

final appsRepositoryProvider = Provider<AppsRepository>(
  (ref) => ServerpodAppsRepository(ref.watch(verilyClientProvider)),
);
