import 'dart:async';
import 'dart:io';

/// Local CI: runs Verily's check lanes on this machine and posts one commit
/// status per lane through the developer's `gh` login, so a GitHub ruleset
/// can require them.
///
///     dart run tool/local_ci.dart [--lane=<lane>]... [--also=<sha>]...
///         [--no-post]
///
/// Each lane is one devenv script, and its status context is the script name.
/// The checked-out commit must be clean, and when posting it must also be
/// exactly what `origin` has for the branch, so a status only ever describes
/// the tree that ran. `--also` reuses the result for ancestor commits, such
/// as the lower layers of a stack that will merge together with this one.
/// Logs are kept per commit under `<git common dir>/local-ci/logs/`, and one
/// run at a time holds `<git common dir>/local-ci/run.lock`. See
/// docs/local-ci.md.
Future<void> main(List<String> args) async {
  final options = LocalCiOptions.parse(args);
  if (options == null) {
    stderr.writeln(
      'usage: dart run tool/local_ci.dart [--lane=<lane>]... '
      '[--also=<sha>]... [--no-post]\n'
      'lanes: ${localCiLanes.map((lane) => lane.script).join(', ')}',
    );
    exitCode = 64;
    return;
  }
  try {
    exitCode = await LocalCi(options).run();
  } on LocalCiException catch (error) {
    stderr.writeln('local CI: ${error.message}');
    exitCode = 1;
  }
}

/// A devenv script run as one lane. Its name is the lane's status context.
class LocalCiLane {
  const LocalCiLane(this.script, {this.optIn = false});

  final String script;

  /// Runs only when named with `--lane`, never by default.
  final bool optIn;
}

/// Every lane, in run order: fast checks first, the image last. The default
/// lanes cover `lint:all` and every script `test:all` runs (a unit test
/// keeps them in step with devenv.nix).
const List<LocalCiLane> localCiLanes = [
  LocalCiLane('lint:all'),
  LocalCiLane('test:tools'),
  LocalCiLane('test:lints'),
  LocalCiLane('test:flutter'),
  LocalCiLane('test:server'),
  LocalCiLane('test:escrow'),
  // Needs a running Docker or Podman machine. Opt-in until it has passed on
  // one; it then becomes a default lane.
  LocalCiLane('test:server-image', optIn: true),
  // Starts a throwaway Solana validator and moves real (local) tokens.
  LocalCiLane('test:escrow:e2e', optIn: true),
];

class LocalCiOptions {
  const LocalCiOptions({
    required this.lanes,
    required this.alsoShas,
    required this.post,
  });

  final List<LocalCiLane> lanes;
  final List<String> alsoShas;
  final bool post;

  static LocalCiOptions? parse(List<String> args) {
    final named = <String>{};
    final also = <String>[];
    var post = true;
    for (final arg in args) {
      if (arg.startsWith('--lane=')) {
        final script = arg.substring('--lane='.length);
        if (!localCiLanes.any((lane) => lane.script == script)) return null;
        named.add(script);
      } else if (arg.startsWith('--also=')) {
        final sha = arg.substring('--also='.length);
        if (!RegExp(r'^[0-9a-f]{7,40}$').hasMatch(sha)) return null;
        also.add(sha);
      } else if (arg == '--no-post') {
        post = false;
      } else {
        return null;
      }
    }
    return LocalCiOptions(
      lanes: [
        for (final lane in localCiLanes)
          if (named.isEmpty ? !lane.optIn : named.contains(lane.script)) lane,
      ],
      alsoShas: also,
      post: post,
    );
  }
}

class LocalCiException implements Exception {
  const LocalCiException(this.message);

  final String message;
}

/// `owner/repo` from a GitHub remote URL.
String? githubRepository(String remoteUrl) {
  final match = RegExp(
    r'github\.com[:/]([^/\s]+)/([^/\s]+?)(?:\.git)?/?$',
  ).firstMatch(remoteUrl.trim());
  return match == null ? null : '${match[1]}/${match[2]}';
}

/// A GitHub status description, which is capped at 140 characters.
String statusDescription(String text) =>
    text.length <= 140 ? text : '${text.substring(0, 139)}…';

String formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return minutes == 0 ? '${seconds}s' : '${minutes}m ${seconds}s';
}

class LocalCi {
  LocalCi(this.options);

  final LocalCiOptions options;

  /// Where git and lane commands run: the current directory until the
  /// repository root is known.
  String _root = Directory.current.path;
  late final String _sha;
  String? _repository;
  late final Directory _logDirectory;
  final Set<String> _openLanes = {};

