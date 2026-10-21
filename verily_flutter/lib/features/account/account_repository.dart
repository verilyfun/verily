import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/core/api_client.dart';

/// Account-level operations: signing out and closing the account.
abstract interface class AccountRepository {
  /// Ends this device's session.
  Future<void> signOut();

  /// Closes the account after the person typed [confirmation] (`DELETE`).
  /// Returns when the closure took effect.
  Future<DateTime> closeAccount({required String confirmation});
}

class ServerpodAccountRepository implements AccountRepository {
  const ServerpodAccountRepository(this._client);

  final Client _client;

  @override
  Future<void> signOut() => _client.auth.signOutDevice();

  @override
  Future<DateTime> closeAccount({required String confirmation}) =>
      _client.accountLifecycle.closeAccount(confirmation: confirmation);
}

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => ServerpodAccountRepository(ref.watch(verilyClientProvider)),
);
