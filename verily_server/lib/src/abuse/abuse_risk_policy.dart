/// The server action to take before a verified completion or payout is authorized.
enum AbuseRiskDisposition { allow, manualReview, reject }

/// A coarse operational tier. It contains no participant identifiers.
enum AbuseRiskTier { low, elevated, high, critical }

/// Determines whether an identical digest is expected or a replay.
enum AbuseEvidenceKind {
  video,
  photo,
  audio,
  motion,
  singleUseQr,
  reusableQr,
  location,

  /// An App's server-to-server confirmation; its digest covers one event.
  externalAttestation,
  other,
}

/// Stable, privacy-safe reasons suitable for audit counters and staff queues.
enum AbuseSignalCode {
  malformedObservation,
  historyLimitExceeded,
  evidenceReplay,
  captureClockAnomaly,
  staleCapture,
  untrustedCapture,
  immutableEvidenceMissing,
  accountVelocity,
  deviceAccountConcentration,
  accountDeviceChurn,
  sceneReuseAcrossAccounts,
  locationTimeConcentration,
  coordinatedCluster,
  reusableQrConcentration,
}

/// One private, pseudonymized fact row supplied to [AbuseRiskPolicy].
///
/// Account, creator, action, attempt, device, scene, and location values must
/// be HMAC pseudonyms. The policy returns none of them. [evidenceKind] prevents
/// a reusable QR digest from being mistaken for unique media. [evidenceDigest]
/// is the SHA-256 digest of immutable evidence bytes, not a storage path or URL.
final class AbuseObservation {
  const AbuseObservation({
    required this.accountPseudonym,
    required this.creatorPseudonym,
    required this.actionPseudonym,
    required this.attemptPseudonym,
    required this.evidenceKind,
    required this.capturedAt,
    required this.receivedAt,
    this.evidenceDigest,
    this.devicePseudonym,
    this.scenePseudonym,
    this.coarseLocationPseudonym,
    this.captureIntegrityTrusted = true,
    this.immutableEvidenceBound = true,
  });

  final String accountPseudonym;
  final String creatorPseudonym;
  final String actionPseudonym;
  final String attemptPseudonym;
  final AbuseEvidenceKind evidenceKind;
  final DateTime capturedAt;
  final DateTime receivedAt;
  final String? evidenceDigest;
  final String? devicePseudonym;
  final String? scenePseudonym;
  final String? coarseLocationPseudonym;
  final bool captureIntegrityTrusted;
  final bool immutableEvidenceBound;
}

/// A decision containing only bounded codes and scores, never raw risk facts.
final class AbuseRiskDecision {
  const AbuseRiskDecision({
    required this.disposition,
    required this.tier,
    required this.score,
    required this.signals,
  });

  static const policyVersion = 'verily-abuse-v1';

  final AbuseRiskDisposition disposition;
  final AbuseRiskTier tier;
  final int score;
  final List<AbuseSignalCode> signals;

  /// Machine-readable operational output safe from identifier disclosure.
  Map<String, Object> toOperationalJson() => {
    'policyVersion': policyVersion,
    'disposition': disposition.name,
    'tier': tier.name,
    'score': score,
    'signals': [for (final signal in signals) signal.name],
  };
}

/// Correlates a candidate proof with a bounded private history.
///
/// This policy is deliberately deterministic and order-independent. It does
/// not decide whether an action happened; it can only permit the normal
/// verifier to continue, require a human review, or reject a definitive replay.
/// Invalid and oversized inputs fail closed to manual review.
final class AbuseRiskPolicy {
  const AbuseRiskPolicy();

  static const maxHistoryObservations = 2000;
  static const historyWindow = Duration(hours: 24);
  static const accountVelocityWindow = Duration(minutes: 10);
  static const locationTimeWindow = Duration(minutes: 2);
  static const maximumCaptureAge = Duration(hours: 24);
  static const maximumFutureCaptureSkew = Duration(minutes: 5);

