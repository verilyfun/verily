// Reflective test discovery requires method names beginning with `test_`.
// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:verily_lints/src/rules/enforce_pinned_app_dependencies_rule.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PinnedAppDependenciesRuleTest);
    defineReflectiveTests(PinnedRuleOutsideTheAppTest);
  });

  group('unpinnedDependencies', () {
    test('accepts exact, pre-release, and build versions', () {
      expect(
        unpinnedDependencies('''
dependencies:
  go_router: 18.0.2
  flutter_hooks: 0.21.3+1
  preview: 2.0.0-dev.3
  quoted: "1.4.0"
'''),
        isEmpty,
      );
    });

    test('accepts SDK, path, and git dependencies', () {
      expect(
        unpinnedDependencies('''
dependencies:
  flutter:
    sdk: flutter
  verily_brand:
    path: ../packages/verily_brand
  pinned_git:
    git:
      url: https://example.com/repo.git
      ref: 0123abcd
'''),
        isEmpty,
      );
    });

    test('reports carets, ranges, any, and missing versions in order', () {
      expect(
        unpinnedDependencies('''
dependencies:
  caret: ^1.2.3
  range: ">=1.0.0 <2.0.0"
  below: "<3.0.0"
  tilde: ~1.0.0
  anything: any
  empty:
  partial: 1.2
  hosted_range:
    hosted: https://pub.example.com
    version: ^4.0.0
  hosted_any:
    hosted: https://pub.example.com
  fine: 1.0.0

dev_dependencies:
  test: ^1.25.0
'''),
        [
          'caret',
          'range',
          'below',
          'tilde',
          'anything',
          'empty',
          'partial',
          'hosted_range',
          'hosted_any',
        ],
      );
    });

    test('leaves an unparseable pubspec to pub', () {
      expect(unpinnedDependencies('dependencies: [unclosed'), isEmpty);
    });
  });
}

@reflectiveTest
class PinnedAppDependenciesRuleTest extends AnalysisRuleTest {
  @override
  String get testPackageRootPath => '$workspaceRootPath/verily_flutter';

  @override
  String get testFileName => 'main.dart';

  @override
  void setUp() {
    rule = EnforcePinnedAppDependenciesRule();
    super.setUp();
  }

  void _writePubspec(String dependencies) => newPubspecYamlFile(
    testPackageRootPath,
    'name: verily_flutter\n\ndependencies:\n$dependencies',
  );

  Future<void> test_acceptsExactPins() async {
    _writePubspec('  go_router: 18.0.2\n');

    await assertNoDiagnostics('void main() {}\n');
  }

  Future<void> test_reportsEachUnpinnedDependencyOnMain() async {
    _writePubspec('  caret: ^1.0.0\n  fine: 1.0.0\n  anything: any\n');

    await assertDiagnostics('void main() {}\n', [
      lint(0, 4, messageContainsAll: ['`caret`']),
      lint(0, 4, messageContainsAll: ['`anything`']),
    ]);
  }
}

@reflectiveTest
class PinnedRuleOutsideTheAppTest extends AnalysisRuleTest {
  @override
  String get testFileName => 'main.dart';

  @override
  void setUp() {
    rule = EnforcePinnedAppDependenciesRule();
    super.setUp();
  }

  Future<void> test_ignoresOtherPackages() async {
    newPubspecYamlFile(
      testPackageRootPath,
      'name: test\n\ndependencies:\n  caret: ^1.0.0\n',
    );

    await assertNoDiagnostics('void main() {}\n');
  }
}
