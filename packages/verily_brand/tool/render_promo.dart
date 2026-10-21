// Renders Verily's launch media: the 30-second promo reel (with and without
// its sound bed) and the 1280x800 cover.
//
//   dart run tool/render_promo.dart [--out <dir>] [--no-audio] [--keep-frames]
//                                   [--flutter <path>]
//
// Frames come from tool/render_promo_test.dart on the Flutter test clock, so
// every run is identical. ffmpeg encodes them as 1920x1080 H.264 at 30
// frames a second and scores a quiet procedural sound bed from the same
// PromoTimeline the reel animates from, so the stamp thunks on the frame it
// lands. Output defaults to <repo>/.screenshots/promo, which is gitignored:
// share the files on the launch, a release, or a pull request.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:verily_brand/promo/promo_timeline.dart';

typedef _T = PromoTimeline;

Future<void> main(List<String> arguments) async {
  final _Options options;
  try {
    options = _Options.parse(arguments);
  } on FormatException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln(_Options.usage);
    exitCode = 64;
    return;
  }
  if (options.help) {
    stdout.writeln(_Options.usage);
    return;
  }
  try {
    await _render(options);
  } on _ToolFailure catch (failure) {
    stderr.writeln('render_promo: ${failure.message}');
    exitCode = 1;
  }
}

Future<void> _render(_Options options) async {
  final package = Directory.fromUri(Platform.script.resolve('..'));
  final out = Directory(
    options.out ?? '${package.parent.parent.path}/.screenshots/promo',
  )..createSync(recursive: true);
  final silent = '${out.path}/verily-promo-silent.mp4';
  await _requireTool('ffmpeg', ['-version']);

  final scratch = Directory.systemTemp.createTempSync('verily-promo-');
  final frames = Directory('${scratch.path}/frames')..createSync();
  try {
    if (options.remux) {
      if (!File(silent).existsSync()) {
        throw _ToolFailure('--remux needs $silent; render it first.');
      }
    } else {
      final flutter = options.flutter ?? _defaultFlutter();
      await _requireTool(flutter, ['--version']);
      stdout.writeln('Rendering ${(_T.duration * _T.fps).round()} frames...');
      await _run(flutter, [
        'test',
        'tool/render_promo_test.dart',
        '--dart-define=PROMO_OUT=${frames.path}',
      ], workingDirectory: package.path);

      stdout.writeln('Rendering the cover...');
      await _run(flutter, [
        'test',
        'tool/render_cover_test.dart',
        '--dart-define=COVER_OUT=${out.path}',
      ], workingDirectory: package.path);

      stdout.writeln('Encoding $silent...');
      await _run('ffmpeg', [
        '-hide_banner',
        '-loglevel',
        'error',
        '-y',
        '-framerate',
        '${_T.fps}',
        '-i',
        '${frames.path}/%05d.png',
        '-c:v',
        'libx264',
        '-preset',
        'slow',
        '-crf',
        '18',
        '-pix_fmt',
        'yuv420p',
        '-r',
        '${_T.fps}',
        '-movflags',
        '+faststart',
        silent,
      ]);
    }

    if (options.audio) {
      final bed = '${scratch.path}/bed.wav';
      stdout.writeln('Scoring the sound bed...');
      await _scoreBed(scratch, bed);
      final promo = '${out.path}/verily-promo.mp4';
      stdout.writeln('Muxing $promo...');
      await _run('ffmpeg', [
        '-hide_banner',
        '-loglevel',
        'error',
        '-y',
        '-i',
        silent,
        '-i',
        bed,
        '-map',
        '0:v',
        '-map',
        '1:a',
        '-c:v',
        'copy',
        '-c:a',
        'aac',
        '-b:a',
        '192k',
        '-shortest',
        '-movflags',
        '+faststart',
        promo,
      ]);
      await _reportLevels(promo);
    }
    stdout.writeln('Done: ${out.path}');
  } finally {
    if (options.keepFrames && !options.remux) {
      stdout.writeln('Frames kept in ${frames.path}');
    } else {
      scratch.deleteSync(recursive: true);
    }
  }
}

// ---------------------------------------------------------------------------
// The sound bed
// ---------------------------------------------------------------------------

/// Loudness the finished bed is normalised to, in LUFS.
const double _targetLoudness = -16;

/// The true-peak ceiling, in dBTP.
const double _peakCeiling = -1.5;

