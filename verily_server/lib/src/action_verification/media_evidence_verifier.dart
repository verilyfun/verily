// The interfaces are intentionally injectable even though they have one
// operation each.
// ignore_for_file: one_member_abstracts

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/action_verification/model_input_security.dart';
import 'package:verily_server/src/evidence_storage/evidence_object_access.dart';
import 'package:verily_server/src/generated/protocol.dart';

const mediaVerifierManualMode = 'manual-review';
const mediaVerifierCloudMode = 'cloud';
const mediaVerifierOpenRouterMode = 'openrouter';
const mediaVerifierContractVersion = 'verily.video-verification.v1';

/// Must commit a cost reservation before the caller sends one provider request.
typedef ReserveVerificationCall = Future<void> Function(String modelId);

/// Missing measured pricing is not permission to perform unbounded inference.
Future<void> denyUnbudgetedVerification(String modelId) async {
  throw StateError('Verification cost policy is not approved.');
}

const openRouterGeminiFlashLiteModel = 'google/gemini-2.5-flash-lite';
const openRouterGeminiFlashModel = 'google/gemini-2.5-flash';
const openRouterGemmaModel = 'google/gemma-4-26b-a4b-it';
const openRouterGlmFlashModel = 'z-ai/glm-5.3-flash';
const openRouterDeepSeekVisionModel = 'deepseek/deepseek-v4-flash-vision-exp';

/// Every model id a deployment may configure. Arbitrary ids are refused.
const Set<String> supportedVerificationModels = {
  openRouterGeminiFlashLiteModel,
  openRouterGeminiFlashModel,
  openRouterGemmaModel,
  openRouterGlmFlashModel,
  openRouterDeepSeekVisionModel,
};

/// Models that accept video input; every council member must be one.
const Set<String> videoVerificationModels = {
  openRouterGeminiFlashLiteModel,
  openRouterGeminiFlashModel,
  openRouterGemmaModel,
  openRouterGlmFlashModel,
};

/// Server-owned verifier deployment settings. Clients and creators cannot
/// select a mode, endpoint, model, or provider option.
class MediaEvidenceVerifierConfiguration {
  const MediaEvidenceVerifierConfiguration._({
    required this.mode,
    required this.endpoint,
    required this.token,
    required this.timeout,
    required this.primaryModelId,
    required this.councilModelIds,
    required this.requireZeroDataRetention,
    required this.promptInjectionGuardEnabled,
  });

  factory MediaEvidenceVerifierConfiguration.fromEnvironment(
    Map<String, String> environment, {
    String? token,
    String? openRouterApiKey,
  }) {
    final mode =
        (environment['VERILY_MEDIA_VERIFIER_MODE'] ?? mediaVerifierManualMode)
            .trim()
            .toLowerCase();
    if (mode == mediaVerifierManualMode) {
      return const MediaEvidenceVerifierConfiguration._(
        mode: mediaVerifierManualMode,
        endpoint: null,
        token: null,
        timeout: Duration(seconds: 90),
        primaryModelId: null,
        councilModelIds: <String>[],
        requireZeroDataRetention: true,
        promptInjectionGuardEnabled: false,
      );
    }
    if (mode == mediaVerifierOpenRouterMode) {
      return MediaEvidenceVerifierConfiguration._openRouter(
        environment,
        openRouterApiKey: openRouterApiKey,
      );
    }
    if (mode != mediaVerifierCloudMode) {
      throw StateError(
        'VERILY_MEDIA_VERIFIER_MODE must be manual-review, cloud, or '
        'openrouter.',
      );
    }

    final endpoint = _httpsEndpoint(
      environment['VERILY_MEDIA_VERIFIER_URL'] ?? '',
      'VERILY_MEDIA_VERIFIER_URL',
    );
    final normalizedToken = token?.trim() ?? '';
    if (normalizedToken.isEmpty) {
      throw StateError(
        'VERILY_MEDIA_VERIFIER_TOKEN is required in cloud mode.',
      );
    }
    return MediaEvidenceVerifierConfiguration._(
      mode: mode,
      endpoint: endpoint,
      token: normalizedToken,
      timeout: _timeout(environment),
      primaryModelId: null,
      councilModelIds: const <String>[],
      requireZeroDataRetention: true,
      promptInjectionGuardEnabled: false,
    );
  }

