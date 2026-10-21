import 'dart:convert';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/actions/action_repository.dart';
import 'package:verily_flutter/features/apps/apps_repository.dart';
import 'package:verily_flutter/features/create/editor/editor_providers.dart';
import 'package:verily_flutter/features/create/funding/reward_funding_sheet.dart';
import 'package:verily_flutter/features/evidence/evidence_service.dart';
import 'package:verily_flutter/features/evidence/location_service.dart';
import 'package:verily_flutter/features/rewards/reward_repository.dart';
import 'package:verily_flutter/features/wallet/mobile_wallet.dart';
import 'package:verily_flutter/features/places/places.dart';

/// Fixtures and fakes for the action editor, venue codes, and reward
/// funding. Nothing here reaches a server, a wallet, a plugin, or a native
/// map, so screenshots can reuse them.

UuidValue editorUuid(int n) => UuidValue.fromString(
  '00000000-0000-4000-9000-${n.toRadixString(16).padLeft(12, '0')}',
);

/// The id every action saved through [FakeActionRepository] gets.
final UuidValue editorActionId = editorUuid(1);

/// The creator's linked payout wallet in fixtures, base58.
const editorCreatorWallet = '7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU';

/// Another account a wallet might offer instead.
const editorOtherWallet = '9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM';

ActionTemplate walkTemplate() => ActionTemplate(
  templateKey: 'morning-walk',
  title: 'Morning walk',
  description: 'Walk to the park and film the view.',
  suggestedRecurrence: ActionRecurrence.daily,
  requirements: [
    ActionRequirementDraft(
      requirementKey: 'park',
      kind: ActionRequirementKind.location,
      title: 'Reach the park',
      instructions: 'Share your location at the gate.',
      isRequired: true,
      latitude: 51.5079,
      longitude: -0.0877,
      radiusMeters: 150,
      maxAccuracyMeters: 50,
    ),
    ActionRequirementDraft(
      requirementKey: 'view',
      kind: ActionRequirementKind.video,
      title: 'Film the view',
      instructions: 'Ten seconds of the park.',
      isRequired: true,
      verificationPrompt: 'The video shows a park in daylight.',
      minDurationSeconds: 5,
      maxDurationSeconds: 30,
      spokenChallengeRequired: true,
    ),
  ],
);

ActionTemplate venueTemplate() => ActionTemplate(
  templateKey: 'gig-check-in',
  title: 'Gig check-in',
  description: 'Scan the code at the door.',
  suggestedRecurrence: ActionRecurrence.once,
  requirements: [
    ActionRequirementDraft(
      requirementKey: 'door',
      kind: ActionRequirementKind.qrCode,
      title: 'Scan at the door',
      instructions: 'Scan the code the host shows.',
      isRequired: true,
      // A template's value must never become the venue's secret.
      qrCode: 'template-secret-do-not-use',
    ),
  ],
);

VerilyAppView appFixture({
  int id = 900,
  String name = 'Slopper',
  VerilyAppStatus status = VerilyAppStatus.active,
}) => VerilyAppView(
  id: editorUuid(id),
  name: name,
  status: status,
  keys: const [],
  boundActionCount: 0,
  webhookSecretVersion: 0,
  redirectUris: const [],
  createdAt: DateTime.utc(2026, 10),
);

RewardSummary rewardSummaryFixture({
  int amountPerPayout = 2500000,
  int maxPayouts = 20,
  int maxWinsPerAccount = 1,
  RewardPoolStatus status = RewardPoolStatus.draft,
  DateTime? expiresAt,
}) => RewardSummary(
  cluster: RewardCluster.devnet,
  mint: 'mint',
  tokenSymbol: 'USDC',
  decimals: 6,
  amountPerPayout: amountPerPayout,
  maxPayouts: maxPayouts,
  payoutsRemaining: maxPayouts,
  maxWinsPerAccount: maxWinsPerAccount,
  myWins: 0,
  status: status,
  expiresAt: expiresAt ?? DateTime.utc(2026, 12),
);

