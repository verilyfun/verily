import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon;

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_fitted_text.dart';
import 'package:verily_flutter/l10n/l10n.dart';

/// Opens the venue-code scanner and returns the first code it reads, or null
/// when the person backs out.
Future<String?> scanVenueCode(BuildContext context) => Navigator.of(
  context,
).push<String>(MaterialPageRoute(builder: (_) => const VenueScannerScreen()));

/// A camera viewfinder for the venue's short-lived code.
///
/// Night paper with a hand-drawn frame, as DESIGN.md's camera viewfinder:
/// no face boxes, no grids, no red rectangles. The code itself is read
/// exactly; only the frame is drawn by the pen.
class VenueScannerScreen extends HookWidget {
  const VenueScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // Detections keep arriving after the first match; only the first pops.
    final handled = useRef(false);

    return Scaffold(
      backgroundColor: VerilyColors.movementScrim,
      appBar: AppBar(
        backgroundColor: VerilyColors.transparent,
        foregroundColor: VerilyColors.movementHudInk,
        title: VerilyFittedText(
          l10n.actionScanTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            color: VerilyColors.movementHudInk,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (handled.value) return;
              final value = capture.barcodes.firstOrNull?.rawValue;
              if (value == null || value.trim().isEmpty) return;
              handled.value = true;
              Navigator.of(context).pop(value.trim());
            },
            errorBuilder: (context, error) => _ScannerProblem(error: error),
          ),
          const IgnorePointer(
            child: Center(
              child: SizedBox.square(
                dimension: 250,
                child: DecoratedBox(
                  decoration: VerilyRoughDecoration(
                    outline: VerilyColors.movementHudInk,
                    radius: VerilyRadius.sheet,
                    strokeWidth: 3,
                    seed: 43,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.actionScanHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: VerilyColors.movementHudInk,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerProblem extends StatelessWidget {
  const _ScannerProblem({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final message = error.errorCode == MobileScannerErrorCode.permissionDenied
        ? l10n.actionScanCameraDenied
        : l10n.actionScanUnavailable;
    debugPrint('Venue scanner unavailable: ${error.errorCode.name}');
    return ColoredBox(
      color: VerilyColors.movementScrim,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SkribbleIcon(
                data: VerilyIcons.videoOff,
                size: 40,
                color: VerilyColors.movementHudInk,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: VerilyColors.movementHudInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