  factory MediaEvidenceVerifierConfiguration._openRouter(
    Map<String, String> environment, {
    required String? openRouterApiKey,
  }) {
    final normalizedToken = openRouterApiKey?.trim() ?? '';
    if (normalizedToken.isEmpty) {
      throw StateError(
        'VERILY_OPENROUTER_API_KEY is required in openrouter mode.',
      );
    }
    final endpoint = _httpsEndpoint(
      environment['VERILY_OPENROUTER_URL'] ?? openRouterChatCompletionsUrl,
      'VERILY_OPENROUTER_URL',
    );
    final primaryModelId =
        (environment['VERILY_OPENROUTER_PRIMARY_MODEL'] ??
                openRouterGeminiFlashLiteModel)
            .trim();
    final councilModelIds =
        (environment['VERILY_OPENROUTER_COUNCIL_MODELS'] ??
                '$openRouterGeminiFlashLiteModel,$openRouterGemmaModel,'
                    '$openRouterGlmFlashModel')
            .split(',')
            .map((model) => model.trim())
            .where((model) => model.isNotEmpty)
            .toList(growable: false);
    final configuredModels = {primaryModelId, ...councilModelIds};
    if (configuredModels.any(
      (model) => !supportedVerificationModels.contains(model),
    )) {
      throw StateError(
        'OpenRouter verification models must use the pinned supported model '
        'IDs.',
      );
    }
    if (councilModelIds.length != 3 || councilModelIds.toSet().length != 3) {
      throw StateError(
        'VERILY_OPENROUTER_COUNCIL_MODELS must contain three unique models.',
      );
    }
    if (councilModelIds.any(
      (model) => !videoVerificationModels.contains(model),
    )) {
      throw StateError('Council verification models must support video input.');
    }
    final requireZeroDataRetention =
        switch ((environment['VERILY_OPENROUTER_REQUIRE_ZDR'] ?? 'true')
            .trim()
            .toLowerCase()) {
          'true' => true,
          'false' => false,
          _ => throw StateError(
            'VERILY_OPENROUTER_REQUIRE_ZDR must be true or false.',
          ),
        };
    final promptInjectionGuard =
        (environment['VERILY_OPENROUTER_PROMPT_INJECTION_GUARD'] ?? '')
            .trim()
            .toLowerCase();
    if (promptInjectionGuard != 'block') {
      throw StateError(
        'VERILY_OPENROUTER_PROMPT_INJECTION_GUARD must be block after the '
        'OpenRouter API key is assigned to a blocking prompt-injection '
        'guardrail.',
      );
    }
    return MediaEvidenceVerifierConfiguration._(
      mode: mediaVerifierOpenRouterMode,
      endpoint: endpoint,
      token: normalizedToken,
      timeout: _timeout(environment),
      primaryModelId: primaryModelId,
      councilModelIds: councilModelIds,
      requireZeroDataRetention: requireZeroDataRetention,
      promptInjectionGuardEnabled: true,
    );
  }

  final String mode;
  final Uri? endpoint;
  final String? token;
  final Duration timeout;
  final String? primaryModelId;
  final List<String> councilModelIds;
  final bool requireZeroDataRetention;
  final bool promptInjectionGuardEnabled;

  bool get usesCloudVerifier => mode == mediaVerifierCloudMode;
  bool get usesOpenRouterVerifier => mode == mediaVerifierOpenRouterMode;
}

const openRouterChatCompletionsUrl =
    'https://openrouter.ai/api/v1/chat/completions';

Uri _httpsEndpoint(String value, String name) {
  final endpoint = Uri.tryParse(value.trim());
  if (endpoint == null ||
      endpoint.scheme != 'https' ||
      endpoint.host.isEmpty ||
      endpoint.userInfo.isNotEmpty ||
      endpoint.query.isNotEmpty ||
      endpoint.fragment.isNotEmpty) {
    throw StateError(
      '$name must be an HTTPS endpoint without credentials, query, or '
      'fragment.',
    );
  }
  return endpoint;
}

