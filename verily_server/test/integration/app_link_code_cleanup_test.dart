import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/apps/linking/app_link_code_cleanup_future_call.dart';
import 'package:verily_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';
import 'test_tools/verily_fixtures.dart';

void main() {
  withServerpod('Given deep-link codes of different ages', (
    sessionBuilder,
    endpoints,
  ) {
    final creatorId = testId(0x731);
    final participantId = testId(0x732);
    final now = DateTime.utc(2026, 10, 21, 12);

    VerilyAppLinkCode code(UuidValue appId, String hash, DateTime createdAt) =>
        VerilyAppLinkCode(
          appId: appId,
          authUserId: participantId,
          codeHash: hash * 64,
          redirectUri: 'https://steps.example/verily',
          expiresAt: createdAt.add(const Duration(minutes: 5)),
          createdAt: createdAt,
        );

    test(
      'when cleanup runs then only codes expired a day ago are removed',
      () async {
        final session = sessionBuilder.build();
        await insertAccounts(session, {
          creatorId: 'Ada',
          participantId: 'Grace',
        });
        final app = await endpoints.verilyApp.createApp(
          signedIn(sessionBuilder, creatorId),
          name: 'Step Counter',
        );
        await VerilyAppLinkCode.db.insert(session, [
          code(app.app.id, 'a', now.subtract(const Duration(days: 3))),
          code(app.app.id, 'b', now.subtract(const Duration(hours: 25))),
          code(app.app.id, 'c', now.subtract(const Duration(hours: 2))),
          code(app.app.id, 'd', now.subtract(const Duration(minutes: 1))),
        ]);

        await AppLinkCodeCleanupFutureCall(
          clock: () => now,
        ).cleanup(session, AppLinkCodeCleanupTask(batchSize: 10));

        final left = await VerilyAppLinkCode.db.find(
          session,
          orderBy: (table) => table.createdAt,
        );
        expect([for (final row in left) row.codeHash[0]], ['c', 'd']);
        await expectLater(
          AppLinkCodeCleanupFutureCall().cleanup(
            session,
            AppLinkCodeCleanupTask(batchSize: 0),
          ),
          throwsArgumentError,
        );
      },
    );
  });
}