  static const accountVelocityThreshold = 5;
  static const deviceAccountThreshold = 3;
  static const accountDeviceThreshold = 4;
  static const sceneAccountThreshold = 3;
  static const locationAccountThreshold = 8;
  static const reusableQrAccountThreshold = 3;

  static final _digestPattern = RegExp(r'^[a-f0-9]{64}$');

  AbuseRiskDecision evaluate({
    required AbuseObservation candidate,
    required List<AbuseObservation> history,
  }) {
    if (history.length > maxHistoryObservations) {
      return _closedDecision(AbuseSignalCode.historyLimitExceeded);
    }

    if (!_validObservation(candidate) ||
        history.any((observation) => !_validObservation(observation))) {
      return _closedDecision(AbuseSignalCode.malformedObservation);
    }

    final signals = <AbuseSignalCode>{};
    final recent = <AbuseObservation>[];

    for (final observation in history) {
      final age = candidate.receivedAt.difference(observation.receivedAt);

      if (age.isNegative) {
        return _closedDecision(AbuseSignalCode.malformedObservation);
      }

      if (age <= historyWindow) {
        recent.add(observation);
      }
    }

    _captureSignals(candidate, signals);

    final replay = _replaySignal(candidate, recent);
    if (replay != null) {
      return _rejectDecision(replay);
    }

    final velocityAttempts = <String>{candidate.attemptPseudonym};
    final deviceAccounts = <String>{candidate.accountPseudonym};
    final accountDevices = <String>{?candidate.devicePseudonym};
    final sceneAccounts = <String>{candidate.accountPseudonym};
    final locationAccounts = <String>{candidate.accountPseudonym};
    final reusableQrAccounts = <String>{candidate.accountPseudonym};

    for (final observation in recent) {
      _collectVelocity(candidate, observation, velocityAttempts);
      _collectDeviceAccounts(candidate, observation, deviceAccounts);
      _collectAccountDevices(candidate, observation, accountDevices);
      _collectSceneAccounts(candidate, observation, sceneAccounts);
      _collectLocationAccounts(candidate, observation, locationAccounts);
      _collectReusableQrAccounts(candidate, observation, reusableQrAccounts);
    }

    if (velocityAttempts.length >= accountVelocityThreshold) {
      signals.add(AbuseSignalCode.accountVelocity);
    }

    if (candidate.devicePseudonym != null &&
        deviceAccounts.length >= deviceAccountThreshold) {
      signals.add(AbuseSignalCode.deviceAccountConcentration);
    }

    if (accountDevices.length >= accountDeviceThreshold) {
      signals.add(AbuseSignalCode.accountDeviceChurn);
    }

    if (candidate.scenePseudonym != null &&
        sceneAccounts.length >= sceneAccountThreshold) {
      signals.add(AbuseSignalCode.sceneReuseAcrossAccounts);
    }

    if (candidate.coarseLocationPseudonym != null &&
        locationAccounts.length >= locationAccountThreshold) {
      signals.add(AbuseSignalCode.locationTimeConcentration);
    }

    if (candidate.evidenceKind == AbuseEvidenceKind.reusableQr &&
        reusableQrAccounts.length >= reusableQrAccountThreshold) {
      signals.add(AbuseSignalCode.reusableQrConcentration);
    }

    final correlatedSignals = signals.intersection({
      AbuseSignalCode.deviceAccountConcentration,
      AbuseSignalCode.sceneReuseAcrossAccounts,
      AbuseSignalCode.locationTimeConcentration,
    });
    if (correlatedSignals.length >= 2) {
      signals.add(AbuseSignalCode.coordinatedCluster);
    }

    return _score(signals);
  }

