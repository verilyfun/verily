import 'dart:convert';
import 'dart:math' as math;

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:verily_evidence/verily_evidence.dart';
import 'package:verily_server/src/action_verification/action_period.dart';
import 'package:verily_server/src/action_verification/action_verification_service.dart';
import 'package:verily_server/src/action_verification/app_attest/app_attest_receipt.dart';
import 'package:verily_server/src/action_verification/app_attest/app_attest_service.dart';
import 'package:verily_server/src/action_verification/app_attest/app_attest_verifier.dart';
import 'package:verily_server/src/action_verification/app_attest/apple_device_client.dart';
import 'package:verily_server/src/action_verification/capture_integrity.dart';
import 'package:verily_server/src/action_verification/device_integrity_verifier.dart';
import 'package:verily_server/src/action_verification/key_attestation/android_key_attestation_verifier.dart';
import 'package:verily_server/src/action_verification/key_attestation/attestation_status_list.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/security/secret_digest.dart';

import 'test_tools/app_attest_test_authority.dart';
import 'test_tools/apple_device_test_authority.dart';
import 'test_tools/key_attestation_test_chain.dart';
import 'test_tools/serverpod_test_tools.dart';
import 'test_tools/verily_fixtures.dart';

/// The creator's permanent code. Static codes are a local fixture that is off
/// by default, so this code alone never verifies a proof.
const _staticVenueCode = 'verily-static-venue-code';

/// Big Ben, the default place in the shared fixtures.
typedef _Place = ({double latitude, double longitude});

const _Place _bigBen = (latitude: 51.5007, longitude: -0.1246);
const _Place _paris = (latitude: 48.8566, longitude: 2.3522);

