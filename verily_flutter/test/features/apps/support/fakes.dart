import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/apps/apps_repository.dart';

import '../../create/hub/support/fakes.dart';

const fixtureSecret = 'AbCdEfGhIjKlMnOpQrStUvWxYz0123456789-_AbCdE';

VerilyAppKeyView fixtureKey(
  String keyId, {
  DateTime? lastUsedAt,
  DateTime? revokedAt,
}) => VerilyAppKeyView(
  keyId: keyId,
  createdAt: fixtureNow.subtract(const Duration(days: 9)),
  lastUsedAt: lastUsedAt,
  revokedAt: revokedAt,
);

VerilyAppView fixtureApp({
  int index = 1,
  String name = 'Sunrise Run Club',
  VerilyAppStatus status = VerilyAppStatus.active,
  List<VerilyAppKeyView>? keys,
  int boundActionCount = 1,
}) => VerilyAppView(
  id: fixtureId(500 + index),
  name: name,
  websiteUrl: 'https://sunrise.example',
  status: status,
  keys: keys ?? [fixtureKey('0123456789abcdef')],
  boundActionCount: boundActionCount,
  redirectUris: const [],
  createdAt: fixtureNow.subtract(const Duration(days: 10)),
  revokedAt: status == VerilyAppStatus.revoked ? fixtureNow : null,
);

VerilyAppCredential fixtureCredential(VerilyAppView app, String keyId) =>
    VerilyAppCredential(
      app: app,
      keyId: keyId,
      secret: 'vly_$keyId.$fixtureSecret',
    );

AppConfirmationView fixtureConfirmation(
  int index, {
  AppConfirmationOutcome outcome = AppConfirmationOutcome.accepted,
  String reasonCode = 'app_confirmed',
  ActionAttemptStatus? attemptStatus = ActionAttemptStatus.verified,
}) => AppConfirmationView(
  id: fixtureId(9000 + index),
  eventId: 'evt_$index',
  actionKey: 'action-1',
  outcome: outcome,
  reasonCode: reasonCode,
  occurredAt: fixtureNow.subtract(Duration(minutes: index)),
  receivedAt: fixtureNow.subtract(Duration(minutes: index)),
  attemptStatus: attemptStatus,
);

/// An in-memory [AppsRepository] that records every change.
class FakeAppsRepository implements AppsRepository {
  FakeAppsRepository({
    List<VerilyAppView>? apps,
    this.confirmationPages = const [],
  }) : apps = apps ?? [fixtureApp()];

  List<VerilyAppView> apps;

  /// Pages returned by successive `listConfirmations` calls.
  List<List<AppConfirmationView>> confirmationPages;

  /// When set, `createApp` throws it.
  Object? createError;

  final created = <({String name, String? websiteUrl})>[];
  final keysCreated = <UuidValue>[];
  final keysRevoked = <({UuidValue appId, String keyId})>[];
  final appsRevoked = <UuidValue>[];
  final confirmationRequests = <({UuidValue appId, UuidValue? beforeId})>[];
  var _nextKey = 0;

  String _keyId() =>
      'fedcba98765432${(_nextKey++).toRadixString(16).padLeft(2, '0')}';

  @override
  Future<List<VerilyAppView>> listApps() async => apps;

  final appsFetched = <UuidValue>[];

  @override
  Future<VerilyAppView> getApp(UuidValue appId) async {
    appsFetched.add(appId);
    for (final app in apps) {
      if (app.id == appId) return app;
    }
    throw ResourceNotFoundException(
      resource: MissingResource.app,
      message: 'That app was not found.',
    );
  }

  @override
  Future<VerilyAppCredential> createApp({
    required String name,
    String? websiteUrl,
  }) async {
    created.add((name: name, websiteUrl: websiteUrl));
    if (createError case final error?) {
      Error.throwWithStackTrace(error, StackTrace.current);
    }
    final keyId = _keyId();
    final app = fixtureApp(
      index: apps.length + 1,
      name: name,
      keys: [fixtureKey(keyId)],
      boundActionCount: 0,
    );
    apps = [...apps, app];
    return fixtureCredential(app, keyId);
  }

  @override
  Future<VerilyAppCredential> createKey(UuidValue appId) async {
    keysCreated.add(appId);
    final keyId = _keyId();
    final app = apps.firstWhere((item) => item.id == appId);
    final updated = app.copyWith(keys: [...app.keys, fixtureKey(keyId)]);
    apps = [
      for (final item in apps)
        if (item.id == appId) updated else item,
    ];
    return fixtureCredential(updated, keyId);
  }