Duration _timeout(Map<String, String> environment) {
  final timeoutSeconds = int.tryParse(
    (environment['VERILY_MEDIA_VERIFIER_TIMEOUT_SECONDS'] ?? '90').trim(),
  );
  if (timeoutSeconds == null || timeoutSeconds < 5 || timeoutSeconds > 180) {
    throw StateError(
      'VERILY_MEDIA_VERIFIER_TIMEOUT_SECONDS must be between 5 and 180.',
    );
  }
  return Duration(seconds: timeoutSeconds);
}

/// Server-measured facts about one immutable piece of media and the
/// server-owned policy it is judged against. Device-reported counts never
/// appear here, so they can never prime a model.
class MediaVerificationRequest {
  const MediaVerificationRequest({
    required this.rule,
    required this.storagePath,
    required this.storageVersionId,
    required this.mimeType,
    required this.sha256Digest,
    required this.byteLength,
    required this.capturedAt,
    this.durationSeconds,
    this.spokenChallengeWord,
  });

  final ActionMediaRule rule;
  final String storagePath;
  final String storageVersionId;
  final String mimeType;
  final String sha256Digest;
  final int byteLength;
  final int? durationSeconds;
  final DateTime capturedAt;

  /// The server-chosen word the participant was asked to say, when the rule
  /// requires one.
  final String? spokenChallengeWord;
}

/// A cloud verifier is deliberately injectable: tests use a deterministic
/// fake and production reports manual review until a real model is wired.
abstract interface class MediaEvidenceVerifier {
  Future<MediaEvidenceVerification> verify(
    Session session,
    MediaVerificationRequest request,
  );
}

class MediaEvidenceVerification {
  const MediaEvidenceVerification({
    required this.status,
    required this.verifierType,
    required this.reasonCode,
    required this.summary,
    this.confidence,
    this.modelName,
    this.modelVersion,
    this.votes = const <MediaEvidenceModelVote>[],
  });

  final EvidenceDecisionStatus status;
  final String verifierType;
  final String reasonCode;
  final String summary;
  final double? confidence;
  final String? modelName;
  final String? modelVersion;
  final List<MediaEvidenceModelVote> votes;
}

enum MediaEvidenceModelVerdict { fulfilled, notFulfilled, uncertain, failed }

/// One model's judgement of the live challenge word.
enum SpokenChallengeVerdict {
  heard,
  notHeard,
  unclear,

  /// The model cannot hear this media's audio, so it cannot vote on the word.
  abstained,
}

class MediaEvidenceModelVote {
  const MediaEvidenceModelVote({
    required this.modelId,
    required this.verdict,
    required this.latencyMilliseconds,
    this.resolvedModelId,
    this.providerName,
    this.responseId,
    this.confidence,
    this.spokenChallengeVerdict,
    this.inputTokens,
    this.outputTokens,
    this.costCredits,
    this.errorCode,
  });

  final String modelId;
  final String? resolvedModelId;
  final String? providerName;
  final String? responseId;
  final MediaEvidenceModelVerdict verdict;
  final double? confidence;

  /// Null when no word was asked of this proof.
  final SpokenChallengeVerdict? spokenChallengeVerdict;
  final int latencyMilliseconds;
  final int? inputTokens;
  final int? outputTokens;
  final double? costCredits;
  final String? errorCode;
}

/// Stable reason codes. Participants see product copy; codes stay in audit.
abstract final class MediaVerificationReason {
  static const verified = 'media_requirements_verified';
  static const notMet = 'media_requirements_not_met';
  static const belowThreshold = 'media_confidence_below_threshold';
  static const uncertain = 'media_verifier_uncertain';
  static const unavailable = 'media_verifier_unavailable';
  static const securityReview = 'media_security_review_required';
  static const councilVerified = 'media_council_verified';
  static const councilNotMet = 'media_council_requirements_not_met';
  static const councilNoConsensus = 'media_council_no_consensus';
  static const councilQuorumUnavailable = 'media_council_quorum_unavailable';
  static const spokenNotHeard = 'spoken_challenge_not_heard';
  static const spokenUnverified = 'spoken_challenge_unverified';
  static const budgetUnavailable = 'verification_budget_unavailable';
  static const retryExhausted = 'media_verifier_retry_exhausted';
}

