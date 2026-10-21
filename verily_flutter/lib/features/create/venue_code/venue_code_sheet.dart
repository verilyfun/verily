import 'dart:async';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/app/widgets/verily_rough_surface.dart';
import 'package:verily_flutter/app/widgets/verily_state_panel.dart';
import 'package:verily_flutter/features/actions/action_repository.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// Shows the rotating venue QR code for one of the creator's `qrCode`
/// requirements, so people at the venue can scan it. Each code is
/// short-lived and single-use; the sheet fetches a fresh one as each expires.
Future<void> showVenueCode(
  BuildContext context, {
  required ActionOpportunity action,
  required ActionRequirementView requirement,
}) => showModalBottomSheet<void>(
  context: context,
  // Over the tab bar too: the sheet is the whole task until it closes.
  useRootNavigator: true,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) => _VenueCodeSheet(requirement: requirement),
);

class _VenueCodeSheet extends HookConsumerWidget {
  const _VenueCodeSheet({required this.requirement});

  final ActionRequirementView requirement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final challenge = useState<ActionQrChallengeView?>(null);
    final loading = useState(true);
    final failed = useState(false);
    final now = useState(clock.now());

    Future<void> fetch() async {
      loading.value = true;
      failed.value = false;
      try {
        final next = await ref
            .read(actionRepositoryProvider)
            .createQrChallenge(requirement.id);
        if (!context.mounted) return;
        challenge.value = next;
        now.value = clock.now();
      } on Object catch (error) {
        debugPrint('Issuing a venue code failed: $error');
        if (context.mounted) failed.value = true;
      } finally {
        if (context.mounted) loading.value = false;
      }
    }

    useEffect(() {
      unawaited(fetch());
      // Ticks the countdown and swaps in a fresh code once the shown one
      // expires. A failed request waits for the creator to try again rather
      // than retrying every second.
      final timer = Timer.periodic(const Duration(seconds: 1), (_) {
        now.value = clock.now();
        final shown = challenge.value;
        if (shown != null &&
            !loading.value &&
            !failed.value &&
            !now.value.isBefore(shown.expiresAt)) {
          unawaited(fetch());
        }
      });
      return timer.cancel;
    }, const []);

    final shown = challenge.value;
    final remaining = shown == null
        ? Duration.zero
        : shown.expiresAt.difference(now.value);
    final expired = remaining <= Duration.zero;

    return SingleChildScrollView(
      key: VerilyTestKeys.venueCodeSheet,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  headingLevel: 2,
                  child: Text(
                    l10n.venueCodeTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: palette.ink,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.dialogClose,
                onPressed: () => Navigator.of(context).pop(),
                icon: const SkribbleIcon(data: VerilyIcons.close),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            requirement.title,
            style: theme.textTheme.titleSmall?.copyWith(color: palette.ink),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.venueCodeBody,
            style: theme.textTheme.bodyMedium?.copyWith(color: palette.ink),
          ),
          const SizedBox(height: 16),
          if (failed.value && (shown == null || expired))
            VerilyStatePanel.problem(
              title: l10n.venueCodeFailed,
              action: VerilyStateAction(
                label: l10n.dialogRetry,
                onPressed: fetch,
              ),
            )
          else if (shown == null || expired)
            VerilyLoadingPanel(label: l10n.venueCodeRefreshing)
          else ...[
            Center(
              child: _VenueQrCode(code: shown.code, title: requirement.title),
            ),
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                l10n.venueCodeChangesIn(_countdown(remaining)),
                key: VerilyTestKeys.venueCodeCountdown,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: palette.ink,
                  fontFamily: verilyNumeralFontFamily,
                ),
              ),
            ),
            const SizedBox(height: 16),
            VerilyActionButton(
              key: VerilyTestKeys.venueCodeNew,
              label: l10n.venueCodeNew,
              tone: VerilyActionTone.secondary,
              isLoading: loading.value,
              leading: const SkribbleIcon(data: VerilyIcons.refresh),
              onPressed: fetch,
            ),
            if (failed.value) ...[
              const SizedBox(height: 8),
              Text(
                l10n.venueCodeFailed,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: palette.ink),
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// `4:32`, the minutes and seconds until the code changes.
  static String _countdown(Duration remaining) {
    final seconds =
        remaining.inSeconds + (remaining.inMilliseconds % 1000 > 0 ? 1 : 0);
    final minutes = seconds ~/ 60;
    return '$minutes:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}

/// The code itself, always ink on paper so any scanner reads it, in light
/// and dark mode alike.
class _VenueQrCode extends StatelessWidget {
  const _VenueQrCode({required this.code, required this.title});

  final String code;
  final String title;

  @override
  Widget build(BuildContext context) {
    const paper = VerilyPalette.paper();
    final side = math.min(MediaQuery.sizeOf(context).width - 64, 300.0);
    return VerilyRoughSurface(
      // Keyed by the code so a fresh code never reuses the last one's
      // painted state.
      key: ValueKey<String>(code),
      fill: paper.surface,
      outline: paper.ink,
      seed: 271,
      padding: const EdgeInsets.all(16),
      child: QrImageView(
        key: VerilyTestKeys.venueCodeImage,
        data: code,
        size: side,
        padding: EdgeInsets.zero,
        backgroundColor: paper.surface,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        semanticsLabel: context.l10n.venueCodeImageLabel(title),
        eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: paper.ink),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: paper.ink,
        ),
      ),
    );
  }
}
