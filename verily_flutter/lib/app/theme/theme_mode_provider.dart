import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which of Verily's two themes to show.
enum VerilyThemePreference {
  /// Follow the device: paper by day, night after dark.
  system,

  /// Always paper.
  light,

  /// Always night.
  dark;

  ThemeMode get themeMode => switch (this) {
    VerilyThemePreference.system => ThemeMode.system,
    VerilyThemePreference.light => ThemeMode.light,
    VerilyThemePreference.dark => ThemeMode.dark,
  };

  /// Reads a saved preference. Anything unrecognised, such as a value written
  /// by a newer build, falls back to [system].
  static VerilyThemePreference decode(String? value) {
    for (final preference in values) {
      if (preference.name == value) return preference;
    }
    return system;
  }

  String encode() => name;
}

/// Where the appearance choice is kept between launches.
abstract interface class ThemePreferenceStore {
  Future<String?> read();

  Future<void> write(String value);
}

class SharedPreferencesThemeStore implements ThemePreferenceStore {
  SharedPreferencesThemeStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'verily.appearance.theme-mode';
  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read() => _preferences.getString(_key);

  @override
  Future<void> write(String value) => _preferences.setString(_key, value);
}

final themePreferenceStoreProvider = Provider<ThemePreferenceStore>(
  (ref) => SharedPreferencesThemeStore(),
);

final verilyThemePreferenceProvider =
    NotifierProvider<VerilyThemePreferenceController, VerilyThemePreference>(
      VerilyThemePreferenceController.new,
    );

/// Holds the appearance choice and keeps it saved.
///
/// The app starts on [VerilyThemePreference.system] and restores the saved
/// choice in the background. A choice made before the restore finishes wins.
class VerilyThemePreferenceController extends Notifier<VerilyThemePreference> {
  var _revision = 0;

  @override
  VerilyThemePreference build() {
    unawaited(_restore(_revision));
    return VerilyThemePreference.system;
  }

  Future<void> setPreference(VerilyThemePreference preference) async {
    _revision++;
    state = preference;
    try {
      await ref.read(themePreferenceStoreProvider).write(preference.encode());
    } on Object catch (error, stack) {
      // The choice still applies for this session; the failure to keep it is
      // reported rather than swallowed.
      _report(error, stack, 'while saving the appearance preference');
    }
  }

  Future<void> _restore(int revision) async {
    final String? saved;
    try {
      saved = await ref.read(themePreferenceStoreProvider).read();
    } on Object catch (error, stack) {
      _report(error, stack, 'while restoring the appearance preference');
      return;
    }
    if (!ref.mounted || revision != _revision || saved == null) return;

    state = VerilyThemePreference.decode(saved);
  }

  void _report(Object error, StackTrace stack, String context) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'verily appearance',
        context: ErrorDescription(context),
      ),
    );
  }
}
