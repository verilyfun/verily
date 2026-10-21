import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/apps/apps_repository.dart';

/// An App holds at most this many active keys, so one can be rotated in
/// before the old one is revoked.
const maxActiveAppKeys = 2;

/// The caller's Apps, newest first as the server returns them.
final FutureProvider<List<VerilyAppView>> verilyAppsProvider =
    FutureProvider.autoDispose(
      (ref) => ref.watch(appsRepositoryProvider).listApps(),
    );

/// One of the caller's Apps, for its own page.
final FutureProviderFamily<VerilyAppView, UuidValue> verilyAppProvider =
    FutureProvider.autoDispose.family<VerilyAppView, UuidValue>(
      (ref, appId) => ref.watch(appsRepositoryProvider).getApp(appId),
    );

/// Reloads the App list and [appId]'s own page after a change to it.
void refreshApp(WidgetRef ref, UuidValue appId) => ref
  ..invalidate(verilyAppsProvider)
  ..invalidate(verilyAppProvider(appId));

/// The keys of [app] that still work.
Iterable<VerilyAppKeyView> activeKeysOf(VerilyAppView app) =>
    app.keys.where((key) => key.revokedAt == null);

/// Whether [app] may issue another key.
bool canIssueKey(VerilyAppView app) =>
    app.status == VerilyAppStatus.active &&
    activeKeysOf(app).length < maxActiveAppKeys;

/// The complete bearer credential to hand to the App's owner, exactly as the
/// server documents it: `vly_<keyId>.<secret>`. The server already sends the
/// complete credential in `secret`; it is shown once and never stored here.
String appBearerKey(VerilyAppCredential credential) {
  assert(
    credential.secret.startsWith('vly_${credential.keyId}.'),
    'The server sends the complete vly_<keyId>.<secret> credential.',
  );
  return credential.secret;
}

/// The public part of a key, safe to show and log.
String appKeyLabel(String keyId) => 'vly_$keyId';

/// The rows of an append-only App log loaded so far, newest first.
@immutable
class AppLogPage<T> {
  const AppLogPage({
    required this.items,
    required this.hasMore,
    this.loadingMore = false,
  });

  final List<T> items;
  final bool hasMore;
  final bool loadingMore;

  AppLogPage<T> copyWith({bool? loadingMore}) => AppLogPage<T>(
    items: items,
    hasMore: hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
  );
}

/// One page of an App's confirmation receipts.
typedef AppConfirmationsPage = AppLogPage<AppConfirmationView>;

/// One page of the calls Verily made to an App's webhook.
typedef AppDeliveriesPage = AppLogPage<AppWebhookDeliveryView>;

/// Loads one of an App's append-only logs a page at a time, newest first,
/// paging backwards by the last row's id.
abstract class AppLogController<T> extends AsyncNotifier<AppLogPage<T>> {
  AppLogController(this.appId);

  final UuidValue appId;

  /// The page size the repository asks the server for; a shorter page is the
  /// last one.
  int get pageSize;

  /// The page of rows older than [beforeId], or the newest page.
  Future<List<T>> fetch(AppsRepository apps, {UuidValue? beforeId});

  /// The id the next page is fetched before.
  UuidValue idOf(T item);

  @override
  Future<AppLogPage<T>> build() async {
    final page = await fetch(ref.read(appsRepositoryProvider));
    return AppLogPage<T>(items: page, hasMore: page.length == pageSize);
  }

  /// Appends the next older page. A failure keeps the rows already loaded
  /// and rethrows so the screen can say so.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final page = await fetch(
        ref.read(appsRepositoryProvider),
        beforeId: idOf(current.items.last),
      );
      state = AsyncData(
        AppLogPage<T>(
          items: [...current.items, ...page],
          hasMore: page.length == pageSize,
        ),
      );
    } on Object {
      state = AsyncData(current.copyWith(loadingMore: false));
      rethrow;
    }
  }
}

/// An App's confirmation receipts.
class AppConfirmationsController extends AppLogController<AppConfirmationView> {
  AppConfirmationsController(super.appId);

  @override
  int get pageSize => AppPageSizes.confirmations;

  @override
  Future<List<AppConfirmationView>> fetch(
    AppsRepository apps, {
    UuidValue? beforeId,
  }) => apps.listConfirmations(appId, beforeId: beforeId);

  @override
  UuidValue idOf(AppConfirmationView item) => item.id;
}

final AsyncNotifierProviderFamily<
  AppConfirmationsController,
  AppConfirmationsPage,
  UuidValue
>
appConfirmationsProvider = AsyncNotifierProvider.autoDispose
    .family<AppConfirmationsController, AppConfirmationsPage, UuidValue>(
      AppConfirmationsController.new,
    );

/// The calls Verily made to an App's webhook: events and pull checks.
class AppDeliveriesController extends AppLogController<AppWebhookDeliveryView> {
  AppDeliveriesController(super.appId);

  @override
  int get pageSize => AppPageSizes.deliveries;

  @override
  Future<List<AppWebhookDeliveryView>> fetch(
    AppsRepository apps, {
    UuidValue? beforeId,
  }) => apps.listWebhookDeliveries(appId, beforeId: beforeId);

  @override
  UuidValue idOf(AppWebhookDeliveryView item) => item.id;
}

final AsyncNotifierProviderFamily<
  AppDeliveriesController,
  AppDeliveriesPage,
  UuidValue
>
appDeliveriesProvider = AsyncNotifierProvider.autoDispose
    .family<AppDeliveriesController, AppDeliveriesPage, UuidValue>(
      AppDeliveriesController.new,
    );