/// Renders the bed to [path]: three ffmpeg-synthesised layers (plucked
/// notes, pencil scratches, the stamp's thunk), mixed, faded, and normalised
/// in two loudnorm passes.
Future<void> _scoreBed(Directory scratch, String path) async {
  final graph = File('${scratch.path}/bed.graph');
  final raw = '${scratch.path}/bed-raw.wav';
  graph.writeAsStringSync(_bedGraph());
  await _run('ffmpeg', [
    '-hide_banner',
    '-loglevel',
    'error',
    '-y',
    '-/filter_complex',
    graph.path,
    '-map',
    '[bed]',
    '-c:a',
    'pcm_f32le',
    raw,
  ]);

  // First pass: measure. Second pass: normalise linearly to the target.
  final measure = await Process.run('ffmpeg', [
    '-hide_banner',
    '-i',
    raw,
    '-af',
    'loudnorm=I=$_targetLoudness:TP=$_peakCeiling:LRA=11:print_format=json',
    '-f',
    'null',
    '-',
  ]);
  final log = measure.stderr as String;
  final json = log.substring(log.lastIndexOf('{'), log.lastIndexOf('}') + 1);
  final measured = jsonDecode(json);
  if (measured is! Map<String, Object?>) {
    throw const _ToolFailure('loudnorm did not report its measurements.');
  }
  String value(String key) => switch (measured[key]) {
    final String v => v,
    _ => throw _ToolFailure('loudnorm did not report $key.'),
  };
  await _run('ffmpeg', [
    '-hide_banner',
    '-loglevel',
    'error',
    '-y',
    '-i',
    raw,
    '-af',
    [
      'loudnorm=I=$_targetLoudness:TP=$_peakCeiling:LRA=11',
      'measured_I=${value('input_i')}',
      'measured_TP=${value('input_tp')}',
      'measured_LRA=${value('input_lra')}',
      'measured_thresh=${value('input_thresh')}',
      'offset=${value('target_offset')}',
      'linear=true',
    ].join(':'),
    '-ar',
    '48000',
    '-c:a',
    'pcm_s16le',
    path,
  ]);
}

/// The ffmpeg filtergraph for the bed. Every event time comes from
/// [PromoTimeline].
String _bedGraph() {
  const rate = 48000;
  final length = _T.duration.toStringAsFixed(2);
  String source(String expression, String label, {String filters = ''}) =>
      "aevalsrc=exprs='$expression':s=$rate:d=$length,"
      '${filters}aformat=channel_layouts=mono[$label]';

  // ffmpeg's expression evaluator nests about a hundred operations deep, so
  // the notes are summed in groups, one source each, and mixed.
  const group = 48;
  final notes = _notes();
  final parts = <String>[];
  final labels = <String>[];
  for (var start = 0; start < notes.length; start += group) {
    final label = 'notes${labels.length}';
    final chunk = notes.skip(start).take(group);
    parts.add(source(chunk.map((note) => note.expression).join('+'), label));
    labels.add('[$label]');
  }
  return [
    ...parts,
    '${labels.join()}amix=inputs=${labels.length}:normalize=0[music]',
    source(
      _pencil(),
      'pencil',
      filters: 'highpass=f=1800,lowpass=f=4500:poles=2,lowpass=f=4500:poles=2,',
    ),
    source(
      _thunk(_T.stampImpact),
      'thunk',
      filters: 'highpass=f=100:poles=2,lowpass=f=1200,',
    ),
    [
      '[music][pencil][thunk]amix=inputs=3:weights=1 0.55 1.3:normalize=0',
      // Nothing below 70 Hz: phones cannot play it and it only eats headroom.
      'highpass=f=70:poles=2',
      'highpass=f=70:poles=2',
      'afade=t=in:st=0:d=0.3',
      'afade=t=out:st=${(_T.duration - 1.4).toStringAsFixed(2)}:d=1.4',
      'aformat=channel_layouts=stereo[bed]',
    ].join(','),
  ].join(';\n');
}

/// Note frequencies in C major pentatonic (plus their octaves).
abstract final class _Hz {
  static const double g2 = 98;
  static const double a2 = 110;
  static const double c3 = 130.81;
  static const double c4 = 261.63;
  static const double e4 = 329.63;
  static const double g4 = 392;
  static const double a4 = 440;
  static const double c5 = 523.25;
  static const double d5 = 587.33;
  static const double e5 = 659.25;
  static const double g5 = 783.99;
  static const double a5 = 880;
  static const double c6 = 1046.5;
  static const double d6 = 1174.66;
  static const double e6 = 1318.51;
  static const double g6 = 1567.98;
  static const double a6 = 1760;
  static const double c7 = 2093;
  static const double e7 = 2637.02;
  static const double g7 = 3135.96;
}