ActionRequirementView requirementViewFor(
  ActionRequirementDraft draft,
  int position,
) => ActionRequirementView(
  id: editorUuid(100 + position),
  requirementKey: draft.requirementKey,
  kind: draft.kind,
  title: draft.title,
  instructions: draft.instructions,
  position: position,
  isRequired: draft.isRequired,
  latitude: draft.latitude,
  longitude: draft.longitude,
  radiusMeters: draft.radiusMeters,
  maxAccuracyMeters: draft.maxAccuracyMeters,
  minDurationSeconds: draft.minDurationSeconds,
  maxDurationSeconds: draft.maxDurationSeconds,
  verificationPolicy: draft.verificationPolicy,
  verificationPrompt: draft.verificationPrompt,
  minConfidence: draft.minConfidence,
  venueCodeConfigured: draft.kind == ActionRequirementKind.qrCode ? true : null,
  spokenChallengeRequired: draft.spokenChallengeRequired ?? false,
  movementKind: draft.movementKind,
  motionType: draft.motionType,
  motionAxis: draft.motionAxis,
  targetRepetitions: draft.targetRepetitions,
  appId: draft.appId,
  appName: draft.appId == null ? null : 'Slopper',
);

ActionOpportunity actionFixture({
  String title = 'Morning walk',
  ActionDefinitionStatus status = ActionDefinitionStatus.draft,
  int revision = 1,
  List<ActionRequirementView>? requirements,
  RewardSummary? reward,
  String actionKey = 'morning-walk-abcde',
}) => ActionOpportunity(
  id: editorActionId,
  creatorDisplayName: 'Ifiok',
  viewerIsCreator: true,
  actionKey: actionKey,
  revision: revision,
  status: status,
  title: title,
  description: 'Walk to the park and film the view.',
  recurrence: ActionRecurrence.once,
  timeZone: 'UTC',
  verifiedCompletions: 0,
  updatedAt: DateTime.utc(2026, 10, 21),
  requirements:
      requirements ??
      [
        for (final (index, draft) in walkTemplate().requirements.indexed)
          requirementViewFor(draft, index),
      ],
  reward: reward,
);

RewardFundingPlan fundingPlanFixture({bool localDevelopment = false}) =>
    RewardFundingPlan(
      poolId: editorUuid(700),
      cluster: RewardCluster.devnet,
      escrowAddress: 'escrow',
      creatorWallet: editorCreatorWallet,
      arbiterAddress: 'arbiter',
      mint: 'mint',
      tokenSymbol: 'USDC',
      decimals: 6,
      totalAtoms: 50000000,
      expiresAt: DateTime.utc(2026, 12),
      refundAfter: DateTime.utc(2026, 12, 8),
      unsignedTransaction: base64Encode(
        localDevelopment
            ? utf8.encode('{"localDevelopmentOnly":true}')
            : [1, 0, 2, 3, 4],
      ),
    );

RewardPoolView poolFixture({
  RewardPoolStatus status = RewardPoolStatus.funded,
}) => RewardPoolView(
  poolId: editorUuid(700),
  status: status,
  cluster: RewardCluster.devnet,
  mint: 'mint',
  tokenSymbol: 'USDC',
  decimals: 6,
  amountPerPayout: 2500000,
  maxPayouts: 20,
  maxWinsPerAccount: 1,
  payoutsReserved: 0,
  payoutsReleased: 0,
  expiresAt: DateTime.utc(2026, 12),
  refundAfter: DateTime.utc(2026, 12, 8),
  creatorWallet: editorCreatorWallet,
  escrowAddress: 'escrow',
);

/// An [ActionRepository] that records what the editor sends and answers the
/// way the server does: a save returns a private draft, a publish makes it
/// live, and reward terms stay as they were once funding started.
class FakeActionRepository implements ActionRepository {
  FakeActionRepository({
    this.templates = const [],
    this.proposal,
    this.draftError,
    this.saveError,
    Map<String, ActionOpportunity> previews = const {},
    this.qrValidity = const Duration(seconds: 5),
  }) : previews = {...previews};

  List<ActionTemplate> templates;
  Exception? templatesError;
  ActionDraftProposal? proposal;
  Exception? draftError;
  Exception? saveError;
  final Map<String, ActionOpportunity> previews;

  final draftPrompts = <String>[];
  final createdRequests = <CreateActionDefinitionRequest>[];
  final savedRequests = <CreateActionDefinitionRequest>[];
  final publishedActions = <ActionOpportunity>[];

  /// The reward status the next save reports for a rewarded action.
  RewardPoolStatus savedRewardStatus = RewardPoolStatus.draft;
  ActionOpportunity? lastSaved;

