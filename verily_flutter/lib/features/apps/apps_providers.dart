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

/// One page of an App's confirmation receipts, newest first.
@immutable
class AppConfirmationsPage {
  const AppConfirmationsPage({
    required this.items,
    required this.hasMore,
    this.loadingMore = false,
  });

  final List<AppConfirmationView> items;
  final bool hasMore;
  final bool loadingMore;

  AppConfirmationsPage copyWith({bool? loadingMore}) => AppConfirmationsPage(
    items: items,
    hasMore: hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
  );
}

/// Loads an App's append-only confirmation receipts a page at a time.
class AppConfirmationsController extends AsyncNotifier<AppConfirmationsPage> {
  AppConfirmationsController(this.appId);

  /// The server's page size for `listConfirmations`.
  static const pageSize = 50;

  final UuidValue appId;

  @override
  Future<AppConfirmationsPage> build() async {
    final page = await ref
        .read(appsRepositoryProvider)
        .listConfirmations(appId);
    return AppConfirmationsPage(items: page, hasMore: page.length == pageSize);
  }

  /// Appends the next older page. A failure keeps the rows already loaded
  /// and rethrows so the screen can say so.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final page = await ref
          .read(appsRepositoryProvider)
          .listConfirmations(appId, beforeId: current.items.last.id);
      state = AsyncData(
        AppConfirmationsPage(
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

final AsyncNotifierProviderFamily<
  AppConfirmationsController,
  AppConfirmationsPage,
  UuidValue
>
appConfirmationsProvider = AsyncNotifierProvider.autoDispose
    .family<AppConfirmationsController, AppConfirmationsPage, UuidValue>(
      AppConfirmationsController.new,
    );
