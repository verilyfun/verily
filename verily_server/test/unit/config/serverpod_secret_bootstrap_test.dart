import 'dart:io';

import 'package:monosecret/monosecret.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/config/serverpod_secret_bootstrap.dart';

void main() {
  group('monosecretProfileForServerpod', () {
    test('prefers an explicit Monosecret profile', () {
      expect(
        monosecretProfileForServerpod(
          ['--mode=production'],
          environment: const {'MONOSECRET_PROFILE': 'staging'},
        ),
        'staging',
      );
    });

    test('uses Serverpod mode arguments before the environment run mode', () {
      expect(
        monosecretProfileForServerpod(
          ['--mode=test'],
          environment: const {'runmode': 'production'},
        ),
        'test',
      );
      expect(
        monosecretProfileForServerpod(['--mode', 'staging']),
        'staging',
      );
    });

    test('defaults to development', () {
      expect(monosecretProfileForServerpod(const []), 'development');
    });
  });

  group('serverpodChildCommand', () {
    test('re-runs a Dart source entrypoint with the current VM', () {
      final command = serverpodChildCommand(
        ['--mode=test'],
        executable: '/opt/dart/bin/dart',
        script: Uri.file('/workspace/bin/main.dart'),
      );

      expect(command.executable, '/opt/dart/bin/dart');
      expect(command.arguments, [
        '/workspace/bin/main.dart',
        '--mode=test',
      ]);
    });

    test('re-runs a compiled executable directly', () {
      final command = serverpodChildCommand(
        ['--mode=production'],
        executable: '/app/bin/server',
        script: Uri.file('/app/bin/server'),
      );

      expect(command.executable, '/app/bin/server');
      expect(command.arguments, ['--mode=production']);
    });

    test(
      'makes a relative Dart entrypoint independent of later cwd changes',
      () {
        final expectedScript = File('bin/main.dart').absolute.path;
        final command = serverpodChildCommand(
          const [],
          executable: '/opt/dart/bin/dart',
          script: Uri(path: 'bin/main.dart'),
        );

        expect(command.arguments, [expectedScript]);
      },
    );
  });

  test('child environment excludes the 1Password bootstrap token', () {
    final environment = serverpodChildEnvironment(
      sourceEnvironment: const {
        'PATH': '/usr/bin',
        'OP_SERVICE_ACCOUNT_TOKEN': 'source-token',
      },
      resolvedFields: const {
        'SERVERPOD_SERVICE_SECRET': 'server-secret',
        'OP_SERVICE_ACCOUNT_TOKEN': 'resolved-token',
      },
      profile: 'development',
    );

    expect(environment['PATH'], '/usr/bin');
    expect(environment['SERVERPOD_SERVICE_SECRET'], 'server-secret');
    expect(environment['MONOSECRET_PROFILE'], 'development');
    expect(environment['VERILY_MONOSECRET_LOADED'], '1');
    expect(environment, isNot(contains('OP_SERVICE_ACCOUNT_TOKEN')));
  });

  test(
    'test profile resolves all required server secrets safely',
    () async {
      final manifest = File('../monosecret.toml').absolute;
      final resolved = await Monosecret.builder()
          .withPath(manifest.path)
          .withProfile('test')
          .withReason('Verify Verily test secret declarations')
          .load();
      addTearDown(resolved.close);

      expect(resolved.profile, 'test');
      expect(resolved.fields['SERVERPOD_DATABASE_PASSWORD'], isNotEmpty);
      expect(resolved.fields['SERVERPOD_SERVICE_SECRET'], isNotEmpty);
      expect(
        resolved.fields['SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey'],
        isNotEmpty,
      );
      expect(
        resolved.fields['VERILY_ABUSE_PSEUDONYM_SECRET'],
        startsWith('public-test-only-'),
      );
    },
  );

  test(
    'dotenv paths resolve from the discovered manifest directory',
    () async {
      final originalDirectory = Directory.current;
      final workspace = await Directory.systemTemp.createTemp(
        'verily-monosecret-bootstrap-',
      );
      addTearDown(() async {
        Directory.current = originalDirectory;
        await workspace.delete(recursive: true);
      });

      final manifest = File('${workspace.path}/monosecret.toml');
      await manifest.writeAsString('''
[project]
name = "bootstrap-test"
revision = "1.0"

[providers]
dotenv = "dotenv:.env"

[profiles.development.defaults]
providers = ["dotenv"]

[profiles.development]
OP_SERVICE_ACCOUNT_TOKEN = { description = "Bootstrap token", required = true }
''');
      await File('${workspace.path}/.env').writeAsString(
        'OP_SERVICE_ACCOUNT_TOKEN=private-test-token\n',
      );
      final nestedServerDirectory = await Directory(
        '${workspace.path}/verily_server',
      ).create();
      Directory.current = nestedServerDirectory;

      expect(
        FileSystemEntity.identicalSync(
          findMonosecretManifest()!,
          manifest.path,
        ),
        isTrue,
      );
      final resolved = await resolveVerilySecrets(
        profile: 'development',
        reason: 'Verify manifest-relative dotenv resolution',
      );
      addTearDown(resolved.close);

      expect(
        resolved.fields['OP_SERVICE_ACCOUNT_TOKEN'],
        'private-test-token',
      );
      expect(
        FileSystemEntity.identicalSync(
          Directory.current.path,
          nestedServerDirectory.path,
        ),
        isTrue,
      );
    },
  );
}
