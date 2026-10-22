import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:verily_server/src/action_verification/app_attest/app_attest_service.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// Registers the App Attest key an iPhone signs its captures with: one key
/// per account per install, attested once against a server challenge.
///
/// Both methods throw [AppAttestException] with an [AppAttestProblem] that
/// says what the phone should do next.
class AppAttestEndpoint extends Endpoint {
  AppAttestEndpoint({AppAttestService? service})
    : service = service ?? AppAttestService.fromEnvironment();

  final AppAttestService service;

  @override
  bool get requireLogin => true;

  /// A single-use challenge, valid for five minutes, to attest the key
  /// against with `clientDataHash = SHA-256(challenge bytes)`.
  Future<AppAttestChallengeView> beginRegistration(Session session) {
    return service.beginRegistration(
      session,
      authUserId: session.authenticated!.authUserId,
    );
  }

  /// Verifies the attestation of [keyId] (base64, as `generateKey` returns
  /// it) made against [challengeId], and registers the key to the caller.
  Future<void> registerKey(
    Session session, {
    required UuidValue challengeId,
    required String keyId,
    required String attestationObject,
  }) {
    return service.registerKey(
      session,
      authUserId: session.authenticated!.authUserId,
      challengeId: challengeId,
      keyId: keyId,
      attestationObject: attestationObject,
    );
  }
}
