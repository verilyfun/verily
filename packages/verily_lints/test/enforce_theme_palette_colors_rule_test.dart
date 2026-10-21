// Reflective test discovery requires method names beginning with `test_`.
// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:verily_lints/src/rules/enforce_theme_palette_colors_rule.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnforceThemePaletteColorsRuleTest);
    defineReflectiveTests(ThemePaletteDeclarationTest);
  });
}

@reflectiveTest
class EnforceThemePaletteColorsRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = EnforceThemePaletteColorsRule();
    super.setUp();
  }

  Future<void> test_allowsNamedVerilyToken() async {
    await assertNoDiagnostics('''
abstract final class VerilyColors {
  static const accent = 1;
}

const color = VerilyColors.accent;
''');
  }

  Future<void> test_reportsColorConstructor() async {
    const source = '''
class Color {
  const Color(int value);
}

const color = Color(0xff112233);
''';
    const expression = 'Color(0xff112233)';

    await assertDiagnostics(source, [
      lint(source.indexOf(expression), expression.length),
    ]);
  }

  Future<void> test_reportsNamedColorConstructor() async {
    const source = '''
class Color {
  const Color.fromARGB(int alpha, int red, int green, int blue);
}

const color = Color.fromARGB(255, 17, 34, 51);
''';
    const expression = 'Color.fromARGB(255, 17, 34, 51)';

    await assertDiagnostics(source, [
      lint(source.indexOf(expression), expression.length),
    ]);
  }

  Future<void> test_reportsCupertinoColorsReference() async {
    const source = '''
abstract final class CupertinoColors {
  static const activeBlue = 1;
}

const color = CupertinoColors.activeBlue;
''';
    const expression = 'CupertinoColors.activeBlue';

    await assertDiagnostics(source, [
      lint(source.indexOf(expression), expression.length),
    ]);
  }

  Future<void> test_reportsMaterialColorsReference() async {
    const source = '''
abstract final class Colors {
  static const red = 1;
}

const color = Colors.red;
''';
    const expression = 'Colors.red';

    await assertDiagnostics(source, [
      lint(source.indexOf(expression), expression.length),
    ]);
  }

  Future<void> test_reportsPrefixedMaterialColorsReference() async {
    const source = '''
class Palette {
  const Palette();
  int get red => 1;
}

abstract final class material {
  static const Colors = Palette();
}

final color = material.Colors.red;
''';
    const expression = 'material.Colors.red';

    await assertDiagnostics(source, [
      lint(source.indexOf(expression), expression.length),
    ]);
  }
}

@reflectiveTest
class ThemePaletteDeclarationTest extends AnalysisRuleTest {
  @override
  String get testFileName => 'app/theme/verily_theme.dart';

  @override
  void setUp() {
    rule = EnforceThemePaletteColorsRule();
    super.setUp();
  }

  Future<void> test_allowsRawDeclarationsInThemeSource() async {
    await assertNoDiagnostics('''
class Color {
  const Color(int value);
}

const accent = Color(0xff112233);
''');
  }
}
