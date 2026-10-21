import 'package:flutter/widgets.dart';

/// Stable selectors shared by production widgets and end-to-end tests.
///
/// Each feature keeps its keys in its own section below.
abstract final class VerilyTestKeys {
  // ── Shell ──
  static const navigationDo = ValueKey<String>('navigation-do');
  static const navigationCreate = ValueKey<String>('navigation-create');
  static const navigationMe = ValueKey<String>('navigation-me');
  static const comingSoonGoToDo = ValueKey<String>('coming-soon-go-to-do');

  // ── Appearance ──
  static const appearanceSystem = ValueKey<String>('appearance-system');
  static const appearanceLight = ValueKey<String>('appearance-light');
  static const appearanceDark = ValueKey<String>('appearance-dark');

  // ── Developer tools ──
  static const developerMenuLauncher = ValueKey<String>(
    'developer-menu-launcher',
  );
  static const developerSkribblePreview = ValueKey<String>(
    'developer-skribble-preview',
  );
  static const developerMovementPreview = ValueKey<String>(
    'developer-movement-preview',
  );

  // ── Create: editor ──
  static const editorPrompt = ValueKey<String>('editor-prompt');
  static const editorDraftWithAi = ValueKey<String>('editor-draft-with-ai');
  static const editorStartBlank = ValueKey<String>('editor-start-blank');
  static const editorStartOver = ValueKey<String>('editor-start-over');
  static ValueKey<String> editorTemplate(String templateKey) =>
      ValueKey<String>('editor-template-$templateKey');
  static const editorTitle = ValueKey<String>('editor-title');
  static const editorDescription = ValueKey<String>('editor-description');
  static const editorAddProof = ValueKey<String>('editor-add-proof');
  static ValueKey<String> editorAddProofKind(String kind) =>
      ValueKey<String>('editor-add-proof-$kind');
  static ValueKey<String> editorRequirement(String requirementKey) =>
      ValueKey<String>('editor-requirement-$requirementKey');
  static ValueKey<String> editorRemoveRequirement(String requirementKey) =>
      ValueKey<String>('editor-requirement-remove-$requirementKey');
  static ValueKey<String> editorRequirementTitle(String requirementKey) =>
      ValueKey<String>('editor-requirement-title-$requirementKey');
  static ValueKey<String> editorRequirementInstructions(
    String requirementKey,
  ) => ValueKey<String>('editor-requirement-instructions-$requirementKey');
  static ValueKey<String> editorVerifierPrompt(String requirementKey) =>
      ValueKey<String>('editor-verifier-prompt-$requirementKey');
  static ValueKey<String> editorMinSeconds(String requirementKey) =>
      ValueKey<String>('editor-min-seconds-$requirementKey');
  static ValueKey<String> editorMaxSeconds(String requirementKey) =>
      ValueKey<String>('editor-max-seconds-$requirementKey');
  static ValueKey<String> editorSpokenChallenge(String requirementKey) =>
      ValueKey<String>('editor-spoken-challenge-$requirementKey');
  static ValueKey<String> editorMoreChecks(String requirementKey) =>
      ValueKey<String>('editor-more-checks-$requirementKey');
  static ValueKey<String> editorMovementKind(
    String requirementKey,
    String movement,
  ) => ValueKey<String>('editor-movement-$requirementKey-$movement');
  static ValueKey<String> editorMovementTarget(String requirementKey) =>
      ValueKey<String>('editor-movement-target-$requirementKey');
  static ValueKey<String> editorMotionType(
    String requirementKey,
    String type,
  ) => ValueKey<String>('editor-motion-$requirementKey-$type');
  static ValueKey<String> editorMotionRepetitions(String requirementKey) =>
      ValueKey<String>('editor-motion-repetitions-$requirementKey');
  static ValueKey<String> editorAppChoice(
    String requirementKey,
    String appId,
  ) => ValueKey<String>('editor-app-$requirementKey-$appId');
  static ValueKey<String> editorPlaceMap(String requirementKey) =>
      ValueKey<String>('editor-place-map-$requirementKey');
  static ValueKey<String> editorUseMyLocation(String requirementKey) =>
      ValueKey<String>('editor-place-locate-$requirementKey');
  static ValueKey<String> editorPlaceRadius(String requirementKey) =>
      ValueKey<String>('editor-place-radius-$requirementKey');
  static ValueKey<String> editorPlaceCoordinates(String requirementKey) =>
      ValueKey<String>('editor-place-coordinates-$requirementKey');
  static ValueKey<String> editorPlaceLatitude(String requirementKey) =>
      ValueKey<String>('editor-place-latitude-$requirementKey');
  static ValueKey<String> editorPlaceLongitude(String requirementKey) =>
      ValueKey<String>('editor-place-longitude-$requirementKey');
  static const editorRecurrence = ValueKey<String>('editor-recurrence');
  static const editorTimeZone = ValueKey<String>('editor-time-zone');
  static const editorOpens = ValueKey<String>('editor-opens');
  static const editorCloses = ValueKey<String>('editor-closes');
  static const editorMaxCompletions = ValueKey<String>(
    'editor-max-completions',
  );
  static const editorRewardToggle = ValueKey<String>('editor-reward-toggle');
  static const editorRewardAmount = ValueKey<String>('editor-reward-amount');
  static const editorRewardMaxPayouts = ValueKey<String>(
    'editor-reward-max-payouts',
  );
  static const editorRewardMaxWins = ValueKey<String>(
    'editor-reward-max-wins',
  );
  static const editorRewardEnds = ValueKey<String>('editor-reward-ends');
  static const editorRewardRefundDelay = ValueKey<String>(
    'editor-reward-refund-delay',
  );
  static const editorRewardBudget = ValueKey<String>('editor-reward-budget');
  static const editorSave = ValueKey<String>('editor-save');
  static const editorPreview = ValueKey<String>('editor-preview');
  static const editorPublish = ValueKey<String>('editor-publish');
  static const editorPublishConfirm = ValueKey<String>(
    'editor-publish-confirm',
  );
  static const venueCodeSheet = ValueKey<String>('venue-code-sheet');
  static const venueCodeImage = ValueKey<String>('venue-code-image');
  static const venueCodeCountdown = ValueKey<String>('venue-code-countdown');
  static const venueCodeNew = ValueKey<String>('venue-code-new');
  static const fundingSheet = ValueKey<String>('funding-sheet');
  static const fundingLinkWallet = ValueKey<String>('funding-link-wallet');
  static const fundingApprove = ValueKey<String>('funding-approve');
  static const fundingDevelopment = ValueKey<String>('funding-development');
  static const fundingDevConfirm = ValueKey<String>('funding-dev-confirm');
  static const fundingUnavailable = ValueKey<String>('funding-unavailable');
  static const fundingFunded = ValueKey<String>('funding-funded');
  static const fundingFailed = ValueKey<String>('funding-failed');
  static const fundingProblem = ValueKey<String>('funding-problem');
  static const fundingDone = ValueKey<String>('funding-done');

