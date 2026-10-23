import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';
import 'package:verily_evidence/verily_evidence.dart';
import 'package:verily_server/src/account/account_access.dart';
import 'package:verily_server/src/action_verification/app_attest/app_attest_receipt.dart';
import 'package:verily_server/src/action_verification/app_attest/app_attest_verifier.dart';
import 'package:verily_server/src/action_verification/app_attest/apple_device_client.dart';
import 'package:verily_server/src/action_verification/device_integrity_verifier.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// How long an iPhone has to attest its key after asking for a challenge.
/// Attestation calls Apple's servers, which normally answer in seconds.
const appAttestChallengeLifetime = Duration(minutes: 5);

/// Registration challenges one account may request an hour.
const maxAppAttestChallengesPerHour = 10;

/// What an App Attest assertion over one capture proved.
final class AppAttestCaptureVerdict {
  const AppAttestCaptureVerdict.trusted({
    required Uint8List this.publicKey,
    this.reviewReasonCode,
  }) : reasonCode = AppAttestReason.valid;

  const AppAttestCaptureVerdict.untrusted(this.reasonCode)
    : publicKey = null,
      reviewReasonCode = null;

  final String reasonCode;

  /// The registered key that made the assertion, `0x04 ‖ X ‖ Y`; set only
  /// when the assertion is trusted.
  final Uint8List? publicKey;
  final String? reviewReasonCode;

  bool get trusted => publicKey != null;
}

/// Registers iPhones' App Attest keys and checks the assertions they sign
/// captures with.
///
/// A key is registered once per account and install, against a single-use
/// challenge. Every later assertion must come from that account's key and
/// carry a counter larger than any accepted before, so an assertion is never
/// accepted twice.
class AppAttestService {
  AppAttestService({
    this.verifier,
    this.apple,
    AppAttestReceiptVerifier? receiptVerifier,
    this.riskThreshold = 10,
    DateTime Function()? clock,
    math.Random? random,
  }) : receiptVerifier = receiptVerifier ?? AppAttestReceiptVerifier(),
       clock = clock ?? (() => DateTime.now().toUtc()),
       _random = random ?? math.Random.secure();

  /// Reads the policy from `VERILY_APPLE_TEAM_ID`, `VERILY_IOS_BUNDLE_ID`,
  /// and `VERILY_APP_ATTEST_ENVIRONMENT`. Without a team id App Attest is off.
  factory AppAttestService.fromEnvironment() => AppAttestService(
    verifier: switch (AppAttestPolicy.fromEnvironment()) {
      final policy? => AppAttestVerifier(policy: policy),
      null => null,
    },
    apple: switch (AppAttestPolicy.fromEnvironment()) {
      final policy? => HttpAppleDeviceClient.fromEnvironment(policy),
      null => null,
    },
  );

  /// Null when this server does not accept App Attest keys.
  final AppAttestVerifier? verifier;
  final AppAttestReceiptVerifier receiptVerifier;
  final AppleDeviceClient? apple;

  /// Ten attested keys in 30 days holds automatic verification; tune using
  /// production observations. It is a review signal, never an automatic ban.
  final int riskThreshold;
  final DateTime Function() clock;
  final math.Random _random;

