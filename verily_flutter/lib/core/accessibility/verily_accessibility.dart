import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';

SemanticsHandle? _webSemanticsHandle;

/// Keeps Flutter's accessibility DOM enabled for the lifetime of the web app.
///
/// Flutter otherwise waits for a user to activate its accessibility overlay.
/// Verily's reviewer workflows must be keyboard and assistive-technology
/// ready from the first frame. Keeping this semantic HTML mounted also lets
/// the browser's native find command index text currently rendered by
/// Flutter.
void enableVerilyWebAccessibility() {
  if (!kIsWeb || _webSemanticsHandle != null) return;

  _webSemanticsHandle = SemanticsBinding.instance.ensureSemantics();
}
