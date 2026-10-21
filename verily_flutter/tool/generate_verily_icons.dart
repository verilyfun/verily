// Generates lib/app/theme/verily_icons.g.dart, the app's hand-drawn icon
// vocabulary.
//
// Skribble's own glyphs are referenced directly. Concepts the glyph set does
// not draw come from the Skribble-roughened Lucide catalog, and only the
// drawings listed here are copied into the app as constants, so the app never
// ships the other two thousand icons and every icon stays `const`.
//
//   dart run tool/generate_verily_icons.dart          # write the catalog
//   dart run tool/generate_verily_icons.dart --check  # fail if it is stale
import 'dart:io';
import 'dart:isolate';

/// Where an icon's drawing comes from.
sealed class IconSource {
  const IconSource();
}

/// One of Skribble's own interface glyphs, by `SkribbleGlyphs` member name.
final class Glyph extends IconSource {
  const Glyph(this.name);
  final String name;
}

/// A Skribble-roughened Lucide drawing, by Lucide identifier.
final class Lucide extends IconSource {
  const Lucide(this.identifier);
  final String identifier;
}

typedef IconEntry = ({String name, IconSource source, String doc});

/// The catalog, in the order it is written. Name icons by what they mean in
/// Verily, not by what they depict, so a drawing can change without renaming
/// every call site. Keep it to what the app draws: every entry ships.
const List<IconEntry> catalog = [
  // Movement through the app.
  (
    name: 'back',
    source: Glyph('arrowLeft'),
    doc: 'Return to the previous page.',
  ),
  (
    name: 'forward',
    source: Glyph('arrowRight'),
    doc: 'Continue to the next step.',
  ),
  (
    name: 'chevronRight',
    source: Glyph('chevronRight'),
    doc: 'Open the item or step forward within a set.',
  ),
  (
    name: 'externalLink',
    source: Lucide('external-link'),
    doc: 'Opens outside the app.',
  ),
  (name: 'close', source: Glyph('close'), doc: 'Dismiss or clear.'),
  (name: 'chevronDown', source: Glyph('chevronDown'), doc: 'Show more.'),
  (name: 'search', source: Glyph('search'), doc: 'Search.'),
  (name: 'share', source: Glyph('share'), doc: 'Share outside the app.'),
  (name: 'link', source: Glyph('link'), doc: 'A link or a linked account.'),

  // Everyday actions.
  (name: 'check', source: Glyph('check'), doc: 'Done, selected, or confirmed.'),
  (name: 'plus', source: Glyph('plus'), doc: 'Add something new.'),
  (name: 'minus', source: Glyph('minus'), doc: 'Take one away, or zoom out.'),
  (name: 'refresh', source: Glyph('refresh'), doc: 'Load again or sync.'),
  (
    name: 'replay',
    source: Lucide('rotate-ccw'),
    doc: 'Try again from the start.',
  ),
  (name: 'edit', source: Glyph('edit'), doc: 'Edit.'),
  (name: 'draw', source: Lucide('pen-line'), doc: 'Write or draw by hand.'),
  (name: 'copy', source: Glyph('copy'), doc: 'Copy to the clipboard.'),
  (name: 'delete', source: Glyph('delete'), doc: 'Remove.'),
  (
    name: 'sliders',
    source: Lucide('sliders-horizontal'),
    doc: 'Adjust settings or filters.',
  ),

  // Time.
  (name: 'clock', source: Glyph('clock'), doc: 'A time or a wait.'),
  (name: 'calendar', source: Glyph('calendar'), doc: 'A date.'),
  (name: 'once', source: Lucide('calendar-1'), doc: 'Happens once.'),
  (name: 'hourglass', source: Lucide('hourglass'), doc: 'Still waiting.'),

  // Capturing proof.
  (name: 'camera', source: Glyph('camera'), doc: 'Take a photo.'),
  (
    name: 'cameraSwitch',
    source: Lucide('switch-camera'),
    doc: 'Switch between the front and back cameras.',
  ),
  (name: 'photo', source: Glyph('image'), doc: 'Photo proof.'),
  (name: 'video', source: Lucide('video'), doc: 'Video proof.'),
  (name: 'videoOff', source: Lucide('video-off'), doc: 'Video unavailable.'),
  (name: 'microphone', source: Lucide('mic'), doc: 'Audio proof.'),
  (
    name: 'microphoneOff',
    source: Lucide('mic-off'),
    doc: 'Microphone unavailable.',
  ),
  (name: 'timer', source: Lucide('timer'), doc: 'Time left to record.'),
  (name: 'record', source: Lucide('disc'), doc: 'Start recording.'),
  (name: 'stop', source: Lucide('circle-stop'), doc: 'Stop recording.'),
  (name: 'play', source: Lucide('play'), doc: 'Play.'),
  (
    name: 'playCircle',
    source: Lucide('circle-play'),
    doc: 'Start playback or a capture.',
  ),
  (name: 'pause', source: Lucide('pause'), doc: 'Pause.'),
  (name: 'pauseCircle', source: Lucide('circle-pause'), doc: 'Paused.'),
  (name: 'qrCode', source: Lucide('qr-code'), doc: 'A venue code to show.'),
  (name: 'scan', source: Lucide('scan-line'), doc: 'Scan a venue code.'),

  // Status.
  (name: 'circleCheck', source: Lucide('circle-check'), doc: 'Complete.'),
  (name: 'info', source: Glyph('info'), doc: 'More information.'),
  (
    name: 'warning',
    source: Glyph('warning'),
    doc: 'Needs attention before continuing.',
  ),
  (name: 'circlePlus', source: Lucide('circle-plus'), doc: 'Add another.'),
  (name: 'cloudOff', source: Lucide('cloud-off'), doc: 'Offline.'),
  (name: 'eye', source: Glyph('eye'), doc: 'Show.'),
  (name: 'lock', source: Glyph('lock'), doc: 'Locked or private.'),
  (name: 'unlock', source: Glyph('unlock'), doc: 'Unlocked.'),

  // Trust and rewards.
  (
    name: 'shieldCheck',
    source: Lucide('shield-check'),
    doc: 'Protected and verified.',
  ),
  (name: 'verified', source: Lucide('badge-check'), doc: 'Verified proof.'),
  (name: 'key', source: Lucide('key-round'), doc: 'A sign-in or signing key.'),
  (
    name: 'wallet',
    source: Lucide('wallet'),
    doc: 'A wallet that pays or receives.',
  ),
  (
    name: 'escrow',
    source: Lucide('lock-keyhole'),
    doc: 'A reward locked in escrow.',
  ),
  (name: 'coins', source: Lucide('coins'), doc: 'A reward amount.'),
  (name: 'award', source: Lucide('award'), doc: 'A reward earned.'),
  (
    name: 'celebration',
    source: Lucide('party-popper'),
    doc: 'A confirmed outcome.',
  ),
  (name: 'document', source: Lucide('file-text'), doc: 'A document.'),

  // People and places.
  (name: 'users', source: Lucide('users'), doc: 'People taking part.'),
  (name: 'user', source: Glyph('user'), doc: 'You and your account.'),
  (name: 'mail', source: Glyph('mail'), doc: 'Email.'),
  (name: 'logOut', source: Lucide('log-out'), doc: 'Sign out.'),
  (name: 'pin', source: Glyph('pin'), doc: 'A place.'),
  (
    name: 'mapPin',
    source: Lucide('map-pin'),
    doc: "An action's place on a map.",
  ),
  (name: 'map', source: Lucide('map'), doc: 'A map of places.'),
  (name: 'nearby', source: Lucide('navigation'), doc: 'Near you.'),
  (
    name: 'myLocation',
    source: Lucide('locate-fixed'),
    doc: 'Use the current location.',
  ),
  (name: 'globe', source: Lucide('globe'), doc: 'Public, or anywhere.'),
  (
    name: 'network',
    source: Lucide('network'),
    doc: 'A connected service that confirms an action.',
  ),
  (name: 'store', source: Lucide('store'), doc: 'A venue.'),
  (name: 'chat', source: Lucide('message-circle'), doc: 'Conversation.'),
  (name: 'megaphone', source: Lucide('megaphone'), doc: 'A sponsored action.'),

  // Actions and reviews.
  (name: 'explore', source: Lucide('compass'), doc: 'Discover actions.'),
  (name: 'bolt', source: Lucide('zap'), doc: 'An action to do.'),
  (name: 'sparkle', source: Glyph('sparkle'), doc: 'Something new.'),
  (name: 'layout', source: Lucide('layout-dashboard'), doc: 'A template.'),
  (name: 'rocket', source: Lucide('rocket'), doc: 'Publish an action.'),
  (name: 'flag', source: Glyph('flag'), doc: 'A goal or a report.'),
  (
    name: 'checklist',
    source: Lucide('clipboard-check'),
    doc: 'Requirements to meet.',
  ),
  (
    name: 'review',
    source: Lucide('message-square-text'),
    doc: 'Review submitted proof.',
  ),

  // Movement proof.
  (name: 'vibrate', source: Lucide('vibrate'), doc: 'Motion sensing.'),
  (
    name: 'rotatePhone',
    source: Lucide('rotate-cw-square'),
    doc: 'Rotate the phone.',
  ),
  (name: 'spin', source: Lucide('rotate-3d'), doc: 'Turn all the way around.'),
  (
    name: 'toss',
    source: Lucide('arrow-up-to-line'),
    doc: 'Toss the phone gently upward.',
  ),
  (name: 'hand', source: Lucide('hand'), doc: 'Hold steady.'),
  (name: 'tap', source: Lucide('pointer'), doc: 'Tap.'),
  (name: 'run', source: Lucide('footprints'), doc: 'Movement actions.'),
  (name: 'dumbbell', source: Lucide('dumbbell'), doc: 'Exercise.'),

  // Appearance and developer surfaces.
  (name: 'settings', source: Glyph('settings'), doc: 'Settings.'),
  (name: 'sun', source: Glyph('sun'), doc: 'Light appearance.'),
  (name: 'moon', source: Glyph('moon'), doc: 'Dark appearance.'),
  (
    name: 'themeAuto',
    source: Lucide('sun-moon'),
    doc: 'Follow the device appearance.',
  ),
  (name: 'developer', source: Lucide('code'), doc: 'Developer tools.'),
  (name: 'server', source: Lucide('server'), doc: 'A server.'),
  (name: 'monitor', source: Lucide('monitor'), doc: 'A desktop browser.'),
];

