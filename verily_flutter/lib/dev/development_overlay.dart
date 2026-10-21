import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon, WiredSvgIconData;

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/dev/skribble_preview_screen.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// Rebuilds its whole subtree from scratch when
/// [DevelopmentRestartBoundary.restart] is called.
///
/// Sits above the `ProviderScope`, so a restart also recreates every provider.
class DevelopmentRestartBoundary extends HookWidget {
  const DevelopmentRestartBoundary({required this.child, super.key});

  final Widget child;

  static final ValueNotifier<int> _restartTick = ValueNotifier(0);

  static void restart() {
    _restartTick.value++;
  }

  @override
  Widget build(BuildContext context) {
    final restartTick = useListenable(_restartTick);
    return KeyedSubtree(key: ValueKey(restartTick.value), child: child);
  }
}

/// A screen the development menu can open, such as a component gallery.
///
/// The menu always offers the Skribble preview; the app adds its own tools
/// through [DevelopmentOverlay.tools].
@immutable
class DevelopmentTool {
  const DevelopmentTool({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.builder,
    this.key,
  });

  final WiredSvgIconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;

  /// Placed on the menu entry so tests can open the tool.
  final Key? key;
}

/// Debug-only developer tools over the whole app.
///
/// In release and profile builds this is just [child]. In debug builds,
/// shaking the phone or pressing ⇧⌘D / Ctrl+Shift+D opens the development
/// menu, and ⌘D / Ctrl+D reassembles the widget tree.
class DevelopmentOverlay extends HookWidget {
  const DevelopmentOverlay({
    required this.child,
    required this.navigatorKey,
    this.serverUrl,
    this.tools = const [],
    this.onFullReload,
    this.onFullRestart,
    super.key,
  });

  final Widget child;

  /// The app's root navigator, so the menu opens above every route.
  final GlobalKey<NavigatorState> navigatorKey;

  /// The server this build talks to, or null when it has none.
  final String? serverUrl;

  /// Extra screens the menu offers after the Skribble preview.
  final List<DevelopmentTool> tools;

