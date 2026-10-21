import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/actions/action_repository.dart';
import 'package:verily_flutter/features/appeals/evidence_appeal_repository.dart';
import 'package:verily_flutter/features/apps/apps_repository.dart';
import 'package:verily_flutter/features/do/do_providers.dart';
import 'package:verily_flutter/features/evidence/capture_provenance_service.dart';
import 'package:verily_flutter/features/evidence/evidence_service.dart';
import 'package:verily_flutter/features/evidence/location_service.dart';
import 'package:verily_flutter/features/places/places.dart';

/// Fixtures and fakes for the Do tab and the action page. Nothing here
/// reaches a server, a plugin, or a native map.

UuidValue doUuid(int n) => UuidValue.fromString(
  '00000000-0000-4000-8000-${n.toRadixString(16).padLeft(12, '0')}',
);

final doFixtureNow = DateTime.utc(2026, 10, 21, 14);

/// Westminster Bridge, so distances read like a real city.
const doFixtureLatitude = 51.5007;
const doFixtureLongitude = -0.1220;

ActionRequirementView placeRequirement({
  int id = 101,
  String key = 'be-there',
  String title = 'Westminster Bridge',
  double latitude = doFixtureLatitude,
  double longitude = doFixtureLongitude,
  double radiusMeters = 150,
  int position = 0,
}) => ActionRequirementView(
  id: doUuid(id),
  requirementKey: key,
  kind: ActionRequirementKind.location,
  title: title,
  instructions: 'Stand on the bridge.',
  position: position,
  isRequired: true,
  latitude: latitude,
  longitude: longitude,
  radiusMeters: radiusMeters,
  maxAccuracyMeters: 50,
);

ActionRequirementView venueCodeRequirement({
  int id = 102,
  String key = 'venue-code',
  String title = 'Scan the code at the bar',
  int position = 1,
}) => ActionRequirementView(
  id: doUuid(id),
  requirementKey: key,
  kind: ActionRequirementKind.qrCode,
  title: title,
  instructions: 'Ask the bar to show the code.',
  position: position,
  isRequired: true,
);

ActionRequirementView videoRequirement({
  int id = 103,
  String key = 'video',
  String title = 'Film the sunrise',
  ActionMovementKind? movementKind,
  int? targetRepetitions,
  bool isRequired = true,
  int position = 2,
}) => ActionRequirementView(
  id: doUuid(id),
  requirementKey: key,
  kind: ActionRequirementKind.video,
  title: title,
  instructions: 'Ten seconds of the sky.',
  position: position,
  isRequired: isRequired,
  movementKind: movementKind,
  targetRepetitions: targetRepetitions,
);

ActionRequirementView motionRequirement({
  int id = 104,
  String key = 'spin',
  int position = 3,
}) => ActionRequirementView(
  id: doUuid(id),
  requirementKey: key,
  kind: ActionRequirementKind.motion,
  title: 'Spin the phone',
  instructions: 'Three full spins.',
  position: position,
  isRequired: true,
  motionType: ActionMotionType.rotation,
  targetRepetitions: 3,
);

ActionRequirementView appRequirement({
  int id = 105,
  String key = 'slopper',
  String appName = 'Slopper',
  int appId = 900,
  bool available = true,
  AppVerificationMode mode = AppVerificationMode.push,
}) => ActionRequirementView(
  id: doUuid(id),
  requirementKey: key,
  kind: ActionRequirementKind.externalApp,
  title: 'Bake in Slopper',
  instructions: 'Finish a loaf in Slopper.',
  position: 0,
  isRequired: true,
  appId: doUuid(appId),
  appName: appName,
  appAvailable: available,
  appVerificationMode: mode,
);

ActionAttemptView attemptFixture({
  required int actionId,
  int id = 500,
  ActionAttemptStatus status = ActionAttemptStatus.collectingEvidence,
  List<UuidValue> accepted = const [],
  RewardPayoutStatus? payoutStatus,
  RewardOutcome? rewardOutcome,
  bool rewardValueReview = false,
  String? rejectionCode,
}) => ActionAttemptView(
  id: doUuid(id),
  actionDefinitionId: doUuid(actionId),
  periodKey: 'once',
  status: status,
  rejectionCode: rejectionCode,
  startedAt: doFixtureNow,
  updatedAt: doFixtureNow,
  acceptedRequirementIds: accepted,
  payoutStatus: payoutStatus,
  rewardOutcome: rewardOutcome,
  rewardValueReview: rewardValueReview,
);

