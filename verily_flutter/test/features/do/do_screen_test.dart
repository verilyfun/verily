import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/widgets/reward_chip.dart';
import 'package:verily_flutter/features/do/do_screen.dart';
import 'package:verily_flutter/features/evidence/location_service.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import 'support/do_harness.dart';
import 'support/fakes.dart';

/// A feed with one action of each proof kind.
final ActionOpportunity _bridge = actionFixture(id: 1, reward: rewardFixture());
final ActionOpportunity _squats = actionFixture(
  id: 2,
  title: 'Twenty squats',
  requirements: [
    videoRequirement(
      movementKind: ActionMovementKind.squats,
      targetRepetitions: 20,
    ),
  ],
  // Not funded yet: no chip.
  reward: rewardFixture(status: RewardPoolStatus.awaitingFunding),
);
final ActionOpportunity _bar = actionFixture(
  id: 3,
  title: 'Visit the bar',
  requirements: [venueCodeRequirement()],
);
final ActionOpportunity _loaf = actionFixture(
  id: 4,
  title: 'Bake a loaf',
  creator: 'Slopper',
  requirements: [appRequirement()],
);
final ActionOpportunity _spin = actionFixture(
  id: 5,
  title: 'Spin around',
  requirements: [motionRequirement()],
  myAttempt: attemptFixture(
    actionId: 5,
    status: ActionAttemptStatus.verifying,
  ),
);

final List<ActionOpportunity> _feed = [_bridge, _squats, _bar, _loaf, _spin];

Finder _card(ActionOpportunity action) =>
    find.byKey(VerilyTestKeys.doActionCard(action.id.toString()));

Finder _inCard(ActionOpportunity action, Finder matching) =>
    find.descendant(of: _card(action), matching: matching);

Future<DoFakes> _pumpDo(
  WidgetTester tester, {
  List<ActionOpportunity>? available,
  List<ActionOpportunity> nearby = const [],
  FakeLocationService? location,
}) async {
  final fakes = DoFakes(
    actions: FakeActionRepository(
      available: available ?? _feed,
      nearby: nearby,
    ),
    location: location,
  );
  await pumpDoRoutes(
    tester,
    initialLocation: '/do',
    overrides: fakes.overrides,
  );
  await settle(tester);
  return fakes;
}

Future<void> _tapFilter(WidgetTester tester, String name) async {
  final chip = find.byKey(VerilyTestKeys.doFilter(name));
  await tester.ensureVisible(chip);
  await tester.tap(chip);
  await settle(tester);
}

