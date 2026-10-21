import 'package:flutter_test/flutter_test.dart';
import 'package:verily_brand/promo/launch_cover.dart';
import 'package:verily_brand/promo/promo_reel.dart';
import 'package:verily_brand/src/stamp_motion.dart';

import '../tool/support/render_support.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadSkribbleFonts();
  });

  testWidgets('the reel renders every beat without errors', (tester) async {
    tester.view
      ..physicalSize = kPromoStage * 2
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    const beats = [
      0.0,
      0.8,
      1.7,
      2.6,
      3.5,
      4.6,
      5.4,
      6.9,
      8.2,
      8.6,
      9.5,
      11.0,
      12.4,
      15.9,
      16.4,
      17.1,
      18.6,
      21.0,
      21.7,
      23.4,
      23.9,
      24.9,
      25.6,
      27.1,
      28.0,
      29.0,
      29.99,
    ];
    for (final time in beats) {
      await tester.pumpWidget(PromoReel(time: time));
      expect(tester.takeException(), isNull, reason: 'at $time s');
    }
  });

  test('the timeline is in order and fits the reel', () {
    final cues = [
      PromoTimeline.hookWrite,
      PromoTimeline.strike,
      PromoTimeline.hookLockup,
      PromoTimeline.createHeadline,
      PromoTimeline.pinDrop,
      PromoTimeline.radius,
      PromoTimeline.doHeadline,
      PromoTimeline.proveHeadline,
      PromoTimeline.seal,
      PromoTimeline.paidHeadline,
      PromoTimeline.stamp,
      PromoTimeline.payout,
      PromoTimeline.endLockup,
    ];
    for (var i = 1; i < cues.length; i++) {
      expect(cues[i].start, greaterThanOrEqualTo(cues[i - 1].start));
    }
    expect(cues.last.end, lessThan(PromoTimeline.duration));
    expect(PromoTimeline.repTimes.last, lessThan(PromoTimeline.doIt.end));
    expect(
      PromoTimeline.stampImpact,
      PromoTimeline.stamp.start +
          PromoTimeline.stamp.length * StampMotion.impact,
    );
  });

  testWidgets('the cover renders on paper and on night', (tester) async {
    tester.view
      ..physicalSize = kLaunchCoverSize
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final night in [false, true]) {
      await tester.pumpWidget(LaunchCover(night: night));
      expect(tester.takeException(), isNull);
    }
  });
}