RewardSummary rewardFixture({
  RewardPoolStatus status = RewardPoolStatus.funded,
  int amountPerPayout = 5000000,
  int payoutsRemaining = 12,
  int maxWinsPerAccount = 1,
  int myWins = 0,
}) => RewardSummary(
  cluster: RewardCluster.devnet,
  mint: 'mint',
  tokenSymbol: 'USDC',
  decimals: 6,
  amountPerPayout: amountPerPayout,
  maxPayouts: 20,
  payoutsRemaining: payoutsRemaining,
  maxWinsPerAccount: maxWinsPerAccount,
  myWins: myWins,
  status: status,
  expiresAt: doFixtureNow.add(const Duration(days: 30)),
);

ActionOpportunity actionFixture({
  required int id,
  String title = 'Watch the sunrise',
  String description = 'Be on the bridge at dawn and film the sky.',
  String creator = 'Café Lumen',
  bool viewerIsCreator = false,
  ActionDefinitionStatus status = ActionDefinitionStatus.active,
  List<ActionRequirementView>? requirements,
  ActionAttemptView? myAttempt,
  RewardSummary? reward,
}) => ActionOpportunity(
  id: doUuid(id),
  creatorDisplayName: creator,
  viewerIsCreator: viewerIsCreator,
  actionKey: 'action-$id',
  revision: 1,
  status: status,
  title: title,
  description: description,
  recurrence: ActionRecurrence.once,
  timeZone: 'Europe/London',
  verifiedCompletions: 3,
  updatedAt: doFixtureNow,
  requirements: requirements ?? [placeRequirement()],
  myAttempt: myAttempt,
  reward: reward,
);

EvidenceSubmissionResult resultFixture({
  required ActionAttemptView attempt,
  required ActionRequirementView requirement,
  EvidenceDecisionStatus? status = EvidenceDecisionStatus.accepted,
  String? reasonCode,
  String summary = '',
}) => EvidenceSubmissionResult(
  attempt: attempt,
  requirementId: requirement.id,
  status: status,
  reasonCode:
      reasonCode ??
      switch (status) {
        EvidenceDecisionStatus.accepted => 'proof_accepted',
        EvidenceDecisionStatus.rejected => 'proof_not_accepted',
        EvidenceDecisionStatus.manualReview => 'needs_review',
        null => 'checking',
      },
  summary: summary,
);

/// Actions, attempts, and previews held in memory.
class FakeActionRepository extends Fake implements ActionRepository {
  FakeActionRepository({
    List<ActionOpportunity> available = const [],
    List<ActionOpportunity> nearby = const [],
    List<ActionOpportunity> owned = const [],
  }) : available = [...available],
       nearby = [...nearby],
       owned = {for (final action in owned) action.id: action};

  List<ActionOpportunity> available;
  List<ActionOpportunity> nearby;
  final Map<UuidValue, ActionOpportunity> owned;

  /// Thrown by [listAvailable] while set.
  Exception? availableError;

  /// What [beginAttempt] returns for an action id.
  ActionAttemptView Function(UuidValue actionId)? onBegin;

  /// What [completeAttempt] returns for an attempt id.
  ActionAttemptView Function(UuidValue attemptId)? onComplete;

  /// What [listMyAttempts] returns.
  List<ActionAttemptView> myAttempts = [];

  int listAvailableCalls = 0;
  int listMyAttemptsCalls = 0;
  final List<UuidValue> begun = [];
  final List<UuidValue> completed = [];
  ({double latitude, double longitude})? nearbyQuery;

  @override
  Future<List<ActionOpportunity>> listAvailable() async {
    listAvailableCalls++;
    if (availableError case final error?) throw error;
    return available;
  }