const _lucideSource =
    'package:skribble_icons_lucide/src/generated/lucide_icons.g.dart';
const _outputPath = 'lib/app/theme/verily_icons.g.dart';

Future<void> main(List<String> arguments) async {
  final check = arguments.contains('--check');
  final rendered = await renderCatalog();
  final output = File(_outputPath);

  if (check) {
    if (!output.existsSync() || output.readAsStringSync() != rendered) {
      stderr.writeln(
        '$_outputPath is stale. Run: dart run tool/generate_verily_icons.dart',
      );
      exitCode = 1;
    }
    return;
  }

  output.writeAsStringSync(rendered);
  stdout.writeln('Wrote ${catalog.length} icons to $_outputPath');
}

/// Renders the catalog from the Lucide drawings the resolved package ships.
Future<String> renderCatalog() async {
  final uri = await Isolate.resolvePackageUri(Uri.parse(_lucideSource));
  if (uri == null) {
    throw StateError('Cannot resolve $_lucideSource. Run `flutter pub get`.');
  }
  return _format(render(File.fromUri(uri).readAsStringSync()));
}

/// Formats [source] as the repository's format gate would format the file.
Future<String> _format(String source) async {
  final process = await Process.start(Platform.resolvedExecutable, [
    'format',
    '--stdin-name',
    _outputPath,
  ]);
  process.stdin.write(source);
  await process.stdin.close();
  final (formatted, errors, code) = await (
    process.stdout.transform(systemEncoding.decoder).join(),
    process.stderr.transform(systemEncoding.decoder).join(),
    process.exitCode,
  ).wait;
  if (code != 0) {
    throw StateError('dart format failed: $errors');
  }
  return formatted;
}

