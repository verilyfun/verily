// Reflective test discovery requires method names beginning with `test_`.
// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:verily_lints/src/rules/disallow_stateful_widgets_rule.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DisallowStatefulWidgetsRuleTest);
  });
}

/// Stand-ins for the Flutter and Riverpod widget bases. The rule matches the
/// class hierarchy by name, so these exercise it without the Flutter SDK.
const _widgetBases = '''
abstract class Widget {}
abstract class StatelessWidget extends Widget {}
abstract class StatefulWidget extends Widget {}
abstract class HookWidget extends StatelessWidget {}
// Riverpod's stateful base, disallowed by name.
abstract class ConsumerStatefulWidget extends Widget {}
''';

@reflectiveTest
class DisallowStatefulWidgetsRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = DisallowStatefulWidgetsRule();
    super.setUp();
  }

  Future<void> test_allowsHookAndStatelessWidgets() async {
    await assertNoDiagnostics('''
$_widgetBases
class Header extends StatelessWidget {}
class Counter extends HookWidget {}
''');
  }

  Future<void> test_reportsStatefulWidget() async {
    const source =
        '''
$_widgetBases
class Counter extends StatefulWidget {}
''';
    const superclass = 'StatefulWidget {}\n';
    final offset = source.lastIndexOf(superclass);

    await assertDiagnostics(source, [lint(offset, 'StatefulWidget'.length)]);
  }

  Future<void> test_reportsStatefulDescendants() async {
    const source =
        '''
$_widgetBases
abstract class AppStatefulBase extends StatefulWidget {}
class Screen extends AppStatefulBase {}
class Picker extends ConsumerStatefulWidget {}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('StatefulWidget {}\nclass Screen'), 14),
      lint(source.indexOf('AppStatefulBase {}\nclass Picker'), 15),
      lint(source.lastIndexOf('ConsumerStatefulWidget'), 22),
    ]);
  }
}
