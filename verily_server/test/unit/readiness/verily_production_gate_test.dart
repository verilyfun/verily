import 'dart:convert';

import 'package:test/test.dart';
import 'package:verily_server/src/readiness/verily_production_gate.dart';

void main() {
  const gate = VerilyProductionGate();

  VerilyProductionGateResult gateFor(
    VerilyProductionReadinessReport report,
    VerilyProductionPriority priority,
  ) => report.gates.singleWhere((result) => result.priority == priority);

  group('Given no release configuration', () {
    test('when evaluated then development stays runnable and lists every '
        'unresolved gate', () {
      final report = gate.evaluate(const {});

      expect(report.stage, VerilyReleaseStage.development);
      expect(report.releaseAllowed, isTrue);
      expect(report.gates, hasLength(VerilyProductionPriority.values.length));
      // Rewards are off by default, so only the escrow gate is satisfied.
      expect(
        report.gates.where((result) => !result.ready).map((r) => r.priority),
        isNot(contains(VerilyProductionPriority.rewardEscrow)),
      );
      expect(
        report.gates.where((result) => !result.ready),
        hasLength(VerilyProductionPriority.values.length - 1),
      );
    });
  });

  group('Given a closed pilot', () {
    test('when no artifact is supplied then the release is refused', () {
      final report = gate.evaluate(const {
        'VERILY_RELEASE_STAGE': 'closed-pilot',
      });

      expect(report.stage, VerilyReleaseStage.closedPilot);
      expect(report.releaseAllowed, isFalse);
    });

    test('when every artifact is supplied then the release passes without '
        'exposing secrets', () {
      final report = gate.evaluate(_closedPilotEnvironment());
      final encoded = jsonEncode(report.toJson());

      expect(report.releaseAllowed, isTrue);
      expect(report.gates.every((result) => result.ready), isTrue);
      expect(encoded, isNot(contains('evidence-secret')));
      expect(encoded, isNot(contains('application-secret')));
      expect(encoded, isNot(contains('test-only-abuse-pseudonym')));
      expect(jsonDecode(encoded), containsPair('stage', 'closed-pilot'));
    });

    test('when local evidence storage is selected then storage blocks', () {
      final report = gate.evaluate(
        _closedPilotEnvironment()..['VERILY_EVIDENCE_STORAGE'] = 'local',
      );
      final storage = gateFor(report, VerilyProductionPriority.evidenceStorage);

      expect(report.releaseAllowed, isFalse);
      expect(
        storage.blockers,
        contains(
          'Production evidence storage must be '
          'b2.',
        ),
      );
    });

    test('when a Backblaze value is missing then storage names it', () {
      final report = gate.evaluate(
        _closedPilotEnvironment()..remove('VERILY_EVIDENCE_B2_KEY_ID'),
      );
      final storage = gateFor(report, VerilyProductionPriority.evidenceStorage);

      expect(storage.ready, isFalse);
      expect(storage.blockers, ['VERILY_EVIDENCE_B2_KEY_ID is required.']);
    });

    test('when the storage policy version is unpinned then storage blocks', () {
      final report = gate.evaluate(
        _closedPilotEnvironment()
          ..['VERILY_EVIDENCE_STORAGE_POLICY_VERSION'] = 'latest',
      );

      expect(
        gateFor(report, VerilyProductionPriority.evidenceStorage).ready,
        isFalse,
      );
    });

    test('when manual review lacks a service-level artifact then the model '
        'gate names it', () {
      final report = gate.evaluate(
        _closedPilotEnvironment()..remove('VERILY_MANUAL_REVIEW_SLA_EVIDENCE'),
      );
      final model = gateFor(report, VerilyProductionPriority.modelVerification);

      expect(model.ready, isFalse);
      expect(
        model.blockers,
        contains(contains('VERILY_MANUAL_REVIEW_SLA_EVIDENCE')),
      );
    });

    test('when OpenRouter lacks ZDR and a blocking guard then both block', () {
      final report = gate.evaluate(
        _closedPilotEnvironment()
          ..['VERILY_MEDIA_VERIFIER_MODE'] = 'openrouter'
          ..['VERILY_AI_DEPLOYMENT_ENABLED'] = 'true'
          ..['VERILY_AI_PREFLIGHT_EVIDENCE'] = _evidence
          ..['VERILY_OPENROUTER_REQUIRE_ZDR'] = 'false'
          ..['VERILY_OPENROUTER_PROMPT_INJECTION_GUARD'] = 'warn',
      );
      final model = gateFor(report, VerilyProductionPriority.modelVerification);

      expect(model.ready, isFalse);
      expect(model.blockers, hasLength(2));
    });

    test('when OpenRouter is fully attested then the model gate passes', () {
      final report = gate.evaluate(
        _closedPilotEnvironment()
          ..['VERILY_MEDIA_VERIFIER_MODE'] = 'openrouter'
          ..['VERILY_AI_DEPLOYMENT_ENABLED'] = 'true'
          ..['VERILY_AI_PREFLIGHT_EVIDENCE'] = _evidence
          ..['VERILY_OPENROUTER_REQUIRE_ZDR'] = 'true'
          ..['VERILY_OPENROUTER_PROMPT_INJECTION_GUARD'] = 'block',
      );

      expect(
        gateFor(report, VerilyProductionPriority.modelVerification).ready,
        isTrue,
      );
    });

    for (final mode in ['cloud', 'auto']) {
      test('when the verifier mode is $mode then the model gate blocks', () {
        final report = gate.evaluate(
          _closedPilotEnvironment()..['VERILY_MEDIA_VERIFIER_MODE'] = mode,
        );

        expect(
          gateFor(report, VerilyProductionPriority.modelVerification).ready,
          isFalse,
        );
        expect(report.releaseAllowed, isFalse);
      });
    }

    test('when the local development escrow is selected then the reward '
        'gate blocks', () {
      final report = gate.evaluate(
        _closedPilotEnvironment()
          ..['VERILY_REWARD_ESCROW_MODE'] = 'local-development',
      );
      final reward = gateFor(report, VerilyProductionPriority.rewardEscrow);

      expect(reward.ready, isFalse);
      expect(reward.blockers, contains(contains('disabled or the reviewed')));
    });

    test('when Solana escrow targets mainnet then the pilot blocks', () {
      final report = gate.evaluate(
        _closedPilotEnvironment()
          ..['VERILY_REWARD_ESCROW_MODE'] = 'solana'
          ..['VERILY_REWARD_CLUSTER'] = 'mainnet'
          ..['VERILY_REWARD_ESCROW_PREFLIGHT_EVIDENCE'] = _evidence,
      );
      final reward = gateFor(report, VerilyProductionPriority.rewardEscrow);

      expect(reward.ready, isFalse);
      expect(reward.blockers, contains(contains('devnet only')));
    });

    test('when Solana escrow on devnet has a preflight artifact then the '
        'reward gate passes', () {
      final report = gate.evaluate(
        _closedPilotEnvironment()
          ..['VERILY_REWARD_ESCROW_MODE'] = 'solana'
          ..['VERILY_REWARD_CLUSTER'] = 'devnet'
          ..['VERILY_REWARD_ESCROW_PREFLIGHT_EVIDENCE'] = _evidence,
      );

      expect(
        gateFor(report, VerilyProductionPriority.rewardEscrow).ready,
        isTrue,
      );
    });

    for (final threshold in ['-1', '1.5', '25 USDC', '1000000001']) {
      test('when the payout review threshold is "$threshold" then the reward '
          'gate blocks', () {
        final report = gate.evaluate(
          _closedPilotEnvironment()
            ..['VERILY_REWARD_REVIEW_THRESHOLD_ATOMS'] = threshold,
        );
        final reward = gateFor(report, VerilyProductionPriority.rewardEscrow);

        expect(reward.ready, isFalse);
        expect(reward.blockers, contains(contains('REVIEW_THRESHOLD_ATOMS')));
      });
    }

    for (final reference in [
      'https://person:secret@evidence.verily.fun/report',
      'https://example.com/report',
      'https://docs.example.com/report',
      'http://evidence.verily.fun/report',
      'https://localhost/report',
      'https://evidence.verily.fun/report#section',
      'sha256:ABC',
    ]) {
      test(
        'when evidence references "$reference" then the gate rejects it',
        () {
          final report = gate.evaluate(
            _closedPilotEnvironment()
              ..['VERILY_SECURITY_AUDIT_EVIDENCE'] = reference,
          );

          expect(
            gateFor(report, VerilyProductionPriority.securityAudit).ready,
            isFalse,
          );
        },
      );
    }

    test('when an HTTPS evidence reference is reviewed then it passes', () {
      final report = gate.evaluate(
        _closedPilotEnvironment()
          ..['VERILY_SECURITY_AUDIT_EVIDENCE'] =
              'https://evidence.verily.fun/audits/2026-10',
      );

      expect(
        gateFor(report, VerilyProductionPriority.securityAudit).ready,
        isTrue,
      );
    });

    test('when abuse handling is advisory then the abuse gate blocks', () {
      final report = gate.evaluate(
        _closedPilotEnvironment()..['VERILY_ABUSE_RUNTIME_MODE'] = 'disabled',
      );
      final abuse = gateFor(report, VerilyProductionPriority.abuseResistance);

      expect(abuse.ready, isFalse);
      expect(abuse.blockers, contains(contains('must be enforced')));
    });

    test('when Play Integrity is optional then the abuse gate blocks', () {
      final report = gate.evaluate(
        _closedPilotEnvironment()
          ..['VERILY_DEVICE_INTEGRITY_MODE'] = 'disabled',
      );
      final abuse = gateFor(report, VerilyProductionPriority.abuseResistance);

      expect(abuse.ready, isFalse);
      expect(abuse.blockers, contains(contains('Play Integrity')));
    });

    test('when the release signing certificate is missing or malformed then '
        'the abuse gate blocks', () {
      for (final value in ['', 'not-a-digest']) {
        final report = gate.evaluate(
          _closedPilotEnvironment()
            ..['VERILY_ANDROID_SIGNING_CERT_SHA256'] = value,
        );
        final abuse = gateFor(report, VerilyProductionPriority.abuseResistance);

        expect(abuse.ready, isFalse, reason: value);
        expect(
          abuse.blockers,
          contains(contains('signing certificate')),
          reason: value,
        );
      }
    });

    test('when the pseudonym secret is short then the abuse gate blocks', () {
      final report = gate.evaluate(
        _closedPilotEnvironment()..['VERILY_ABUSE_PSEUDONYM_SECRET'] = 'short',
      );

      expect(
        gateFor(report, VerilyProductionPriority.abuseResistance).ready,
        isFalse,
      );
    });
  });

  group('Given a live-money release', () {
    test('when evaluated with complete pilot evidence then it is refused', () {
      final report = gate.evaluate(
        _closedPilotEnvironment()..['VERILY_RELEASE_STAGE'] = 'live-money',
      );
      final reward = gateFor(report, VerilyProductionPriority.rewardEscrow);

      expect(report.stage, VerilyReleaseStage.liveMoney);
      expect(report.releaseAllowed, isFalse);
      expect(
        reward.blockers,
        contains('This build does not authorize live-money payouts.'),
      );
    });
  });

  group('Given an unknown release stage', () {
    test('when evaluated then it fails closed', () {
      expect(
        () => gate.evaluate(const {'VERILY_RELEASE_STAGE': 'public'}),
        throwsFormatException,
      );
    });
  });
}

