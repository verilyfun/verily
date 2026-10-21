import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/action_verification_service.dart';
import 'package:verily_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';
import 'test_tools/verily_fixtures.dart';

/// A point in Westminster, about 40 m from Big Ben.
const _queryLatitude = 51.5010;
const _queryLongitude = -0.1250;

void main() {
  withServerpod('Given live and hidden actions around London', (
    sessionBuilder,
    endpoints,
  ) {
    final creatorId = testId(0x301);
    final participantId = testId(0x302);
    late TestSessionBuilder creator;
    late TestSessionBuilder participant;

    Future<ActionOpportunity> place(
      String key,
      double latitude,
      double longitude, {
      DateTime? opensAt,
      DateTime? closesAt,
      int? maxVerifiedCompletions,
    }) => endpoints.actionVerification.createAction(
      creator,
      actionRequest(
        actionKey: key,
        maxVerifiedCompletions: maxVerifiedCompletions,
        requirements: [
          locationRequirement(latitude: latitude, longitude: longitude),
        ],
      ).copyWith(opensAt: opensAt, closesAt: closesAt),
    );

    setUp(() async {
      creator = signedIn(sessionBuilder, creatorId);
      participant = signedIn(sessionBuilder, participantId);
      final session = sessionBuilder.build();
      await insertAccounts(session, {
        creatorId: 'Ada',
        participantId: 'Grace',
      });
      final now = DateTime.now().toUtc();

      // Live actions, nearest first from the query point.
      await place('big-ben', 51.5007, -0.1246);
      await endpoints.actionVerification.createAction(
        creator,
        actionRequest(
          actionKey: 'eye-and-tower',
          requirements: [
            locationRequirement(
              key: 'london-eye',
              latitude: 51.5033,
              longitude: -0.1196,
            ),
            locationRequirement(
              key: 'tower-of-london',
              latitude: 51.5081,
              longitude: -0.0759,
            ),
          ],
        ),
      );
      await place('tower-bridge', 51.5055, -0.0754);
      await place('greenwich', 51.4769, -0.0005);
      await place('oxford', 51.7520, -1.2577);
      await place('paris', 48.8566, 2.3522);
      // A live action with no place is never "nearby".
      await endpoints.actionVerification.createAction(
        creator,
        actionRequest(
          actionKey: 'code-only',
          requirements: [qrRequirement(qrCode: 'verily-code-only-venue')],
        ),
      );

      // Hidden actions right next to the query point.
      await endpoints.actionVerification.saveActionDraft(
        creator,
        actionRequest(
          actionKey: 'draft-nearby',
          requirements: [
            locationRequirement(latitude: 51.5011, longitude: -0.1251),
          ],
        ),
      );
      final paused = await place('paused-nearby', 51.5012, -0.1249);
      await endpoints.actionVerification.pauseAction(
        creator,
        actionId: paused.id,
        expectedRevision: paused.revision,
      );
      await place(
        'closed-nearby',
        51.5009,
        -0.1252,
        closesAt: now.subtract(const Duration(hours: 1)),
      );
      await place(
        'opens-later-nearby',
        51.5008,
        -0.1251,
        opensAt: now.add(const Duration(days: 1)),
        closesAt: now.add(const Duration(days: 2)),
      );
      final full = await place(
        'full-nearby',
        51.5013,
        -0.1248,
        maxVerifiedCompletions: 1,
      );
      final fullRow = await ActionDefinition.db.findById(session, full.id);
      await ActionDefinition.db.updateRow(
        session,
        fullRow!.copyWith(verifiedCompletions: 1),
      );
    });

    Future<List<String>> nearby({
      required double radiusKm,
      double latitude = _queryLatitude,
      double longitude = _queryLongitude,
      int limit = 30,
    }) async => [
      for (final action in await endpoints.actionVerification.listNearbyActions(
        participant,
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        limit: limit,
      ))
        action.actionKey,
    ];

    test(
      'when searching 5 km then only open placed actions return, '
      'nearest first',
      () async {
        expect(await nearby(radiusKm: 5), [
          'big-ben',
          'eye-and-tower',
          'tower-bridge',
        ]);
      },
    );

    test(
      'when the radius grows then farther live actions join in order',
      () async {
        expect(await nearby(radiusKm: 10), [
          'big-ben',
          'eye-and-tower',
          'tower-bridge',
          'greenwich',
        ]);
      },
    );

    test('when the radius exceeds 50 km then it is clamped', () async {
      final results = await nearby(radiusKm: 500);

      expect(results, contains('greenwich'));
      // Oxford is about 80 km away and Paris much farther.
      expect(results, isNot(contains('oxford')));
      expect(results, isNot(contains('paris')));
    });

    test('when the radius is tiny then it is widened to 100 m', () async {
      expect(await nearby(radiusKm: 0.001), ['big-ben']);
    });

    test('when a limit is given then it is bounded to 1-50', () async {
      expect(await nearby(radiusKm: 10, limit: 1), ['big-ben']);
      expect(await nearby(radiusKm: 10, limit: 0), ['big-ben']);
      expect(await nearby(radiusKm: 10, limit: 500), hasLength(4));
    });

    test('when nothing is near then the list is empty', () async {
      // Mid-Atlantic.
      expect(
        await nearby(latitude: 40, longitude: -40, radiusKm: 50),
        isEmpty,
      );
    });

    test('when listed then the viewer sees the public place only', () async {
      final results = await endpoints.actionVerification.listNearbyActions(
        participant,
        latitude: _queryLatitude,
        longitude: _queryLongitude,
        radiusKm: 0.6,
        limit: 10,
      );

      expect(results.map((action) => action.actionKey), [
        'big-ben',
        'eye-and-tower',
      ]);
      final bigBen = results.first;
      expect(bigBen.viewerIsCreator, isFalse);
      expect(bigBen.creatorDisplayName, 'Ada');
      expect(bigBen.myAttempt, isNull);
      expect(bigBen.requirements.single.latitude, closeTo(51.5007, 1e-9));
      expect(results.last.requirements, hasLength(2));
    });

    test(
      'when coordinates or the radius are invalid then the search is '
      'refused',
      () async {
        for (final (latitude, longitude) in [
          (91.0, 0.0),
          (-91.0, 0.0),
          (0.0, 181.0),
          (0.0, -181.0),
        ]) {
          await expectLater(
            nearby(latitude: latitude, longitude: longitude, radiusKm: 5),
            throwsArgumentError,
          );
        }
        for (final radiusKm in [0.0, -1.0]) {
          await expectLater(nearby(radiusKm: radiusKm), throwsArgumentError);
        }
        // NaN and infinity cannot cross the JSON protocol, but the service
        // still refuses them from any in-process caller.
        final service = ActionVerificationService();
        for (final (latitude, longitude, radiusKm) in [
          (double.nan, 0.0, 5.0),
          (0.0, double.infinity, 5.0),
          (0.0, 0.0, double.nan),
          (0.0, 0.0, double.infinity),
        ]) {
          await expectLater(
            service.listNearbyActions(
              sessionBuilder.build(),
              authUserId: participantId,
              latitude: latitude,
              longitude: longitude,
              radiusKm: radiusKm,
            ),
            throwsArgumentError,
          );
        }
      },
    );

    test('when searching then the caller location is never stored', () async {
      final session = sessionBuilder.build();
      final rulesBefore = await ActionLocationRule.db.count(session);

      await nearby(radiusKm: 10);

      expect(await ActionLocationRule.db.count(session), rulesBefore);
      expect(await ActionEvidence.db.count(session), 0);
      expect(await ActionAttempt.db.count(session), 0);
      final stored = await session.db.unsafeQuery(
        'SELECT count(*) FROM "verily_action_location_rule" '
        'WHERE ST_DWithin(location, '
        "ST_GeogFromText('SRID=4326;POINT(-0.125 51.501)'), 1)",
      );
      expect(stored.single.single, 0);
    });

    test('when signed out then nearby discovery requires sign-in', () async {
      await expectLater(
        endpoints.actionVerification.listNearbyActions(
          sessionBuilder,
          latitude: _queryLatitude,
          longitude: _queryLongitude,
          radiusKm: 5,
          limit: 10,
        ),
        throwsA(isA<ServerpodUnauthenticatedException>()),
      );
    });
  });
}