  final VoidCallback? onFullReload;
  final VoidCallback? onFullRestart;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return child;
    }

    final lastShake = useRef(DateTime.fromMillisecondsSinceEpoch(0));
    final shouldShowMenuButtonAfterSheet = useRef(false);
    final isMenuButtonVisible = useState(false);
    final isDraggingMenuButton = useState(false);
    final isDevelopmentMenuVisible = useState(false);
    final menuButtonOffset = useState<Offset?>(null);

    Future<void> debugReassemble(String source) async {
      await WidgetsBinding.instance.reassembleApplication();

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.developerReassembled(source)),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    void showDevelopmentMenu() {
      if (isDevelopmentMenuVisible.value) {
        return;
      }

      final sheetContext = navigatorKey.currentContext ?? context;
      isDevelopmentMenuVisible.value = true;
      isDraggingMenuButton.value = false;
      shouldShowMenuButtonAfterSheet.value = isMenuButtonVisible.value;
      isMenuButtonVisible.value = false;

      unawaited(
        showModalBottomSheet<void>(
          context: sheetContext,
          showDragHandle: false,
          isScrollControlled: true,
          builder: (context) => _DevelopmentMenu(
            serverUrl: serverUrl,
            tools: tools,
            onShowDeveloperIcon: () {
              shouldShowMenuButtonAfterSheet.value = true;
            },
            onHotReload: () => debugReassemble('menu'),
            onFullReload: onFullReload,
            onFullRestart: onFullRestart,
          ),
        ).whenComplete(() {
          isDevelopmentMenuVisible.value = false;
          isMenuButtonVisible.value = shouldShowMenuButtonAfterSheet.value;
        }),
      );
    }

    useEffect(() {
      void handleAccelerometerEvent(AccelerometerEvent event) {
        final acceleration = math.sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z,
        );

        final now = DateTime.now();
        if (acceleration < 28 ||
            now.difference(lastShake.value) < const Duration(seconds: 2)) {
          return;
        }

        lastShake.value = now;
        showDevelopmentMenu();
      }

      final subscription =
          accelerometerEventStream(
            samplingPeriod: SensorInterval.uiInterval,
          ).listen(
            handleAccelerometerEvent,
            // Browsers, desktops, and emulators without a sensor still have
            // the keyboard shortcut, so a missing accelerometer is only noted.
            onError: (Object error) => debugPrint(
              'Development menu shake is unavailable: $error',
            ),
          );

      return subscription.cancel;
    }, const []);

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyD, meta: true):
            _DebugReassembleIntent(),
        SingleActivator(LogicalKeyboardKey.keyD, control: true):
            _DebugReassembleIntent(),
        SingleActivator(LogicalKeyboardKey.keyD, meta: true, shift: true):
            _OpenDevelopmentMenuIntent(),
        SingleActivator(LogicalKeyboardKey.keyD, control: true, shift: true):
            _OpenDevelopmentMenuIntent(),
      },
      child: Actions(
        actions: {
          _DebugReassembleIntent: CallbackAction<_DebugReassembleIntent>(
            onInvoke: (_) {
              unawaited(debugReassemble('shortcut'));
              return null;
            },
          ),
          _OpenDevelopmentMenuIntent:
              CallbackAction<_OpenDevelopmentMenuIntent>(
                onInvoke: (_) {
                  showDevelopmentMenu();
                  return null;
                },
              ),
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            const hitTargetSize = 64.0;
            const deleteTargetWidth = 156.0;
            const deleteTargetHeight = 56.0;
            const deleteTargetBottom = 18.0;
            final maxLeft = math.max(
              0.0,
              constraints.maxWidth - hitTargetSize,
            );
            final maxTop = math.max(
              0.0,
              constraints.maxHeight - hitTargetSize,
            );
            final fallbackOffset = Offset(
              maxLeft - 6,
              math.max(0.0, maxTop - 68),
            );
            final rawOffset = menuButtonOffset.value ?? fallbackOffset;
            final offset = Offset(
              rawOffset.dx.clamp(0.0, maxLeft),
              rawOffset.dy.clamp(0.0, maxTop),
            );
            final deleteTargetRect = Rect.fromLTWH(
              (constraints.maxWidth - deleteTargetWidth) / 2,
              constraints.maxHeight - deleteTargetHeight - deleteTargetBottom,
              deleteTargetWidth,
              deleteTargetHeight,
            );
            final buttonCenter = offset.translate(
              hitTargetSize / 2,
              hitTargetSize / 2,
            );
            final isOverDeleteTarget = deleteTargetRect.contains(
              buttonCenter,
            );

            return Stack(
              children: [
                child,
                if (isDraggingMenuButton.value)
                  Positioned(
                    left: deleteTargetRect.left,
                    top: deleteTargetRect.top,
                    width: deleteTargetRect.width,
                    height: deleteTargetRect.height,
                    child: _DeveloperIconDeleteTarget(
                      isActive: isOverDeleteTarget,
                    ),
                  ),
                if (isMenuButtonVisible.value)
                  Positioned(
                    left: offset.dx,
                    top: offset.dy,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanStart: (_) => isDraggingMenuButton.value = true,
                      onPanUpdate: (details) {
                        final current = menuButtonOffset.value ?? offset;
                        menuButtonOffset.value = Offset(
                          (current.dx + details.delta.dx).clamp(0.0, maxLeft),
                          (current.dy + details.delta.dy).clamp(0.0, maxTop),
                        );
                      },
                      onPanCancel: () => isDraggingMenuButton.value = false,
                      onPanEnd: (_) {
                        final current = menuButtonOffset.value ?? offset;
                        final currentCenter = current.translate(
                          hitTargetSize / 2,
                          hitTargetSize / 2,
                        );
                        isDraggingMenuButton.value = false;
                        if (deleteTargetRect.contains(currentCenter)) {
                          isMenuButtonVisible.value = false;
                          menuButtonOffset.value = null;
                        }
                      },
                      child: SizedBox.square(
                        dimension: hitTargetSize,
                        // The overlay sits above the navigator, outside any
                        // Overlay a tooltip could use, so the label is
                        // semantic only.
                        child: Center(
                          child: Semantics(
                            button: true,
                            label: context.l10n.developerIconTooltip,
                            child: FloatingActionButton.small(
                              key: VerilyTestKeys.developerMenuLauncher,
                              heroTag: null,
                              onPressed: showDevelopmentMenu,
                              child: const SkribbleIcon(
                                data: VerilyIcons.developer,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DeveloperIconDeleteTarget extends StatelessWidget {
  const _DeveloperIconDeleteTarget({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    // The target floats over any screen, so it inverts the paper until the
    // launcher is over it, then turns to the error roles.
    final backgroundColor = isActive
        ? theme.colorScheme.errorContainer
        : palette.ink;
    final foregroundColor = isActive
        ? theme.colorScheme.onErrorContainer
        : palette.canvas;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      decoration: VerilyRoughDecoration(
        color: backgroundColor,
        outline: foregroundColor.withValues(alpha: isActive ? 0.7 : 0.5),
        radius: VerilyRadius.chip,
        seed: 191,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SkribbleIcon(
            data: VerilyIcons.delete,
            color: foregroundColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            context.l10n.developerRemoveIcon,
            style: theme.textTheme.labelLarge?.copyWith(
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DebugReassembleIntent extends Intent {
  const _DebugReassembleIntent();
}

class _OpenDevelopmentMenuIntent extends Intent {
  const _OpenDevelopmentMenuIntent();
}

class _DevelopmentMenu extends StatelessWidget {
  const _DevelopmentMenu({
    required this.serverUrl,
    required this.tools,
    required this.onShowDeveloperIcon,
    required this.onHotReload,
    required this.onFullReload,
    required this.onFullRestart,
  });

  final String? serverUrl;
  final List<DevelopmentTool> tools;
  final VoidCallback onShowDeveloperIcon;
  final Future<void> Function() onHotReload;
  final VoidCallback? onFullReload;
  final VoidCallback? onFullRestart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    final allTools = [
      DevelopmentTool(
        key: VerilyTestKeys.developerSkribblePreview,
        icon: VerilyIcons.draw,
        title: l10n.developerSkribblePreview,
        subtitle: l10n.developerSkribblePreviewSubtitle,
        builder: (context) => const SkribblePreviewScreen(),
      ),
      ...tools,
    ];

    void open(DevelopmentTool tool) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: tool.builder));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SkribbleIcon(data: VerilyIcons.developer, color: palette.ink),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        l10n.developerMenuTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: palette.ink,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.developerCloseMenu,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const SkribbleIcon(data: VerilyIcons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DevActionTile(
                icon: VerilyIcons.developer,
                title: l10n.developerIconShow,
                subtitle: l10n.developerIconShowSubtitle,
                onPressed: () {
                  onShowDeveloperIcon();
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 12),
              _InfoTile(
                icon: VerilyIcons.rotatePhone,
                title: l10n.developerOrientationTitle,
                value: l10n.developerPortraitOnly,
              ),
              _InfoTile(
                icon: VerilyIcons.server,
                title: l10n.developerServerTitle,
                value: serverUrl ?? l10n.developerServerNotConfigured,
              ),
              for (final tool in allTools) ...[
                const SizedBox(height: 8),
                _DevActionTile(
                  key: tool.key,
                  icon: tool.icon,
                  title: tool.title,
                  subtitle: tool.subtitle,
                  onPressed: () => open(tool),
                ),
              ],
              const SizedBox(height: 16),
              _DevActionTile(
                icon: VerilyIcons.bolt,
                title: l10n.developerHotReload,
                subtitle: l10n.developerHotReloadSubtitle,
                onPressed: () async {
                  Navigator.of(context).pop();
                  await onHotReload();
                },
              ),
              const SizedBox(height: 8),
              _DevActionTile(
                icon: VerilyIcons.refresh,
                title: l10n.developerFullReload,
                subtitle: l10n.developerFullReloadSubtitle,
                onPressed: switch (onFullReload) {
                  final reload? => () {
                    Navigator.of(context).pop();
                    reload();
                  },
                  null => null,
                },
              ),
              const SizedBox(height: 8),
              _DevActionTile(
                icon: VerilyIcons.replay,
                title: l10n.developerFullRestart,
                subtitle: l10n.developerFullRestartSubtitle,
                onPressed: switch (onFullRestart) {
                  final restart? => () {
                    Navigator.of(context).pop();
                    restart();
                  },
                  null => null,
                },
              ),
              const SizedBox(height: 16),
              _InfoTile(
                icon: VerilyIcons.vibrate,
                title: l10n.developerDebugShortcutsTitle,
                value: l10n.developerDebugShortcutsValue,
              ),
              const SizedBox(height: 16),
              VerilyActionButton(
                tone: VerilyActionTone.secondary,
                onPressed: () => Navigator.of(context).pop(),
                label: l10n.developerClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DevActionTile extends StatelessWidget {
  const _DevActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    super.key,
  });

  final WiredSvgIconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Quiet paper rows under the theme's pen; none of these tools is the one
    // deliberate step, so none takes the stamp fill.
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          alignment: AlignmentDirectional.centerStart,
        ),
        onPressed: onPressed,
        icon: SkribbleIcon(data: icon),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.verily.mutedInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final WiredSvgIconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkribbleIcon(data: icon, size: 20, color: palette.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: palette.mutedInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
