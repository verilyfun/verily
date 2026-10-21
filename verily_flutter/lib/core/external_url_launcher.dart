import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [uri] outside Verily, in the app that handles it, and says whether
/// anything opened.
///
/// Used to hand a person back to another app (a verification request's or a
/// link request's redirect). Tests replace it, so nothing reaches a browser.
typedef ExternalUrlLauncher = Future<bool> Function(Uri uri);

/// Opens [uri] in the app that registered it (or the browser for `https`).
///
/// A platform refusal (no app handles the address) is reported as `false`
/// so the page can offer the way back by hand instead of failing.
Future<bool> launchExternalUrl(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on PlatformException catch (error) {
    debugPrint('Opening an external address failed: ${error.code}');
    return false;
  }
}

final externalUrlLauncherProvider = Provider<ExternalUrlLauncher>(
  (ref) => launchExternalUrl,
);