void main() {
  withServerpod('Given a published place-and-venue action', (
    sessionBuilder,
    endpoints,
  ) {
    final creatorId = testId(0x201);
    final participantId = testId(0x202);
    final otherId = testId(0x203);
    late TestSessionBuilder creator;
    late TestSessionBuilder participant;
    late TestSessionBuilder other;
    late ActionOpportunity action;
    late ActionRequirementView location;
    late ActionRequirementView venue;

    setUp(() async {
      creator = signedIn(sessionBuilder, creatorId);
      participant = signedIn(sessionBuilder, participantId);
      other = signedIn(sessionBuilder, otherId);
      await insertAccounts(sessionBuilder.build(), {
        creatorId: 'Ada',
        participantId: 'Grace',
        otherId: 'Hedy',
      });
      action = await endpoints.actionVerification.createAction(
        creator,
        _venueRequest(actionKey: 'big-ben-visit'),
      );
      location = action.requirements.singleWhere(
        (item) => item.kind == ActionRequirementKind.location,
      );
      venue = action.requirements.singleWhere(
        (item) => item.kind == ActionRequirementKind.qrCode,
      );
    });

    Future<ActionAttemptView> begin(
      TestSessionBuilder who, [
      String key = 'attempt',
    ]) => endpoints.actionVerification.beginAttempt(
      who,
      actionId: action.id,
      idempotencyKey: key,
    );

    Future<String> liveCode() async =>
        (await endpoints.actionVerification.createQrChallenge(
          creator,
          requirementId: venue.id,
          validitySeconds: 60,
        )).code;

    Future<EvidenceSubmissionResult> checkIn(
      TestSessionBuilder who,
      UuidValue attemptId, {
      _Place at = _bigBen,
      double accuracyMeters = 10,
      DateTime? capturedAt,
      ActionRequirementView? requirement,
    }) => endpoints.actionVerification.submitEvidence(
      who,
      ActionEvidenceInput(
        attemptId: attemptId,
        requirementId: (requirement ?? location).id,
        capturedAt: capturedAt ?? DateTime.now().toUtc(),
        latitude: at.latitude,
        longitude: at.longitude,
        accuracyMeters: accuracyMeters,
      ),
    );

    Future<EvidenceSubmissionResult> scan(
      TestSessionBuilder who,
      UuidValue attemptId,
      String code,
    ) => endpoints.actionVerification.submitEvidence(
      who,
      ActionEvidenceInput(
        attemptId: attemptId,
        requirementId: venue.id,
        capturedAt: DateTime.now().toUtc(),
        qrCode: code,
      ),
    );

    group('when a participant begins an attempt', () {
      test('then retries converge on one attempt per period', () async {
        final first = await begin(participant, 'mobile-request-1');
        final retry = await begin(participant, 'mobile-request-2');
        final sameKey = await begin(participant, 'mobile-request-1');

        expect(retry.id, first.id);
        expect(sameKey.id, first.id);
        expect(first.status, ActionAttemptStatus.collectingEvidence);
        expect(first.periodKey, _londonToday());
        expect(
          await ActionAttempt.db.count(sessionBuilder.build()),
          1,
        );
      });

      test('then idempotency keys are scoped to the account', () async {
        final mine = await begin(participant, 'shared-request-id');
        final theirs = await begin(other, 'shared-request-id');

        expect(theirs.id, isNot(mine.id));
        expect(
          await ActionAttempt.db.count(
            sessionBuilder.build(),
            where: (table) => table.idempotencyKey.equals('shared-request-id'),
          ),
          2,
        );
      });

      test(
        'then reusing a key for a different action is refused',
        () async {
          await begin(participant, 'reused-key');
          final second = await endpoints.actionVerification.createAction(
            creator,
            _venueRequest(actionKey: 'second-visit'),
          );

          await expectLater(
            endpoints.actionVerification.beginAttempt(
              participant,
              actionId: second.id,
              idempotencyKey: 'reused-key',
            ),
            throwsStateError,
          );
        },
      );

      test('then an unknown or paused action cannot be started', () async {
        await expectLater(
          endpoints.actionVerification.beginAttempt(
            participant,
            actionId: testId(0xdead),
            idempotencyKey: 'unknown-action',
          ),
          throwsStateError,
        );
        await endpoints.actionVerification.pauseAction(
          creator,
          actionId: action.id,
          expectedRevision: action.revision,
        );
        await expectLater(
          begin(participant, 'paused-action'),
          throwsStateError,
        );
      });
    });

    group('when a participant checks in', () {
      test(
        'then PostGIS accepts the place and stores a geography point',
        () async {
          final attempt = await begin(participant);

          final result = await checkIn(participant, attempt.id);

          expect(result.status, EvidenceDecisionStatus.accepted);
          expect(result.reasonCode, 'proof_accepted');
          expect(result.confidence, 1);
          expect(result.requirementId, location.id);
          final stored = await ActionEvidence.db.findFirstRow(
            sessionBuilder.build(),
            where: (table) => table.attemptId.equals(attempt.id),
          );
          expect(
            stored!.location,
            GeographyPoint(
              latitude: _bigBen.latitude,
              longitude: _bigBen.longitude,
            ),
          );
          expect(stored.accuracyMeters, 10);
        },
      );

      test('then a check-in outside the radius is rejected', () async {
        final attempt = await begin(participant);

        // About 200 m north of the 150 m geofence.
        final result = await checkIn(
          participant,
          attempt.id,
          at: (latitude: 51.5025, longitude: -0.1246),
        );

        expect(result.status, EvidenceDecisionStatus.rejected);
        expect(result.reasonCode, 'outside_area');
      });

      test('then an imprecise check-in is rejected', () async {
        final attempt = await begin(participant);

        final result = await checkIn(
          participant,
          attempt.id,
          accuracyMeters: 80,
        );

        expect(result.status, EvidenceDecisionStatus.rejected);
        expect(result.reasonCode, 'location_not_precise');
      });

      test('then stale and future captures are rejected', () async {
        final attempt = await begin(participant);
        final now = DateTime.now().toUtc();

        final stale = await checkIn(
          participant,
          attempt.id,
          capturedAt: now.subtract(const Duration(minutes: 6)),
        );
        final future = await checkIn(
          participant,
          attempt.id,
          capturedAt: now.add(const Duration(minutes: 3)),
        );

        expect(stale.status, EvidenceDecisionStatus.rejected);
        expect(stale.reasonCode, 'location_too_old');
        expect(future.status, EvidenceDecisionStatus.rejected);
        expect(future.reasonCode, 'phone_clock');
      });

      test('then incomplete or wrapped coordinates are refused', () async {
        final attempt = await begin(participant);

        await expectLater(
          endpoints.actionVerification.submitEvidence(
            participant,
            ActionEvidenceInput(
              attemptId: attempt.id,
              requirementId: location.id,
              capturedAt: DateTime.now().toUtc(),
              latitude: _bigBen.latitude,
              longitude: _bigBen.longitude,
            ),
          ),
          throwsArgumentError,
        );
        // PostGIS geography would silently store latitude 95 as 85.
        await expectLater(
          endpoints.actionVerification.submitEvidence(
            participant,
            ActionEvidenceInput(
              attemptId: attempt.id,
              requirementId: venue.id,
              capturedAt: DateTime.now().toUtc(),
              qrCode: await liveCode(),
              latitude: 95,
              longitude: _bigBen.longitude,
            ),
          ),
          throwsArgumentError,
        );
        expect(
          await ActionEvidence.db.count(
            sessionBuilder.build(),
            where: (table) => table.attemptId.equals(attempt.id),
          ),
          0,
        );
      });

      test(
        'then implausible travel between accepted places goes to review',
        () async {
          final london = await begin(participant, 'london');
          expect(
            (await checkIn(participant, london.id)).status,
            EvidenceDecisionStatus.accepted,
          );
          final paris = await endpoints.actionVerification.createAction(
            creator,
            actionRequest(
              actionKey: 'paris-visit',
              requirements: [
                locationRequirement(
                  latitude: _paris.latitude,
                  longitude: _paris.longitude,
                ),
              ],
            ),
          );
          final parisAttempt = await endpoints.actionVerification.beginAttempt(
            participant,
            actionId: paris.id,
            idempotencyKey: 'paris',
          );

          final result = await checkIn(
            participant,
            parisAttempt.id,
            at: _paris,
            requirement: paris.requirements.single,
          );

          expect(result.status, EvidenceDecisionStatus.manualReview);
          expect(result.reasonCode, 'needs_review');
        },
      );
    });

    group('when a participant scans a venue code', () {
      test(
        'then the creator static code is refused while static codes are '
        'off',
        () async {
          final attempt = await begin(participant);

          final result = await scan(
            participant,
            attempt.id,
            _staticVenueCode,
          );

          expect(result.status, EvidenceDecisionStatus.rejected);
          expect(result.reasonCode, 'code_not_matched');
        },
      );

      test(
        'then a live code verifies once and its replay is rejected',
        () async {
          final challenge = await endpoints.actionVerification
              .createQrChallenge(
                creator,
                requirementId: venue.id,
                validitySeconds: 60,
              );
          expect(challenge.code, startsWith('verily:v1:'));
          expect(challenge.expiresAt.isAfter(DateTime.now().toUtc()), isTrue);

          final firstAttempt = await begin(participant);
          final accepted = await scan(
            participant,
            firstAttempt.id,
            challenge.code,
          );
          // Resubmitting on the same attempt still finds its own code.
          final resubmitted = await scan(
            participant,
            firstAttempt.id,
            challenge.code,
          );
          final replayAttempt = await begin(other);
          final replayed = await scan(
            other,
            replayAttempt.id,
            challenge.code,
          );

          expect(accepted.status, EvidenceDecisionStatus.accepted);
          expect(accepted.reasonCode, 'proof_accepted');
          expect(resubmitted.status, EvidenceDecisionStatus.accepted);
          expect(replayed.status, EvidenceDecisionStatus.rejected);
          final stored = await ActionQrChallenge.db.findFirstRow(
            sessionBuilder.build(),
            where: (table) => table.requirementId.equals(venue.id),
          );
          expect(stored!.secretHash, secretSha256Hex(challenge.code));
          expect(stored.secretHash, isNot(challenge.code));
          expect(stored.usedByAttemptId, firstAttempt.id);
          expect(stored.usedAt, isNotNull);
        },
      );

      test('then an expired live code is rejected', () async {
        const code = 'verily:v1:expired-test-code-0000000000';
        final now = DateTime.now().toUtc();
        await ActionQrChallenge.db.insertRow(
          sessionBuilder.build(),
          ActionQrChallenge(
            requirementId: venue.id,
            createdByAuthUserId: creatorId,
            secretHash: secretSha256Hex(code),
            createdAt: now.subtract(const Duration(minutes: 10)),
            expiresAt: now.subtract(const Duration(minutes: 5)),
          ),
        );
        final attempt = await begin(participant);

        final result = await scan(participant, attempt.id, code);

        expect(result.status, EvidenceDecisionStatus.rejected);
        expect(result.reasonCode, 'code_not_matched');
      });

      test('then codes need a bounded lifetime and a live action', () async {
        for (final seconds in [10, 901]) {
          await expectLater(
            endpoints.actionVerification.createQrChallenge(
              creator,
              requirementId: venue.id,
              validitySeconds: seconds,
            ),
            throwsArgumentError,
          );
        }
        await expectLater(
          endpoints.actionVerification.createQrChallenge(
            creator,
            requirementId: location.id,
            validitySeconds: 60,
          ),
          throwsStateError,
        );
        await endpoints.actionVerification.pauseAction(
          creator,
          actionId: action.id,
          expectedRevision: action.revision,
        );
        await expectLater(liveCode(), throwsStateError);
        expect(await ActionQrChallenge.db.count(sessionBuilder.build()), 0);
      });

      test(
        'then expired code audit rows are removed after retention',
        () async {
          final now = DateTime.now().toUtc();
          final session = sessionBuilder.build();
          final old = await ActionQrChallenge.db.insertRow(
            session,
            ActionQrChallenge(
              requirementId: venue.id,
              createdByAuthUserId: creatorId,
              secretHash: 'a' * 64,
              createdAt: now.subtract(const Duration(days: 9)),
              expiresAt: now.subtract(const Duration(days: 8)),
            ),
          );
          final current = await ActionQrChallenge.db.insertRow(
            session,
            ActionQrChallenge(
              requirementId: venue.id,
              createdByAuthUserId: creatorId,
              secretHash: 'b' * 64,
              createdAt: now,
              expiresAt: now.add(const Duration(minutes: 5)),
            ),
          );

          await endpoints.futureCalls.actionQrChallengeCleanup.cleanup(
            sessionBuilder,
            ActionQrChallengeCleanupTask(batchSize: 100),
          );

          expect(await ActionQrChallenge.db.findById(session, old.id!), isNull);
          expect(
            await ActionQrChallenge.db.findById(session, current.id!),
            isNotNull,
          );
        },
      );
    });

    group('when proof is bound to a capture window', () {
      late _TrustedDeviceIntegrityVerifier integrityVerifier;
      late ActionVerificationService attestedService;
      final authority = TestAttestationAuthority();

      setUp(() {
        integrityVerifier = _TrustedDeviceIntegrityVerifier();
        attestedService = ActionVerificationService(
          captureIntegrity: CaptureIntegrityEvaluator(
            deviceIntegrityRequired: true,
            deviceIntegrityVerifier: integrityVerifier,
          ),
        );
      });

      /// A service that requires an attested capture key, trusting
      /// [authority]'s root the way production trusts Google's.
      ActionVerificationService signedService({bool required = true}) =>
          ActionVerificationService(
            captureIntegrity: CaptureIntegrityEvaluator(
              captureSignatureRequired: required,
              deviceIntegrityVerifier: integrityVerifier,
              keyAttestationVerifier: AndroidKeyAttestationVerifier(
                policy: KeyAttestationPolicy(
                  signingCertificateDigests: {testSigningCertificateDigest},
                ),
                trustAnchors: required ? [authority.root] : null,
                statusSource: _NothingListed(),
              ),
            ),
          );

      /// What the device signs and asks Play to vouch for, once the venue
      /// code is captured inside [window].
      ({String bindingHash, String requestHash, List<int> manifest}) bound(
        ActionAttemptView attempt,
        ActionCaptureChallengeView window,
        DateTime capturedAt,
        String code,
      ) {
        final bindingHash = qrEvidenceBindingHash(
          capturedAt: capturedAt,
          code: code,
        );
        final requestHash = captureIntegrityRequestHash(
          attemptId: attempt.id.toString(),
          requirementId: venue.id.toString(),
          captureChallenge: window.captureChallenge,
          evidenceBindingHash: bindingHash,
        );
        return (
          bindingHash: bindingHash,
          requestHash: requestHash,
          manifest: captureProvenanceManifest(
            attemptId: attempt.id.toString(),
            requirementId: venue.id.toString(),
            requestHash: requestHash,
            evidenceBindingHash: bindingHash,
          ),
        );
      }

      Future<ActionCaptureChallengeView> open(
        ActionVerificationService service,
        ActionAttemptView attempt,
      ) => service.beginCapture(
        participant.build(),
        authUserId: participantId,
        attemptId: attempt.id,
        requirementId: venue.id,
      );

      test(
        'then a Play-attested proof consumes its window once and records '
        'what it was bound to',
        () async {
          final attempt = await begin(participant);
          final session = participant.build();
          final window = await open(attestedService, attempt);
          final capturedAt = DateTime.now().toUtc();
          final code = await liveCode();
          final binding = bound(attempt, window, capturedAt, code);
          expect(window.integrityRequired, isTrue);
          final input = ActionEvidenceInput(
            attemptId: attempt.id,
            requirementId: venue.id,
            capturedAt: capturedAt,
            qrCode: code,
            captureChallengeId: window.id,
            deviceIntegrityToken: _tokenFor(binding.requestHash),
          );

          final result = await attestedService.submitEvidence(
            session,
            authUserId: participantId,
            input: input,
          );

          expect(result.status, EvidenceDecisionStatus.accepted);
          expect(result.provenanceLevel, EvidenceProvenanceLevel.appAttested);
          expect(integrityVerifier.requestHash, binding.requestHash);
          final stored = await ActionCaptureChallenge.db.findById(
            session,
            window.id,
          );
          expect(stored!.usedAt, isNotNull);
          expect(stored.nonce, window.captureChallenge);
          expect(stored.requestHash, binding.requestHash);
          expect(stored.evidenceBindingHash, binding.bindingHash);
          expect(stored.provider, integrityVerifier.providerName);
          expect(stored.verdict, 'device_integrity_met');
          expect(
            stored.tokenHash,
            secretSha256Hex(_tokenFor(binding.requestHash)),
          );

          final replay = await attestedService.submitEvidence(
            session,
            authUserId: participantId,
            input: input,
          );
          expect(replay.status, EvidenceDecisionStatus.rejected);
          expect(replay.reasonCode, 'capture_not_verified');
        },
      );

      test(
        'then a manifest signed by a key attested for the window is '
        'verified and kept with the proof',
        () async {
          final service = signedService();
          final attempt = await begin(participant);
          final session = participant.build();
          final window = await open(service, attempt);
          // The phone generates its capture key as the window opens, with
          // the window's nonce in the key's attestation.
          final key = authority.issue(
            challenge: captureKeyAttestationChallenge(
              captureChallenge: window.captureChallenge,
              attemptId: attempt.id.toString(),
            ),
          );
          final capturedAt = DateTime.now().toUtc();
          final code = await liveCode();
          final binding = bound(attempt, window, capturedAt, code);

          final result = await service.submitEvidence(
            session,
            authUserId: participantId,
            input: ActionEvidenceInput(
              attemptId: attempt.id,
              requirementId: venue.id,
              capturedAt: capturedAt,
              qrCode: code,
              captureChallengeId: window.id,
              captureManifest: base64Encode(binding.manifest),
              captureSignature: key.signP1363(binding.manifest),
              captureCertificateChain: key.encodedChain,
            ),
          );

          expect(window.signatureRequired, isTrue);
          expect(result.status, EvidenceDecisionStatus.accepted);
          expect(
            result.provenanceLevel,
            EvidenceProvenanceLevel.hardwareAttested,
          );
          final evidence = await ActionEvidence.db.findFirstRow(
            session,
            where: (table) => table.attemptId.equals(attempt.id),
          );
          expect(
            evidence!.provenanceLevel,
            EvidenceProvenanceLevel.hardwareAttested,
          );
          expect(evidence.captureManifest, base64Encode(binding.manifest));
          expect(evidence.capturePublicKey, base64Encode(key.publicKey));
          expect(evidence.captureKeyId, capturePublicKeyId(key.publicKey));
          // Read from the attestation, never from the phone's own claim.
          expect(evidence.captureKeyStorage, 'trustedEnvironment');
          expect(evidence.captureCertificateChain, key.encodedChain);
          expect(evidence.captureDeviceKeyId, hasLength(64));
          final stored = await ActionCaptureChallenge.db.findById(
            session,
            window.id,
          );
          expect(stored!.provider, CaptureIntegrityProvider.keyAttestation);
          expect(stored.verdict, KeyAttestationReason.valid);
        },
      );

      test(
        'then a key attested for another window is refused',
        () async {
          final service = signedService();
          final attempt = await begin(participant);
          final session = participant.build();
          final earlier = await open(service, attempt);
          final window = await open(service, attempt);
          final key = authority.issue(
            challenge: captureKeyAttestationChallenge(
              captureChallenge: earlier.captureChallenge,
              attemptId: attempt.id.toString(),
            ),
          );
          final capturedAt = DateTime.now().toUtc();
          final code = await liveCode();
          final binding = bound(attempt, window, capturedAt, code);

          final result = await service.submitEvidence(
            session,
            authUserId: participantId,
            input: ActionEvidenceInput(
              attemptId: attempt.id,
              requirementId: venue.id,
              capturedAt: capturedAt,
              qrCode: code,
              captureChallengeId: window.id,
              captureManifest: base64Encode(binding.manifest),
              captureSignature: key.signP1363(binding.manifest),
              captureCertificateChain: key.encodedChain,
            ),
          );

          expect(result.status, EvidenceDecisionStatus.rejected);
          expect(result.reasonCode, 'capture_not_verified');
          final stored = await ActionCaptureChallenge.db.findById(
            session,
            window.id,
          );
          expect(stored!.verdict, KeyAttestationReason.challengeMismatch);
        },
      );

      test(
        'then a signature from a key other than the attested one is '
        'refused',
        () async {
          final service = signedService();
          final attempt = await begin(participant);
          final session = participant.build();
          final window = await open(service, attempt);
          final challenge = captureKeyAttestationChallenge(
            captureChallenge: window.captureChallenge,
            attemptId: attempt.id.toString(),
          );
          final attested = authority.issue(challenge: challenge);
          final other = authority.issue(
            challenge: challenge,
            keySeed: 'another-key',
          );
          final capturedAt = DateTime.now().toUtc();
          final code = await liveCode();
          final binding = bound(attempt, window, capturedAt, code);

          final result = await service.submitEvidence(
            session,
            authUserId: participantId,
            input: ActionEvidenceInput(
              attemptId: attempt.id,
              requirementId: venue.id,
              capturedAt: capturedAt,
              qrCode: code,
              captureChallengeId: window.id,
              captureManifest: base64Encode(binding.manifest),
              captureSignature: other.signP1363(binding.manifest),
              captureCertificateChain: attested.encodedChain,
            ),
          );

          expect(result.status, EvidenceDecisionStatus.rejected);
          final stored = await ActionCaptureChallenge.db.findById(
            session,
            window.id,
          );
          expect(stored!.verdict, 'capture_signature_invalid');
        },
      );

      test(
        'then with signatures optional an unattested key is recorded as '
        'device-signed, without a storage claim',
        () async {
          // Production roots only: the test authority is not trusted, as
          // an emulator's software attestation would not be.
          final service = signedService(required: false);
          final attempt = await begin(participant);
          final session = participant.build();
          final window = await open(service, attempt);
          final key = authority.issue(
            challenge: captureKeyAttestationChallenge(
              captureChallenge: window.captureChallenge,
              attemptId: attempt.id.toString(),
            ),
          );
          final capturedAt = DateTime.now().toUtc();
          final code = await liveCode();
          final binding = bound(attempt, window, capturedAt, code);

          final result = await service.submitEvidence(
            session,
            authUserId: participantId,
            input: ActionEvidenceInput(
              attemptId: attempt.id,
              requirementId: venue.id,
              capturedAt: capturedAt,
              qrCode: code,
              captureChallengeId: window.id,
              captureManifest: base64Encode(binding.manifest),
              captureSignature: key.signP1363(binding.manifest),
              captureCertificateChain: key.encodedChain,
            ),
          );

          expect(result.status, EvidenceDecisionStatus.accepted);
          expect(result.provenanceLevel, EvidenceProvenanceLevel.deviceSigned);
          final evidence = await ActionEvidence.db.findFirstRow(
            session,
            where: (table) => table.attemptId.equals(attempt.id),
          );
          expect(evidence!.captureKeyStorage, isNull);
          expect(evidence.captureDeviceKeyId, isNull);
          expect(evidence.captureKeyId, capturePublicKeyId(key.publicKey));
        },
      );

      test(
        'then a trusted token bound to different evidence is rejected',
        () async {
          final attempt = await begin(participant);
          final session = participant.build();
          final window = await open(attestedService, attempt);
          final capturedAt = DateTime.now().toUtc();
          final code = await liveCode();
          // Play vouched for another capture than the one submitted.
          final elsewhere = bound(
            attempt,
            window,
            capturedAt,
            'a-different-venue-code',
          );

          final result = await attestedService.submitEvidence(
            session,
            authUserId: participantId,
            input: ActionEvidenceInput(
              attemptId: attempt.id,
              requirementId: venue.id,
              capturedAt: capturedAt,
              qrCode: code,
              captureChallengeId: window.id,
              deviceIntegrityToken: _tokenFor(elsewhere.requestHash),
            ),
          );

          expect(result.status, EvidenceDecisionStatus.rejected);
          expect(result.reasonCode, 'capture_not_verified');
          final stored = await ActionCaptureChallenge.db.findById(
            session,
            window.id,
          );
          expect(stored!.usedAt, isNotNull);
          expect(stored.verdict, 'device_integrity_invalid');
          // An untrusted capture never consumes the venue code.
          final qr = await ActionQrChallenge.db.findFirstRow(
            session,
            where: (table) => table.secretHash.equals(secretSha256Hex(code)),
          );
          expect(qr!.usedAt, isNull);
        },
      );

      test(
        'then proof captured before its window opened is rejected',
        () async {
          final attempt = await begin(participant);
          final session = participant.build();
          final capturedAt = DateTime.now().toUtc().subtract(
            const Duration(minutes: 10),
          );
          final code = await liveCode();
          final window = await open(attestedService, attempt);
          final binding = bound(attempt, window, capturedAt, code);

          final result = await attestedService.submitEvidence(
            session,
            authUserId: participantId,
            input: ActionEvidenceInput(
              attemptId: attempt.id,
              requirementId: venue.id,
              capturedAt: capturedAt,
              qrCode: code,
              captureChallengeId: window.id,
              deviceIntegrityToken: _tokenFor(binding.requestHash),
            ),
          );

          expect(result.status, EvidenceDecisionStatus.rejected);
          final stored = await ActionCaptureChallenge.db.findById(
            session,
            window.id,
          );
          expect(stored!.verdict, 'capture_predates_challenge');
        },
      );

      test(
        'then a device risk Play reports sends the proof to a person',
        () async {
          integrityVerifier.reviewReasonCode = deviceCaptureRiskReviewCode;
          final attempt = await begin(participant);
          final session = participant.build();
          final window = await open(attestedService, attempt);
          final capturedAt = DateTime.now().toUtc();
          final code = await liveCode();
          final binding = bound(attempt, window, capturedAt, code);

          final result = await attestedService.submitEvidence(
            session,
            authUserId: participantId,
            input: ActionEvidenceInput(
              attemptId: attempt.id,
              requirementId: venue.id,
              capturedAt: capturedAt,
              qrCode: code,
              captureChallengeId: window.id,
              deviceIntegrityToken: _tokenFor(binding.requestHash),
            ),
          );

          expect(result.status, EvidenceDecisionStatus.manualReview);
          expect(result.reasonCode, 'needs_review');
          final evidence = await ActionEvidence.db.findFirstRow(
            session,
            where: (table) => table.attemptId.equals(attempt.id),
          );
          final decision = await EvidenceDecision.db.findFirstRow(
            session,
            where: (table) => table.evidenceId.equals(evidence!.id),
          );
          expect(decision!.reasonCode, deviceCaptureRiskReviewCode);
          expect(decision.verifierType, integrityVerifier.providerName);
        },
      );

      test('then a proof without required integrity is rejected', () async {
        final attempt = await begin(participant);

        final result = await attestedService.submitEvidence(
          participant.build(),
          authUserId: participantId,
          input: ActionEvidenceInput(
            attemptId: attempt.id,
            requirementId: venue.id,
            capturedAt: DateTime.now().toUtc(),
            qrCode: await liveCode(),
          ),
        );

        expect(result.status, EvidenceDecisionStatus.rejected);
        expect(result.reasonCode, 'capture_not_verified');
      });

      test(
        'then windows open with a fresh nonce, are rate limited, and belong '
        'to the participant',
        () async {
          final attempt = await begin(participant);
          final nonces = <String>{};
          for (var index = 0; index < maxCaptureChallengesPerHour; index += 1) {
            final window = await endpoints.actionVerification.beginCapture(
              participant,
              attemptId: attempt.id,
              requirementId: venue.id,
            );
            nonces.add(window.captureChallenge);
            expect(
              window.expiresAt.difference(window.issuedAt),
              captureChallengeLifetime,
            );
          }
          expect(nonces, hasLength(maxCaptureChallengesPerHour));

          await expectLater(
            endpoints.actionVerification.beginCapture(
              participant,
              attemptId: attempt.id,
              requirementId: venue.id,
            ),
            throwsStateError,
          );
          await expectLater(
            endpoints.actionVerification.beginCapture(
              other,
              attemptId: attempt.id,
              requirementId: venue.id,
            ),
            throwsStateError,
          );
        },
      );

      group('and an iPhone signs with its App Attest key', () {
        final apple = TestAppAttestAuthority();
        late TestAppleDeviceClient deviceClient;
        final deviceToken = base64Encode(utf8.encode('device-token'));
        late AppAttestService appAttest;
        late ActionVerificationService service;

        setUp(() {
          deviceClient = TestAppleDeviceClient(apple.receipts);
          // Trusts the test authority's root the way production trusts
          // Apple's.
          appAttest = AppAttestService(
            receiptVerifier: AppAttestReceiptVerifier(
              root: apple.receipts.root,
            ),
            apple: deviceClient,
            verifier: AppAttestVerifier(
              policy: testAppAttestPolicy(),
              trustAnchors: [apple.root],
            ),
          );
          service = ActionVerificationService(
            captureIntegrity: CaptureIntegrityEvaluator(
              captureSignatureRequired: true,
              deviceIntegrityVerifier: integrityVerifier,
              keyAttestationVerifier: AndroidKeyAttestationVerifier(
                policy: KeyAttestationPolicy(
                  signingCertificateDigests: {testSigningCertificateDigest},
                ),
                statusSource: _NothingListed(),
              ),
              appAttest: appAttest,
            ),
          );
        });

        /// Registers a key for [who] the way the app does before its first
        /// capture: a server challenge, then Apple's attestation over it.
        Future<TestAppAttestKey> register(
          TestSessionBuilder who,
          UuidValue whoId, {
          String keySeed = 'install',
        }) async {
          final session = who.build();
          final challenge = await appAttest.beginRegistration(
            session,
            authUserId: whoId,
          );
          final key = apple.attest(
            clientDataHash: appAttestRegistrationClientDataHash(
              challenge.challenge,
            ),
            keySeed: keySeed,
          );
          await appAttest.registerKey(
            session,
            authUserId: whoId,
            challengeId: challenge.id,
            keyId: key.keyId,
            attestationObject: key.encodedAttestation,
          );
          return key;
        }

        /// Scans a live venue code inside a new window and signs it with an
        /// assertion by [key] at [counter].
        Future<(EvidenceSubmissionResult, ActionCaptureChallengeView)> scan(
          ActionAttemptView attempt,
          TestAppAttestKey key, {
          required int counter,
          String? keyId,
          List<String>? certificateChain,
          String? sentToken,
          bool legacy = false,
        }) async {
          final window = await open(service, attempt);
          final capturedAt = DateTime.now().toUtc();
          final code = await liveCode();
          final binding = bound(attempt, window, capturedAt, code);
          final result = await service.submitEvidence(
            participant.build(),
            authUserId: participantId,
            input: ActionEvidenceInput(
              attemptId: attempt.id,
              requirementId: venue.id,
              capturedAt: capturedAt,
              qrCode: code,
              captureChallengeId: window.id,
              captureManifest: base64Encode(binding.manifest),
              captureSignature: key.encodedAssertion(
                legacy
                    ? binding.manifest
                    : appAttestDeviceClientData(binding.manifest, deviceToken),
                counter: counter,
              ),
              captureAppAttestKeyId: keyId ?? key.keyId,
              captureDeviceCheckToken: legacy ? null : sentToken ?? deviceToken,
              captureCertificateChain: certificateChain,
            ),
          );
          return (result, window);
        }

        test(
          'an expired receipt cannot reuse a previously low metric',
          () async {
            final key = await register(participant, participantId);
            final attempt = await begin(participant);
            final (first, _) = await scan(attempt, key, counter: 1);
            expect(first.status, EvidenceDecisionStatus.accepted);
            final row = (await AppAttestKey.db.findFirstRow(
              participant.build(),
            ))!;
            await AppAttestKey.db.updateRow(
              participant.build(),
              row.copyWith(
                receiptExpiresAt: DateTime.now().toUtc().subtract(
                  const Duration(seconds: 1),
                ),
              ),
            );
            final (expired, _) = await scan(attempt, key, counter: 2);
            expect(expired.status, EvidenceDecisionStatus.manualReview);
            expect(deviceClient.refreshes, 1);
          },
        );

        Future<String?> verdictOf(ActionCaptureChallengeView window) async =>
            (await ActionCaptureChallenge.db.findById(
              participant.build(),
              window.id,
            ))!.verdict;

        test(
          'a high verified receipt metric holds automatic acceptance',
          () async {
            deviceClient.metric = 10;
            final key = await register(participant, participantId);
            final attempt = await begin(participant);
            final (result, _) = await scan(attempt, key, counter: 1);
            expect(result.status, EvidenceDecisionStatus.manualReview);
            final stored = await AppAttestKey.db.findFirstRow(
              participant.build(),
            );
            expect(stored!.riskMetric, 10);
            final receipt = stored.receipt;
            final (again, _) = await scan(attempt, key, counter: 2);
            expect(again.status, EvidenceDecisionStatus.manualReview);
            expect(deviceClient.refreshes, 1);
            expect(
              (await AppAttestKey.db.findById(
                participant.build(),
                stored.id!,
              ))!.receipt,
              receipt,
            );
          },
        );

        test(
          'DeviceCheck ban survives a newly registered install key',
          () async {
            deviceClient.bits = const AppleDeviceBits(
              banned: true,
              reviewRequired: false,
            );
            final attempt = await begin(participant);
            for (final seed in ['first-install', 'reinstalled']) {
              final key = await register(
                participant,
                participantId,
                keySeed: seed,
              );
              final (result, window) = await scan(attempt, key, counter: 1);
              expect(result.status, EvidenceDecisionStatus.rejected);
              expect(await verdictOf(window), 'capture_device_banned');
            }
          },
        );

        test(
          'review bit and Apple outages hold the proof for a person',
          () async {
            final key = await register(participant, participantId);
            final attempt = await begin(participant);
            deviceClient.bits = const AppleDeviceBits(
              banned: false,
              reviewRequired: true,
            );
            final (review, _) = await scan(attempt, key, counter: 1);
            expect(review.status, EvidenceDecisionStatus.manualReview);
            deviceClient
              ..bits = const AppleDeviceBits(
                banned: false,
                reviewRequired: false,
              )
              ..unavailable = true;
            final (outage, _) = await scan(attempt, key, counter: 2);
            expect(outage.status, EvidenceDecisionStatus.manualReview);
          },
        );

        test(
          'invalid refresh preserves the verified receipt and backs off',
          () async {
            final key = await register(participant, participantId);
            final before = (await AppAttestKey.db.findFirstRow(
              participant.build(),
            ))!;
            final attempt = await begin(participant);
            deviceClient.invalidReceipt = true;
            final (result, _) = await scan(attempt, key, counter: 1);
            expect(result.status, EvidenceDecisionStatus.manualReview);
            final after = (await AppAttestKey.db.findById(
              participant.build(),
              before.id!,
            ))!;
            expect(after.receipt, before.receipt);
            expect(after.riskMetric, isNull);
            expect(
              after.receiptRefreshAfter.isAfter(before.receiptRefreshAfter),
              isTrue,
            );
            final (again, _) = await scan(attempt, key, counter: 2);
            expect(again.status, EvidenceDecisionStatus.manualReview);
            expect(deviceClient.refreshes, 1);
          },
        );

        test('token substitution fails the assertion; legacy clients cannot bypass review', () async {
          final key = await register(participant, participantId);
          final attempt = await begin(participant);
          final (tampered, window) = await scan(
            attempt,
            key,
            counter: 1,
            sentToken: base64Encode(utf8.encode('another-phone')),
          );
          expect(tampered.status, EvidenceDecisionStatus.rejected);
          expect(await verdictOf(window), AppAttestReason.signatureInvalid);
          final (legacy, _) = await scan(
            attempt,
            key,
            counter: 2,
            legacy: true,
          );
          expect(legacy.status, EvidenceDecisionStatus.manualReview);
          expect(deviceClient.refreshes, 0);
        });

        test(
          'scheduled refresh maintains inactive keys and respects not-before',
          () async {
            final key = await register(participant, participantId);
            await appAttest.refreshDueReceipts(participant.build());
            final stored = (await AppAttestKey.db.findFirstRow(
              participant.build(),
            ))!;
            expect(stored.keyId, capturePublicKeyId(key.publicKey));
            expect(stored.riskMetric, 2);
            expect(stored.signCount, 0);
            await appAttest.refreshDueReceipts(participant.build());
            expect(deviceClient.refreshes, 1);
          },
        );

        test(
          'then a registered key asserting the manifest is recorded at the '
          'Secure Enclave level, without a boot claim',
          () async {
            final key = await register(participant, participantId);
            final attempt = await begin(participant);
            final session = participant.build();

            final (result, window) = await scan(attempt, key, counter: 1);

            expect(result.status, EvidenceDecisionStatus.accepted);
            expect(
              result.provenanceLevel,
              EvidenceProvenanceLevel.secureEnclaveAttested,
            );
            final evidence = await ActionEvidence.db.findFirstRow(
              session,
              where: (table) => table.attemptId.equals(attempt.id),
            );
            expect(
              evidence!.provenanceLevel,
              EvidenceProvenanceLevel.secureEnclaveAttested,
            );
            expect(evidence.capturePublicKey, base64Encode(key.publicKey));
            expect(evidence.captureKeyId, capturePublicKeyId(key.publicKey));
            expect(evidence.captureKeyStorage, 'secureEnclave');
            expect(evidence.captureCertificateChain, isNull);
            expect(evidence.captureDeviceKeyId, isNull);
            final stored = await ActionCaptureChallenge.db.findById(
              session,
              window.id,
            );
            expect(stored!.usedAt, isNotNull);
            expect(stored.provider, CaptureIntegrityProvider.appAttest);
            expect(stored.verdict, AppAttestReason.valid);
            final registered = await AppAttestKey.db.findFirstRow(
              session,
              where: (table) =>
                  table.keyId.equals(capturePublicKeyId(key.publicKey)),
            );
            expect(registered!.authUserId, participantId);
            expect(registered.signCount, 1);
            expect(registered.lastAssertedAt, isNotNull);
            expect(registered.environment, AppAttestEnvironment.production);
            expect(registered.certificateChain, hasLength(2));
            expect(registered.receipt, isNotEmpty);
          },
        );

        test(
          'then an assertion whose counter does not advance is refused',
          () async {
            final key = await register(participant, participantId);
            final attempt = await begin(participant);
            await scan(attempt, key, counter: 3);

            final (replayed, window) = await scan(attempt, key, counter: 3);
            final (earlier, earlierWindow) = await scan(
              attempt,
              key,
              counter: 2,
            );

            expect(replayed.status, EvidenceDecisionStatus.rejected);
            expect(replayed.reasonCode, 'capture_not_verified');
            expect(await verdictOf(window), AppAttestReason.replayed);
            expect(earlier.status, EvidenceDecisionStatus.rejected);
            expect(await verdictOf(earlierWindow), AppAttestReason.replayed);
            final (next, _) = await scan(attempt, key, counter: 4);
            expect(next.status, EvidenceDecisionStatus.accepted);
          },
        );

        test(
          'then an assertion for another capture is refused',
          () async {
            final key = await register(participant, participantId);
            final attempt = await begin(participant);
            final window = await open(service, attempt);
            final capturedAt = DateTime.now().toUtc();
            final code = await liveCode();
            final binding = bound(attempt, window, capturedAt, code);
            final elsewhere = bound(attempt, window, capturedAt, 'another');

            final result = await service.submitEvidence(
              participant.build(),
              authUserId: participantId,
              input: ActionEvidenceInput(
                attemptId: attempt.id,
                requirementId: venue.id,
                capturedAt: capturedAt,
                qrCode: code,
                captureChallengeId: window.id,
                captureManifest: base64Encode(binding.manifest),
                captureSignature: key.encodedAssertion(
                  elsewhere.manifest,
                  counter: 1,
                ),
                captureAppAttestKeyId: key.keyId,
              ),
            );

            expect(result.status, EvidenceDecisionStatus.rejected);
            expect(await verdictOf(window), AppAttestReason.signatureInvalid);
          },
        );

        test(
          'then a key registered to another account or to no one is '
          'refused',
          () async {
            final theirs = await register(other, otherId, keySeed: 'theirs');
            final unregistered = apple.attest(
              clientDataHash: List.filled(32, 0),
              keySeed: 'never-registered',
            );
            final attempt = await begin(participant);

            final (borrowed, borrowedWindow) = await scan(
              attempt,
              theirs,
              counter: 1,
            );
            final (unknown, unknownWindow) = await scan(
              attempt,
              unregistered,
              counter: 1,
            );

            expect(borrowed.status, EvidenceDecisionStatus.rejected);
            expect(await verdictOf(borrowedWindow), AppAttestReason.keyUnknown);
            expect(unknown.status, EvidenceDecisionStatus.rejected);
            expect(await verdictOf(unknownWindow), AppAttestReason.keyUnknown);
          },
        );

        test(
          'then a proof naming both an Android chain and an App Attest key '
          'is refused',
          () async {
            final key = await register(participant, participantId);
            final attempt = await begin(participant);

            final (result, window) = await scan(
              attempt,
              key,
              counter: 1,
              certificateChain: authority
                  .issue(challenge: List.filled(32, 0))
                  .encodedChain,
            );

            expect(result.status, EvidenceDecisionStatus.rejected);
            expect(await verdictOf(window), 'capture_signature_ambiguous');
          },
        );

        test(
          'then registration needs a fresh challenge of the caller and a '
          'key no other account holds',
          () async {
            final session = participant.build();
            final challenge = await appAttest.beginRegistration(
              session,
              authUserId: participantId,
            );
            final key = apple.attest(
              clientDataHash: appAttestRegistrationClientDataHash(
                challenge.challenge,
              ),
            );
            Future<void> registerWith(
              UuidValue challengeId,
              TestAppAttestKey attested, {
              UuidValue? as,
            }) => appAttest.registerKey(
              session,
              authUserId: as ?? participantId,
              challengeId: challengeId,
              keyId: attested.keyId,
              attestationObject: attested.encodedAttestation,
            );
            Matcher refused(AppAttestProblem problem) => throwsA(
              isA<AppAttestException>().having(
                (error) => error.problem,
                'problem',
                problem,
              ),
            );

            // Another account cannot spend this account's challenge.
            await expectLater(
              registerWith(challenge.id, key, as: otherId),
              refused(AppAttestProblem.challengeInvalid),
            );
            await registerWith(challenge.id, key);
            // A challenge is used once.
            await expectLater(
              registerWith(challenge.id, key),
              refused(AppAttestProblem.challengeInvalid),
            );

            // An attestation made for another challenge is refused, and
            // its challenge is spent.
            final next = await appAttest.beginRegistration(
              session,
              authUserId: participantId,
            );
            await expectLater(
              registerWith(
                next.id,
                apple.attest(
                  clientDataHash: List.filled(32, 9),
                  keySeed: 'stale',
                ),
              ),
              refused(AppAttestProblem.keyRejected),
            );
            final spent = await AppAttestChallenge.db.findById(
              session,
              next.id,
            );
            expect(spent!.usedAt, isNotNull);

            // A key registered to this account cannot move to another.
            final theirs = await appAttest.beginRegistration(
              other.build(),
              authUserId: otherId,
            );
            await expectLater(
              appAttest.registerKey(
                other.build(),
                authUserId: otherId,
                challengeId: theirs.id,
                keyId: key.keyId,
                attestationObject: apple
                    .attest(
                      clientDataHash: appAttestRegistrationClientDataHash(
                        theirs.challenge,
                      ),
                    )
                    .encodedAttestation,
              ),
              refused(AppAttestProblem.keyRejected),
            );
          },
        );

        test(
          'then registration challenges are rate limited per account',
          () async {
            final session = participant.build();
            for (
              var index = 0;
              index < maxAppAttestChallengesPerHour;
              index += 1
            ) {
              await appAttest.beginRegistration(
                session,
                authUserId: participantId,
              );
            }

            await expectLater(
              appAttest.beginRegistration(session, authUserId: participantId),
              throwsA(
                isA<AppAttestException>().having(
                  (error) => error.problem,
                  'problem',
                  AppAttestProblem.rateLimited,
                ),
              ),
            );
            await appAttest.beginRegistration(
              other.build(),
              authUserId: otherId,
            );
          },
        );

        test(
          'then a server without an Apple team refuses registration',
          () async {
            await expectLater(
              endpoints.appAttest.beginRegistration(participant),
              throwsA(
                isA<AppAttestException>().having(
                  (error) => error.problem,
                  'problem',
                  AppAttestProblem.unavailable,
                ),
              ),
            );
          },
        );
      });
    });

    group('when a participant completes an attempt', () {
      test(
        'then accepted proof for every requirement verifies it',
        () async {
          final attempt = await begin(participant);
          await checkIn(participant, attempt.id);
          await scan(participant, attempt.id, await liveCode());

          final completed = await endpoints.actionVerification.completeAttempt(
            participant,
            attempt.id,
          );
          final again = await endpoints.actionVerification.completeAttempt(
            participant,
            attempt.id,
          );

          expect(completed.status, ActionAttemptStatus.verified);
          expect(completed.verifiedRank, 1);
          expect(completed.verificationScore, 1);
          expect(completed.verifiedAt, isNotNull);
          expect(completed.rewardOutcome, isNull);
          expect(again.id, completed.id);
          expect(again.verifiedRank, 1);
          final stored = await ActionDefinition.db.findById(
            sessionBuilder.build(),
            action.id,
          );
          expect(stored!.verifiedCompletions, 1);
          final mine = await endpoints.actionVerification.listMyAttempts(
            participant,
            limit: 10,
          );
          expect(mine.single.id, attempt.id);
          expect(mine.single.status, ActionAttemptStatus.verified);
          expect(
            await endpoints.actionVerification.listMyAttempts(other, limit: 10),
            isEmpty,
          );
          await expectLater(
            checkIn(participant, attempt.id),
            throwsStateError,
          );
        },
      );

      test('then missing proof keeps the attempt open', () async {
        final attempt = await begin(participant);
        await checkIn(participant, attempt.id);

        final completed = await endpoints.actionVerification.completeAttempt(
          participant,
          attempt.id,
        );

        expect(completed.status, ActionAttemptStatus.collectingEvidence);
        expect(completed.rejectionCode, 'proof_missing');
        final listed = await endpoints.actionVerification.listAvailableActions(
          participant,
          limit: 10,
        );
        expect(listed.single.myAttempt?.id, attempt.id);
        expect(listed.single.myAttempt?.acceptedRequirementIds, [location.id]);
        expect(listed.single.requirements, hasLength(2));
      });

      test('then a rejected proof rejects the attempt', () async {
        final attempt = await begin(participant);
        await checkIn(participant, attempt.id, at: _paris);
        await scan(participant, attempt.id, await liveCode());

        final completed = await endpoints.actionVerification.completeAttempt(
          participant,
          attempt.id,
        );

        expect(completed.status, ActionAttemptStatus.rejected);
        expect(completed.rejectionCode, 'outside_area');
      });

      test('then proof routed to a person waits for review', () async {
        final london = await begin(participant, 'anchor');
        await checkIn(participant, london.id);
        await scan(participant, london.id, await liveCode());
        await endpoints.actionVerification.completeAttempt(
          participant,
          london.id,
        );
        final paris = await endpoints.actionVerification.createAction(
          creator,
          actionRequest(
            actionKey: 'paris-review',
            requirements: [
              locationRequirement(
                latitude: _paris.latitude,
                longitude: _paris.longitude,
              ),
            ],
          ),
        );
        final attempt = await endpoints.actionVerification.beginAttempt(
          participant,
          actionId: paris.id,
          idempotencyKey: 'paris-review',
        );
        await checkIn(
          participant,
          attempt.id,
          at: _paris,
          requirement: paris.requirements.single,
        );

        final completed = await endpoints.actionVerification.completeAttempt(
          participant,
          attempt.id,
        );

        expect(completed.status, ActionAttemptStatus.pendingReview);
      });

      test('then an action with no required proof never verifies', () async {
        final session = sessionBuilder.build();
        await ActionRequirement.db.update(session, [
          for (final requirement in await ActionRequirement.db.find(
            session,
            where: (table) => table.actionDefinitionId.equals(action.id),
          ))
            requirement.copyWith(isRequired: false),
        ]);
        final attempt = await begin(participant);

        await expectLater(
          endpoints.actionVerification.completeAttempt(
            participant,
            attempt.id,
          ),
          throwsStateError,
        );
        final stored = await ActionAttempt.db.findById(session, attempt.id);
        expect(stored!.status, isNot(ActionAttemptStatus.verified));
      });

      test(
        'then another account can neither submit to nor complete it',
        () async {
          final attempt = await begin(participant);

          await expectLater(checkIn(other, attempt.id), throwsStateError);
          await expectLater(
            endpoints.actionVerification.completeAttempt(other, attempt.id),
            throwsStateError,
          );
          expect(
            await ActionEvidence.db.count(sessionBuilder.build()),
            0,
          );
        },
      );

      test(
        'then proof for another action or a media proof is refused here',
        () async {
          final media = await endpoints.actionVerification.createAction(
            creator,
            actionRequest(
              actionKey: 'photo-proof',
              requirements: [
                mediaRequirement(kind: ActionRequirementKind.photo),
              ],
            ),
          );
          final attempt = await begin(participant);
          final mediaAttempt = await endpoints.actionVerification.beginAttempt(
            participant,
            actionId: media.id,
            idempotencyKey: 'photo-attempt',
          );

          await expectLater(
            checkIn(
              participant,
              attempt.id,
              requirement: media.requirements.single,
            ),
            throwsStateError,
          );
          await expectLater(
            endpoints.actionVerification.submitEvidence(
              participant,
              ActionEvidenceInput(
                attemptId: mediaAttempt.id,
                requirementId: media.requirements.single.id,
                capturedAt: DateTime.now().toUtc(),
              ),
            ),
            throwsStateError,
          );
        },
      );
    });
  });

  withServerpod('Given daily actions in different time zones', (
    sessionBuilder,
    endpoints,
  ) {
    final creatorId = testId(0x211);
    final participantId = testId(0x212);

    setUp(() async {
      await insertAccounts(sessionBuilder.build(), {
        creatorId: 'Ada',
        participantId: 'Grace',
      });
    });

    test(
      'when the local day changes then a new attempt period begins',
      () async {
        final action = await endpoints.actionVerification.createAction(
          signedIn(sessionBuilder, creatorId),
          actionRequest(
            actionKey: 'auckland-daily',
            recurrence: ActionRecurrence.daily,
            requirements: [locationRequirement()],
          ).copyWith(timeZone: 'Pacific/Auckland'),
        );
        final session = sessionBuilder.build();
        // 12:00 UTC is already the next day in Auckland (UTC+13 in October).
        var now = DateTime.utc(2026, 10, 21, 12);
        final service = ActionVerificationService(clock: () => now);

        final first = await service.beginAttempt(
          session,
          authUserId: participantId,
          actionId: action.id,
          idempotencyKey: 'auckland-day-1',
        );
        now = now.add(const Duration(hours: 10));
        final sameDay = await service.beginAttempt(
          session,
          authUserId: participantId,
          actionId: action.id,
          idempotencyKey: 'auckland-day-1-retry',
        );
        now = now.add(const Duration(hours: 14));
        final nextDay = await service.beginAttempt(
          session,
          authUserId: participantId,
          actionId: action.id,
          idempotencyKey: 'auckland-day-2',
        );

        expect(first.periodKey, '2026-10-22');
        expect(sameDay.id, first.id);
        expect(nextDay.periodKey, '2026-10-23');
        expect(nextDay.id, isNot(first.id));
      },
    );

    test('when an action happens once then its period never ends', () async {
      final action = await endpoints.actionVerification.createAction(
        signedIn(sessionBuilder, creatorId),
        actionRequest(
          actionKey: 'one-time',
          requirements: [locationRequirement()],
        ),
      );
      var now = DateTime.utc(2026, 10, 21, 12);
      final service = ActionVerificationService(clock: () => now);
      final session = sessionBuilder.build();

      final first = await service.beginAttempt(
        session,
        authUserId: participantId,
        actionId: action.id,
        idempotencyKey: 'once-1',
      );
      now = now.add(const Duration(days: 30));
      final later = await service.beginAttempt(
        session,
        authUserId: participantId,
        actionId: action.id,
        idempotencyKey: 'once-2',
      );

      expect(first.periodKey, 'once');
      expect(later.id, first.id);
    });
  });

  withServerpod('Given a published phone-motion action', (
    sessionBuilder,
    endpoints,
  ) {
    final creatorId = testId(0x221);
    final participantId = testId(0x222);
    late TestSessionBuilder creator;
    late TestSessionBuilder participant;

    setUp(() async {
      creator = signedIn(sessionBuilder, creatorId);
      participant = signedIn(sessionBuilder, participantId);
      await insertAccounts(sessionBuilder.build(), {
        creatorId: 'Ada',
        participantId: 'Grace',
      });
    });

    Future<(ActionOpportunity, ActionAttemptView)> started(String key) async {
      final action = await endpoints.actionVerification.createAction(
        creator,
        actionRequest(
          actionKey: key,
          requirements: [_yawMotionRequirement(), locationRequirement()],
        ),
      );
      final attempt = await endpoints.actionVerification.beginAttempt(
        participant,
        actionId: action.id,
        idempotencyKey: key,
      );
      return (action, attempt);
    }

    test(
      'when a bound five-turn trace is submitted with a check-in then the '
      'attempt verifies',
      () async {
        final (action, attempt) = await started('five-yaw-turns');
        final motion = action.requirements.singleWhere(
          (item) => item.kind == ActionRequirementKind.motion,
        );
        final location = action.requirements.singleWhere(
          (item) => item.kind == ActionRequirementKind.location,
        );
        expect(motion.motionType, ActionMotionType.rotation);
        expect(motion.motionAxis, ActionMotionAxis.yaw);
        expect(motion.targetRepetitions, 5);
        final challenge = await endpoints.actionVerification.beginCapture(
          participant,
          attemptId: attempt.id,
          requirementId: motion.id,
        );
        final capturedAt = DateTime.now().toUtc();
        final samples = _rotationSamples(turns: 5, axis: ActionMotionAxis.yaw);

        final motionResult = await endpoints.actionVerification.submitEvidence(
          participant,
          ActionEvidenceInput(
            attemptId: attempt.id,
            requirementId: motion.id,
            capturedAt: capturedAt,
            motionSamples: samples,
            captureChallengeId: challenge.id,
          ),
        );
        final locationResult = await endpoints.actionVerification
            .submitEvidence(
              participant,
              ActionEvidenceInput(
                attemptId: attempt.id,
                requirementId: location.id,
                capturedAt: DateTime.now().toUtc(),
                latitude: _bigBen.latitude,
                longitude: _bigBen.longitude,
                accuracyMeters: 10,
              ),
            );
        final completed = await endpoints.actionVerification.completeAttempt(
          participant,
          attempt.id,
        );

        expect(motionResult.status, EvidenceDecisionStatus.accepted);
        expect(motionResult.reasonCode, 'proof_accepted');
        expect(motionResult.confidence, 1);
        expect(locationResult.status, EvidenceDecisionStatus.accepted);
        expect(completed.status, ActionAttemptStatus.verified);
        final session = sessionBuilder.build();
        final rule = await ActionMotionRule.db.findFirstRow(
          session,
          where: (table) => table.requirementId.equals(motion.id),
        );
        final evidence = await ActionEvidence.db.findFirstRow(
          session,
          where: (table) =>
              table.attemptId.equals(attempt.id) &
              table.requirementId.equals(motion.id),
        );
        expect(rule!.targetRepetitions, 5);
        expect(evidence!.motionTraceJson, isNotEmpty);
        expect(evidence.motionTraceSha256, hasLength(64));
        expect(evidence.sha256Digest, evidence.motionTraceSha256);
        expect(evidence.motionSampleCount, samples.length);
        expect(evidence.motionAnalysisJson, contains('"repetitionCount":5'));
      },
    );

    test(
      'when the trace changes after it was signed then it is rejected',
      () async {
        final authority = TestAttestationAuthority(name: 'motion');
        final service = ActionVerificationService(
          captureIntegrity: CaptureIntegrityEvaluator(
            captureSignatureRequired: true,
            keyAttestationVerifier: AndroidKeyAttestationVerifier(
              policy: KeyAttestationPolicy(
                signingCertificateDigests: {testSigningCertificateDigest},
              ),
              trustAnchors: [authority.root],
              statusSource: _NothingListed(),
            ),
          ),
        );
        final (action, attempt) = await started('binding-mutation');
        final motion = action.requirements.singleWhere(
          (item) => item.kind == ActionRequirementKind.motion,
        );
        final session = participant.build();
        final window = await service.beginCapture(
          session,
          authUserId: participantId,
          attemptId: attempt.id,
          requirementId: motion.id,
        );
        final key = authority.issue(
          challenge: captureKeyAttestationChallenge(
            captureChallenge: window.captureChallenge,
            attemptId: attempt.id.toString(),
          ),
        );
        final capturedAt = DateTime.now().toUtc();
        final original = _rotationSamples(turns: 5, axis: ActionMotionAxis.yaw);
        final bindingHash = _motionBinding(capturedAt, original);
        final manifest = captureProvenanceManifest(
          attemptId: attempt.id.toString(),
          requirementId: motion.id.toString(),
          requestHash: captureIntegrityRequestHash(
            attemptId: attempt.id.toString(),
            requirementId: motion.id.toString(),
            captureChallenge: window.captureChallenge,
            evidenceBindingHash: bindingHash,
          ),
          evidenceBindingHash: bindingHash,
        );
        final mutated = [...original];
        mutated[10] = mutated[10].copyWith(gyroscopeZ: 0.2);

        final result = await service.submitEvidence(
          session,
          authUserId: participantId,
          input: ActionEvidenceInput(
            attemptId: attempt.id,
            requirementId: motion.id,
            capturedAt: capturedAt,
            motionSamples: mutated,
            captureChallengeId: window.id,
            captureManifest: base64Encode(manifest),
            captureSignature: key.signP1363(manifest),
            captureCertificateChain: key.encodedChain,
          ),
        );

        expect(result.status, EvidenceDecisionStatus.rejected);
        expect(result.reasonCode, 'capture_not_verified');
        final stored = await ActionCaptureChallenge.db.findById(
          session,
          window.id,
        );
        expect(stored!.verdict, 'capture_manifest_mismatch');
      },
    );

    test(
      'when the phone turns around the wrong axis then it is rejected',
      () async {
        final (action, attempt) = await started('wrong-axis');
        final motion = action.requirements.singleWhere(
          (item) => item.kind == ActionRequirementKind.motion,
        );

        final result = await endpoints.actionVerification.submitEvidence(
          participant,
          ActionEvidenceInput(
            attemptId: attempt.id,
            requirementId: motion.id,
            capturedAt: DateTime.now().toUtc(),
            motionSamples: _rotationSamples(
              turns: 5,
              axis: ActionMotionAxis.pitch,
            ),
          ),
        );

        expect(result.status, EvidenceDecisionStatus.rejected);
        expect(result.reasonCode, 'motion_not_matched');
      },
    );

    test('when no samples are sent then the proof is refused', () async {
      final (action, attempt) = await started('no-samples');
      final motion = action.requirements.singleWhere(
        (item) => item.kind == ActionRequirementKind.motion,
      );

      await expectLater(
        endpoints.actionVerification.submitEvidence(
          participant,
          ActionEvidenceInput(
            attemptId: attempt.id,
            requirementId: motion.id,
            capturedAt: DateTime.now().toUtc(),
            motionSamples: const [],
          ),
        ),
        throwsArgumentError,
      );
    });
  });

  withServerpod(
    'Given concurrent requests from one participant',
    (sessionBuilder, endpoints) {
      final creatorId = testId(0x231);
      final participantId = testId(0x232);
      late TestSessionBuilder creator;
      late TestSessionBuilder participant;

      setUpAll(() async {
        creator = signedIn(sessionBuilder, creatorId);
        participant = signedIn(sessionBuilder, participantId);
        await insertAccounts(sessionBuilder.build(), {
          creatorId: 'Ada',
          participantId: 'Grace',
        });
      });

      test(
        'when eight starts race then they converge on one attempt',
        () async {
          final action = await endpoints.actionVerification.createAction(
            creator,
            actionRequest(
              actionKey: 'concurrent-start',
              requirements: [locationRequirement()],
            ),
          );

          final attempts = await Future.wait([
            for (var index = 0; index < 8; index += 1)
              endpoints.actionVerification.beginAttempt(
                participant,
                actionId: action.id,
                idempotencyKey: 'concurrent-start-$index',
              ),
          ]);

          expect(attempts.map((attempt) => attempt.id).toSet(), hasLength(1));
          expect(
            await ActionAttempt.db.count(
              sessionBuilder.build(),
              where: (table) => table.actionDefinitionId.equals(action.id),
            ),
            1,
          );
        },
      );

      test(
        'when check-ins in two cities race then one is held for review',
        () async {
          final london = await endpoints.actionVerification.createAction(
            creator,
            actionRequest(
              actionKey: 'concurrent-london',
              requirements: [locationRequirement()],
            ),
          );
          final paris = await endpoints.actionVerification.createAction(
            creator,
            actionRequest(
              actionKey: 'concurrent-paris',
              requirements: [
                locationRequirement(
                  latitude: _paris.latitude,
                  longitude: _paris.longitude,
                ),
              ],
            ),
          );
          final londonAttempt = await endpoints.actionVerification.beginAttempt(
            participant,
            actionId: london.id,
            idempotencyKey: 'concurrent-london',
          );
          final parisAttempt = await endpoints.actionVerification.beginAttempt(
            participant,
            actionId: paris.id,
            idempotencyKey: 'concurrent-paris',
          );
          final capturedAt = DateTime.now().toUtc();

          final results = await Future.wait([
            for (final (attempt, requirement, place) in [
              (londonAttempt, london.requirements.single, _bigBen),
              (parisAttempt, paris.requirements.single, _paris),
            ])
              endpoints.actionVerification.submitEvidence(
                participant,
                ActionEvidenceInput(
                  attemptId: attempt.id,
                  requirementId: requirement.id,
                  capturedAt: capturedAt,
                  latitude: place.latitude,
                  longitude: place.longitude,
                  accuracyMeters: 10,
                ),
              ),
          ]);

          expect(
            results.map((result) => result.status),
            unorderedEquals([
              EvidenceDecisionStatus.accepted,
              EvidenceDecisionStatus.manualReview,
            ]),
          );
        },
      );
    },
    rollbackDatabase: RollbackDatabase.disabled,
  );
}

