import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Asks the platform for an integrity token bound to one capture challenge's
/// [requestHash]. Returns null where none can be had; the server decides
/// whether a capture without a token is acceptable
/// (`VERILY_DEVICE_INTEGRITY_MODE`).
typedef DeviceIntegrityTokenSource = Future<String?> Function(
  String requestHash,
);

const _channel = MethodChannel('app.verily/device_integrity');
const _cloudProjectNumber = String.fromEnvironment(
  'VERILY_PLAY_INTEGRITY_CLOUD_PROJECT_NUMBER',
);

/// Play Integrity's Standard API on Android. Other platforms, and builds
/// without a Google Cloud project number, return null.
Future<String?> requestPlayIntegrityToken(String requestHash) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
  final projectNumber = int.tryParse(_cloudProjectNumber);
  if (projectNumber == null || projectNumber <= 0) return null;
  try {
    return await _channel.invokeMethod<String>('requestStandardToken', {
      'requestHash': requestHash,
      'cloudProjectNumber': projectNumber,
    });
  } on PlatformException catch (error) {
    // The server refuses the capture if a token is required; the reason stays
    // in the log, never in front of the person.
    debugPrint('Play Integrity token unavailable: ${error.code}');
    return null;
  }
}