/// A plucked note: a soft attack, then an exponential decay, with a quieter
/// octave partial that fades faster.
final class _Pluck {
  const _Pluck(
    this.at,
    this.hz,
    this.gain, {
    this.decay = 5,
    this.attack = 260,
  });

  final double at;
  final double hz;
  final double gain;
  final double decay;

  /// How fast the note reaches full level; lower is a softer onset.
  final double attack;

  String get expression {
    final a = at.toStringAsFixed(4);
    final ring = math.min(5 / decay, 3.5).toStringAsFixed(3);
    final x = '(t-$a)';
    return 'if(between(t,$a,$a+$ring),'
        '${gain.toStringAsFixed(4)}*(1-exp(-$attack*$x))*exp(-$decay*$x)*'
        '(sin(2*PI*${hz.toStringAsFixed(2)}*$x)'
        '+0.3*exp(-${decay * 1.5}*$x)*sin(4*PI*${hz.toStringAsFixed(2)}*$x)),0)';
  }
}

/// Every plucked note in the reel, in time order.
List<_Pluck> _notes() {
  const beat = 60 / 100;
  final notes = <_Pluck>[];

  // A soft root on each bar's downbeat (C, A, C, G), short and quiet so it
  // supports the plucks instead of thumping, until the end card resolves
  // home to C.
  const roots = [_Hz.c3, _Hz.a2, _Hz.c3, _Hz.g2];
  for (var bar = 0; bar * 4 * beat < _T.end.start; bar++) {
    notes.add(
      _Pluck(
        bar * 4 * beat,
        roots[bar % roots.length],
        0.045,
        decay: 4.5,
        attack: 90,
      ),
    );
  }
  notes.add(
    _Pluck(_T.endLockup.start, _Hz.c3, 0.055, decay: 3, attack: 90),
  );

  // A soft eighth-note arpeggio over the same chords while there is room for
  // it: not under the squats, which play their own notes.
  const arpeggios = [
    [_Hz.c5, _Hz.g5, _Hz.e5, _Hz.g5, _Hz.c5, _Hz.g5, _Hz.e5, _Hz.a5],
    [_Hz.a4, _Hz.e5, _Hz.c5, _Hz.e5, _Hz.a4, _Hz.e5, _Hz.c5, _Hz.g5],
    [_Hz.c5, _Hz.g5, _Hz.e5, _Hz.g5, _Hz.c5, _Hz.g5, _Hz.e5, _Hz.d5],
    [_Hz.g4, _Hz.d5, _Hz.g5, _Hz.d5, _Hz.g4, _Hz.d5, _Hz.e5, _Hz.d5],
  ];
  final quiet = [
    PromoCue(0, _T.hookLockup.start),
    PromoCue(_T.doIt.start, _T.doIt.end),
    PromoCue(_T.end.start + .3, _T.duration),
  ];
  for (var eighth = 0; eighth * beat / 2 < _T.duration; eighth++) {
    final at = eighth * beat / 2;
    if (quiet.any((cue) => at >= cue.start && at < cue.end)) continue;
    final bar = eighth ~/ 8;
    notes.add(
      _Pluck(at, arpeggios[bar % arpeggios.length][eighth % 8], 0.055),
    );
  }

  // Each squat plays the next note up the scale, landing on a high C.
  const climb = [
    _Hz.c5,
    _Hz.d5,
    _Hz.e5,
    _Hz.g5,
    _Hz.a5,
    _Hz.c6,
    _Hz.d6,
    _Hz.e6,
    _Hz.g6,
    _Hz.c6,
  ];
  for (final (i, at) in _T.repTimes.indexed) {
    notes.add(_Pluck(at, climb[i], 0.11, decay: 6));
    if (i == climb.length - 1) {
      notes
        ..add(_Pluck(at, _Hz.e6, 0.07, decay: 4))
        ..add(_Pluck(at, _Hz.g6, 0.06, decay: 4));
    }
  }

  // The checklist ticks up a chord.
  const ticks = [_Hz.e5, _Hz.g5, _Hz.a5, _Hz.c6, _Hz.e6];
  for (final (i, at) in _T.ticks.indexed) {
    notes.add(_Pluck(at, ticks[i], 0.1, decay: 7));
  }

  // Pops: a light two-note blip.
  for (final at in _T.pops) {
    notes
      ..add(_Pluck(at, _Hz.g5, 0.05, decay: 12))
      ..add(_Pluck(at + .05, _Hz.c6, 0.05, decay: 12));
  }

  // The pin lands with a low bloop.
  notes.add(_Pluck(_T.pinDrop.at(.55), _Hz.c4, 0.14, decay: 8));

  // Coins clink: bright, short, and in key.
  void clink(double at, double gain) => notes
    ..add(_Pluck(at, _Hz.c7, gain, decay: 16))
    ..add(_Pluck(at + .012, _Hz.e7, gain * .8, decay: 18))
    ..add(_Pluck(at + .02, _Hz.g7, gain * .5, decay: 20));
  for (final at in _T.coinLandings) {
    clink(at, 0.045);
  }
  clink(_T.payout.end, 0.05);
  for (final (i, hz) in const [_Hz.c6, _Hz.e6, _Hz.g6, _Hz.c7].indexed) {
    notes.add(_Pluck(_T.payout.end + .08 + i * .07, hz, 0.06, decay: 6));
  }

  // The seal shimmers past.
  for (final (i, hz) in const [
    _Hz.g6,
    _Hz.a6,
    _Hz.c7,
    _Hz.a6,
    _Hz.g6,
    _Hz.e6,
  ].indexed) {
    notes.add(_Pluck(_T.seal.start + .1 + i * .15, hz, 0.025, decay: 9));
  }

  // The end card strums a C major chord, then rings out.
  for (final (i, hz) in const [
    _Hz.c4,
    _Hz.e4,
    _Hz.g4,
    _Hz.c5,
    _Hz.e5,
  ].indexed) {
    notes.add(_Pluck(_T.endLockup.start + i * .06, hz, 0.075, decay: 1.4));
  }
  notes
    ..add(const _Pluck(_T.tagline, _Hz.g5, 0.05, decay: 3))
    ..add(const _Pluck(_T.url, _Hz.c6, 0.05, decay: 3));

  return notes..sort((a, b) => a.at.compareTo(b.at));
}

