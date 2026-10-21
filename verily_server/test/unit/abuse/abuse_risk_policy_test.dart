import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/abuse/abuse_risk_policy.dart';

void main() {
  const policy = AbuseRiskPolicy();
  final now = DateTime.utc(2026, 9, 4, 12);

  group('AbuseRiskPolicy replay and input safety', () {
    test('allows a clean observation', () {
      final decision = policy.evaluate(
        candidate: observation(1, now),
        history: const [],
      );

      expect(decision.disposition, AbuseRiskDisposition.allow);
      expect(decision.tier, AbuseRiskTier.low);
      expect(decision.score, 0);
      expect(decision.signals, isEmpty);
    });

    test('allows an idempotent read of the same attempt and bytes', () {
      final candidate = observation(1, now);
      final decision = policy.evaluate(
        candidate: candidate,
        history: [candidate],
      );

      expect(decision.disposition, AbuseRiskDisposition.allow);
    });

    test('rejects exact evidence replay across attempts', () {
      final original = observation(1, now);
      final replay = observation(
        2,
        now.add(const Duration(seconds: 1)),
        evidence: original.evidenceDigest,
      );
      final decision = policy.evaluate(candidate: replay, history: [original]);

      expect(decision.disposition, AbuseRiskDisposition.reject);
      expect(decision.tier, AbuseRiskTier.critical);
      expect(decision.signals, [AbuseSignalCode.evidenceReplay]);
    });

    test('treats a signed motion trace as replay-protected evidence', () {
      final original = observation(
        1,
        now,
        evidenceKind: AbuseEvidenceKind.motion,
      );
      final replay = observation(
        2,
        now.add(const Duration(seconds: 1)),
        evidence: original.evidenceDigest,
        evidenceKind: AbuseEvidenceKind.motion,
      );

      final decision = policy.evaluate(candidate: replay, history: [original]);

      expect(decision.disposition, AbuseRiskDisposition.reject);
      expect(decision.signals, [AbuseSignalCode.evidenceReplay]);
    });

    for (final kind in [
      AbuseEvidenceKind.photo,
      AbuseEvidenceKind.audio,
      AbuseEvidenceKind.externalAttestation,
    ]) {
      test('rejects ${kind.name} evidence replayed across attempts', () {
        final original = observation(1, now, evidenceKind: kind);
        final replay = observation(
          2,
          now.add(const Duration(seconds: 1)),
          evidence: original.evidenceDigest,
          evidenceKind: kind,
        );

        final decision = policy.evaluate(
          candidate: replay,
          history: [original],
        );

        expect(decision.disposition, AbuseRiskDisposition.reject);
        expect(decision.signals, [AbuseSignalCode.evidenceReplay]);
      });

      test('fails closed when ${kind.name} evidence has no digest', () {
        final decision = policy.evaluate(
          candidate: observation(
            1,
            now,
            evidenceKind: kind,
            omitEvidenceDigest: true,
          ),
          history: const [],
        );

        expect(decision.disposition, AbuseRiskDisposition.manualReview);
        expect(decision.signals, [AbuseSignalCode.malformedObservation]);
      });
    }

    test('allows a reusable QR digest across attempts', () {
      final original = observation(
        1,
        now,
        evidenceKind: AbuseEvidenceKind.reusableQr,
      );
      final nextScan = observation(
        2,
        now,
        evidence: original.evidenceDigest,
        evidenceKind: AbuseEvidenceKind.reusableQr,
      );
      final decision = policy.evaluate(
        candidate: nextScan,
        history: [original],
      );

      expect(decision.disposition, AbuseRiskDisposition.allow);
    });

    test('fails closed when replay-protected evidence has no digest', () {
      final decision = policy.evaluate(
        candidate: observation(
          1,
          now,
          omitEvidenceDigest: true,
        ),
        history: const [],
      );

      expect(decision.disposition, AbuseRiskDisposition.manualReview);
      expect(decision.signals, [AbuseSignalCode.malformedObservation]);
    });

    test('allows an authorized evidence replacement within one attempt', () {
      final original = observation(1, now);
      final replacement = observation(
        2,
        now,
        attempt: original.attemptPseudonym,
      );
      final decision = policy.evaluate(
        candidate: replacement,
        history: [original],
      );

      expect(decision.disposition, AbuseRiskDisposition.allow);
    });

    test('oversized or malformed histories fail closed', () {
      final candidate = observation(1, now);
      final oversized = policy.evaluate(
        candidate: candidate,
        history: List.filled(
          AbuseRiskPolicy.maxHistoryObservations + 1,
          candidate,
        ),
      );
      final malformed = policy.evaluate(
        candidate: observation(2, now, account: 'raw-account-id'),
        history: const [],
      );

      expect(oversized.disposition, AbuseRiskDisposition.manualReview);
      expect(
        oversized.signals,
        [AbuseSignalCode.historyLimitExceeded],
      );
      expect(malformed.disposition, AbuseRiskDisposition.manualReview);
      expect(
        malformed.signals,
        [AbuseSignalCode.malformedObservation],
      );
    });

    test('a future history row fails closed instead of being ignored', () {
      final decision = policy.evaluate(
        candidate: observation(1, now),
        history: [observation(2, now.add(const Duration(seconds: 1)))],
      );

      expect(decision.disposition, AbuseRiskDisposition.manualReview);
      expect(decision.signals, [AbuseSignalCode.malformedObservation]);
    });
  });

  group('AbuseRiskPolicy correlation signals', () {
    test('escalates account attempt velocity', () {
      final account = digest('shared-account');
      final candidate = observation(1, now, account: account);
      final history = [
        for (var index = 2; index <= 5; index++)
          observation(
            index,
            now.subtract(Duration(minutes: index)),
            account: account,
          ),
      ];
      final decision = policy.evaluate(candidate: candidate, history: history);

      expect(decision.disposition, AbuseRiskDisposition.manualReview);
      expect(decision.signals, contains(AbuseSignalCode.accountVelocity));
    });

    test('escalates one device spanning several accounts', () {
      final device = digest('shared-device');
      final candidate = observation(1, now, device: device);
      final decision = policy.evaluate(
        candidate: candidate,
        history: [
          observation(2, now, device: device),
          observation(3, now, device: device),
        ],
      );

      expect(decision.disposition, AbuseRiskDisposition.manualReview);
      expect(
        decision.signals,
        contains(AbuseSignalCode.deviceAccountConcentration),
      );
    });

    test('escalates rapid device churn on one account', () {
      final account = digest('shared-account');
      final candidate = observation(
        1,
        now,
        account: account,
        device: digest('device-1'),
      );
      final decision = policy.evaluate(
        candidate: candidate,
        history: [
          for (var index = 2; index <= 4; index++)
            observation(
              index,
              now.subtract(const Duration(hours: 1)),
              account: account,
              device: digest('device-$index'),
            ),
        ],
      );

      expect(decision.disposition, AbuseRiskDisposition.manualReview);
      expect(decision.signals, contains(AbuseSignalCode.accountDeviceChurn));
    });

    test('escalates repeated scene fingerprints across accounts', () {
      final scene = digest('shared-scene');
      final candidate = observation(1, now, scene: scene);
      final decision = policy.evaluate(
        candidate: candidate,
        history: [
          observation(2, now, scene: scene, sameActionAs: candidate),
          observation(3, now, scene: scene, sameActionAs: candidate),
        ],
      );

      expect(decision.disposition, AbuseRiskDisposition.manualReview);
      expect(
        decision.signals,
        contains(AbuseSignalCode.sceneReuseAcrossAccounts),
      );
    });

    test(
      'escalates dense location and time clusters without exposing place',
      () {
        final location = digest('coarse-place');
        final candidate = observation(1, now, location: location);
        final history = [
          for (var index = 2; index <= 8; index++)
            observation(
              index,
              now.subtract(Duration(seconds: index)),
              location: location,
              sameActionAs: candidate,
            ),
        ];
        final decision = policy.evaluate(
          candidate: candidate,
          history: history,
        );
        final output = jsonEncode(decision.toOperationalJson());

        expect(decision.disposition, AbuseRiskDisposition.manualReview);
        expect(
          decision.signals,
          contains(AbuseSignalCode.locationTimeConcentration),
        );
        expect(output, isNot(contains(location)));
      },
    );

    test('adds a coordinated signal when independent clusters agree', () {
      final device = digest('shared-device');
      final scene = digest('shared-scene');
      final candidate = observation(1, now, device: device, scene: scene);
      final decision = policy.evaluate(
        candidate: candidate,
        history: [
          observation(
            2,
            now,
            device: device,
            scene: scene,
            sameActionAs: candidate,
          ),
          observation(
            3,
            now,
            device: device,
            scene: scene,
            sameActionAs: candidate,
          ),
        ],
      );

      expect(decision.tier, AbuseRiskTier.critical);
      expect(decision.signals, contains(AbuseSignalCode.coordinatedCluster));
    });

    test('escalates a static venue code shared across three accounts', () {
      final code = digest('venue-code');
      final action = observation(99, now);
      final decision = policy.evaluate(
        candidate: observation(
          1,
          now,
          evidenceKind: AbuseEvidenceKind.reusableQr,
          evidence: code,
          sameActionAs: action,
        ),
        history: [
          for (var index = 2; index <= 3; index++)
            observation(
              index,
              now,
              evidenceKind: AbuseEvidenceKind.reusableQr,
              evidence: code,
              sameActionAs: action,
            ),
        ],
      );

      expect(decision.disposition, AbuseRiskDisposition.manualReview);
      expect(
        decision.signals,
        contains(AbuseSignalCode.reusableQrConcentration),
      );
    });

    test('leaves a narrowly held static code for the normal verifier', () {
      final code = digest('venue-code');
      final action = observation(99, now);
      final decision = policy.evaluate(
        candidate: observation(
          1,
          now,
          evidenceKind: AbuseEvidenceKind.reusableQr,
          evidence: code,
          sameActionAs: action,
        ),
        history: [
          observation(
            2,
            now,
            evidenceKind: AbuseEvidenceKind.reusableQr,
            evidence: code,
            sameActionAs: action,
          ),
        ],
      );

      expect(decision.disposition, AbuseRiskDisposition.allow);
      expect(
        decision.signals,
        isNot(contains(AbuseSignalCode.reusableQrConcentration)),
      );
    });

    test('does not apply reusable-code concentration to single-use codes', () {
      final code = digest('challenge-digest');
      final action = observation(99, now);
      final decision = policy.evaluate(
        candidate: observation(
          1,
          now,
          evidenceKind: AbuseEvidenceKind.singleUseQr,
          evidence: code,
          sameActionAs: action,
        ),
        history: [
          observation(
            2,
            now,
            evidenceKind: AbuseEvidenceKind.singleUseQr,
            evidence: code,
            sameActionAs: action,
          ),
        ],
      );

      // A repeated single-use digest is impossible evidence, so it stays on
      // the deterministic replay path rather than the reusable-code rule.
      expect(decision.disposition, AbuseRiskDisposition.reject);
      expect(decision.signals, [AbuseSignalCode.evidenceReplay]);
    });

    test('ignores reusable-code reuse from an unrelated action', () {
      final code = digest('venue-code');
      final action = observation(99, now);
      final decision = policy.evaluate(
        candidate: observation(
          1,
          now,
          evidenceKind: AbuseEvidenceKind.reusableQr,
          evidence: code,
          sameActionAs: action,
        ),
        history: [
          for (var index = 2; index <= 4; index++)
            observation(
              index,
              now,
              evidenceKind: AbuseEvidenceKind.reusableQr,
              evidence: code,
            ),
        ],
      );

      // Each history row carries its own creator and action, so the candidate
      // shares no action with the history and no concentration is recorded.
      expect(
        decision.signals,
        isNot(contains(AbuseSignalCode.reusableQrConcentration)),
      );
    });

    test('capture provenance and timing failures require manual review', () {
      final untrusted = policy.evaluate(
        candidate: observation(1, now, captureIntegrityTrusted: false),
        history: const [],
      );
      final unbound = policy.evaluate(
        candidate: observation(2, now, immutableEvidenceBound: false),
        history: const [],
      );
      final future = policy.evaluate(
        candidate: observation(
          3,
          now,
          capturedAt: now.add(const Duration(minutes: 6)),
        ),
        history: const [],
      );
      final stale = policy.evaluate(
        candidate: observation(
          4,
          now,
          capturedAt: now.subtract(const Duration(hours: 25)),
        ),
        history: const [],
      );

      for (final decision in [untrusted, unbound, future, stale]) {
        expect(decision.disposition, AbuseRiskDisposition.manualReview);
      }
    });

    test('old observations do not create new correlation signals', () {
      final device = digest('shared-device');
      final candidate = observation(1, now, device: device);
      final decision = policy.evaluate(
        candidate: candidate,
        history: [
          observation(
            2,
            now.subtract(const Duration(hours: 25)),
            device: device,
          ),
          observation(
            3,
            now.subtract(const Duration(hours: 26)),
            device: device,
          ),
        ],
      );

      expect(decision.disposition, AbuseRiskDisposition.allow);
    });

    test('history ordering cannot change a decision', () {
      final device = digest('shared-device');
      final candidate = observation(1, now, device: device);
      final history = [
        observation(2, now, device: device),
        observation(3, now, device: device),
      ];
      final forward = policy.evaluate(candidate: candidate, history: history);
      final reverse = policy.evaluate(
        candidate: candidate,
        history: history.reversed.toList(),
      );

      expect(forward.toOperationalJson(), reverse.toOperationalJson());
    });
  });
}