  // Venue codes.
  Duration qrValidity;
  Exception? qrError;
  final qrRequests = <UuidValue>[];

  @override
  Future<List<ActionTemplate>> listTemplates() async {
    if (templatesError case final error?) throw error;
    return templates;
  }

  @override
  Future<ActionDraftProposal> draftFromPrompt(String prompt) async {
    draftPrompts.add(prompt);
    if (draftError case final error?) throw error;
    return proposal!;
  }

  @override
  Future<ActionOpportunity> createAction(
    CreateActionDefinitionRequest request,
  ) async {
    createdRequests.add(request);
    return _actionFor(request, ActionDefinitionStatus.active);
  }

  @override
  Future<ActionOpportunity> saveDraft(
    CreateActionDefinitionRequest request,
  ) async {
    savedRequests.add(request);
    if (saveError case final error?) throw error;
    return lastSaved = _actionFor(request, ActionDefinitionStatus.draft);
  }

  ActionOpportunity _actionFor(
    CreateActionDefinitionRequest request,
    ActionDefinitionStatus status,
  ) {
    final terms = request.reward;
    final reward = terms == null
        ? lastSaved?.reward
        : RewardSummary(
            cluster: RewardCluster.devnet,
            mint: 'mint',
            tokenSymbol: 'USDC',
            decimals: 6,
            amountPerPayout: terms.amountPerPayout,
            maxPayouts: terms.maxPayouts,
            payoutsRemaining: terms.maxPayouts,
            maxWinsPerAccount: terms.maxWinsPerAccount,
            myWins: 0,
            status: savedRewardStatus,
            expiresAt: terms.expiresAt,
          );
    return ActionOpportunity(
      id: editorActionId,
      creatorDisplayName: 'Ifiok',
      viewerIsCreator: true,
      actionKey: request.actionKey,
      revision: savedRequests.length + createdRequests.length,
      status: status,
      title: request.title,
      description: request.description,
      recurrence: request.recurrence,
      timeZone: request.timeZone,
      maxVerifiedCompletions: request.maxVerifiedCompletions,
      verifiedCompletions: 0,
      opensAt: request.opensAt,
      closesAt: request.closesAt,
      updatedAt: DateTime.utc(2026, 10, 21),
      requirements: [
        for (final (index, draft) in request.requirements.indexed)
          requirementViewFor(draft, index),
      ],
      reward: reward,
    );
  }

  int previewCalls = 0;

  @override
  Future<ActionOpportunity> preview(UuidValue actionId) async {
    previewCalls++;
    final action = previews[actionId.uuid];
    if (action == null) {
      throw ResourceNotFoundException(
        resource: MissingResource.action,
        message: 'Not found.',
      );
    }
    return action;
  }

  @override
  Future<ActionOpportunity> publish(ActionOpportunity action) async {
    publishedActions.add(action);
    return action.copyWith(
      status: ActionDefinitionStatus.active,
      revision: action.revision + 1,
      publishedAt: DateTime.utc(2026, 10, 21),
    );
  }

  @override
  Future<ActionQrChallengeView> createQrChallenge(
    UuidValue requirementId, {
    Duration validity = const Duration(minutes: 5),
  }) async {
    qrRequests.add(requirementId);
    if (qrError case final error?) throw error;
    return ActionQrChallengeView(
      code: 'venue-code-${qrRequests.length}',
      expiresAt: clock.now().add(qrValidity),
    );
  }

  @override
  Future<List<ActionOpportunity>> listOwned() => throw UnimplementedError();

  @override
  Future<ActionOpportunity> pause(ActionOpportunity action) =>
      throw UnimplementedError();

  @override
  Future<List<ActionOpportunity>> listAvailable() => throw UnimplementedError();

  @override
  Future<ActionOpportunity> getAction(UuidValue actionId) =>
      throw UnimplementedError();

