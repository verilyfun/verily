import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';

/// Produces unlinkable abuse-correlation keys without publishing source IDs.
///
/// The secret is an operational key, not an application constant. Rotation is
/// represented by [keyEpoch], allowing a bounded overlap window while old
/// pseudonyms expire from the risk history.
final class AbusePseudonymizer {
  AbusePseudonymizer({required String secret, required this.keyEpoch})
    : _secret = utf8.encode(secret) {
    if (_secret.length < 32) {
      throw ArgumentError('Abuse pseudonym secrets need at least 32 bytes.');
    }

    if (!_epochPattern.hasMatch(keyEpoch)) {
      throw ArgumentError('Use a bounded abuse pseudonym key epoch.');
    }
  }

  static final _epochPattern = RegExp(r'^[a-z0-9][a-z0-9._-]{0,31}$');

  final List<int> _secret;
  final String keyEpoch;

  String account(String stableAccountId) => _derive(
    namespace: 'account',
    value: stableAccountId,
  );

  String creator(String stableCreatorId) => _derive(
    namespace: 'creator',
    value: stableCreatorId,
  );

  String action(String stableActionId) => _derive(
    namespace: 'action',
    value: stableActionId,
  );

  String attempt(String stableAttemptId) => _derive(
    namespace: 'attempt',
    value: stableAttemptId,
  );

  String device(String deviceBinding) => _derive(
    namespace: 'device',
    value: deviceBinding,
  );

  String scene(String sceneFingerprint) => _derive(
    namespace: 'scene',
    value: sceneFingerprint,
  );

  /// Coarsens a location before deriving an opaque correlation key.
  ///
  /// A 0.01-degree cell is roughly one kilometre north-to-south. This is only
  /// an abuse signal: it is not a public location, geofence decision, or proof
  /// that multiple people were physically together.
  String coarseLocation({required double latitude, required double longitude}) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      throw ArgumentError('Invalid location for abuse correlation.');
    }

    const cellSizeDegrees = 0.01;
    final latitudeCell = math.min(
      17999,
      ((latitude + 90) / cellSizeDegrees).floor(),
    );
    final longitudeCell = math.min(
      35999,
      ((longitude + 180) / cellSizeDegrees).floor(),
    );

    return _derive(
      namespace: 'coarse-location-v1',
      value: '$latitudeCell:$longitudeCell',
    );
  }

  String _derive({required String namespace, required String value}) {
    final normalized = value.trim();

    if (normalized.isEmpty || normalized.length > 1024) {
      throw ArgumentError('Invalid abuse-correlation source value.');
    }

    // Security: namespaces stop an account pseudonym from being compared with
    // the same source bytes used as a device or scene identifier.
    final message = utf8.encode(
      'verily-abuse-v1\n$keyEpoch\n$namespace\n$normalized',
    );

    return Hmac(sha256, _secret).convert(message).toString();
  }
}
