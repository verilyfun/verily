/// Verily's brand in code.
///
/// - `VerilyBrandColors`: every brand colour, with its role and contrast.
/// - `VerilyMark`: the pin-check, a solid pin with a check cut through it.
/// - `VerilyWordmark`: ✓erily, the "v" a vermilion check.
/// - `VerilyLockup`: the two together, side by side or stacked.
/// - `VerifiedStamp`: the stamp pressed onto verified proof.
///
/// Every drawing reads its geometry from `VerilyGeometry`, the one place the
/// shapes are defined; `VerilySvg` writes the files from the same data.
library;

export 'package:verily_brand/src/colors.dart';
export 'package:verily_brand/src/geometry.dart'
    show
        BrandBox,
        BrandCubic,
        BrandDot,
        BrandGlyph,
        BrandInk,
        BrandPoint,
        BrandShape,
        BrandStroke,
        VerilyGeometry;
export 'package:verily_brand/src/glyph_painter.dart';
export 'package:verily_brand/src/ink.dart'
    show BrandInkPainter, verilyBrandPen, verilyMarkPen;
export 'package:verily_brand/src/lockup.dart';
export 'package:verily_brand/src/mark.dart';
export 'package:verily_brand/src/stamp.dart';
export 'package:verily_brand/src/stamp_motion.dart';
export 'package:verily_brand/src/svg_export.dart';
export 'package:verily_brand/src/wordmark.dart';