  /// Issues the single-use challenge an iPhone attests its key against.
  Future<AppAttestChallengeView> beginRegistration(
    Session session, {
    required UuidValue authUserId,
  }) async {
    _requireVerifier();
    final now = clock().toUtc();
    final nonce = base64Url
        .encode(List<int>.generate(32, (_) => _random.nextInt(256)))
        .replaceAll('=', '');
    final expiresAt = now.add(appAttestChallengeLifetime);
    final challenge = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        await AccountAccess.requireActive(
          session,
          authUserId,
          transaction: transaction,
        );
        final recent = await AppAttestChallenge.db.count(
          session,
          where: (table) =>
              table.authUserId.equals(authUserId) &
              (table.createdAt > now.subtract(const Duration(hours: 1))),
          transaction: transaction,
        );
        if (recent >= maxAppAttestChallengesPerHour) {
          throw AppAttestException(
            problem: AppAttestProblem.rateLimited,
            message: 'Please wait before setting up this phone again.',
          );
        }
        return AppAttestChallenge.db.insertRow(
          session,
          AppAttestChallenge(
            authUserId: authUserId,
            nonce: nonce,
            expiresAt: expiresAt,
            createdAt: now,
          ),
          transaction: transaction,
        );
      },
    );
    return AppAttestChallengeView(
      id: challenge.id!,
      challenge: nonce,
      expiresAt: expiresAt,
    );
  }

  /// Verifies [attestationObject] (base64) for the key Apple named [keyId]
  /// (base64), made against [challengeId], and registers the key to the
  /// caller.
  ///
  /// The challenge is consumed whatever the attestation says. Registering a
  /// key the caller already holds is a no-op that keeps its counter; a key
  /// another account holds is refused, as Apple's guidance requires.
  Future<void> registerKey(
    Session session, {
    required UuidValue authUserId,
    required UuidValue challengeId,
    required String keyId,
    required String attestationObject,
  }) async {
    final verifier = _requireVerifier();
    if (keyId.length > _maxEncodedKeyId ||
        attestationObject.length > _maxEncodedAttestation) {
      throw ArgumentError('The App Attest registration is too large.');
    }
    final keyDigest = _decodeKeyId(keyId);
    final Uint8List attestation;
    try {
      attestation = base64Decode(attestationObject.trim());
    } on FormatException {
      throw _keyRejected();
    }
    if (keyDigest == null) throw _keyRejected();

    final now = clock().toUtc();
    final challenge = await DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        await AccountAccess.requireActive(
          session,
          authUserId,
          transaction: transaction,
        );
        final row = await AppAttestChallenge.db.findFirstRow(
          session,
          where: (table) =>
              table.id.equals(challengeId) &
              table.authUserId.equals(authUserId),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (row == null || row.usedAt != null || !row.expiresAt.isAfter(now)) {
          return null;
        }
        return AppAttestChallenge.db.updateRow(
          session,
          row.copyWith(usedAt: now),
          transaction: transaction,
        );
      },
    );
    if (challenge == null) {
      throw AppAttestException(
        problem: AppAttestProblem.challengeInvalid,
        message: 'That setup request expired. Try again.',
      );
    }

    final verdict = verifier.verifyAttestation(
      attestationObject: attestation,
      keyId: keyDigest,
      clientDataHash: appAttestRegistrationClientDataHash(challenge.nonce),
      now: now,
    );
    final attested = verdict.key;
    if (attested == null) {
      session.log(
        'App Attest registration refused (${verdict.reasonCode}).',
        level: LogLevel.info,
      );
      throw _keyRejected();
    }

    final registeredId = capturePublicKeyId(attested.publicKey);
    final AppAttestReceipt receipt;
    try {
      receipt = receiptVerifier.verify(
        receipt: attested.receipt,
        appId: '${verifier.policy.teamId}.${verifier.policy.bundleId}',
        publicKey: attested.publicKey,
        now: now,
        refreshed: false,
      );
    } on FormatException {
      throw _keyRejected();
    }
    await DatabaseUtil.runInTransactionOrSavepoint(session.db, null, (
      transaction,
    ) async {
      final existing = await AppAttestKey.db.findFirstRow(
        session,
        where: (table) => table.keyId.equals(registeredId),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (existing != null) {
        if (existing.authUserId == authUserId) return;
        session.log(
          'App Attest registration refused: the key belongs to another '
          'account.',
          level: LogLevel.warning,
        );
        throw _keyRejected();
      }
      await AppAttestKey.db.insertRow(
        session,
        AppAttestKey(
          authUserId: authUserId,
          keyId: registeredId,
          publicKey: base64Encode(attested.publicKey),
          environment: verifier.policy.environment,
          signCount: 0,
          certificateChain: [
            for (final certificate in attested.certificateChain)
              base64Encode(certificate),
          ],
          receipt: base64Encode(attested.receipt),
          receiptCreatedAt: receipt.createdAt,
          receiptRefreshAfter: receipt.notBefore,
          receiptNotBefore: receipt.notBefore,
          receiptExpiresAt: receipt.expiresAt,
          validationCategory: attested.validationCategory,
          bundleVersion: attested.bundleVersion,
          registeredAt: now,
        ),
        transaction: transaction,
      );
    });
  }

  /// Checks the [assertion] (base64) the caller's key [keyId] (base64) made
  /// over [clientData], and records its counter so it is never accepted
  /// again.
  Future<AppAttestCaptureVerdict> verifyCaptureAssertion(
    Session session, {
    required UuidValue authUserId,
    required String keyId,
    required String assertion,
    required List<int> clientData,
    required DateTime now,
    String? deviceCheckToken,
  }) async {
    if (deviceCheckToken != null && !validDeviceCheckToken(deviceCheckToken)) {
      return const AppAttestCaptureVerdict.untrusted(AppAttestReason.malformed);
    }
    final verifier = this.verifier;
    if (verifier == null) {
      return const AppAttestCaptureVerdict.untrusted(
        AppAttestReason.unconfigured,
      );
    }
    final keyDigest = keyId.length > _maxEncodedKeyId
        ? null
        : _decodeKeyId(keyId);
    if (keyDigest == null) {
      return const AppAttestCaptureVerdict.untrusted(
        AppAttestReason.keyUnknown,
      );
    }
    // Apple's identifier is already the key's SHA-256; rows store it as hex.
    final key = await AppAttestKey.db.findFirstRow(
      session,
      where: (table) =>
          table.keyId.equals(_hex(keyDigest)) &
          table.authUserId.equals(authUserId),
    );
    if (key == null) {
      return const AppAttestCaptureVerdict.untrusted(
        AppAttestReason.keyUnknown,
      );
    }
    // A key from the other environment cannot be checked against this one.
    if (key.environment != verifier.policy.environment) {
      return const AppAttestCaptureVerdict.untrusted(
        AppAttestReason.environmentMismatch,
      );
    }
    final Uint8List assertionBytes;
    try {
      assertionBytes = base64Decode(assertion.trim());
    } on FormatException {
      return const AppAttestCaptureVerdict.untrusted(AppAttestReason.malformed);
    }
    final publicKey = base64Decode(key.publicKey);
    final verdict = verifier.verifyAssertion(
      assertion: assertionBytes,
      clientData: deviceCheckToken == null
          ? clientData
          : appAttestDeviceClientData(clientData, deviceCheckToken),
      publicKey: publicKey,
      previousCounter: key.signCount,
    );
    final counter = verdict.counter;
    if (counter == null) {
      return AppAttestCaptureVerdict.untrusted(verdict.reasonCode);
    }

    // Two submissions may race with assertions from one key: the row lock
    // lets only the first to reach each counter through.
    return DatabaseUtil.runInTransactionOrSavepoint(
      session.db,
      null,
      (transaction) async {
        final locked = await AppAttestKey.db.findFirstRow(
          session,
          where: (table) => table.id.equals(key.id),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (locked == null || counter <= locked.signCount) {
          return const AppAttestCaptureVerdict.untrusted(
            AppAttestReason.replayed,
          );
        }
        var updated = await AppAttestKey.db.updateRow(
          session,
          locked.copyWith(signCount: counter, lastAssertedAt: now),
          transaction: transaction,
        );
        final gateway = apple;
        if (gateway == null || deviceCheckToken == null) {
          return AppAttestCaptureVerdict.trusted(
            publicKey: publicKey,
            reviewReasonCode: appleDeviceRiskUnavailableReviewCode,
          );
        }
        try {
          final bits = await gateway.queryBits(session, deviceCheckToken);
          if (bits.banned) {
            return const AppAttestCaptureVerdict.untrusted(
              'capture_device_banned',
            );
          }
          updated = await _refreshReceipt(session, updated, transaction);
          final metric = updated.riskMetric;
          final String? reviewReason;
          if (bits.reviewRequired) {
            reviewReason = appleDeviceReviewCode;
          } else if (metric == null ||
              !now.isBefore(updated.receiptExpiresAt) ||
              !now.isBefore(updated.receiptNotBefore)) {
            reviewReason = appleDeviceRiskUnavailableReviewCode;
          } else if (metric >= riskThreshold) {
            reviewReason = deviceActivityRiskReviewCode;
          } else {
            reviewReason = null;
          }
          return AppAttestCaptureVerdict.trusted(
            publicKey: publicKey,
            reviewReasonCode: reviewReason,
          );
        } on AppleDeviceUnavailable {
          session.log(
            'Apple device risk check unavailable; holding automatic verification.',
            level: LogLevel.warning,
          );
        } on FormatException {
          session.log(
            'Apple returned an invalid fraud-risk receipt; holding automatic verification.',
            level: LogLevel.warning,
          );
        }
        return AppAttestCaptureVerdict.trusted(
          publicKey: publicKey,
          reviewReasonCode: appleDeviceRiskUnavailableReviewCode,
        );
      },
    );
  }

  /// Refresh due receipts even for dormant installations, before Apple expires
  /// them. A row lock shares refresh ownership with capture verification.
  Future<void> refreshDueReceipts(Session session, {int limit = 100}) async {
    final verifier = this.verifier;
    if (verifier == null || apple == null) return;
    final now = clock().toUtc();
    final due = await AppAttestKey.db.find(
      session,
      where: (t) =>
          (t.receiptRefreshAfter <= now) &
          (t.receiptExpiresAt > now) &
          t.environment.equals(verifier.policy.environment),
      orderBy: (t) => t.receiptRefreshAfter,
      limit: limit.clamp(1, 100),
    );
    for (final key in due) {
      await DatabaseUtil.runInTransactionOrSavepoint(session.db, null, (
        transaction,
      ) async {
        final locked = await AppAttestKey.db.findFirstRow(
          session,
          where: (t) => t.id.equals(key.id),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (locked == null) return;
        try {
          await _refreshReceipt(session, locked, transaction);
        } on AppleDeviceUnavailable {
          session.log(
            'Apple receipt refresh unavailable; automatic verification remains held.',
            level: LogLevel.warning,
          );
        } on FormatException {
          session.log(
            'Invalid Apple receipt refresh; automatic verification remains held.',
            level: LogLevel.warning,
          );
        }
      });
    }
  }

  Future<AppAttestKey> _refreshReceipt(
    Session session,
    AppAttestKey key,
    Transaction transaction,
  ) async {
    final now = clock().toUtc();
    if (now.isBefore(key.receiptRefreshAfter) ||
        !now.isBefore(key.receiptExpiresAt)) {
      return key;
    }
    // Persist a bounded backoff before contacting Apple. No request retries;
    // failures preserve the previous verified receipt and cannot clear risk.
    await AppAttestKey.db.updateRow(
      session,
      key.copyWith(receiptRefreshAfter: now.add(const Duration(hours: 1))),
      transaction: transaction,
    );
    final encoded = await apple!.refreshReceipt(session, key.receipt);
    final policy = verifier!.policy;
    final fresh = receiptVerifier.verify(
      receipt: base64Decode(encoded),
      appId: '${policy.teamId}.${policy.bundleId}',
      publicKey: base64Decode(key.publicKey),
      now: clock().toUtc(),
      refreshed: true,
    );
    if (!fresh.notBefore.isAfter(now)) {
      throw const FormatException('Receipt has no future refresh window.');
    }
    return AppAttestKey.db.updateRow(
      session,
      key.copyWith(
        receipt: encoded,
        receiptCreatedAt: fresh.createdAt,
        receiptNotBefore: fresh.notBefore,
        receiptRefreshAfter: fresh.notBefore,
        receiptExpiresAt: fresh.expiresAt,
        riskMetric: fresh.riskMetric,
      ),
      transaction: transaction,
    );
  }

  AppAttestVerifier _requireVerifier() =>
      verifier ??
      (throw AppAttestException(
        problem: AppAttestProblem.unavailable,
        message: 'This phone cannot be set up to sign proof here.',
      ));
}

/// Apple's key identifier: SHA-256 of the public key in standard base64.
/// Null unless it decodes to exactly 32 bytes.
Uint8List? _decodeKeyId(String keyId) {
  try {
    final digest = base64Decode(keyId.trim());
    return digest.length == 32 ? digest : null;
  } on FormatException {
    return null;
  }
}

String _hex(List<int> bytes) =>
    bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

AppAttestException _keyRejected() => AppAttestException(
  problem: AppAttestProblem.keyRejected,
  message: 'This phone could not be set up to sign proof.',
);

// Apple's key identifier is 44 base64 characters.
const _maxEncodedKeyId = 64;

// An attestation object, receipt included, is about six kilobytes.
const int _maxEncodedAttestation = 32 * 1024;