CreateActionDefinitionRequest _venueRequest({required String actionKey}) =>
    actionRequest(
      actionKey: actionKey,
      title: 'Visit Big Ben',
      recurrence: ActionRecurrence.daily,
      requirements: [
        locationRequirement(),
        qrRequirement(qrCode: _staticVenueCode),
      ],
    ).copyWith(timeZone: 'Europe/London');

String _londonToday() => actionPeriodKey(
  ActionRecurrence.daily,
  'Europe/London',
  DateTime.now(),
);

ActionRequirementDraft _yawMotionRequirement() => ActionRequirementDraft(
  requirementKey: 'five-yaw-turns',
  kind: ActionRequirementKind.motion,
  title: 'Rotate five times',
  instructions: 'Keep a secure grip and turn the phone five times around yaw.',
  isRequired: true,
  minDurationSeconds: 1,
  maxDurationSeconds: 10,
  motionType: ActionMotionType.rotation,
  motionAxis: ActionMotionAxis.yaw,
  targetRepetitions: 5,
  minAngularSpeedRadiansPerSecond: 1,
  maxAngularSpeedRadiansPerSecond: 20,
  minAxisDominance: 0.6,
  minFreeFallMilliseconds: 180,
  maxFreeFallMilliseconds: 700,
  minPeakAccelerationMetersPerSecondSquared: 12,
  maxPeakAccelerationMetersPerSecondSquared: 60,
);

