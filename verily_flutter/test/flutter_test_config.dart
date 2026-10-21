import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:verily_flutter/app/theme/verily_icon_catalog.dart';

/// Runs before every test file under `test/`.
///
/// Registers Verily's icon catalog as `main` does, so Skribble widgets that
/// look icons up by name draw what the app draws.
///
/// The debug-only development overlay listens to the accelerometer for its
/// shake gesture. Tests have no sensor plugin, so for every test its channels
/// answer with a silent stream rather than a missing-plugin error.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  registerVerilyIconCatalog();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/sensors/method'),
        (call) async => null,
      )
      ..setMockStreamHandler(
        const EventChannel('dev.fluttercommunity.plus/sensors/accelerometer'),
        MockStreamHandler.inline(onListen: (arguments, events) {}),
      );
  });
  await testMain();
}
