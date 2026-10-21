import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:verily_server/src/apps/linking/app_link_service.dart';
import 'package:verily_server/src/apps/verily_app_service.dart';
import 'package:verily_server/src/apps/webhooks/app_event_delivery_service.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// Creator management of Verily Apps, and a participant's own subject.
///
/// Every method derives the caller from the authenticated session; creator
/// methods re-check App ownership on each call. Apps themselves never use
/// this endpoint: they call `POST /api/v1/confirmations` with an App key.
class VerilyAppEndpoint extends Endpoint {
  VerilyAppEndpoint({
    VerilyAppService? service,
    AppEventDeliveryService? deliveries,
    AppLinkService? links,
  }) : service = service ?? VerilyAppService(),
       deliveries = deliveries ?? AppEventDeliveryService(),
       links = links ?? AppLinkService();

  final VerilyAppService service;
  final AppEventDeliveryService deliveries;
  final AppLinkService links;

  @override
  bool get requireLogin => true;

  Future<List<VerilyAppView>> listApps(Session session) {
    return service.listApps(
      session,
      authUserId: session.authenticated!.authUserId,
    );
  }

  /// One of the caller's Apps, for its detail page.
  Future<VerilyAppView> getApp(
    Session session, {
    required UuidValue appId,
  }) {
    return service.getApp(
      session,
      authUserId: session.authenticated!.authUserId,
      appId: appId,
    );
  }

  /// Registers an App. The returned key is never retrievable again.
  Future<VerilyAppCredential> createApp(
    Session session, {
    required String name,
    String? websiteUrl,
  }) {
    return service.createApp(
      session,
      authUserId: session.authenticated!.authUserId,
      name: name,
      websiteUrl: websiteUrl,
    );
  }

  /// Adds a rotation key. The returned key is never retrievable again.
  Future<VerilyAppCredential> createKey(
    Session session, {
    required UuidValue appId,
  }) {
    return service.createKey(
      session,
      authUserId: session.authenticated!.authUserId,
      appId: appId,
    );
  }

  Future<VerilyAppView> revokeKey(
    Session session, {
    required UuidValue appId,
    required String keyId,
  }) {
    return service.revokeKey(
      session,
      authUserId: session.authenticated!.authUserId,
      appId: appId,
      keyId: keyId,
    );
  }

  Future<VerilyAppView> revokeApp(
    Session session, {
    required UuidValue appId,
  }) {
    return service.revokeApp(
      session,
      authUserId: session.authenticated!.authUserId,
      appId: appId,
    );
  }

  Future<List<AppConfirmationView>> listConfirmations(
    Session session, {
    required UuidValue appId,
    int limit = 25,
    UuidValue? beforeId,
  }) {
    return service.listConfirmations(
      session,
      authUserId: session.authenticated!.authUserId,
      appId: appId,
      limit: limit,
      beforeId: beforeId,
    );
  }

  /// Returns the caller's own subject for an App of a live action.
  Future<VerilyAppLinkView> linkApp(
    Session session, {
    required UuidValue appId,
  }) {
    return service.linkApp(
      session,
      authUserId: session.authenticated!.authUserId,
      appId: appId,
    );
  }

  /// Sets or clears the HTTPS URL that receives signed events and pull
  /// verification calls.
  Future<VerilyAppView> setWebhookUrl(
    Session session, {
    required UuidValue appId,
    String? webhookUrl,
  }) {
    return service.setWebhookUrl(
      session,
      authUserId: session.authenticated!.authUserId,
      appId: appId,
      webhookUrl: webhookUrl,
    );
  }

  /// Issues the next `whsec_` signing secret, returned only this once.
  Future<VerilyAppWebhookSecret> rotateWebhookSecret(
    Session session, {
    required UuidValue appId,
  }) {
    return service.rotateWebhookSecret(
      session,
      authUserId: session.authenticated!.authUserId,
      appId: appId,
    );
  }

  /// Replaces the exact-match redirect URIs used by deep links.
  Future<VerilyAppView> setRedirectUris(
    Session session, {
    required UuidValue appId,
    required List<String> redirectUris,
  }) {
    return service.setRedirectUris(
      session,
      authUserId: session.authenticated!.authUserId,
      appId: appId,
      redirectUris: redirectUris,
    );
  }

  /// The App's outbound webhook log, newest first.
  Future<List<AppWebhookDeliveryView>> listWebhookDeliveries(
    Session session, {
    required UuidValue appId,
    int limit = 25,
    UuidValue? beforeId,
  }) {
    return deliveries.listDeliveries(
      session,
      authUserId: session.authenticated!.authUserId,
      appId: appId,
      limit: limit,
      beforeId: beforeId,
    );
  }

  /// What to show before linking this account to an App that opened
  /// `https://verily.fun/link?app=…&redirect_uri=…&state=…`.
  Future<AppLinkRequestView> describeLinkRequest(
    Session session, {
    required UuidValue appId,
    required String redirectUri,
    String? state,
  }) {
    return links.describe(
      session,
      authUserId: session.authenticated!.authUserId,
      appId: appId,
      redirectUri: redirectUri,
      state: state,
    );
  }

  /// Approves the link and returns the App's redirect with a one-time,
  /// five-minute code.
  Future<AppLinkRedirect> approveLink(
    Session session, {
    required UuidValue appId,
    required String redirectUri,
    String? state,
  }) {
    return links.approve(
      session,
      authUserId: session.authenticated!.authUserId,
      appId: appId,
      redirectUri: redirectUri,
      state: state,
    );
  }

  /// Declines the link and returns the App's redirect with
  /// `error=access_denied`.
  Future<AppLinkRedirect> declineLink(
    Session session, {
    required UuidValue appId,
    required String redirectUri,
    String? state,
  }) {
    return links.decline(
      session,
      authUserId: session.authenticated!.authUserId,
      appId: appId,
      redirectUri: redirectUri,
      state: state,
    );
  }
}
