import 'package:skribble/skribble.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';

/// The drawings Skribble's own widgets ask for by name, such as the map's
/// zoom buttons. Verily ships its icons as constants rather than a whole
/// catalog, so without this those widgets would draw empty buttons.
const Map<String, WiredSvgIconData> _iconsByIdentifier = {
  'add': VerilyIcons.plus,
  'remove': VerilyIcons.minus,
};

/// Registers Verily's icons as the catalog Skribble's widgets look names up
/// in. Call once before the first frame; tests call it too, so they draw what
/// the app draws.
void registerVerilyIconCatalog() {
  registerWiredIconCatalog(
    WiredIconCatalog(
      name: 'Verily',
      // Verily draws every icon itself, so there is no font to fall back to
      // and no Flutter IconData to translate.
      resolve: (_) => null,
      resolveByIdentifier: (identifier) => _iconsByIdentifier[identifier],
      fontFamily: 'Verily',
      identifierCodePoints: const {},
      codePoints: const [],
      resolveFontIcon: (_) => null,
    ),
  );
}
