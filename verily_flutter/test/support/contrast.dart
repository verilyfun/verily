import 'dart:ui';

import 'package:verily_flutter/app/theme/verily_theme.dart';

/// The contrast of [foreground] laid over [background], resolving any
/// translucency the way it paints.
double contrastOver(Color foreground, Color background) =>
    verilyContrastRatio(Color.alphaBlend(foreground, background), background);
