import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/create/editor/editor_form.dart';
import 'package:verily_flutter/features/create/editor/widgets/editor_common.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// When the action can be done: once or every day, the window it is open,
/// and an optional cap on verified completions.
class TimingSection extends HookWidget {
  const TimingSection({required this.form, super.key});

  final EditorForm form;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    useListenable(form);

    Future<DateTime?> pickDay(DateTime? current) async {
      final now = clock.now();
      final first = DateTime(now.year, now.month, now.day);
      final last = first.add(const Duration(days: 365 * 2));
      final initial = current == null || current.isBefore(first)
          ? first
          : current.isAfter(last)
          ? last
          : current;
      return showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: first,
        lastDate: last,
      );
    }

    return EditorSection(
      title: l10n.editorTimingHeading,
      children: [
        SegmentedButton<ActionRecurrence>(
          key: VerilyTestKeys.editorRecurrence,
          segments: [
            ButtonSegment(
              value: ActionRecurrence.once,
              label: Text(l10n.editorOnce),
            ),
            ButtonSegment(
              value: ActionRecurrence.daily,
              label: Text(l10n.editorDaily),
            ),
          ],
          selected: {form.recurrence},
          onSelectionChanged: (selection) {
            form.recurrence = selection.single;
            form.touch();
          },
        ),
        if (form.recurrence == ActionRecurrence.daily) ...[
          const SizedBox(height: editorStackGap),
          TextFormField(
            key: VerilyTestKeys.editorTimeZone,
            controller: form.timeZone,
            autocorrect: false,
            inputFormatters: [
              LengthLimitingTextInputFormatter(EditorLimits.maxTimeZoneLength),
            ],
            decoration: InputDecoration(
              labelText: l10n.editorTimeZoneLabel,
              helperText: l10n.editorTimeZoneHelp,
              helperMaxLines: 2,
            ),
            validator: (text) =>
                (text ?? '').trim().isEmpty ? l10n.editorFieldRequired : null,
          ),
        ],
        const SizedBox(height: editorStackGap),
        EditorDateRow(
          key: VerilyTestKeys.editorOpens,
          label: l10n.editorOpensLabel,
          value: form.opensAt,
          onPick: () async {
            final day = await pickDay(form.opensAt);
            if (day == null) return;
            form.opensAt = day;
            form.touch();
          },
          onClear: () {
            form.opensAt = null;
            form.touch();
          },
        ),
        FormField<void>(
          builder: (field) => EditorDateRow(
            key: VerilyTestKeys.editorCloses,
            label: l10n.editorClosesLabel,
            value: form.closesAt,
            errorText: field.errorText,
            onPick: () async {
              final day = await pickDay(form.closesAt ?? form.opensAt);
              if (day == null) return;
              // An action closes at the end of the day it is set to.
              form.closesAt = day.copyWith(hour: 23, minute: 59);
              form.touch();
            },
            onClear: () {
              form.closesAt = null;
              form.touch();
            },
          ),
          validator: (_) {
            final opens = form.opensAt;
            final closes = form.closesAt;
            return opens != null && closes != null && !closes.isAfter(opens)
                ? l10n.editorClosesBeforeOpens
                : null;
          },
        ),
        const SizedBox(height: editorStackGap),
        TextFormField(
          key: VerilyTestKeys.editorMaxCompletions,
          controller: form.maxVerifiedCompletions,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: l10n.editorMaxCompletionsLabel,
          ),
          validator: (text) {
            final trimmed = (text ?? '').trim();
            if (trimmed.isEmpty) return null;
            final value = int.tryParse(trimmed);
            return value == null || value < 1
                ? l10n.editorWholeNumberInvalid
                : null;
          },
        ),
      ],
    );
  }
}
