import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:verily_flutter/testing/verily_test_keys.dart';

/// Asks for the note that goes on the record with a decision. Returns the
/// trimmed note, or null when the person backed out.
///
/// The note is required: a decision without a reason cannot be explained to
/// the participant or audited later.
Future<String?> showDecisionNoteDialog(
  BuildContext context, {
  required String title,
  required String label,
  required String hint,
  required String confirmLabel,
  String? body,
  int maxLength = 500,
}) => showDialog<String>(
  context: context,
  builder: (context) => _DecisionNoteDialog(
    title: title,
    body: body,
    label: label,
    hint: hint,
    confirmLabel: confirmLabel,
    maxLength: maxLength,
  ),
);

class _DecisionNoteDialog extends HookWidget {
  const _DecisionNoteDialog({
    required this.title,
    required this.body,
    required this.label,
    required this.hint,
    required this.confirmLabel,
    required this.maxLength,
  });

  final String title;
  final String? body;
  final String label;
  final String hint;
  final String confirmLabel;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final note = useValueListenable(controller).text.trim();
    final localizations = MaterialLocalizations.of(context);

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (body case final text?) ...[
              Text(text),
              const SizedBox(height: 16),
            ],
            TextField(
              key: VerilyTestKeys.decisionNote,
              controller: controller,
              autofocus: true,
              maxLength: maxLength,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: label, hintText: hint),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.cancelButtonLabel),
        ),
        FilledButton(
          key: VerilyTestKeys.decisionSubmit,
          onPressed: note.isEmpty
              ? null
              : () => Navigator.of(context).pop(note),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