  @override
  Future<List<ActionOpportunity>> listNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    nearbyQuery = (latitude: latitude, longitude: longitude);
    return nearby;
  }

  @override
  Future<ActionOpportunity> preview(UuidValue actionId) async {
    if (owned[actionId] case final action?) return action;
    throw _notFound;
  }

  /// Thrown by [getAction] while set, before looking anything up.
  Exception? getActionError;
  int getActionCalls = 0;

  @override
  Future<ActionOpportunity> getAction(UuidValue actionId) async {
    getActionCalls++;
    if (getActionError case final error?) throw error;
    for (final action in [...available, ...nearby, ...owned.values]) {
      if (action.id == actionId) return action;
    }
    throw _notFound;
  }

  static final _notFound = ResourceNotFoundException(
    resource: MissingResource.action,
    message: 'No such action.',
  );

  @override
  Future<ActionAttemptView> beginAttempt(UuidValue actionId) async {
    begun.add(actionId);
    final begin = onBegin;
    if (begin == null) throw StateError('No attempt prepared for $actionId');
    return begin(actionId);
  }

  @override
  Future<ActionAttemptView> completeAttempt(UuidValue attemptId) async {
    completed.add(attemptId);
    final complete = onComplete;
    if (complete == null) throw StateError('No completion for $attemptId');
    return complete(attemptId);
  }

  @override
  Future<List<ActionAttemptView>> listMyAttempts() async {
    listMyAttemptsCalls++;
    return myAttempts;
  }

  /// What [requestAppVerification] answers, or throws.
  EvidenceSubmissionResult Function(UuidValue requirementId)? onAskApp;

  final List<
    ({UuidValue attemptId, UuidValue requirementId, String? reference})
  >
  appRequests = [];

  @override
  Future<EvidenceSubmissionResult> requestAppVerification({
    required UuidValue attemptId,
    required UuidValue requirementId,
    String? reference,
  }) async {
    appRequests.add((
      attemptId: attemptId,
      requirementId: requirementId,
      reference: reference,
    ));
    final answer = onAskApp;
    if (answer == null) throw StateError('No App answer for $requirementId');
    return answer(requirementId);
  }

  /// Where each pull check stands on the server, by requirement; absent
  /// means nobody asked yet.
  final Map<UuidValue, EvidenceSubmissionResult> appChecks = {};

  /// Every read of a pull check, in order.
  final List<UuidValue> appCheckReads = [];

  @override
  Future<EvidenceSubmissionResult?> getAppVerification({
    required UuidValue attemptId,
    required UuidValue requirementId,
  }) async {
    appCheckReads.add(requirementId);
    return appChecks[requirementId];
  }
}

/// Positions and failures chosen by the test.
class FakeLocationService implements LocationService {
  FakeLocationService({
    this.approximateFailure,
    this.preciseFailure,
    LocationFix? fix,
  }) : fix =
           fix ??
           LocationFix(
             latitude: doFixtureLatitude + 0.004,
             longitude: doFixtureLongitude,
             accuracyMeters: 12,
             capturedAt: doFixtureNow,
           );

  LocationFailure? approximateFailure;
  LocationFailure? preciseFailure;
  LocationFix fix;

  int approximateCalls = 0;
  int preciseCalls = 0;
  int openSettingsCalls = 0;

  /// Runs as each precise fix is taken, so tests can check what came first.
  void Function()? onPrecise;

  @override
  Future<LocationFix> approximatePosition() async {
    approximateCalls++;
    if (approximateFailure case final failure?) {
      throw LocationException(failure);
    }
    return fix;
  }

  @override
  Future<LocationFix> precisePosition() async {
    preciseCalls++;
    onPrecise?.call();
    if (preciseFailure case final failure?) {
      throw LocationException(failure);
    }
    return fix;
  }

  @override
  Future<void> openSettings() async => openSettingsCalls++;
}

/// The server's evidence endpoints. Every capture challenge is granted and
/// every submission is answered by [onSubmit].
class FakeEvidenceGateway extends Fake implements EvidenceGateway {
  FakeEvidenceGateway({this.integrityRequired = false});

  /// Whether the challenge demands a Play Integrity token.
  bool integrityRequired;

  EvidenceSubmissionResult Function(ActionEvidenceInput input)? onSubmit;

  final List<ActionEvidenceInput> submitted = [];

  /// Capture windows opened.
  int windowsOpened = 0;

  @override
  Future<ActionCaptureChallengeView> beginCapture({
    required UuidValue attemptId,
    required UuidValue requirementId,
  }) async {
    windowsOpened += 1;
    return ActionCaptureChallengeView(
      id: doUuid(700 + windowsOpened),
      captureChallenge: 'A' * 43,
      issuedAt: doFixtureNow,
      expiresAt: doFixtureNow.add(const Duration(minutes: 30)),
      integrityRequired: integrityRequired,
      signatureRequired: false,
    );
  }

  @override
  Future<EvidenceSubmissionResult> submitEvidence(
    ActionEvidenceInput input,
  ) async {
    submitted.add(input);
    final answer = onSubmit;
    if (answer == null) {
      throw StateError('No answer for ${input.requirementId}');
    }
    return answer(input);
  }
}

