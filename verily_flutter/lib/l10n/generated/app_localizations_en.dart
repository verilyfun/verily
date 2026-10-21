// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Verily';

  @override
  String get appTagline => 'Do it, prove it, get paid.';

  @override
  String get placeholderTitle => 'Do it. Prove it. Get paid.';

  @override
  String get placeholderBody =>
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
}