  // ── Create: hub and Apps ──
  static const hubPostAction = ValueKey<String>('hub-post-action');
  static const hubApps = ValueKey<String>('hub-apps');
  static const hubAppeals = ValueKey<String>('hub-appeals');
  static ValueKey<String> hubActionCard(String actionId) =>
      ValueKey<String>('hub-action-$actionId');
  static ValueKey<String> hubFund(String actionId) =>
      ValueKey<String>('hub-fund-$actionId');
  static ValueKey<String> hubPublish(String actionId) =>
      ValueKey<String>('hub-publish-$actionId');
  static ValueKey<String> hubPause(String actionId) =>
      ValueKey<String>('hub-pause-$actionId');
  static ValueKey<String> hubVenueCode(String actionId) =>
      ValueKey<String>('hub-venue-code-$actionId');
  static ValueKey<String> hubEdit(String actionId) =>
      ValueKey<String>('hub-edit-$actionId');
  static ValueKey<String> hubView(String actionId) =>
      ValueKey<String>('hub-view-$actionId');
  static const appsName = ValueKey<String>('apps-name');
  static const appsWebsite = ValueKey<String>('apps-website');
  static const appsRegister = ValueKey<String>('apps-register');
  static ValueKey<String> appsCard(String appId) =>
      ValueKey<String>('apps-card-$appId');
  static const appsKeyValue = ValueKey<String>('apps-key-value');
  static const appsKeyCopy = ValueKey<String>('apps-key-copy');
  static const appsKeySaved = ValueKey<String>('apps-key-saved');
  static const appsNewKey = ValueKey<String>('apps-new-key');
  static ValueKey<String> appsRevokeKey(String keyId) =>
      ValueKey<String>('apps-revoke-key-$keyId');
  static const appsRevokeApp = ValueKey<String>('apps-revoke-app');
  static const appsRevokeConfirm = ValueKey<String>('apps-revoke-confirm');
  static const appsCurlExample = ValueKey<String>('apps-curl-example');
  static const appsCurlCopy = ValueKey<String>('apps-curl-copy');
  static const appsConfirmationsMore = ValueKey<String>(
    'apps-confirmations-more',
  );
  static ValueKey<String> appsConfirmation(String eventId) =>
      ValueKey<String>('apps-confirmation-$eventId');

