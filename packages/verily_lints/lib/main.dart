import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:verily_lints/src/rules/disallow_stateful_widgets_rule.dart';
import 'package:verily_lints/src/rules/enforce_pinned_app_dependencies_rule.dart';
import 'package:verily_lints/src/rules/enforce_theme_palette_colors_rule.dart';

/// The analysis server loads this top-level `plugin`.
final plugin = VerilyLintPlugin();

/// Verily's analyzer plugin.
///
/// Warnings are on by default wherever the plugin is enabled. The
/// `avoid_stateful_widgets` lint is opt-in through `diagnostics:` in the
/// package's `analysis_options.yaml`.
class VerilyLintPlugin extends Plugin {
  @override
  String get name => 'Verily Lints';

  @override
  void register(PluginRegistry registry) {
    registry
      ..registerLintRule(DisallowStatefulWidgetsRule())
      ..registerWarningRule(EnforcePinnedAppDependenciesRule())
      ..registerWarningRule(EnforceThemePaletteColorsRule());
  }
}
