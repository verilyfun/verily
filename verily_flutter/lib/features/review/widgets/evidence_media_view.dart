import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skribble/skribble.dart'
    show SkribbleIcon, WiredProgress, WiredSvgIconData;
import 'package:verily_client/verily_client.dart';
import 'package:video_player/video_player.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/l10n/l10n.dart';

/// Plays private evidence from a short-lived server link: video and audio
/// through the platform player, photos as an image.
///
/// The media is shown exactly as captured inside a quiet frame. A link that
/// has expired or cannot play says so; the screen offers a reload.
class EvidenceMediaView extends StatelessWidget {
  const EvidenceMediaView({
    required this.kind,
    required this.url,
    required this.photoLabel,
    super.key,
  });

  final ActionRequirementKind kind;

  /// The private link, or null when the server sent none.
  final String? url;

  /// What a screen reader says for a photo.
  final String photoLabel;

  @override
  Widget build(BuildContext context) {
    final uri = _playableUri(url);
    return switch (kind) {
      ActionRequirementKind.photo => _Frame(
        aspectRatio: 1,
        child: uri == null
            ? const _Unavailable()
            : Semantics(
                image: true,
                label: photoLabel,
                child: Image.network(
                  uri.toString(),
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                  loadingBuilder: (context, child, progress) =>
                      progress == null ? child : const _Loading(),
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Evidence photo failed to load: $error');
                    return const _Unavailable();
                  },
                ),
              ),
      ),
      ActionRequirementKind.video => _Frame(
        aspectRatio: 1,
        child: uri == null
            ? const _Unavailable()
            : _PlayerView(uri: uri, showPicture: true),
      ),
      ActionRequirementKind.audio => _Frame(
        child: uri == null
            ? const _Unavailable()
            : _PlayerView(uri: uri, showPicture: false),
      ),
      ActionRequirementKind.location ||
      ActionRequirementKind.qrCode ||
      ActionRequirementKind.motion ||
      ActionRequirementKind.externalApp => const SizedBox.shrink(),
    };
  }
}

Uri? _playableUri(String? url) {
  final uri = Uri.tryParse(url ?? '');
  if (uri == null || uri.host.isEmpty) return null;
  // Local development serves evidence over http; deployments use https.
  if (!(uri.isScheme('https') || uri.isScheme('http'))) return null;
  return uri;
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child, this.aspectRatio});

  final Widget child;
  final double? aspectRatio;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).verily;
    final framed = Container(
      clipBehavior: Clip.antiAlias,
      constraints: const BoxConstraints(minHeight: 72),
      decoration: VerilyRoughDecoration(color: palette.highlight),
      foregroundDecoration: VerilyRoughDecoration(
        outline: palette.quietPen,
        strokeWidth: 2,
        seed: 97,
      ),
      child: child,
    );
    final ratio = aspectRatio;
    return ratio == null
        ? framed
        : AspectRatio(aspectRatio: ratio, child: framed);
  }
}

class _PlayerView extends HookWidget {
  const _PlayerView({required this.uri, required this.showPicture});

  final Uri uri;
  final bool showPicture;

  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(
      () => VideoPlayerController.networkUrl(uri),
      [uri],
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
      debugPrint('Evidence media failed to load: ${initialization.error}');
      return const _Unavailable();
    }
    if (initialization.connectionState != ConnectionState.done) {
      return const _Loading();
    }

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final controls = _PlaybackControls(
          controller: controller,
          value: value,
        );
        if (!showPicture) {
          return Padding(padding: const EdgeInsets.all(12), child: controls);
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              child: SizedBox(
                width: value.size.width,
                height: value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
            Positioned(left: 12, right: 12, bottom: 12, child: controls),
          ],
        );
      },
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({required this.controller, required this.value});

  final VideoPlayerController controller;
  final VideoPlayerValue value;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).verily;
    final l10n = context.l10n;
    final duration = value.duration.inMilliseconds;
    final played = duration <= 0
        ? 0.0
        : (value.position.inMilliseconds / duration).clamp(0.0, 1.0);

    return DecoratedBox(
      decoration: VerilyRoughDecoration(
        color: palette.surface.withValues(alpha: 0.88),
        radius: VerilyRadius.control,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
            IconButton(
              tooltip: value.isPlaying ? l10n.reviewPause : l10n.reviewPlay,
              onPressed: () => unawaited(_toggle(controller, value)),
              icon: SkribbleIcon(
                data: value.isPlaying
                    ? VerilyIcons.pause
                    : value.isCompleted
                    ? VerilyIcons.replay
                    : VerilyIcons.play,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: VideoScrubber(
                controller: controller,
                child: WiredProgress(
                  value: played,
                  height: 12,
                  semanticLabel: l10n.reviewPlaybackPosition,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _toggle(
  VideoPlayerController controller,
  VideoPlayerValue value,
) async {
  if (value.isPlaying) {
    await controller.pause();
    return;
  }
  if (value.isCompleted || value.position >= value.duration) {
    await controller.seekTo(Duration.zero);
  }
  await controller.play();
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => _Message(
    icon: VerilyIcons.hourglass,
    label: context.l10n.reviewMediaLoading,
  );
}

class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) => _Message(
    icon: VerilyIcons.videoOff,
    label: context.l10n.reviewMediaUnavailable,
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.label});

  final WiredSvgIconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SkribbleIcon(data: icon, color: palette.mutedInk, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.mutedInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