/// Renders the catalog from the text of Lucide's generated catalog.
String render(String lucideSource) {
  final names = <String>{};
  final buffer = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.')
    ..writeln('// Regenerate with: dart run tool/generate_verily_icons.dart')
    ..writeln('// ignore_for_file: lines_longer_than_80_chars')
    ..writeln('//')
    ..writeln('// Lucide drawings are ISC licensed, copyright Lucide')
    ..writeln('// contributors (https://lucide.dev), as roughened by the')
    ..writeln('// skribble_icons_lucide package.')
    ..writeln()
    ..writeln("import 'package:skribble/skribble.dart';")
    ..writeln()
    ..writeln("/// Verily's hand-drawn icon vocabulary.")
    ..writeln('///')
    ..writeln(
      '/// Every icon is a stroke drawing inked by the active Skribble pen,',
    )
    ..writeln(
      '/// so it follows the theme and never renders a vector font glyph.',
    )
    ..writeln('/// Draw one with `SkribbleIcon(data: VerilyIcons.bolt)`.')
    ..writeln('abstract final class VerilyIcons {');

  for (final entry in catalog) {
    if (!names.add(entry.name)) {
      throw StateError('Duplicate icon name: ${entry.name}');
    }
    buffer
      ..writeln('  /// ${entry.doc}')
      ..writeln(switch (entry.source) {
        Glyph(:final name) =>
          '  static const ${entry.name} = SkribbleGlyphs.$name;',
        Lucide(:final identifier) =>
          '  static const ${entry.name} = ${_lucideDrawing(lucideSource, identifier)};',
      })
      ..writeln();
  }

  return '${buffer.toString().trimRight()}\n}\n';
}

/// Copies one `WiredSvgIconData(...)` literal out of Lucide's catalog.
String _lucideDrawing(String source, String identifier) {
  final codePoint = RegExp(
    "^  '${RegExp.escape(identifier)}': (0x[0-9a-f]+),\$",
    multiLine: true,
  ).firstMatch(source)?.group(1);
  if (codePoint == null) {
    throw StateError('Lucide has no icon named "$identifier".');
  }

  const opener = 'WiredSvgIconData(';
  final start = source.indexOf('  $codePoint: $opener');
  if (start < 0) {
    throw StateError('Lucide has no drawing for $identifier ($codePoint).');
  }
  final literalStart = source.indexOf(opener, start);
  var depth = 0;
  for (var index = literalStart; index < source.length; index++) {
    final char = source[index];
    if (char == '(') depth++;
    if (char == ')' && --depth == 0) {
      // Re-indent the literal from its map-entry depth to a class member.
      return source.substring(literalStart, index + 1).replaceAll('\n  ', '\n');
    }
  }
  throw StateError('Unterminated drawing for $identifier.');
}
