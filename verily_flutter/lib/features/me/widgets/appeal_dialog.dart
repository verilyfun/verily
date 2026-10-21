import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// The shortest reason the server accepts for an appeal.
const appealReasonMinLength = 10;

/// The longest reason the server accepts for an appeal.
const appealReasonMaxLength = 1000;

/// Asks why a rejected proof should count. Returns the trimmed reason, or
/// null when the person backed out.
Future<String?> showAppealDialog(BuildContext context) =>
    showDialog<String>(context: context, builder: (_) => const _AppealDialog());

class _AppealDialog extends HookWidget {
  const _AppealDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = useTextEditingController();
    final reason = useValueListenable(controller).text.trim();
    final ready = reason.length >= appealReasonMinLength;

    return AlertDialog(
      title: Text(l10n.meAppealTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.meAppealBody),
            const SizedBox(height: 16),
            TextField(
              key: VerilyTestKeys.meAppealReason,
              controller: controller,
              autofocus: true,
              maxLength: appealReasonMaxLength,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.meAppealReasonLabel,
                hintText: l10n.meAppealReasonHint,
                helperText: l10n.meAppealReasonHelper,
                helperMaxLines: 2,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: VerilyTestKeys.meAppealSubmit,
          onPressed: ready ? () => Navigator.of(context).pop(reason) : null,
          child: Text(l10n.meAppealSend),
        ),
      ],
    );
  }
}
