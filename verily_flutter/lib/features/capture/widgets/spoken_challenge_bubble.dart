import 'package:flutter/material.dart';

import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_fitted_text.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// "Say “pelican”": the live spoken challenge in a speech bubble.
///
/// The word comes from the server before recording starts and is shown big
/// enough to read from arm's length. It is paper with ink, the same over a
/// camera feed or a page.
class SpokenChallengeBubble extends StatelessWidget {
  const SpokenChallengeBubble({
    required this.word,
    this.intro = false,
    super.key,
  });

  final String word;

  /// Before recording: adds the line that explains when to say it.
  final bool intro;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Semantics(
      container: true,
      liveRegion: true,
      label: l10n.captureChallengeSemantics(word),
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                key: VerilyTestKeys.captureChallengeWord,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                decoration: const VerilyRoughDecoration(
                  color: VerilyColors.movementBone,
                  outline: VerilyColors.movementOutline,
                  radius: VerilyRadius.sheet,
                  seed: 409,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (intro) ...[
                      Text(
                        l10n.captureChallengeIntro,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: VerilyColors.movementOutline,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    VerilyFittedText(
                      l10n.captureChallengeSay(word),
                      alignment: Alignment.center,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: VerilyColors.movementOutline,
                      ),
                    ),
                  ],
                ),
              ),
              // The bubble's tail points down at whoever is speaking.
              const CustomPaint(
                size: Size(28, 16),
                painter: _TailPainter(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  const _TailPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.45, size.height)
      ..lineTo(size.width, 0);
    canvas
      ..drawPath(
        Path.from(path)..close(),
        Paint()..color = VerilyColors.movementBone,
      )
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = VerilyColors.movementOutline,
      );
  }

  @override
  bool shouldRepaint(covariant _TailPainter oldDelegate) => false;
}
