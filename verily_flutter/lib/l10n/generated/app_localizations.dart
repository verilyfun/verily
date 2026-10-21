import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Bottom navigation: find and do actions.
  ///
  /// In en, this message translates to:
  /// **'Do'**
  String get tabDo;

  /// Bottom navigation: post actions and manage Apps.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get tabCreate;

  /// Bottom navigation: your attempts, payouts, and settings.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get tabMe;

  /// Accessible label of the main navigation.
  ///
  /// In en, this message translates to:
  /// **'Main sections'**
  String get navigationPrimaryLabel;

  /// Heading above the navigation rail on wide screens.
  ///
  /// In en, this message translates to:
  /// **'Your spaces'**
  String get navigationRailHeading;

  /// Fallback message for an unexpected failure. Never shows technical detail.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again in a moment.'**
  String get errorGeneric;

  /// Shown when an action, App, or link no longer exists.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find that. It may have ended or been removed.'**
  String get errorNotFound;

  /// Title shown when another app opens a verification request link.
  ///
  /// In en, this message translates to:
  /// **'Verify with Verily is almost here'**
  String get comingSoonVerificationTitle;

  /// Body shown for a verification request link before the feature exists.
  ///
  /// In en, this message translates to:
  /// **'An app asked you to prove something with Verily. Requests like this will open right here soon. Nothing was captured or shared.'**
  String get comingSoonVerificationBody;

  /// Title shown when another app opens an account-linking link.
  ///
  /// In en, this message translates to:
  /// **'Linking apps is almost here'**
  String get comingSoonLinkTitle;

  /// Body shown for an App linking link before the feature exists.
  ///
  /// In en, this message translates to:
  /// **'An app asked to link with your Verily account. Soon you\'ll confirm that here. Until then, copy your link code from the action the app shared.'**
  String get comingSoonLinkBody;

  /// Button that leaves a coming-soon page for the Do tab.
  ///
  /// In en, this message translates to:
  /// **'Find actions'**
  String get comingSoonGoToDo;

  /// Trust label for actions whose proof is captured live and checked by Verily.
  ///
  /// In en, this message translates to:
  /// **'Verified on your phone'**
  String get trustVerifiedOnPhone;

  /// Trust label for actions a third-party App confirms. Verily does not check the act itself.
  ///
  /// In en, this message translates to:
  /// **'Confirmed by {appName}'**
  String trustConfirmedByApp(String appName);

  /// Reward chip: the payout per completion, locked in escrow. Amount includes the token, such as '5 USDC'.
  ///
  /// In en, this message translates to:
  /// **'{amount} · in escrow'**
  String rewardInEscrow(String amount);

  /// How many payouts remain in an action's escrow.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No rewards left} =1{1 reward left} other{{count} rewards left}}'**
  String rewardRemaining(int count);

  /// Attempt status: proof still being gathered.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get attemptStatusCollectingEvidence;

  /// Attempt status: the proof is being checked.
  ///
  /// In en, this message translates to:
  /// **'Checking your proof'**
  String get attemptStatusVerifying;

  /// Attempt status: a person is looking at the proof.
  ///
  /// In en, this message translates to:
  /// **'With a reviewer'**
  String get attemptStatusPendingReview;

  /// Attempt status: the proof passed.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get attemptStatusVerified;

  /// Attempt status: the proof was not accepted.
  ///
  /// In en, this message translates to:
  /// **'Not accepted'**
  String get attemptStatusRejected;

  /// Attempt status: the action reached its limit before this attempt finished.
  ///
  /// In en, this message translates to:
  /// **'This action is full'**
  String get attemptStatusCapacityReached;

  /// Payout status: reserved or being sent.
  ///
  /// In en, this message translates to:
  /// **'{amount} on its way'**
  String payoutOnItsWay(String amount);

  /// Payout status: waiting for the participant to link a payout wallet.
  ///
  /// In en, this message translates to:
  /// **'Add a wallet to receive {amount}'**
  String payoutAwaitingWallet(String amount);

  /// Payout status: a person checks valuable payouts before release.
  ///
  /// In en, this message translates to:
  /// **'{amount} held for a quick check'**
  String payoutHeldForReview(String amount);

  /// Payout status: sent to the participant's wallet.
  ///
  /// In en, this message translates to:
  /// **'{amount} paid'**
  String payoutReleased(String amount);

  /// Payout status: release failed and will be retried.
  ///
  /// In en, this message translates to:
  /// **'Sending {amount} didn\'t work yet. We\'ll keep trying.'**
  String payoutFailed(String amount);

  /// Payout status: the escrow's payout window closed.
  ///
  /// In en, this message translates to:
  /// **'{amount} expired before it could be sent'**
  String payoutExpired(String amount);

  /// Shown on a verified attempt when no payout was left.
  ///
  /// In en, this message translates to:
  /// **'Every reward for this action has been claimed'**
  String get rewardOutcomePoolEmpty;

  /// Shown when the participant reached the action's per-account limit.
  ///
  /// In en, this message translates to:
  /// **'You\'ve earned the most this action allows'**
  String get rewardOutcomeAccountLimit;

  /// Shown when the escrow's payout period closed before this completion.
  ///
  /// In en, this message translates to:
  /// **'The reward period had ended'**
  String get rewardOutcomePoolEnded;

  /// Shown instead of the place picker map when it cannot load or the platform has no map.
  ///
  /// In en, this message translates to:
  /// **'The map isn\'t available here. Enter the place\'s coordinates instead.'**
  String get editorMapUnavailable;

  /// Validation for the verification prompt.
  ///
  /// In en, this message translates to:
  /// **'Say what Verily should check in at least 10 characters.'**
  String get editorVerifierPromptInvalid;

  /// Button that replaces the shown venue code with a fresh one, for example after someone scanned it.
  ///
  /// In en, this message translates to:
  /// **'Show a new code'**
  String get venueCodeNew;

  /// Editor page title when creating an action.
  ///
  /// In en, this message translates to:
  /// **'New action'**
  String get editorNewTitle;

  /// Editor page title when editing an action.
  ///
  /// In en, this message translates to:
  /// **'Edit action'**
  String get editorEditTitle;

  /// Breadcrumb under the new-action title.
  ///
  /// In en, this message translates to:
  /// **'A place, a proof, and an optional reward'**
  String get editorNewSubtitle;

  /// Breadcrumb under the edit-action title. Live actions keep their rules for attempts already started.
  ///
  /// In en, this message translates to:
  /// **'Saving a live action starts its next version'**
  String get editorEditSubtitle;

  /// Shown while a saved action loads in the editor.
  ///
  /// In en, this message translates to:
  /// **'Opening your action…'**
  String get editorLoading;

  /// Title shown when a saved action fails to load.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t open this action'**
  String get editorLoadFailed;

  /// Heading above the ways to start a new action.
  ///
  /// In en, this message translates to:
  /// **'How do you want to start?'**
  String get editorStartHeading;

  /// Label of the field for describing an action to draft with AI.
  ///
  /// In en, this message translates to:
  /// **'Describe the action'**
  String get editorPromptLabel;

  /// Example shown in the describe-the-action field.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ten squats in the park before 9am, filmed in one go'**
  String get editorPromptHint;

  /// Explains AI drafting under the describe field.
  ///
  /// In en, this message translates to:
  /// **'Verily drafts the place, the proof, and the wording. You check every field before anything goes live.'**
  String get editorPromptHelp;

  /// Button that drafts an action from the description.
  ///
  /// In en, this message translates to:
  /// **'Draft it for me'**
  String get editorPromptAction;

  /// Shown when the description is too short to draft from.
  ///
  /// In en, this message translates to:
  /// **'Say a little more: at least 20 characters.'**
  String get editorPromptTooShort;

  /// Heading above the action templates.
  ///
  /// In en, this message translates to:
  /// **'Or start from a template'**
  String get editorTemplatesHeading;

  /// Shown while templates load.
  ///
  /// In en, this message translates to:
  /// **'Loading templates…'**
  String get editorTemplatesLoading;

  /// Shown when templates fail to load.
  ///
  /// In en, this message translates to:
  /// **'Templates didn\'t load.'**
  String get editorTemplatesFailed;

  /// Button that starts an empty action.
  ///
  /// In en, this message translates to:
  /// **'Start from scratch'**
  String get editorStartBlank;

  /// Button that discards the unsaved draft and returns to the starting choices.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get editorStartOver;

  /// Shown when a template or AI draft fills the editor.
  ///
  /// In en, this message translates to:
  /// **'Draft ready. Check every field before you save.'**
  String get editorDraftReady;

  /// Heading above safety notes that came with a draft.
  ///
  /// In en, this message translates to:
  /// **'Before you publish'**
  String get editorSafetyHeading;

  /// Section heading for the title and description.
  ///
  /// In en, this message translates to:
  /// **'The action'**
  String get editorBasicsHeading;

  /// Label of the action title field.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get editorTitleLabel;

  /// Label of the action description field.
  ///
  /// In en, this message translates to:
  /// **'What people do'**
  String get editorDescriptionLabel;

  /// Validation message for an empty required field.
  ///
  /// In en, this message translates to:
  /// **'Fill this in.'**
  String get editorFieldRequired;

  /// Shown when saving finds invalid fields.
  ///
  /// In en, this message translates to:
  /// **'A few fields need a look before saving.'**
  String get editorFixErrors;

  /// Section heading for an action's requirements.
  ///
  /// In en, this message translates to:
  /// **'Proof'**
  String get editorProofHeading;

  /// Explains the proof section.
  ///
  /// In en, this message translates to:
  /// **'Up to five. Every proof is captured live in Verily, or confirmed by one of your Apps.'**
  String get editorProofHelp;

  /// Shown when an action has no requirements.
  ///
  /// In en, this message translates to:
  /// **'Add at least one proof.'**
  String get editorProofNone;

  /// Button that opens the list of proof kinds.
  ///
  /// In en, this message translates to:
  /// **'Add proof'**
  String get editorAddProof;

  /// Title of the sheet listing proof kinds.
  ///
  /// In en, this message translates to:
  /// **'What should people prove?'**
  String get editorAddProofSheetTitle;

  /// Accessible label of the button that removes a proof.
  ///
  /// In en, this message translates to:
  /// **'Remove {title}'**
  String editorRemoveProof(String title);

  /// Label of a proof's title field.
  ///
  /// In en, this message translates to:
  /// **'What to call it'**
  String get editorProofTitleLabel;

  /// Label of a proof's instructions field.
  ///
  /// In en, this message translates to:
  /// **'What people do for it'**
  String get editorProofInstructionsLabel;

  /// Shown when five proofs already exist.
  ///
  /// In en, this message translates to:
  /// **'An action can ask for five proofs at most.'**
  String get editorProofMaxReached;

  /// Explains why phone proof cannot be added next to App confirmation.
  ///
  /// In en, this message translates to:
  /// **'An App\'s confirmation is the only proof on its action. Remove it to add phone proof.'**
  String get editorProofAppOnly;

  /// Explains why App confirmation cannot be added next to phone proof.
  ///
  /// In en, this message translates to:
  /// **'App confirmation can\'t be mixed with phone proof. Remove the other proofs to use it.'**
  String get editorProofPhoneOnly;

  /// Name of the 'Be at a place' proof kind.
  ///
  /// In en, this message translates to:
  /// **'Be at a place'**
  String get editorKindLocation;

  /// One-line explanation of the 'Be at a place' proof kind.
  ///
  /// In en, this message translates to:
  /// **'A pin and a radius. People share a fresh location from inside it.'**
  String get editorKindLocationHelp;

  /// Starting title of a new 'Be at a place' proof.
  ///
  /// In en, this message translates to:
  /// **'Check in at the place'**
  String get editorKindLocationDefaultTitle;

  /// Starting instructions of a new 'Be at a place' proof.
  ///
  /// In en, this message translates to:
  /// **'Share a fresh location while you\'re there.'**
  String get editorKindLocationDefaultInstructions;

  /// Name of the 'Scan a venue code' proof kind.
  ///
  /// In en, this message translates to:
  /// **'Scan a venue code'**
  String get editorKindVenueCode;

  /// One-line explanation of the 'Scan a venue code' proof kind.
  ///
  /// In en, this message translates to:
  /// **'You show a code at the venue that changes every few minutes.'**
  String get editorKindVenueCodeHelp;

  /// Starting title of a new 'Scan a venue code' proof.
  ///
  /// In en, this message translates to:
  /// **'Scan the venue code'**
  String get editorKindVenueCodeDefaultTitle;

  /// Starting instructions of a new 'Scan a venue code' proof.
  ///
  /// In en, this message translates to:
  /// **'Scan the code on display right now.'**
  String get editorKindVenueCodeDefaultInstructions;

  /// Name of the 'Move the phone' proof kind.
  ///
  /// In en, this message translates to:
  /// **'Move the phone'**
  String get editorKindMotion;

  /// One-line explanation of the 'Move the phone' proof kind.
  ///
  /// In en, this message translates to:
  /// **'Spins, flips, shakes, a gentle toss, or holding still, felt by the phone.'**
  String get editorKindMotionHelp;

  /// Starting title of a new 'Move the phone' proof.
  ///
  /// In en, this message translates to:
  /// **'Move the phone'**
  String get editorKindMotionDefaultTitle;

  /// Starting instructions of a new 'Move the phone' proof.
  ///
  /// In en, this message translates to:
  /// **'Hold the phone securely and do the movement once you start.'**
  String get editorKindMotionDefaultInstructions;

  /// Name of the 'Count reps' proof kind.
  ///
  /// In en, this message translates to:
  /// **'Count reps'**
  String get editorKindMovementReps;

  /// One-line explanation of the 'Count reps' proof kind.
  ///
  /// In en, this message translates to:
  /// **'Squats, press-ups and more, counted live by the camera and checked from the video.'**
  String get editorKindMovementRepsHelp;

  /// Starting title of a new 'Count reps' proof.
  ///
  /// In en, this message translates to:
  /// **'Do the reps'**
  String get editorKindMovementRepsDefaultTitle;

  /// Starting instructions of a new 'Count reps' proof.
  ///
  /// In en, this message translates to:
  /// **'Prop your phone up, step back so your whole body is in frame, and keep going until the counter reaches the target.'**
  String get editorKindMovementRepsDefaultInstructions;

  /// Name of the 'Record a video' proof kind.
  ///
  /// In en, this message translates to:
  /// **'Record a video'**
  String get editorKindVideo;

  /// One-line explanation of the 'Record a video' proof kind.
  ///
  /// In en, this message translates to:
  /// **'Filmed live in Verily, never uploaded.'**
  String get editorKindVideoHelp;

  /// Starting title of a new 'Record a video' proof.
  ///
  /// In en, this message translates to:
  /// **'Record it'**
  String get editorKindVideoDefaultTitle;

  /// Starting instructions of a new 'Record a video' proof.
  ///
  /// In en, this message translates to:
  /// **'Film one continuous take that shows it happening.'**
  String get editorKindVideoDefaultInstructions;

  /// Name of the 'Take a photo' proof kind.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get editorKindPhoto;

  /// One-line explanation of the 'Take a photo' proof kind.
  ///
  /// In en, this message translates to:
  /// **'Taken live in Verily, never picked from the gallery.'**
  String get editorKindPhotoHelp;

  /// Starting title of a new 'Take a photo' proof.
  ///
  /// In en, this message translates to:
  /// **'Take the photo'**
  String get editorKindPhotoDefaultTitle;

  /// Starting instructions of a new 'Take a photo' proof.
  ///
  /// In en, this message translates to:
  /// **'Take one clear photo that shows it.'**
  String get editorKindPhotoDefaultInstructions;

  /// Name of the 'Record audio' proof kind.
  ///
  /// In en, this message translates to:
  /// **'Record audio'**
  String get editorKindAudio;

  /// One-line explanation of the 'Record audio' proof kind.
  ///
  /// In en, this message translates to:
  /// **'Recorded live in Verily.'**
  String get editorKindAudioHelp;

  /// Starting title of a new 'Record audio' proof.
  ///
  /// In en, this message translates to:
  /// **'Record it'**
  String get editorKindAudioDefaultTitle;

  /// Starting instructions of a new 'Record audio' proof.
  ///
  /// In en, this message translates to:
  /// **'Record one continuous clip.'**
  String get editorKindAudioDefaultInstructions;

  /// Name of the 'Confirmed by your App' proof kind.
  ///
  /// In en, this message translates to:
  /// **'Confirmed by your App'**
  String get editorKindApp;

  /// One-line explanation of the 'Confirmed by your App' proof kind.
  ///
  /// In en, this message translates to:
  /// **'One of your Verily Apps tells Verily it happened. Verily doesn\'t check the act itself.'**
  String get editorKindAppHelp;

  /// Starting title of a new 'Confirmed by your App' proof.
  ///
  /// In en, this message translates to:
  /// **'Confirmed by your App'**
  String get editorKindAppDefaultTitle;

  /// Starting instructions of a new 'Confirmed by your App' proof.
  ///
  /// In en, this message translates to:
  /// **'Do it in the App. It confirms with Verily for you.'**
  String get editorKindAppDefaultInstructions;

  /// Hint under the place picker map.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to move the pin. The hatched circle is where proof counts.'**
  String get editorPlaceTapHint;

  /// Button that moves the pin to the creator's position.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get editorUseMyLocation;

  /// Shown when the device position could not be read.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find your location. Tap the map or enter the coordinates.'**
  String get editorLocationFailed;

  /// Shown when location permission is denied or services are off.
  ///
  /// In en, this message translates to:
  /// **'Location is off for Verily. Tap the map or enter the coordinates.'**
  String get editorLocationOff;

  /// The place's radius in metres.
  ///
  /// In en, this message translates to:
  /// **'Radius: {meters} m'**
  String editorRadius(int meters);

  /// Accessible label of the radius slider.
  ///
  /// In en, this message translates to:
  /// **'Radius around the place'**
  String get editorRadiusSemantic;

  /// Expands the latitude and longitude fields.
  ///
  /// In en, this message translates to:
  /// **'Enter coordinates'**
  String get editorCoordinates;

  /// Label of the latitude field.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get editorLatitudeLabel;

  /// Label of the longitude field.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get editorLongitudeLabel;

  /// Shown for out-of-range coordinates.
  ///
  /// In en, this message translates to:
  /// **'Latitude runs from -90 to 90 and longitude from -180 to 180.'**
  String get editorCoordinatesInvalid;

  /// Shown when a place proof has no place yet.
  ///
  /// In en, this message translates to:
  /// **'Pick a place on the map or enter its coordinates.'**
  String get editorPlaceMissing;

  /// Accessible label of the place picker map.
  ///
  /// In en, this message translates to:
  /// **'Map for choosing where the action happens'**
  String get editorMapLabel;

  /// Accessible label of the place pin.
  ///
  /// In en, this message translates to:
  /// **'Where the action happens'**
  String get editorPlacePin;

  /// Explains how venue codes work in the editor.
  ///
  /// In en, this message translates to:
  /// **'Participants scan a code that only exists at the venue. After you publish, open the action and show its venue code there. It changes every few minutes, so a photo of it won\'t work later.'**
  String get editorVenueCodeExplainer;

  /// Label of the field describing what the proof must show.
  ///
  /// In en, this message translates to:
  /// **'What Verily should check'**
  String get editorVerifierPromptLabel;

  /// Helper under the verification prompt field.
  ///
  /// In en, this message translates to:
  /// **'Say plainly what the proof must show. Everything in the recording is treated as evidence, never as instructions.'**
  String get editorVerifierPromptHelp;

  /// Shown when editing a saved media proof whose check text is not returned by the server.
  ///
  /// In en, this message translates to:
  /// **'Write this again: saved actions don\'t send it back to the app.'**
  String get editorVerifierPromptRewrite;

  /// Label of the minimum recording length field.
  ///
  /// In en, this message translates to:
  /// **'Shortest (seconds)'**
  String get editorMinSecondsLabel;

  /// Label of the maximum recording length field.
  ///
  /// In en, this message translates to:
  /// **'Longest (seconds)'**
  String get editorMaxSecondsLabel;

  /// Validation for recording lengths.
  ///
  /// In en, this message translates to:
  /// **'Between 3 and 300 seconds, and the longest can\'t be shorter than the shortest.'**
  String get editorSecondsInvalid;

  /// Validation for motion durations.
  ///
  /// In en, this message translates to:
  /// **'Between 1 and {max} seconds, and the longest can\'t be shorter than the shortest.'**
  String editorMotionSecondsInvalid(int max);

  /// Toggle for the live spoken challenge on recordings.
  ///
  /// In en, this message translates to:
  /// **'Ask for a spoken word'**
  String get editorSpokenChallenge;

  /// Explains the spoken challenge.
  ///
  /// In en, this message translates to:
  /// **'Verily gives each person a fresh word to say while recording, so an old or generated clip can\'t pass.'**
  String get editorSpokenChallengeHelp;

  /// Expands advanced verification settings.
  ///
  /// In en, this message translates to:
  /// **'More checking options'**
  String get editorMoreChecks;

  /// Label of the verification policy picker.
  ///
  /// In en, this message translates to:
  /// **'How it\'s checked'**
  String get editorPolicyLabel;

  /// Single-model verification policy.
  ///
  /// In en, this message translates to:
  /// **'One careful check'**
  String get editorPolicySingle;

  /// Model-council verification policy.
  ///
  /// In en, this message translates to:
  /// **'Several independent checks (stricter)'**
  String get editorPolicyCouncil;

  /// Minimum confidence for automatic acceptance.
  ///
  /// In en, this message translates to:
  /// **'How sure the check must be: {percent}%'**
  String editorConfidence(int percent);

  /// Accessible label of the confidence slider.
  ///
  /// In en, this message translates to:
  /// **'How sure the check must be'**
  String get editorConfidenceSemantic;

  /// Label of the movement picker.
  ///
  /// In en, this message translates to:
  /// **'Movement'**
  String get editorMovementLabel;

  /// Label of the repetition target field.
  ///
  /// In en, this message translates to:
  /// **'How many'**
  String get editorMovementTargetLabel;

  /// Validation for repetition targets.
  ///
  /// In en, this message translates to:
  /// **'Between 1 and 1,000.'**
  String get editorMovementTargetInvalid;

  /// Name of the squats movement.
  ///
  /// In en, this message translates to:
  /// **'Squats'**
  String get editorMovementSquats;

  /// Name of the press-ups movement.
  ///
  /// In en, this message translates to:
  /// **'Press-ups'**
  String get editorMovementPressUps;

  /// Name of the sit-ups movement.
  ///
  /// In en, this message translates to:
  /// **'Sit-ups'**
  String get editorMovementSitUps;

  /// Name of the lunges movement.
  ///
  /// In en, this message translates to:
  /// **'Lunges'**
  String get editorMovementLunges;

  /// Name of the star jumps movement.
  ///
  /// In en, this message translates to:
  /// **'Star jumps'**
  String get editorMovementStarJumps;

  /// Name of the burpees movement.
  ///
  /// In en, this message translates to:
  /// **'Burpees'**
  String get editorMovementBurpees;

  /// Name of the high knees movement.
  ///
  /// In en, this message translates to:
  /// **'High knees'**
  String get editorMovementHighKnees;

  /// Name of the lateral raises movement.
  ///
  /// In en, this message translates to:
  /// **'Lateral raises'**
  String get editorMovementLateralRaises;

  /// Name of the biceps curls movement.
  ///
  /// In en, this message translates to:
  /// **'Biceps curls'**
  String get editorMovementBicepsCurls;

  /// Name of the side bends movement.
  ///
  /// In en, this message translates to:
  /// **'Side bends'**
  String get editorMovementSideBends;

  /// Name of the football kick-ups movement.
  ///
  /// In en, this message translates to:
  /// **'Football kick-ups'**
  String get editorMovementFootballKickUps;

  /// Name of the table tennis bounces movement.
  ///
  /// In en, this message translates to:
  /// **'Table tennis bounces'**
  String get editorMovementTableTennisBounces;

  /// Label of the phone-motion picker.
  ///
  /// In en, this message translates to:
  /// **'Movement'**
  String get editorMotionTypeLabel;

  /// Phone motion: a low toss and catch.
  ///
  /// In en, this message translates to:
  /// **'Gentle toss'**
  String get editorMotionToss;

  /// Phone motion: full rotations.
  ///
  /// In en, this message translates to:
  /// **'Full turns'**
  String get editorMotionRotation;

  /// Phone motion: back-and-forth shakes.
  ///
  /// In en, this message translates to:
  /// **'Shakes'**
  String get editorMotionShake;

  /// Phone motion: holding the phone still.
  ///
  /// In en, this message translates to:
  /// **'Hold still'**
  String get editorMotionStillness;

  /// Label of the motion direction picker.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get editorMotionAxisLabel;

  /// Rotation around the vertical axis.
  ///
  /// In en, this message translates to:
  /// **'Spin with the screen facing you'**
  String get editorMotionAxisYaw;

  /// Rotation end over end.
  ///
  /// In en, this message translates to:
  /// **'Flip forward'**
  String get editorMotionAxisPitch;

  /// Rotation side over side.
  ///
  /// In en, this message translates to:
  /// **'Roll side over side'**
  String get editorMotionAxisRoll;

  /// Motion in any direction.
  ///
  /// In en, this message translates to:
  /// **'Any direction'**
  String get editorMotionAxisAny;

  /// Label of the motion repetition field.
  ///
  /// In en, this message translates to:
  /// **'How many times'**
  String get editorMotionRepetitionsLabel;

  /// Validation for motion repetitions.
  ///
  /// In en, this message translates to:
  /// **'Between 1 and {max}.'**
  String editorMotionRepetitionsInvalid(int max);

  /// Safety note shown for the toss motion.
  ///
  /// In en, this message translates to:
  /// **'Ask for a low toss over something soft, caught with both hands. Never ask anyone to throw a phone.'**
  String get editorMotionTossSafety;

  /// Label of the App picker for App-confirmed proof.
  ///
  /// In en, this message translates to:
  /// **'Your App'**
  String get editorAppPickerLabel;

  /// Shown when the creator has no active Apps.
  ///
  /// In en, this message translates to:
  /// **'You have no active Apps yet. Create one under Apps first.'**
  String get editorAppNone;

  /// Shown while the creator's Apps load.
  ///
  /// In en, this message translates to:
  /// **'Loading your Apps…'**
  String get editorAppsLoading;

  /// Shown when the creator's Apps fail to load.
  ///
  /// In en, this message translates to:
  /// **'Your Apps didn\'t load.'**
  String get editorAppsFailed;

  /// Validation when no App is chosen.
  ///
  /// In en, this message translates to:
  /// **'Choose the App that confirms this.'**
  String get editorAppMissing;

  /// Explains the trust label participants see.
  ///
  /// In en, this message translates to:
  /// **'People will see “Confirmed by {appName}”.'**
  String editorAppTrust(String appName);

  /// Section heading for schedule settings.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get editorTimingHeading;

  /// Recurrence: each person does it once.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get editorOnce;

  /// Recurrence: each person can do it once a day.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get editorDaily;

  /// Label of the time zone field.
  ///
  /// In en, this message translates to:
  /// **'Time zone for daily resets'**
  String get editorTimeZoneLabel;

  /// Helper for the time zone field.
  ///
  /// In en, this message translates to:
  /// **'An IANA name, such as Europe/London or America/New_York.'**
  String get editorTimeZoneHelp;

  /// Label of the opening date.
  ///
  /// In en, this message translates to:
  /// **'Opens'**
  String get editorOpensLabel;

  /// Label of the closing date.
  ///
  /// In en, this message translates to:
  /// **'Closes'**
  String get editorClosesLabel;

  /// Shown when no date is set.
  ///
  /// In en, this message translates to:
  /// **'Any time'**
  String get editorDateAnyTime;

  /// Accessible label of the button that clears a date.
  ///
  /// In en, this message translates to:
  /// **'Clear {label}'**
  String editorDateClear(String label);

  /// Validation for dates.
  ///
  /// In en, this message translates to:
  /// **'It has to close after it opens.'**
  String get editorClosesBeforeOpens;

  /// Label of the completion limit field.
  ///
  /// In en, this message translates to:
  /// **'Most completions (optional)'**
  String get editorMaxCompletionsLabel;

  /// Validation for whole numbers.
  ///
  /// In en, this message translates to:
  /// **'A whole number above zero.'**
  String get editorWholeNumberInvalid;

  /// Section heading for the escrowed reward.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get editorRewardHeading;

  /// Toggle that adds an escrowed reward.
  ///
  /// In en, this message translates to:
  /// **'Pay people who do it'**
  String get editorRewardToggle;

  /// Explains rewards in the editor.
  ///
  /// In en, this message translates to:
  /// **'Rewards are paid in USDC from an escrow you fund before publishing. Nobody works for a promise.'**
  String get editorRewardHelp;

  /// Label of the payout amount field.
  ///
  /// In en, this message translates to:
  /// **'Per completion (USDC)'**
  String get editorRewardAmountLabel;

  /// Label of the payout count field.
  ///
  /// In en, this message translates to:
  /// **'Number of payouts'**
  String get editorRewardMaxPayoutsLabel;

  /// Label of the per-person limit field.
  ///
  /// In en, this message translates to:
  /// **'Most payouts one person can earn'**
  String get editorRewardMaxWinsLabel;

  /// Label of the reward end date.
  ///
  /// In en, this message translates to:
  /// **'Payouts end'**
  String get editorRewardEndsLabel;

  /// The refund delay in days.
  ///
  /// In en, this message translates to:
  /// **'Unused funds come back {days} days after it ends'**
  String editorRewardRefundDelay(int days);

  /// Explains the refund delay.
  ///
  /// In en, this message translates to:
  /// **'Time for checks and appeals to finish before the escrow can close.'**
  String get editorRewardRefundDelayHelp;

  /// Accessible label of the refund delay slider.
  ///
  /// In en, this message translates to:
  /// **'Days until unused funds come back'**
  String get editorRewardRefundSemantic;

  /// The total budget the creator funds, such as '50 USDC'.
  ///
  /// In en, this message translates to:
  /// **'You lock {total} in escrow'**
  String editorRewardBudget(String total);

  /// Shown before the budget can be computed.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount and the number of payouts to see the total.'**
  String get editorRewardBudgetIncomplete;

  /// Validation for the payout amount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount above zero with at most 6 decimal places.'**
  String get editorRewardAmountInvalid;

  /// Validation for a too-large payout.
  ///
  /// In en, this message translates to:
  /// **'One payout can be at most 1,000,000 USDC.'**
  String get editorRewardAmountTooLarge;

  /// Validation for the payout count.
  ///
  /// In en, this message translates to:
  /// **'Between 1 and 2,048 payouts.'**
  String get editorRewardMaxPayoutsInvalid;

  /// Validation for the per-person limit.
  ///
  /// In en, this message translates to:
  /// **'Between 1 and {max}.'**
  String editorRewardMaxWinsInvalid(int max);

  /// Validation for a reward ending too soon.
  ///
  /// In en, this message translates to:
  /// **'Give it at least an hour.'**
  String get editorRewardEndTooSoon;

  /// Validation for a reward ending too late.
  ///
  /// In en, this message translates to:
  /// **'A reward can stay open for a year at most.'**
  String get editorRewardEndTooLate;

  /// Shown when reward terms can no longer change.
  ///
  /// In en, this message translates to:
  /// **'Funding has started, so these terms are fixed.'**
  String get editorRewardLocked;

  /// Reward pool status: funding prepared, not confirmed.
  ///
  /// In en, this message translates to:
  /// **'Waiting for escrow'**
  String get editorRewardStatusAwaiting;

  /// Reward pool status: escrow verified by the server.
  ///
  /// In en, this message translates to:
  /// **'Locked in escrow'**
  String get editorRewardStatusFunded;

  /// Reward pool status: ended.
  ///
  /// In en, this message translates to:
  /// **'Payouts ended'**
  String get editorRewardStatusEnded;

  /// Reward pool status: closed.
  ///
  /// In en, this message translates to:
  /// **'Escrow closed'**
  String get editorRewardStatusClosed;

  /// Button that saves the action as a private draft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get editorSave;

  /// Button that saves the draft and opens it as participants see it.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get editorPreview;

  /// Button that publishes the action.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get editorPublish;

  /// Button that funds the reward and then publishes.
  ///
  /// In en, this message translates to:
  /// **'Fund and publish'**
  String get editorFundAndPublish;

  /// Title of the publish confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Publish “{title}”?'**
  String editorPublishConfirmTitle(String title);

  /// Body of the publish confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'It goes live for everyone right away. You can pause it later.'**
  String get editorPublishConfirmBody;

  /// Confirms publishing.
  ///
  /// In en, this message translates to:
  /// **'Publish now'**
  String get editorPublishConfirm;

  /// Shown after saving a draft.
  ///
  /// In en, this message translates to:
  /// **'Draft saved.'**
  String get editorSaved;

  /// Shown after publishing.
  ///
  /// In en, this message translates to:
  /// **'It\'s live.'**
  String get editorPublished;

  /// Shown when publishing stops because the reward is not funded.
  ///
  /// In en, this message translates to:
  /// **'Fund the reward to publish this action.'**
  String get editorFundFirst;

  /// Action status: draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get editorStatusDraft;

  /// Action status: live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get editorStatusLive;

  /// Action status: paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get editorStatusPaused;

  /// Action status: ended.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get editorStatusCompleted;

  /// Title of the venue code sheet.
  ///
  /// In en, this message translates to:
  /// **'Venue code'**
  String get venueCodeTitle;

  /// Explains the venue code to the creator.
  ///
  /// In en, this message translates to:
  /// **'Keep this open at the venue. People scan it with Verily, and it changes every few minutes.'**
  String get venueCodeBody;

  /// Countdown until the venue code changes, such as '4:32'.
  ///
  /// In en, this message translates to:
  /// **'Changes in {time}'**
  String venueCodeChangesIn(String time);

  /// Shown while a new venue code loads.
  ///
  /// In en, this message translates to:
  /// **'Getting a fresh code…'**
  String get venueCodeRefreshing;

  /// Shown when a venue code fails to load.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t get a venue code.'**
  String get venueCodeFailed;

  /// Accessible label of the QR code image.
  ///
  /// In en, this message translates to:
  /// **'Venue code for {title}'**
  String venueCodeImageLabel(String title);

  /// Title of the reward funding sheet.
  ///
  /// In en, this message translates to:
  /// **'Lock the reward in escrow'**
  String get fundingTitle;

  /// Explains escrow funding.
  ///
  /// In en, this message translates to:
  /// **'Before anyone starts, the whole reward goes into an escrow that only verified proof can release. Unused funds come back to you after the action ends.'**
  String get fundingIntro;

  /// Heading for the creator's linked wallet.
  ///
  /// In en, this message translates to:
  /// **'Your payout wallet'**
  String get fundingWalletHeading;

  /// Shown when no payout wallet is linked.
  ///
  /// In en, this message translates to:
  /// **'Link the Solana wallet you\'ll fund the reward from. Refunds come back to it too.'**
  String get fundingWalletNeeded;

  /// Button that links a wallet through Mobile Wallet Adapter.
  ///
  /// In en, this message translates to:
  /// **'Link a wallet'**
  String get fundingLinkWallet;

  /// Shows the linked wallet's shortened address.
  ///
  /// In en, this message translates to:
  /// **'Linked wallet {address}'**
  String fundingWalletLinked(String address);

  /// Shown on platforms that cannot sign the funding transaction.
  ///
  /// In en, this message translates to:
  /// **'Funding needs the Verily Android app and a Solana wallet, such as Phantom or Solflare, on the same phone.'**
  String get fundingNeedsAndroid;

  /// Shown while the linked wallet loads.
  ///
  /// In en, this message translates to:
  /// **'Checking your wallet…'**
  String get fundingLoading;

  /// Shown while the server prepares funding.
  ///
  /// In en, this message translates to:
  /// **'Preparing the escrow…'**
  String get fundingPreparing;

  /// Escrow summary row: payout amount.
  ///
  /// In en, this message translates to:
  /// **'Per completion'**
  String get fundingPerCompletion;

  /// Escrow summary row: number of payouts.
  ///
  /// In en, this message translates to:
  /// **'Payouts'**
  String get fundingPayouts;

  /// Escrow summary row: total budget.
  ///
  /// In en, this message translates to:
  /// **'Total locked'**
  String get fundingTotal;

  /// Escrow summary row: end of payouts.
  ///
  /// In en, this message translates to:
  /// **'Payouts end'**
  String get fundingEnds;

  /// Escrow summary row: when unused funds can be reclaimed.
  ///
  /// In en, this message translates to:
  /// **'Refund available from'**
  String get fundingRefundFrom;

  /// Button that opens the wallet to sign and send the escrow transaction.
  ///
  /// In en, this message translates to:
  /// **'Approve in your wallet'**
  String get fundingApprove;

  /// Shown while the server verifies the escrow from chain state.
  ///
  /// In en, this message translates to:
  /// **'Checking the escrow…'**
  String get fundingConfirming;

  /// Shown when the server reports the reward funded.
  ///
  /// In en, this message translates to:
  /// **'Locked in escrow'**
  String get fundingFunded;

  /// Shown after funding succeeds.
  ///
  /// In en, this message translates to:
  /// **'{total} is in escrow. You can publish the action now.'**
  String fundingFundedBody(String total);

  /// Shown when the server has not verified the escrow.
  ///
  /// In en, this message translates to:
  /// **'The escrow isn\'t confirmed yet. Try again in a moment.'**
  String get fundingNotYet;

  /// Shown when the wallet sent the funding transaction but the server can't see the escrow on chain yet.
  ///
  /// In en, this message translates to:
  /// **'Your wallet sent the escrow, but it isn\'t visible yet. Check again in a moment; there\'s no need to approve it twice.'**
  String get fundingSentNotVisible;

  /// Button that asks the server to look for an escrow the wallet already sent, without signing again.
  ///
  /// In en, this message translates to:
  /// **'Check the escrow again'**
  String get fundingCheckAgain;

  /// Heading of the debug-only local development funding step.
  ///
  /// In en, this message translates to:
  /// **'Development escrow (developer only)'**
  String get fundingDevHeading;

  /// Explains the debug-only development escrow.
  ///
  /// In en, this message translates to:
  /// **'This server uses a local development escrow with no blockchain. Confirming records a development signature, and no money moves.'**
  String get fundingDevBody;

  /// Debug-only button that confirms a development escrow.
  ///
  /// In en, this message translates to:
  /// **'Confirm development escrow'**
  String get fundingDevConfirm;

  /// Shown in release builds when the server has no real escrow.
  ///
  /// In en, this message translates to:
  /// **'Rewards aren\'t available on this server yet.'**
  String get fundingUnavailable;

  /// Wallet failure: no wallet available.
  ///
  /// In en, this message translates to:
  /// **'No Solana wallet answered. Install one that supports Mobile Wallet Adapter and try again.'**
  String get fundingWalletUnavailable;

  /// Wallet failure: declined.
  ///
  /// In en, this message translates to:
  /// **'You declined in your wallet. Nothing was sent.'**
  String get fundingWalletCancelled;

  /// Wallet failure: timeout.
  ///
  /// In en, this message translates to:
  /// **'Your wallet didn\'t answer in time. Try again.'**
  String get fundingWalletTimedOut;

  /// Wallet failure: wrong account.
  ///
  /// In en, this message translates to:
  /// **'That\'s a different wallet account. Approve with the wallet you linked.'**
  String get fundingWalletWrongAccount;

  /// Wallet failure: unusable response.
  ///
  /// In en, this message translates to:
  /// **'Your wallet sent back something we couldn\'t use. Try again.'**
  String get fundingWalletInvalid;

  /// Wallet failure: other.
  ///
  /// In en, this message translates to:
  /// **'The wallet request didn\'t finish. Try again.'**
  String get fundingWalletFailed;

  /// Title of the Create tab.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get hubTitle;

  /// Subtitle of the Create tab.
  ///
  /// In en, this message translates to:
  /// **'Post actions people do in real places.'**
  String get hubSubtitle;

  /// Primary button that starts a new action.
  ///
  /// In en, this message translates to:
  /// **'Post an action'**
  String get hubPostAction;

  /// Heading above the creator's actions.
  ///
  /// In en, this message translates to:
  /// **'Your actions'**
  String get hubActionsHeading;

  /// Shown while the creator's actions load.
  ///
  /// In en, this message translates to:
  /// **'Loading your actions…'**
  String get hubLoading;

  /// Problem title when the creator's actions fail to load.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your actions'**
  String get hubLoadFailedTitle;

  /// Empty state title before the creator has any actions.
  ///
  /// In en, this message translates to:
  /// **'Post your first action'**
  String get hubEmptyTitle;

  /// Empty state body before the creator has any actions.
  ///
  /// In en, this message translates to:
  /// **'Pick a place, choose the proof, and add a reward if you like. People can start as soon as it\'s live.'**
  String get hubEmptyBody;

  /// Action status: not published yet.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get hubStatusDraft;

  /// Action status: published and open to participants.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get hubStatusLive;

  /// Action status: no new attempts until published again.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get hubStatusPaused;

  /// Action status: finished.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get hubStatusCompleted;

  /// How many people completed the action with verified proof.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No verified completions yet} =1{1 verified completion} other{{count} verified completions}}'**
  String hubVerifiedCount(int count);

  /// Shown on an action whose escrowed reward has not been funded.
  ///
  /// In en, this message translates to:
  /// **'The reward needs funding before this action can go live.'**
  String get hubRewardNeedsFunding;

  /// Shown on an action whose reward period ended.
  ///
  /// In en, this message translates to:
  /// **'The reward has ended. Anything unclaimed returns to you after the refund delay.'**
  String get hubRewardEnded;

  /// Shown on an action whose escrow has been closed.
  ///
  /// In en, this message translates to:
  /// **'The reward is closed.'**
  String get hubRewardClosed;

  /// Confirmation after the server verified the reward's escrow.
  ///
  /// In en, this message translates to:
  /// **'Your reward is in escrow.'**
  String get hubRewardFunded;

  /// Button that locks an action's reward in escrow.
  ///
  /// In en, this message translates to:
  /// **'Fund reward'**
  String get hubFund;

  /// Button that makes a draft or paused action live.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get hubPublish;

  /// Button that stops new attempts on a live action.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get hubPause;

  /// Button that shows the QR code people scan at the venue.
  ///
  /// In en, this message translates to:
  /// **'Show venue code'**
  String get hubVenueCode;

  /// Button that opens the action editor.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get hubEdit;

  /// Button that opens the action as participants see it.
  ///
  /// In en, this message translates to:
  /// **'View as a participant'**
  String get hubView;

  /// Confirmation after publishing an action.
  ///
  /// In en, this message translates to:
  /// **'{title} is live.'**
  String hubPublished(String title);

  /// Confirmation after pausing an action.
  ///
  /// In en, this message translates to:
  /// **'{title} is paused. No one can start it until you publish it again.'**
  String hubPaused(String title);

  /// Heading of the Verily Apps summary on the Create tab.
  ///
  /// In en, this message translates to:
  /// **'Your Apps'**
  String get hubAppsHeading;

  /// Apps summary shown before the creator's Apps load.
  ///
  /// In en, this message translates to:
  /// **'Let your own software confirm actions for you.'**
  String get hubAppsIntro;

  /// How many active Verily Apps the creator has.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Register an App to confirm actions from your own software.} =1{1 App confirms actions for you.} other{{count} Apps confirm actions for you.}}'**
  String hubAppsBody(int count);

  /// Button that opens the Verily Apps page.
  ///
  /// In en, this message translates to:
  /// **'Manage Apps'**
  String get hubAppsOpen;

  /// Heading of the appeals link on the Create tab.
  ///
  /// In en, this message translates to:
  /// **'Appeals on your actions'**
  String get hubAppealsHeading;

  /// Explains the appeals page.
  ///
  /// In en, this message translates to:
  /// **'When someone contests a rejected proof on one of your actions, you decide here.'**
  String get hubAppealsBody;

  /// Button that opens the appeals page.
  ///
  /// In en, this message translates to:
  /// **'Open appeals'**
  String get hubAppealsOpen;

  /// Title of the Verily Apps page.
  ///
  /// In en, this message translates to:
  /// **'Your Apps'**
  String get appsTitle;

  /// Subtitle of the Verily Apps page.
  ///
  /// In en, this message translates to:
  /// **'Software that confirms actions for you'**
  String get appsSubtitle;

  /// Shown while the creator's Apps load.
  ///
  /// In en, this message translates to:
  /// **'Loading your Apps…'**
  String get appsLoading;

  /// Problem title when Apps fail to load.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your Apps'**
  String get appsLoadFailedTitle;

  /// Heading above the list of Apps.
  ///
  /// In en, this message translates to:
  /// **'Registered Apps'**
  String get appsListHeading;

  /// Empty state title before any App is registered.
  ///
  /// In en, this message translates to:
  /// **'No Apps yet'**
  String get appsEmptyTitle;

  /// Empty state body before any App is registered.
  ///
  /// In en, this message translates to:
  /// **'Register one above to get its key.'**
  String get appsEmptyBody;

  /// Heading that introduces Verily Apps.
  ///
  /// In en, this message translates to:
  /// **'What\'s a Verily App?'**
  String get appsIntroTitle;

  /// Explains what a Verily App is and how participants see it.
  ///
  /// In en, this message translates to:
  /// **'An App is your own software, like a booking system or a game, that tells Verily when someone did an action. Participants see that your App confirmed it: Verily takes your App\'s word and doesn\'t check the act itself.'**
  String get appsIntroBody;

  /// Heading of the form that registers an App.
  ///
  /// In en, this message translates to:
  /// **'Register an App'**
  String get appsRegisterHeading;

  /// Label of the App name field.
  ///
  /// In en, this message translates to:
  /// **'App name'**
  String get appsNameLabel;

  /// Example App name.
  ///
  /// In en, this message translates to:
  /// **'e.g. Sunrise Run Club'**
  String get appsNameHint;

  /// Validation message when the App name is empty.
  ///
  /// In en, this message translates to:
  /// **'Name your App.'**
  String get appsNameRequired;

  /// Validation message when the App name is too long.
  ///
  /// In en, this message translates to:
  /// **'Keep the name to 80 characters or fewer.'**
  String get appsNameTooLong;

  /// Label of the App website field.
  ///
  /// In en, this message translates to:
  /// **'Website (optional)'**
  String get appsWebsiteLabel;

  /// Example App website.
  ///
  /// In en, this message translates to:
  /// **'https://example.com'**
  String get appsWebsiteHint;

  /// Validation message for an invalid App website.
  ///
  /// In en, this message translates to:
  /// **'Use a full https:// address.'**
  String get appsWebsiteInvalid;

  /// Button that registers a new App.
  ///
  /// In en, this message translates to:
  /// **'Register App'**
  String get appsRegister;

  /// Shown when registering an App fails.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t register that App. Check you don\'t already have an active App with that name, then try again.'**
  String get appsRegisterFailed;

  /// App status: its keys work.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get appsStatusActive;

  /// App status: its keys no longer work.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get appsStatusRevoked;

  /// How many actions an App confirms.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No actions use it yet} =1{1 action uses it} other{{count} actions use it}}'**
  String appsBoundActions(int count);

  /// How many of an App's keys still work.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No active keys} =1{1 active key} other{{count} active keys}}'**
  String appsActiveKeys(int count);

  /// Title of the dialog that shows a new App key once.
  ///
  /// In en, this message translates to:
  /// **'Save your App key'**
  String get appsKeyTitle;

  /// Explains a new App key.
  ///
  /// In en, this message translates to:
  /// **'{appName} uses this key to confirm actions. Keep it on your server, never in an app people download.'**
  String appsKeyBody(String appName);

  /// Warns that a new key is shown once.
  ///
  /// In en, this message translates to:
  /// **'Verily shows this key only once. If you lose it, make a new key and revoke this one.'**
  String get appsKeyWarning;

  /// Label above the new App key.
  ///
  /// In en, this message translates to:
  /// **'App key'**
  String get appsKeyLabel;

  /// Button that copies the new App key.
  ///
  /// In en, this message translates to:
  /// **'Copy key'**
  String get appsKeyCopy;

  /// Shown after the new App key was copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get appsKeyCopied;

  /// Button that closes the new key dialog.
  ///
  /// In en, this message translates to:
  /// **'I\'ve saved it'**
  String get appsKeySaved;

  /// Button that returns to the Apps list.
  ///
  /// In en, this message translates to:
  /// **'Back to your Apps'**
  String get appsBackToApps;

  /// Shown on a revoked App's page.
  ///
  /// In en, this message translates to:
  /// **'This App is revoked. Its keys no longer work and its actions are paused.'**
  String get appsRevokedNotice;

  /// Heading of an App's keys.
  ///
  /// In en, this message translates to:
  /// **'Keys'**
  String get appsKeysHeading;

  /// Button that issues another key for an App.
  ///
  /// In en, this message translates to:
  /// **'New key'**
  String get appsNewKey;

  /// Explains why a new key cannot be made.
  ///
  /// In en, this message translates to:
  /// **'An App can have two working keys. Revoke one to make another.'**
  String get appsKeyLimit;

  /// When an App key was made.
  ///
  /// In en, this message translates to:
  /// **'Made {date}'**
  String appsKeyCreated(String date);

  /// When an App key was last used.
  ///
  /// In en, this message translates to:
  /// **'Last used {date}'**
  String appsKeyLastUsed(String date);

  /// Shown for an App key that has never been used.
  ///
  /// In en, this message translates to:
  /// **'Not used yet'**
  String get appsKeyNeverUsed;

  /// When an App key was revoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked {date}'**
  String appsKeyRevokedOn(String date);

  /// Accessible label of the button that revokes one key.
  ///
  /// In en, this message translates to:
  /// **'Revoke {key}'**
  String appsRevokeKeyTooltip(String key);

  /// Title of the dialog that confirms revoking a key.
  ///
  /// In en, this message translates to:
  /// **'Revoke this key?'**
  String get appsRevokeKeyTitle;

  /// Explains revoking a key.
  ///
  /// In en, this message translates to:
  /// **'Requests sent with {key} stop working right away. Any other key keeps working.'**
  String appsRevokeKeyBody(String key);

  /// Confirms revoking a key or an App.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get appsRevokeConfirm;

  /// Button that revokes an App.
  ///
  /// In en, this message translates to:
  /// **'Revoke this App'**
  String get appsRevokeApp;

  /// Title of the dialog that confirms revoking an App.
  ///
  /// In en, this message translates to:
  /// **'Revoke {appName}?'**
  String appsRevokeAppTitle(String appName);

  /// Explains revoking an App.
  ///
  /// In en, this message translates to:
  /// **'Its keys stop working right away, and every action it confirms is paused. This can\'t be undone.'**
  String get appsRevokeAppBody;

  /// Heading of the example request.
  ///
  /// In en, this message translates to:
  /// **'Send a confirmation'**
  String get appsGuideHeading;

  /// Explains the example confirmation request.
  ///
  /// In en, this message translates to:
  /// **'When someone does the action in your App, send this from your server. The subject is the link code the participant copies from the action in Verily.'**
  String get appsGuideBody;

  /// Explains the responses to a confirmation.
  ///
  /// In en, this message translates to:
  /// **'Verily answers accepted, duplicate, or rejected with a reason. Sending the same eventId again is safe.'**
  String get appsGuideResponses;

  /// Button that copies the example request.
  ///
  /// In en, this message translates to:
  /// **'Copy example'**
  String get appsGuideCopy;

  /// Shown after the example request was copied.
  ///
  /// In en, this message translates to:
  /// **'Example copied'**
  String get appsGuideCopied;

  /// Heading of an App's confirmation log.
  ///
  /// In en, this message translates to:
  /// **'Confirmations'**
  String get appsConfirmationsHeading;

  /// Shown while confirmations load.
  ///
  /// In en, this message translates to:
  /// **'Loading confirmations…'**
  String get appsConfirmationsLoading;

  /// Shown when confirmations fail to load.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load confirmations'**
  String get appsConfirmationsFailed;

  /// Shown when an App has sent no confirmations.
  ///
  /// In en, this message translates to:
  /// **'No confirmations yet. They show up here as your App sends them.'**
  String get appsConfirmationsEmpty;

  /// Button that loads older confirmations.
  ///
  /// In en, this message translates to:
  /// **'Load older'**
  String get appsConfirmationsMore;

  /// Confirmation outcome: Verily counted it.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get appsConfirmationAccepted;

  /// Confirmation outcome: Verily did not count it.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get appsConfirmationRejected;

  /// The confirmation's event id and action key.
  ///
  /// In en, this message translates to:
  /// **'Event {eventId} for {actionKey}'**
  String appsConfirmationEvent(String eventId, String actionKey);

  /// When Verily received a confirmation.
  ///
  /// In en, this message translates to:
  /// **'Received {date}'**
  String appsConfirmationReceived(String date);

  /// The participant's attempt status after a confirmation.
  ///
  /// In en, this message translates to:
  /// **'Attempt: {status}'**
  String appsConfirmationAttempt(String status);

  /// The machine-readable reason the App's server received, for developers matching logs.
  ///
  /// In en, this message translates to:
  /// **'Response code {code}'**
  String appsConfirmationCode(String code);

  /// Reason: the confirmation counted.
  ///
  /// In en, this message translates to:
  /// **'Counted toward the attempt'**
  String get appsReasonConfirmed;

  /// Reason: the attempt for this period was already finished.
  ///
  /// In en, this message translates to:
  /// **'Already counted for this period'**
  String get appsReasonAlreadyComplete;

  /// Reason: the action key matched no live action.
  ///
  /// In en, this message translates to:
  /// **'No live action has that key'**
  String get appsReasonUnknownAction;

  /// Reason: the subject matched no linked participant.
  ///
  /// In en, this message translates to:
  /// **'No participant has that link code'**
  String get appsReasonUnknownSubject;

  /// Reason: occurredAt was outside the accepted range.
  ///
  /// In en, this message translates to:
  /// **'The time was too far from now'**
  String get appsReasonOutOfRange;

  /// Reason: occurredAt was outside the action's open dates.
  ///
  /// In en, this message translates to:
  /// **'It happened outside the action\'s dates'**
  String get appsReasonOutsideWindow;

  /// Reason: occurredAt was outside the current daily period.
  ///
  /// In en, this message translates to:
  /// **'It happened outside the current period'**
  String get appsReasonOutsidePeriod;

  /// Reason: the action is paused, full, or held.
  ///
  /// In en, this message translates to:
  /// **'The action isn\'t taking proof right now'**
  String get appsReasonUnavailable;

  /// Reason fallback for a code the app does not know.
  ///
  /// In en, this message translates to:
  /// **'Not counted'**
  String get appsReasonOther;

  /// Title of the Do tab.
  ///
  /// In en, this message translates to:
  /// **'Things to do'**
  String get doTitle;

  /// Subtitle of the Do tab.
  ///
  /// In en, this message translates to:
  /// **'Real actions in real places. Prove them on your phone.'**
  String get doSubtitle;

  /// Do tab toggle: show actions as a list.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get doViewList;

  /// Do tab toggle: show actions on a map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get doViewMap;

  /// Do filter: every live action.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get doFilterAll;

  /// Do filter: actions with a place near you.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get doFilterNearby;

  /// Do filter: actions you prove by being somewhere.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get doFilterPlace;

  /// Do filter: phone motion or reps counted on camera.
  ///
  /// In en, this message translates to:
  /// **'Movement'**
  String get doFilterMovement;

  /// Do filter: actions you prove with a code at the venue.
  ///
  /// In en, this message translates to:
  /// **'Venue codes'**
  String get doFilterVenueCode;

  /// Do filter: actions a Verily App confirms.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get doFilterApps;

  /// Proof kind: be at the action's place.
  ///
  /// In en, this message translates to:
  /// **'Be there'**
  String get doProofPlace;

  /// Proof kind: scan the code the venue shows.
  ///
  /// In en, this message translates to:
  /// **'Venue code'**
  String get doProofVenueCode;

  /// Proof kind: a live video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get doProofVideo;

  /// Proof kind: a video where the phone counts repetitions.
  ///
  /// In en, this message translates to:
  /// **'Reps on camera'**
  String get doProofMovement;

  /// Proof kind: a live photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get doProofPhoto;

  /// Proof kind: a live audio recording.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get doProofAudio;

  /// Proof kind: moving the phone in a pattern.
  ///
  /// In en, this message translates to:
  /// **'Phone motion'**
  String get doProofMotion;

  /// Proof kind: a Verily App confirms the action.
  ///
  /// In en, this message translates to:
  /// **'App confirms'**
  String get doProofApp;

  /// Who posted an action. Name is their public display name.
  ///
  /// In en, this message translates to:
  /// **'by {name}'**
  String doCreatorBy(String name);

  /// Your attempt's status on an action card, such as 'You: Checking your proof'.
  ///
  /// In en, this message translates to:
  /// **'You: {status}'**
  String doYourAttempt(String status);

  /// Distance to an action's place, under a kilometre.
  ///
  /// In en, this message translates to:
  /// **'{meters} m away'**
  String doDistanceMeters(int meters);

  /// Distance to an action's place in kilometres, already formatted.
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String doDistanceKilometers(String km);

  /// Shown while the Do feed loads.
  ///
  /// In en, this message translates to:
  /// **'Finding actions…'**
  String get doLoading;

  /// Title when the Do feed fails to load.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load actions'**
  String get doLoadFailedTitle;

  /// Title when there are no live actions.
  ///
  /// In en, this message translates to:
  /// **'Nothing to do here yet'**
  String get doEmptyTitle;

  /// Body when there are no live actions.
  ///
  /// In en, this message translates to:
  /// **'When someone posts an action, it shows up here. You could post the first one.'**
  String get doEmptyBody;

  /// Button from an empty Do feed to the action editor.
  ///
  /// In en, this message translates to:
  /// **'Post an action'**
  String get doPostAction;

  /// Title when a filter hides every action.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches that yet'**
  String get doFilterEmptyTitle;

  /// Body when a filter hides every action.
  ///
  /// In en, this message translates to:
  /// **'Try another filter, or see everything.'**
  String get doFilterEmptyBody;

  /// Button that clears the Do filter.
  ///
  /// In en, this message translates to:
  /// **'Show all actions'**
  String get doShowAll;

  /// Title when no live actions have a place near the person.
  ///
  /// In en, this message translates to:
  /// **'Nothing nearby yet'**
  String get doNearbyEmptyTitle;

  /// Body when no live actions have a place near the person.
  ///
  /// In en, this message translates to:
  /// **'No live actions have a place near you right now.'**
  String get doNearbyEmptyBody;

  /// Title of the explanation shown before reading the location.
  ///
  /// In en, this message translates to:
  /// **'Find actions near you'**
  String get doNearbyExplainTitle;

  /// Explains why Nearby reads the location and what happens to it.
  ///
  /// In en, this message translates to:
  /// **'We use your approximate location once to find actions near you. Verily rounds it and never stores it.'**
  String get doNearbyExplainBody;

  /// Declines sharing the location for Nearby.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get doNearbyNotNow;

  /// Agrees to share the approximate location for Nearby.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get doNearbyContinue;

  /// Reads the approximate location for Nearby.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get doNearbyUseLocation;

  /// Shown while the approximate location is read.
  ///
  /// In en, this message translates to:
  /// **'Finding where you are…'**
  String get doNearbyLocating;

  /// Title after the person chose not to share their location.
  ///
  /// In en, this message translates to:
  /// **'Nearby needs your location'**
  String get doNearbyDeclinedTitle;

  /// Body after the person chose not to share their location.
  ///
  /// In en, this message translates to:
  /// **'Share your approximate location to see actions close to you. Everything else works without it.'**
  String get doNearbyDeclinedBody;

  /// Title when location permission was permanently denied.
  ///
  /// In en, this message translates to:
  /// **'Location is off for Verily'**
  String get doNearbyBlockedTitle;

  /// Body when location permission was permanently denied.
  ///
  /// In en, this message translates to:
  /// **'Turn location on for Verily in your phone\'s settings to see nearby actions.'**
  String get doNearbyBlockedBody;

  /// Opens the system settings for Verily.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get doOpenSettings;

  /// Title when the device's location services are off.
  ///
  /// In en, this message translates to:
  /// **'Location services are off'**
  String get doNearbyServicesOffTitle;

  /// Body when the device's location services are off.
  ///
  /// In en, this message translates to:
  /// **'Turn on location services, then try again.'**
  String get doNearbyServicesOffBody;

  /// Title when location permission was denied this time.
  ///
  /// In en, this message translates to:
  /// **'Location wasn\'t allowed'**
  String get doNearbyDeniedTitle;

  /// Body when location permission was denied this time.
  ///
  /// In en, this message translates to:
  /// **'Allow location when your phone asks to see actions near you.'**
  String get doNearbyDeniedBody;

  /// Title when no location arrived in time.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find you'**
  String get doNearbyTimedOutTitle;

  /// Body when no location arrived in time.
  ///
  /// In en, this message translates to:
  /// **'Your phone didn\'t share a location in time. Try again, ideally near a window.'**
  String get doNearbyTimedOutBody;

  /// Title when none of the shown actions has a place.
  ///
  /// In en, this message translates to:
  /// **'No places to show'**
  String get doMapEmptyTitle;

  /// Body when none of the shown actions has a place.
  ///
  /// In en, this message translates to:
  /// **'None of these actions has a place on the map. Switch to the list to see them.'**
  String get doMapEmptyBody;

  /// Accessible label of the Do map.
  ///
  /// In en, this message translates to:
  /// **'Map of actions with a place'**
  String get doMapLabel;

  /// Accessible label of an action's place map.
  ///
  /// In en, this message translates to:
  /// **'Map of {place}'**
  String actionPlaceMapLabel(String place);

  /// Accessible label of the hatched radius on the place map.
  ///
  /// In en, this message translates to:
  /// **'The {meters} m area around the pin'**
  String actionPlaceRadiusLabel(int meters);

  /// How close the participant must be to the place.
  ///
  /// In en, this message translates to:
  /// **'Be within {meters} m of the pin'**
  String actionPlaceRadius(int meters);

  /// Title of the venue code scanner.
  ///
  /// In en, this message translates to:
  /// **'Scan the venue code'**
  String get actionScanTitle;

  /// Hint under the venue code scanner.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the code the venue shows. It changes every few minutes.'**
  String get actionScanHint;

  /// Shown when camera permission is denied in the scanner.
  ///
  /// In en, this message translates to:
  /// **'Verily needs the camera to read the venue code. Allow it in your phone\'s settings.'**
  String get actionScanCameraDenied;

  /// Shown when the scanner's camera cannot start.
  ///
  /// In en, this message translates to:
  /// **'The camera isn\'t available right now. Try again in a moment.'**
  String get actionScanUnavailable;

  /// How many repetitions a movement step needs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 rep} other{{count} reps}}'**
  String actionProofReps(int count);

  /// Marks a step that is not required.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get actionProofOptional;

  /// Accessible state of a step with no proof yet.
  ///
  /// In en, this message translates to:
  /// **'Not done yet'**
  String get actionProofStateOpen;

  /// Accessible state of a step being captured or sent.
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get actionProofStateWorking;

  /// Accessible state of a step whose proof was accepted.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionProofStateAccepted;

  /// Title of a verified attempt.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get actionVerifiedTitle;

  /// Body of a verified attempt. Never claims the proof shows something is real.
  ///
  /// In en, this message translates to:
  /// **'Verily checked your proof and it passed.'**
  String get actionVerifiedBody;

  /// Button to Me, where a payout wallet can be linked.
  ///
  /// In en, this message translates to:
  /// **'Add a wallet'**
  String get actionAddWallet;

  /// Explains a payout held for review.
  ///
  /// In en, this message translates to:
  /// **'Bigger rewards get a quick look from a person before they\'re sent.'**
  String get actionPayoutHeldBody;

  /// Fallback name for a Verily App with no name.
  ///
  /// In en, this message translates to:
  /// **'the App'**
  String get actionAppUnnamed;

  /// Shown when the App confirmed the participant's step.
  ///
  /// In en, this message translates to:
  /// **'{appName} confirmed this'**
  String actionAppConfirmed(String appName);

  /// Explains an App-confirmed step and what Verily does and does not check.
  ///
  /// In en, this message translates to:
  /// **'{appName} confirms this step itself. Give it your link code so it knows it\'s you. Verily doesn\'t check the act, only that {appName} said so.'**
  String actionAppBody(String appName);

  /// Shown when the confirming App was revoked.
  ///
  /// In en, this message translates to:
  /// **'{appName} isn\'t confirming actions any more, so this one can\'t be done right now.'**
  String actionAppUnavailable(String appName);

  /// Opens the participant's link code for an App.
  ///
  /// In en, this message translates to:
  /// **'Show my link code'**
  String get actionLinkCodeShow;

  /// Title of the link code dialog.
  ///
  /// In en, this message translates to:
  /// **'Your code for {appName}'**
  String actionLinkCodeTitle(String appName);

  /// Explains what to do with the link code.
  ///
  /// In en, this message translates to:
  /// **'Paste this into {appName} so it can confirm you.'**
  String actionLinkCodeBody(String appName);

  /// Copies the link code.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get actionLinkCodeCopy;

  /// Confirms the link code was copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get actionLinkCodeCopied;

  /// Explains the privacy of pairwise link codes.
  ///
  /// In en, this message translates to:
  /// **'Each App gets a different code, so Apps can\'t compare notes about you. {appName} never sees your account.'**
  String actionLinkCodePrivacy(String appName);

  /// Fallback body of a rejected attempt.
  ///
  /// In en, this message translates to:
  /// **'This proof wasn\'t accepted.'**
  String get actionRejectedBody;

  /// Invites a participant to appeal a rejection.
  ///
  /// In en, this message translates to:
  /// **'Think this was a mistake? You can ask for a second look once. A person reads it.'**
  String get actionAppealInvite;

  /// Opens the appeal form.
  ///
  /// In en, this message translates to:
  /// **'Ask for a second look'**
  String get actionAppealOpen;

  /// Title of the appeal form.
  ///
  /// In en, this message translates to:
  /// **'Ask for a second look'**
  String get actionAppealTitle;

  /// Explains the appeal form.
  ///
  /// In en, this message translates to:
  /// **'Tell the action\'s creator what happened. Be specific; you can do this once.'**
  String get actionAppealBody;

  /// Label of the appeal reason field.
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get actionAppealReasonLabel;

  /// Hint for the appeal reason field.
  ///
  /// In en, this message translates to:
  /// **'At least 10 characters'**
  String get actionAppealReasonHint;

  /// Sends the appeal.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get actionAppealSubmit;

  /// Status of a pending appeal.
  ///
  /// In en, this message translates to:
  /// **'You asked for a second look. A person will read it.'**
  String get actionAppealPending;

  /// Status of an accepted appeal.
  ///
  /// In en, this message translates to:
  /// **'Your appeal was accepted.'**
  String get actionAppealAccepted;

  /// Status of a rejected appeal.
  ///
  /// In en, this message translates to:
  /// **'Your appeal was read and the decision stands.'**
  String get actionAppealRejected;

  /// Shown while an action page loads.
  ///
  /// In en, this message translates to:
  /// **'Opening the action…'**
  String get actionLoading;

  /// Title when an action page fails to load.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t open this action'**
  String get actionLoadFailedTitle;

  /// Title when a linked action cannot be found.
  ///
  /// In en, this message translates to:
  /// **'This action isn\'t here'**
  String get actionNotFoundTitle;

  /// Accessible label of the back button.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// Shown when the device could not produce the integrity proof the server requires.
  ///
  /// In en, this message translates to:
  /// **'This phone couldn\'t vouch for the capture. Check your phone is up to date, then try again.'**
  String get actionIntegrityUnavailable;

  /// Shown when the device could not sign the capture.
  ///
  /// In en, this message translates to:
  /// **'This phone couldn\'t sign the capture. Try again; if it keeps happening, this phone can\'t be used for this action.'**
  String get actionSignatureUnavailable;

  /// Shown when a media upload failed.
  ///
  /// In en, this message translates to:
  /// **'Your proof didn\'t finish uploading. It\'s still on your phone; try again.'**
  String get actionUploadFailed;

  /// Title when an action is paused, finished, or unpublished.
  ///
  /// In en, this message translates to:
  /// **'This action isn\'t live'**
  String get actionNotLiveTitle;

  /// Body when an action is paused, finished, or unpublished.
  ///
  /// In en, this message translates to:
  /// **'It\'s paused, finished, or not published yet, so it can\'t be started.'**
  String get actionNotLiveBody;

  /// Heading of the requirement checklist before starting.
  ///
  /// In en, this message translates to:
  /// **'What you\'ll prove'**
  String get actionProofHeading;

  /// Heading of the requirement checklist after starting.
  ///
  /// In en, this message translates to:
  /// **'Your proof'**
  String get actionYourProof;

  /// Explains live capture before starting.
  ///
  /// In en, this message translates to:
  /// **'Every step is captured live on your phone when you do it. There\'s no upload button.'**
  String get actionProofIntro;

  /// Tells the participant how to work through the checklist.
  ///
  /// In en, this message translates to:
  /// **'Tap a step to do it.'**
  String get actionProofTapHint;

  /// Starts an attempt.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get actionStart;

  /// Finishes an attempt whose proof is all accepted.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get actionFinish;

  /// Shown while an attempt is being finished.
  ///
  /// In en, this message translates to:
  /// **'Wrapping up…'**
  String get actionFinishing;

  /// Explains that media proof is being checked.
  ///
  /// In en, this message translates to:
  /// **'This usually takes a minute or two. You can leave this page; Verily keeps checking and updates your attempt.'**
  String get actionCheckingBody;

  /// Explains review by a person.
  ///
  /// In en, this message translates to:
  /// **'A person will look at your proof. You\'ll see the result here and in Me.'**
  String get actionReviewBody;

  /// Explains a value review by a person.
  ///
  /// In en, this message translates to:
  /// **'Bigger rewards get a quick look from a person. You\'ll see the result here and in Me.'**
  String get actionReviewValueBody;

  /// Explains that the action reached its limit.
  ///
  /// In en, this message translates to:
  /// **'Everyone this action could take has already finished it.'**
  String get actionCapacityBody;

  /// Shown when a step's proof was accepted.
  ///
  /// In en, this message translates to:
  /// **'Got it. That step is done.'**
  String get actionProofAccepted;

  /// Shown when a step's proof went to a person.
  ///
  /// In en, this message translates to:
  /// **'A person will check that step.'**
  String get actionProofWithReviewer;

  /// Fallback when a step's proof was rejected.
  ///
  /// In en, this message translates to:
  /// **'That proof wasn\'t accepted.'**
  String get actionProofNotAccepted;

  /// Shown when media proof was uploaded and queued for checking.
  ///
  /// In en, this message translates to:
  /// **'Sent. Verily is checking it now.'**
  String get actionProofSent;

  /// Shown when location services are off during a place step.
  ///
  /// In en, this message translates to:
  /// **'Turn on location services so Verily can check you\'re at the place.'**
  String get actionLocationServicesOff;

  /// Shown when location was denied during a place step.
  ///
  /// In en, this message translates to:
  /// **'Verily needs your location for this step. Allow it when asked and try again.'**
  String get actionLocationDenied;

  /// Shown when location is permanently denied during a place step.
  ///
  /// In en, this message translates to:
  /// **'Location is off for Verily. Turn it on in Settings to do this step.'**
  String get actionLocationBlocked;

  /// Shown when no precise location arrived in time.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t get a precise location. Step outside or near a window and try again.'**
  String get actionLocationTimedOut;

  /// Shown when the participant reached the per-person limit.
  ///
  /// In en, this message translates to:
  /// **'You\'ve earned the most this action allows'**
  String get actionRewardCapReached;

  /// How many rewards one person can earn.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{One reward per person} other{Up to {count} per person}}'**
  String actionRewardPerPerson(int count);

  /// Title of the creator's panel on their own action.
  ///
  /// In en, this message translates to:
  /// **'This is your action'**
  String get actionCreatorTitle;

  /// Creator panel: draft status.
  ///
  /// In en, this message translates to:
  /// **'It\'s a draft, so nobody can see it yet.'**
  String get actionCreatorDraft;

  /// Creator panel: live status.
  ///
  /// In en, this message translates to:
  /// **'It\'s live. This is what people see.'**
  String get actionCreatorLive;

  /// Creator panel: paused status.
  ///
  /// In en, this message translates to:
  /// **'It\'s paused, so nobody can start it.'**
  String get actionCreatorPaused;

  /// Creator panel: completed status.
  ///
  /// In en, this message translates to:
  /// **'It\'s finished.'**
  String get actionCreatorCompleted;

  /// Opens the action editor.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionCreatorEdit;

  /// Shows the rotating venue code people scan.
  ///
  /// In en, this message translates to:
  /// **'Show venue code'**
  String get actionCreatorShowVenueCode;

  /// Shows one venue code when an action has several.
  ///
  /// In en, this message translates to:
  /// **'Show code for {title}'**
  String actionCreatorShowVenueCodeFor(String title);

  /// Shown on the proof review when the recording is longer than the action allows; sending is disabled.
  ///
  /// In en, this message translates to:
  /// **'This recording runs past the {limit} limit. Retake a shorter one.'**
  String captureReviewTooLong(String limit);

  /// Live status while a recorded phone-motion trace is being sent.
  ///
  /// In en, this message translates to:
  /// **'Sending your motion…'**
  String get captureMotionSending;

  /// Name of the squats movement.
  ///
  /// In en, this message translates to:
  /// **'Squats'**
  String get movementNameSquats;

  /// A counted squats target, such as "10 squats".
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 squat} other{{count} squats}}'**
  String movementTargetSquats(int count);

  /// Where to put the phone so the camera can count squats.
  ///
  /// In en, this message translates to:
  /// **'Side view · keep your hips, knees and ankles in frame'**
  String get movementGuideSquats;

  /// Live instruction while doing squats.
  ///
  /// In en, this message translates to:
  /// **'Bend your knees'**
  String get movementCueSquats;

  /// Name of the press ups movement.
  ///
  /// In en, this message translates to:
  /// **'Press-ups'**
  String get movementNamePressUps;

  /// A counted press ups target, such as "10 squats".
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 press-up} other{{count} press-ups}}'**
  String movementTargetPressUps(int count);

  /// Where to put the phone so the camera can count press ups.
  ///
  /// In en, this message translates to:
  /// **'Side view · set the phone low, near the floor'**
  String get movementGuidePressUps;

  /// Live instruction while doing press ups.
  ///
  /// In en, this message translates to:
  /// **'Lower your chest'**
  String get movementCuePressUps;

  /// Name of the sit ups movement.
  ///
  /// In en, this message translates to:
  /// **'Sit-ups'**
  String get movementNameSitUps;

  /// A counted sit ups target, such as "10 squats".
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sit-up} other{{count} sit-ups}}'**
  String movementTargetSitUps(int count);

  /// Where to put the phone so the camera can count sit ups.
  ///
  /// In en, this message translates to:
  /// **'Side view · set the phone low and lie with knees bent'**
  String get movementGuideSitUps;

  /// Live instruction while doing sit ups.
  ///
  /// In en, this message translates to:
  /// **'Lift your torso'**
  String get movementCueSitUps;

  /// Name of the lunges movement.
  ///
  /// In en, this message translates to:
  /// **'Lunges'**
  String get movementNameLunges;

  /// A counted lunges target, such as "10 squats".
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 lunge} other{{count} lunges}}'**
  String movementTargetLunges(int count);

  /// Where to put the phone so the camera can count lunges.
  ///
  /// In en, this message translates to:
  /// **'Side view · step back so both legs are in frame'**
  String get movementGuideLunges;

  /// Live instruction while doing lunges.
  ///
  /// In en, this message translates to:
  /// **'Lower your back knee'**
  String get movementCueLunges;

  /// Name of the star jumps movement.
  ///
  /// In en, this message translates to:
  /// **'Star jumps'**
  String get movementNameStarJumps;

  /// A counted star jumps target, such as "10 squats".
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 star jump} other{{count} star jumps}}'**
  String movementTargetStarJumps(int count);

  /// Where to put the phone so the camera can count star jumps.
  ///
  /// In en, this message translates to:
  /// **'Front view · leave room above and beside you'**
  String get movementGuideStarJumps;

  /// Live instruction while doing star jumps.
  ///
  /// In en, this message translates to:
  /// **'Jump wide, arms up'**
  String get movementCueStarJumps;

  /// Name of the burpees movement.
  ///
  /// In en, this message translates to:
  /// **'Burpees'**
  String get movementNameBurpees;

  /// A counted burpees target, such as "10 squats".
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 burpee} other{{count} burpees}}'**
  String movementTargetBurpees(int count);

  /// Where to put the phone so the camera can count burpees.
  ///
  /// In en, this message translates to:
  /// **'Side view · keep your whole body and the floor in frame'**
  String get movementGuideBurpees;

  /// Live instruction while doing burpees.
  ///
  /// In en, this message translates to:
  /// **'Crouch down'**
  String get movementCueBurpees;

  /// Name of the high knees movement.
  ///
  /// In en, this message translates to:
  /// **'High knees'**
  String get movementNameHighKnees;

  /// A counted high knees target, such as "10 squats".
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 high knee} other{{count} high knees}}'**
  String movementTargetHighKnees(int count);

  /// Where to put the phone so the camera can count high knees.
  ///
  /// In en, this message translates to:
  /// **'Side view · stand tall and keep both legs in frame'**
  String get movementGuideHighKnees;

  /// Live instruction while doing high knees.
  ///
  /// In en, this message translates to:
  /// **'Knee up to hip height'**
  String get movementCueHighKnees;

  /// Name of the lateral raises movement.
  ///
  /// In en, this message translates to:
  /// **'Lateral raises'**
  String get movementNameLateralRaises;

  /// A counted lateral raises target, such as "10 squats".
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 lateral raise} other{{count} lateral raises}}'**
  String movementTargetLateralRaises(int count);

  /// Where to put the phone so the camera can count lateral raises.
  ///
  /// In en, this message translates to:
  /// **'Front view · keep your whole arm span in frame'**
  String get movementGuideLateralRaises;

  /// Live instruction while doing lateral raises.
  ///
  /// In en, this message translates to:
  /// **'Raise both arms'**
  String get movementCueLateralRaises;

  /// Name of the biceps curls movement.
  ///
  /// In en, this message translates to:
  /// **'Biceps curls'**
  String get movementNameBicepsCurls;

  /// A counted biceps curls target, such as "10 squats".
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 biceps curl} other{{count} biceps curls}}'**
  String movementTargetBicepsCurls(int count);

  /// Where to put the phone so the camera can count biceps curls.
  ///
  /// In en, this message translates to:
  /// **'Front view · keep shoulders, elbows and wrists in frame'**
  String get movementGuideBicepsCurls;

  /// Live instruction while doing biceps curls.
  ///
  /// In en, this message translates to:
  /// **'Curl your hands up'**
  String get movementCueBicepsCurls;

  /// Name of the side bends movement.
  ///
  /// In en, this message translates to:
  /// **'Side bends'**
  String get movementNameSideBends;

  /// A counted side bends target, such as "10 squats".
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 side bend} other{{count} side bends}}'**
  String movementTargetSideBends(int count);

  /// Where to put the phone so the camera can count side bends.
  ///
  /// In en, this message translates to:
  /// **'Front view · keep your hips still'**
  String get movementGuideSideBends;

  /// Live instruction while doing side bends.
  ///
  /// In en, this message translates to:
  /// **'Lean to one side'**
  String get movementCueSideBends;

  /// Name of the football kick ups movement.
  ///
  /// In en, this message translates to:
  /// **'Football kick-ups'**
  String get movementNameFootballKickUps;

  /// A counted football kick ups target, such as "10 squats".
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 kick-up} other{{count} kick-ups}}'**
  String movementTargetFootballKickUps(int count);

  /// Where to put the phone so the camera can count football kick ups.
  ///
  /// In en, this message translates to:
  /// **'Step back so your whole body and the ball stay in frame'**
  String get movementGuideFootballKickUps;

  /// Live instruction while doing football kick ups.
  ///
  /// In en, this message translates to:
  /// **'Keep the ball up'**
  String get movementCueFootballKickUps;

  /// Name of the table tennis bounces movement.
  ///
  /// In en, this message translates to:
  /// **'Table tennis bounces'**
  String get movementNameTableTennisBounces;

  /// A counted table tennis bounces target, such as "10 squats".
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 bat bounce} other{{count} bat bounces}}'**
  String movementTargetTableTennisBounces(int count);

  /// Where to put the phone so the camera can count table tennis bounces.
  ///
  /// In en, this message translates to:
  /// **'Keep the bat, the ball and your upper body in frame'**
  String get movementGuideTableTennisBounces;

  /// Live instruction while doing table tennis bounces.
  ///
  /// In en, this message translates to:
  /// **'Keep the ball up'**
  String get movementCueTableTennisBounces;

  /// Live cue: the person is not in the camera frame yet.
  ///
  /// In en, this message translates to:
  /// **'Step into frame'**
  String get movementCueStepIntoFrame;

  /// Live cue: get into the starting position.
  ///
  /// In en, this message translates to:
  /// **'Get into your starting position'**
  String get movementCueGetIntoPosition;

  /// Live cue: return to the start so the repetition counts.
  ///
  /// In en, this message translates to:
  /// **'Back to the start to count it'**
  String get movementCueReturnToStart;

  /// Live cue during a burpee: crouch.
  ///
  /// In en, this message translates to:
  /// **'Crouch down'**
  String get movementCueCrouch;

  /// Live cue during a burpee: kick back to a plank.
  ///
  /// In en, this message translates to:
  /// **'Kick back to a plank'**
  String get movementCuePlank;

  /// Live cue during a burpee: bring the feet back in.
  ///
  /// In en, this message translates to:
  /// **'Bring your feet back in'**
  String get movementCueFeetForward;

  /// Live cue during a burpee: jump.
  ///
  /// In en, this message translates to:
  /// **'Jump!'**
  String get movementCueJump;

  /// Live cue: land after a jump.
  ///
  /// In en, this message translates to:
  /// **'Land on your feet'**
  String get movementCueLand;

  /// Title of the movement capture screen.
  ///
  /// In en, this message translates to:
  /// **'Movement challenge'**
  String get movementCaptureTitle;

  /// Tooltip of the button that closes the camera.
  ///
  /// In en, this message translates to:
  /// **'Close the camera'**
  String get movementCaptureClose;

  /// Tooltip of the button that switches between cameras.
  ///
  /// In en, this message translates to:
  /// **'Switch camera'**
  String get movementCaptureFlip;

  /// Shown while the camera starts.
  ///
  /// In en, this message translates to:
  /// **'Starting the camera…'**
  String get movementCaptureOpening;

  /// Shown while the live counter loads.
  ///
  /// In en, this message translates to:
  /// **'Getting your live counter ready…'**
  String get movementCaptureCoachLoading;

  /// Shown when live counting cannot run on this device.
  ///
  /// In en, this message translates to:
  /// **'Live counting isn\'t available here. Record your set and it will be checked after you submit.'**
  String get movementCaptureCoachUnavailable;

  /// Explains that the live count is a guide and the recording is what gets checked.
  ///
  /// In en, this message translates to:
  /// **'The live count helps you pace yourself. Your recording is what gets checked after you submit.'**
  String get movementCaptureAdvisory;

  /// Button that starts the hands-free countdown and recording.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get movementCaptureStart;

  /// Button that stops recording.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get movementCaptureStop;

  /// Disabled stop button before the minimum length is reached.
  ///
  /// In en, this message translates to:
  /// **'Keep recording'**
  String get movementCaptureKeepGoing;

  /// Shown while the recording is saved.
  ///
  /// In en, this message translates to:
  /// **'Saving your recording…'**
  String get movementCaptureSaving;

  /// Celebration when the live count reaches the target.
  ///
  /// In en, this message translates to:
  /// **'Target reached!'**
  String get movementCaptureTargetReached;

  /// Shown under the countdown: step back into frame.
  ///
  /// In en, this message translates to:
  /// **'Step back into frame'**
  String get movementCaptureStepBack;

  /// The countdown number before recording starts.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String movementCaptureCountdown(int count);

  /// The live repetition count.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String movementCaptureCount(int count);

  /// How many repetitions are left of the target.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Target reached} =1{of {target} · 1 to go} other{of {target} · {count} to go}}'**
  String movementCaptureRemaining(int count, int target);

  /// Screen reader text for the live count.
  ///
  /// In en, this message translates to:
  /// **'{count} of {target} counted'**
  String movementCaptureCountSemantics(int count, int target);

  /// Recording time out of the limit, such as 0:12 of 2:00.
  ///
  /// In en, this message translates to:
  /// **'{elapsed} of {limit}'**
  String movementCaptureElapsed(String elapsed, String limit);

  /// Screen reader value of the movement depth gauge.
  ///
  /// In en, this message translates to:
  /// **'Movement depth {percent}%'**
  String movementCaptureDepthSemantics(int percent);

  /// Title when camera access is off.
  ///
  /// In en, this message translates to:
  /// **'Camera access is off'**
  String get movementCapturePermissionDenied;

  /// Explains how to turn camera access back on.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access for Verily in your phone\'s settings, then try again. Proof can only be captured live.'**
  String get movementCapturePermissionDeniedBody;

  /// Title when the device has no usable camera.
  ///
  /// In en, this message translates to:
  /// **'No camera found'**
  String get movementCaptureNoCamera;

  /// Explains that this device has no usable camera.
  ///
  /// In en, this message translates to:
  /// **'This device doesn\'t have a camera Verily can use.'**
  String get movementCaptureNoCameraBody;

  /// Title when the camera cannot start.
  ///
  /// In en, this message translates to:
  /// **'The camera couldn\'t start'**
  String get movementCaptureUnavailable;

  /// What to do when the camera cannot start.
  ///
  /// In en, this message translates to:
  /// **'Close any other app using the camera, then try again.'**
  String get movementCaptureUnavailableBody;

  /// Title when the recording could not be saved.
  ///
  /// In en, this message translates to:
  /// **'The recording couldn\'t be saved'**
  String get movementCaptureRecordingFailed;

  /// Reassures that nothing was submitted and suggests recording again.
  ///
  /// In en, this message translates to:
  /// **'Nothing was submitted. Try recording again.'**
  String get movementCaptureRecordingFailedBody;

  /// Shown after leaving the app stopped a recording.
  ///
  /// In en, this message translates to:
  /// **'Recording stopped when you left the app. Start again when you\'re ready.'**
  String get movementCaptureInterrupted;

  /// Button that retries opening the camera.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get movementCaptureTryAgain;

  /// Live cue for ball skills: show the ball to the camera.
  ///
  /// In en, this message translates to:
  /// **'Show the ball to the camera'**
  String get movementCueShowBall;

  /// Live cue for ball skills: the ball dropped; start a new run.
  ///
  /// In en, this message translates to:
  /// **'Dropped! Go again'**
  String get movementCueDropped;

  /// The longest ball-skill run so far.
  ///
  /// In en, this message translates to:
  /// **'Best run: {count}'**
  String movementCaptureBest(int count);

  /// Motion capture (phone sensors): title.
  ///
  /// In en, this message translates to:
  /// **'Capture device motion'**
  String get captureMotionTitle;

  /// Motion capture (phone sensors): ready.
  ///
  /// In en, this message translates to:
  /// **'Find a clear space'**
  String get captureMotionReady;

  /// Motion capture (phone sensors): ready body.
  ///
  /// In en, this message translates to:
  /// **'Hold your phone securely. Verily starts after a three-second countdown and records only the short motion trace needed for this action.'**
  String get captureMotionReadyBody;

  /// Motion capture (phone sensors): begin.
  ///
  /// In en, this message translates to:
  /// **'Start countdown'**
  String get captureMotionBegin;

  /// Motion capture (phone sensors): countdown.
  ///
  /// In en, this message translates to:
  /// **'Starting in {count}'**
  String captureMotionCountdown(int count);

  /// Motion capture (phone sensors): countdown body.
  ///
  /// In en, this message translates to:
  /// **'Get into position and keep a secure grip.'**
  String get captureMotionCountdownBody;

  /// Motion capture (phone sensors): countdown number.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String captureMotionCountdownNumber(int count);

  /// Motion capture (phone sensors): recording.
  ///
  /// In en, this message translates to:
  /// **'Motion capture in progress'**
  String get captureMotionRecording;

  /// Motion capture (phone sensors): progress.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of the capture complete'**
  String captureMotionProgress(int percent);

  /// Motion capture (phone sensors): matched.
  ///
  /// In en, this message translates to:
  /// **'Movement matched'**
  String get captureMotionMatched;

  /// Motion capture (phone sensors): matched body.
  ///
  /// In en, this message translates to:
  /// **'Verily detected {count, plural, =0{the required movement} =1{one complete movement} other{{count} complete movements}}. It will be checked again after you submit.'**
  String captureMotionMatchedBody(int count);

  /// Motion capture (phone sensors): not matched.
  ///
  /// In en, this message translates to:
  /// **'Not quite'**
  String get captureMotionNotMatched;

  /// Motion capture (phone sensors): retry.
  ///
  /// In en, this message translates to:
  /// **'Capture again'**
  String get captureMotionRetry;

  /// Motion capture (phone sensors): use proof.
  ///
  /// In en, this message translates to:
  /// **'Use this motion proof'**
  String get captureMotionUseProof;

  /// Motion capture (phone sensors): privacy.
  ///
  /// In en, this message translates to:
  /// **'Only a short sensor trace is collected. Motion capture does not record video, audio, or continuous location.'**
  String get captureMotionPrivacy;

  /// Motion capture (phone sensors): no sensor.
  ///
  /// In en, this message translates to:
  /// **'Motion sensors unavailable'**
  String get captureMotionNoSensor;

  /// Motion capture (phone sensors): no sensor body.
  ///
  /// In en, this message translates to:
  /// **'Verily couldn’t read this device’s motion sensors. Check motion access in your device settings, then try again.'**
  String get captureMotionNoSensorBody;

  /// Motion capture (phone sensors): unavailable.
  ///
  /// In en, this message translates to:
  /// **'This motion action is unavailable'**
  String get captureMotionUnavailable;

  /// Motion capture (phone sensors): unavailable body.
  ///
  /// In en, this message translates to:
  /// **'Its movement settings are incomplete, so Verily will not guess what counts. Ask the creator to update the action.'**
  String get captureMotionUnavailableBody;

  /// Motion capture (phone sensors): interrupted.
  ///
  /// In en, this message translates to:
  /// **'Capture interrupted'**
  String get captureMotionInterrupted;

  /// Motion capture (phone sensors): interrupted body.
  ///
  /// In en, this message translates to:
  /// **'Motion recording stopped early. Keep Verily open and try again.'**
  String get captureMotionInterruptedBody;

  /// Motion capture (phone sensors): toss safety title.
  ///
  /// In en, this message translates to:
  /// **'Protect yourself and your phone'**
  String get captureMotionTossSafetyTitle;

  /// Motion capture (phone sensors): toss safety body.
  ///
  /// In en, this message translates to:
  /// **'Use both hands over a soft, clear surface. Keep the toss below eye level. Do not attempt this near people, traffic, water, edges, or hard ground.'**
  String get captureMotionTossSafetyBody;

  /// Motion capture (phone sensors): failure too fast.
  ///
  /// In en, this message translates to:
  /// **'That rotation exceeded the safe speed set for this action. Slow down and keep control of the phone.'**
  String get captureMotionFailureTooFast;

  /// Motion capture (phone sensors): failure wrong axis.
  ///
  /// In en, this message translates to:
  /// **'The phone turned the wrong way. Follow the direction shown above and try again.'**
  String get captureMotionFailureWrongAxis;

  /// Motion capture (phone sensors): failure too slow.
  ///
  /// In en, this message translates to:
  /// **'The rotation was too small or too slow to count clearly. Make deliberate, complete turns.'**
  String get captureMotionFailureTooSlow;

  /// Motion capture (phone sensors): failure count.
  ///
  /// In en, this message translates to:
  /// **'Verily did not detect enough complete movements. Reset your grip and try the full count again.'**
  String get captureMotionFailureCount;

  /// Motion capture (phone sensors): failure impact.
  ///
  /// In en, this message translates to:
  /// **'The movement was too forceful for this action. Stop if the phone or your surroundings could be damaged.'**
  String get captureMotionFailureImpact;

  /// Motion capture (phone sensors): failure air time.
  ///
  /// In en, this message translates to:
  /// **'We didn’t detect a low, controlled toss. Toss gently, just above your hands, and try again.'**
  String get captureMotionFailureAirTime;

  /// Motion capture (phone sensors): failure toss.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t detect a full toss and catch. Try one gentle toss and catch it with both hands.'**
  String get captureMotionFailureToss;

  /// Motion capture (phone sensors): failure stillness.
  ///
  /// In en, this message translates to:
  /// **'The phone moved more than this action allows. Rest your arms and try holding it steady again.'**
  String get captureMotionFailureStillness;

  /// Motion capture (phone sensors): failure duration.
  ///
  /// In en, this message translates to:
  /// **'The capture was too short or too long for this action. Try again.'**
  String get captureMotionFailureDuration;

  /// Motion capture (phone sensors): failure generic.
  ///
  /// In en, this message translates to:
  /// **'The movement didn’t match the action. Check the target and try again.'**
  String get captureMotionFailureGeneric;

  /// Motion capture (phone sensors): target label.
  ///
  /// In en, this message translates to:
  /// **'Motion target'**
  String get captureMotionTargetLabel;

  /// Motion capture (phone sensors): target toss.
  ///
  /// In en, this message translates to:
  /// **'One low, controlled toss and two-handed catch'**
  String get captureMotionTargetToss;

  /// Motion capture (phone sensors): target rotation.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 complete {axis} rotation} other{{count} complete {axis} rotations}}'**
  String captureMotionTargetRotation(int count, String axis);

  /// Motion capture (phone sensors): target shake.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 controlled back-and-forth shake} other{{count} controlled back-and-forth shakes}}'**
  String captureMotionTargetShake(int count);

  /// Motion capture (phone sensors): target stillness.
  ///
  /// In en, this message translates to:
  /// **'Hold the phone steady for {seconds} seconds'**
  String captureMotionTargetStillness(int seconds);

  /// Motion capture (phone sensors): target unavailable.
  ///
  /// In en, this message translates to:
  /// **'The creator needs to finish the motion settings'**
  String get captureMotionTargetUnavailable;

  /// Motion capture (phone sensors): type phone toss.
  ///
  /// In en, this message translates to:
  /// **'Gentle phone toss'**
  String get captureMotionTypePhoneToss;

  /// Motion capture (phone sensors): type rotation.
  ///
  /// In en, this message translates to:
  /// **'Counted rotation'**
  String get captureMotionTypeRotation;

  /// Motion capture (phone sensors): type shake.
  ///
  /// In en, this message translates to:
  /// **'Controlled shake'**
  String get captureMotionTypeShake;

  /// Motion capture (phone sensors): type stillness.
  ///
  /// In en, this message translates to:
  /// **'Hold still'**
  String get captureMotionTypeStillness;

  /// Motion capture (phone sensors): axis yaw.
  ///
  /// In en, this message translates to:
  /// **'steering-wheel'**
  String get captureMotionAxisYaw;

  /// Motion capture (phone sensors): axis pitch.
  ///
  /// In en, this message translates to:
  /// **'forward-flip'**
  String get captureMotionAxisPitch;

  /// Motion capture (phone sensors): axis roll.
  ///
  /// In en, this message translates to:
  /// **'sideways'**
  String get captureMotionAxisRoll;

  /// Motion capture (phone sensors): axis any.
  ///
  /// In en, this message translates to:
  /// **'any axis'**
  String get captureMotionAxisAny;

  /// What live counting counted while recording; advisory only.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Your phone didn\'t count any repetitions. The recording is still checked after you submit.} =1{Your phone counted 1 repetition. The recording is checked after you submit.} other{Your phone counted {count} repetitions. The recording is checked after you submit.}}'**
  String captureReviewDeviceCount(int count);

  /// Developer preview result: what the tracker counted and its version.
  ///
  /// In en, this message translates to:
  /// **'Counted {count} · {version}'**
  String movementPreviewResult(int count, String version);

  /// Tooltip of the button that leaves a capture without sending anything.
  ///
  /// In en, this message translates to:
  /// **'Close without sending'**
  String get captureClose;

  /// Tooltip of the button that switches between front and back cameras.
  ///
  /// In en, this message translates to:
  /// **'Switch camera'**
  String get captureFlipCamera;

  /// Label on the camera viewfinder: proof is captured live, never uploaded.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get captureLive;

  /// Shown while Verily fetches the word to say while recording.
  ///
  /// In en, this message translates to:
  /// **'Getting your word…'**
  String get captureChallengeLoading;

  /// Shown above the spoken challenge word before recording starts.
  ///
  /// In en, this message translates to:
  /// **'When you record, say this word clearly'**
  String get captureChallengeIntro;

  /// The spoken challenge, shown big while recording.
  ///
  /// In en, this message translates to:
  /// **'Say “{word}”'**
  String captureChallengeSay(String word);

  /// Screen reader text for the spoken challenge.
  ///
  /// In en, this message translates to:
  /// **'Say the word {word} while you record'**
  String captureChallengeSemantics(String word);

  /// Title when the spoken challenge could not be fetched; recording cannot start without it.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t get your word'**
  String get captureChallengeFailedTitle;

  /// Explains why recording waits for the word.
  ///
  /// In en, this message translates to:
  /// **'Each recording needs a fresh word from Verily so it is clearly live. Check your connection and try again.'**
  String get captureChallengeFailedBody;

  /// Button that starts a video or audio recording.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get captureRecordStart;

  /// Button that stops a recording.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get captureRecordStop;

  /// Shutter button for photo proof.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get captureTakePhoto;

  /// Recording time out of the limit, such as 0:12 of 2:00.
  ///
  /// In en, this message translates to:
  /// **'{elapsed} of {limit}'**
  String captureElapsed(String elapsed, String limit);

  /// Shown while a recording is shorter than the action allows.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, =1{Record at least 1 second} other{Record at least {seconds} seconds}}'**
  String captureMinimumHint(int seconds);

  /// Shown when a recording stopped itself at the maximum length.
  ///
  /// In en, this message translates to:
  /// **'Stopped at the {limit} limit'**
  String captureLimitReached(String limit);

  /// Title when camera access is off.
  ///
  /// In en, this message translates to:
  /// **'Camera access is off'**
  String get captureCameraPermissionTitle;

  /// Explains how to turn camera access back on.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access for Verily in your phone\'s settings. Proof can only be captured live, here in the app.'**
  String get captureCameraPermissionBody;

  /// Title when microphone access is off.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is off'**
  String get captureMicrophonePermissionTitle;

  /// Explains how to turn microphone access back on.
  ///
  /// In en, this message translates to:
  /// **'Allow microphone access for Verily in your phone\'s settings. Your recording needs sound for this action.'**
  String get captureMicrophonePermissionBody;

  /// Button that opens this app's system settings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get captureOpenSettings;

  /// Title of the audio capture screen.
  ///
  /// In en, this message translates to:
  /// **'Record audio'**
  String get captureAudioTitle;

  /// Guidance before recording audio proof.
  ///
  /// In en, this message translates to:
  /// **'Hold your phone close and speak clearly.'**
  String get captureAudioHint;

  /// Screen reader value of the microphone level meter.
  ///
  /// In en, this message translates to:
  /// **'Sound level {percent}%'**
  String captureAudioLevelSemantics(int percent);

  /// Shown while audio is being recorded.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get captureAudioRecording;

  /// Title of the review step after capturing.
  ///
  /// In en, this message translates to:
  /// **'Check your proof'**
  String get captureReviewTitle;

  /// Guidance for reviewing a photo.
  ///
  /// In en, this message translates to:
  /// **'Make sure the photo shows the action clearly.'**
  String get captureReviewPhotoBody;

  /// Guidance for reviewing a recording.
  ///
  /// In en, this message translates to:
  /// **'Play it back and make sure the action is clear.'**
  String get captureReviewRecordingBody;

  /// Reminds the person of the spoken challenge before sending.
  ///
  /// In en, this message translates to:
  /// **'Did you say “{word}”? It needs to be heard in the recording.'**
  String captureReviewWordCheck(String word);

  /// How long the recording is.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, =1{1 second recorded} other{{seconds} seconds recorded}}'**
  String captureReviewDuration(int seconds);

  /// Discards the capture and returns to the camera or microphone.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get captureReviewRetake;

  /// Sends the capture to Verily to be checked.
  ///
  /// In en, this message translates to:
  /// **'Send proof'**
  String get captureReviewSend;

  /// Privacy note on the review step.
  ///
  /// In en, this message translates to:
  /// **'Your proof stays private: only Verily\'s checks and the people reviewing this action see it.'**
  String get captureReviewPrivacy;

  /// Tooltip of the play button in the capture preview.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get captureReviewPlay;

  /// Tooltip of the pause button in the capture preview.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get captureReviewPause;

  /// Shown when the capture cannot be played back on this device.
  ///
  /// In en, this message translates to:
  /// **'This preview can\'t play here. You can still send it.'**
  String get captureReviewPreviewUnavailable;

  /// Shown while the capture uploads.
  ///
  /// In en, this message translates to:
  /// **'Sending your proof…'**
  String get captureSending;

  /// Title when the upload failed.
  ///
  /// In en, this message translates to:
  /// **'Your proof didn\'t send'**
  String get captureSendFailedTitle;

  /// Reassures that the capture was kept.
  ///
  /// In en, this message translates to:
  /// **'It is still on this phone. Check your connection and send it again.'**
  String get captureSendFailedBody;

  /// Retries sending the kept capture.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get captureSendAgain;

  /// Title when the device could not sign or attest the capture.
  ///
  /// In en, this message translates to:
  /// **'This phone couldn\'t vouch for the capture'**
  String get captureIntegrityTitle;

  /// Explains the device check in plain words.
  ///
  /// In en, this message translates to:
  /// **'This action needs proof from a phone that can confirm it captured it live. Try again, or use another phone.'**
  String get captureIntegrityBody;

  /// Title when the capture format is not accepted.
  ///
  /// In en, this message translates to:
  /// **'This action can\'t take what this phone recorded'**
  String get captureUnsupportedFormatTitle;

  /// Explains the format problem without technical detail.
  ///
  /// In en, this message translates to:
  /// **'Nothing was sent. Try again; if it keeps happening, this action may not work on this phone.'**
  String get captureUnsupportedFormatBody;

  /// Title when the capture exceeds the size the action accepts.
  ///
  /// In en, this message translates to:
  /// **'That capture is too large'**
  String get captureTooLargeTitle;

  /// Explains the size problem.
  ///
  /// In en, this message translates to:
  /// **'Nothing was sent. Record a shorter clip and try again.'**
  String get captureTooLargeBody;

  /// Title for an unexpected capture problem.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t work'**
  String get captureProblemTitle;

  /// Which proof an appeal is about, and its kind.
  ///
  /// In en, this message translates to:
  /// **'{requirement} · {kind}'**
  String appealsRequirement(String requirement, String kind);

  /// Display line on the front door.
  ///
  /// In en, this message translates to:
  /// **'Do it. Prove it. Get paid.'**
  String get welcomeTitle;

  /// The pitch under the display line on the front door.
  ///
  /// In en, this message translates to:
  /// **'Real actions in real places. Your phone captures the proof as it happens, Verily checks it, and the reward is already waiting.'**
  String get welcomeBody;

  /// Heading above the three parts of an action on the front door.
  ///
  /// In en, this message translates to:
  /// **'Every action is a small promise'**
  String get welcomePromiseHeading;

  /// First part of an action: where it happens.
  ///
  /// In en, this message translates to:
  /// **'A place'**
  String get welcomePromisePlaceTitle;

  /// Explains the place part of an action.
  ///
  /// In en, this message translates to:
  /// **'A pin on a map or a code at the venue. Being there is part of it.'**
  String get welcomePromisePlaceBody;

  /// Second part of an action: the proof.
  ///
  /// In en, this message translates to:
  /// **'Proof, captured live'**
  String get welcomePromiseProofTitle;

  /// Explains that proof is captured live, never uploaded.
  ///
  /// In en, this message translates to:
  /// **'Video, a photo, sound, or motion, recorded in the app. There\'s no upload button.'**
  String get welcomePromiseProofBody;

  /// Third part of an action: the optional reward.
  ///
  /// In en, this message translates to:
  /// **'A reward, locked first'**
  String get welcomePromiseRewardTitle;

  /// Explains that rewards are escrowed before work begins.
  ///
  /// In en, this message translates to:
  /// **'Rewards sit in escrow before anyone starts, so nobody works for a promise.'**
  String get welcomePromiseRewardBody;

  /// Primary action on the front door. Leads to sign-in.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get welcomeGetStarted;

  /// Quiet action on the front door. Leads to sign-in.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get welcomeHaveAccount;

  /// Sign-in heading when there is no particular reason.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Verily'**
  String get signInTitle;

  /// Sign-in heading when someone tried to start or open an action.
  ///
  /// In en, this message translates to:
  /// **'Sign in to do this action'**
  String get signInTitleDoAction;

  /// Sign-in heading when someone tried to create or fund an action.
  ///
  /// In en, this message translates to:
  /// **'Sign in to post an action'**
  String get signInTitleCreateAction;

  /// Sign-in heading when someone opened their attempts, payouts, or appeals.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your proof and payouts'**
  String get signInTitlePrivateHistory;

  /// Sign-in heading when someone opened their Verily Apps.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your Verily Apps'**
  String get signInTitleManageApps;

  /// Reassurance under the sign-in heading.
  ///
  /// In en, this message translates to:
  /// **'Your proof stays private to you and the people who check it.'**
  String get signInSubtitle;

  /// Heading of the email sign-in form for someone who already has an account.
  ///
  /// In en, this message translates to:
  /// **'Sign in with email'**
  String get signInEmailTitle;

  /// Heading of the email form that starts a new account.
  ///
  /// In en, this message translates to:
  /// **'Sign up with email'**
  String get signInEmailSignUpTitle;

  /// Shown while verifying an email address during sign-up.
  ///
  /// In en, this message translates to:
  /// **'Enter the 8-digit code we emailed you.'**
  String get signInVerificationPrompt;

  /// Password rule: the minimum length. The sign-in kit fills in {length}; pass the literal text {length}.
  ///
  /// In en, this message translates to:
  /// **'{length}+ characters'**
  String signInPasswordMinLength(String length);

  /// Password rule: the maximum length. The sign-in kit fills in {length}; pass the literal text {length}.
  ///
  /// In en, this message translates to:
  /// **'Up to {length} characters'**
  String signInPasswordMaxLength(String length);

  /// Password rule.
  ///
  /// In en, this message translates to:
  /// **'One lowercase letter'**
  String get signInPasswordLowercase;

  /// Password rule.
  ///
  /// In en, this message translates to:
  /// **'One uppercase letter'**
  String get signInPasswordUppercase;

  /// Password rule.
  ///
  /// In en, this message translates to:
  /// **'One number'**
  String get signInPasswordNumber;

  /// Password rule.
  ///
  /// In en, this message translates to:
  /// **'One symbol'**
  String get signInPasswordSymbol;

  /// Shown when sign-in fails. Never shows technical detail.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t sign you in. Try again.'**
  String get signInFailed;

  /// Shown when no sign-in method is configured.
  ///
  /// In en, this message translates to:
  /// **'Sign-in isn\'t available in this build.'**
  String get signInUnavailable;

  /// Shown above the button that leaves sign-in without an account.
  ///
  /// In en, this message translates to:
  /// **'Your place is saved. Sign in when you\'re ready and we\'ll bring you back.'**
  String get signInIntentKept;

  /// Leaves the sign-in page without an account.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get signInNotNow;

  /// Short prompt beside the link from creating an account to signing in. Kept short so it fits one line beside the link on a narrow phone.
  ///
  /// In en, this message translates to:
  /// **'Have an account?'**
  String get signInHaveAccountPrompt;

  /// Short prompt beside the link from signing in to creating an account. Kept short so it fits one line beside the link on a narrow phone.
  ///
  /// In en, this message translates to:
  /// **'New here?'**
  String get signInNewHerePrompt;

  /// Title of the Me tab.
  ///
  /// In en, this message translates to:
  /// **'Your proof and payouts'**
  String get meTitle;

  /// Breadcrumb under the Me tab title.
  ///
  /// In en, this message translates to:
  /// **'Attempts, rewards, and where they go'**
  String get meSubtitle;

  /// Heading of the payout wallet card.
  ///
  /// In en, this message translates to:
  /// **'Payout wallet'**
  String get meWalletTitle;

  /// Shown when a payout wallet is linked.
  ///
  /// In en, this message translates to:
  /// **'Rewards you earn are sent to this wallet.'**
  String get meWalletLinkedBody;

  /// Accessible label of the shortened wallet address.
  ///
  /// In en, this message translates to:
  /// **'Wallet address {address}'**
  String meWalletAddressLabel(String address);

  /// Tooltip of the button that copies the payout wallet address.
  ///
  /// In en, this message translates to:
  /// **'Copy wallet address'**
  String get meWalletCopy;

  /// Confirms the wallet address was copied.
  ///
  /// In en, this message translates to:
  /// **'Wallet address copied'**
  String get meWalletCopied;

  /// Links a different payout wallet.
  ///
  /// In en, this message translates to:
  /// **'Use a different wallet'**
  String get meWalletChange;

  /// Heading when no payout wallet is linked.
  ///
  /// In en, this message translates to:
  /// **'Link a wallet to get paid'**
  String get meWalletUnlinkedTitle;

  /// Explains why to link a payout wallet.
  ///
  /// In en, this message translates to:
  /// **'Rewards are paid in USDC on Solana. Link your wallet once, and anything waiting for you is sent as soon as it\'s linked.'**
  String get meWalletUnlinkedBody;

  /// Starts linking a payout wallet.
  ///
  /// In en, this message translates to:
  /// **'Link a wallet'**
  String get meWalletLink;

  /// Shown while the wallet app is open.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your wallet…'**
  String get meWalletLinking;

  /// Shown where wallets can't be reached, such as the web or iOS.
  ///
  /// In en, this message translates to:
  /// **'Linking a wallet needs Verily on Android with a Solana wallet app installed.'**
  String get meWalletUnsupported;

  /// Confirms a payout wallet was linked.
  ///
  /// In en, this message translates to:
  /// **'Wallet linked. Payouts go there now.'**
  String get meWalletLinked;

  /// Wallet linking failed: no wallet app.
  ///
  /// In en, this message translates to:
  /// **'No Solana wallet app answered. Install one, then try again.'**
  String get meWalletFailureUnavailable;

  /// Wallet linking failed: declined in the wallet.
  ///
  /// In en, this message translates to:
  /// **'Linking was cancelled in your wallet.'**
  String get meWalletFailureCancelled;

  /// Wallet linking failed: timed out.
  ///
  /// In en, this message translates to:
  /// **'Your wallet didn\'t answer in time. Try again.'**
  String get meWalletFailureTimedOut;

  /// Wallet linking failed: a different account was authorized.
  ///
  /// In en, this message translates to:
  /// **'Your wallet offered a different account. Choose the one you want paid, then try again.'**
  String get meWalletFailureWrongAccount;

  /// Wallet linking failed: unusable response.
  ///
  /// In en, this message translates to:
  /// **'Your wallet sent back something we couldn\'t use. Try again.'**
  String get meWalletFailureInvalidResponse;

  /// Wallet linking failed for another reason.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t link your wallet. Try again.'**
  String get meWalletFailureFailed;

  /// Heading of the payouts list.
  ///
  /// In en, this message translates to:
  /// **'Payouts'**
  String get mePayoutsTitle;

  /// Shown when there are no payouts.
  ///
  /// In en, this message translates to:
  /// **'Nothing paid yet. Rewards you earn show up here.'**
  String get mePayoutsEmpty;

  /// Deadline for a payout waiting for a wallet.
  ///
  /// In en, this message translates to:
  /// **'Link a wallet by {date} to receive it.'**
  String mePayoutPayableUntil(String date);

  /// Heading of the attempts list.
  ///
  /// In en, this message translates to:
  /// **'Your attempts'**
  String get meAttemptsTitle;

  /// Shown when there are no attempts.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t tried an action yet. Find one in Do.'**
  String get meAttemptsEmpty;

  /// Stands in for an attempt's action title when the action is no longer listed.
  ///
  /// In en, this message translates to:
  /// **'An action you tried'**
  String get meAttemptUnknownAction;

  /// When an attempt began.
  ///
  /// In en, this message translates to:
  /// **'Started {date}'**
  String meAttemptStarted(String date);

  /// Opens the appeal form for a rejected attempt.
  ///
  /// In en, this message translates to:
  /// **'Appeal'**
  String get meAppeal;

  /// Title of the appeal form.
  ///
  /// In en, this message translates to:
  /// **'Appeal this decision'**
  String get meAppealTitle;

  /// Explains the appeal form.
  ///
  /// In en, this message translates to:
  /// **'Tell the action\'s creator what your proof shows. You can appeal once.'**
  String get meAppealBody;

  /// Label of the appeal reason field.
  ///
  /// In en, this message translates to:
  /// **'What should they know?'**
  String get meAppealReasonLabel;

  /// Example appeal reason.
  ///
  /// In en, this message translates to:
  /// **'For example: all ten squats are in the second half of the video.'**
  String get meAppealReasonHint;

  /// Explains the appeal reason's minimum length.
  ///
  /// In en, this message translates to:
  /// **'At least 10 characters.'**
  String get meAppealReasonHelper;

  /// Sends the appeal.
  ///
  /// In en, this message translates to:
  /// **'Send appeal'**
  String get meAppealSend;

  /// Confirms the appeal was sent.
  ///
  /// In en, this message translates to:
  /// **'Appeal sent.'**
  String get meAppealSent;

  /// An appeal waiting for a decision.
  ///
  /// In en, this message translates to:
  /// **'Appeal sent · waiting for the creator'**
  String get meAppealPending;

  /// An appeal the creator accepted.
  ///
  /// In en, this message translates to:
  /// **'Appeal accepted'**
  String get meAppealAccepted;

  /// An appeal the creator turned down.
  ///
  /// In en, this message translates to:
  /// **'Appeal not accepted'**
  String get meAppealRejected;

  /// Title when a Me section fails to load.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this'**
  String get meLoadFailedTitle;

  /// Shown while attempts load.
  ///
  /// In en, this message translates to:
  /// **'Loading your attempts…'**
  String get meLoadingAttempts;

  /// Shown while payouts load.
  ///
  /// In en, this message translates to:
  /// **'Loading your payouts…'**
  String get meLoadingPayouts;

  /// Opens the review queue. Only for reviewers.
  ///
  /// In en, this message translates to:
  /// **'Review proof'**
  String get meLinkReview;

  /// Opens appeals on the person's own actions.
  ///
  /// In en, this message translates to:
  /// **'Appeals on your actions'**
  String get meLinkAppeals;

  /// Breadcrumb under the settings title.
  ///
  /// In en, this message translates to:
  /// **'How Verily looks, and your account'**
  String get settingsSubtitle;

  /// Heading of the account section.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get settingsAccountTitle;

  /// Signs out of this device.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// Announced while signing out.
  ///
  /// In en, this message translates to:
  /// **'Signing out…'**
  String get settingsSigningOut;

  /// Explains signing out.
  ///
  /// In en, this message translates to:
  /// **'You can sign back in any time. Nothing you\'ve done is lost.'**
  String get settingsSignOutSubtitle;

  /// Title of the sign-out confirmation.
  ///
  /// In en, this message translates to:
  /// **'Sign out of Verily?'**
  String get settingsSignOutDialogTitle;

  /// Body of the sign-out confirmation.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again to do actions or see your payouts.'**
  String get settingsSignOutDialogBody;

  /// Shown when signing out fails.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t sign you out. Try again.'**
  String get settingsSignOutFailed;

  /// Starts closing the account.
  ///
  /// In en, this message translates to:
  /// **'Close account'**
  String get settingsCloseAccount;

  /// Explains closing the account.
  ///
  /// In en, this message translates to:
  /// **'Remove your sign-in details and end every session.'**
  String get settingsCloseAccountSubtitle;

  /// Title of the close-account confirmation.
  ///
  /// In en, this message translates to:
  /// **'Close your account?'**
  String get settingsCloseAccountDialogTitle;

  /// Says plainly what closing the account does.
  ///
  /// In en, this message translates to:
  /// **'Your sign-in details are removed, every session ends, and your live actions are paused. Rewards already sent stay in the wallets they went to.'**
  String get settingsCloseAccountDialogBody;

  /// Label of the field that confirms closing the account. Keep the word DELETE in English: the server expects it.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get settingsCloseAccountConfirmationLabel;

  /// Confirms closing the account.
  ///
  /// In en, this message translates to:
  /// **'Close account'**
  String get settingsCloseAccountConfirm;

  /// Announced while closing the account.
  ///
  /// In en, this message translates to:
  /// **'Closing account…'**
  String get settingsClosingAccount;

  /// Shown when closing the account fails.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t close your account. Try again.'**
  String get settingsCloseAccountFailed;

  /// Title of the review queue.
  ///
  /// In en, this message translates to:
  /// **'Proof to review'**
  String get reviewTitle;

  /// Shown to accounts without review access.
  ///
  /// In en, this message translates to:
  /// **'Reviewing is for Verily\'s reviewers'**
  String get reviewNotReviewerTitle;

  /// Explains the review queue to accounts without access.
  ///
  /// In en, this message translates to:
  /// **'People with review access decide proof that needs a person. Your own proof is in Me.'**
  String get reviewNotReviewerBody;

  /// Shown while the queue loads.
  ///
  /// In en, this message translates to:
  /// **'Loading proof to review…'**
  String get reviewLoading;

  /// Shown when the queue is empty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to review'**
  String get reviewEmptyTitle;

  /// Explains an empty review queue.
  ///
  /// In en, this message translates to:
  /// **'Proof that needs a person shows up here.'**
  String get reviewEmptyBody;

  /// Shown when the review queue fails to load.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the queue'**
  String get reviewLoadFailedTitle;

  /// Who posted the action and which proof this is.
  ///
  /// In en, this message translates to:
  /// **'{creator} · {requirement}'**
  String reviewContext(String creator, String requirement);

  /// Kind of proof.
  ///
  /// In en, this message translates to:
  /// **'Video proof'**
  String get reviewKindVideo;

  /// Kind of proof.
  ///
  /// In en, this message translates to:
  /// **'Photo proof'**
  String get reviewKindPhoto;

  /// Kind of proof.
  ///
  /// In en, this message translates to:
  /// **'Audio proof'**
  String get reviewKindAudio;

  /// Kind of proof.
  ///
  /// In en, this message translates to:
  /// **'Location proof'**
  String get reviewKindLocation;

  /// Kind of proof.
  ///
  /// In en, this message translates to:
  /// **'Venue code proof'**
  String get reviewKindQrCode;

  /// Kind of proof.
  ///
  /// In en, this message translates to:
  /// **'Motion proof'**
  String get reviewKindMotion;

  /// Kind of proof.
  ///
  /// In en, this message translates to:
  /// **'App confirmation'**
  String get reviewKindExternalApp;

  /// A kind of proof with its length.
  ///
  /// In en, this message translates to:
  /// **'{kind} · {seconds, plural, =1{1 second} other{{seconds} seconds}}'**
  String reviewKindWithDuration(String kind, int seconds);

  /// When the proof was captured and sent.
  ///
  /// In en, this message translates to:
  /// **'Captured {captured} · sent {submitted}'**
  String reviewTimes(String captured, String submitted);

  /// The word the participant was asked to say while recording.
  ///
  /// In en, this message translates to:
  /// **'Listen for “{word}”'**
  String reviewListenFor(String word);

  /// Why a valuable payout waits for a person.
  ///
  /// In en, this message translates to:
  /// **'Pays {amount}, above the {threshold} review threshold'**
  String reviewPayout(String amount, String threshold);

  /// Explains that evidence links are short-lived.
  ///
  /// In en, this message translates to:
  /// **'Private link. It expires five minutes after loading.'**
  String get reviewMediaExpires;

  /// Fetches fresh private links.
  ///
  /// In en, this message translates to:
  /// **'Reload proof'**
  String get reviewMediaReload;

  /// Shown when evidence media can't load.
  ///
  /// In en, this message translates to:
  /// **'This proof can\'t play here. Reload to get a fresh link.'**
  String get reviewMediaUnavailable;

  /// Shown while evidence media loads.
  ///
  /// In en, this message translates to:
  /// **'Loading proof…'**
  String get reviewMediaLoading;

  /// Plays evidence media.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get reviewPlay;

  /// Pauses evidence media.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get reviewPause;

  /// Accessible label of the playback position.
  ///
  /// In en, this message translates to:
  /// **'Playback position'**
  String get reviewPlaybackPosition;

  /// Accessible label of a photo being reviewed.
  ///
  /// In en, this message translates to:
  /// **'Photo proof for {action}'**
  String reviewPhotoLabel(String action);

  /// Accepts the proof.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get reviewAccept;

  /// Rejects the proof.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reviewReject;

  /// Title of the accept confirmation.
  ///
  /// In en, this message translates to:
  /// **'Accept this proof?'**
  String get reviewAcceptTitle;

  /// Title of the reject confirmation.
  ///
  /// In en, this message translates to:
  /// **'Reject this proof?'**
  String get reviewRejectTitle;

  /// Label of the review note.
  ///
  /// In en, this message translates to:
  /// **'Note for the record'**
  String get reviewNoteLabel;

  /// Hint for the review note.
  ///
  /// In en, this message translates to:
  /// **'What you saw, in a sentence.'**
  String get reviewNoteHint;

  /// Confirms a review decision.
  ///
  /// In en, this message translates to:
  /// **'Decision saved.'**
  String get reviewSaved;

  /// Shown when a review decision fails.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save that decision. Try again.'**
  String get reviewSaveFailed;

  /// Title of the creator's appeals list.
  ///
  /// In en, this message translates to:
  /// **'Appeals on your actions'**
  String get appealsTitle;

  /// Shown while appeals load.
  ///
  /// In en, this message translates to:
  /// **'Loading appeals…'**
  String get appealsLoading;

  /// Shown when there are no appeals.
  ///
  /// In en, this message translates to:
  /// **'No appeals'**
  String get appealsEmptyTitle;

  /// Explains an empty appeals list.
  ///
  /// In en, this message translates to:
  /// **'When someone contests a rejection on one of your actions, it shows up here.'**
  String get appealsEmptyBody;

  /// Shown when appeals fail to load.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load appeals'**
  String get appealsLoadFailedTitle;

  /// Heading above the participant's appeal reason.
  ///
  /// In en, this message translates to:
  /// **'Their words'**
  String get appealsReasonHeading;

  /// An appeal waiting for the creator.
  ///
  /// In en, this message translates to:
  /// **'Waiting for you'**
  String get appealsStatusPending;

  /// An appeal the creator accepted.
  ///
  /// In en, this message translates to:
  /// **'You accepted this appeal'**
  String get appealsStatusAccepted;

  /// An appeal the creator turned down.
  ///
  /// In en, this message translates to:
  /// **'You turned this appeal down'**
  String get appealsStatusRejected;

  /// Accepts an appeal.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get appealsAccept;

  /// Rejects an appeal.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get appealsReject;

  /// Title of the accept confirmation.
  ///
  /// In en, this message translates to:
  /// **'Accept this appeal?'**
  String get appealsAcceptTitle;

  /// Explains accepting an appeal.
  ///
  /// In en, this message translates to:
  /// **'Accepting counts the proof as verified.'**
  String get appealsAcceptBody;

  /// Title of the reject confirmation.
  ///
  /// In en, this message translates to:
  /// **'Reject this appeal?'**
  String get appealsRejectTitle;

  /// Explains rejecting an appeal.
  ///
  /// In en, this message translates to:
  /// **'Rejecting keeps the original decision.'**
  String get appealsRejectBody;

  /// Label of the appeal resolution note.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get appealsNoteLabel;

  /// Hint for the resolution note, which the participant sees.
  ///
  /// In en, this message translates to:
  /// **'Why, in a sentence. They\'ll see this.'**
  String get appealsNoteHint;

  /// Confirms an appeal decision.
  ///
  /// In en, this message translates to:
  /// **'Appeal decided.'**
  String get appealsSaved;

  /// Shown when an appeal decision fails.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save that. Try again.'**
  String get appealsSaveFailed;

  /// The app's name, shown in the task switcher and page headers.
  ///
  /// In en, this message translates to:
  /// **'Verily'**
  String get appTitle;

  /// The one-line promise of the product.
  ///
  /// In en, this message translates to:
  /// **'Do it, prove it, get paid.'**
  String get appTagline;

  /// A paragraph showing the body type role in the component gallery.
  ///
  /// In en, this message translates to:
  /// **'Real actions in real places, proof captured live on your phone, and rewards locked away before anyone starts. The first actions are on their way.'**
  String get skribblePreviewBodySample;

  /// Dismisses a dialog without making a change.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialogCancel;

  /// Closes a dialog or sheet after the person has finished.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get dialogDone;

  /// Repeats a request that did not work.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get dialogRetry;

  /// Closes a sheet, dialog, or page.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get dialogClose;

  /// Title of the settings page or sheet.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Tooltip and accessible label of the settings button.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get settingsOpenTooltip;

  /// Heading of the light and dark mode setting.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// Explains the appearance setting. Paper is the light theme and night the dark theme.
  ///
  /// In en, this message translates to:
  /// **'Paper by day, night after dark, or one of them all the time.'**
  String get appearanceSubtitle;

  /// Appearance choice that follows the device's light or dark setting.
  ///
  /// In en, this message translates to:
  /// **'Match device'**
  String get appearanceSystem;

  /// Describes the selected Match device appearance.
  ///
  /// In en, this message translates to:
  /// **'Follows your phone or browser automatically.'**
  String get appearanceSystemSubtitle;

  /// Appearance choice that always uses the light paper theme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceLight;

  /// Describes the selected light appearance.
  ///
  /// In en, this message translates to:
  /// **'Always warm paper and plum ink.'**
  String get appearanceLightSubtitle;

  /// Appearance choice that always uses the dark night theme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceDark;

  /// Describes the selected dark appearance.
  ///
  /// In en, this message translates to:
  /// **'Always deep night with paper ink.'**
  String get appearanceDarkSubtitle;

  /// Heading of the debug-only development menu.
  ///
  /// In en, this message translates to:
  /// **'Development menu'**
  String get developerMenuTitle;

  /// Accessible label of the button that closes the development menu.
  ///
  /// In en, this message translates to:
  /// **'Close development menu'**
  String get developerCloseMenu;

  /// Closes a debug-only developer surface.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get developerClose;

  /// Accessible label of the floating debug-only launcher.
  ///
  /// In en, this message translates to:
  /// **'Open developer tools'**
  String get developerIconTooltip;

  /// Development menu entry that reveals the floating launcher.
  ///
  /// In en, this message translates to:
  /// **'Show developer icon'**
  String get developerIconShow;

  /// Explains the Show developer icon entry.
  ///
  /// In en, this message translates to:
  /// **'Reveal the draggable launcher without reopening this menu.'**
  String get developerIconShowSubtitle;

  /// Drop target that hides the floating developer launcher.
  ///
  /// In en, this message translates to:
  /// **'Remove icon'**
  String get developerRemoveIcon;

  /// Label of the screen orientation detail in the development menu.
  ///
  /// In en, this message translates to:
  /// **'Orientation'**
  String get developerOrientationTitle;

  /// The app's locked screen orientation.
  ///
  /// In en, this message translates to:
  /// **'Portrait only'**
  String get developerPortraitOnly;

  /// Label of the server address detail in the development menu.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get developerServerTitle;

  /// Shown in the development menu when the build has no server.
  ///
  /// In en, this message translates to:
  /// **'Not connected in this build'**
  String get developerServerNotConfigured;

  /// Development menu entry and title of the component gallery.
  ///
  /// In en, this message translates to:
  /// **'Skribble component preview'**
  String get developerSkribblePreview;

  /// Explains the component gallery.
  ///
  /// In en, this message translates to:
  /// **'Hand-drawn components in the active Verily theme. Developer preview only.'**
  String get developerSkribblePreviewSubtitle;

  /// Development menu entry for live pose tracking.
  ///
  /// In en, this message translates to:
  /// **'Movement tracking preview'**
  String get developerMovementPreview;

  /// Explains the movement tracking preview.
  ///
  /// In en, this message translates to:
  /// **'Try live pose tracking for any movement without an action. Developer preview only.'**
  String get developerMovementPreviewSubtitle;

  /// Development menu entry that reassembles the widget tree.
  ///
  /// In en, this message translates to:
  /// **'Hot reload'**
  String get developerHotReload;

  /// Explains what the in-app hot reload entry does and does not do.
  ///
  /// In en, this message translates to:
  /// **'Reassemble the widget tree without clearing state. New code needs a reload from the terminal.'**
  String get developerHotReloadSubtitle;

  /// Development menu entry that rebuilds the app shell.
  ///
  /// In en, this message translates to:
  /// **'Full reload'**
  String get developerFullReload;

  /// Explains the Full reload entry.
  ///
  /// In en, this message translates to:
  /// **'Rebuild the app shell and return to the start screen.'**
  String get developerFullReloadSubtitle;

  /// Development menu entry that recreates the app from scratch.
  ///
  /// In en, this message translates to:
  /// **'Full restart'**
  String get developerFullRestart;

  /// Explains the Full restart entry.
  ///
  /// In en, this message translates to:
  /// **'Recreate the provider scope and app from scratch.'**
  String get developerFullRestartSubtitle;

  /// Label of the keyboard and gesture shortcut detail in the development menu.
  ///
  /// In en, this message translates to:
  /// **'Debug shortcuts'**
  String get developerDebugShortcutsTitle;

  /// Lists the debug-only shortcuts.
  ///
  /// In en, this message translates to:
  /// **'Shake the phone or press ⇧⌘D / Ctrl+Shift+D to open this menu. ⌘D / Ctrl+D reassembles the widget tree. Drag the launcher onto Remove icon to hide it.'**
  String get developerDebugShortcutsValue;

  /// Confirms a debug reassemble and where it was requested.
  ///
  /// In en, this message translates to:
  /// **'{source, select, menu{Widget tree reassembled from the development menu.} other{Widget tree reassembled from the keyboard shortcut.}}'**
  String developerReassembled(String source);

  /// Component gallery section showing the colour tones.
  ///
  /// In en, this message translates to:
  /// **'Colours'**
  String get skribblePreviewColorsHeading;

  /// Name of the neutral highlight wash used for selections and quiet invitations.
  ///
  /// In en, this message translates to:
  /// **'Highlight'**
  String get skribblePreviewToneNeutral;

  /// Sample of the vermilion stamp, which marks verified proof only.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get skribblePreviewToneStamp;

  /// Name of the place colour tone.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get skribblePreviewTonePlace;

  /// Name of the reward colour tone.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get skribblePreviewToneReward;

  /// Name of the review colour tone.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get skribblePreviewToneReview;

  /// Component gallery section showing the type scale.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get skribblePreviewTypeHeading;

  /// Name of the largest type role.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get skribblePreviewTypeDisplay;

  /// Name of the heading type role.
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get skribblePreviewTypeHeadline;

  /// Name of the title type role.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get skribblePreviewTypeTitle;

  /// Name of the body type role.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get skribblePreviewTypeBody;

  /// Name of the label type role.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get skribblePreviewTypeLabel;

  /// Name of the smallest type role.
  ///
  /// In en, this message translates to:
  /// **'Caption'**
  String get skribblePreviewTypeCaption;

  /// Names a type role with its font size and line height in logical pixels, such as 'Body · 16/23'.
  ///
  /// In en, this message translates to:
  /// **'{role} · {size}/{lineHeight}'**
  String skribblePreviewTypeRole(String role, int size, int lineHeight);

  /// Component gallery section showing buttons.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get skribblePreviewActionsHeading;

  /// Sample primary button label in the component gallery.
  ///
  /// In en, this message translates to:
  /// **'Publish action'**
  String get skribblePreviewPrimaryAction;

  /// Sample secondary button label in the component gallery.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get skribblePreviewSecondaryAction;

  /// Sample destructive button label in the component gallery.
  ///
  /// In en, this message translates to:
  /// **'Discard draft'**
  String get skribblePreviewDestructiveAction;

  /// Sample postcard headline in the component gallery.
  ///
  /// In en, this message translates to:
  /// **'Ten squats at the park'**
  String get skribblePreviewPostcardTitle;

  /// Sample postcard supporting line in the component gallery.
  ///
  /// In en, this message translates to:
  /// **'Proof is captured live, then checked against the place.'**
  String get skribblePreviewPostcardBody;

  /// Component gallery section showing empty, problem, and loading states.
  ///
  /// In en, this message translates to:
  /// **'States'**
  String get skribblePreviewStatesHeading;

  /// Sample empty-state title in the component gallery.
  ///
  /// In en, this message translates to:
  /// **'No actions nearby yet'**
  String get skribblePreviewEmptyTitle;

  /// Sample empty-state message in the component gallery.
  ///
  /// In en, this message translates to:
  /// **'Widen the map or post the first one here.'**
  String get skribblePreviewEmptyBody;

  /// Sample empty-state action in the component gallery.
  ///
  /// In en, this message translates to:
  /// **'Post an action'**
  String get skribblePreviewEmptyAction;

  /// Sample problem-state title in the component gallery.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load your proof'**
  String get skribblePreviewProblemTitle;

  /// Sample problem-state message in the component gallery.
  ///
  /// In en, this message translates to:
  /// **'The connection dropped before the upload finished. Reference VER-104.'**
  String get skribblePreviewProblemBody;

  /// Sample loading label in the component gallery.
  ///
  /// In en, this message translates to:
  /// **'Checking your proof…'**
  String get skribblePreviewLoading;

  /// Component gallery section showing text fields.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get skribblePreviewFieldsHeading;

  /// Sample text field label in the component gallery.
  ///
  /// In en, this message translates to:
  /// **'Action title'**
  String get skribblePreviewFieldLabel;

  /// Sample text field hint in the component gallery.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ten squats at the park'**
  String get skribblePreviewFieldHint;

  /// Component gallery section showing checkboxes, switches, radios, and sliders.
  ///
  /// In en, this message translates to:
  /// **'Selection'**
  String get skribblePreviewSelectionHeading;

  /// Sample checkbox label in the component gallery.
  ///
  /// In en, this message translates to:
  /// **'Tell me when my proof is reviewed'**
  String get skribblePreviewNotifyCheckboxLabel;

  /// Sample switch label in the component gallery.
  ///
  /// In en, this message translates to:
  /// **'Roughen the preview'**
  String get skribblePreviewRoughenSwitchLabel;

  /// Component gallery section showing decorative doodles and icons.
  ///
  /// In en, this message translates to:
  /// **'Doodles and icons'**
  String get skribblePreviewDoodlesHeading;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
