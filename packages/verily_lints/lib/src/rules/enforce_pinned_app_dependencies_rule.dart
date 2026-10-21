import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:yaml/yaml.dart';

/// Requires every hosted dependency of the Verily app to name one exact
/// version.
///
/// A caret, range, or `any` lets `pub get` move the app onto a release nobody
/// reviewed, so the app pins each `dependencies:` entry exactly and moves pins
/// deliberately. SDK, path, and git dependencies carry no version and are
/// left alone; development dependencies are not checked.
///
/// Analyzer plugins cannot report on `pubspec.yaml` from a Dart rule, so the
/// violations are reported once, on the first token of `lib/main.dart`.
final class EnforcePinnedAppDependenciesRule extends AnalysisRule {
  EnforcePinnedAppDependenciesRule()
    : super(
        name: 'enforce_pinned_app_dependencies',
        description:
            'Require exact versions in the verily_flutter dependencies '
            'section.',
      );

  static const LintCode code = LintCode(
    'enforce_pinned_app_dependencies',
    'verily_flutter dependency `{0}` must use an exact version. '
        'Do not use `^`, `>`, `>=`, `<`, `~`, or `any` constraints.',
    correctionMessage: 'Pin to an exact version, for example: `{0}: 1.2.3`.',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addCompilationUnit(
      this,
      _PinnedDependenciesVisitor(this, context),
    );
  }
}

final class _PinnedDependenciesVisitor extends SimpleAstVisitor<void> {
  _PinnedDependenciesVisitor(this.rule, this.context);

  static const String _appFolderName = 'verily_flutter';
  static const String _mainDartPath = 'lib/main.dart';
  static const String _pubspecPath = 'pubspec.yaml';

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final packageRoot = context.package?.root;
    final currentFile = context.currentUnit?.file;
    if (packageRoot == null || currentFile == null) {
      return;
    }
    if (packageRoot.shortName != _appFolderName) {
      return;
    }

    final pathContext = packageRoot.provider.pathContext;
    final anchorPath = pathContext.normalize(
      pathContext.join(packageRoot.path, _mainDartPath),
    );
    if (pathContext.normalize(currentFile.path) != anchorPath) {
      return;
    }

    final pubspec = packageRoot.getChildAssumingFile(_pubspecPath);
    if (!pubspec.exists) {
      return;
    }
    final violations = unpinnedDependencies(pubspec.readAsStringSync());
    for (final dependencyName in violations) {
      rule.reportAtToken(node.beginToken, arguments: [dependencyName]);
    }
  }
}

/// The names of `dependencies:` entries in [pubspecContent] that do not pin
/// one exact version, in declaration order.
///
/// A pubspec that does not parse reports nothing here: pub itself rejects it
/// with a precise error.
List<String> unpinnedDependencies(String pubspecContent) {
  final Object? document;
  try {
    document = loadYaml(pubspecContent);
  } on YamlException {
    return const [];
  }
  if (document is! YamlMap) {
    return const [];
  }
  final dependencies = document['dependencies'];
  if (dependencies is! YamlMap) {
    return const [];
  }

  return [
    for (final MapEntry(:key, :value) in dependencies.entries)
      if (!_isPinned(value)) '$key',
  ];
}

/// Whether one dependency's value pins an exact hosted version, or is not a
/// hosted dependency at all.
bool _isPinned(Object? value) => switch (value) {
  // `name:` with no value means any version.
  null => false,
  String() => _exactVersion.hasMatch(value.trim()),
  YamlMap() when value.containsKey('version') => _isPinned(value['version']),
  // A hosted map without a version accepts any release.
  YamlMap() when value.containsKey('hosted') => false,
  // `sdk:`, `path:`, and `git:` dependencies have no hosted version.
  YamlMap() => true,
  // A bare number such as `1.2` is not a full version.
  _ => false,
};

/// One semantic version, with optional pre-release and build parts.
final RegExp _exactVersion = RegExp(
  r'^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$',
);