  void _captureSignals(
    AbuseObservation candidate,
    Set<AbuseSignalCode> signals,
  ) {
    final captureDelay = candidate.receivedAt.difference(candidate.capturedAt);

    if (captureDelay < -maximumFutureCaptureSkew) {
      signals.add(AbuseSignalCode.captureClockAnomaly);
    }

    if (captureDelay > maximumCaptureAge) {
      signals.add(AbuseSignalCode.staleCapture);
    }

    if (!candidate.captureIntegrityTrusted) {
      signals.add(AbuseSignalCode.untrustedCapture);
    }

    if (!candidate.immutableEvidenceBound) {
      signals.add(AbuseSignalCode.immutableEvidenceMissing);
    }
  }

  AbuseSignalCode? _replaySignal(
    AbuseObservation candidate,
    List<AbuseObservation> history,
  ) {
    final candidateDigest = candidate.evidenceDigest;
    if (candidateDigest == null ||
        !_digestMustBeUnique(candidate.evidenceKind)) {
      return null;
    }

    for (final observation in history) {
      final digest = observation.evidenceDigest;

      if (observation.attemptPseudonym != candidate.attemptPseudonym &&
          observation.evidenceKind == candidate.evidenceKind &&
          digest == candidateDigest) {
        return AbuseSignalCode.evidenceReplay;
      }
    }

    return null;
  }

  void _collectVelocity(
    AbuseObservation candidate,
    AbuseObservation observation,
    Set<String> attempts,
  ) {
    if (observation.accountPseudonym != candidate.accountPseudonym) return;

    final age = candidate.receivedAt.difference(observation.receivedAt);
    if (age <= accountVelocityWindow) {
      attempts.add(observation.attemptPseudonym);
    }
  }

  void _collectDeviceAccounts(
    AbuseObservation candidate,
    AbuseObservation observation,
    Set<String> accounts,
  ) {
    final device = candidate.devicePseudonym;
    if (device != null && observation.devicePseudonym == device) {
      accounts.add(observation.accountPseudonym);
    }
  }

  void _collectAccountDevices(
    AbuseObservation candidate,
    AbuseObservation observation,
    Set<String> devices,
  ) {
    final device = observation.devicePseudonym;
    if (device != null &&
        observation.accountPseudonym == candidate.accountPseudonym) {
      devices.add(device);
    }
  }

  void _collectSceneAccounts(
    AbuseObservation candidate,
    AbuseObservation observation,
    Set<String> accounts,
  ) {
    final scene = candidate.scenePseudonym;
    if (scene != null &&
        observation.scenePseudonym == scene &&
        _sameAction(candidate, observation)) {
      accounts.add(observation.accountPseudonym);
    }
  }

  void _collectLocationAccounts(
    AbuseObservation candidate,
    AbuseObservation observation,
    Set<String> accounts,
  ) {
    final location = candidate.coarseLocationPseudonym;
    if (location == null ||
        observation.coarseLocationPseudonym != location ||
        !_sameAction(candidate, observation)) {
      return;
    }

    final difference = candidate.capturedAt.difference(observation.capturedAt);
    if (difference.abs() <= locationTimeWindow) {
      accounts.add(observation.accountPseudonym);
    }
  }

  /// Collects accounts that presented the same non-unique venue code.
  ///
  /// A static code is legitimately shared by everyone at a venue, so this does
  /// not reject on its own. It records how many distinct accounts presented
  /// this exact digest inside the correlation window, which lets
  /// [_score] escalate a widely shared code to manual review instead of
  /// silently accepting every holder.
  void _collectReusableQrAccounts(
    AbuseObservation candidate,
    AbuseObservation observation,
    Set<String> accounts,
  ) {
    final digest = candidate.evidenceDigest;
    if (candidate.evidenceKind != AbuseEvidenceKind.reusableQr ||
        digest == null ||
        observation.evidenceKind != AbuseEvidenceKind.reusableQr ||
        observation.evidenceDigest != digest ||
        !_sameAction(candidate, observation)) {
      return;
    }

    accounts.add(observation.accountPseudonym);
  }

