import 'package:flutter/widgets.dart';

/// Stable selectors shared by production widgets and end-to-end tests.
abstract final class VerilyTestKeys {
  static const appearanceSystem = ValueKey<String>('appearance-system');
  static const appearanceLight = ValueKey<String>('appearance-light');
  static const appearanceDark = ValueKey<String>('appearance-dark');

  static const developerMenuLauncher = ValueKey<String>(
    'developer-menu-launcher',
  );
  static const developerSkribblePreview = ValueKey<String>(
    'developer-skribble-preview',
  );
}
