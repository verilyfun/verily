import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Native settings a store review, a verifier, or a person relies on. Each one
/// is a single line in a platform file that is easy to lose in a template
/// upgrade.
void main() {
  final androidManifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();
  final androidBuild = File('android/app/build.gradle.kts').readAsStringSync();
  final iosInfo = File('ios/Runner/Info.plist').readAsStringSync();
  final iosProject = File(
    'ios/Runner.xcodeproj/project.pbxproj',
  ).readAsStringSync();

  test('Android and iOS are locked to portrait', () {
    expect(androidManifest, contains('android:screenOrientation="portrait"'));
    expect(
      RegExp(
        r'<key>UISupportedInterfaceOrientations</key>\s*<array>\s*'
        r'<string>UIInterfaceOrientationPortrait</string>\s*</array>',
      ).hasMatch(iosInfo),
      isTrue,
    );
    expect(
      RegExp(
        r'<key>UISupportedInterfaceOrientations~ipad</key>\s*<array>\s*'
        r'<string>UIInterfaceOrientationPortrait</string>\s*</array>',
      ).hasMatch(iosInfo),
      isTrue,
    );
  });

  test('the public identity is fun.verily.app on both platforms', () {
    expect(androidBuild, contains('applicationId = "fun.verily.app"'));
    // `fun` is a Kotlin keyword, so the code namespace differs on purpose.
    expect(androidBuild, contains('namespace = "app.verily"'));
    expect(
      File(
        'android/app/src/main/kotlin/app/verily/MainActivity.kt',
      ).readAsStringSync(),
      startsWith('package app.verily\n'),
    );
    expect(
      RegExp(
        r'PRODUCT_BUNDLE_IDENTIFIER = fun\.verily\.app;',
      ).allMatches(iosProject),
      hasLength(3),
    );
    expect(androidManifest, contains('android:label="Verily"'));
    expect(
      RegExp(
        r'<key>CFBundleDisplayName</key>\s*<string>Verily</string>',
      ).hasMatch(iosInfo),
      isTrue,
    );
  });

  test(
    'Android asks only for what live capture needs, and keeps data home',
    () {
      final permissions = RegExp(
        r'android:name="android\.permission\.([A-Z_]+)"',
      ).allMatches(androidManifest).map((match) => match.group(1)).toSet();
      expect(permissions, {
        'INTERNET',
        'CAMERA',
        'RECORD_AUDIO',
        'ACCESS_FINE_LOCATION',
        'ACCESS_COARSE_LOCATION',
      });
      expect(androidManifest, contains('android:allowBackup="false"'));
      expect(
        androidManifest,
        contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
      );
      expect(androidManifest, contains('android:scheme="solana-wallet"'));
      expect(androidManifest, contains('android.intent.action.PROCESS_TEXT'));
    },
  );

  test('iOS explains each sensor in plain words', () {
    for (final key in [
      'NSCameraUsageDescription',
      'NSMicrophoneUsageDescription',
      'NSLocationWhenInUseUsageDescription',
    ]) {
      final description = RegExp(
        '<key>$key</key>\\s*<string>([^<]+)</string>',
      ).firstMatch(iosInfo)?.group(1);
      expect(description, isNotNull, reason: key);
      expect(description, startsWith('Verily '), reason: key);
    }
  });

  test('both platforms accept "Verify with Verily" links', () {
    expect(
      androidManifest,
      contains(
        '<meta-data\n'
        '                android:name="flutter_deeplinking_enabled"\n'
        '                android:value="true"/>',
      ),
    );
    for (final host in ['r', 'link']) {
      expect(
        RegExp(
          'android:scheme="verily"\\s*android:host="$host"',
        ).hasMatch(androidManifest),
        isTrue,
        reason: 'verily://$host',
      );
    }
    expect(
      androidManifest,
      contains('<intent-filter android:autoVerify="true">'),
    );
    for (final prefix in ['/r/', '/link']) {
      expect(
        RegExp(
          r'android:scheme="https"\s*android:host="verily\.fun"\s*'
          'android:pathPrefix="$prefix"',
        ).hasMatch(androidManifest),
        isTrue,
        reason: 'https://verily.fun$prefix',
      );
    }
    expect(androidManifest, contains('android:launchMode="singleTop"'));

    expect(
      RegExp(
        r'<key>CFBundleURLSchemes</key>\s*<array>\s*<string>verily</string>',
      ).hasMatch(iosInfo),
      isTrue,
    );
    expect(
      RegExp(r'<key>FlutterDeepLinkingEnabled</key>\s*<true/>').hasMatch(
        iosInfo,
      ),
      isTrue,
    );
    expect(
      File('ios/Runner/Runner.entitlements').readAsStringSync(),
      contains('<string>applinks:verily.fun</string>'),
    );
    expect(
      RegExp(
        r'CODE_SIGN_ENTITLEMENTS = Runner/Runner\.entitlements;',
      ).allMatches(iosProject),
      hasLength(3),
    );
  });
}
