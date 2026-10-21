import 'package:verily_flutter/app/theme/theme_mode_provider.dart';

/// An in-memory [ThemePreferenceStore] so tests never touch the platform
/// preferences plugin.
class MemoryThemeStore implements ThemePreferenceStore {
  MemoryThemeStore({this.saved});

  String? saved;

  @override
  Future<String?> read() async => saved;

  @override
  Future<void> write(String value) async {
    saved = value;
  }
}
