import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skribble/skribble.dart'
    show SkribbleIcon, WiredLoadingIndicator;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_rough_decoration.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/core/user_message.dart';
import 'package:verily_flutter/features/appeals/evidence_appeal_repository.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';
import 'package:verily_flutter/features/evidence/proof_reasons.dart';

/// A rejected attempt and the one appeal it allows.
///
/// A person (the action's creator) reads the appeal; the copy says so and
/// promises nothing about the outcome.
class AppealSection extends HookConsumerWidget {
  const AppealSection({required this.attempt, this.reasonCode, super.key});

  final ActionAttemptView attempt;

  /// Why the proof sent from this page was not accepted, when it was; the
  /// attempt's own reason otherwise.
  final String? reasonCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final l10n = context.l10n;
    final loading = useState(true);
    final sending = useState(false);
    final appeal = useState<EvidenceAppealView?>(null);
    final failure = useState<String?>(null);

    useEffect(() {
      var active = true;
      unawaited(() async {
        try {
          final existing = await ref
              .read(evidenceAppealRepositoryProvider)
              .getMine(attempt.id);
          if (active) appeal.value = existing;
        } on Exception catch (error) {
          // Without the record the button still shows; the server allows
          // one appeal and refuses a second.
          debugPrint('Appeal status unavailable: $error');
        } finally {
          if (active) loading.value = false;
        }
      }());
      return () => active = false;
    }, [attempt.id]);

    Future<void> submit() async {
      final reason = await showDialog<String>(
        context: context,
        builder: (_) => const _AppealDialog(),
      );
      if (reason == null || !context.mounted) return;
      sending.value = true;
      failure.value = null;
      try {
        appeal.value = await ref
            .read(evidenceAppealRepositoryProvider)
            .submit(attemptId: attempt.id, reason: reason);
      } on Exception catch (error) {
        debugPrint('Appeal failed: $error');
        if (context.mounted) failure.value = userMessageFor(l10n, error);
      } finally {
        if (context.mounted) sending.value = false;
      }
    }

    final current = appeal.value;
    return Container(
      key: VerilyTestKeys.actionRejectedOutcome,
      padding: const EdgeInsets.all(16),
      decoration: VerilyRoughDecoration(
        color: palette.surface,
        outline: palette.ink,
        seed: 281,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.attemptStatusRejected,
            style: theme.textTheme.titleLarge?.copyWith(color: palette.ink),
          ),
          const SizedBox(height: 6),
          Text(
            switch (reasonCode ?? attempt.rejectionCode) {
              final code? => proofReasonMessage(l10n, code),
              null => l10n.actionRejectedBody,
            },
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.mutedInk,
            ),
          ),
          const SizedBox(height: 12),
          if (loading.value)
            Center(child: WiredLoadingIndicator(color: palette.ink))
          else if (current != null)
            Row(
              children: [
                SkribbleIcon(data: VerilyIcons.review, color: palette.review),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    switch (current.status) {
                      EvidenceAppealStatus.pending => l10n.actionAppealPending,
                      EvidenceAppealStatus.accepted =>
                        l10n.actionAppealAccepted,
                      EvidenceAppealStatus.rejected =>
                        l10n.actionAppealRejected,
                    },
                    key: VerilyTestKeys.actionAppealStatus,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.ink,
                    ),
                  ),
                ),
              ],
            )
          else ...[
            Text(
              l10n.actionAppealInvite,
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.mutedInk,
              ),
            ),
            const SizedBox(height: 12),
            VerilyActionButton(
              key: VerilyTestKeys.actionAppealOpen,
              label: l10n.actionAppealOpen,
              tone: VerilyActionTone.secondary,
              isLoading: sending.value,
              leading: const SkribbleIcon(data: VerilyIcons.review),
              onPressed: () => unawaited(submit()),
            ),
          ],
          if (failure.value case final message?) ...[
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: palette.ink),
            ),
          ],
        ],
      ),
    );
  }
}

class _AppealDialog extends HookWidget {
  const _AppealDialog();

  static const _minimumLength = 10;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = useTextEditingController();
    final reason = useValueListenable(controller).text.trim();
    return AlertDialog(
      title: Text(l10n.actionAppealTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.actionAppealBody),
          const SizedBox(height: 12),
          TextField(
            key: VerilyTestKeys.actionAppealReason,
            controller: controller,
            minLines: 3,
            maxLines: 5,
            maxLength: 1000,
            decoration: InputDecoration(
              labelText: l10n.actionAppealReasonLabel,
              hintText: l10n.actionAppealReasonHint,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.dialogCancel),
        ),
        FilledButton(
          key: VerilyTestKeys.actionAppealSubmit,
          onPressed: reason.length >= _minimumLength
              ? () => Navigator.of(context).pop(reason)
              : null,
          child: Text(l10n.actionAppealSubmit),
        ),
      ],
    );
  }
}