  @override
  Future<List<ActionOpportunity>> listNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) => throw UnimplementedError();

  @override
  Future<ActionAttemptView> beginAttempt(UuidValue actionId) =>
      throw UnimplementedError();

  @override
  Future<ActionSpokenChallengeView> issueSpokenChallenge({
    required UuidValue attemptId,
    required UuidValue requirementId,
  }) => throw UnimplementedError();

  @override
  Future<ActionAttemptView> completeAttempt(UuidValue attemptId) =>
      throw UnimplementedError();

  @override
  Future<List<ActionAttemptView>> listMyAttempts() =>
      throw UnimplementedError();

  @override
  Future<EvidenceSubmissionResult> requestAppVerification({
    required UuidValue attemptId,
    required UuidValue requirementId,
    String? reference,
  }) => throw UnimplementedError();

  @override
  Future<EvidenceSubmissionResult?> getAppVerification({
    required UuidValue attemptId,
    required UuidValue requirementId,
  }) => throw UnimplementedError();
}

/// A [RewardRepository] whose funding answers are set per test.
class FakeRewardRepository implements RewardRepository {
  FakeRewardRepository({
    RewardFundingPlan? plan,
    this.prepareError,
    List<RewardPoolView>? confirmations,
    List<Exception>? confirmErrors,
  }) : plan = plan ?? fundingPlanFixture(),
       confirmations = confirmations ?? [poolFixture()],
       confirmErrors = confirmErrors ?? [];

  RewardFundingPlan plan;
  Exception? prepareError;

  /// Thrown by the first confirmations, in order, before any succeeds.
  final List<Exception> confirmErrors;

  /// What successive confirmations return; the last one repeats.
  final List<RewardPoolView> confirmations;
  final preparedActions = <UuidValue>[];
  final confirmedSignatures = <String>[];

  @override
  Future<RewardFundingPlan> prepareFunding(UuidValue actionId) async {
    preparedActions.add(actionId);
    if (prepareError case final error?) throw error;
    return plan;
  }

  @override
  Future<RewardPoolView> confirmFunding({
    required UuidValue actionId,
    required String signature,
  }) async {
    confirmedSignatures.add(signature);
    if (confirmErrors.isNotEmpty) throw confirmErrors.removeAt(0);
    final index = confirmedSignatures.length - 1;
    return confirmations[index < confirmations.length
        ? index
        : confirmations.length - 1];
  }

  @override
  Future<RewardPoolView?> getPool(UuidValue actionId) =>
      throw UnimplementedError();

  @override
  Future<RewardEndPlan> endEarly(UuidValue actionId) =>
      throw UnimplementedError();

  @override
  Future<List<RewardPayoutView>> listMyPayouts() => throw UnimplementedError();
}

class FakePayoutWalletRepository implements PayoutWalletRepository {
  FakePayoutWalletRepository({this.wallet});

  PayoutWalletView? wallet;
  final linkedSignatures = <String>[];

  @override
  Future<PayoutWalletView?> getMine() async => wallet;

  @override
  Future<PayoutWalletLinkChallengeView> createLinkChallenge(
    String walletAddress,
  ) async => PayoutWalletLinkChallengeView(
    walletAddress: walletAddress,
    message: 'Link $walletAddress to Verily',
    nonce: 'nonce',
    expiresAt: DateTime.utc(2026, 10, 21, 15),
  );

  @override
  Future<PayoutWalletView> link({
    required String walletAddress,
    required String nonce,
    required String signature,
  }) async {
    linkedSignatures.add(signature);
    return wallet = linkedWalletFixture(walletAddress);
  }
}

PayoutWalletView linkedWalletFixture([String address = editorCreatorWallet]) =>
    PayoutWalletView(
      walletAddress: address,
      label: 'Phantom',
      linkedAt: DateTime.utc(2026, 10, 20),
    );

class FakeAppsRepository implements AppsRepository {
  FakeAppsRepository({this.apps = const []});

  List<VerilyAppView> apps;

  @override
  Future<List<VerilyAppView>> listApps() async => apps;

  @override
  Future<VerilyAppView> getApp(UuidValue appId) => throw UnimplementedError();

  @override
  Future<VerilyAppCredential> createApp({
    required String name,
    String? websiteUrl,
  }) => throw UnimplementedError();

  @override
  Future<VerilyAppCredential> createKey(UuidValue appId) =>
      throw UnimplementedError();

  @override
  Future<VerilyAppView> revokeKey({
    required UuidValue appId,
    required String keyId,
  }) => throw UnimplementedError();

  @override
  Future<VerilyAppView> revokeApp(UuidValue appId) =>
      throw UnimplementedError();

  @override
  Future<List<AppConfirmationView>> listConfirmations(
    UuidValue appId, {
    UuidValue? beforeId,
  }) => throw UnimplementedError();