const verifiedSummary = 'Proof verified.';
const needsReviewSummary = 'A person will check this proof.';
const notMetSummary = 'This proof did not show what the action asks for.';
const spokenNotHeardSummary =
    'We could not hear the challenge word in this recording.';

/// Combines bounded model votes into one decision.
///
/// The action itself is decided first: one decisive vote for a single-model
/// policy, or two matching decisive votes for a council. A clear "not
/// fulfilled" rejects regardless of the challenge word. A "fulfilled" proof
/// with a spoken challenge also needs the word confirmed, and only models that
/// can hear the audio may vote on it: one for a single model, two for a
/// council. A model that cannot hear abstains, so a council with fewer than
/// two hearing members routes the proof to a person rather than guessing.
MediaEvidenceVerification decideMediaVerification({
  required ActionVerificationPolicy policy,
  required List<MediaEvidenceModelVote> votes,
  required double minimumConfidence,
  required bool spokenChallengeRequested,
}) {
  final council = policy == ActionVerificationPolicy.modelCouncil;
  final verifierType = council
      ? 'openrouter-model-council'
      : 'openrouter-single-model';
  final modelName = council ? 'openrouter-council' : votes.firstOrNull?.modelId;
  final modelVersion = council
      ? '2-of-3-v1'
      : votes.firstOrNull?.resolvedModelId;
  MediaEvidenceVerification decision(
    EvidenceDecisionStatus status,
    String reasonCode,
    String summary, {
    double? confidence,
  }) => MediaEvidenceVerification(
    status: status,
    verifierType: verifierType,
    reasonCode: reasonCode,
    summary: summary,
    confidence: confidence,
    modelName: modelName,
    modelVersion: modelVersion,
    votes: votes,
  );

  if (votes.any((vote) => vote.errorCode == promptInjectionErrorCode)) {
    return decision(
      EvidenceDecisionStatus.manualReview,
      MediaVerificationReason.securityReview,
      needsReviewSummary,
    );
  }
  final quorum = council ? 2 : 1;
  final fulfilled = _decisive(
    votes,
    MediaEvidenceModelVerdict.fulfilled,
    minimumConfidence,
  );
  final notFulfilled = _decisive(
    votes,
    MediaEvidenceModelVerdict.notFulfilled,
    minimumConfidence,
  );

  if (notFulfilled.length >= quorum && fulfilled.length < quorum) {
    return decision(
      EvidenceDecisionStatus.rejected,
      council
          ? MediaVerificationReason.councilNotMet
          : MediaVerificationReason.notMet,
      notMetSummary,
      confidence: _lowestConfidence(notFulfilled),
    );
  }
  if (fulfilled.length < quorum) {
    final anyFailed = votes.any(
      (vote) => vote.verdict == MediaEvidenceModelVerdict.failed,
    );
    final single = votes.length == 1 ? votes.single : null;
    final reason = council
        ? anyFailed
              ? MediaVerificationReason.councilQuorumUnavailable
              : MediaVerificationReason.councilNoConsensus
        : single?.verdict == MediaEvidenceModelVerdict.failed
        ? (single?.errorCode == MediaVerificationReason.budgetUnavailable
              ? MediaVerificationReason.budgetUnavailable
              : MediaVerificationReason.unavailable)
        : single?.confidence != null && single!.confidence! < minimumConfidence
        ? MediaVerificationReason.belowThreshold
        : MediaVerificationReason.uncertain;
    return decision(
      EvidenceDecisionStatus.manualReview,
      reason,
      needsReviewSummary,
      confidence: single?.confidence,
    );
  }

  final confidence = _lowestConfidence(fulfilled);
  if (!spokenChallengeRequested) {
    return decision(
      EvidenceDecisionStatus.accepted,
      council
          ? MediaVerificationReason.councilVerified
          : MediaVerificationReason.verified,
      verifiedSummary,
      confidence: confidence,
    );
  }

  final hearing = votes.where(
    (vote) =>
        vote.verdict != MediaEvidenceModelVerdict.failed &&
        vote.confidence != null &&
        vote.confidence! >= minimumConfidence,
  );
  final heard = hearing
      .where(
        (vote) => vote.spokenChallengeVerdict == SpokenChallengeVerdict.heard,
      )
      .length;
  final notHeard = hearing
      .where(
        (vote) =>
            vote.spokenChallengeVerdict == SpokenChallengeVerdict.notHeard,
      )
      .length;
  if (heard >= quorum && notHeard == 0) {
    return decision(
      EvidenceDecisionStatus.accepted,
      council
          ? MediaVerificationReason.councilVerified
          : MediaVerificationReason.verified,
      verifiedSummary,
      confidence: confidence,
    );
  }
  if (notHeard >= quorum && heard == 0) {
    return decision(
      EvidenceDecisionStatus.rejected,
      MediaVerificationReason.spokenNotHeard,
      spokenNotHeardSummary,
      confidence: confidence,
    );
  }
  return decision(
    EvidenceDecisionStatus.manualReview,
    MediaVerificationReason.spokenUnverified,
    needsReviewSummary,
    confidence: confidence,
  );
}

