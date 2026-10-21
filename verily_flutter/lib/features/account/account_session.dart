import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import 'package:verily_flutter/core/api_client.dart';

/// The scope a person needs to decide proof that waits for review.
const evidenceReviewScope = 'evidence.review';

/// Who is signed in, as far as the app needs to know.
///
/// Serverpod owns authentication; this only widens its session into a
/// watchable value. Nothing here decides authorization: the server checks
/// every call, so a stale value can hide or show a screen but never grants
/// access to data.
@immutable
class AccountSession {
  const AccountSession({this.authUserId, this.scopes = const {}});

  const AccountSession.signedOut() : authUserId = null, scopes = const {};

  final UuidValue? authUserId;
  final Set<String> scopes;

  bool get isSignedIn => authUserId != null;

  /// Whether this account may open the review queue.
  bool get canReviewEvidence => scopes.contains(evidenceReviewScope);

  @override
  bool operator ==(Object other) =>
      other is AccountSession &&
      other.authUserId == authUserId &&
      setEquals(other.scopes, scopes);

  @override
  int get hashCode => Object.hash(authUserId, Object.hashAllUnordered(scopes));
}

/// The current session, rebuilt whenever Serverpod's session changes.
final accountSessionProvider = Provider<AccountSession>((ref) {
  final auth = ref.watch(verilyClientProvider).auth;
  final listenable = auth.authInfoListenable;
  void changed() => ref.invalidateSelf();
  listenable.addListener(changed);
  ref.onDispose(() => listenable.removeListener(changed));

  final info = auth.authInfo;
  if (info == null) return const AccountSession.signedOut();
  return AccountSession(authUserId: info.authUserId, scopes: info.scopeNames);
});