void main() {
  group('DoScreen feed', () {
    testWidgets('shows each live action with its creator and status', (
      tester,
    ) async {
      await _pumpDo(tester);

      expect(find.byType(DoScreen), findsOneWidget);
      for (final action in _feed) {
        await tester.ensureVisible(_card(action));
        expect(_inCard(action, find.text(action.title)), findsOneWidget);
      }
      expect(_inCard(_loaf, find.text('by Slopper')), findsOneWidget);
      expect(
        _inCard(_spin, find.text('You: Checking your proof')),
        findsOneWidget,
      );
    });

    testWidgets('labels who vouches for each action', (tester) async {
      await _pumpDo(tester);

      expect(
        _inCard(_bridge, find.text('Verified on your phone')),
        findsOneWidget,
      );
      await tester.ensureVisible(_card(_loaf));
      expect(_inCard(_loaf, find.text('Confirmed by Slopper')), findsOneWidget);
      expect(
        _inCard(_loaf, find.text('Verified on your phone')),
        findsNothing,
      );
    });

    testWidgets('shows a reward chip only for a funded pool', (tester) async {
      await _pumpDo(tester);

      expect(_inCard(_bridge, find.byType(RewardChip)), findsOneWidget);
      expect(_inCard(_bridge, find.text('5 USDC · in escrow')), findsOneWidget);
      await tester.ensureVisible(_card(_squats));
      expect(_inCard(_squats, find.byType(RewardChip)), findsNothing);
      expect(_inCard(_bar, find.byType(RewardChip)), findsNothing);
    });

    testWidgets('filters by how an action is proven', (tester) async {
      await _pumpDo(tester);

      Future<void> expectOnly(String filter, List<ActionOpportunity> shown) {
        return _tapFilter(tester, filter).then((_) {
          for (final action in _feed) {
            expect(
              _card(action),
              shown.contains(action) ? findsOneWidget : findsNothing,
              reason: '${action.title} under $filter',
            );
          }
        });
      }

      await expectOnly('place', [_bridge]);
      await expectOnly('movement', [_squats, _spin]);
      await expectOnly('venueCode', [_bar]);
      await expectOnly('apps', [_loaf]);
      await expectOnly('all', _feed);
    });

    testWidgets('a filter with no match offers everything again', (
      tester,
    ) async {
      await _pumpDo(tester, available: [_bridge]);

      await _tapFilter(tester, 'apps');
      expect(find.text('Nothing matches that yet'), findsOneWidget);

      await tester.tap(find.text('Show all actions'));
      await settle(tester);
      expect(_card(_bridge), findsOneWidget);
    });

    testWidgets('an empty feed invites the first action', (tester) async {
      await _pumpDo(tester, available: const []);

      expect(find.text('Nothing to do here yet'), findsOneWidget);
      await tester.tap(find.text('Post an action'));
      await settle(tester);
      expect(find.text('editor: new'), findsOneWidget);
    });

    testWidgets('a failed load can be retried', (tester) async {
      final actions = FakeActionRepository(available: [_bridge])
        ..availableError = Exception('offline');
      final fakes = DoFakes(actions: actions);
      await pumpDoRoutes(
        tester,
        initialLocation: '/do',
        overrides: fakes.overrides,
      );
      await settle(tester);

      expect(find.text("We couldn't load actions"), findsOneWidget);
      expect(find.textContaining('offline'), findsNothing);

      actions.availableError = null;
      await tester.tap(find.text('Try again'));
      await settle(tester);
      expect(_card(_bridge), findsOneWidget);
    });

    testWidgets('opens an action from its card', (tester) async {
      await _pumpDo(tester);

      await tester.tap(_inCard(_bar, find.text('Visit the bar')));
      await settle(tester);

      expect(find.byType(DoScreen), findsNothing);
      expect(find.text('Visit the bar'), findsOneWidget);
      expect(find.byKey(VerilyTestKeys.actionStart), findsOneWidget);
    });

    testWidgets('the map shows a pin for each action with a place', (
      tester,
    ) async {
      await _pumpDo(tester);

      await tester.tap(find.text('Map'));
      await settle(tester);

      expect(find.byKey(VerilyTestKeys.doMap), findsOneWidget);
      expect(
        find.byKey(VerilyTestKeys.doMapPin(_bridge.id.toString())),
        findsOneWidget,
      );
      expect(
        find.byKey(VerilyTestKeys.doMapPin(_bar.id.toString())),
        findsNothing,
      );
    });
  });

  group('DoScreen nearby', () {
    testWidgets('explains the location read before making it', (
      tester,
    ) async {
      final fakes = await _pumpDo(tester, nearby: [_bridge]);

      await _tapFilter(tester, 'nearby');

      final dialog = find.byType(AlertDialog);
      expect(
        find.descendant(
          of: dialog,
          matching: find.text('Find actions near you'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: dialog,
          matching: find.text(
            'We use your approximate location once to find actions near '
            'you. Verily rounds it and never stores it.',
          ),
        ),
        findsOneWidget,
      );
      expect(fakes.location.approximateCalls, 0);

      await tester.tap(find.byKey(VerilyTestKeys.doNearbyContinue));
      await settle(tester);

      expect(fakes.location.approximateCalls, 1);
      expect(fakes.location.preciseCalls, 0);
      expect(fakes.actions.nearbyQuery?.latitude, fakes.location.fix.latitude);
      expect(_card(_bridge), findsOneWidget);
      // 0.004° of latitude north of the pin.
      expect(_inCard(_bridge, find.text('440 m away')), findsOneWidget);
    });

    testWidgets('not now is remembered for the session', (tester) async {
      final fakes = await _pumpDo(tester);

      await _tapFilter(tester, 'nearby');
      await tester.tap(find.byKey(VerilyTestKeys.doNearbyNotNow));
      await settle(tester);

      expect(fakes.location.approximateCalls, 0);
      expect(find.text('Nearby needs your location'), findsOneWidget);

      await _tapFilter(tester, 'all');
      await _tapFilter(tester, 'nearby');
      expect(find.byKey(VerilyTestKeys.doNearbyContinue), findsNothing);
      expect(find.text('Nearby needs your location'), findsOneWidget);
    });

    testWidgets('a permanent denial points to settings', (tester) async {
      final fakes = await _pumpDo(
        tester,
        location: FakeLocationService(
          approximateFailure: LocationFailure.deniedForever,
        ),
      );

      await _tapFilter(tester, 'nearby');
      await tester.tap(find.byKey(VerilyTestKeys.doNearbyContinue));
      await settle(tester);

      expect(find.text('Location is off for Verily'), findsOneWidget);
      await tester.tap(find.text('Open settings'));
      await settle(tester);
      expect(fakes.location.openSettingsCalls, 1);

      // After settings, the same panel can read the location again.
      fakes.location.approximateFailure = null;
      await tester.tap(find.text('Use my location'));
      await settle(tester);
      expect(find.text('Nothing nearby yet'), findsOneWidget);
    });

    testWidgets('a one-off denial asks again', (tester) async {
      await _pumpDo(
        tester,
        location: FakeLocationService(
          approximateFailure: LocationFailure.denied,
        ),
      );

      await _tapFilter(tester, 'nearby');
      await tester.tap(find.byKey(VerilyTestKeys.doNearbyContinue));
      await settle(tester);

      expect(find.text("Location wasn't allowed"), findsOneWidget);
      expect(find.text('Use my location'), findsOneWidget);
      expect(find.text('Open settings'), findsNothing);
    });
  });

  group('DoScreen fit', () {
    for (final brightness in Brightness.values) {
      testWidgets('fits a Seeker at 1.3x text (${brightness.name})', (
        tester,
      ) async {
        final fakes = DoFakes(
          actions: FakeActionRepository(available: _feed),
        );
        await pumpDoRoutes(
          tester,
          initialLocation: '/do',
          overrides: fakes.overrides,
          brightness: brightness,
          physicalSize: seekerPhysicalSize,
          devicePixelRatio: seekerPixelRatio,
          textScale: 1.3,
          useAppTypeface: true,
        );
        await settle(tester);

        expect(tester.takeException(), isNull);
        for (final action in _feed) {
          await tester.ensureVisible(_card(action));
          await tester.pump();
          expect(tester.takeException(), isNull);
        }
        for (final name in ['all', 'nearby', 'place', 'apps']) {
          await tester.ensureVisible(find.byKey(VerilyTestKeys.doFilter(name)));
          await tester.pump();
        }
        expect(tester.takeException(), isNull);
      });
    }
  });
}