  @override
  Future<VerilyAppView> revokeKey({
    required UuidValue appId,
    required String keyId,
  }) async {
    keysRevoked.add((appId: appId, keyId: keyId));
    final app = apps.firstWhere((item) => item.id == appId);
    final updated = app.copyWith(
      keys: [
        for (final key in app.keys)
          if (key.keyId == keyId) key.copyWith(revokedAt: fixtureNow) else key,
      ],
    );
    apps = [
      for (final item in apps)
        if (item.id == appId) updated else item,
    ];
    return updated;
  }

  @override
  Future<VerilyAppView> revokeApp(UuidValue appId) async {
    appsRevoked.add(appId);
    final app = apps.firstWhere((item) => item.id == appId);
    final updated = app.copyWith(
      status: VerilyAppStatus.revoked,
      revokedAt: fixtureNow,
    );
    apps = [
      for (final item in apps)
        if (item.id == appId) updated else item,
    ];
    return updated;
  }

  @override
  Future<List<AppConfirmationView>> listConfirmations(
    UuidValue appId, {
    UuidValue? beforeId,
  }) async {
    confirmationRequests.add((appId: appId, beforeId: beforeId));
    final index = confirmationRequests.length - 1;
    return index < confirmationPages.length ? confirmationPages[index] : [];
  }

  @override
  Future<VerilyAppLinkView> linkApp(UuidValue appId) =>
      throw UnimplementedError('linkApp is not used by the Apps pages.');

  /// Thrown by the next settings change while set, then cleared.
  Object? settingsError;

  /// Pages returned by successive `listWebhookDeliveries` calls.
  List<List<AppWebhookDeliveryView>> deliveryPages = const [];

  final webhookUrlsSet = <String?>[];
  final secretsRotated = <UuidValue>[];
  final redirectUrisSet = <List<String>>[];
  final deliveryRequests = <({UuidValue appId, UuidValue? beforeId})>[];

  void _failIfAsked() {
    if (settingsError case final error?) {
      settingsError = null;
      Error.throwWithStackTrace(error, StackTrace.current);
    }
  }

  VerilyAppView _update(
    UuidValue appId,
    VerilyAppView Function(VerilyAppView app) change,
  ) {
    final updated = change(apps.firstWhere((item) => item.id == appId));
    apps = [
      for (final item in apps)
        if (item.id == appId) updated else item,
    ];
    return updated;
  }

  @override
  Future<VerilyAppView> setWebhookUrl({
    required UuidValue appId,
    required String? webhookUrl,
  }) async {
    webhookUrlsSet.add(webhookUrl);
    _failIfAsked();
    // The generated copyWith clears a field given an explicit null.
    return _update(appId, (app) => app.copyWith(webhookUrl: webhookUrl));
  }

  @override
  Future<VerilyAppWebhookSecret> rotateWebhookSecret(UuidValue appId) async {
    secretsRotated.add(appId);
    _failIfAsked();
    final app = _update(
      appId,
      (app) => app.copyWith(webhookSecretVersion: app.webhookSecretVersion + 1),
    );
    return VerilyAppWebhookSecret(
      appId: appId,
      version: app.webhookSecretVersion,
      secret: 'whsec_${fixtureSecret}v${app.webhookSecretVersion}',
      previousSecretValidUntil: app.webhookSecretVersion > 1
          ? fixtureNow.add(const Duration(hours: 24))
          : null,
    );
  }

  @override
  Future<VerilyAppView> setRedirectUris({
    required UuidValue appId,
    required List<String> redirectUris,
  }) async {
    redirectUrisSet.add(redirectUris);
    _failIfAsked();
    return _update(appId, (app) => app.copyWith(redirectUris: redirectUris));
  }

  @override
  Future<List<AppWebhookDeliveryView>> listWebhookDeliveries(
    UuidValue appId, {
    UuidValue? beforeId,
  }) async {
    deliveryRequests.add((appId: appId, beforeId: beforeId));
    final index = deliveryRequests.length - 1;
    return index < deliveryPages.length ? deliveryPages[index] : [];
  }
}

AppWebhookDeliveryView fixtureDelivery(
  int index, {
  String eventType = 'attempt.verified',
  bool succeeded = true,
  int? statusCode = 200,
  String? errorCode,
  int attemptNumber = 1,
  AppEventStatus? eventStatus = AppEventStatus.delivered,
}) => AppWebhookDeliveryView(
  id: fixtureId(7000 + index),
  eventId: 'vev_$index',
  eventType: eventType,
  attemptNumber: attemptNumber,
  requestedAt: fixtureNow.subtract(Duration(minutes: index)),
  durationMilliseconds: 120 + index,
  statusCode: statusCode,
  errorCode: errorCode,
  succeeded: succeeded,
  eventStatus: eventStatus,
);
