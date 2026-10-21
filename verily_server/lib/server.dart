import 'dart:io';

import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';
import 'package:serverpod_auth_idp_server/providers/google.dart';
import 'package:verily_server/src/abuse/action_abuse_gate.dart';
import 'package:verily_server/src/action_verification/action_capture_challenge_cleanup_future_call.dart';
import 'package:verily_server/src/action_verification/action_qr_challenge_cleanup_future_call.dart';
import 'package:verily_server/src/action_verification/action_spoken_challenge_cleanup_future_call.dart';
import 'package:verily_server/src/action_verification/action_verification_service.dart';
import 'package:verily_server/src/action_verification/capture_integrity.dart';
import 'package:verily_server/src/action_verification/evidence_verification_recovery_future_call.dart';
import 'package:verily_server/src/action_verification/media_evidence_verifier.dart';
import 'package:verily_server/src/action_verification/production_ai_deployment.dart';
import 'package:verily_server/src/auth/email_auth_configuration.dart';
import 'package:verily_server/src/auth/email_delivery_service.dart';
import 'package:verily_server/src/evidence_storage/evidence_storage_configuration.dart';
import 'package:verily_server/src/evidence_storage/evidence_upload_cleanup_future_call.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/generated/serverpod.dart';
import 'package:verily_server/src/rewards/payout_wallet_challenge_cleanup_future_call.dart';
import 'package:verily_server/src/rewards/reward_configuration.dart';
import 'package:verily_server/src/rewards/reward_payout_recovery_future_call.dart';
import 'package:verily_server/src/web/routes/app_config_route.dart';
import 'package:verily_server/src/web/routes/app_confirmations_route.dart';
import 'package:verily_server/src/web/routes/health_route.dart';
import 'package:verily_server/src/web/routes/root_route.dart';