/// Filtered-noise pencil scratches while a pen writes, the strike through
/// "didn't", and the padlock's click.
String _pencil() {
  final parts = <String>[];
  for (final cue in _T.pencilWork) {
    final a = cue.start.toStringAsFixed(3);
    final b = cue.end.toStringAsFixed(3);
    // A soft scribbly texture: the level sways with the strokes but never
    // drops to silence, so it reads as a pencil, not as clicks.
    parts.add(
      'if(between(t,$a,$b),0.03*min(1,(t-$a)*8)*min(1,($b-t)*8)*'
      '(0.35+0.65*pow(abs(sin(2*PI*7*t+1.7*sin(2*PI*1.3*t))),2))*'
      '(random(0)*2-1),0)',
    );
  }
  const strike = _T.strike;
  parts.add(
    'if(between(t,${strike.start},${strike.end}),'
    '0.12*sin(PI*(t-${strike.start})/${strike.length.toStringAsFixed(3)})*'
    '(random(0)*2-1),0)',
  );
  final lock = _T.lockSnap.toStringAsFixed(3);
  parts.add(
    'if(between(t,$lock,$lock+0.08),0.15*exp(-60*(t-$lock))*(random(0)*2-1),0)',
  );
  return parts.join('+');
}

/// The stamp landing at [at]: a short, warm thud in the low mids, and a
/// papery smack.
String _thunk(double at) {
  final a = at.toStringAsFixed(4);
  final x = '(t-$a)';
  // The pitch falls from 200 Hz to 120 Hz in a few hundredths of a second,
  // with an octave above for warmth; nothing reaches the sub range.
  final phase = '(120*$x+80*(1-exp(-25*$x))/25)';
  final body =
      '0.5*(1-exp(-300*$x))*exp(-16*$x)*'
      '(sin(2*PI*$phase)+0.35*sin(4*PI*$phase))';
  final smack = '0.2*exp(-70*$x)*(random(1)*2-1)';
  return 'if(between(t,$a,$a+0.4),$body+$smack,0)';
}