/// Error code a vote carries when the media appeared to instruct the model.
const promptInjectionErrorCode = 'media_prompt_injection_detected';

List<MediaEvidenceModelVote> _decisive(
  List<MediaEvidenceModelVote> votes,
  MediaEvidenceModelVerdict verdict,
  double minimumConfidence,
) {
  return votes
      .where(
        (vote) =>
            vote.verdict == verdict &&
            vote.confidence != null &&
            vote.confidence! >= minimumConfidence,
      )
      .toList(growable: false);
}

double? _lowestConfidence(List<MediaEvidenceModelVote> votes) {
  if (votes.isEmpty) return null;
  return votes
      .map((vote) => vote.confidence!)
      .reduce((lowest, value) => value < lowest ? value : lowest);
}

/// Honest production fallback. It never turns uploaded media into a verified
/// completion without an actual verifier decision.
class ManualReviewMediaEvidenceVerifier implements MediaEvidenceVerifier {
  const ManualReviewMediaEvidenceVerifier();

  @override
  Future<MediaEvidenceVerification> verify(
    Session session,
    MediaVerificationRequest request,
  ) async {
    return const MediaEvidenceVerification(
      status: EvidenceDecisionStatus.manualReview,
      verifierType: 'manual-review-fallback',
      reasonCode: MediaVerificationReason.unavailable,
      summary: needsReviewSummary,
    );
  }
}

/// Calls a separately deployed, approved media-verification service.
///
/// The service receives a short-lived URL for the immutable stored version,
/// the expected digest, and the server-owned verification policy. Provider
/// prose is never copied into user-facing decisions.
class CloudMediaEvidenceVerifier implements MediaEvidenceVerifier {
  factory CloudMediaEvidenceVerifier({
    required MediaEvidenceVerifierConfiguration configuration,
    required EvidenceObjectAccess storage,
    required http.Client httpClient,
    ReserveVerificationCall reserveCall = denyUnbudgetedVerification,
  }) => CloudMediaEvidenceVerifier._(
    configuration,
    storage,
    httpClient,
    reserveCall,
  );

  CloudMediaEvidenceVerifier._(
    this._configuration,
    this._storage,
    this._httpClient,
    this._reserveCall,
  ) {
    if (!_configuration.usesCloudVerifier) {
      throw ArgumentError.value(
        _configuration.mode,
        'configuration',
        'Cloud verifier configuration is required.',
      );
    }
  }

  static const int _maxResponseBytes = 32 * 1024;

  final MediaEvidenceVerifierConfiguration _configuration;
  final EvidenceObjectAccess _storage;
  final http.Client _httpClient;
  final ReserveVerificationCall _reserveCall;

