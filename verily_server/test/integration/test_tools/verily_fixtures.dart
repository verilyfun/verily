import 'dart:convert';
import 'dart:typed_data';

import 'package:bs58/bs58.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:verily_server/src/action_verification/media_evidence_verifier.dart';
import 'package:verily_server/src/evidence_storage/evidence_media_types.dart';
import 'package:verily_server/src/evidence_storage/evidence_object_access.dart';
import 'package:verily_server/src/evidence_storage/local_evidence_storage.dart';
import 'package:verily_server/src/generated/protocol.dart';

import 'serverpod_test_tools.dart';

/// A signed-in test session for [authUserId].
TestSessionBuilder signedIn(
  TestSessionBuilder sessionBuilder,
  UuidValue authUserId, {
  Set<String> scopes = const {},
}) => sessionBuilder.copyWith(
  authentication: AuthenticationOverride.authenticationInfo(
    authUserId.toString(),
    {for (final scope in scopes) Scope(scope)},
  ),
);

/// Inserts one active account per entry, with a public profile name.
Future<void> insertAccounts(
  Session session,
  Map<UuidValue, String> displayNames,
) async {
  await AuthUser.db.insert(session, [
    for (final id in displayNames.keys) AuthUser(id: id, scopeNames: const {}),
  ]);
  await UserProfile.db.insert(session, [
    for (final entry in displayNames.entries)
      UserProfile(authUserId: entry.key, userName: entry.value),
  ]);
}

/// Registers the zero-config local evidence storage on the test server, as
/// development and test startup does.
void registerLocalEvidenceStorage(Session session) {
  if (session.serverpod.storage[evidenceStorageId] is! LocalEvidenceStorage) {
    session.serverpod.addCloudStorage(LocalEvidenceStorage());
  }
}

/// A deterministic test UUID ending in [suffix].
UuidValue testId(int suffix) => UuidValue.withValidation(
  '0198bc26-4be5-7ca0-94d2-${suffix.toRadixString(16).padLeft(12, '0')}',
);

ActionRequirementDraft locationRequirement({
  String key = 'be-there',
  double latitude = 51.5007,
  double longitude = -0.1246,
  double radiusMeters = 150,
}) => ActionRequirementDraft(
  requirementKey: key,
  kind: ActionRequirementKind.location,
  title: 'Be there',
  instructions: 'Share your location when you arrive.',
  isRequired: true,
  latitude: latitude,
  longitude: longitude,
  radiusMeters: radiusMeters,
  maxAccuracyMeters: 50,
);

ActionRequirementDraft qrRequirement({
  String key = 'scan-code',
  String? qrCode,
}) => ActionRequirementDraft(
  requirementKey: key,
  kind: ActionRequirementKind.qrCode,
  title: 'Scan the code',
  instructions: 'Scan the code shown at the venue.',
  isRequired: true,
  qrCode: qrCode,
);

ActionRequirementDraft mediaRequirement({
  required ActionRequirementKind kind,
  String? key,
  bool? spokenChallengeRequired,
  ActionVerificationPolicy policy = ActionVerificationPolicy.singleModel,
  double minConfidence = 0.8,
}) {
  final isPhoto = kind == ActionRequirementKind.photo;
  return ActionRequirementDraft(
    requirementKey: key ?? '${kind.name}-proof',
    kind: kind,
    title: 'Show it',
    instructions: 'Capture the proof the action asks for.',
    isRequired: true,
    verificationPrompt: 'Verify that the person waters a plant.',
    minDurationSeconds: isPhoto ? null : 3,
    maxDurationSeconds: isPhoto ? null : 60,
    minConfidence: minConfidence,
    verificationPolicy: policy,
    spokenChallengeRequired: spokenChallengeRequired,
  );
}

ActionRequirementDraft externalRequirement({
  required UuidValue appId,
  String key = 'app-confirmed',
}) => ActionRequirementDraft(
  requirementKey: key,
  kind: ActionRequirementKind.externalApp,
  title: 'Finish in the app',
  instructions: 'Complete the challenge in the partner app.',
  isRequired: true,
  appId: appId,
);

CreateActionDefinitionRequest actionRequest({
  required String actionKey,
  required List<ActionRequirementDraft> requirements,
  String title = 'Water a plant',
  ActionRecurrence recurrence = ActionRecurrence.once,
  int? maxVerifiedCompletions,
  RewardTermsDraft? reward,
}) => CreateActionDefinitionRequest(
  actionKey: actionKey,
  title: title,
  description: 'A small thing, done for real.',
  recurrence: recurrence,
  timeZone: 'UTC',
  maxVerifiedCompletions: maxVerifiedCompletions,
  requirements: requirements,
  reward: reward,
);

/// Creates and publishes an action as [creator].
Future<ActionOpportunity> publishedAction(
  TestEndpoints endpoints,
  TestSessionBuilder creator,
  CreateActionDefinitionRequest request,
) async {
  final draft = await endpoints.actionVerification.createAction(
    creator,
    request,
  );
  return endpoints.actionVerification.publishAction(
    creator,
    actionId: draft.id,
    expectedRevision: draft.revision,
  );
}

