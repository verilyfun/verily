import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:verily_server/src/account/account_access.dart';
import 'package:verily_server/src/action_verification/app_attest/app_attest_verifier.dart';
import 'package:verily_server/src/action_verification/app_attest/apple_device_client.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// Device-wide restrictions are controlled by dedicated operators, never by
/// the participant who supplies the token. Evidence reviewers cannot clear a ban.
const deviceCheckManageScope = Scope('device-check.manage');

/// Staff query/update APIs for Apple's two persistent device bits. Both flags
/// are set explicitly to avoid read/modify/write races. A fresh token must be
/// obtained from the affected phone; App Attest key IDs are not device IDs.
class DeviceCheckEndpoint extends Endpoint {
  DeviceCheckEndpoint({AppleDeviceClient? apple})
    : apple =
          apple ??
          switch (AppAttestPolicy.fromEnvironment()) {
            final policy? => HttpAppleDeviceClient.fromEnvironment(policy),
            null => null,
          };

  final AppleDeviceClient? apple;

  @override
  bool get requireLogin => true;

  @override
  Set<Scope> get requiredScopes => {deviceCheckManageScope};

  Future<DeviceCheckBits> query(
    Session session, {
    required String deviceToken,
  }) async {
    await AccountAccess.requireActive(
      session,
      session.authenticated!.authUserId,
    );
    final client = _requireClient(deviceToken);
    try {
      final bits = await client.queryBits(session, deviceToken);
      return DeviceCheckBits(
        banned: bits.banned,
        reviewRequired: bits.reviewRequired,
      );
    } on AppleDeviceUnavailable {
      throw _unavailable();
    }
  }

  Future<void> update(
    Session session, {
    required String deviceToken,
    required bool banned,
    required bool reviewRequired,
    required String note,
  }) async {
    final operator = session.authenticated!.authUserId;
    await AccountAccess.requireActive(session, operator);
    final client = _requireClient(deviceToken);
    final reason = note.trim();
    if (reason.isEmpty || reason.length > 1000) {
      throw ArgumentError('A bounded audit note is required.');
    }
    // Persist intent before the external side effect. An Apple timeout may
    // mean the update happened; completedAt stays null and operators must query.
    final audit = await DeviceCheckAudit.db.insertRow(
      session,
      DeviceCheckAudit(
        operatorAuthUserId: operator,
        tokenHash: sha256.convert(deviceToken.codeUnits).toString(),
        banned: banned,
        reviewRequired: reviewRequired,
        note: reason,
        createdAt: DateTime.now().toUtc(),
      ),
    );
    try {
      await client.updateBits(
        session,
        deviceToken,
        AppleDeviceBits(banned: banned, reviewRequired: reviewRequired),
      );
    } on AppleDeviceUnavailable {
      throw _unavailable();
    }
    await DeviceCheckAudit.db.updateRow(
      session,
      audit.copyWith(completedAt: DateTime.now().toUtc()),
    );
  }

  AppleDeviceClient _requireClient(String token) {
    if (!validDeviceCheckToken(token)) {
      throw ArgumentError('Invalid device token.');
    }
    return apple ?? (throw _unavailable());
  }
}

AppAttestException _unavailable() => AppAttestException(
  problem: AppAttestProblem.unavailable,
  message: 'This device restriction could not be checked. Try again later.',
);