  Future<int> run() async {
    _root = await _git(['rev-parse', '--show-toplevel']);
    _sha = await _git(['rev-parse', 'HEAD']);
    if ((await _git(['status', '--porcelain'])).isNotEmpty) {
      throw const LocalCiException(
        'the working tree has changes; commit them so the run describes the '
        'committed tree',
      );
    }
    if (options.post) _repository = await _pushedRepository();
    final also = <String>[];
    for (final sha in options.alsoShas) {
      final full = await _git(['rev-parse', '$sha^{commit}']);
      final ancestor = await Process.run('git', [
        'merge-base',
        '--is-ancestor',
        full,
        _sha,
      ], workingDirectory: _root);
      if (ancestor.exitCode != 0) {
        throw LocalCiException('--also $sha is not an ancestor of HEAD');
      }
      also.add(full);
    }

    final common = await _git([
      'rev-parse',
      '--path-format=absolute',
      '--git-common-dir',
    ]);
    final lockFile = File('$common/local-ci/run.lock')
      ..createSync(recursive: true);
    final lock = lockFile.openSync(mode: FileMode.write);
    try {
      lock.lockSync();
    } on FileSystemException {
      throw const LocalCiException('another local CI run holds the lock');
    }
    _logDirectory = Directory('$common/local-ci/logs/$_sha')
      ..createSync(recursive: true);
    final interrupt = ProcessSignal.sigint.watch().listen((_) async {
      for (final lane in _openLanes.toList()) {
        await _post(_sha, lane, 'error', 'Local CI was cancelled');
      }
      exit(130);
    });

    try {
      for (final lane in options.lanes) {
        await _post(_sha, lane.script, 'pending', 'Running on ${_host()}');
        _openLanes.add(lane.script);
      }
      var failed = false;
      for (final lane in options.lanes) {
        final stopwatch = Stopwatch()..start();
        final failure = await _runLane(lane)
            ? await _treeChanged()
            : 'it exited with an error';
        final elapsed = formatDuration(stopwatch.elapsed);
        final state = failure == null ? 'success' : 'failure';
        final description = failure == null
            ? 'Passed locally on ${_host()} in $elapsed'
            : 'Failed locally on ${_host()}: $failure';
        await _post(_sha, lane.script, state, description);
        for (final ancestor in also) {
          await _post(
            ancestor,
            lane.script,
            state,
            '$description, as stack top ${_sha.substring(0, 8)}',
          );
        }
        _openLanes.remove(lane.script);
        failed |= failure != null;
        stdout.writeln(
          '== ${lane.script}: ${failure == null ? 'passed' : 'FAILED'} '
          '($elapsed)',
        );
      }
      stdout.writeln('Logs: ${_logDirectory.path}');
      return failed ? 1 : 0;
    } finally {
      await interrupt.cancel();
      lock
        ..unlockSync()
        ..closeSync();
    }
  }

  /// The GitHub repository to post to, once HEAD is exactly what `origin`
  /// has for the current branch.
  Future<String> _pushedRepository() async {
    final branch = await _git(['rev-parse', '--abbrev-ref', 'HEAD']);
    if (branch == 'HEAD' || branch == 'main') {
      throw const LocalCiException(
        'check out the pull request branch first, or pass --no-post',
      );
    }
    final remotes = await _git(['remote']);
    final repository = remotes.split('\n').contains('origin')
        ? githubRepository(await _git(['remote', 'get-url', 'origin']))
        : null;
    if (repository == null) {
      throw const LocalCiException(
        'origin is not a GitHub repository; pass --no-post to run without '
        'posting statuses',
      );
    }
    final remote = (await _git([
      'ls-remote',
      'origin',
      'refs/heads/$branch',
    ])).split(RegExp(r'\s')).first;
    if (remote != _sha) {
      throw LocalCiException(
        'push $branch first: origin is at '
        '${remote.isEmpty ? 'nothing' : remote.substring(0, 8)}, '
        'HEAD is ${_sha.substring(0, 8)}',
      );
    }
    return repository;
  }

  /// Runs [lane]'s devenv script, streaming its output to the terminal and
  /// to the lane's log.
  Future<bool> _runLane(LocalCiLane lane) async {
    stdout.writeln('== ${lane.script}');
    final name = lane.script.replaceAll(':', '-');
    final log = File('${_logDirectory.path}/$name.log').openWrite();
    try {
      final process = await Process.start('devenv', [
        'shell',
        lane.script,
      ], workingDirectory: _root);
      final out = process.stdout.forEach((chunk) {
        stdout.add(chunk);
        log.add(chunk);
      });
      final err = process.stderr.forEach((chunk) {
        stderr.add(chunk);
        log.add(chunk);
      });
      final code = await process.exitCode;
      await Future.wait([out, err]);
      return code == 0;
    } finally {
      await log.close();
    }
  }

  /// A lane may only pass if it left the tested commit untouched.
  Future<String?> _treeChanged() async {
    if (await _git(['rev-parse', 'HEAD']) != _sha) {
      return 'HEAD moved during the run';
    }
    if ((await _git(['status', '--porcelain'])).isNotEmpty) {
      return 'a step changed the working tree';
    }
    return null;
  }

  Future<void> _post(
    String sha,
    String lane,
    String state,
    String description,
  ) async {
    final repository = _repository;
    if (repository == null) return;
    final result = await Process.run('gh', [
      'api', '--method', 'POST', //
      'repos/$repository/statuses/$sha',
      '-f', 'state=$state',
      '-f', 'context=$lane',
      '-f', 'description=${statusDescription(description)}',
    ]);
    if (result.exitCode != 0) {
      throw LocalCiException(
        'could not post the $lane status for '
        '${sha.substring(0, 8)}: ${'${result.stderr}'.trim()}',
      );
    }
  }

  Future<String> _git(List<String> args) async {
    final result = await Process.run('git', args, workingDirectory: _root);
    if (result.exitCode != 0) {
      throw LocalCiException(
        'git ${args.join(' ')} failed: ${'${result.stderr}'.trim()}',
      );
    }
    return '${result.stdout}'.trim();
  }

  static String _host() => Platform.localHostname.split('.').first;
}
