import 'package:flutter/material.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon;

import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/features/create/editor/editor_form.dart';
import 'package:verily_flutter/features/create/editor/editor_labels.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// The order proof kinds are offered in: place first, then live captures,
/// then the phone's own sensors, and an App's confirmation last because it
/// replaces all of them.
const List<ProofKind> addProofOrder = [
  ProofKind.location,
  ProofKind.venueCode,
  ProofKind.video,
  ProofKind.photo,
  ProofKind.audio,
  ProofKind.movementReps,
  ProofKind.motion,
  ProofKind.appConfirmation,
];

/// Lists the proof kinds [form] can take now and returns the one picked.
/// Kinds that cannot be added stay listed with the reason.
Future<ProofKind?> showAddProofSheet(BuildContext context, EditorForm form) =>
    showModalBottomSheet<ProofKind>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _AddProofSheet(form: form),
    );

class _AddProofSheet extends StatelessWidget {
  const _AddProofSheet({required this.form});

  final EditorForm form;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final full = form.requirements.length >= EditorLimits.maxRequirements;

    String? blockedReason(ProofKind kind) {
      if (form.canAdd(kind)) return null;
      if (full) return l10n.editorProofMaxReached;
      return kind == ProofKind.appConfirmation
          ? l10n.editorProofPhoneOnly
          : l10n.editorProofAppOnly;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            headingLevel: 2,
            child: Text(
              l10n.editorAddProofSheetTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: palette.ink,
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final kind in addProofOrder)
            _ProofKindRow(kind: kind, blockedReason: blockedReason(kind)),
        ],
      ),
    );
  }
}

class _ProofKindRow extends StatelessWidget {
  const _ProofKindRow({required this.kind, required this.blockedReason});

  final ProofKind kind;

  /// Why this kind cannot be added now, or null when it can.
  final String? blockedReason;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final enabled = blockedReason == null;
    final ink = enabled ? palette.ink : palette.mutedInk;

    return InkWell(
      key: VerilyTestKeys.editorAddProofKind(kind.name),
      onTap: enabled ? () => Navigator.of(context).pop(kind) : null,
      borderRadius: BorderRadius.circular(VerilyRadius.control),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkribbleIcon(data: proofKindIcon(kind), size: 24, color: ink),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proofKindName(l10n, kind),
                      style: theme.textTheme.titleSmall?.copyWith(color: ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      blockedReason ?? proofKindHelp(l10n, kind),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.mutedInk,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
