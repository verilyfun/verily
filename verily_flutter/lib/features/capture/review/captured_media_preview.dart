import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skribble/skribble.dart'
    show SkribbleIcon, WiredLoadingIndicator, WiredProgress;
import 'package:verily_evidence/verily_evidence.dart';
import 'package:video_player/video_player.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/features/capture/review/media_duration_probe.dart';
import 'package:verily_flutter/features/evidence/captured_media.dart';
import 'package:verily_flutter/l10n/l10n.dart';

/// Shows a capture exactly as it will be sent: the photo, or a player for a
/// video or audio recording. Evidence is never cropped or filtered here.
class CapturedMediaPreview extends StatelessWidget {
  const CapturedMediaPreview({required this.media, super.key});

  final CapturedMedia media;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).verily;
    final child = switch (media.kind) {
      MediaEvidenceKind.photo => _PhotoPreview(media: media),
      MediaEvidenceKind.video ||
      MediaEvidenceKind.audio => _RecordingPreview(media: media),
    };
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: VerilyColors.movementScrim,
        borderRadius: BorderRadius.circular(VerilyRadius.card),
      ),
      foregroundDecoration: VerilyRoughDecoration(
        outline: palette.ink,
        seed: 411,
      ),
      child: child,
    );
  }
}

class _PhotoPreview extends HookWidget {
  const _PhotoPreview({required this.media});

  final CapturedMedia media;

  @override
  Widget build(BuildContext context) {
    final bytes = useFuture(
      useMemoized(media.file.readAsBytes, [media.file]),
    );
    final data = bytes.data;
    if (data == null) {
      return Center(
        child: bytes.hasError
            ? _Unavailable(
                message: context.l10n.captureReviewPreviewUnavailable,
              )
            : const WiredLoadingIndicator(
                color: VerilyColors.movementHudInk,
              ),
      );
    }
    return Image.memory(data, fit: BoxFit.contain, gaplessPlayback: true);
  }
}

class _RecordingPreview extends HookWidget {
  const _RecordingPreview({required this.media});

  final CapturedMedia media;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = useMemoized(
      () => capturedMediaController(media.file),
      [media.file],
    );
    useEffect(
      () =>
          () => unawaited(controller.dispose()),
      [controller],
    );
    final initialization = useFuture(
      useMemoized(controller.initialize, [controller]),
    );
    if (initialization.hasError) {
      return _Unavailable(message: l10n.captureReviewPreviewUnavailable);
    }
    if (initialization.connectionState != ConnectionState.done) {
      return const Center(
        child: WiredLoadingIndicator(color: VerilyColors.movementHudInk),
      );
    }
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final isAudio = media.kind == MediaEvidenceKind.audio;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (isAudio)
              const Center(
                child: SkribbleIcon(
                  data: VerilyIcons.microphone,
                  size: 72,
                  color: VerilyColors.movementHudInk,
                ),
              )
            else
              FittedBox(
                child: SizedBox(
                  width: value.size.width,
                  height: value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            Center(
              child: IconButton.filled(
                tooltip: value.isPlaying
                    ? l10n.captureReviewPause
                    : l10n.captureReviewPlay,
                iconSize: 32,
                style: IconButton.styleFrom(
                  minimumSize: const Size.square(64),
                  backgroundColor: VerilyColors.movementScrim.withValues(
                    alpha: 0.6,
                  ),
                  foregroundColor: VerilyColors.movementHudInk,
                ),
                onPressed: () => unawaited(_toggle(controller, value)),
                icon: SkribbleIcon(
                  data: value.isPlaying
                      ? VerilyIcons.pause
                      : value.isCompleted
                      ? VerilyIcons.replay
                      : VerilyIcons.play,
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: ExcludeSemantics(
                child: WiredProgress(
                  value: value.duration.inMilliseconds == 0
                      ? 0
                      : (value.position.inMilliseconds /
                                value.duration.inMilliseconds)
                            .clamp(0.0, 1.0),
                  height: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _toggle(
    VideoPlayerController controller,
    VideoPlayerValue value,
  ) async {
    if (value.isPlaying) {
      await controller.pause();
      return;
    }
    if (value.isCompleted) await controller.seekTo(Duration.zero);
    await controller.play();
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: VerilyColors.movementHudInk,
          ),
        ),
      ),
    );
  }
}
