// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tabDo => 'Do';

  @override
  String get tabCreate => 'Create';

  @override
  String get tabMe => 'Me';

  @override
  String get navigationPrimaryLabel => 'Main sections';

  @override
  String get navigationRailHeading => 'Your spaces';

  @override
  String get errorGeneric => 'Something went wrong. Try again in a moment.';

  @override
  String get errorNotFound =>
      'We couldn\'t find that. It may have ended or been removed.';

  @override
  String get errorActionInvalid =>
      'Part of this action can\'t be saved yet. Check each step and try again.';

  @override
  String get errorActionUnsafeText =>
      'Some of this text can\'t be used. Rephrase it and try again.';

  @override
  String get navigationFindActions => 'Find actions';

  @override
  String get trustVerifiedOnPhone => 'Verified on your phone';

  @override
  String trustConfirmedByApp(String appName) {
    return 'Confirmed by $appName';
  }

  @override
  String rewardInEscrow(String amount) {
    return '$amount · in escrow';
  }

  @override
  String rewardRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rewards left',
      one: '1 reward left',
      zero: 'No rewards left',
    );
    return '$_temp0';
  }

  @override
  String get attemptStatusCollectingEvidence => 'In progress';

  @override
  String get attemptStatusVerifying => 'Checking your proof';

  @override
  String get attemptStatusPendingReview => 'With a reviewer';

  @override
  String get attemptStatusVerified => 'Verified';

  @override
  String get attemptStatusRejected => 'Not accepted';

  @override
  String get attemptStatusCapacityReached => 'This action is full';

  @override
  String payoutOnItsWay(String amount) {
    return '$amount on its way';
  }

  @override
  String payoutAwaitingWallet(String amount) {
    return 'Add a wallet to receive $amount';
  }

  @override
  String payoutHeldForReview(String amount) {
    return '$amount held for a quick check';
  }

  @override
  String payoutReleased(String amount) {
    return '$amount paid';
  }

  @override
  String payoutFailed(String amount) {
    return 'Sending $amount didn\'t work yet. We\'ll keep trying.';
  }

  @override
  String payoutExpired(String amount) {
    return '$amount expired before it could be sent';
  }

  @override
  String get rewardOutcomePoolEmpty =>
      'Every reward for this action has been claimed';

  @override
  String get rewardOutcomeAccountLimit =>
      'You\'ve earned the most this action allows';

  @override
  String get rewardOutcomePoolEnded => 'The reward period had ended';

  @override
  String get editorMapUnavailable =>
      'The map isn\'t available here. Enter the place\'s coordinates instead.';

  @override
  String get editorVerifierPromptInvalid =>
      'Say what Verily should check in at least 10 characters.';

  @override
  String get venueCodeNew => 'Show a new code';

  @override
  String get editorNewTitle => 'New action';

  @override
  String get editorEditTitle => 'Edit action';

  @override
  String get editorNewSubtitle => 'A place, a proof, and an optional reward';

  @override
  String get editorEditSubtitle =>
      'Saving a live action starts its next version';

  @override
  String get editorLoading => 'Opening your action…';

  @override
  String get editorLoadFailed => 'We couldn\'t open this action';

  @override
  String get editorStartHeading => 'How do you want to start?';

  @override
  String get editorPromptLabel => 'Describe the action';

  @override
  String get editorPromptHint =>
      'e.g. Ten squats in the park before 9am, filmed in one go';

  @override
  String get editorPromptHelp =>
      'Verily drafts the place, the proof, and the wording. You check every field before anything goes live.';

  @override
  String get editorPromptAction => 'Draft it for me';

  @override
  String get editorPromptTooShort =>
      'Say a little more: at least 20 characters.';

  @override
  String get editorTemplatesHeading => 'Or start from a template';

  @override
  String get editorTemplatesLoading => 'Loading templates…';

  @override
  String get editorTemplatesFailed => 'Templates didn\'t load.';

  @override
  String get editorStartBlank => 'Start from scratch';

  @override
  String get editorStartOver => 'Start over';

  @override
  String get editorDraftReady =>
      'Draft ready. Check every field before you save.';

  @override
  String get editorSafetyHeading => 'Before you publish';

  @override
  String get editorBasicsHeading => 'The action';

  @override
  String get editorTitleLabel => 'Title';

  @override
  String get editorDescriptionLabel => 'What people do';

  @override
  String get editorFieldRequired => 'Fill this in.';

  @override
  String get editorFixErrors => 'A few fields need a look before saving.';

  @override
  String get editorProofHeading => 'Proof';

  @override
  String get editorProofHelp =>
      'Up to five. Every proof is captured live in Verily, or confirmed by one of your Apps.';

  @override
  String get editorProofNone => 'Add at least one proof.';

  @override
  String get editorAddProof => 'Add proof';

  @override
  String get editorAddProofSheetTitle => 'What should people prove?';

  @override
  String editorRemoveProof(String title) {
    return 'Remove $title';
  }

  @override
  String get editorProofTitleLabel => 'What to call it';

  @override
  String get editorProofInstructionsLabel => 'What people do for it';

  @override
  String get editorProofMaxReached =>
      'An action can ask for five proofs at most.';

  @override
  String get editorProofAppOnly =>
      'An App\'s confirmation is the only proof on its action. Remove it to add phone proof.';

  @override
  String get editorProofPhoneOnly =>
      'App confirmation can\'t be mixed with phone proof. Remove the other proofs to use it.';

  @override
  String get editorKindLocation => 'Be at a place';

  @override
  String get editorKindLocationHelp =>
      'A pin and a radius. People share a fresh location from inside it.';

  @override
  String get editorKindLocationDefaultTitle => 'Check in at the place';

  @override
  String get editorKindLocationDefaultInstructions =>
      'Share a fresh location while you\'re there.';

  @override
  String get editorKindVenueCode => 'Scan a venue code';

  @override
  String get editorKindVenueCodeHelp =>
      'You show a code at the venue that changes every few minutes.';

  @override
  String get editorKindVenueCodeDefaultTitle => 'Scan the venue code';

  @override
  String get editorKindVenueCodeDefaultInstructions =>
      'Scan the code on display right now.';

  @override
  String get editorKindMotion => 'Move the phone';

  @override
  String get editorKindMotionHelp =>
      'Spins, flips, shakes, a gentle toss, or holding still, felt by the phone.';

  @override
  String get editorKindMotionDefaultTitle => 'Move the phone';

  @override
  String get editorKindMotionDefaultInstructions =>
      'Hold the phone securely and do the movement once you start.';

  @override
  String get editorKindMovementReps => 'Count reps';

  @override
  String get editorKindMovementRepsHelp =>
      'Squats, press-ups and more, counted live by the camera and checked from the video.';

  @override
  String get editorKindMovementRepsDefaultTitle => 'Do the reps';

  @override
  String get editorKindMovementRepsDefaultInstructions =>
      'Prop your phone up, step back so your whole body is in frame, and keep going until the counter reaches the target.';

  @override
  String get editorKindVideo => 'Record a video';

  @override
  String get editorKindVideoHelp => 'Filmed live in Verily, never uploaded.';

  @override
  String get editorKindVideoDefaultTitle => 'Record it';

  @override
  String get editorKindVideoDefaultInstructions =>
      'Film one continuous take that shows it happening.';

  @override
  String get editorKindPhoto => 'Take a photo';

  @override
  String get editorKindPhotoHelp =>
      'Taken live in Verily, never picked from the gallery.';

  @override
  String get editorKindPhotoDefaultTitle => 'Take the photo';

  @override
  String get editorKindPhotoDefaultInstructions =>
      'Take one clear photo that shows it.';

  @override
  String get editorKindAudio => 'Record audio';

  @override
  String get editorKindAudioHelp => 'Recorded live in Verily.';

  @override
  String get editorKindAudioDefaultTitle => 'Record it';

  @override
  String get editorKindAudioDefaultInstructions =>
      'Record one continuous clip.';

  @override
  String get editorKindApp => 'Confirmed by your App';

  @override
  String get editorKindAppHelp =>
      'One of your Verily Apps tells Verily it happened. Verily doesn\'t check the act itself.';

  @override
  String get editorKindAppDefaultTitle => 'Confirmed by your App';

  @override
  String get editorKindAppDefaultInstructions =>
      'Do it in the App. It confirms with Verily for you.';

  @override
  String get editorPlaceTapHint =>
      'Tap the map to move the pin. The hatched circle is where proof counts.';

  @override
  String get editorUseMyLocation => 'Use my location';

  @override
  String get editorLocationFailed =>
      'We couldn\'t find your location. Tap the map or enter the coordinates.';

  @override
  String get editorLocationOff =>
      'Location is off for Verily. Tap the map or enter the coordinates.';

  @override
  String editorRadius(int meters) {
    return 'Radius: $meters m';
  }

  @override
  String get editorRadiusSemantic => 'Radius around the place';

  @override
  String get editorCoordinates => 'Enter coordinates';

  @override
  String get editorLatitudeLabel => 'Latitude';

  @override
  String get editorLongitudeLabel => 'Longitude';

  @override
  String get editorCoordinatesInvalid =>
      'Latitude runs from -90 to 90 and longitude from -180 to 180.';

  @override
  String get editorPlaceMissing =>
      'Pick a place on the map or enter its coordinates.';

  @override
  String get editorMapLabel => 'Map for choosing where the action happens';

  @override
  String get editorPlacePin => 'Where the action happens';

  @override
  String get editorVenueCodeExplainer =>
      'Participants scan a code that only exists at the venue. After you publish, open the action and show its venue code there. It changes every few minutes, so a photo of it won\'t work later.';

  @override
  String get editorVerifierPromptLabel => 'What Verily should check';

  @override
  String get editorVerifierPromptHelp =>
      'Say plainly what the proof must show. Everything in the recording is treated as evidence, never as instructions.';

  @override
  String get editorMinSecondsLabel => 'Shortest (seconds)';

  @override
  String get editorMaxSecondsLabel => 'Longest (seconds)';

  @override
  String get editorSecondsInvalid =>
      'Between 3 and 300 seconds, and the longest can\'t be shorter than the shortest.';

  @override
  String editorMotionSecondsInvalid(int max) {
    return 'Between 1 and $max seconds, and the longest can\'t be shorter than the shortest.';
  }

  @override
  String get editorSpokenChallenge => 'Ask for a spoken word';

  @override
  String get editorSpokenChallengeHelp =>
      'Verily gives each person a fresh word to say while recording, so an old or generated clip can\'t pass.';

  @override
  String get editorMoreChecks => 'More checking options';

  @override
  String get editorPolicyLabel => 'How it\'s checked';

  @override
  String get editorPolicySingle => 'One careful check';

  @override
  String get editorPolicyCouncil => 'Several independent checks (stricter)';

  @override
  String editorConfidence(int percent) {
    return 'How sure the check must be: $percent%';
  }

  @override
  String get editorConfidenceSemantic => 'How sure the check must be';

  @override
  String get editorMovementLabel => 'Movement';

  @override
  String get editorMovementTargetLabel => 'How many';

  @override
  String get editorMovementTargetInvalid => 'Between 1 and 1,000.';

  @override
  String get editorMovementSquats => 'Squats';

  @override
  String get editorMovementPressUps => 'Press-ups';

  @override
  String get editorMovementSitUps => 'Sit-ups';

  @override
  String get editorMovementLunges => 'Lunges';

  @override
  String get editorMovementStarJumps => 'Star jumps';

  @override
  String get editorMovementBurpees => 'Burpees';

  @override
  String get editorMovementHighKnees => 'High knees';

  @override
  String get editorMovementLateralRaises => 'Lateral raises';

  @override
  String get editorMovementBicepsCurls => 'Biceps curls';

  @override
  String get editorMovementSideBends => 'Side bends';

  @override
  String get editorMovementFootballKickUps => 'Football kick-ups';

  @override
  String get editorMovementTableTennisBounces => 'Table tennis bounces';

  @override
  String get editorMotionTypeLabel => 'Movement';

  @override
  String get editorMotionToss => 'Gentle toss';

  @override
  String get editorMotionRotation => 'Full turns';

  @override
  String get editorMotionShake => 'Shakes';

  @override
  String get editorMotionStillness => 'Hold still';

  @override
  String get editorMotionAxisLabel => 'Direction';

  @override
  String get editorMotionAxisYaw => 'Spin with the screen facing you';

  @override
  String get editorMotionAxisPitch => 'Flip forward';

  @override
  String get editorMotionAxisRoll => 'Roll side over side';

  @override
  String get editorMotionAxisAny => 'Any direction';

  @override
  String get editorMotionRepetitionsLabel => 'How many times';

  @override
  String editorMotionRepetitionsInvalid(int max) {
    return 'Between 1 and $max.';
  }

  @override
  String get editorMotionTossSafety =>
      'Ask for a low toss over something soft, caught with both hands. Never ask anyone to throw a phone.';

  @override
  String get editorAppPickerLabel => 'Your App';

  @override
  String get editorAppNone =>
      'You have no active Apps yet. Create one under Apps first.';

  @override
  String get editorAppsLoading => 'Loading your Apps…';

  @override
  String get editorAppsFailed => 'Your Apps didn\'t load.';

  @override
  String get editorAppMissing => 'Choose the App that confirms this.';

  @override
  String editorAppTrust(String appName) {
    return 'People will see “Confirmed by $appName”.';
  }

  @override
  String get editorTimingHeading => 'When';

  @override
  String get editorOnce => 'Once';

  @override
  String get editorDaily => 'Every day';

  @override
  String get editorTimeZoneLabel => 'Time zone for daily resets';

  @override
  String get editorTimeZoneHelp =>
      'An IANA name, such as Europe/London or America/New_York.';

  @override
  String get editorOpensLabel => 'Opens';

  @override
  String get editorClosesLabel => 'Closes';

  @override
  String get editorDateAnyTime => 'Any time';

  @override
  String editorDateClear(String label) {
    return 'Clear $label';
  }

  @override
  String get editorClosesBeforeOpens => 'It has to close after it opens.';

  @override
  String get editorMaxCompletionsLabel => 'Most completions (optional)';

  @override
  String get editorWholeNumberInvalid => 'A whole number above zero.';

  @override
  String get editorRewardHeading => 'Reward';

  @override
  String get editorRewardToggle => 'Pay people who do it';

  @override
  String get editorRewardHelp =>
      'Rewards are paid in USDC from an escrow you fund before publishing. Nobody works for a promise.';

  @override
  String get editorRewardAmountLabel => 'Per completion (USDC)';

  @override
  String get editorRewardMaxPayoutsLabel => 'Number of payouts';

  @override
  String get editorRewardMaxWinsLabel => 'Most payouts one person can earn';

  @override
  String get editorRewardEndsLabel => 'Payouts end';

  @override
  String editorRewardRefundDelay(int days) {
    return 'Unused funds come back $days days after it ends';
  }

  @override
  String get editorRewardRefundDelayHelp =>
      'Time for checks and appeals to finish before the escrow can close.';

  @override
  String get editorRewardRefundSemantic => 'Days until unused funds come back';

  @override
  String editorRewardBudget(String total) {
    return 'You lock $total in escrow';
  }

  @override
  String get editorRewardBudgetIncomplete =>
      'Enter an amount and the number of payouts to see the total.';

  @override
  String get editorRewardAmountInvalid =>
      'Enter an amount above zero with at most 6 decimal places.';

  @override
  String get editorRewardAmountTooLarge =>
      'One payout can be at most 1,000,000 USDC.';

  @override
  String get editorRewardMaxPayoutsInvalid => 'Between 1 and 2,048 payouts.';

  @override
  String editorRewardMaxWinsInvalid(int max) {
    return 'Between 1 and $max.';
  }

  @override
  String get editorRewardEndTooSoon => 'Give it at least an hour.';

  @override
  String get editorRewardEndTooLate =>
      'A reward can stay open for a year at most.';

  @override
  String get editorRewardLocked =>
      'Funding has started, so these terms are fixed.';

  @override
  String get editorRewardStatusAwaiting => 'Waiting for escrow';

  @override
  String get editorRewardStatusFunded => 'Locked in escrow';

  @override
  String get editorRewardStatusEnded => 'Payouts ended';

  @override
  String get editorRewardStatusClosed => 'Escrow closed';

  @override
  String get editorSave => 'Save draft';

  @override
  String get editorPreview => 'Preview';

  @override
  String get editorPublish => 'Publish';

  @override
  String get editorFundAndPublish => 'Fund and publish';

  @override
  String editorPublishConfirmTitle(String title) {
    return 'Publish “$title”?';
  }

  @override
  String get editorPublishConfirmBody =>
      'It goes live for everyone right away. You can pause it later.';

  @override
  String get editorPublishConfirm => 'Publish now';

  @override
  String get editorSaved => 'Draft saved.';

  @override
  String get editorPublished => 'It\'s live.';

  @override
  String get editorFundFirst => 'Fund the reward to publish this action.';

  @override
  String get editorStatusDraft => 'Draft';

  @override
  String get editorStatusLive => 'Live';

  @override
  String get editorStatusPaused => 'Paused';

  @override
  String get editorStatusCompleted => 'Ended';

  @override
  String get venueCodeTitle => 'Venue code';

  @override
  String get venueCodeBody =>
      'Keep this open at the venue. People scan it with Verily, and it changes every few minutes.';

  @override
  String venueCodeChangesIn(String time) {
    return 'Changes in $time';
  }

  @override
  String get venueCodeRefreshing => 'Getting a fresh code…';

  @override
  String get venueCodeFailed => 'We couldn\'t get a venue code.';

  @override
  String venueCodeImageLabel(String title) {
    return 'Venue code for $title';
  }

  @override
  String get fundingTitle => 'Lock the reward in escrow';

  @override
  String get fundingIntro =>
      'Before anyone starts, the whole reward goes into an escrow that only verified proof can release. Unused funds come back to you after the action ends.';

  @override
  String get fundingWalletHeading => 'Your payout wallet';

  @override
  String get fundingWalletNeeded =>
      'Link the Solana wallet you\'ll fund the reward from. Refunds come back to it too.';

  @override
  String get fundingLinkWallet => 'Link a wallet';

  @override
  String fundingWalletLinked(String address) {
    return 'Linked wallet $address';
  }

  @override
  String get fundingNeedsAndroid =>
      'Funding needs the Verily Android app and a Solana wallet, such as Phantom or Solflare, on the same phone.';

  @override
  String get fundingLoading => 'Checking your wallet…';

  @override
  String get fundingPreparing => 'Preparing the escrow…';

  @override
  String get fundingPerCompletion => 'Per completion';

  @override
  String get fundingPayouts => 'Payouts';

  @override
  String get fundingTotal => 'Total locked';

  @override
  String get fundingEnds => 'Payouts end';

  @override
  String get fundingRefundFrom => 'Refund available from';

  @override
  String get fundingApprove => 'Approve in your wallet';

  @override
  String get fundingConfirming => 'Checking the escrow…';

  @override
  String get fundingFunded => 'Locked in escrow';

  @override
  String fundingFundedBody(String total) {
    return '$total is in escrow. You can publish the action now.';
  }

  @override
  String get fundingNotYet =>
      'The escrow isn\'t confirmed yet. Try again in a moment.';

  @override
  String get fundingSentNotVisible =>
      'Your wallet sent the escrow, but it isn\'t visible yet. Check again in a moment; there\'s no need to approve it twice.';

  @override
  String get fundingCheckAgain => 'Check the escrow again';

  @override
  String get fundingDevHeading => 'Development escrow (developer only)';

  @override
  String get fundingDevBody =>
      'This server uses a local development escrow with no blockchain. Confirming records a development signature, and no money moves.';

  @override
  String get fundingDevConfirm => 'Confirm development escrow';

  @override
  String get fundingUnavailable =>
      'Rewards aren\'t available on this server yet.';

  @override
  String get fundingWalletUnavailable =>
      'No Solana wallet answered. Install one that supports Mobile Wallet Adapter and try again.';

  @override
  String get fundingWalletCancelled =>
      'You declined in your wallet. Nothing was sent.';

  @override
  String get fundingWalletTimedOut =>
      'Your wallet didn\'t answer in time. Try again.';

  @override
  String get fundingWalletWrongAccount =>
      'That\'s a different wallet account. Approve with the wallet you linked.';

  @override
  String get fundingWalletInvalid =>
      'Your wallet sent back something we couldn\'t use. Try again.';

  @override
  String get fundingWalletFailed =>
      'The wallet request didn\'t finish. Try again.';

  @override
  String get hubTitle => 'Create';

  @override
  String get hubSubtitle => 'Post actions people do in real places.';

  @override
  String get hubPostAction => 'Post an action';

  @override
  String get hubActionsHeading => 'Your actions';

  @override
  String get hubLoading => 'Loading your actions…';

  @override
  String get hubLoadFailedTitle => 'We couldn\'t load your actions';

  @override
  String get hubEmptyTitle => 'Post your first action';

  @override
  String get hubEmptyBody =>
      'Pick a place, choose the proof, and add a reward if you like. People can start as soon as it\'s live.';

  @override
  String get hubStatusDraft => 'Draft';

  @override
  String get hubStatusLive => 'Live';

  @override
  String get hubStatusPaused => 'Paused';

  @override
  String get hubStatusCompleted => 'Completed';

  @override
  String hubVerifiedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verified completions',
      one: '1 verified completion',
      zero: 'No verified completions yet',
    );
    return '$_temp0';
  }

  @override
  String get hubRewardNeedsFunding =>
      'The reward needs funding before this action can go live.';

  @override
  String get hubRewardEnded =>
      'The reward has ended. Anything unclaimed returns to you after the refund delay.';

  @override
  String get hubRewardClosed => 'The reward is closed.';

  @override
  String get hubRewardFunded => 'Your reward is in escrow.';

  @override
  String get hubFund => 'Fund reward';

  @override
  String get hubPublish => 'Publish';

  @override
  String get hubPause => 'Pause';

  @override
  String get hubVenueCode => 'Show venue code';

  @override
  String get hubEdit => 'Edit';

  @override
  String get hubView => 'View as a participant';

  @override
  String hubPublished(String title) {
    return '$title is live.';
  }

  @override
  String hubPaused(String title) {
    return '$title is paused. No one can start it until you publish it again.';
  }

  @override
  String get hubAppsHeading => 'Your Apps';

  @override
  String get hubAppsIntro => 'Let your own software confirm actions for you.';

  @override
  String hubAppsBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Apps confirm actions for you.',
      one: '1 App confirms actions for you.',
      zero: 'Register an App to confirm actions from your own software.',
    );
    return '$_temp0';
  }

  @override
  String get hubAppsOpen => 'Manage Apps';

  @override
  String get hubAppealsHeading => 'Appeals on your actions';

  @override
  String get hubAppealsBody =>
      'When someone contests a rejected proof on one of your actions, you decide here.';

  @override
  String get hubAppealsOpen => 'Open appeals';

  @override
  String get appsTitle => 'Your Apps';

  @override
  String get appsSubtitle => 'Software that confirms actions for you';

  @override
  String get appsLoading => 'Loading your Apps…';

  @override
  String get appsLoadFailedTitle => 'We couldn\'t load your Apps';

  @override
  String get appsListHeading => 'Registered Apps';

  @override
  String get appsEmptyTitle => 'No Apps yet';

  @override
  String get appsEmptyBody => 'Register one above to get its key.';

  @override
  String get appsIntroTitle => 'What\'s a Verily App?';

  @override
  String get appsIntroBody =>
      'An App is your own software, like a booking system or a game, that tells Verily when someone did an action. Participants see that your App confirmed it: Verily takes your App\'s word and doesn\'t check the act itself.';

  @override
  String get appsRegisterHeading => 'Register an App';

  @override
  String get appsNameLabel => 'App name';

  @override
  String get appsNameHint => 'e.g. Sunrise Run Club';

  @override
  String get appsNameRequired => 'Name your App.';

  @override
  String get appsNameTooLong => 'Keep the name to 80 characters or fewer.';

  @override
  String get appsWebsiteLabel => 'Website (optional)';

  @override
  String get appsWebsiteHint => 'https://example.com';

  @override
  String get appsWebsiteInvalid => 'Use a full https:// address.';

  @override
  String get appsRegister => 'Register App';

  @override
  String get appsRegisterFailed =>
      'We couldn\'t register that App. Check you don\'t already have an active App with that name, then try again.';

  @override
  String get appsStatusActive => 'Active';

  @override
  String get appsStatusRevoked => 'Revoked';

  @override
  String appsBoundActions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actions use it',
      one: '1 action uses it',
      zero: 'No actions use it yet',
    );
    return '$_temp0';
  }

  @override
  String appsActiveKeys(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active keys',
      one: '1 active key',
      zero: 'No active keys',
    );
    return '$_temp0';
  }

  @override
  String get appsKeyTitle => 'Save your App key';

  @override
  String appsKeyBody(String appName) {
    return '$appName uses this key to confirm actions. Keep it on your server, never in an app people download.';
  }

  @override
  String get appsKeyWarning =>
      'Verily shows this key only once. If you lose it, make a new key and revoke this one.';

  @override
  String get appsKeyLabel => 'App key';

  @override
  String get appsKeyCopy => 'Copy key';

  @override
  String get appsKeyCopied => 'Copied';

  @override
  String get appsKeySaved => 'I\'ve saved it';

  @override
  String get appsBackToApps => 'Back to your Apps';

  @override
  String get appsRevokedNotice =>
      'This App is revoked. Its keys no longer work and its actions are paused.';

  @override
  String get appsKeysHeading => 'Keys';

  @override
  String get appsNewKey => 'New key';

  @override
  String get appsKeyLimit =>
      'An App can have two working keys. Revoke one to make another.';

  @override
  String appsKeyCreated(String date) {
    return 'Made $date';
  }

  @override
  String appsKeyLastUsed(String date) {
    return 'Last used $date';
  }

  @override
  String get appsKeyNeverUsed => 'Not used yet';

  @override
  String appsKeyRevokedOn(String date) {
    return 'Revoked $date';
  }

  @override
  String appsRevokeKeyTooltip(String key) {
    return 'Revoke $key';
  }

  @override
  String get appsRevokeKeyTitle => 'Revoke this key?';

  @override
  String appsRevokeKeyBody(String key) {
    return 'Requests sent with $key stop working right away. Any other key keeps working.';
  }

  @override
  String get appsRevokeConfirm => 'Revoke';

  @override
  String get appsRevokeApp => 'Revoke this App';

  @override
  String appsRevokeAppTitle(String appName) {
    return 'Revoke $appName?';
  }

  @override
  String get appsRevokeAppBody =>
      'Its keys stop working right away, and every action it confirms is paused. This can\'t be undone.';

  @override
  String get appsGuideHeading => 'Send a confirmation';

  @override
  String get appsGuideBody =>
      'When someone does the action in your App, send this from your server. The subject is the link code the participant copies from the action in Verily.';

  @override
  String get appsGuideResponses =>
      'Verily answers accepted, duplicate, or rejected with a reason. Sending the same eventId again is safe.';

  @override
  String get appsGuideCopy => 'Copy example';

  @override
  String get appsGuideCopied => 'Example copied';

  @override
  String get appsConfirmationsHeading => 'Confirmations';

  @override
  String get appsConfirmationsLoading => 'Loading confirmations…';

  @override
  String get appsConfirmationsFailed => 'We couldn\'t load confirmations';

  @override
  String get appsConfirmationsEmpty =>
      'No confirmations yet. They show up here as your App sends them.';

  @override
  String get appsConfirmationsMore => 'Load older';

  @override
  String get appsConfirmationAccepted => 'Accepted';

  @override
  String get appsConfirmationRejected => 'Rejected';

  @override
  String appsConfirmationEvent(String eventId, String actionKey) {
    return 'Event $eventId for $actionKey';
  }

  @override
  String appsConfirmationReceived(String date) {
    return 'Received $date';
  }

  @override
  String appsConfirmationAttempt(String status) {
    return 'Attempt: $status';
  }

  @override
  String appsConfirmationCode(String code) {
    return 'Response code $code';
  }

  @override
  String get appsReasonConfirmed => 'Counted toward the attempt';

  @override
  String get appsReasonAlreadyComplete => 'Already counted for this period';

  @override
  String get appsReasonUnknownAction => 'No live action has that key';

  @override
  String get appsReasonUnknownSubject => 'No participant has that link code';

  @override
  String get appsReasonOutOfRange => 'The time was too far from now';

  @override
  String get appsReasonOutsideWindow =>
      'It happened outside the action\'s dates';

  @override
  String get appsReasonOutsidePeriod =>
      'It happened outside the current period';

  @override
  String get appsReasonUnavailable =>
      'The action isn\'t taking proof right now';

  @override
  String get appsReasonOther => 'Not counted';

  @override
  String get doTitle => 'Things to do';

  @override
  String get doSubtitle =>
      'Real actions in real places. Prove them on your phone.';

  @override
  String get doViewList => 'List';

  @override
  String get doViewMap => 'Map';

  @override
  String get doFilterAll => 'All';

  @override
  String get doFilterNearby => 'Nearby';

  @override
  String get doFilterPlace => 'Places';

  @override
  String get doFilterMovement => 'Movement';

  @override
  String get doFilterVenueCode => 'Venue codes';

  @override
  String get doFilterApps => 'Apps';

  @override
  String get doProofPlace => 'Be there';

  @override
  String get doProofVenueCode => 'Venue code';

  @override
  String get doProofVideo => 'Video';

  @override
  String get doProofMovement => 'Reps on camera';

  @override
  String get doProofPhoto => 'Photo';

  @override
  String get doProofAudio => 'Audio';

  @override
  String get doProofMotion => 'Phone motion';

  @override
  String get doProofApp => 'App confirms';

  @override
  String doCreatorBy(String name) {
    return 'by $name';
  }

  @override
  String doYourAttempt(String status) {
    return 'You: $status';
  }

  @override
  String doDistanceMeters(int meters) {
    return '$meters m away';
  }

  @override
  String doDistanceKilometers(String km) {
    return '$km km away';
  }

  @override
  String get doLoading => 'Finding actions…';

  @override
  String get doLoadFailedTitle => 'We couldn\'t load actions';

  @override
  String get doEmptyTitle => 'Nothing to do here yet';

  @override
  String get doEmptyBody =>
      'When someone posts an action, it shows up here. You could post the first one.';

  @override
  String get doPostAction => 'Post an action';

  @override
  String get doFilterEmptyTitle => 'Nothing matches that yet';

  @override
  String get doFilterEmptyBody => 'Try another filter, or see everything.';

  @override
  String get doShowAll => 'Show all actions';

  @override
  String get doNearbyEmptyTitle => 'Nothing nearby yet';

  @override
  String get doNearbyEmptyBody =>
      'No live actions have a place near you right now.';

  @override
  String get doNearbyExplainTitle => 'Find actions near you';

  @override
  String get doNearbyExplainBody =>
      'We use your approximate location once to find actions near you. Verily rounds it and never stores it.';

  @override
  String get doNearbyNotNow => 'Not now';

  @override
  String get doNearbyContinue => 'Continue';

  @override
  String get doNearbyUseLocation => 'Use my location';

  @override
  String get doNearbyLocating => 'Finding where you are…';

  @override
  String get doNearbyDeclinedTitle => 'Nearby needs your location';

  @override
  String get doNearbyDeclinedBody =>
      'Share your approximate location to see actions close to you. Everything else works without it.';

  @override
  String get doNearbyBlockedTitle => 'Location is off for Verily';

  @override
  String get doNearbyBlockedBody =>
      'Turn location on for Verily in your phone\'s settings to see nearby actions.';

  @override
  String get doOpenSettings => 'Open settings';

  @override
  String get doNearbyServicesOffTitle => 'Location services are off';

  @override
  String get doNearbyServicesOffBody =>
      'Turn on location services, then try again.';

  @override
  String get doNearbyDeniedTitle => 'Location wasn\'t allowed';

  @override
  String get doNearbyDeniedBody =>
      'Allow location when your phone asks to see actions near you.';

  @override
  String get doNearbyTimedOutTitle => 'We couldn\'t find you';

  @override
  String get doNearbyTimedOutBody =>
      'Your phone didn\'t share a location in time. Try again, ideally near a window.';

  @override
  String get doMapEmptyTitle => 'No places to show';

  @override
  String get doMapEmptyBody =>
      'None of these actions has a place on the map. Switch to the list to see them.';

  @override
  String get doMapLabel => 'Map of actions with a place';

  @override
  String actionPlaceMapLabel(String place) {
    return 'Map of $place';
  }

  @override
  String actionPlaceRadiusLabel(int meters) {
    return 'The $meters m area around the pin';
  }

  @override
  String actionPlaceRadius(int meters) {
    return 'Be within $meters m of the pin';
  }

  @override
  String get actionScanTitle => 'Scan the venue code';

  @override
  String get actionScanHint =>
      'Point the camera at the code the venue shows. It changes every few minutes.';

  @override
  String get actionScanCameraDenied =>
      'Verily needs the camera to read the venue code. Allow it in your phone\'s settings.';

  @override
  String get actionScanUnavailable =>
      'The camera isn\'t available right now. Try again in a moment.';

  @override
  String actionProofReps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reps',
      one: '1 rep',
    );
    return '$_temp0';
  }

  @override
  String get actionProofOptional => 'Optional';

  @override
  String get actionProofStateOpen => 'Not done yet';

  @override
  String get actionProofStateWorking => 'Sending';

  @override
  String get actionProofStateAccepted => 'Done';

  @override
  String get actionVerifiedTitle => 'Verified';

  @override
  String get actionVerifiedBody => 'Verily checked your proof and it passed.';

  @override
  String get actionAddWallet => 'Add a wallet';

  @override
  String get actionPayoutHeldBody =>
      'Bigger rewards get a quick look from a person before they\'re sent.';

  @override
  String get actionAppUnnamed => 'the App';

  @override
  String actionAppConfirmed(String appName) {
    return '$appName confirmed this';
  }

  @override
  String actionAppBody(String appName) {
    return '$appName confirms this step itself. Give it your link code so it knows it\'s you. Verily doesn\'t check the act, only that $appName said so.';
  }

  @override
  String actionAppUnavailable(String appName) {
    return '$appName isn\'t confirming actions any more, so this one can\'t be done right now.';
  }

  @override
  String get actionLinkCodeShow => 'Show my link code';

  @override
  String actionLinkCodeTitle(String appName) {
    return 'Your code for $appName';
  }

  @override
  String actionLinkCodeBody(String appName) {
    return 'Paste this into $appName so it can confirm you.';
  }

  @override
  String get actionLinkCodeCopy => 'Copy code';

  @override
  String get actionLinkCodeCopied => 'Copied';

  @override
  String actionLinkCodePrivacy(String appName) {
    return 'Each App gets a different code, so Apps can\'t compare notes about you. $appName never sees your account.';
  }

  @override
  String get actionRejectedBody => 'This proof wasn\'t accepted.';

  @override
  String get actionAppealInvite =>
      'Think this was a mistake? You can ask for a second look once. A person reads it.';

  @override
  String get actionAppealOpen => 'Ask for a second look';

  @override
  String get actionAppealTitle => 'Ask for a second look';

  @override
  String get actionAppealBody =>
      'Tell the action\'s creator what happened. Be specific; you can do this once.';

  @override
  String get actionAppealReasonLabel => 'What happened?';

  @override
  String get actionAppealReasonHint => 'At least 10 characters';

  @override
  String get actionAppealSubmit => 'Send';

  @override
  String get actionAppealPending =>
      'You asked for a second look. A person will read it.';

  @override
  String get actionAppealAccepted => 'Your appeal was accepted.';

  @override
  String get actionAppealRejected =>
      'Your appeal was read and the decision stands.';

  @override
  String get actionLoading => 'Opening the action…';

  @override
  String get actionLoadFailedTitle => 'We couldn\'t open this action';

  @override
  String get actionNotFoundTitle => 'This action isn\'t here';

  @override
  String get actionBack => 'Back';

  @override
  String get actionIntegrityUnavailable =>
      'This phone couldn\'t vouch for the capture. Check your phone is up to date, then try again.';

  @override
  String get actionSignatureUnavailable =>
      'This phone couldn\'t sign the capture. Try again; if it keeps happening, this phone can\'t be used for this action.';

  @override
  String get actionUploadFailed =>
      'Your proof didn\'t finish uploading. It\'s still on your phone; try again.';

  @override
  String get actionNotLiveTitle => 'This action isn\'t live';

  @override
  String get actionNotLiveBody =>
      'It\'s paused, finished, or not published yet, so it can\'t be started.';

  @override
  String get actionProofHeading => 'What you\'ll prove';

  @override
  String get actionYourProof => 'Your proof';

  @override
  String get actionProofIntro =>
      'Every step is captured live on your phone when you do it. There\'s no upload button.';

  @override
  String get actionProofTapHint => 'Tap a step to do it.';

  @override
  String get actionStart => 'Start';

  @override
  String get actionFinish => 'Finish';

  @override
  String get actionFinishing => 'Wrapping up…';

  @override
  String get actionCheckingBody =>
      'This usually takes a minute or two. You can leave this page; Verily keeps checking and updates your attempt.';

  @override
  String get actionReviewBody =>
      'A person will look at your proof. You\'ll see the result here and in Me.';

  @override
  String get actionReviewValueBody =>
      'Bigger rewards get a quick look from a person. You\'ll see the result here and in Me.';

  @override
  String get actionCapacityBody =>
      'Everyone this action could take has already finished it.';

  @override
  String get actionProofAccepted => 'Got it. That step is done.';

  @override
  String get actionProofWithReviewer => 'A person will check that step.';

  @override
  String get actionProofNotAccepted => 'That proof wasn\'t accepted.';

  @override
  String get actionProofSent => 'Sent. Verily is checking it now.';

  @override
  String get actionLocationServicesOff =>
      'Turn on location services so Verily can check you\'re at the place.';

  @override
  String get actionLocationDenied =>
      'Verily needs your location for this step. Allow it when asked and try again.';

  @override
  String get actionLocationBlocked =>
      'Location is off for Verily. Turn it on in Settings to do this step.';

  @override
  String get actionLocationTimedOut =>
      'We couldn\'t get a precise location. Step outside or near a window and try again.';

  @override
  String get actionRewardCapReached =>
      'You\'ve earned the most this action allows';

  @override
  String actionRewardPerPerson(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Up to $count per person',
      one: 'One reward per person',
    );
    return '$_temp0';
  }

  @override
  String get actionCreatorTitle => 'This is your action';

  @override
  String get actionCreatorDraft => 'It\'s a draft, so nobody can see it yet.';

  @override
  String get actionCreatorLive => 'It\'s live. This is what people see.';

  @override
  String get actionCreatorPaused => 'It\'s paused, so nobody can start it.';

  @override
  String get actionCreatorCompleted => 'It\'s finished.';

  @override
  String get actionCreatorEdit => 'Edit';

  @override
  String get actionCreatorShowVenueCode => 'Show venue code';

  @override
  String actionCreatorShowVenueCodeFor(String title) {
    return 'Show code for $title';
  }

  @override
  String captureReviewTooLong(String limit) {
    return 'This recording runs past the $limit limit. Retake a shorter one.';
  }

  @override
  String get captureMotionSending => 'Sending your motion…';

  @override
  String get movementNameSquats => 'Squats';

  @override
  String movementTargetSquats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count squats',
      one: '1 squat',
    );
    return '$_temp0';
  }

  @override
  String get movementGuideSquats =>
      'Side view · keep your hips, knees and ankles in frame';

  @override
  String get movementCueSquats => 'Bend your knees';

  @override
  String get movementNamePressUps => 'Press-ups';

  @override
  String movementTargetPressUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count press-ups',
      one: '1 press-up',
    );
    return '$_temp0';
  }

  @override
  String get movementGuidePressUps =>
      'Side view · set the phone low, near the floor';

  @override
  String get movementCuePressUps => 'Lower your chest';

  @override
  String get movementNameSitUps => 'Sit-ups';

  @override
  String movementTargetSitUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sit-ups',
      one: '1 sit-up',
    );
    return '$_temp0';
  }

  @override
  String get movementGuideSitUps =>
      'Side view · set the phone low and lie with knees bent';

  @override
  String get movementCueSitUps => 'Lift your torso';

  @override
  String get movementNameLunges => 'Lunges';

  @override
  String movementTargetLunges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lunges',
      one: '1 lunge',
    );
    return '$_temp0';
  }

  @override
  String get movementGuideLunges =>
      'Side view · step back so both legs are in frame';

  @override
  String get movementCueLunges => 'Lower your back knee';

  @override
  String get movementNameStarJumps => 'Star jumps';

  @override
  String movementTargetStarJumps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count star jumps',
      one: '1 star jump',
    );
    return '$_temp0';
  }

  @override
  String get movementGuideStarJumps =>
      'Front view · leave room above and beside you';

  @override
  String get movementCueStarJumps => 'Jump wide, arms up';

  @override
  String get movementNameBurpees => 'Burpees';

  @override
  String movementTargetBurpees(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count burpees',
      one: '1 burpee',
    );
    return '$_temp0';
  }

  @override
  String get movementGuideBurpees =>
      'Side view · keep your whole body and the floor in frame';

  @override
  String get movementCueBurpees => 'Crouch down';

  @override
  String get movementNameHighKnees => 'High knees';

  @override
  String movementTargetHighKnees(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count high knees',
      one: '1 high knee',
    );
    return '$_temp0';
  }

  @override
  String get movementGuideHighKnees =>
      'Side view · stand tall and keep both legs in frame';

  @override
  String get movementCueHighKnees => 'Knee up to hip height';

  @override
  String get movementNameLateralRaises => 'Lateral raises';

  @override
  String movementTargetLateralRaises(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lateral raises',
      one: '1 lateral raise',
    );
    return '$_temp0';
  }

  @override
  String get movementGuideLateralRaises =>
      'Front view · keep your whole arm span in frame';

  @override
  String get movementCueLateralRaises => 'Raise both arms';

  @override
  String get movementNameBicepsCurls => 'Biceps curls';

  @override
  String movementTargetBicepsCurls(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count biceps curls',
      one: '1 biceps curl',
    );
    return '$_temp0';
  }

  @override
  String get movementGuideBicepsCurls =>
      'Front view · keep shoulders, elbows and wrists in frame';

  @override
  String get movementCueBicepsCurls => 'Curl your hands up';

  @override
  String get movementNameSideBends => 'Side bends';

  @override
  String movementTargetSideBends(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count side bends',
      one: '1 side bend',
    );
    return '$_temp0';
  }

  @override
  String get movementGuideSideBends => 'Front view · keep your hips still';

  @override
  String get movementCueSideBends => 'Lean to one side';

  @override
  String get movementNameFootballKickUps => 'Football kick-ups';

  @override
  String movementTargetFootballKickUps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kick-ups',
      one: '1 kick-up',
    );
    return '$_temp0';
  }

  @override
  String get movementGuideFootballKickUps =>
      'Step back so your whole body and the ball stay in frame';

  @override
  String get movementCueFootballKickUps => 'Keep the ball up';

  @override
  String get movementNameTableTennisBounces => 'Table tennis bounces';

  @override
  String movementTargetTableTennisBounces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bat bounces',
      one: '1 bat bounce',
    );
    return '$_temp0';
  }

  @override
  String get movementGuideTableTennisBounces =>
      'Keep the bat, the ball and your upper body in frame';

  @override
  String get movementCueTableTennisBounces => 'Keep the ball up';

  @override
  String get movementCueStepIntoFrame => 'Step into frame';

  @override
  String get movementCueGetIntoPosition => 'Get into your starting position';

  @override
  String get movementCueReturnToStart => 'Back to the start to count it';

  @override
  String get movementCueCrouch => 'Crouch down';

  @override
  String get movementCuePlank => 'Kick back to a plank';

  @override
  String get movementCueFeetForward => 'Bring your feet back in';

  @override
  String get movementCueJump => 'Jump!';

  @override
  String get movementCueLand => 'Land on your feet';

  @override
  String get movementCaptureTitle => 'Movement challenge';

  @override
  String get movementCaptureClose => 'Close the camera';

  @override
  String get movementCaptureFlip => 'Switch camera';

  @override
  String get movementCaptureOpening => 'Starting the camera…';

  @override
  String get movementCaptureCoachLoading => 'Getting your live counter ready…';

  @override
  String get movementCaptureCoachUnavailable =>
      'Live counting isn\'t available here. Record your set and it will be checked after you submit.';

  @override
  String get movementCaptureAdvisory =>
      'The live count helps you pace yourself. Your recording is what gets checked after you submit.';

  @override
  String get movementCaptureStart => 'Start recording';

  @override
  String get movementCaptureStop => 'Stop recording';

  @override
  String get movementCaptureKeepGoing => 'Keep recording';

  @override
  String get movementCaptureSaving => 'Saving your recording…';

  @override
  String get movementCaptureTargetReached => 'Target reached!';

  @override
  String get movementCaptureStepBack => 'Step back into frame';

  @override
  String movementCaptureCountdown(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString';
  }

  @override
  String movementCaptureCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString';
  }

  @override
  String movementCaptureRemaining(int count, int target) {
    final intl.NumberFormat targetNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String targetString = targetNumberFormat.format(target);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'of $targetString · $count to go',
      one: 'of $targetString · 1 to go',
      zero: 'Target reached',
    );
    return '$_temp0';
  }

  @override
  String movementCaptureCountSemantics(int count, int target) {
    return '$count of $target counted';
  }

  @override
  String movementCaptureElapsed(String elapsed, String limit) {
    return '$elapsed of $limit';
  }

  @override
  String movementCaptureDepthSemantics(int percent) {
    return 'Movement depth $percent%';
  }

  @override
  String get movementCapturePermissionDenied => 'Camera access is off';

  @override
  String get movementCapturePermissionDeniedBody =>
      'Allow camera access for Verily in your phone\'s settings, then try again. Proof can only be captured live.';

  @override
  String get movementCaptureNoCamera => 'No camera found';

  @override
  String get movementCaptureNoCameraBody =>
      'This device doesn\'t have a camera Verily can use.';

  @override
  String get movementCaptureUnavailable => 'The camera couldn\'t start';

  @override
  String get movementCaptureUnavailableBody =>
      'Close any other app using the camera, then try again.';

  @override
  String get movementCaptureRecordingFailed =>
      'The recording couldn\'t be saved';

  @override
  String get movementCaptureRecordingFailedBody =>
      'Nothing was submitted. Try recording again.';

  @override
  String get movementCaptureInterrupted =>
      'Recording stopped when you left the app. Start again when you\'re ready.';

  @override
  String get movementCaptureTryAgain => 'Try again';

  @override
  String get movementCueShowBall => 'Show the ball to the camera';

  @override
  String get movementCueDropped => 'Dropped! Go again';

  @override
  String movementCaptureBest(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Best run: $countString';
  }

  @override
  String get captureMotionTitle => 'Capture device motion';

  @override
  String get captureMotionReady => 'Find a clear space';

  @override
  String get captureMotionReadyBody =>
      'Hold your phone securely. Verily starts after a three-second countdown and records only the short motion trace needed for this action.';

  @override
  String get captureMotionBegin => 'Start countdown';

  @override
  String captureMotionCountdown(int count) {
    return 'Starting in $count';
  }

  @override
  String get captureMotionCountdownBody =>
      'Get into position and keep a secure grip.';

  @override
  String captureMotionCountdownNumber(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString';
  }

  @override
  String get captureMotionRecording => 'Motion capture in progress';

  @override
  String captureMotionProgress(int percent) {
    return '$percent% of the capture complete';
  }

  @override
  String get captureMotionMatched => 'Movement matched';

  @override
  String captureMotionMatchedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count complete movements',
      one: 'one complete movement',
      zero: 'the required movement',
    );
    return 'Verily detected $_temp0. It will be checked again after you submit.';
  }

  @override
  String get captureMotionNotMatched => 'Not quite';

  @override
  String get captureMotionRetry => 'Capture again';

  @override
  String get captureMotionUseProof => 'Use this motion proof';

  @override
  String get captureMotionPrivacy =>
      'Only a short sensor trace is collected. Motion capture does not record video, audio, or continuous location.';

  @override
  String get captureMotionNoSensor => 'Motion sensors unavailable';

  @override
  String get captureMotionNoSensorBody =>
      'Verily couldn’t read this device’s motion sensors. Check motion access in your device settings, then try again.';

  @override
  String get captureMotionUnavailable => 'This motion action is unavailable';

  @override
  String get captureMotionUnavailableBody =>
      'Its movement settings are incomplete, so Verily will not guess what counts. Ask the creator to update the action.';

  @override
  String get captureMotionInterrupted => 'Capture interrupted';

  @override
  String get captureMotionInterruptedBody =>
      'Motion recording stopped early. Keep Verily open and try again.';

  @override
  String get captureMotionTossSafetyTitle => 'Protect yourself and your phone';

  @override
  String get captureMotionTossSafetyBody =>
      'Use both hands over a soft, clear surface. Keep the toss below eye level. Do not attempt this near people, traffic, water, edges, or hard ground.';

  @override
  String get captureMotionFailureTooFast =>
      'That rotation exceeded the safe speed set for this action. Slow down and keep control of the phone.';

  @override
  String get captureMotionFailureWrongAxis =>
      'The phone turned the wrong way. Follow the direction shown above and try again.';

  @override
  String get captureMotionFailureTooSlow =>
      'The rotation was too small or too slow to count clearly. Make deliberate, complete turns.';

  @override
  String get captureMotionFailureCount =>
      'Verily did not detect enough complete movements. Reset your grip and try the full count again.';

  @override
  String get captureMotionFailureImpact =>
      'The movement was too forceful for this action. Stop if the phone or your surroundings could be damaged.';

  @override
  String get captureMotionFailureAirTime =>
      'We didn’t detect a low, controlled toss. Toss gently, just above your hands, and try again.';

  @override
  String get captureMotionFailureToss =>
      'We couldn’t detect a full toss and catch. Try one gentle toss and catch it with both hands.';

  @override
  String get captureMotionFailureStillness =>
      'The phone moved more than this action allows. Rest your arms and try holding it steady again.';

  @override
  String get captureMotionFailureDuration =>
      'The capture was too short or too long for this action. Try again.';

  @override
  String get captureMotionFailureGeneric =>
      'The movement didn’t match the action. Check the target and try again.';

  @override
  String get captureMotionTargetLabel => 'Motion target';

  @override
  String get captureMotionTargetToss =>
      'One low, controlled toss and two-handed catch';

  @override
  String captureMotionTargetRotation(int count, String axis) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count complete $axis rotations',
      one: '1 complete $axis rotation',
    );
    return '$_temp0';
  }

  @override
  String captureMotionTargetShake(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count controlled back-and-forth shakes',
      one: '1 controlled back-and-forth shake',
    );
    return '$_temp0';
  }

  @override
  String captureMotionTargetStillness(int seconds) {
    return 'Hold the phone steady for $seconds seconds';
  }

  @override
  String get captureMotionTargetUnavailable =>
      'The creator needs to finish the motion settings';

  @override
  String get captureMotionTypePhoneToss => 'Gentle phone toss';

  @override
  String get captureMotionTypeRotation => 'Counted rotation';

  @override
  String get captureMotionTypeShake => 'Controlled shake';

  @override
  String get captureMotionTypeStillness => 'Hold still';

  @override
  String get captureMotionAxisYaw => 'steering-wheel';

  @override
  String get captureMotionAxisPitch => 'forward-flip';

  @override
  String get captureMotionAxisRoll => 'sideways';

  @override
  String get captureMotionAxisAny => 'any axis';

  @override
  String captureReviewDeviceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Your phone counted $count repetitions. The recording is checked after you submit.',
      one: 'Your phone counted 1 repetition. The recording is checked after you submit.',
      zero: 'Your phone didn\'t count any repetitions. The recording is still checked after you submit.',
    );
    return '$_temp0';
  }

  @override
  String movementPreviewResult(int count, String version) {
    return 'Counted $count · $version';
  }

  @override
  String get captureClose => 'Close without sending';

  @override
  String get captureFlipCamera => 'Switch camera';

  @override
  String get captureLive => 'Live';

  @override
  String get captureChallengeLoading => 'Getting your word…';

  @override
  String get captureChallengeIntro => 'When you record, say this word clearly';

  @override
  String captureChallengeSay(String word) {
    return 'Say “$word”';
  }

  @override
  String captureChallengeSemantics(String word) {
    return 'Say the word $word while you record';
  }

  @override
  String get captureChallengeFailedTitle => 'We couldn\'t get your word';

  @override
  String get captureChallengeFailedBody =>
      'Each recording needs a fresh word from Verily so it is clearly live. Check your connection and try again.';

  @override
  String get captureWindowLoading => 'Getting ready to capture…';

  @override
  String get captureWindowFailedTitle => 'We couldn\'t start the capture';

  @override
  String get captureWindowFailedBody =>
      'Verily starts a fresh, live capture for each proof. Check your connection and try again.';

  @override
  String get captureRecordStart => 'Start recording';

  @override
  String get captureRecordStop => 'Stop recording';

  @override
  String get captureTakePhoto => 'Take photo';

  @override
  String captureElapsed(String elapsed, String limit) {
    return '$elapsed of $limit';
  }

  @override
  String captureMinimumHint(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Record at least $seconds seconds',
      one: 'Record at least 1 second',
    );
    return '$_temp0';
  }

  @override
  String captureLimitReached(String limit) {
    return 'Stopped at the $limit limit';
  }

  @override
  String get captureCameraPermissionTitle => 'Camera access is off';

  @override
  String get captureCameraPermissionBody =>
      'Allow camera access for Verily in your phone\'s settings. Proof can only be captured live, here in the app.';

  @override
  String get captureMicrophonePermissionTitle => 'Microphone access is off';

  @override
  String get captureMicrophonePermissionBody =>
      'Allow microphone access for Verily in your phone\'s settings. Your recording needs sound for this action.';

  @override
  String get captureOpenSettings => 'Open settings';

  @override
  String get captureAudioTitle => 'Record audio';

  @override
  String get captureAudioHint => 'Hold your phone close and speak clearly.';

  @override
  String get captureAudioSoundHint => 'Hold your phone close to the sound.';

  @override
  String captureAudioLevelSemantics(int percent) {
    return 'Sound level $percent%';
  }

  @override
  String get captureAudioRecording => 'Recording';

  @override
  String get captureReviewTitle => 'Check your proof';

  @override
  String get captureReviewPhotoBody =>
      'Make sure the photo shows the action clearly.';

  @override
  String get captureReviewRecordingBody =>
      'Play it back and make sure the action is clear.';

  @override
  String captureReviewWordCheck(String word) {
    return 'Did you say “$word”? It needs to be heard in the recording.';
  }

  @override
  String captureReviewDuration(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds seconds recorded',
      one: '1 second recorded',
    );
    return '$_temp0';
  }

  @override
  String get captureReviewRetake => 'Retake';

  @override
  String get captureReviewSend => 'Send proof';

  @override
  String get captureReviewPrivacy =>
      'Your proof stays private: only Verily\'s checks and the people reviewing this action see it.';

  @override
  String get captureReviewPlay => 'Play';

  @override
  String get captureReviewPause => 'Pause';

  @override
  String get captureReviewPreviewUnavailable =>
      'This preview can\'t play here. You can still send it.';

  @override
  String get captureSending => 'Sending your proof…';

  @override
  String get captureSendFailedTitle => 'Your proof didn\'t send';

  @override
  String get captureSendFailedBody =>
      'It is still on this phone. Check your connection and send it again.';

  @override
  String get captureSendAgain => 'Send again';

  @override
  String get captureIntegrityTitle =>
      'This phone couldn\'t vouch for the capture';

  @override
  String get captureIntegrityBody =>
      'This action needs proof from a phone that can confirm it captured it live. Try again, or use another phone.';

  @override
  String get captureUnsupportedFormatTitle =>
      'This action can\'t take what this phone recorded';

  @override
  String get captureUnsupportedFormatBody =>
      'Nothing was sent. Try again; if it keeps happening, this action may not work on this phone.';

  @override
  String get captureTooLargeTitle => 'That capture is too large';

  @override
  String get captureTooLargeBody =>
      'Nothing was sent. Record a shorter clip and try again.';

  @override
  String get captureProblemTitle => 'That didn\'t work';

  @override
  String appealsRequirement(String requirement, String kind) {
    return '$requirement · $kind';
  }

  @override
  String get welcomeTitle => 'Do it. Prove it. Get paid.';

  @override
  String get welcomeBody =>
      'Real actions in real places. Your phone captures the proof as it happens, Verily checks it, and the reward is already waiting.';

  @override
  String get welcomePromiseHeading => 'Every action is a small promise';

  @override
  String get welcomePromisePlaceTitle => 'A place';

  @override
  String get welcomePromisePlaceBody =>
      'A pin on a map or a code at the venue. Being there is part of it.';

  @override
  String get welcomePromiseProofTitle => 'Proof, captured live';

  @override
  String get welcomePromiseProofBody =>
      'Video, a photo, sound, or motion, recorded in the app. There\'s no upload button.';

  @override
  String get welcomePromiseRewardTitle => 'A reward, locked first';

  @override
  String get welcomePromiseRewardBody =>
      'Rewards sit in escrow before anyone starts, so nobody works for a promise.';

  @override
  String get welcomeGetStarted => 'Get started';

  @override
  String get welcomeHaveAccount => 'I already have an account';

  @override
  String get signInTitle => 'Sign in to Verily';

  @override
  String get signInTitleDoAction => 'Sign in to do this action';

  @override
  String get signInTitleCreateAction => 'Sign in to post an action';

  @override
  String get signInTitlePrivateHistory =>
      'Sign in to see your proof and payouts';

  @override
  String get signInTitleManageApps => 'Sign in to manage your Verily Apps';

  @override
  String get signInSubtitle =>
      'Your proof stays private to you and the people who check it.';

  @override
  String get signInEmailTitle => 'Sign in with email';

  @override
  String get signInEmailSignUpTitle => 'Sign up with email';

  @override
  String get signInVerificationPrompt =>
      'Enter the 8-digit code we emailed you.';

  @override
  String signInPasswordMinLength(String length) {
    return '$length+ characters';
  }

  @override
  String signInPasswordMaxLength(String length) {
    return 'Up to $length characters';
  }

  @override
  String get signInPasswordLowercase => 'One lowercase letter';

  @override
  String get signInPasswordUppercase => 'One uppercase letter';

  @override
  String get signInPasswordNumber => 'One number';

  @override
  String get signInPasswordSymbol => 'One symbol';

  @override
  String get signInFailed => 'We couldn\'t sign you in. Try again.';

  @override
  String get signInUnavailable => 'Sign-in isn\'t available in this build.';

  @override
  String get signInIntentKept =>
      'Your place is saved. Sign in when you\'re ready and we\'ll bring you back.';

  @override
  String get signInNotNow => 'Not now';

  @override
  String get signInHaveAccountPrompt => 'Have an account?';

  @override
  String get signInNewHerePrompt => 'New here?';

  @override
  String get meTitle => 'Your proof and payouts';

  @override
  String get meSubtitle => 'Attempts, rewards, and where they go';

  @override
  String get meWalletTitle => 'Payout wallet';

  @override
  String get meWalletLinkedBody => 'Rewards you earn are sent to this wallet.';

  @override
  String meWalletAddressLabel(String address) {
    return 'Wallet address $address';
  }

  @override
  String get meWalletCopy => 'Copy wallet address';

  @override
  String get meWalletCopied => 'Wallet address copied';

  @override
  String get meWalletChange => 'Use a different wallet';

  @override
  String get meWalletUnlinkedTitle => 'Link a wallet to get paid';

  @override
  String get meWalletUnlinkedBody =>
      'Rewards are paid in USDC on Solana. Link your wallet once, and anything waiting for you is sent as soon as it\'s linked.';

  @override
  String get meWalletLink => 'Link a wallet';

  @override
  String get meWalletLinking => 'Waiting for your wallet…';

  @override
  String get meWalletUnsupported =>
      'Linking a wallet needs Verily on Android with a Solana wallet app installed.';

  @override
  String get meWalletLinked => 'Wallet linked. Payouts go there now.';

  @override
  String get meWalletFailureUnavailable =>
      'No Solana wallet app answered. Install one, then try again.';

  @override
  String get meWalletFailureCancelled =>
      'Linking was cancelled in your wallet.';

  @override
  String get meWalletFailureTimedOut =>
      'Your wallet didn\'t answer in time. Try again.';

  @override
  String get meWalletFailureWrongAccount =>
      'Your wallet offered a different account. Choose the one you want paid, then try again.';

  @override
  String get meWalletFailureInvalidResponse =>
      'Your wallet sent back something we couldn\'t use. Try again.';

  @override
  String get meWalletFailureFailed =>
      'We couldn\'t link your wallet. Try again.';

  @override
  String get mePayoutsTitle => 'Payouts';

  @override
  String get mePayoutsEmpty =>
      'Nothing paid yet. Rewards you earn show up here.';

  @override
  String mePayoutPayableUntil(String date) {
    return 'Link a wallet by $date to receive it.';
  }

  @override
  String get meAttemptsTitle => 'Your attempts';

  @override
  String get meAttemptsEmpty =>
      'You haven\'t tried an action yet. Find one in Do.';

  @override
  String get meAttemptUnknownAction => 'An action you tried';

  @override
  String meAttemptStarted(String date) {
    return 'Started $date';
  }

  @override
  String get meAppeal => 'Appeal';

  @override
  String get meAppealTitle => 'Appeal this decision';

  @override
  String get meAppealBody =>
      'Tell the action\'s creator what your proof shows. You can appeal once.';

  @override
  String get meAppealReasonLabel => 'What should they know?';

  @override
  String get meAppealReasonHint =>
      'For example: all ten squats are in the second half of the video.';

  @override
  String get meAppealReasonHelper => 'At least 10 characters.';

  @override
  String get meAppealSend => 'Send appeal';

  @override
  String get meAppealSent => 'Appeal sent.';

  @override
  String get meAppealPending => 'Appeal sent · waiting for the creator';

  @override
  String get meAppealAccepted => 'Appeal accepted';

  @override
  String get meAppealRejected => 'Appeal not accepted';

  @override
  String get meLoadFailedTitle => 'We couldn\'t load this';

  @override
  String get meLoadingAttempts => 'Loading your attempts…';

  @override
  String get meLoadingPayouts => 'Loading your payouts…';

  @override
  String get meLinkReview => 'Review proof';

  @override
  String get meLinkAppeals => 'Appeals on your actions';

  @override
  String get settingsSubtitle => 'How Verily looks, and your account';

  @override
  String get settingsAccountTitle => 'Your account';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsSigningOut => 'Signing out…';

  @override
  String get settingsSignOutSubtitle =>
      'You can sign back in any time. Nothing you\'ve done is lost.';

  @override
  String get settingsSignOutDialogTitle => 'Sign out of Verily?';

  @override
  String get settingsSignOutDialogBody =>
      'You\'ll need to sign in again to do actions or see your payouts.';

  @override
  String get settingsSignOutFailed => 'We couldn\'t sign you out. Try again.';

  @override
  String get settingsCloseAccount => 'Close account';

  @override
  String get settingsCloseAccountSubtitle =>
      'Remove your sign-in details and end every session.';

  @override
  String get settingsCloseAccountDialogTitle => 'Close your account?';

  @override
  String get settingsCloseAccountDialogBody =>
      'Your sign-in details are removed, every session ends, and your live actions are paused. Rewards already sent stay in the wallets they went to.';

  @override
  String get settingsCloseAccountConfirmationLabel => 'Type DELETE to confirm';

  @override
  String get settingsCloseAccountConfirm => 'Close account';

  @override
  String get settingsClosingAccount => 'Closing account…';

  @override
  String get settingsCloseAccountFailed =>
      'We couldn\'t close your account. Try again.';

  @override
  String get reviewTitle => 'Proof to review';

  @override
  String get reviewNotReviewerTitle => 'Reviewing is for Verily\'s reviewers';

  @override
  String get reviewNotReviewerBody =>
      'People with review access decide proof that needs a person. Your own proof is in Me.';

  @override
  String get reviewLoading => 'Loading proof to review…';

  @override
  String get reviewEmptyTitle => 'Nothing to review';

  @override
  String get reviewEmptyBody => 'Proof that needs a person shows up here.';

  @override
  String get reviewLoadFailedTitle => 'We couldn\'t load the queue';

  @override
  String reviewContext(String creator, String requirement) {
    return '$creator · $requirement';
  }

  @override
  String get reviewKindVideo => 'Video proof';

  @override
  String get reviewKindPhoto => 'Photo proof';

  @override
  String get reviewKindAudio => 'Audio proof';

  @override
  String get reviewKindLocation => 'Location proof';

  @override
  String get reviewKindQrCode => 'Venue code proof';

  @override
  String get reviewKindMotion => 'Motion proof';

  @override
  String get reviewKindExternalApp => 'App confirmation';

  @override
  String reviewKindWithDuration(String kind, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds seconds',
      one: '1 second',
    );
    return '$kind · $_temp0';
  }

  @override
  String reviewTimes(String captured, String submitted) {
    return 'Captured $captured · sent $submitted';
  }

  @override
  String reviewListenFor(String word) {
    return 'Listen for “$word”';
  }

  @override
  String reviewPayout(String amount, String threshold) {
    return 'Pays $amount, above the $threshold review threshold';
  }

  @override
  String get reviewMediaExpires =>
      'Private link. It expires five minutes after loading.';

  @override
  String get reviewMediaReload => 'Reload proof';

  @override
  String get reviewMediaUnavailable =>
      'This proof can\'t play here. Reload to get a fresh link.';

  @override
  String get reviewMediaLoading => 'Loading proof…';

  @override
  String get reviewPlay => 'Play';

  @override
  String get reviewPause => 'Pause';

  @override
  String get reviewPlaybackPosition => 'Playback position';

  @override
  String reviewPhotoLabel(String action) {
    return 'Photo proof for $action';
  }

  @override
  String get reviewAccept => 'Accept';

  @override
  String get reviewReject => 'Reject';

  @override
  String get reviewAcceptTitle => 'Accept this proof?';

  @override
  String get reviewRejectTitle => 'Reject this proof?';

  @override
  String get reviewNoteLabel => 'Note for the record';

  @override
  String get reviewNoteHint => 'What you saw, in a sentence.';

  @override
  String get reviewSaved => 'Decision saved.';

  @override
  String get reviewSaveFailed => 'We couldn\'t save that decision. Try again.';

  @override
  String get appealsTitle => 'Appeals on your actions';

  @override
  String get appealsLoading => 'Loading appeals…';

  @override
  String get appealsEmptyTitle => 'No appeals';

  @override
  String get appealsEmptyBody =>
      'When someone contests a rejection on one of your actions, it shows up here.';

  @override
  String get appealsLoadFailedTitle => 'We couldn\'t load appeals';

  @override
  String get appealsReasonHeading => 'Their words';

  @override
  String get appealsStatusPending => 'Waiting for you';

  @override
  String get appealsStatusAccepted => 'You accepted this appeal';

  @override
  String get appealsStatusRejected => 'You turned this appeal down';

  @override
  String get appealsAccept => 'Accept';

  @override
  String get appealsReject => 'Reject';

  @override
  String get appealsAcceptTitle => 'Accept this appeal?';

  @override
  String get appealsAcceptBody => 'Accepting counts the proof as verified.';

  @override
  String get appealsRejectTitle => 'Reject this appeal?';

  @override
  String get appealsRejectBody => 'Rejecting keeps the original decision.';

  @override
  String get appealsNoteLabel => 'Your answer';

  @override
  String get appealsNoteHint => 'Why, in a sentence. They\'ll see this.';

  @override
  String get appealsSaved => 'Appeal decided.';

  @override
  String get appealsSaveFailed => 'We couldn\'t save that. Try again.';

  @override
  String get appTitle => 'Verily';

  @override
  String get appTagline => 'Do it, prove it, get paid.';

  @override
  String get skribblePreviewBodySample =>
      'Real actions in real places, proof captured live on your phone, and rewards locked away before anyone starts. The first actions are on their way.';

  @override
  String get dialogCancel => 'Cancel';

  @override
  String get dialogDone => 'Done';

  @override
  String get dialogRetry => 'Try again';

  @override
  String get dialogClose => 'Close';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsOpenTooltip => 'Open settings';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceSubtitle =>
      'Paper by day, night after dark, or one of them all the time.';

  @override
  String get appearanceSystem => 'Match device';

  @override
  String get appearanceSystemSubtitle =>
      'Follows your phone or browser automatically.';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceLightSubtitle => 'Always warm paper and plum ink.';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get appearanceDarkSubtitle => 'Always deep night with paper ink.';

  @override
  String get developerMenuTitle => 'Development menu';

  @override
  String get developerCloseMenu => 'Close development menu';

  @override
  String get developerClose => 'Close';

  @override
  String get developerIconTooltip => 'Open developer tools';

  @override
  String get developerIconShow => 'Show developer icon';

  @override
  String get developerIconShowSubtitle =>
      'Reveal the draggable launcher without reopening this menu.';

  @override
  String get developerRemoveIcon => 'Remove icon';

  @override
  String get developerOrientationTitle => 'Orientation';

  @override
  String get developerPortraitOnly => 'Portrait only';

  @override
  String get developerServerTitle => 'Server';

  @override
  String get developerServerNotConfigured => 'Not connected in this build';

  @override
  String get developerSkribblePreview => 'Skribble component preview';

  @override
  String get developerSkribblePreviewSubtitle =>
      'Hand-drawn components in the active Verily theme. Developer preview only.';

  @override
  String get developerMovementPreview => 'Movement tracking preview';

  @override
  String get developerMovementPreviewSubtitle =>
      'Try live pose tracking for any movement without an action. Developer preview only.';

  @override
  String get developerHotReload => 'Hot reload';

  @override
  String get developerHotReloadSubtitle =>
      'Reassemble the widget tree without clearing state. New code needs a reload from the terminal.';

  @override
  String get developerFullReload => 'Full reload';

  @override
  String get developerFullReloadSubtitle =>
      'Rebuild the app shell and return to the start screen.';

  @override
  String get developerFullRestart => 'Full restart';

  @override
  String get developerFullRestartSubtitle =>
      'Recreate the provider scope and app from scratch.';

  @override
  String get developerDebugShortcutsTitle => 'Debug shortcuts';

  @override
  String get developerDebugShortcutsValue =>
      'Shake the phone or press ⇧⌘D / Ctrl+Shift+D to open this menu. ⌘D / Ctrl+D reassembles the widget tree. Drag the launcher onto Remove icon to hide it.';

  @override
  String developerReassembled(String source) {
    String _temp0 = intl.Intl.selectLogic(
      source,
      {
        'menu': 'Widget tree reassembled from the development menu.',
        'other': 'Widget tree reassembled from the keyboard shortcut.',
      },
    );
    return '$_temp0';
  }

  @override
  String get skribblePreviewColorsHeading => 'Colours';

  @override
  String get skribblePreviewToneNeutral => 'Highlight';

  @override
  String get skribblePreviewToneStamp => 'Verified';

  @override
  String get skribblePreviewTonePlace => 'Place';

  @override
  String get skribblePreviewToneReward => 'Reward';

  @override
  String get skribblePreviewToneReview => 'Review';

  @override
  String get skribblePreviewTypeHeading => 'Type';

  @override
  String get skribblePreviewTypeDisplay => 'Display';

  @override
  String get skribblePreviewTypeHeadline => 'Heading';

  @override
  String get skribblePreviewTypeTitle => 'Title';

  @override
  String get skribblePreviewTypeBody => 'Body';

  @override
  String get skribblePreviewTypeLabel => 'Label';

  @override
  String get skribblePreviewTypeCaption => 'Caption';

  @override
  String skribblePreviewTypeRole(String role, int size, int lineHeight) {
    return '$role · $size/$lineHeight';
  }

  @override
  String get skribblePreviewActionsHeading => 'Actions';

  @override
  String get skribblePreviewPrimaryAction => 'Publish action';

  @override
  String get skribblePreviewSecondaryAction => 'Maybe later';

  @override
  String get skribblePreviewDestructiveAction => 'Discard draft';

  @override
  String get skribblePreviewPostcardTitle => 'Ten squats at the park';

  @override
  String get skribblePreviewPostcardBody =>
      'Proof is captured live, then checked against the place.';

  @override
  String get skribblePreviewStatesHeading => 'States';

  @override
  String get skribblePreviewEmptyTitle => 'No actions nearby yet';

  @override
  String get skribblePreviewEmptyBody =>
      'Widen the map or post the first one here.';

  @override
  String get skribblePreviewEmptyAction => 'Post an action';

  @override
  String get skribblePreviewProblemTitle => 'We couldn’t load your proof';

  @override
  String get skribblePreviewProblemBody =>
      'The connection dropped before the upload finished. Reference VER-104.';

  @override
  String get skribblePreviewLoading => 'Checking your proof…';

  @override
  String get skribblePreviewFieldsHeading => 'Fields';

  @override
  String get skribblePreviewFieldLabel => 'Action title';

  @override
  String get skribblePreviewFieldHint => 'e.g. Ten squats at the park';

  @override
  String get skribblePreviewSelectionHeading => 'Selection';

  @override
  String get skribblePreviewNotifyCheckboxLabel =>
      'Tell me when my proof is reviewed';

  @override
  String get skribblePreviewRoughenSwitchLabel => 'Roughen the preview';

  @override
  String get skribblePreviewDoodlesHeading => 'Doodles and icons';

  @override
  String get verifyRequestHeaderTitle => 'Verify with Verily';

  @override
  String verifyRequestFrom(String app) {
    return 'From $app';
  }

  @override
  String verifyRequestFromWebsite(String app, String website) {
    return 'From $app · $website';
  }

  @override
  String verifyRequestAsks(String app, String kind) {
    String _temp0 = intl.Intl.selectLogic(
      kind,
      {
        'video': '$app wants a live video',
        'photo': '$app wants a live photo',
        'audio': '$app wants a live recording',
        'location': '$app wants to check you\'re at their place',
        'other': '$app wants live proof',
      },
    );
    return '$_temp0';
  }

  @override
  String get verifyRequestTheirWords => 'What they asked for';

  @override
  String verifyRequestInstructions(String instructions) {
    return '“$instructions”';
  }

  @override
  String get verifyRequestHowHeading => 'How it works';

  @override
  String verifyRequestHowCapture(String kind) {
    String _temp0 = intl.Intl.selectLogic(
      kind,
      {
        'video': 'You record it live in Verily, in one take. Nothing from your gallery.',
        'photo': 'You take it live in Verily. Nothing from your gallery.',
        'audio': 'You record it live in Verily, in one take.',
        'other': 'Verily checks your location once, right now.',
      },
    );
    return '$_temp0';
  }

  @override
  String get verifyRequestHowWord =>
      'Verily gives you a word to say while you record.';

  @override
  String get verifyRequestHowPlace =>
      'Verily checks your location once, to see if you\'re at their place.';

  @override
  String get verifyRequestHowContent =>
      'Verily checks it shows what they asked for.';

  @override
  String get verifyRequestHowCaptureOnly =>
      'Verily checks it\'s a genuine live capture.';

  @override
  String verifyRequestSharedHeading(String app) {
    return 'What $app gets';
  }

  @override
  String get verifyRequestSharesResult =>
      'Whether it passed, and when it was captured.';

  @override
  String get verifyRequestSharesPlace =>
      'Whether you were inside their place. Never where you were.';

  @override
  String verifyRequestSharesMedia(String kind) {
    String _temp0 = intl.Intl.selectLogic(
      kind,
      {
        'video': 'A copy of your video to download.',
        'photo': 'A copy of your photo to download.',
        'audio': 'A copy of your recording to download.',
        'other': 'A copy of your proof to download.',
      },
    );
    return '$_temp0';
  }

  @override
  String verifyRequestKeepsMedia(String kind) {
    String _temp0 = intl.Intl.selectLogic(
      kind,
      {
        'video': 'Not your video. It stays with Verily.',
        'photo': 'Not your photo. It stays with Verily.',
        'audio': 'Not your recording. It stays with Verily.',
        'other': 'Not your proof. It stays with Verily.',
      },
    );
    return '$_temp0';
  }

  @override
  String verifyRequestSharesSubject(String app) {
    return 'A private ID made only for $app. Never your name, email, or account.';
  }

  @override
  String verifyRequestExpires(String time) {
    return 'Answer by $time';
  }

  @override
  String get verifyRequestAccept => 'Accept and start';

  @override
  String get verifyRequestDecline => 'Decline';

  @override
  String get verifyRequestClose => 'Close';

  @override
  String verifyRequestProofTitle(String app) {
    return 'Your proof for $app';
  }

  @override
  String get verifyRequestStepPlace => 'Check in at their place';

  @override
  String verifyRequestStepPlaceBody(String app) {
    return 'Share your location once. $app only learns inside or outside.';
  }

  @override
  String get verifyRequestSharePlace => 'Share my location';

  @override
  String get verifyRequestSkipPlace => 'Continue without it';

  @override
  String get verifyRequestPlaceSent => 'Location sent';

  @override
  String verifyRequestPlaceSkipped(String app) {
    return 'Skipped. $app will see your place wasn\'t checked.';
  }

  @override
  String verifyRequestProofMissing(String app) {
    return 'Verily hasn\'t got your proof yet, so there\'s nothing to send $app. Finish the steps above, then try again.';
  }

  @override
  String verifyRequestPlaceNotConfirmed(String app) {
    return 'Verily couldn\'t confirm you\'re inside their place. $app will see that.';
  }

  @override
  String verifyRequestStepMedia(String kind) {
    String _temp0 = intl.Intl.selectLogic(
      kind,
      {
        'photo': 'Take the photo',
        'audio': 'Record the audio',
        'other': 'Record the video',
      },
    );
    return '$_temp0';
  }

  @override
  String get verifyRequestStepMediaBody =>
      'Live, in one take. This phone signs it before it\'s sent.';

  @override
  String verifyRequestOpenCapture(String kind) {
    String _temp0 = intl.Intl.selectLogic(
      kind,
      {
        'audio': 'Open the recorder',
        'other': 'Open the camera',
      },
    );
    return '$_temp0';
  }

  @override
  String get verifyRequestMediaSent => 'Proof sent';

  @override
  String get verifyRequestPlaceFirst => 'Check in first, then capture.';

  @override
  String get verifyRequestProofIn => 'Your proof is in';

  @override
  String verifyRequestReturn(String app) {
    return 'Return to $app';
  }

  @override
  String get verifyRequestDeclineInstead => 'Decline instead';

  @override
  String get verifyRequestTryAgain => 'Try again';

  @override
  String get verifyRequestLoading => 'Loading the request';

  @override
  String get verifyRequestSending => 'Sending your answer';

  @override
  String verifyRequestReturningTitle(String app) {
    return 'Returning you to $app';
  }

  @override
  String get verifyRequestReturningPassed =>
      'Verily checked your proof and it passed.';

  @override
  String verifyRequestReturningChecking(String app) {
    return 'Verily is still checking your proof. $app will get the result.';
  }

  @override
  String verifyRequestReturningFailed(String app) {
    return 'Your proof didn\'t pass. $app will be told.';
  }

  @override
  String get verifyRequestDeclinedTitle => 'Request declined';

  @override
  String verifyRequestDeclinedBody(String app) {
    return 'Returning you to $app. Nothing was captured or shared.';
  }

  @override
  String verifyRequestOpenFailed(String app) {
    return '$app didn\'t open. Switch back to it yourself to carry on.';
  }

  @override
  String verifyRequestOpenApp(String app) {
    return 'Open $app';
  }

  @override
  String get verifyRequestBackToVerily => 'Back to Verily';

  @override
  String get verifyRequestTheApp => 'the app';

  @override
  String get verifyRequestNotFoundTitle => 'We couldn\'t find this request';

  @override
  String get verifyRequestNotFoundBody =>
      'The link may be wrong, or the request was removed. Ask the app to send a new one.';

  @override
  String get verifyRequestExpiredTitle => 'This request has expired';

  @override
  String verifyRequestExpiredBody(String app) {
    return 'Requests only last a short while. Ask $app for a new one.';
  }

  @override
  String get verifyRequestTakenTitle => 'Someone else answered this request';

  @override
  String verifyRequestTakenBody(String app) {
    return 'Each request is for one person. Ask $app for your own.';
  }

  @override
  String get verifyRequestYouDeclinedTitle => 'You declined this request';

  @override
  String verifyRequestYouDeclinedBody(String app) {
    return 'Nothing was captured or shared with $app. Ask $app for a new request if you change your mind.';
  }

  @override
  String get verifyRequestClosedTitle => 'This request is closed';

  @override
  String verifyRequestClosedBody(String app) {
    return 'It was already answered or turned down. Ask $app for a new one if you still need it.';
  }

  @override
  String get verifyRequestRateLimitedTitle =>
      'That\'s a lot of requests for now';

  @override
  String verifyRequestRateLimitedBody(String app) {
    return 'You\'ve answered many requests from $app in the last hour. Try again later.';
  }

  @override
  String verifyRequestAppUnavailableTitle(String app) {
    return '$app isn\'t available';
  }

  @override
  String get verifyRequestLoadFailedTitle => 'We couldn\'t load this request';

  @override
  String get signInTitleAnswerRequest => 'Sign in to answer this request';

  @override
  String get signInTitleLinkApp => 'Sign in to link this app';

  @override
  String get appLinkHeaderTitle => 'Link an app';

  @override
  String appLinkAsks(String app) {
    return '$app wants to link with your Verily account';
  }

  @override
  String appLinkHow(String app) {
    return 'Once linked, $app can tell Verily when you\'ve done its actions.';
  }

  @override
  String appLinkAlreadyLinked(String app) {
    return 'You\'ve linked $app before. Linking again confirms it\'s still you.';
  }

  @override
  String appLinkSharesSubject(String app) {
    return 'A private ID made only for $app. Never your name, email, or account.';
  }

  @override
  String get appLinkSharesNothingElse =>
      'Nothing else. It can\'t see your proof, payouts, or other apps.';

  @override
  String appLinkApprove(String app) {
    return 'Link $app';
  }

  @override
  String get appLinkDecline => 'Don\'t link';

  @override
  String appLinkLinkedBody(String app) {
    return '$app is linked to your Verily account.';
  }

  @override
  String appLinkDeclinedBody(String app) {
    return '$app wasn\'t linked. Nothing was shared.';
  }

  @override
  String get appLinkDeclinedTitle => 'Not linked';

  @override
  String get appLinkInvalidTitle => 'This link doesn\'t work';

  @override
  String get appLinkInvalidBody =>
      'It\'s missing something or wasn\'t made for Verily. Go back to the app and try again.';

  @override
  String get appLinkLoadFailedTitle => 'We couldn\'t load this link';

  @override
  String appLinkRateLimitedBody(String app) {
    return 'You\'ve tried to link with $app many times. Try again later.';
  }

  @override
  String localCheckGuideTitle(String label) {
    return 'Quick check: $label';
  }

  @override
  String get localCheckPreparing => 'Getting the quick check ready';

  @override
  String localCheckAfterFinishLook(String label) {
    return 'Verily checks for “$label” after you finish';
  }

  @override
  String localCheckAfterFinishListen(String label) {
    return 'Verily listens for “$label” after you finish';
  }

  @override
  String localCheckGestureNotSeen(String label) {
    return 'We can\'t see your “$label” yet';
  }

  @override
  String localCheckGestureHandSeen(String label) {
    return 'We can see your hand. Now show “$label”';
  }

  @override
  String localCheckObjectNotSeen(String label) {
    return 'We can\'t spot “$label” yet';
  }

  @override
  String localCheckObjectAlmost(String label) {
    return 'Almost. Bring “$label” closer or into better light';
  }

  @override
  String get localCheckHolding => 'Got it, hold it there';

  @override
  String localCheckLooksRight(String label) {
    return 'That looks like “$label”';
  }

  @override
  String get localCheckReadyToRecord => 'Start recording when you\'re ready';

  @override
  String get localCheckKeepGoing => 'Keep going a moment';

  @override
  String get localCheckSayWordThenStop => 'Say your word, then stop';

  @override
  String get localCheckFinishing => 'Finishing';

  @override
  String get localCheckReviewNote =>
      'The phone\'s quick check is only a guide. Verily checks your proof again before it counts.';

  @override
  String get editorQuickCheckAdd => 'Add a quick check';

  @override
  String get editorQuickCheckAddHelp =>
      'The phone looks for a hand gesture, a thing, or a sound while people capture, and helps them get it right.';

  @override
  String get editorQuickCheckTitle => 'Quick check';

  @override
  String get editorQuickCheckRemove => 'Remove quick check';

  @override
  String get editorQuickCheckTaskLabel => 'Look for';

  @override
  String get editorQuickCheckTaskGesture => 'A hand gesture';

  @override
  String get editorQuickCheckTaskObject => 'A thing';

  @override
  String get editorQuickCheckTaskSound => 'A sound';

  @override
  String get editorQuickCheckGestureLabel => 'Gesture';

  @override
  String get editorQuickCheckObjectLabel => 'Thing';

  @override
  String get editorQuickCheckSoundLabel => 'Sound';

  @override
  String get editorQuickCheckPickObject => 'Pick a thing';

  @override
  String get editorQuickCheckPickSound => 'Pick a sound';

  @override
  String get editorQuickCheckSearch => 'Search';

  @override
  String get editorQuickCheckNoMatches => 'Nothing matches that';

  @override
  String editorQuickCheckScore(int percent) {
    return 'How sure: $percent%';
  }

  @override
  String get editorQuickCheckScoreSemantic =>
      'How sure the quick check must be';

  @override
  String editorQuickCheckFrames(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matching moments',
      one: '1 matching moment',
    );
    return '$_temp0';
  }

  @override
  String get editorQuickCheckFramesSemantic => 'How many moments must match';

  @override
  String get editorQuickCheckFramesHelp =>
      'How many of the moments Verily samples from the recording must show it.';

  @override
  String get editorQuickCheckPhotoFrames => 'A photo is checked once.';

  @override
  String get editorQuickCheckNote =>
      'People see live guidance while they capture. Verily checks the proof again itself before it counts.';

  @override
  String get editorQuickCheckPromptHelp =>
      'Optional with a quick check. Leave it empty and Verily writes the check from what you picked.';

  @override
  String get editorQuickCheckSpokenHelp =>
      'A quick check can\'t hear words, so with the word on, Verily\'s other checks or a person decide.';

  @override
  String get localCheckGestureClosedFist => 'Closed fist';

  @override
  String get localCheckGestureOpenPalm => 'Open palm';

  @override
  String get localCheckGesturePointingUp => 'Pointing up';

  @override
  String get localCheckGestureThumbDown => 'Thumbs down';

  @override
  String get localCheckGestureThumbUp => 'Thumbs up';

  @override
  String get localCheckGestureVictory => 'Victory sign';

  @override
  String get localCheckGestureILoveYou => '“I love you” sign';

  @override
  String get localCheckObjectPerson => 'Person';

  @override
  String get localCheckObjectBicycle => 'Bicycle';

  @override
  String get localCheckObjectCar => 'Car';

  @override
  String get localCheckObjectMotorcycle => 'Motorbike';

  @override
  String get localCheckObjectAirplane => 'Aeroplane';

  @override
  String get localCheckObjectBus => 'Bus';

  @override
  String get localCheckObjectTrain => 'Train';

  @override
  String get localCheckObjectTruck => 'Truck';

  @override
  String get localCheckObjectBoat => 'Boat';

  @override
  String get localCheckObjectTrafficLight => 'Traffic light';

  @override
  String get localCheckObjectFireHydrant => 'Fire hydrant';

  @override
  String get localCheckObjectStopSign => 'Stop sign';

  @override
  String get localCheckObjectParkingMeter => 'Parking meter';

  @override
  String get localCheckObjectBench => 'Bench';

  @override
  String get localCheckObjectBird => 'Bird';

  @override
  String get localCheckObjectCat => 'Cat';

  @override
  String get localCheckObjectDog => 'Dog';

  @override
  String get localCheckObjectHorse => 'Horse';

  @override
  String get localCheckObjectSheep => 'Sheep';

  @override
  String get localCheckObjectCow => 'Cow';

  @override
  String get localCheckObjectElephant => 'Elephant';

  @override
  String get localCheckObjectBear => 'Bear';

  @override
  String get localCheckObjectZebra => 'Zebra';

  @override
  String get localCheckObjectGiraffe => 'Giraffe';

  @override
  String get localCheckObjectBackpack => 'Backpack';

  @override
  String get localCheckObjectUmbrella => 'Umbrella';

  @override
  String get localCheckObjectHandbag => 'Handbag';

  @override
  String get localCheckObjectTie => 'Tie';

  @override
  String get localCheckObjectSuitcase => 'Suitcase';

  @override
  String get localCheckObjectFrisbee => 'Frisbee';

  @override
  String get localCheckObjectSkis => 'Skis';

  @override
  String get localCheckObjectSnowboard => 'Snowboard';

  @override
  String get localCheckObjectSportsBall => 'Ball';

  @override
  String get localCheckObjectKite => 'Kite';

  @override
  String get localCheckObjectBaseballBat => 'Baseball bat';

  @override
  String get localCheckObjectBaseballGlove => 'Baseball glove';

  @override
  String get localCheckObjectSkateboard => 'Skateboard';

  @override
  String get localCheckObjectSurfboard => 'Surfboard';

  @override
  String get localCheckObjectTennisRacket => 'Tennis racket';

  @override
  String get localCheckObjectBottle => 'Bottle';

  @override
  String get localCheckObjectWineGlass => 'Wine glass';

  @override
  String get localCheckObjectCup => 'Cup';

  @override
  String get localCheckObjectFork => 'Fork';

  @override
  String get localCheckObjectKnife => 'Knife';

  @override
  String get localCheckObjectSpoon => 'Spoon';

  @override
  String get localCheckObjectBowl => 'Bowl';

  @override
  String get localCheckObjectBanana => 'Banana';

  @override
  String get localCheckObjectApple => 'Apple';

  @override
  String get localCheckObjectSandwich => 'Sandwich';

  @override
  String get localCheckObjectOrange => 'Orange';

  @override
  String get localCheckObjectBroccoli => 'Broccoli';

  @override
  String get localCheckObjectCarrot => 'Carrot';

  @override
  String get localCheckObjectHotDog => 'Hot dog';

  @override
  String get localCheckObjectPizza => 'Pizza';

  @override
  String get localCheckObjectDonut => 'Doughnut';

  @override
  String get localCheckObjectCake => 'Cake';

  @override
  String get localCheckObjectChair => 'Chair';

  @override
  String get localCheckObjectCouch => 'Sofa';

  @override
  String get localCheckObjectPottedPlant => 'Potted plant';

  @override
  String get localCheckObjectBed => 'Bed';

  @override
  String get localCheckObjectDiningTable => 'Table';

  @override
  String get localCheckObjectToilet => 'Toilet';

  @override
  String get localCheckObjectTv => 'TV';

  @override
  String get localCheckObjectLaptop => 'Laptop';

  @override
  String get localCheckObjectMouse => 'Computer mouse';

  @override
  String get localCheckObjectRemote => 'Remote control';

  @override
  String get localCheckObjectKeyboard => 'Keyboard';

  @override
  String get localCheckObjectCellPhone => 'Phone';

  @override
  String get localCheckObjectMicrowave => 'Microwave';

  @override
  String get localCheckObjectOven => 'Oven';

  @override
  String get localCheckObjectToaster => 'Toaster';

  @override
  String get localCheckObjectSink => 'Sink';

  @override
  String get localCheckObjectRefrigerator => 'Refrigerator';

  @override
  String get localCheckObjectBook => 'Book';

  @override
  String get localCheckObjectClock => 'Clock';

  @override
  String get localCheckObjectVase => 'Vase';

  @override
  String get localCheckObjectScissors => 'Scissors';

  @override
  String get localCheckObjectTeddyBear => 'Teddy bear';

  @override
  String get localCheckObjectHairDrier => 'Hair dryer';

  @override
  String get localCheckObjectToothbrush => 'Toothbrush';

  @override
  String get localCheckSoundClapping => 'Clapping';

  @override
  String get localCheckSoundFingerSnapping => 'Finger snapping';

  @override
  String get localCheckSoundWhistling => 'Whistling';

  @override
  String get localCheckSoundApplause => 'Applause';

  @override
  String get localCheckSoundLaughter => 'Laughter';

  @override
  String get localCheckSoundCough => 'Coughing';

  @override
  String get localCheckSoundSneeze => 'Sneezing';

  @override
  String get localCheckSoundBell => 'Bell';

  @override
  String get localCheckSoundDoorbell => 'Doorbell';

  @override
  String get localCheckSoundKnock => 'Knocking';

  @override
  String get localCheckSoundDog => 'Dog';

  @override
  String get localCheckSoundBark => 'Dog barking';

  @override
  String get localCheckSoundCat => 'Cat';

  @override
  String get localCheckSoundMeow => 'Cat meowing';

  @override
  String get localCheckSoundBird => 'Bird';

  @override
  String get localCheckSoundChirpTweet => 'Birdsong';

  @override
  String get localCheckSoundCrowingCockADoodleDoo => 'Rooster crowing';

  @override
  String get localCheckSoundSiren => 'Siren';

  @override
  String get localCheckSoundAlarmClock => 'Alarm clock';

  @override
  String get localCheckSoundTyping => 'Typing';

  @override
  String get localCheckSoundWaterTapFaucet => 'Running tap';

  @override
  String get localCheckSoundGuitar => 'Guitar';

  @override
  String get localCheckSoundPiano => 'Piano';

  @override
  String get localCheckSoundDrum => 'Drum';

  @override
  String get localCheckSoundWhistle => 'Whistle blown';

  @override
  String editorAppModeLabel(String appName) {
    return 'How $appName confirms';
  }

  @override
  String get editorAppModePush => 'It tells Verily';

  @override
  String get editorAppModePull => 'Verily asks it';

  @override
  String editorAppModePushBody(String appName) {
    return '$appName\'s server sends a confirmation when someone does it, using the link code they gave it. Participants have nothing to tap.';
  }

  @override
  String editorAppModePullBody(String appName) {
    return 'Participants tap \"I did it\" and Verily asks $appName\'s webhook straight away. They can add a username or order number so $appName can find them.';
  }

  @override
  String editorAppModePullNeedsWebhook(String appName) {
    return '$appName has no webhook address yet. Add one on its App page before you publish, or Verily has nowhere to ask.';
  }

  @override
  String get appsSecretTitle => 'Save your signing secret';

  @override
  String appsSecretBody(String appName) {
    return '$appName\'s server uses this secret to check that each webhook call really came from Verily. Keep it on that server only.';
  }

  @override
  String get appsSecretWarning =>
      'Verily shows this secret only once. If you lose it, rotate to get a new one.';

  @override
  String appsSecretOverlap(String date) {
    return 'Calls are signed with both this secret and the previous one until $date, so you can switch over without missing any.';
  }

  @override
  String appsSecretLabel(int version) {
    return 'Signing secret, version $version';
  }

  @override
  String get appsSecretCopy => 'Copy secret';

  @override
  String get appsWebhookHeading => 'Webhook';

  @override
  String get appsWebhookBody =>
      'Verily sends signed events here (verified and rejected attempts, payouts, finished verification requests) and asks it to confirm proof on actions set to \"Verily asks it\".';

  @override
  String get appsWebhookLabel => 'Webhook address';

  @override
  String get appsWebhookHint => 'https://example.com/verily/webhook';

  @override
  String get appsWebhookSave => 'Save address';

  @override
  String get appsWebhookRemove => 'Remove address';

  @override
  String get appsWebhookSaved => 'Webhook address saved';

  @override
  String get appsWebhookRemoved => 'Webhook address removed';

  @override
  String get appsWebhookInvalid =>
      'Use an https address on a public website: the standard port, no password, and no #fragment. Local, private, and internal addresses can\'t receive webhooks.';

  @override
  String get appsWebhooksUnavailable =>
      'Webhooks aren\'t switched on for Verily yet. Try again later.';

  @override
  String get appsWebhookNotSending =>
      'Verily sends events once this App has both a webhook address and a signing secret.';

  @override
  String appsSecretVersion(int version) {
    return 'Signing secret: version $version';
  }

  @override
  String get appsSecretNone => 'No signing secret yet';

  @override
  String get appsSecretHelp =>
      'Rotate it if it may have leaked. The old secret keeps signing for 24 hours, so nothing is missed.';

  @override
  String get appsSecretNoneHelp =>
      'Issue one so your server can check that each call came from Verily.';

  @override
  String get appsSecretRotate => 'Rotate secret';

  @override
  String get appsSecretIssue => 'Issue secret';

  @override
  String get appsRedirectHeading => 'Return addresses';

  @override
  String get appsRedirectBody =>
      'Where Verily sends people back after they link their account or finish a verification for this App. Matching is exact, so add each address exactly as your app sends it.';

  @override
  String get appsRedirectEmpty => 'No return addresses yet.';

  @override
  String get appsRedirectLabel => 'Return address';

  @override
  String get appsRedirectHint => 'com.example.app://verily';

  @override
  String get appsRedirectAdd => 'Add address';

  @override
  String appsRedirectCount(int count, int max) {
    return '$count of $max';
  }

  @override
  String appsRedirectFull(int max) {
    return 'That\'s all $max. Remove one to add another.';
  }

  @override
  String get appsRedirectDuplicate => 'That address is already on the list.';

  @override
  String get appsRedirectInvalid =>
      'Use an exact https address or your app\'s own scheme, such as com.example.app://verily. Wildcards, #fragments, plain http, and verily: addresses aren\'t allowed.';

  @override
  String appsRedirectTooMany(int max) {
    return 'An App can have at most $max return addresses. Remove one first.';
  }

  @override
  String get appsRedirectRemoveTitle => 'Remove this return address?';

  @override
  String appsRedirectRemoveBody(String uri) {
    return 'Links that send people back to $uri will stop working.';
  }

  @override
  String get appsRedirectRemoveConfirm => 'Remove';

  @override
  String appsRedirectRemoveTooltip(String uri) {
    return 'Remove $uri';
  }

  @override
  String get appsRateLimited =>
      'That\'s a lot of requests in a short time. Wait a little, then try again.';

  @override
  String get appsDeliveriesHeading => 'Webhook calls';

  @override
  String get appsDeliveriesBody =>
      'Every call Verily made to your webhook, newest first, with how your server answered.';

  @override
  String get appsDeliveriesLoading => 'Loading webhook calls';

  @override
  String get appsDeliveriesFailed => 'Webhook calls didn\'t load';

  @override
  String get appsDeliveriesEmpty =>
      'No calls yet. They appear here once this App has a webhook address and a signing secret.';

  @override
  String get appsDeliveriesMore => 'Show older calls';

  @override
  String get appsDeliveryNoAnswer => 'no answer';

  @override
  String appsDeliveryHttp(int code) {
    return 'HTTP $code';
  }

  @override
  String get appsDeliverySucceeded => 'Your server accepted it.';

  @override
  String appsDeliveryDetails(int attempt, String answer, int milliseconds) {
    return 'Try $attempt · $answer · $milliseconds ms';
  }

  @override
  String appsDeliveryEvent(String eventType) {
    return 'Event: $eventType';
  }

  @override
  String appsDeliveryEventError(String eventType, String errorCode) {
    return 'Event: $eventType · Error code: $errorCode';
  }

  @override
  String actionAppPullBody(String appName) {
    return '$appName checks this step when you say you\'ve done it. Verily doesn\'t check the act, only that $appName said so.';
  }

  @override
  String get appsEventAttemptVerify => 'Pull check: asked to confirm';

  @override
  String get appsEventAttemptVerified => 'Attempt verified';

  @override
  String get appsEventAttemptRejected => 'Attempt rejected';

  @override
  String get appsEventPayoutReleased => 'Payout released';

  @override
  String get appsEventRequestCompleted => 'Verification request finished';

  @override
  String get appsEventOther => 'Webhook event';

  @override
  String get appsDeliveryTimeout =>
      'Your server didn\'t answer within 10 seconds.';

  @override
  String get appsDeliveryConnectionFailed =>
      'Verily couldn\'t connect to your server.';

  @override
  String get appsDeliveryTlsFailure =>
      'The secure connection to your server failed.';

  @override
  String get appsDeliveryHostNotPublic =>
      'The address didn\'t lead to a public server.';

  @override
  String get appsDeliveryInvalidUrl => 'The webhook address isn\'t valid.';

  @override
  String get appsDeliveryTooLarge => 'Your server\'s answer was too large.';

  @override
  String get appsDeliveryInvalidResponse =>
      'Your server\'s answer wasn\'t the expected JSON verdict.';

  @override
  String get appsDeliveryNoWebhook => 'There was no webhook address to call.';

  @override
  String get appsDeliveryNoSecret =>
      'There was no signing secret to sign the call with.';

  @override
  String appsDeliveryRefused(int code) {
    return 'Your server answered HTTP $code.';
  }

  @override
  String get appsDeliveryFailedOther => 'The call didn\'t go through.';

  @override
  String get appsEventStatusPending => 'Verily will try again.';

  @override
  String get appsEventStatusDelivering => 'Being delivered now.';

  @override
  String get appsEventStatusDelivered => 'Delivered.';

  @override
  String get appsEventStatusFailed => 'Verily stopped trying.';

  @override
  String actionPullIntro(String appName) {
    return 'Done it in $appName? Tap \"I did it\" and Verily asks $appName to confirm.';
  }

  @override
  String get actionPullReferenceLabel => 'Username or order number (optional)';

  @override
  String get actionPullReferenceHint => 'ada_lovelace or #1234';

  @override
  String actionPullReferenceHelp(String appName) {
    return 'Helps $appName find you. Letters, numbers, spaces, and . _ @ # : / + - only.';
  }

  @override
  String get actionPullReferenceInvalid =>
      'Use up to 120 letters, numbers, spaces, or . _ @ # : / + -';

  @override
  String get actionPullAsk => 'I did it';

  @override
  String get actionPullAskAgain => 'Ask again';

  @override
  String actionPullWaitingTitle(String appName) {
    return 'Waiting for $appName';
  }

  @override
  String actionPullWaitingBody(String appName) {
    return '$appName is checking and will confirm on its own. You can leave this page; it updates when $appName answers.';
  }

  @override
  String actionPullFailedTitle(String appName) {
    return '$appName didn\'t answer';
  }

  @override
  String get actionPullFailedBody => 'Try again in a little while.';

  @override
  String actionPullUnansweredTitle(String appName) {
    return '$appName never answered';
  }

  @override
  String get actionPullAcceptedBody => 'Nothing more to do here.';

  @override
  String actionPullRejectedTitle(String appName) {
    return '$appName didn\'t confirm it';
  }

  @override
  String actionPullRejectedBody(String appName) {
    return 'If you think that\'s wrong, check with $appName, or appeal and the action\'s creator will look again.';
  }

  @override
  String actionPullUnavailable(String appName) {
    return '$appName can\'t confirm proof right now. Try again later.';
  }

  @override
  String get proofReasonProofAccepted => 'Your proof passed.';

  @override
  String get proofReasonChecking => 'Verily is checking your proof.';

  @override
  String get proofReasonNeedsReview =>
      'A person will check this before it counts.';

  @override
  String get proofReasonNotAccepted =>
      'Your proof didn\'t show what this action asks for.';

  @override
  String get proofReasonMissing =>
      'Some proof is still missing. Finish every step first.';

  @override
  String get proofReasonActionFull => 'This action has reached its limit.';

  @override
  String get proofReasonOutsideArea =>
      'You weren\'t inside the area for this action. Go to the pin and try again.';

  @override
  String get proofReasonLocationNotPrecise =>
      'Your location wasn\'t precise enough. Step outside or near a window and try again.';

  @override
  String get proofReasonLocationTooOld =>
      'Your location was too old by the time it arrived. Try again.';

  @override
  String get proofReasonPhoneClock =>
      'Your phone\'s clock doesn\'t match the time. Set it to automatic and try again.';

  @override
  String get proofReasonRecordingLength =>
      'The recording was too short or too long for this action.';

  @override
  String get proofReasonChallengeWordMissing =>
      'The word to say wasn\'t ready before you recorded. Record again.';

  @override
  String get proofReasonChallengeWordTooEarly =>
      'The recording started before your word arrived. Record again.';

  @override
  String get proofReasonChallengeWordNotHeard =>
      'We couldn\'t hear your word. Say it clearly and record again.';

  @override
  String get proofReasonCodeNotMatched =>
      'That code isn\'t this place\'s code. Scan the one shown here.';

  @override
  String get proofReasonMotionNotMatched =>
      'The movement didn\'t match what this action asks for. Try again.';

  @override
  String get proofReasonCaptureNotVerified =>
      'Your phone couldn\'t vouch for this capture. Record it again in Verily.';

  @override
  String get proofReasonPayoutReview =>
      'Bigger rewards get a quick look from a person before they\'re sent.';

  @override
  String get proofReasonAppConfirmed => 'The App confirmed it.';

  @override
  String get proofReasonAppNotConfirmed => 'The App didn\'t confirm it.';

  @override
  String get proofReasonAppChecking => 'Waiting for the App to confirm.';

  @override
  String get proofReasonAppUnreachable =>
      'The App couldn\'t be reached. Try again in a little while.';

  @override
  String get proofReasonAppNoAnswer => 'The App didn\'t answer in time.';

  @override
  String get proofReasonOther => 'Your proof wasn\'t accepted.';

  @override
  String get reviewReasonPayout => 'Large reward';

  @override
  String get reviewReasonSecurity => 'Security check';

  @override
  String get reviewReasonChallengeWord => 'Word unclear';

  @override
  String get reviewReasonLocation => 'Location check';

  @override
  String get reviewReasonAbuse => 'Possible misuse';

  @override
  String get reviewReasonLocalCheck => 'Quick check didn\'t run';

  @override
  String get reviewReasonVerifier => 'Automatic check unavailable';

  @override
  String get reviewReasonLowConfidence => 'Not sure enough';

  @override
  String get reviewReasonNeedsPerson => 'Needs a person';

  @override
  String reviewReasonLabel(String reason) {
    return 'Why it\'s here: $reason';
  }
}
