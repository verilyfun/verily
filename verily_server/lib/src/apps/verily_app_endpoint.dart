import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:verily_server/src/apps/verily_app_service.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// Creator management of Verily Apps, and a participant's own subject.
///
/// Every method derives the caller from the authenticated session; creator
/// methods re-check App ownership on each call. Apps themselves never use
/// this endpoint: they call `POST /api/v1/confirmations` with an App key.
class VerilyAppEndpoint extends Endpoint {
  VerilyAppEndpoint({VerilyAppService? service})
    : service = service ?? VerilyAppService();

  final VerilyAppService service;

  @override
  bool get requireLogin => true;

  Future<List<VerilyAppView>> listApps(Session session) {
    return service.listApps(
      session,
      authUserId: session.authenticated!.authUserId,
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
}
