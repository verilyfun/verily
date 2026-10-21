// Renders Verily's 1280x800 launch cover, on paper and on night paper.
// `dart run tool/render_promo.dart` runs this; to render directly:
//
//   flutter test tool/render_cover_test.dart --dart-define=COVER_OUT=<dir>
//
// Writes verily-cover.png and verily-cover-night.png.
import 'package:flutter_test/flutter_test.dart';
import 'package:verily_brand/promo/launch_cover.dart';

import 'support/render_support.dart';

const String _out = String.fromEnvironment('COVER_OUT');

void main() {
  testWidgets('render the launch cover', (tester) async {
    if (_out.isEmpty) {
      markTestSkipped('Set --dart-define=COVER_OUT=<dir> to render.');
      return;
    }
    await tester.runAsync(loadSkribbleFonts);
    tester.view
      ..physicalSize = kLaunchCoverSize
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final (night, name) in const [
      (false, 'verily-cover.png'),
      (true, 'verily-cover-night.png'),
    ]) {
      await tester.pumpWidget(LaunchCover(night: night));
      await captureView(tester, '$_out/$name');
    }
  });
}
