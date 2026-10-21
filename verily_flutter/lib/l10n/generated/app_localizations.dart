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

  /// Headline of the welcome card shown before actions are available.
  ///
  /// In en, this message translates to:
  /// **'Do it. Prove it. Get paid.'**
  String get placeholderTitle;

  /// Supporting copy of the welcome card shown before actions are available.
  ///
  /// In en, this message translates to:
  /// **'Real actions in real places, proof captured live on your phone, and rewards locked away before anyone starts. The first actions are on their way.'**
  String get placeholderBody;

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
