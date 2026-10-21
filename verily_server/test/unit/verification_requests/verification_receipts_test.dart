import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/verification_requests/verification_receipts.dart';

final _requestId = UuidValue.withValidation(
  '0198bc26-4be5-7ca0-94d2-000000000a01',
);
final _appId = UuidValue.withValidation('0198bc26-4be5-7ca0-94d2-000000000a02');
final _attemptId = UuidValue.withValidation(
  '0198bc26-4be5-7ca0-94d2-000000000a03',
);
final _requirementId = UuidValue.withValidation(
  '0198bc26-4be5-7ca0-94d2-000000000a04',
);
final _evidenceId = UuidValue.withValidation(
  '0198bc26-4be5-7ca0-94d2-000000000a05',
);
final _now = DateTime.utc(2026, 10, 12, 8, 31);

VerificationRequest _request({
  VerificationRequestKind kind = VerificationRequestKind.video,
  VerificationRequestCheck check = VerificationRequestCheck.content,
  bool spokenChallenge = true,
  bool place = false,
  VerificationRequestStatus status = VerificationRequestStatus.accepted,
  String? subject = 'vls_ABCDEFGHIJKLMNOPQRSTUV',
}) => VerificationRequest(
  id: _requestId,
  appId: _appId,
  kind: kind,
  instructions: 'Show your finished sourdough.',
  check: check,
  placeLatitude: place ? 51.5 : null,
  placeLongitude: place ? -0.12 : null,
  placeRadiusMeters: place ? 150 : null,
  spokenChallenge: spokenChallenge,
  shareEvidence: false,
  redirectUri: 'https://slopper.example.org/return',
  status: status,
  expiresAt: _now.add(const Duration(minutes: 10)),
  subject: subject,
  attemptId: _attemptId,
  createdAt: _now,
  updatedAt: _now,
);

ReceiptProof _proof({
  EvidenceProvenanceLevel provenance = EvidenceProvenanceLevel.basic,
  String? word = 'pelican',
  EvidenceDecisionStatus? decision = EvidenceDecisionStatus.accepted,
  String verifierType = 'openrouter-single-model',
  String reasonCode = 'media_requirements_verified',
  String? challengeProvider = 'capture-challenge',
  String? challengeVerdict = 'capture_challenge_bound',
  ActionRequirementKind kind = ActionRequirementKind.video,
}) => ReceiptProof(
  evidence: ActionEvidence(
    id: _evidenceId,
    attemptId: _attemptId,
    requirementId: _requirementId,
    kind: kind,
    storagePath: 'action-evidence/a/b/c.mp4',
    storageVersionId: 'version-1',
    mimeType: kind == ActionRequirementKind.location ? null : 'video/mp4',
    sha256Digest: kind == ActionRequirementKind.location ? null : 'a' * 64,
    byteLength: 1234,
    durationSeconds: 14,
    location: kind == ActionRequirementKind.location
        ? const GeographyPoint(latitude: 51.5, longitude: -0.12)
        : null,
    spokenChallengeWord: word,
    provenanceLevel: provenance,
    capturedAt: DateTime.utc(2026, 10, 12, 8, 30, 12, 345),
  ),
  decision: decision == null
      ? null
      : EvidenceDecision(
          evidenceId: _evidenceId,
          status: decision,
          verifierType: verifierType,
          reasonCode: reasonCode,
          summary: 'summary',
        ),
  captureChallenge: challengeProvider == null
      ? null
      : ActionCaptureChallenge(
          attemptId: _attemptId,
          requirementId: _requirementId,
          participantAuthUserId: _appId,
          requestHash: 'r' * 64,
          evidenceBindingHash: 'b' * 64,
          expiresAt: _now,
          usedAt: _now,
          provider: challengeProvider,
          verdict: challengeVerdict,
        ),
);

ReceiptProof _placeProof(String reasonCode, EvidenceDecisionStatus status) =>
    _proof(
      kind: ActionRequirementKind.location,
      word: null,
      decision: status,
      verifierType: 'geofence',
      reasonCode: reasonCode,
      challengeProvider: null,
    );

