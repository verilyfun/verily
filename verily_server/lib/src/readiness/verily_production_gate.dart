import 'package:verily_server/src/evidence_storage/production_evidence_preflight.dart';
import 'package:verily_server/src/rewards/reward_configuration.dart';

enum VerilyReleaseStage {
  development,
  closedPilot,
  liveMoney;

  static VerilyReleaseStage parse(String? value) {
    return switch (value?.trim().toLowerCase()) {
      null || '' || 'development' => development,
      'closed-pilot' => closedPilot,
      'live-money' => liveMoney,
      _ => throw const FormatException(
        'VERILY_RELEASE_STAGE must be development, closed-pilot, or '
        'live-money.',
      ),
    };
  }

  String get wireName => switch (this) {
    development => 'development',
    closedPilot => 'closed-pilot',
    liveMoney => 'live-money',
  };
}

enum VerilyProductionPriority {
  evidenceStorage,
  modelVerification,
  rewardEscrow,
  endToEndJourney,
  securityAudit,
  abuseResistance,
  operations,
  controlledPilot,
}

final class VerilyProductionGateResult {
  const VerilyProductionGateResult({
    required this.priority,
    required this.ready,
    required this.blockers,
  });

  final VerilyProductionPriority priority;
  final bool ready;
  final List<String> blockers;

  Map<String, Object?> toJson() => {
    'priority': priority.name,
    'ready': ready,
    'blockers': blockers,
  };
}

final class VerilyProductionReadinessReport {
  const VerilyProductionReadinessReport({
    required this.stage,
    required this.gates,
  });

  final VerilyReleaseStage stage;
  final List<VerilyProductionGateResult> gates;

  bool get releaseAllowed {
    if (stage == VerilyReleaseStage.development) return true;
    if (stage == VerilyReleaseStage.liveMoney) return false;
    return gates.every((gate) => gate.ready);
  }

  Map<String, Object?> toJson() => {
    'stage': stage.wireName,
    'releaseAllowed': releaseAllowed,
    'gates': gates.map((gate) => gate.toJson()).toList(growable: false),
  };
}

/// Evaluates the non-secret deployment gates for a controlled pilot.
///
/// Evidence references prove only that an accountable artifact was supplied;
/// this checker never replaces the reviewer named by it. Live-money releases
/// are refused outright until a reviewed Solana escrow gateway ships.
final class VerilyProductionGate {
  const VerilyProductionGate();

  VerilyProductionReadinessReport evaluate(Map<String, String> environment) {
    final stage = VerilyReleaseStage.parse(
      environment['VERILY_RELEASE_STAGE'],
    );
    return VerilyProductionReadinessReport(
      stage: stage,
      gates: [
        _evidenceStorage(environment),
        _modelVerification(environment),
        _rewardEscrow(environment, stage),
        _evidenceGate(
          environment,
          priority: VerilyProductionPriority.endToEndJourney,
          variable: 'VERILY_END_TO_END_EVIDENCE',
        ),
        _evidenceGate(
          environment,
          priority: VerilyProductionPriority.securityAudit,
          variable: 'VERILY_SECURITY_AUDIT_EVIDENCE',
        ),
        _abuseResistance(environment),
        _evidenceGate(
          environment,
          priority: VerilyProductionPriority.operations,
          variable: 'VERILY_OPERATIONS_APPROVAL_EVIDENCE',
        ),
        _evidenceGate(
          environment,
          priority: VerilyProductionPriority.controlledPilot,
          variable: 'VERILY_PILOT_LOAD_EVIDENCE',
        ),
      ],
    );
  }

  VerilyProductionGateResult _evidenceStorage(Map<String, String> environment) {
    final blockers = <String>[];
    final mode = _value(environment, 'VERILY_EVIDENCE_STORAGE');
    if (mode.isNotEmpty && mode != 'b2') {
      blockers.add('Production evidence storage must be b2.');
    }
    for (final name in const [
      'VERILY_EVIDENCE_B2_S3_ENDPOINT',
      'VERILY_EVIDENCE_B2_REGION',
      'VERILY_EVIDENCE_B2_BUCKET_NAME',
      'VERILY_EVIDENCE_B2_KEY_ID',
      'VERILY_EVIDENCE_B2_APPLICATION_KEY',
    ]) {
      if (_value(environment, name).isEmpty) {
        blockers.add('$name is required.');
      }
    }
    if (_value(environment, 'VERILY_EVIDENCE_STORAGE_POLICY_VERSION') !=
        productionEvidenceStoragePolicyVersion) {
      blockers.add('The evidence storage policy version must be pinned.');
    }
    if (_value(environment, 'VERILY_EVIDENCE_ALLOWED_WEB_ORIGINS').isEmpty) {
      blockers.add('Exact evidence web origins are required.');
    }
    _requireEvidence(
      environment,
      'VERILY_EVIDENCE_PREFLIGHT_EVIDENCE',
      blockers,
    );
    return _result(VerilyProductionPriority.evidenceStorage, blockers);
  }