const _evidence =
    'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

Map<String, String> _closedPilotEnvironment() => {
  'VERILY_RELEASE_STAGE': 'closed-pilot',
  'VERILY_EVIDENCE_STORAGE': 'b2',
  'VERILY_EVIDENCE_B2_S3_ENDPOINT': 'https://s3.us-west-004.backblazeb2.com',
  'VERILY_EVIDENCE_B2_REGION': 'us-west-004',
  'VERILY_EVIDENCE_B2_BUCKET_NAME': 'verily-private-evidence',
  'VERILY_EVIDENCE_B2_KEY_ID': 'evidence-secret',
  'VERILY_EVIDENCE_B2_APPLICATION_KEY': 'application-secret',
  'VERILY_EVIDENCE_PREFLIGHT_EVIDENCE': _evidence,
  'VERILY_EVIDENCE_STORAGE_POLICY_VERSION':
      'verily.evidence-storage.production.v1',
  'VERILY_EVIDENCE_ALLOWED_WEB_ORIGINS': 'https://app.verily.fun',
  'VERILY_MEDIA_VERIFIER_MODE': 'manual-review',
  'VERILY_MANUAL_REVIEW_SLA_EVIDENCE': _evidence,
  'VERILY_REWARD_ESCROW_MODE': 'disabled',
  'VERILY_END_TO_END_EVIDENCE': _evidence,
  'VERILY_SECURITY_AUDIT_EVIDENCE': _evidence,
  'VERILY_ABUSE_REVIEW_EVIDENCE': _evidence,
  'VERILY_ABUSE_RUNTIME_MODE': 'enforced',
  'VERILY_ABUSE_PSEUDONYM_SECRET': 'test-only-abuse-pseudonym-secret-32-bytes',
  'VERILY_ABUSE_PSEUDONYM_KEY_EPOCH': 'pilot-2026-10',
  'VERILY_CAPTURE_SIGNATURE_MODE': 'required',
  'VERILY_DEVICE_INTEGRITY_MODE': 'required',
  'VERILY_ANDROID_SIGNING_CERT_SHA256': 'ab' * 32,
  'VERILY_OPERATIONS_APPROVAL_EVIDENCE': _evidence,
  'VERILY_PILOT_LOAD_EVIDENCE': _evidence,
};