AbuseObservation observation(
  int index,
  DateTime now, {
  String? account,
  String? attempt,
  String? evidence,
  AbuseEvidenceKind evidenceKind = AbuseEvidenceKind.video,
  bool omitEvidenceDigest = false,
  String? device,
  String? scene,
  String? location,
  AbuseObservation? sameActionAs,
  DateTime? capturedAt,
  bool captureIntegrityTrusted = true,
  bool immutableEvidenceBound = true,
}) => AbuseObservation(
  accountPseudonym: account ?? digest('account-$index'),
  creatorPseudonym: sameActionAs?.creatorPseudonym ?? digest('creator-$index'),
  actionPseudonym: sameActionAs?.actionPseudonym ?? digest('action-$index'),
  attemptPseudonym: attempt ?? digest('attempt-$index'),
  evidenceKind: evidenceKind,
  capturedAt: capturedAt ?? now,
  receivedAt: now,
  evidenceDigest: omitEvidenceDigest
      ? null
      : evidence ?? digest('evidence-$index'),
  devicePseudonym: device ?? digest('device-$index'),
  scenePseudonym: scene,
  coarseLocationPseudonym: location,
  captureIntegrityTrusted: captureIntegrityTrusted,
  immutableEvidenceBound: immutableEvidenceBound,
);

String digest(String value) => sha256.convert(utf8.encode(value)).toString();