/// The real evidence pipeline over [gateway], with a device that gives no
/// integrity token and cannot sign.
EvidenceService fakeEvidenceService(FakeEvidenceGateway gateway) =>
    EvidenceService(
      gateway: gateway,
      deviceIntegrity: (_) async => null,
      captureKeys: const NoCaptureKeys(),
    );

/// A phone without a capture key store, like iOS today.
final class NoCaptureKeys implements CaptureKeyStore {
  const NoCaptureKeys();

  @override
  Future<bool> prepare({
    required String captureId,
    required List<int> attestationChallenge,
  }) async => false;

  @override
  Future<CaptureProvenanceProof?> sign({
    required String captureId,
    required List<int> manifest,
  }) async => null;
}

/// Link codes for Apps.
class FakeAppsRepository extends Fake implements AppsRepository {
  FakeAppsRepository({this.subject = 'vls_ABCDEFGHIJKLMNOPQRSTUV'});

  final String subject;
  final List<UuidValue> linked = [];

  @override
  Future<VerilyAppLinkView> linkApp(UuidValue appId) async {
    linked.add(appId);
    return VerilyAppLinkView(
      appId: appId,
      appName: 'Slopper',
      subject: subject,
      createdAt: doFixtureNow,
    );
  }
}

/// One appeal per attempt, held in memory.
class FakeEvidenceAppealRepository extends Fake
    implements EvidenceAppealRepository {
  final Map<UuidValue, EvidenceAppealView> appeals = {};
  final List<({UuidValue attemptId, String reason})> submissions = [];

  @override
  Future<EvidenceAppealView?> getMine(UuidValue attemptId) async =>
      appeals[attemptId];

  @override
  Future<EvidenceAppealView> submit({
    required UuidValue attemptId,
    required String reason,
  }) async {
    submissions.add((attemptId: attemptId, reason: reason));
    return appeals[attemptId] = EvidenceAppealView(
      id: doUuid(800 + submissions.length),
      evidenceId: doUuid(810),
      attemptId: attemptId,
      actionTitle: 'Watch the sunrise',
      requirementTitle: 'Film the sunrise',
      requirementKind: ActionRequirementKind.video,
      reason: reason,
      status: EvidenceAppealStatus.pending,
      createdAt: doFixtureNow,
    );
  }
}

/// Every fake the Do slice touches, wired into one set of overrides.
class DoFakes {
  DoFakes({
    FakeActionRepository? actions,
    FakeLocationService? location,
    FakeEvidenceGateway? evidence,
    FakeAppsRepository? apps,
    FakeEvidenceAppealRepository? appeals,
  }) : actions = actions ?? FakeActionRepository(),
       location = location ?? FakeLocationService(),
       evidence = evidence ?? FakeEvidenceGateway(),
       apps = apps ?? FakeAppsRepository(),
       appeals = appeals ?? FakeEvidenceAppealRepository();

  final FakeActionRepository actions;
  final FakeLocationService location;
  final FakeEvidenceGateway evidence;
  final FakeAppsRepository apps;
  final FakeEvidenceAppealRepository appeals;

  /// The code the venue scanner reads, or null to cancel the scan.
  String? scannedCode = 'venue-code-1';
  int scans = 0;

  /// Capture windows already open when the scanner started, per scan.
  final List<int> windowsOpenAtScan = [];

  /// What the capture flow returns, or null when the person backs out.
  EvidenceSubmissionResult? Function(
    ActionAttemptView attempt,
    ActionRequirementView requirement,
  )?
  onCapture;
  final List<ActionRequirementView> captured = [];

  /// Polling every [pollInterval], so tests advance a known clock.
  Duration pollInterval = const Duration(seconds: 5);

  List<Override> get overrides => [
    actionRepositoryProvider.overrideWithValue(actions),
    locationServiceProvider.overrideWithValue(location),
    evidenceServiceProvider.overrideWithValue(fakeEvidenceService(evidence)),
    appsRepositoryProvider.overrideWithValue(apps),
    evidenceAppealRepositoryProvider.overrideWithValue(appeals),
    venueCodeScannerProvider.overrideWithValue((context) async {
      scans++;
      windowsOpenAtScan.add(evidence.windowsOpened);
      return scannedCode;
    }),
    evidenceCaptureLauncherProvider.overrideWithValue((
      context, {
      required attempt,
      required requirement,
    }) async {
      captured.add(requirement);
      return onCapture?.call(attempt, requirement);
    }),
    actionMapViewBuilderProvider.overrideWithValue(
      (context) => const SizedBox.expand(),
    ),
    attemptPollIntervalProvider.overrideWithValue((_) => pollInterval),
  ];
}