/// The smallest byte sequences each allowed container is recognized from.
abstract final class MediaFixtures {
  static Uint8List jpeg() =>
      _padded([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, ...ascii.encode('JFIF')]);

  static Uint8List png() =>
      _padded([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

  static Uint8List mp4Video() => _ftyp('isom', ['isom', 'mp41']);

  static Uint8List m4aAudio() => _ftyp('M4A ', ['M4A ', 'mp42']);

  static Uint8List _ftyp(String major, List<String> compatible) {
    final body = [
      ...ascii.encode(major),
      0,
      0,
      2,
      0,
      for (final brand in compatible) ...ascii.encode(brand),
    ];
    final length = body.length + 8;
    return _padded([
      (length >> 24) & 0xff,
      (length >> 16) & 0xff,
      (length >> 8) & 0xff,
      length & 0xff,
      ...ascii.encode('ftyp'),
      ...body,
    ]);
  }

  static Uint8List _padded(List<int> header) =>
      Uint8List.fromList([...header, ...List<int>.filled(256, 7)]);
}

/// Uploads [bytes] for one media requirement the way a client does: a
/// reserved description, then the bytes stored unverified at the
/// server-derived path, then confirmation.
Future<EvidenceSubmissionResult> uploadMediaProof(
  TestEndpoints endpoints,
  TestSessionBuilder participant, {
  required UuidValue participantId,
  required UuidValue attemptId,
  required UuidValue requirementId,
  required String contentType,
  required Uint8List bytes,
  int? durationSeconds,
  DateTime? capturedAt,
}) async {
  await endpoints.actionVerification.requestMediaUpload(
    participant,
    attemptId: attemptId,
    requirementId: requirementId,
    contentType: contentType,
    byteLength: bytes.length,
  );
  final session = participant.build();
  final storage =
      session.serverpod.storage[evidenceStorageId]! as LocalEvidenceStorage;
  await storage.storeUnverifiedFile(
    session: session,
    path: evidenceStoragePath(
      authUserId: participantId.toString(),
      attemptId: attemptId.toString(),
      requirementId: requirementId.toString(),
      type: evidenceMediaTypes[contentType]!,
    ),
    byteData: ByteData.sublistView(bytes),
    options: StoreFileOptions(
      metadata: FileMetadata(contentType: contentType),
    ),
  );
  return endpoints.actionVerification.confirmMediaUpload(
    participant,
    MediaUploadConfirmation(
      attemptId: attemptId,
      requirementId: requirementId,
      contentType: contentType,
      byteLength: bytes.length,
      durationSeconds: durationSeconds,
      capturedAt: capturedAt ?? DateTime.now().toUtc(),
    ),
  );
}

/// A verifier that answers every request with one fixed single-model vote.
class ScriptedMediaVerifier implements MediaEvidenceVerifier {
  ScriptedMediaVerifier({
    this.verdict = MediaEvidenceModelVerdict.fulfilled,
    this.confidence = 0.95,
    this.spokenChallengeVerdict,
  });

  final MediaEvidenceModelVerdict verdict;
  final double confidence;
  final SpokenChallengeVerdict? spokenChallengeVerdict;
  final requests = <MediaVerificationRequest>[];

  @override
  Future<MediaEvidenceVerification> verify(
    Session session,
    MediaVerificationRequest request,
  ) async {
    requests.add(request);
    return decideMediaVerification(
      policy: request.rule.verificationPolicy,
      votes: [
        MediaEvidenceModelVote(
          modelId: openRouterGeminiFlashModel,
          verdict: verdict,
          confidence: confidence,
          latencyMilliseconds: 5,
          spokenChallengeVerdict: request.spokenChallengeWord == null
              ? null
              : spokenChallengeVerdict ?? SpokenChallengeVerdict.heard,
        ),
      ],
      minimumConfidence: request.rule.minConfidence,
      spokenChallengeRequested: request.spokenChallengeWord != null,
    );
  }
}

/// A Solana keypair for wallet-link tests.
final class TestWallet {
  TestWallet._(this._privateKey, this.address);

  factory TestWallet.fromSeed(int seed) {
    final privateKey = ed.newKeyFromSeed(
      Uint8List.fromList(List<int>.filled(32, seed)),
    );
    return TestWallet._(
      privateKey,
      base58.encode(Uint8List.fromList(ed.public(privateKey).bytes)),
    );
  }

  final ed.PrivateKey _privateKey;
  final String address;

  /// A base58 ed25519 signature over [message].
  String sign(String message) => base58.encode(
    ed.sign(_privateKey, Uint8List.fromList(utf8.encode(message))),
  );
}

/// Links [wallet] as [participant]'s payout wallet through the endpoint.
Future<PayoutWalletView> linkWallet(
  TestEndpoints endpoints,
  TestSessionBuilder participant,
  TestWallet wallet,
) async {
  final challenge = await endpoints.payoutWallet.createWalletLinkChallenge(
    participant,
    walletAddress: wallet.address,
  );
  return endpoints.payoutWallet.linkPayoutWallet(
    participant,
    walletAddress: wallet.address,
    nonce: challenge.nonce,
    signature: wallet.sign(challenge.message),
  );
}