/// Prints the finished file's loudness and peaks, and fails if it clips.
Future<void> _reportLevels(String path) async {
  final result = await Process.run('ffmpeg', [
    '-hide_banner',
    '-i',
    path,
    '-vn',
    '-af',
    'ebur128=peak=true,volumedetect',
    '-f',
    'null',
    '-',
  ]);
  final log = result.stderr as String;
  String? find(RegExp pattern) => pattern.allMatches(log).lastOrNull?.group(1);
  final integrated = find(RegExp(r'I:\s+(-?[\d.]+) LUFS'));
  final truePeak = find(RegExp(r'Peak:\s+(-?[\d.]+) dBFS'));
  final maxVolume = find(RegExp(r'max_volume:\s+(-?[\d.]+) dB'));
  final meanVolume = find(RegExp(r'mean_volume:\s+(-?[\d.]+) dB'));
  stdout.writeln(
    'Audio: integrated $integrated LUFS, true peak $truePeak dBTP, '
    'max $maxVolume dB, mean $meanVolume dB',
  );
  final peak = double.tryParse(maxVolume ?? '');
  if (peak == null) {
    throw _ToolFailure('could not measure the audio in $path.');
  }
  if (peak > -0.5) {
    throw _ToolFailure('the sound bed peaks at $peak dB and may clip.');
  }
}

// ---------------------------------------------------------------------------
// Processes and options
// ---------------------------------------------------------------------------

/// The `flutter` beside the Dart SDK running this tool, when there is one.
String _defaultFlutter() {
  if (Platform.environment['FLUTTER'] case final String path?) return path;
  // <flutter>/bin/cache/dart-sdk/bin/dart -> <flutter>/bin/flutter
  final dart = File(Platform.resolvedExecutable);
  final bin = dart.parent.parent.parent.parent;
  final flutter = File('${bin.path}/flutter');
  return flutter.existsSync() ? flutter.path : 'flutter';
}

Future<void> _requireTool(String executable, List<String> arguments) async {
  try {
    final result = await Process.run(executable, arguments);
    if (result.exitCode == 0) return;
  } on ProcessException {
    // Reported below.
  }
  throw _ToolFailure('$executable is required but could not be run.');
}

Future<void> _run(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
}) async {
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    mode: ProcessStartMode.inheritStdio,
  );
  final code = await process.exitCode;
  if (code != 0) {
    throw _ToolFailure('$executable ${arguments.first} exited with $code.');
  }
}

final class _ToolFailure implements Exception {
  const _ToolFailure(this.message);

  final String message;
}

final class _Options {
  const _Options({
    required this.audio,
    required this.keepFrames,
    required this.remux,
    required this.help,
    this.out,
    this.flutter,
  });

  factory _Options.parse(List<String> arguments) {
    String? out;
    String? flutter;
    var audio = true;
    var keepFrames = false;
    var remux = false;
    var help = false;
    final queue = [...arguments];
    String value(String flag) {
      if (queue.isEmpty) throw FormatException('$flag needs a value.');
      return queue.removeAt(0);
    }

    while (queue.isNotEmpty) {
      switch (queue.removeAt(0)) {
        case '--out':
          out = value('--out');
        case '--flutter':
          flutter = value('--flutter');
        case '--no-audio':
          audio = false;
        case '--keep-frames':
          keepFrames = true;
        case '--remux':
          remux = true;
        case '-h' || '--help':
          help = true;
        case final other:
          throw FormatException('Unknown option: $other');
      }
    }
    if (remux && !audio) {
      throw const FormatException('--remux and --no-audio contradict.');
    }
    return _Options(
      audio: audio,
      keepFrames: keepFrames,
      remux: remux,
      help: help,
      out: out,
      flutter: flutter,
    );
  }

  static const String usage = r'''
Usage: dart run tool/render_promo.dart [options]

  --out <dir>        Where to write the files (default: <repo>/.screenshots/promo)
  --no-audio         Encode only verily-promo-silent.mp4
  --keep-frames      Keep the rendered PNG frames
  --remux            Re-score the sound bed onto an existing
                     verily-promo-silent.mp4 in --out, without re-rendering
  --flutter <path>   The flutter executable (default: $FLUTTER, then the
                     flutter beside this Dart SDK, then flutter on PATH)
  -h, --help         Show this help''';

  final String? out;
  final String? flutter;
  final bool audio;
  final bool keepFrames;
  final bool remux;
  final bool help;
}
