@Timeout(Duration(minutes: 5))
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/evidence_verification_worker.dart';
import 'package:verily_server/src/action_verification/local_check/local_check_catalog.dart';
import 'package:verily_server/src/action_verification/local_check/local_check_models.dart';
import 'package:verily_server/src/action_verification/local_check/local_check_replay.dart';
import 'package:verily_server/src/action_verification/local_check/mp_local_check_replayer.dart';
import 'package:verily_server/src/action_verification/media_evidence_verifier.dart';
import 'package:verily_server/src/evidence_storage/evidence_media_types.dart';
import 'package:verily_server/src/evidence_storage/evidence_object_access.dart';
import 'package:verily_server/src/evidence_storage/local_evidence_storage.dart';
import 'package:verily_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';
import 'test_tools/verily_fixtures.dart';

/// Scripted replay results; records every call so tests can prove what the
/// replay saw.
final class _FakeReplayer implements LocalCheckReplayer {
  _FakeReplayer(this.result);

  LocalCheckReplay result;
  final calls = <({ActionLocalCheck check, Uint8List media, String mime})>[];

  @override
  Future<LocalCheckReplay> replay({
    required ActionLocalCheck check,
    required LocalCheckModel model,
    required Uint8List media,
    required String mimeType,
  }) async {
    calls.add((check: check, media: media, mime: mimeType));
    return result;
  }
}

LocalCheckReplayScores _scores(List<double> scores) =>
    LocalCheckReplayScores(scores, latency: const Duration(milliseconds: 12));

const _thumbsUpUrl =
    'https://storage.googleapis.com/mediapipe-tasks/gesture_recognizer/'
    'thumbs_up.jpg';
const _thumbsUpSha256 =
    '2aee0e3a69ba5f0d3287597e61d265f4f3ac2a44ccec198dddd2639b0c8ef7ba';
final Directory _cache = Directory('.dart_tool/verily_test_cache/local_check');

ActionRequirementDraft _gesturePhoto({
  bool? spokenChallengeRequired,
  String? verificationPrompt,
}) =>
    mediaRequirement(
      kind: ActionRequirementKind.photo,
      key: 'thumbs-up',
    ).copyWith(
      verificationPrompt: verificationPrompt,
      spokenChallengeRequired: spokenChallengeRequired,
      localCheck: ActionLocalCheck(
        task: LocalCheckTask.gesture,
        label: 'Thumb_Up',
        minScore: 0.6,
        minFrames: 1,
      ),
    );