  // ── Do ──
  static const doViewToggle = ValueKey<String>('do-view-toggle');
  static ValueKey<String> doFilter(String name) =>
      ValueKey<String>('do-filter-$name');
  static ValueKey<String> doActionCard(String actionId) =>
      ValueKey<String>('do-action-card-$actionId');
  static const doMap = ValueKey<String>('do-map');
  static ValueKey<String> doMapPin(String actionId) =>
      ValueKey<String>('do-map-pin-$actionId');
  static const doNearbyContinue = ValueKey<String>('do-nearby-continue');
  static const doNearbyNotNow = ValueKey<String>('do-nearby-not-now');
  static const actionNotFound = ValueKey<String>('action-not-found');
  static const actionStart = ValueKey<String>('action-start');
  static const actionFinish = ValueKey<String>('action-finish');
  static const actionNotice = ValueKey<String>('action-notice');
  static ValueKey<String> actionProof(String requirementKey) =>
      ValueKey<String>('action-proof-$requirementKey');
  static const actionProofAcceptedTick = ValueKey<String>(
    'action-proof-accepted-tick',
  );
  static const actionVerifiedOutcome = ValueKey<String>(
    'action-verified-outcome',
  );
  static const actionPayoutStatus = ValueKey<String>('action-payout-status');
  static const actionAddWallet = ValueKey<String>('action-add-wallet');
  static const actionCheckingOutcome = ValueKey<String>(
    'action-checking-outcome',
  );
  static const actionReviewOutcome = ValueKey<String>('action-review-outcome');
  static const actionCapacityOutcome = ValueKey<String>(
    'action-capacity-outcome',
  );
  static const actionRejectedOutcome = ValueKey<String>(
    'action-rejected-outcome',
  );
  static const actionAppealOpen = ValueKey<String>('action-appeal-open');
  static const actionAppealReason = ValueKey<String>('action-appeal-reason');
  static const actionAppealSubmit = ValueKey<String>('action-appeal-submit');
  static const actionAppealStatus = ValueKey<String>('action-appeal-status');
  static ValueKey<String> actionAppCard(String requirementKey) =>
      ValueKey<String>('action-app-card-$requirementKey');
  static const actionLinkCodeOpen = ValueKey<String>('action-link-code-open');
  static const actionLinkCode = ValueKey<String>('action-link-code');
  static const actionLinkCodeCopy = ValueKey<String>('action-link-code-copy');
  static const actionCreatorPanel = ValueKey<String>('action-creator-panel');
  static const actionEdit = ValueKey<String>('action-edit');
  static ValueKey<String> actionShowVenueCode(String requirementKey) =>
      ValueKey<String>('action-show-venue-code-$requirementKey');