  @override
  Future<VerilyAppLinkView> linkApp(UuidValue appId) =>
      throw UnimplementedError();

  @override
  Future<VerilyAppView> setWebhookUrl({
    required UuidValue appId,
    required String? webhookUrl,
  }) => throw UnimplementedError();

  @override
  Future<VerilyAppWebhookSecret> rotateWebhookSecret(UuidValue appId) =>
      throw UnimplementedError();

  @override
  Future<VerilyAppView> setRedirectUris({
    required UuidValue appId,
    required List<String> redirectUris,
  }) => throw UnimplementedError();

  @override
  Future<List<AppWebhookDeliveryView>> listWebhookDeliveries(
    UuidValue appId, {
    UuidValue? beforeId,
  }) => throw UnimplementedError();
}

/// A wallet that authorizes [address] and signs whatever it is asked to,
/// or fails with [failure].
class FakeMobileWallet implements MobileWallet {
  FakeMobileWallet({
    this.isSupported = true,
    this.address = editorCreatorWallet,
    this.failure,
  });

  @override
  final bool isSupported;
  String address;
  WalletFailure? failure;
  final sentTransactions = <Uint8List>[];
  final signedMessages = <String>[];

  @override
  Future<T> connect<T>({
    required WalletChain chain,
    required Future<T> Function(WalletConnection wallet) body,
  }) async {
    if (!isSupported) throw const WalletException(WalletFailure.unavailable);
    if (failure case final failure?) throw WalletException(failure);
    return body(_FakeConnection(this));
  }
}

class _FakeConnection implements WalletConnection {
  _FakeConnection(this._wallet);

  final FakeMobileWallet _wallet;

  @override
  String get address => _wallet.address;

  @override
  Future<String> signMessage(String message) async {
    _wallet.signedMessages.add(message);
    return 'signed-message';
  }

  @override
  Future<String> signAndSendTransaction(Uint8List wireTransaction) async {
    _wallet.sentTransactions.add(wireTransaction);
    return 'funding-signature';
  }
}

class FakeLocationService implements LocationService {
  FakeLocationService({this.fix, this.failure});

  LocationFix? fix;
  LocationFailure? failure;

  @override
  Future<LocationFix> precisePosition() async {
    if (failure case final failure?) throw LocationException(failure);
    return fix!;
  }

  @override
  Future<LocationFix> approximatePosition() => precisePosition();

  @override
  Future<void> openSettings() async {}
}

/// The fakes one editor test uses, with the overrides that install them.
class EditorFakes {
  EditorFakes({
    FakeActionRepository? actions,
    FakeRewardRepository? rewards,
    FakePayoutWalletRepository? wallets,
    FakeAppsRepository? apps,
    FakeMobileWallet? wallet,
    FakeLocationService? location,
    this.developmentEscrowAllowed = true,
    this.deviceTimeZone = 'Europe/London',
  }) : actions = actions ?? FakeActionRepository(),
       rewards = rewards ?? FakeRewardRepository(),
       wallets = wallets ?? FakePayoutWalletRepository(),
       apps = apps ?? FakeAppsRepository(),
       wallet = wallet ?? FakeMobileWallet(),
       location = location ?? FakeLocationService();

  final FakeActionRepository actions;
  final FakeRewardRepository rewards;
  final FakePayoutWalletRepository wallets;
  final FakeAppsRepository apps;
  final FakeMobileWallet wallet;
  final FakeLocationService location;
  final bool developmentEscrowAllowed;

  /// What the device reports as its time zone.
  final String deviceTimeZone;

  List<Override> get overrides => [
    actionRepositoryProvider.overrideWithValue(actions),
    rewardRepositoryProvider.overrideWithValue(rewards),
    payoutWalletRepositoryProvider.overrideWithValue(wallets),
    appsRepositoryProvider.overrideWithValue(apps),
    mobileWalletProvider.overrideWithValue(wallet),
    locationServiceProvider.overrideWithValue(location),
    deviceTimeZoneProvider.overrideWith((ref) async => deviceTimeZone),
    fundingDevelopmentEscrowAllowedProvider.overrideWithValue(
      developmentEscrowAllowed,
    ),
    // The place picker draws its overlays over a plain box, not MapLibre.
    actionMapViewBuilderProvider.overrideWithValue(
      (context) => const SizedBox.expand(),
    ),
  ];
}
