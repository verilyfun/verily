import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs before every test file under `test/`.
///
/// The debug-only development overlay listens to the accelerometer for its
/// shake gesture. Tests have no sensor plugin, so for every test its channels
/// answer with a silent stream rather than a missing-plugin error.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
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