  // ── Capture ──
  static const captureClose = ValueKey<String>('capture-close');
  static const captureFlip = ValueKey<String>('capture-flip');
  static const captureShutter = ValueKey<String>('capture-shutter');
  static const captureRecordStart = ValueKey<String>('capture-record-start');
  static const captureRecordStop = ValueKey<String>('capture-record-stop');
  static const captureChallengeWord = ValueKey<String>(
    'capture-challenge-word',
  );
  static const captureChallengeRetry = ValueKey<String>(
    'capture-challenge-retry',
  );
  static const captureReviewSend = ValueKey<String>('capture-review-send');
  static const captureReviewRetake = ValueKey<String>('capture-review-retake');
  static const captureSendAgain = ValueKey<String>('capture-send-again');
  static const captureOpenSettings = ValueKey<String>('capture-open-settings');
  static const captureAudioLevel = ValueKey<String>('capture-audio-level');
  static const movementCaptureStart = ValueKey<String>(
    'movement-capture-start',
  );
  static const movementCaptureStop = ValueKey<String>('movement-capture-stop');
  static const movementCaptureClose = ValueKey<String>(
    'movement-capture-close',
  );
  static const movementCaptureFlip = ValueKey<String>('movement-capture-flip');
  static const movementCaptureCount = ValueKey<String>(
    'movement-capture-count',
  );
  static const movementCaptureCountdown = ValueKey<String>(
    'movement-capture-countdown',
  );
  static const movementCaptureDepthMeter = ValueKey<String>(
    'movement-capture-depth-meter',
  );
  static const movementCaptureRetry = ValueKey<String>(
    'movement-capture-retry',
  );
  static const captureMotionBegin = ValueKey<String>('capture-motion-begin');
  static const captureMotionRetry = ValueKey<String>('capture-motion-retry');
  static const captureMotionUse = ValueKey<String>('capture-motion-use');
  static const captureMotionCancel = ValueKey<String>('capture-motion-cancel');
  static const captureMotionSafetyWarning = ValueKey<String>(
    'capture-motion-safety-warning',
  );

  // ── Me, welcome, sign-in, settings, review, appeals ──
  static const welcomeGetStarted = ValueKey<String>('welcome-get-started');
  static const welcomeHaveAccount = ValueKey<String>('welcome-have-account');
  static const signInCancel = ValueKey<String>('sign-in-cancel');
  static const meSettingsButton = ValueKey<String>('me-settings-button');
  static const meWalletLink = ValueKey<String>('me-wallet-link');
  static const meWalletCopy = ValueKey<String>('me-wallet-copy');
  static const meLinkReview = ValueKey<String>('me-link-review');
  static const meLinkAppeals = ValueKey<String>('me-link-appeals');
  static const meLinkSettings = ValueKey<String>('me-link-settings');
  static ValueKey<String> meAttempt(String attemptId) =>
      ValueKey<String>('me-attempt-$attemptId');
  static ValueKey<String> meAppeal(String attemptId) =>
      ValueKey<String>('me-appeal-$attemptId');
  static const meAppealReason = ValueKey<String>('me-appeal-reason');
  static const meAppealSubmit = ValueKey<String>('me-appeal-submit');
  static ValueKey<String> mePayout(String payoutId) =>
      ValueKey<String>('me-payout-$payoutId');
  static const settingsSignOut = ValueKey<String>('settings-sign-out');
  static const settingsSignOutConfirm = ValueKey<String>(
    'settings-sign-out-confirm',
  );
  static const settingsCloseAccount = ValueKey<String>(
    'settings-close-account',
  );
  static const settingsCloseAccountConfirmation = ValueKey<String>(
    'settings-close-account-confirmation',
  );
  static const settingsCloseAccountConfirm = ValueKey<String>(
    'settings-close-account-confirm',
  );
  static ValueKey<String> reviewAccept(String evidenceId) =>
      ValueKey<String>('review-accept-$evidenceId');
  static ValueKey<String> reviewReject(String evidenceId) =>
      ValueKey<String>('review-reject-$evidenceId');
  static const reviewMediaReload = ValueKey<String>('review-media-reload');
  static const decisionNote = ValueKey<String>('decision-note');
  static const decisionSubmit = ValueKey<String>('decision-submit');
  static ValueKey<String> appealAccept(String appealId) =>
      ValueKey<String>('appeal-accept-$appealId');
  static ValueKey<String> appealReject(String appealId) =>
      ValueKey<String>('appeal-reject-$appealId');
}
