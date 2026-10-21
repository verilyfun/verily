import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';
import 'package:serverpod_auth_idp_server/providers/google.dart';
import 'package:verily_server/src/generated/protocol.dart';

const accountClosureConfirmation = 'DELETE';

typedef RevokeAccountTokens = Future<void> Function(
  Session session,
  UuidValue authUserId,
);

/// Closes an account: blocks sign-in, purges identity, and keeps the
/// verification and payout audit history the account produced.
class AccountLifecycleService {
  AccountLifecycleService({
    RevokeAccountTokens? revokeTokens,
    DateTime Function()? clock,
  }) : revokeTokens = revokeTokens ?? _revokeTokens,
       clock = clock ?? (() => DateTime.now().toUtc());

  final RevokeAccountTokens revokeTokens;
  final DateTime Function() clock;

  Future<DateTime> closeAccount(
    Session session, {
    required UuidValue authUserId,
    required String confirmation,
  }) async {
    if (confirmation.trim() != accountClosureConfirmation) {
      throw ArgumentError.value(
        confirmation,
        'confirmation',
        'Account closure was not confirmed.',
      );
    }
    final closedAt = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        final authUser = await AuthUser.db.findFirstRow(
          session,
          where: (table) => table.id.equals(authUserId),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (authUser == null) throw StateError('Account was not found.');

        final existing = await AccountClosure.db.findFirstRow(
          session,
          where: (table) => table.authUserId.equals(authUserId),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (existing != null) return existing.identityPurgedAt;

        final now = clock().toUtc();
        await EmailAccount.db.deleteWhere(
          session,
          where: (table) => table.authUserId.equals(authUserId),
          transaction: transaction,
        );
        await GoogleAccount.db.deleteWhere(
          session,
          where: (table) => table.authUserId.equals(authUserId),
          transaction: transaction,
        );
        await UserProfile.db.deleteWhere(
          session,
          where: (table) => table.authUserId.equals(authUserId),
          transaction: transaction,
        );
        // A payout wallet identifies its owner. Payouts already released keep
        // their own recipient snapshot; unreleased ones are held because the
        // account is no longer active.
        await PayoutWalletLinkChallenge.db.deleteWhere(
          session,
          where: (table) => table.authUserId.equals(authUserId),
          transaction: transaction,
        );
        await PayoutWallet.db.deleteWhere(
          session,
          where: (table) => table.authUserId.equals(authUserId),
          transaction: transaction,
        );
        // Nobody can answer appeals or manage a closed creator's live
        // actions, so they stop taking new participants. Escrowed rewards
        // stay on chain and the creator's wallet can still reclaim them.
        await ActionDefinition.db.updateWhere(
          session,
          columnValues: (table) => [
            table.status(ActionDefinitionStatus.paused),
            table.pausedAt(now),
            table.updatedAt(now),
          ],
          where: (table) =>
              table.creatorAuthUserId.equals(authUserId) &
              table.status.equals(ActionDefinitionStatus.active),
          transaction: transaction,
          noReturn: true,
        );
        await AuthUser.db.updateRow(
          session,
          authUser.copyWith(blocked: true, scopeNames: const {}),
          transaction: transaction,
        );
        await AccountClosure.db.insertRow(
          session,
          AccountClosure(
            authUserId: authUserId,
            status: AccountClosureStatus.closed,
            requestedAt: now,
            identityPurgedAt: now,
          ),
          transaction: transaction,
        );
        return now;
      },
    );
    await revokeTokens(session, authUserId);
    return closedAt;
  }
}

Future<void> _revokeTokens(Session session, UuidValue authUserId) {
  return AuthServices.instance.tokenManager.revokeAllTokens(
    session,
    authUserId: authUserId,
  );
}