void main() {
  group('Given a verified video request with every check', () {
    test('when the receipt is built then the checks report what passed', () {
      final checks = receiptChecks(
        request: _request(place: true),
        primary: _proof(
          provenance: EvidenceProvenanceLevel.deviceSigned,
          challengeProvider: 'google-play-integrity+android-keystore',
          challengeVerdict: 'capture_signature_valid',
        ),
        place: _placeProof('inside_geofence', EvidenceDecisionStatus.accepted),
      );

      expect(checks, {
        'liveCapture': 'passed',
        'deviceIntegrity': 'passed',
        'captureSignature': 'passed',
        'place': 'inside',
        'liveChallenge': 'passed',
        'content': 'passed',
      });
    });

    test('when the claims are built then they match platform.md and carry no '
        'place, path, or account', () {
      final claims = receiptClaims(
        request: _request(place: true),
        status: ReceiptStatus.verified,
        issuedAt: _now,
        primary: _proof(),
        place: _placeProof('inside_geofence', EvidenceDecisionStatus.accepted),
      );

      expect(claims.keys, [
        'iss',
        'aud',
        'sub',
        'jti',
        'iat',
        'kind',
        'status',
        'checks',
        'capturedAt',
        'evidence',
      ]);
      expect(claims['iss'], 'https://verily.fun');
      expect(claims['aud'], _appId.toString());
      expect(claims['sub'], 'vls_ABCDEFGHIJKLMNOPQRSTUV');
      expect(claims['jti'], _requestId.toString());
      expect(claims['iat'], _now.millisecondsSinceEpoch ~/ 1000);
      expect(claims['capturedAt'], '2026-10-12T08:30:12Z');
      expect(claims['evidence'], {
        'sha256': 'a' * 64,
        'mimeType': 'video/mp4',
        'durationSeconds': 14,
      });
      final text = claims.toString();
      expect(text, isNot(contains('51.5')));
      expect(text, isNot(contains('action-evidence')));
      expect(text, isNot(contains('version-1')));
    });
  });

  group('Given proofs that failed or were never checked', () {
    test('when Play Integrity refused the capture then liveCapture and '
        'deviceIntegrity failed', () {
      final checks = receiptChecks(
        request: _request(),
        primary: _proof(
          decision: EvidenceDecisionStatus.rejected,
          verifierType: 'google-play-integrity',
          reasonCode: 'device_integrity_untrusted',
          challengeProvider: 'google-play-integrity',
          challengeVerdict: 'device_integrity_untrusted',
        ),
      );

      expect(checks['liveCapture'], 'failed');
      expect(checks['deviceIntegrity'], 'failed');
      expect(checks['captureSignature'], 'notChecked');
      expect(checks['content'], 'notChecked');
    });

    test('when the device signature was refused then captureSignature '
        'failed', () {
      final checks = receiptChecks(
        request: _request(),
        primary: _proof(
          decision: EvidenceDecisionStatus.rejected,
          verifierType: 'android-keystore',
          reasonCode: 'capture_manifest_mismatch',
          challengeProvider: 'android-keystore',
          challengeVerdict: 'capture_manifest_mismatch',
        ),
      );

      expect(checks['liveCapture'], 'failed');
      expect(checks['deviceIntegrity'], 'notChecked');
      expect(checks['captureSignature'], 'failed');
    });

    test(
      'when no capture challenge was used then provenance is notChecked',
      () {
        final checks = receiptChecks(
          request: _request(),
          primary: _proof(challengeProvider: null),
        );

        expect(checks['liveCapture'], 'notChecked');
        expect(checks['deviceIntegrity'], 'notChecked');
        expect(checks['captureSignature'], 'notChecked');
      },
    );

    test('when the spoken word was not heard then liveChallenge failed and '
        'content is not blamed', () {
      final checks = receiptChecks(
        request: _request(),
        primary: _proof(
          decision: EvidenceDecisionStatus.rejected,
          reasonCode: 'spoken_challenge_not_heard',
        ),
      );

      expect(checks['liveChallenge'], 'failed');
      expect(checks['content'], 'notChecked');
    });

    test('when a verifier rejected the content then content failed', () {
      final checks = receiptChecks(
        request: _request(),
        primary: _proof(
          decision: EvidenceDecisionStatus.rejected,
          reasonCode: 'media_requirements_not_met',
        ),
      );

      expect(checks['content'], 'failed');
      expect(checks['liveChallenge'], 'notChecked');
    });

    test(
      'when an abuse hold rejected the proof then content is not blamed',
      () {
        final checks = receiptChecks(
          request: _request(),
          primary: _proof(
            decision: EvidenceDecisionStatus.rejected,
            verifierType: 'abuse-risk',
            reasonCode: 'abuse_replay',
          ),
        );

        expect(checks['content'], 'notChecked');
      },
    );

    test('when the decision is still pending then nothing claims to pass', () {
      final checks = receiptChecks(
        request: _request(),
        primary: _proof(decision: EvidenceDecisionStatus.manualReview),
      );

      expect(checks['content'], 'notChecked');
      expect(checks['liveChallenge'], 'notChecked');
    });

    test('when the check is captureOnly then content is notChecked', () {
      final checks = receiptChecks(
        request: _request(check: VerificationRequestCheck.captureOnly),
        primary: _proof(),
      );

      expect(checks['content'], 'notChecked');
      expect(checks['liveChallenge'], 'passed');
    });

    test('when the place proof is outside or refused for accuracy then the '
        'receipt says outside or notChecked', () {
      expect(
        receiptChecks(
          request: _request(place: true),
          primary: _proof(),
          place: _placeProof(
            'outside_geofence',
            EvidenceDecisionStatus.rejected,
          ),
        )['place'],
        'outside',
      );
      expect(
        receiptChecks(
          request: _request(place: true),
          primary: _proof(),
          place: _placeProof(
            'location_accuracy_too_low',
            EvidenceDecisionStatus.rejected,
          ),
        )['place'],
        'notChecked',
      );
      expect(
        receiptChecks(
          request: _request(place: true),
          primary: _proof(),
        )['place'],
        'notChecked',
      );
    });

    test('when nothing was submitted then every check is notChecked', () {
      expect(
        receiptChecks(request: _request(place: true)).values.toSet(),
        {'notChecked'},
      );
    });
  });

  group('Given a location request', () {
    test('when the check-in is inside then place is inside and media checks '
        'are notChecked', () {
      final placeProof = _placeProof(
        'inside_geofence',
        EvidenceDecisionStatus.accepted,
      );
      final request = _request(
        kind: VerificationRequestKind.location,
        check: VerificationRequestCheck.captureOnly,
        spokenChallenge: false,
        place: true,
      );
      final claims = receiptClaims(
        request: request,
        status: ReceiptStatus.verified,
        issuedAt: _now,
        primary: placeProof,
        place: placeProof,
      );

      expect((claims['checks']! as Map)['place'], 'inside');
      expect((claims['checks']! as Map)['content'], 'notChecked');
      expect(claims.containsKey('evidence'), isFalse);
      expect(claims['capturedAt'], '2026-10-12T08:30:12Z');
    });
  });

  group('Given request and attempt states', () {
    ActionAttempt attempt(ActionAttemptStatus status) => ActionAttempt(
      id: _attemptId,
      actionDefinitionId: _appId,
      participantAuthUserId: _appId,
      periodKey: 'once',
      idempotencyKey: 'key',
      status: status,
    );

    test('when the attempt settles then the status follows it', () {
      final request = _request();
      expect(
        receiptStatusFor(request, attempt(ActionAttemptStatus.verified)),
        'verified',
      );
      expect(
        receiptStatusFor(request, attempt(ActionAttemptStatus.rejected)),
        'rejected',
      );
      expect(
        receiptStatusFor(request, attempt(ActionAttemptStatus.capacityReached)),
        'rejected',
      );
      for (final pending in [
        ActionAttemptStatus.collectingEvidence,
        ActionAttemptStatus.verifying,
        ActionAttemptStatus.pendingReview,
      ]) {
        expect(receiptStatusFor(request, attempt(pending)), 'pendingReview');
      }
      expect(receiptStatusIsFinal('pendingReview'), isFalse);
      expect(receiptStatusIsFinal('verified'), isTrue);
    });

    test('when the request was declined or expired then that status wins and '
        'a decliner is never named', () {
      final declined = _request(status: VerificationRequestStatus.declined);
      expect(receiptStatusFor(declined, null), 'declined');
      expect(
        receiptStatusFor(
          _request(status: VerificationRequestStatus.expired),
          null,
        ),
        'expired',
      );
      final claims = receiptClaims(
        request: declined,
        status: ReceiptStatus.declined,
        issuedAt: _now,
      );
      expect(claims.containsKey('sub'), isFalse);
      expect(claims.containsKey('capturedAt'), isFalse);
    });
  });
}