  @override
  Future<MediaEvidenceVerification> verify(
    Session session,
    MediaVerificationRequest request,
  ) async {
    final rule = request.rule;
    if (!ModelInputSecurity.isSafeVerificationPolicy(rule.verificationPrompt)) {
      return _unsafePolicyDecision('cloud-input-policy');
    }
    final digest = _requiredDigest(request.sha256Digest);
    final mediaUrl = await _storage.createReviewUrl(
      session,
      request.storagePath,
      versionId: request.storageVersionId,
    );
    final word = request.spokenChallengeWord;
    final httpRequest = http.Request('POST', _configuration.endpoint!)
      ..followRedirects = false
      ..headers.addAll({
        'authorization': 'Bearer ${_configuration.token!}',
        'accept': 'application/json',
        'content-type': 'application/json',
      })
      ..body = jsonEncode({
        'contractVersion': mediaVerifierContractVersion,
        'policy': {
          'mediaKind': rule.kind.name,
          'prompt': rule.verificationPrompt,
          'minDurationSeconds': rule.minDurationSeconds,
          'maxDurationSeconds': rule.maxDurationSeconds,
          'minConfidence': rule.minConfidence,
          'liveChallenge': word == null
              ? null
              : {'type': 'spokenWord', 'word': word},
        },
        'security': {
          'mediaIsUntrustedData': true,
          'promptInjectionAction': 'manual_review',
        },
        'evidence': {
          'url': mediaUrl.toString(),
          'mimeType': request.mimeType,
          'sha256': digest,
          'byteLength': request.byteLength,
          'durationSeconds': request.durationSeconds,
          'capturedAt': request.capturedAt.toUtc().toIso8601String(),
        },
      });
    try {
      // The all-in cloud contract cost must include any internal council calls.
      await _reserveCall('cloud-media-contract-v1');
    } on Object {
      return const MediaEvidenceVerification(
        status: EvidenceDecisionStatus.manualReview,
        verifierType: 'manual-review-fallback',
        reasonCode: MediaVerificationReason.budgetUnavailable,
        summary: needsReviewSummary,
      );
    }

    final response = await _httpClient
        .send(httpRequest)
        .timeout(_configuration.timeout);
    final responseBytes = await _readBoundedResponse(response);
    if (response.statusCode != 200) {
      throw MediaEvidenceVerifierException(
        'Cloud verifier rejected the request (HTTP ${response.statusCode}).',
      );
    }
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.toLowerCase().startsWith('application/json')) {
      throw const MediaEvidenceVerifierException(
        'Cloud verifier returned an unsupported response type.',
      );
    }
    return _decodeResponse(
      responseBytes,
      rule: rule,
      expectedDigest: digest,
      spokenChallengeRequested: word != null,
    );
  }

  static Future<List<int>> _readBoundedResponse(
    http.StreamedResponse response,
  ) async {
    final bytes = <int>[];
    await for (final chunk in response.stream) {
      if (bytes.length + chunk.length > _maxResponseBytes) {
        throw const MediaEvidenceVerifierException(
          'Cloud verifier response exceeded the size limit.',
        );
      }
      bytes.addAll(chunk);
    }
    return bytes;
  }

  static MediaEvidenceVerification _decodeResponse(
    List<int> bytes, {
    required ActionMediaRule rule,
    required String expectedDigest,
    required bool spokenChallengeRequested,
  }) {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException catch (error) {
      throw MediaEvidenceVerifierException(
        'Cloud verifier returned malformed JSON.',
        error,
      );
    }
    if (decoded is! Map<String, Object?>) {
      throw const MediaEvidenceVerifierException(
        'Cloud verifier response must be a JSON object.',
      );
    }
    if (decoded['contractVersion'] != mediaVerifierContractVersion ||
        decoded['observedSha256'] != expectedDigest) {
      throw const MediaEvidenceVerifierException(
        'Cloud verifier response did not match the evidence contract.',
      );
    }
    final model = decoded['model'];
    if (model is! Map<String, Object?>) {
      throw const MediaEvidenceVerifierException(
        'Cloud verifier response omitted model provenance.',
      );
    }
    final modelName = _boundedResponseString(model['name'], 'model.name', 128);
    final modelVersion = _boundedResponseString(
      model['version'],
      'model.version',
      128,
    );
    final confidenceValue = decoded['confidence'];
    if (confidenceValue is! num ||
        !confidenceValue.isFinite ||
        confidenceValue < 0 ||
        confidenceValue > 1) {
      throw const MediaEvidenceVerifierException(
        'Cloud verifier confidence must be between zero and one.',
      );
    }
    final confidence = confidenceValue.toDouble();
    final promptInjectionDetected = decoded['promptInjectionDetected'];
    if (promptInjectionDetected is! bool) {
      throw const MediaEvidenceVerifierException(
        'Cloud verifier omitted the prompt-injection signal.',
      );
    }
    final challengeWordHeard = decoded['challengeWordHeard'];
    if (spokenChallengeRequested &&
        !const {'yes', 'no', 'unclear'}.contains(challengeWordHeard)) {
      throw const MediaEvidenceVerifierException(
        'Cloud verifier omitted the live challenge result.',
      );
    }
    MediaEvidenceVerification decision(
      EvidenceDecisionStatus status,
      String reasonCode,
      String summary,
    ) => MediaEvidenceVerification(
      status: status,
      verifierType: 'cloud-ai-media',
      reasonCode: reasonCode,
      summary: summary,
      confidence: confidence,
      modelName: modelName,
      modelVersion: modelVersion,
    );
    if (promptInjectionDetected) {
      return decision(
        EvidenceDecisionStatus.manualReview,
        MediaVerificationReason.securityReview,
        needsReviewSummary,
      );
    }
    final verdict = decoded['verdict'];
    if (!const {'accepted', 'rejected', 'manual_review'}.contains(verdict)) {
      throw const MediaEvidenceVerifierException(
        'Cloud verifier returned an unsupported verdict.',
      );
    }
    final confident = confidence >= rule.minConfidence;
    if (verdict == 'rejected' && confident) {
      return decision(
        EvidenceDecisionStatus.rejected,
        MediaVerificationReason.notMet,
        notMetSummary,
      );
    }
    if (verdict != 'accepted' || !confident) {
      return decision(
        EvidenceDecisionStatus.manualReview,
        confident
            ? MediaVerificationReason.uncertain
            : MediaVerificationReason.belowThreshold,
        needsReviewSummary,
      );
    }
    if (spokenChallengeRequested && challengeWordHeard != 'yes') {
      return challengeWordHeard == 'no'
          ? decision(
              EvidenceDecisionStatus.rejected,
              MediaVerificationReason.spokenNotHeard,
              spokenNotHeardSummary,
            )
          : decision(
              EvidenceDecisionStatus.manualReview,
              MediaVerificationReason.spokenUnverified,
              needsReviewSummary,
            );
    }
    return decision(
      EvidenceDecisionStatus.accepted,
      MediaVerificationReason.verified,
      verifiedSummary,
    );
  }
}

MediaEvidenceVerification _unsafePolicyDecision(String verifierType) {
  return MediaEvidenceVerification(
    status: EvidenceDecisionStatus.manualReview,
    verifierType: verifierType,
    reasonCode: MediaVerificationReason.securityReview,
    summary: needsReviewSummary,
  );
}

/// The decision for a policy that fails the input-security check before any
/// model sees it.
MediaEvidenceVerification unsafePolicyDecision(String verifierType) =>
    _unsafePolicyDecision(verifierType);

class MediaEvidenceVerifierException implements Exception {
  const MediaEvidenceVerifierException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'MediaEvidenceVerifierException: $message';
}

String _requiredDigest(String value) {
  final normalized = value.trim();
  if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(normalized)) {
    throw const MediaEvidenceVerifierException(
      'Evidence SHA-256 digest is invalid.',
    );
  }
  return normalized;
}

String _boundedResponseString(Object? value, String field, int maxLength) {
  if (value is! String ||
      value.trim().isEmpty ||
      value.length > maxLength ||
      value.contains(RegExp(r'[\u0000-\u001f\u007f]'))) {
    throw MediaEvidenceVerifierException('Cloud verifier $field is invalid.');
  }
  return value.trim();
}