void main() {
  withServerpod('Given an action with a phone-only gesture check', (
    sessionBuilder,
    endpoints,
  ) {
    final creatorId = testId(901);
    final participantId = testId(902);
    late TestSessionBuilder creator;
    late TestSessionBuilder participant;

    setUp(() async {
      creator = signedIn(sessionBuilder, creatorId);
      participant = signedIn(sessionBuilder, participantId);
      final session = sessionBuilder.build();
      registerLocalEvidenceStorage(session);
      await insertAccounts(session, {creatorId: 'Ada', participantId: 'Grace'});
    });

    Future<ActionOpportunity> publish(ActionRequirementDraft requirement) =>
        publishedAction(
          endpoints,
          creator,
          actionRequest(actionKey: 'show-a-thumb', requirements: [requirement]),
        );

    /// Uploads like a client, optionally with the phone's own result.
    Future<({ActionAttemptView attempt, ActionEvidence evidence})> submit(
      ActionOpportunity action, {
      Uint8List? bytes,
      String contentType = 'image/jpeg',
      int? durationSeconds,
      DeviceLocalCheckResult? deviceLocalCheck,
    }) async {
      final media = bytes ?? MediaFixtures.jpeg();
      final requirement = action.requirements.single;
      final attempt = await endpoints.actionVerification.beginAttempt(
        participant,
        actionId: action.id,
        idempotencyKey: 'attempt',
      );
      if (requirement.spokenChallengeRequired) {
        await endpoints.actionVerification.issueSpokenChallenge(
          participant,
          attemptId: attempt.id,
          requirementId: requirement.id,
        );
      }
      await endpoints.actionVerification.requestMediaUpload(
        participant,
        attemptId: attempt.id,
        requirementId: requirement.id,
        contentType: contentType,
        byteLength: media.length,
      );
      final session = sessionBuilder.build();
      final storage =
          session.serverpod.storage[evidenceStorageId]! as LocalEvidenceStorage;
      await storage.storeUnverifiedFile(
        session: session,
        path: evidenceStoragePath(
          authUserId: participantId.toString(),
          attemptId: attempt.id.toString(),
          requirementId: requirement.id.toString(),
          type: evidenceMediaTypes[contentType]!,
        ),
        byteData: ByteData.sublistView(media),
        options: StoreFileOptions(
          metadata: FileMetadata(contentType: contentType),
        ),
      );
      await endpoints.actionVerification.confirmMediaUpload(
        participant,
        MediaUploadConfirmation(
          attemptId: attempt.id,
          requirementId: requirement.id,
          contentType: contentType,
          byteLength: media.length,
          durationSeconds: durationSeconds,
          capturedAt: DateTime.now().toUtc(),
          deviceLocalCheck: deviceLocalCheck,
        ),
      );
      final evidence = await ActionEvidence.db.findFirstRow(
        session,
        where: (table) => table.attemptId.equals(attempt.id),
      );
      return (attempt: attempt, evidence: evidence!);
    }

    Future<
      ({
        ActionAttempt attempt,
        EvidenceDecision decision,
        List<EvidenceVerificationVote> votes,
      })
    >
    verifyWith(
      ActionEvidence evidence, {
      required LocalCheckReplayer replayer,
      MediaEvidenceVerifier verifier =
          const ManualReviewMediaEvidenceVerifier(),
    }) async {
      final session = sessionBuilder.build();
      await EvidenceVerificationWorker(
        verifierFactory: (_, _, _) => verifier,
        localCheckReplayer: replayer,
      ).verify(session, evidence.id!);
      final decision = await EvidenceDecision.db.findFirstRow(
        session,
        where: (table) => table.evidenceId.equals(evidence.id),
        orderBy: (table) => table.createdAt.desc(),
      );
      final votes = await EvidenceVerificationVote.db.find(
        session,
        where: (table) => table.decisionId.equals(decision!.id),
      );
      final attempt = await ActionAttempt.db.findById(
        session,
        evidence.attemptId,
      );
      return (attempt: attempt!, decision: decision!, votes: votes);
    }

    group('when the creator designs it', () {
      test('then the check, its pinned model, and server-written verifier '
          'text round-trip', () async {
        final action = await publish(_gesturePhoto());

        final requirement = action.requirements.single;
        expect(requirement.localCheck?.label, 'Thumb_Up');
        expect(requirement.localCheck?.minScore, 0.6);
        final model = LocalCheckTask.gesture.model;
        expect(requirement.localCheckModel?.url, model.url);
        expect(requirement.localCheckModel?.sha256, model.sha256);
        expect(requirement.localCheckModel?.byteLength, model.byteLength);
        final rule = await ActionMediaRule.db.findFirstRow(
          sessionBuilder.build(),
          where: (table) => table.requirementId.equals(requirement.id),
        );
        expect(rule!.localCheckTask, LocalCheckTask.gesture);
        expect(rule.localCheckMinFrames, 1);
        // No creator prompt: the server writes one from the label.
        expect(rule.verificationPrompt, contains('thumb up'));
      });

      test('then a recording with a local check has the spoken word off by '
          'default but can opt in', () async {
        final video = mediaRequirement(kind: ActionRequirementKind.video)
            .copyWith(
              localCheck: ActionLocalCheck(
                task: LocalCheckTask.object,
                label: 'sports ball',
                minScore: 0.5,
                minFrames: 5,
              ),
            );

        final byDefault = await publishedAction(
          endpoints,
          creator,
          actionRequest(actionKey: 'ball-default', requirements: [video]),
        );
        final optedIn = await publishedAction(
          endpoints,
          creator,
          actionRequest(
            actionKey: 'ball-spoken',
            requirements: [video.copyWith(spokenChallengeRequired: true)],
          ),
        );

        expect(byDefault.requirements.single.spokenChallengeRequired, isFalse);
        expect(optedIn.requirements.single.spokenChallengeRequired, isTrue);
      });

      test('then a label off the allow-list or a mismatched task is refused '
          'and nothing is stored', () async {
        for (final check in [
          ActionLocalCheck(
            task: LocalCheckTask.gesture,
            label: 'Middle_Finger',
            minScore: 0.6,
            minFrames: 1,
          ),
          ActionLocalCheck(
            task: LocalCheckTask.sound,
            label: 'Clapping',
            minScore: 0.6,
            minFrames: 1,
          ),
        ]) {
          await expectLater(
            endpoints.actionVerification.createAction(
              creator,
              actionRequest(
                actionKey: 'bad-check',
                requirements: [_gesturePhoto().copyWith(localCheck: check)],
              ),
            ),
            throwsA(anything),
          );
        }
        expect(
          await ActionMediaRule.db.count(sessionBuilder.build()),
          0,
        );
      });
    });

    group('when the server replay finds the gesture', () {
      test('then mp-replay accepts it and the attempt is verified without '
          'another client call', () async {
        final action = await publish(_gesturePhoto());
        final submitted = await submit(action);
        final replayer = _FakeReplayer(_scores([0.83]));

        final result = await verifyWith(
          submitted.evidence,
          replayer: replayer,
        );

        expect(result.decision.status, EvidenceDecisionStatus.accepted);
        expect(result.decision.verifierType, mpReplayVerifierType);
        expect(result.decision.reasonCode, LocalCheckReason.matched);
        final model = LocalCheckTask.gesture.model;
        expect(result.decision.modelName, model.modelId);
        expect(result.decision.modelVersion, model.sha256);
        expect(result.decision.confidence, closeTo(0.83, 1e-9));
        expect(result.votes.single.providerName, mpReplayVerifierType);
        expect(result.attempt.status, ActionAttemptStatus.verified);
        // The replay judged exactly the sealed bytes.
        final call = replayer.calls.single;
        expect(
          sha256.convert(call.media).toString(),
          submitted.evidence.sha256Digest,
        );
        expect(call.mime, 'image/jpeg');
      });
    });

    group('when the server replay does not find the gesture', () {
      test(
        'then the proof is rejected even though the phone said it matched',
        () async {
          final action = await publish(_gesturePhoto());
          final submitted = await submit(
            action,
            deviceLocalCheck: DeviceLocalCheckResult(
              modelId: 'mediapipe/gesture_recognizer/float16/1',
              modelSha256: LocalCheckTask.gesture.model.sha256,
              label: 'Thumb_Up',
              score: 0.99,
              matchedFrames: 1,
            ),
          );

          final result = await verifyWith(
            submitted.evidence,
            replayer: _FakeReplayer(_scores([0.31])),
          );

          expect(result.decision.status, EvidenceDecisionStatus.rejected);
          expect(result.decision.reasonCode, LocalCheckReason.notMatched);
          expect(result.attempt.status, ActionAttemptStatus.rejected);
          // The phone's claim is kept for calibration only.
          expect(submitted.evidence.deviceLocalCheckScore, 0.99);
          expect(submitted.evidence.deviceLocalCheckLabel, 'Thumb_Up');
          expect(
            submitted.evidence.deviceLocalCheckModelId,
            'mediapipe/gesture_recognizer/float16/1',
          );
        },
      );
    });

    group('when the replay cannot run on this server', () {
      const unavailable = LocalCheckReplayUnavailable(
        LocalCheckUnavailableCode.runtimeUnavailable,
      );

      test('then a manual-review policy routes it to a person with '
          'mp_replay_unavailable', () async {
        final action = await publish(_gesturePhoto());
        final submitted = await submit(action);

        final result = await verifyWith(
          submitted.evidence,
          replayer: _FakeReplayer(unavailable),
        );

        expect(result.decision.status, EvidenceDecisionStatus.manualReview);
        expect(result.decision.reasonCode, LocalCheckReason.replayUnavailable);
        expect(result.votes.single.verdict, 'failed');
        expect(
          result.votes.single.errorCode,
          LocalCheckUnavailableCode.runtimeUnavailable,
        );
        expect(result.attempt.status, ActionAttemptStatus.pendingReview);
      });

      test('then the AI policy decides and the failed replay is still '
          'audited', () async {
        final action = await publish(_gesturePhoto());
        final submitted = await submit(action);
        final ai = ScriptedMediaVerifier();

        final result = await verifyWith(
          submitted.evidence,
          replayer: _FakeReplayer(unavailable),
          verifier: ai,
        );

        expect(result.decision.status, EvidenceDecisionStatus.accepted);
        expect(result.decision.verifierType, 'openrouter-single-model');
        expect(result.votes, hasLength(2));
        expect(
          result.votes
              .where((vote) => vote.providerName == 'mp-replay')
              .single
              .errorCode,
          LocalCheckUnavailableCode.runtimeUnavailable,
        );
        // The AI saw the server-written check text, not device data.
        expect(
          ai.requests.single.rule.verificationPrompt,
          contains('thumb up'),
        );
        expect(result.attempt.status, ActionAttemptStatus.verified);
      });

      test('then stored bytes that no longer match the seal make the replay '
          'unavailable instead of judging them', () async {
        final action = await publish(_gesturePhoto());
        final submitted = await submit(action);
        final session = sessionBuilder.build();
        final storage =
            session.serverpod.storage[evidenceStorageId]!
                as LocalEvidenceStorage;
        await storage.storeFile(
          session: session,
          path: submitted.evidence.storagePath!,
          byteData: ByteData.sublistView(MediaFixtures.png()),
        );
        final replayer = _FakeReplayer(_scores([0.99]));

        final result = await verifyWith(
          submitted.evidence,
          replayer: replayer,
        );

        expect(replayer.calls, isEmpty);
        expect(result.decision.reasonCode, LocalCheckReason.replayUnavailable);
        expect(
          result.votes.single.errorCode,
          LocalCheckUnavailableCode.evidenceDigestMismatch,
        );
      });
    });

    group('when the check also needs a spoken word', () {
      test('then the replay is recorded but the AI policy decides', () async {
        final action = await publish(
          mediaRequirement(kind: ActionRequirementKind.video).copyWith(
            spokenChallengeRequired: true,
            localCheck: ActionLocalCheck(
              task: LocalCheckTask.gesture,
              label: 'Thumb_Up',
              minScore: 0.6,
              minFrames: 3,
            ),
          ),
        );
        final submitted = await submit(
          action,
          bytes: MediaFixtures.mp4Video(),
          contentType: 'video/mp4',
          durationSeconds: 8,
        );

        final result = await verifyWith(
          submitted.evidence,
          replayer: _FakeReplayer(_scores([0.9, 0.9, 0.9, 0.9])),
          verifier: ScriptedMediaVerifier(
            spokenChallengeVerdict: SpokenChallengeVerdict.notHeard,
          ),
        );

        expect(result.decision.status, EvidenceDecisionStatus.rejected);
        expect(result.decision.reasonCode, 'spoken_challenge_not_heard');
        final replayVote = result.votes.firstWhere(
          (vote) => vote.providerName == mpReplayVerifierType,
        );
        expect(replayVote.verdict, 'fulfilled');
        expect(result.attempt.status, ActionAttemptStatus.rejected);
      });
    });

    group('when the phone reports a local-check result', () {
      test('then a proof without a local check ignores it entirely', () async {
        final action = await publish(
          mediaRequirement(kind: ActionRequirementKind.photo),
        );

        final submitted = await submit(
          action,
          deviceLocalCheck: DeviceLocalCheckResult(
            modelId: 'anything',
            modelSha256: 'not-a-digest',
            label: 'Thumb_Up',
            score: 0.9,
            matchedFrames: 1,
          ),
        );

        expect(submitted.evidence.deviceLocalCheckModelId, isNull);
        expect(submitted.evidence.deviceLocalCheckScore, isNull);
      });

      test(
        'then a malformed result on a local-check proof is refused',
        () async {
          final action = await publish(_gesturePhoto());

          await expectLater(
            submit(
              action,
              deviceLocalCheck: DeviceLocalCheckResult(
                modelId: 'mediapipe/gesture_recognizer/float16/1',
                modelSha256: 'not-a-digest',
                label: 'Thumb_Up',
                score: 0.9,
                matchedFrames: 1,
              ),
            ),
            throwsA(anything),
          );
          expect(
            await ActionEvidence.db.count(sessionBuilder.build()),
            0,
          );
        },
      );
    });

    group('when the real MediaPipe runtime replays a real photo', () {
      test('then a genuine thumbs-up photo is verified end to end', () async {
        final skip = await _realRuntimeSkipReason();
        if (skip != null) {
          markTestSkipped(skip);
          return;
        }
        final photo = await _pinnedThumbsUp();
        if (photo == null) {
          markTestSkipped('The pinned fixture is unavailable (offline?).');
          return;
        }
        final action = await publish(_gesturePhoto());
        final submitted = await submit(action, bytes: photo);

        final result = await verifyWith(
          submitted.evidence,
          replayer: MpLocalCheckReplayer(
            models: PinnedLocalCheckModelStore(cacheDirectory: _cache),
          ),
        );
        if (result.decision.reasonCode == LocalCheckReason.replayUnavailable) {
          markTestSkipped(
            'The replay was unavailable: ${result.votes.single.errorCode}',
          );
          return;
        }

        expect(result.decision.verifierType, mpReplayVerifierType);
        expect(result.decision.status, EvidenceDecisionStatus.accepted);
        expect(result.decision.confidence, greaterThan(0.6));
        expect(result.attempt.status, ActionAttemptStatus.verified);
      });
    });
  });
}

Future<String?> _realRuntimeSkipReason() async {
  if (!Platform.isMacOS && !Platform.isLinux) {
    return 'The MP runtime is not published for this host.';
  }
  try {
    final result = await Process.run('ffmpeg', ['-version']);
    return result.exitCode == 0 ? null : 'ffmpeg is not installed.';
  } on ProcessException {
    return 'ffmpeg is not installed.';
  }
}

Future<Uint8List?> _pinnedThumbsUp() async {
  final file = File('${_cache.path}/$_thumbsUpSha256');
  if (file.existsSync()) {
    final cached = file.readAsBytesSync();
    if (sha256.convert(cached).toString() == _thumbsUpSha256) return cached;
  }
  try {
    final response = await http
        .get(Uri.parse(_thumbsUpUrl))
        .timeout(const Duration(seconds: 30));
    final bytes = response.bodyBytes;
    if (response.statusCode != 200 ||
        sha256.convert(bytes).toString() != _thumbsUpSha256) {
      return null;
    }
    _cache.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
    return bytes;
  } on Object {
    return null;
  }
}