List<ActionMotionSample> _rotationSamples({
  required int turns,
  required ActionMotionAxis axis,
}) {
  const intervalMicros = 20000;
  final count = turns * 50 + 1;
  return [
    for (var index = 0; index < count; index += 1)
      ActionMotionSample(
        elapsedMicroseconds: index * intervalMicros,
        gyroscopeX: axis == ActionMotionAxis.pitch ? 2 * math.pi : 0.1,
        gyroscopeY: 0.1,
        gyroscopeZ: axis == ActionMotionAxis.yaw ? 2 * math.pi : 0.1,
        accelerationX: 0,
        accelerationY: 0,
        accelerationZ: 9.81,
      ),
  ];
}

String _motionBinding(DateTime capturedAt, List<ActionMotionSample> samples) {
  final shared = [
    for (final sample in samples)
      MotionEvidenceSample(
        elapsedMicroseconds: sample.elapsedMicroseconds,
        gyroscopeX: sample.gyroscopeX,
        gyroscopeY: sample.gyroscopeY,
        gyroscopeZ: sample.gyroscopeZ,
        accelerationX: sample.accelerationX,
        accelerationY: sample.accelerationY,
        accelerationZ: sample.accelerationZ,
      ),
  ];
  return motionEvidenceBindingHash(
    capturedAt: capturedAt,
    traceSha256: motionTraceSha256(shared),
    sampleCount: samples.length,
    durationMilliseconds: (samples.last.elapsedMicroseconds / 1000).round(),
  );
}

/// The token Play would issue for [requestHash]; the fake verifier trusts a
/// token only for the request it was issued for, as Google's does.
String _tokenFor(String requestHash) => 'play-token-for:$requestHash';

class _TrustedDeviceIntegrityVerifier implements DeviceIntegrityVerifier {
  String? requestHash;
  String? reviewReasonCode;

  @override
  String get providerName => 'test-device-integrity';

  @override
  Future<DeviceIntegrityVerdict> verify(
    Session session, {
    required String token,
    required String requestHash,
    required DateTime now,
    required bool requireStrongIntegrity,
  }) async {
    if (token != _tokenFor(requestHash)) {
      return const DeviceIntegrityVerdict(
        trusted: false,
        reasonCode: 'device_integrity_invalid',
        provider: 'test-device-integrity',
      );
    }
    this.requestHash = requestHash;
    return DeviceIntegrityVerdict(
      trusted: true,
      reasonCode: 'device_integrity_met',
      provider: 'test-device-integrity',
      reviewReasonCode: reviewReasonCode,
    );
  }
}

class _NothingListed implements AttestationStatusSource {
  @override
  Future<AttestationStatusList> statusAt(DateTime now) async =>
      AttestationStatusList(const []);
}