  bool _sameAction(
    AbuseObservation candidate,
    AbuseObservation observation,
  ) =>
      observation.creatorPseudonym == candidate.creatorPseudonym &&
      observation.actionPseudonym == candidate.actionPseudonym;

  bool _validObservation(AbuseObservation observation) {
    final pseudonyms = [
      observation.accountPseudonym,
      observation.creatorPseudonym,
      observation.actionPseudonym,
      observation.attemptPseudonym,
      ?observation.devicePseudonym,
      ?observation.scenePseudonym,
      ?observation.coarseLocationPseudonym,
    ];

    return observation.capturedAt.isUtc &&
        observation.receivedAt.isUtc &&
        pseudonyms.every(_digestPattern.hasMatch) &&
        (!_digestMustBeUnique(observation.evidenceKind) ||
            observation.evidenceDigest != null) &&
        (observation.evidenceDigest == null ||
            _digestPattern.hasMatch(observation.evidenceDigest!));
  }

  bool _digestMustBeUnique(AbuseEvidenceKind kind) => switch (kind) {
    AbuseEvidenceKind.video ||
    AbuseEvidenceKind.photo ||
    AbuseEvidenceKind.audio ||
    AbuseEvidenceKind.motion ||
    AbuseEvidenceKind.singleUseQr ||
    AbuseEvidenceKind.externalAttestation => true,
    AbuseEvidenceKind.reusableQr ||
    AbuseEvidenceKind.location ||
    AbuseEvidenceKind.other => false,
  };

  AbuseRiskDecision _score(Set<AbuseSignalCode> signals) {
    final ordered = signals.toList()..sort(_compareSignals);
    final score = ordered.fold<int>(0, (total, signal) {
      return (total + _weight(signal)).clamp(0, 100);
    });
    final tier = switch (score) {
      < 20 => AbuseRiskTier.low,
      < 35 => AbuseRiskTier.elevated,
      < 70 => AbuseRiskTier.high,
      _ => AbuseRiskTier.critical,
    };

    return AbuseRiskDecision(
      disposition: score >= 35
          ? AbuseRiskDisposition.manualReview
          : AbuseRiskDisposition.allow,
      tier: tier,
      score: score,
      signals: List.unmodifiable(ordered),
    );
  }

  AbuseRiskDecision _closedDecision(AbuseSignalCode signal) =>
      AbuseRiskDecision(
        disposition: AbuseRiskDisposition.manualReview,
        tier: AbuseRiskTier.critical,
        score: 100,
        signals: [signal],
      );

  AbuseRiskDecision _rejectDecision(AbuseSignalCode signal) =>
      AbuseRiskDecision(
        disposition: AbuseRiskDisposition.reject,
        tier: AbuseRiskTier.critical,
        score: 100,
        signals: [signal],
      );

  int _compareSignals(AbuseSignalCode left, AbuseSignalCode right) =>
      left.index.compareTo(right.index);

  int _weight(AbuseSignalCode signal) => switch (signal) {
    AbuseSignalCode.malformedObservation ||
    AbuseSignalCode.historyLimitExceeded ||
    AbuseSignalCode.evidenceReplay => 100,
    AbuseSignalCode.captureClockAnomaly => 70,
    AbuseSignalCode.staleCapture => 35,
    AbuseSignalCode.untrustedCapture => 45,
    AbuseSignalCode.immutableEvidenceMissing => 45,
    AbuseSignalCode.accountVelocity => 40,
    AbuseSignalCode.deviceAccountConcentration => 55,
    AbuseSignalCode.accountDeviceChurn => 35,
    AbuseSignalCode.sceneReuseAcrossAccounts => 55,
    AbuseSignalCode.locationTimeConcentration => 35,
    AbuseSignalCode.coordinatedCluster => 30,
    // Reaches the 35-point manual-review threshold alone: a code presented by
    // many distinct accounts must be reviewed, never silently accepted.
    AbuseSignalCode.reusableQrConcentration => 55,
  };
}
