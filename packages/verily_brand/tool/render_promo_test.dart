// Renders Verily's launch reel to PNG frames on the test clock, so every run
// produces identical frames. `dart run tool/render_promo.dart` runs this and
// encodes the video; to render frames directly:
//
//   flutter test tool/render_promo_test.dart --dart-define=PROMO_OUT=<dir>
//
// Frames are 1920x1080 (a 960x540 stage at 2x) at 30 frames a second, named
// 00000.png onwards. PROMO_STILLS renders only the given comma-separated
// seconds, named by time (for example 12.5s.png), for review.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verily_brand/promo/promo_reel.dart';

import 'support/render_support.dart';

const String _out = String.fromEnvironment('PROMO_OUT');
const String _stills = String.fromEnvironment('PROMO_STILLS');
const double _pixelRatio = 2;

void main() {
  testWidgets('render the promo reel', (tester) async {
    if (_out.isEmpty) {
      markTestSkipped('Set --dart-define=PROMO_OUT=<dir> to render frames.');
      return;
    }
    await tester.runAsync(loadSkribbleFonts);
    tester.view
      ..physicalSize = kPromoStage * _pixelRatio
      ..devicePixelRatio = _pixelRatio;
    addTearDown(tester.view.reset);

    final time = ValueNotifier<double>(0);
    addTearDown(time.dispose);
    await tester.pumpWidget(
      ValueListenableBuilder<double>(
        valueListenable: time,
        builder: (context, value, _) => PromoReel(time: value),
      ),
    );

    const frameTime = Duration(microseconds: 1000000 ~/ PromoTimeline.fps);
    if (_stills.isNotEmpty) {
      for (final second in _stills.split(',').map(double.parse)) {
        time.value = second;
        await tester.pump(frameTime);
        await captureView(tester, '$_out/${second}s.png');
      }
      return;
    }
    final frames = (PromoTimeline.duration * PromoTimeline.fps).round();
    for (var frame = 0; frame < frames; frame++) {
      time.value = frame / PromoTimeline.fps;
      await tester.pump(frameTime);
      await captureView(
        tester,
        '$_out/${frame.toString().padLeft(5, '0')}.png',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 40)));
}
