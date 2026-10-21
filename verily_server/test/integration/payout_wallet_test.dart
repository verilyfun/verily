import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/rewards/payout_wallet_challenge_cleanup_future_call.dart';
import 'package:verily_server/src/rewards/payout_wallet_service.dart';

import 'test_tools/serverpod_test_tools.dart';
import 'test_tools/verily_fixtures.dart';

Matcher _stateError(String message) => throwsA(
  isA<StateError>().having((error) => error.message, 'message', message),
);

void main() {
  withServerpod('Given a signed-in account linking a payout wallet', (
    sessionBuilder,
    endpoints,
  ) {
    final ownerId = testId(0x501);
    final otherId = testId(0x502);
    final wallet = TestWallet.fromSeed(51);
    final otherWallet = TestWallet.fromSeed(52);
    late TestSessionBuilder owner;
    late TestSessionBuilder other;

    setUp(() async {
      owner = signedIn(sessionBuilder, ownerId);
      other = signedIn(sessionBuilder, otherId);
      await insertAccounts(sessionBuilder.build(), {
        ownerId: 'Grace',
        otherId: 'Katherine',
      });
    });

    test('when signed out then wallet operations are refused', () async {
      await expectLater(
        endpoints.payoutWallet.getMine(sessionBuilder),
        throwsA(isA<ServerpodUnauthenticatedException>()),
      );
      await expectLater(
        endpoints.payoutWallet.createWalletLinkChallenge(
          sessionBuilder,
          walletAddress: wallet.address,
        ),
        throwsA(isA<ServerpodUnauthenticatedException>()),
      );
    });

    test(
      'when a challenge is requested then it names the wallet, a fresh '
      'nonce, and a five-minute window',
      () async {
        final before = DateTime.now().toUtc();

        final challenge = await endpoints.payoutWallet
            .createWalletLinkChallenge(owner, walletAddress: wallet.address);
        final second = await endpoints.payoutWallet.createWalletLinkChallenge(
          owner,
          walletAddress: wallet.address,
        );

        expect(challenge.walletAddress, wallet.address);
        expect(challenge.nonce.length, inInclusiveRange(16, 64));
        expect(second.nonce, isNot(challenge.nonce));
        final lines = challenge.message.split('\n');
        expect(lines[0], contains('wants you to link a Solana payout wallet'));
        expect(lines[1], wallet.address);
        expect(challenge.message, contains('Signing does not move any funds.'));
        expect(lines, contains('Nonce: ${challenge.nonce}'));
        expect(
          lines,
          contains(
            'Expiration Time: ${challenge.expiresAt.toIso8601String()}',
          ),
        );
        final lifetime = challenge.expiresAt.difference(before);
        expect(
          lifetime.inMilliseconds,
          inInclusiveRange(
            PayoutWalletService.challengeLifetime.inMilliseconds,
            (PayoutWalletService.challengeLifetime + const Duration(seconds: 5))
                .inMilliseconds,
          ),
        );
        expect(await endpoints.payoutWallet.getMine(owner), isNull);
      },
    );

    test(
      'when the address is not a Solana public key then it is refused',
      () async {
        await expectLater(
          endpoints.payoutWallet.createWalletLinkChallenge(
            owner,
            walletAddress: '11111',
          ),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test('when the wallet signs the challenge then it is linked', () async {
      final linked = await linkWallet(endpoints, owner, wallet);

      expect(linked.walletAddress, wallet.address);
      expect(
        linked.label,
        '${wallet.address.substring(0, 4)}…'
        '${wallet.address.substring(wallet.address.length - 4)}',
      );
      final mine = await endpoints.payoutWallet.getMine(owner);
      expect(mine!.walletAddress, wallet.address);
      expect(await endpoints.payoutWallet.getMine(other), isNull);
    });

    test('when another key signs the challenge then it is refused', () async {
      final challenge = await endpoints.payoutWallet.createWalletLinkChallenge(
        owner,
        walletAddress: wallet.address,
      );

      await expectLater(
        endpoints.payoutWallet.linkPayoutWallet(
          owner,
          walletAddress: wallet.address,
          nonce: challenge.nonce,
          signature: otherWallet.sign(challenge.message),
        ),
        _stateError('The wallet signature could not be verified.'),
      );
      expect(await endpoints.payoutWallet.getMine(owner), isNull);

      // The failed attempt did not spend the challenge.
      final linked = await endpoints.payoutWallet.linkPayoutWallet(
        owner,
        walletAddress: wallet.address,
        nonce: challenge.nonce,
        signature: wallet.sign(challenge.message),
      );
      expect(linked.walletAddress, wallet.address);
    });

    test(
      'when the signature signs different text then it is refused',
      () async {
        final challenge = await endpoints.payoutWallet
            .createWalletLinkChallenge(
              owner,
              walletAddress: wallet.address,
            );

        await expectLater(
          endpoints.payoutWallet.linkPayoutWallet(
            owner,
            walletAddress: wallet.address,
            nonce: challenge.nonce,
            signature: wallet.sign('${challenge.message}\nExtra: line'),
          ),
          _stateError('The wallet signature could not be verified.'),
        );
      },
    );

    test('when the signature is malformed then it is refused', () async {
      final challenge = await endpoints.payoutWallet.createWalletLinkChallenge(
        owner,
        walletAddress: wallet.address,
      );

      await expectLater(
        endpoints.payoutWallet.linkPayoutWallet(
          owner,
          walletAddress: wallet.address,
          nonce: challenge.nonce,
          signature: '11111',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('when a nonce is reused then the second link is refused', () async {
      final challenge = await endpoints.payoutWallet.createWalletLinkChallenge(
        owner,
        walletAddress: wallet.address,
      );
      final signature = wallet.sign(challenge.message);
      await endpoints.payoutWallet.linkPayoutWallet(
        owner,
        walletAddress: wallet.address,
        nonce: challenge.nonce,
        signature: signature,
      );

      await expectLater(
        endpoints.payoutWallet.linkPayoutWallet(
          owner,
          walletAddress: wallet.address,
          nonce: challenge.nonce,
          signature: signature,
        ),
        _stateError('This wallet link request is no longer valid.'),
      );
    });

    test('when the challenge has expired then the link is refused', () async {
      final challenge = await endpoints.payoutWallet.createWalletLinkChallenge(
        owner,
        walletAddress: wallet.address,
      );
      final later = PayoutWalletService(
        clock: () => challenge.expiresAt.add(const Duration(seconds: 1)),
      );

      await expectLater(
        later.link(
          sessionBuilder.build(),
          authUserId: ownerId,
          walletAddress: wallet.address,
          nonce: challenge.nonce,
          signature: wallet.sign(challenge.message),
        ),
        _stateError('This wallet link request is no longer valid.'),
      );
      expect(await endpoints.payoutWallet.getMine(owner), isNull);
    });

    test(
      'when a nonce is presented by another account or for another wallet '
      'then it is refused',
      () async {
        final challenge = await endpoints.payoutWallet
            .createWalletLinkChallenge(owner, walletAddress: wallet.address);

        await expectLater(
          endpoints.payoutWallet.linkPayoutWallet(
            other,
            walletAddress: wallet.address,
            nonce: challenge.nonce,
            signature: wallet.sign(challenge.message),
          ),
          _stateError('This wallet link request is no longer valid.'),
        );
        await expectLater(
          endpoints.payoutWallet.linkPayoutWallet(
            owner,
            walletAddress: otherWallet.address,
            nonce: challenge.nonce,
            signature: otherWallet.sign(challenge.message),
          ),
          _stateError('This wallet link request is no longer valid.'),
        );
      },
    );

    test(
      'when the wallet already belongs to another account then it is refused',
      () async {
        await linkWallet(endpoints, owner, wallet);

        await expectLater(
          linkWallet(endpoints, other, wallet),
          _stateError('This wallet is linked to another account.'),
        );
        expect(await endpoints.payoutWallet.getMine(other), isNull);
      },
    );

    test('when a new wallet is linked then it replaces the old one', () async {
      await linkWallet(endpoints, owner, wallet);
      final replaced = await linkWallet(endpoints, owner, otherWallet);

      expect(replaced.walletAddress, otherWallet.address);
      final rows = await PayoutWallet.db.find(
        sessionBuilder.build(),
        where: (table) => table.authUserId.equals(ownerId),
      );
      expect(rows.single.walletAddress, otherWallet.address);
      // The released address can now be linked by someone else.
      final reused = await linkWallet(endpoints, other, wallet);
      expect(reused.walletAddress, wallet.address);
    });

    test(
      'when too many challenges are requested then the next is refused',
      () async {
        for (var i = 0; i < PayoutWalletService.maxChallengesPerWindow; i++) {
          await endpoints.payoutWallet.createWalletLinkChallenge(
            owner,
            walletAddress: wallet.address,
          );
        }

        await expectLater(
          endpoints.payoutWallet.createWalletLinkChallenge(
            owner,
            walletAddress: wallet.address,
          ),
          _stateError(
            'Too many wallet link requests. Wait a few minutes and try again.',
          ),
        );
      },
    );

    test('when the account is blocked then no challenge is issued', () async {
      final session = sessionBuilder.build();
      final account = (await AuthUser.db.findById(session, ownerId))!;
      await AuthUser.db.updateRow(session, account.copyWith(blocked: true));

      await expectLater(
        endpoints.payoutWallet.createWalletLinkChallenge(
          owner,
          walletAddress: wallet.address,
        ),
        _stateError('An active account is required.'),
      );
    });

    test(
      'when the cleanup call runs then only long-expired challenges are '
      'deleted',
      () async {
        final session = sessionBuilder.build();
        final now = DateTime.now().toUtc();
        final stale = now.subtract(
          payoutWalletChallengeRetention + const Duration(hours: 1),
        );
        await PayoutWalletLinkChallenge.db.insert(session, [
          PayoutWalletLinkChallenge(
            authUserId: ownerId,
            walletAddress: wallet.address,
            nonce: 'stale-nonce-0000000001',
            message: 'stale',
            createdAt: stale.subtract(const Duration(minutes: 5)),
            expiresAt: stale,
          ),
          PayoutWalletLinkChallenge(
            authUserId: ownerId,
            walletAddress: wallet.address,
            nonce: 'recent-nonce-000000001',
            message: 'recently expired',
            createdAt: now.subtract(const Duration(minutes: 10)),
            expiresAt: now.subtract(const Duration(minutes: 5)),
          ),
        ]);
        final live = await endpoints.payoutWallet.createWalletLinkChallenge(
          owner,
          walletAddress: wallet.address,
        );

        await endpoints.futureCalls.payoutWalletChallengeCleanup.cleanup(
          sessionBuilder,
          PayoutWalletChallengeCleanupTask(batchSize: 100),
        );

        final remaining = await PayoutWalletLinkChallenge.db.find(
          session,
          where: (table) => table.authUserId.equals(ownerId),
        );
        expect(
          remaining.map((challenge) => challenge.nonce).toSet(),
          {'recent-nonce-000000001', live.nonce},
        );
      },
    );

    test(
      'when a wallet row is written directly then the address is checked',
      () async {
        final session = sessionBuilder.build();
        final now = DateTime.now().toUtc();

        await expectLater(
          session.db.transaction((transaction) async {
            await PayoutWallet.db.insertRow(
              session,
              PayoutWallet(
                authUserId: ownerId,
                walletAddress: 'not a wallet',
                linkedAt: now,
                updatedAt: now,
              ),
              transaction: transaction,
            );
          }),
          throwsA(isA<DatabaseQueryException>()),
        );
      },
    );
  });
}