/// The starting point of the Verily Serverpod server.
///
/// Every security-relevant setting is parsed before the server accepts
/// traffic, and an invalid or incomplete one stops startup: verifier modes,
/// AI deployment attestations, capture-integrity modes, abuse enforcement,
/// evidence storage, reward escrow, and the payout review threshold.
Future<void> run(List<String> args) async {
  final environment = Platform.environment;
  ActionAbuseGateRegistry.configureFromEnvironment(environment);

  final pod = Serverpod(args)
    ..loadCustomPasswords([
      (
        envName: 'VERILY_EVIDENCE_B2_S3_ENDPOINT',
        alias: 'evidenceB2S3Endpoint',
      ),
      (envName: 'VERILY_EVIDENCE_B2_REGION', alias: 'evidenceB2Region'),
      (
        envName: 'VERILY_EVIDENCE_B2_BUCKET_NAME',
        alias: 'evidenceB2BucketName',
      ),
      (envName: 'VERILY_EVIDENCE_B2_KEY_ID', alias: 'evidenceB2KeyId'),
      (
        envName: 'VERILY_EVIDENCE_B2_APPLICATION_KEY',
        alias: 'evidenceB2ApplicationKey',
      ),
      (envName: 'VERILY_RESEND_API_KEY', alias: 'resendApiKey'),
      (
        envName: 'VERILY_PLAY_INTEGRITY_SERVICE_ACCOUNT_JSON',
        alias: 'playIntegrityServiceAccountJson',
      ),
      (envName: 'VERILY_MEDIA_VERIFIER_TOKEN', alias: 'mediaVerifierToken'),
      (envName: 'VERILY_OPENROUTER_API_KEY', alias: 'openRouterApiKey'),
    ]);
  final developmentLike =
      pod.runMode == ServerpodRunMode.development ||
      pod.runMode == ServerpodRunMode.test;

  // Reject partial verifier, AI, and capture configuration up front.
  final verifier = MediaEvidenceVerifierConfiguration.fromEnvironment(
    environment,
    token: pod.getPassword('mediaVerifierToken'),
    openRouterApiKey: pod.getPassword('openRouterApiKey'),
  );
  ProductionAiDeploymentConfiguration.fromEnvironment(
    environment,
    verifier: verifier,
    inferencePolicy: productionInferenceCostPolicyFromEnvironment(environment),
  );
  deviceIntegrityRequiredFromEnvironment(environment);
  captureSignatureRequiredFromEnvironment(environment);
  if (staticQrCodesAllowed(environment) && !developmentLike) {
    throw StateError(
      'Static venue codes are a local fixture; VERILY_STATIC_QR_ENABLED must '
      'be false outside development and test.',
    );
  }
  RewardRuntime.current = RewardConfiguration.fromEnvironment(
    runMode: pod.runMode,
    environment: environment,
  );

  final storageMode = EvidenceStorageSelection.resolveMode(
    runMode: pod.runMode,
    environment: environment,
    readPassword: pod.getPassword,
  );
  pod.addCloudStorage(
    EvidenceStorageSelection.create(
      mode: storageMode,
      readPassword: pod.getPassword,
    ),
  );
  if (storageMode == EvidenceStorageMode.local) {
    stdout.writeln(
      '[development-only] Evidence is stored in the local database. Set the '
      'VERILY_EVIDENCE_B2_* values to use private Backblaze storage.',
    );
  }

  final emailAuth = EmailAuthConfiguration.fromEnvironment(environment);
  final emailDelivery = switch (emailAuth.mode) {
    EmailAuthMode.resend => ResendEmailDeliveryService(
      apiKey: emailAuth.resendApiKey!,
      fromAddress: emailAuth.fromAddress!,
    ),
    _ => null,
  };
  pod.initializeAuthServices(
    tokenManagerBuilders: [JwtConfigFromPasswords()],
    identityProviderBuilders: [
      if (emailAuth.isEnabled)
        EmailIdpConfigFromPasswords(
          sendRegistrationVerificationCode:
              (
                session, {
                required email,
                required accountRequestId,
                required verificationCode,
                required transaction,
              }) => _deliverEmailCode(
                session: session,
                configuration: emailAuth,
                deliveryService: emailDelivery,
                email: email,
                verificationCode: verificationCode,
                purpose: EmailVerificationPurpose.registration,
              ),
          sendPasswordResetVerificationCode:
              (
                session, {
                required email,
                required passwordResetRequestId,
                required verificationCode,
                required transaction,
              }) => _deliverEmailCode(
                session: session,
                configuration: emailAuth,
                deliveryService: emailDelivery,
                email: email,
                verificationCode: verificationCode,
                purpose: EmailVerificationPurpose.passwordReset,
              ),
        ),
      if ((pod.getPassword('googleClientSecret') ?? '').trim().isNotEmpty)
        GoogleIdpConfigFromPasswords(),
    ],
  );

  pod.webServer
    ..addRoute(RootRoute())
    ..addRoute(RootRoute(), '/index.html')
    ..addRoute(HealthRoute(), '/healthz')
    ..addRoute(
      AppConfigRoute(apiConfig: pod.config.apiServer),
      '/app/assets/assets/config.json',
    )
    ..addRoute(AppConfirmationsRoute(), '/api/v1/confirmations');
  final appDir = Directory(Uri(path: 'web/app').toFilePath());
  if (appDir.existsSync()) {
    pod.webServer.addRoute(FlutterRoute(appDir), '/app');
  }

  await pod.start();

  // One recurring call of each kind survives single-server restarts.
  final futureCalls = pod.futureCalls;
  Future<void> recurring(
    String identifier,
    Future<void> Function() schedule,
  ) async {
    await futureCalls.cancel(identifier);
    await schedule();
  }

  await recurring(
    evidenceUploadCleanupIdentifier,
    () => futureCalls
        .callRecurring(identifier: evidenceUploadCleanupIdentifier)
        .every(const Duration(days: 1))
        .evidenceUploadCleanup
        .cleanup(EvidenceUploadCleanupTask(batchSize: 100)),
  );
  await recurring(
    actionQrChallengeCleanupIdentifier,
    () => futureCalls
        .callRecurring(identifier: actionQrChallengeCleanupIdentifier)
        .every(const Duration(days: 1))
        .actionQrChallengeCleanup
        .cleanup(ActionQrChallengeCleanupTask(batchSize: 500)),
  );
  await recurring(
    actionCaptureChallengeCleanupIdentifier,
    () => futureCalls
        .callRecurring(identifier: actionCaptureChallengeCleanupIdentifier)
        .every(const Duration(days: 1))
        .actionCaptureChallengeCleanup
        .cleanup(ActionCaptureChallengeCleanupTask(batchSize: 500)),
  );
  await recurring(
    actionSpokenChallengeCleanupIdentifier,
    () => futureCalls
        .callRecurring(identifier: actionSpokenChallengeCleanupIdentifier)
        .every(const Duration(days: 1))
        .actionSpokenChallengeCleanup
        .cleanup(ActionSpokenChallengeCleanupTask(batchSize: 500)),
  );
  await recurring(
    payoutWalletChallengeCleanupIdentifier,
    () => futureCalls
        .callRecurring(identifier: payoutWalletChallengeCleanupIdentifier)
        .every(const Duration(days: 1))
        .payoutWalletChallengeCleanup
        .cleanup(PayoutWalletChallengeCleanupTask(batchSize: 500)),
  );
  await recurring(
    evidenceVerificationRecoveryIdentifier,
    () => futureCalls
        .callRecurring(identifier: evidenceVerificationRecoveryIdentifier)
        .every(const Duration(minutes: 5))
        .evidenceVerificationRecovery
        .recover(EvidenceVerificationRecoveryTask(batchSize: 100)),
  );
  await recurring(
    rewardPayoutRecoveryIdentifier,
    () => futureCalls
        .callRecurring(identifier: rewardPayoutRecoveryIdentifier)
        .every(const Duration(minutes: 5))
        .rewardPayoutRecovery
        .recover(RewardPayoutRecoveryTask(batchSize: 100)),
  );
}

Future<void> _deliverEmailCode({
  required Session session,
  required EmailAuthConfiguration configuration,
  required ResendEmailDeliveryService? deliveryService,
  required String email,
  required String verificationCode,
  required EmailVerificationPurpose purpose,
}) async {
  if (configuration.mode == EmailAuthMode.developmentLog) {
    session.log(
      '[development-only] Email verification code ($email): '
      '$verificationCode',
    );
    return;
  }

  final service = deliveryService;
  if (service == null) {
    throw StateError('Email delivery is not configured.');
  }
  await service.sendVerificationCode(
    email: email,
    verificationCode: verificationCode,
    purpose: purpose,
  );
}
