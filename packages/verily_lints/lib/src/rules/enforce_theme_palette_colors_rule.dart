import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

final class EnforceThemePaletteColorsRule extends AnalysisRule {
  EnforceThemePaletteColorsRule()
    : super(
        name: 'enforce_theme_palette_colors',
        description: 'Require Verily theme color tokens in verily_flutter.',
      );

  static const LintCode code = LintCode(
    'enforce_theme_palette_colors',
    'Avoid hardcoded colors. Use a named Verily theme token instead.',
    correctionMessage:
        'Use Theme.of(context).colorScheme, Theme.of(context).verily, or a '
        'named VerilyColors token.',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _EnforceThemePaletteColorsVisitor(this, context);
    registry
      ..addInstanceCreationExpression(this, visitor)
      ..addPrefixedIdentifier(this, visitor)
      ..addPropertyAccess(this, visitor);
  }
}

final class _EnforceThemePaletteColorsVisitor extends SimpleAstVisitor<void> {
  _EnforceThemePaletteColorsVisitor(this.rule, this.context);

  static const String _palettePath = 'lib/app/theme/verily_theme.dart';

  final AnalysisRule rule;
  final RuleContext context;

  bool get _shouldLintCurrentFile {
    final packageRoot = context.package?.root;
    final currentFile = context.currentUnit?.file;
    if (packageRoot == null || currentFile == null) {
      return false;
    }
    final pathContext = packageRoot.provider.pathContext;
    final relativePath = pathContext.relative(
      pathContext.normalize(currentFile.path),
      from: packageRoot.path,
    );

    return relativePath != _palettePath;
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!_shouldLintCurrentFile) {
      return;
    }

    final typeName = node.constructorName.type.name.lexeme;
    if (typeName == 'Color') {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (!_shouldLintCurrentFile) {
      return;
    }

    if (node.prefix.name == 'Colors' || node.prefix.name == 'CupertinoColors') {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (!_shouldLintCurrentFile) {
      return;
    }

    if (_isDisallowedPalette(node.target)) {
      rule.reportAtNode(node);
    }
  }

  bool _isDisallowedPalette(Expression? expression) {
    return switch (expression) {
      SimpleIdentifier(:final name) =>
        name == 'Colors' || name == 'CupertinoColors',
      PrefixedIdentifier(:final identifier) =>
        identifier.name == 'Colors' || identifier.name == 'CupertinoColors',
      _ => false,
    };
  }
}