  VerilyProductionGateResult _modelVerification(
    Map<String, String> environment,
  ) {
    final blockers = <String>[];
    switch (_value(environment, 'VERILY_MEDIA_VERIFIER_MODE')) {
      case 'manual-review' || '':
        _requireEvidence(
          environment,
          'VERILY_MANUAL_REVIEW_SLA_EVIDENCE',
          blockers,
        );
      case 'openrouter':
        if (_value(environment, 'VERILY_AI_DEPLOYMENT_ENABLED') != 'true') {
          blockers.add('The attested AI deployment policy must be enabled.');
        }
        if (_value(environment, 'VERILY_OPENROUTER_REQUIRE_ZDR') != 'true') {
          blockers.add('OpenRouter must require zero-data-retention routing.');
        }
        if (_value(environment, 'VERILY_OPENROUTER_PROMPT_INJECTION_GUARD') !=
            'block') {
          blockers.add('OpenRouter prompt-injection handling must block.');
        }
        _requireEvidence(environment, 'VERILY_AI_PREFLIGHT_EVIDENCE', blockers);
      case 'cloud':
        blockers.add(
          'The unverified generic cloud verifier is unavailable to the pilot.',
        );
      default:
        blockers.add(
          'VERILY_MEDIA_VERIFIER_MODE must be manual-review or openrouter.',
        );
    }
    return _result(VerilyProductionPriority.modelVerification, blockers);
  }

  VerilyProductionGateResult _rewardEscrow(
    Map<String, String> environment,
    VerilyReleaseStage stage,
  ) {
    final blockers = <String>[];
    final mode = _value(environment, 'VERILY_REWARD_ESCROW_MODE');
    switch (mode) {
      case '' || 'disabled':
        // Rewards off: nothing is escrowed, so nothing is at risk.
        break;
      case 'solana':
        if (_value(environment, 'VERILY_REWARD_CLUSTER') != 'devnet' &&
            stage == VerilyReleaseStage.closedPilot) {
          blockers.add('The closed pilot escrows rewards on devnet only.');
        }
        _requireEvidence(
          environment,
          'VERILY_REWARD_ESCROW_PREFLIGHT_EVIDENCE',
          blockers,
        );
      default:
        blockers.add(
          'Production reward escrow must be disabled or the reviewed Solana '
          'gateway.',
        );
    }
    if (parseRewardReviewThreshold(environment) == null) {
      blockers.add(rewardReviewThresholdError);
    }
    if (stage == VerilyReleaseStage.liveMoney) {
      blockers.add('This build does not authorize live-money payouts.');
    }
    return _result(VerilyProductionPriority.rewardEscrow, blockers);
  }

  VerilyProductionGateResult _evidenceGate(
    Map<String, String> environment, {
    required VerilyProductionPriority priority,
    required String variable,
  }) {
    final blockers = <String>[];
    _requireEvidence(environment, variable, blockers);
    return _result(priority, blockers);
  }

  VerilyProductionGateResult _abuseResistance(Map<String, String> environment) {
    final blockers = <String>[];
    if (_value(environment, 'VERILY_ABUSE_RUNTIME_MODE') != 'enforced') {
      blockers.add('The runtime abuse gate must be enforced.');
    }
    if (_value(environment, 'VERILY_CAPTURE_SIGNATURE_MODE') != 'required') {
      blockers.add('Abuse correlation requires signed device captures.');
    }
    if (_value(environment, 'VERILY_ABUSE_PSEUDONYM_SECRET').length < 32) {
      blockers.add('A strong abuse pseudonym secret is required.');
    }
    if (!RegExp(r'^[a-z0-9][a-z0-9._-]{0,31}$').hasMatch(
      _value(environment, 'VERILY_ABUSE_PSEUDONYM_KEY_EPOCH'),
    )) {
      blockers.add('A bounded abuse pseudonym key epoch is required.');
    }
    _requireEvidence(environment, 'VERILY_ABUSE_REVIEW_EVIDENCE', blockers);
    return _result(VerilyProductionPriority.abuseResistance, blockers);
  }
}

VerilyProductionGateResult _result(
  VerilyProductionPriority priority,
  List<String> blockers,
) {
  return VerilyProductionGateResult(
    priority: priority,
    ready: blockers.isEmpty,
    blockers: List.unmodifiable(blockers),
  );
}

void _requireEvidence(
  Map<String, String> environment,
  String name,
  List<String> blockers,
) {
  if (!_isEvidenceReference(_value(environment, name))) {
    blockers.add('$name must reference a reviewed artifact.');
  }
}

bool _isEvidenceReference(String value) {
  if (RegExp(r'^sha256:[a-f0-9]{64}$').hasMatch(value)) return true;
  final uri = Uri.tryParse(value);
  return uri != null &&
      uri.scheme == 'https' &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty &&
      uri.fragment.isEmpty &&
      !uri.host.endsWith('.example.com') &&
      uri.host != 'example.com' &&
      uri.host != 'localhost';
}

String _value(Map<String, String> environment, String name) =>
    environment[name]?.trim() ?? '';
