import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon, WiredSlider;
import 'package:verily_client/verily_client.dart';
import 'package:verily_evidence/verily_evidence.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/features/create/editor/editor_form.dart';
import 'package:verily_flutter/features/create/editor/widgets/editor_common.dart';
import 'package:verily_flutter/features/local_check/local_check_catalog.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// "Add a quick check" on a photo, video, or audio proof: a hand gesture, a
/// thing, or a sound the phone guides people toward while they capture.
///
/// The choices come from the labels the server accepts, and the phone's
/// result is only a guide: Verily checks the proof again itself, with the
/// same model, before it counts.
class QuickCheckSection extends StatelessWidget {
  const QuickCheckSection({
    required this.form,
    required this.requirement,
    super.key,
  });

  final EditorForm form;
  final RequirementForm requirement;

  MediaEvidenceKind get _media => switch (requirement.kind) {
    ProofKind.photo => MediaEvidenceKind.photo,
    ProofKind.audio => MediaEvidenceKind.audio,
    _ => MediaEvidenceKind.video,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final key = requirement.requirementKey;
    final check = requirement.localCheck;
    final tasks = localCheckTasksFor(_media);

    if (check == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              key: VerilyTestKeys.editorQuickCheckAdd(key),
              onPressed: () {
                requirement.setLocalCheckTask(tasks.first);
                form.touch();
              },
              icon: const SkribbleIcon(data: VerilyIcons.circlePlus, size: 20),
              label: Text(l10n.editorQuickCheckAdd),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                l10n.editorQuickCheckAddHelp,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.mutedInk,
                ),
              ),
            ),
          ],
        ),
      );
    }

    void update(ActionLocalCheck next) {
      requirement.localCheck = next;
      form.touch();
    }

    final percent = (check.minScore * 100).round();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: EditorPanel(
        seed: 520 + key.hashCode % 31,
        fill: palette.canvas,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SkribbleIcon(
                  data: VerilyIcons.scan,
                  size: 22,
                  color: palette.ink,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    headingLevel: 4,
                    child: Text(
                      l10n.editorQuickCheckTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: palette.ink,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  key: VerilyTestKeys.editorQuickCheckRemove(key),
                  onPressed: () {
                    requirement.localCheck = null;
                    form.touch();
                  },
                  child: Text(l10n.editorQuickCheckRemove),
                ),
              ],
            ),
            if (tasks.length > 1) ...[
              const SizedBox(height: editorStackGap),
              EditorChoices<LocalCheckTask>(
                label: l10n.editorQuickCheckTaskLabel,
                values: tasks,
                selected: check.task,
                nameOf: (task) => _taskName(l10n, task),
                keyOf: (task) =>
                    VerilyTestKeys.editorQuickCheckTask(key, task.name),
                onSelected: (task) {
                  requirement.setLocalCheckTask(task);
                  form.touch();
                },
              ),
            ],
            const SizedBox(height: editorStackGap),
            if (check.task == LocalCheckTask.gesture)
              EditorChoices<String>(
                label: l10n.editorQuickCheckGestureLabel,
                values: LocalCheckTask.gesture.model.labels,
                selected: check.label,
                nameOf: (label) =>
                    localCheckLabelName(l10n, LocalCheckTask.gesture, label),
                keyOf: (label) =>
                    VerilyTestKeys.editorQuickCheckGesture(key, label),
                onSelected: (label) => update(check.copyWith(label: label)),
              )
            else
              _LabelPickerRow(
                key: VerilyTestKeys.editorQuickCheckPickLabel(key),
                check: check,
                onPicked: (label) => update(check.copyWith(label: label)),
              ),
            const SizedBox(height: editorStackGap),
            Text(
              l10n.editorQuickCheckScore(percent),
              style: theme.textTheme.labelLarge?.copyWith(color: palette.ink),
            ),
            SizedBox(
              height: 48,
              child: WiredSlider(
                key: VerilyTestKeys.editorQuickCheckScore(key),
                value: check.minScore.clamp(
                  LocalCheckBounds.minScore,
                  LocalCheckBounds.maxScore,
                ),
                min: LocalCheckBounds.minScore,
                max: LocalCheckBounds.maxScore,
                divisions: 69,
                semanticLabel: l10n.editorQuickCheckScoreSemantic,
                onChanged: (value) {
                  update(
                    check.copyWith(
                      minScore: (value * 100).roundToDouble() / 100,
                    ),
                  );
                  return true;
                },
              ),
            ),
            if (requirement.kind == ProofKind.photo)
              Text(
                l10n.editorQuickCheckPhotoFrames,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.mutedInk,
                ),
              )
            else ...[
              Text(
                l10n.editorQuickCheckFrames(check.minFrames),
                style: theme.textTheme.labelLarge?.copyWith(color: palette.ink),
              ),
              SizedBox(
                height: 48,
                child: WiredSlider(
                  key: VerilyTestKeys.editorQuickCheckFrames(key),
                  value: check.minFrames.toDouble(),
                  min: LocalCheckBounds.minFrames.toDouble(),
                  max: LocalCheckBounds.maxFrames.toDouble(),
                  divisions:
                      LocalCheckBounds.maxFrames - LocalCheckBounds.minFrames,
                  semanticLabel: l10n.editorQuickCheckFramesSemantic,
                  onChanged: (value) {
                    update(check.copyWith(minFrames: value.round()));
                    return true;
                  },
                ),
              ),
              Text(
                l10n.editorQuickCheckFramesHelp,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.mutedInk,
                ),
              ),
            ],
            const SizedBox(height: editorStackGap),
            EditorNote(text: l10n.editorQuickCheckNote),
          ],
        ),
      ),
    );
  }
}

String _taskName(AppLocalizations l10n, LocalCheckTask task) => switch (task) {
  LocalCheckTask.gesture => l10n.editorQuickCheckTaskGesture,
  LocalCheckTask.object => l10n.editorQuickCheckTaskObject,
  LocalCheckTask.sound => l10n.editorQuickCheckTaskSound,
};

/// The chosen thing or sound, opening the full list to change it.
class _LabelPickerRow extends StatelessWidget {
  const _LabelPickerRow({
    required this.check,
    required this.onPicked,
    super.key,
  });

  final ActionLocalCheck check;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final heading = check.task == LocalCheckTask.sound
        ? l10n.editorQuickCheckSoundLabel
        : l10n.editorQuickCheckObjectLabel;
    final name = localCheckLabelName(l10n, check.task, check.label);
    return Semantics(
      button: true,
      label: '$heading: $name',
      excludeSemantics: true,
      child: InkWell(
        onTap: () async {
          final picked = await showQuickCheckLabelPicker(
            context,
            task: check.task,
            selected: check.label,
          );
          if (picked != null) onPicked(picked);
        },
        borderRadius: BorderRadius.circular(VerilyRadius.control),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      heading,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: palette.ink,
                      ),
                    ),
                  ],
                ),
              ),
              SkribbleIcon(
                data: VerilyIcons.chevronRight,
                size: 20,
                color: palette.ink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lists every thing or sound a quick check of [task] can look or listen
/// for, with a search, and returns the label picked.
Future<String?> showQuickCheckLabelPicker(
  BuildContext context, {
  required LocalCheckTask task,
  required String selected,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) => _LabelPickerSheet(task: task, selected: selected),
);

class _LabelPickerSheet extends HookWidget {
  const _LabelPickerSheet({required this.task, required this.selected});

  final LocalCheckTask task;
  final String selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final query = useState('');
    final named = useMemoized(
      () =>
          [
            for (final label in task.model.labels)
              (label: label, name: localCheckLabelName(l10n, task, label)),
          ]..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          ),
      [task],
    );
    final needle = query.value.trim().toLowerCase();
    final shown = [
      for (final entry in named)
        if (needle.isEmpty || entry.name.toLowerCase().contains(needle)) entry,
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, controller) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              headingLevel: 2,
              child: Text(
                task == LocalCheckTask.sound
                    ? l10n.editorQuickCheckPickSound
                    : l10n.editorQuickCheckPickObject,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: palette.ink,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: VerilyTestKeys.editorQuickCheckSearch,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: l10n.editorQuickCheckSearch,
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(12),
                  child: SkribbleIcon(data: VerilyIcons.search, size: 20),
                ),
              ),
              onChanged: (text) => query.value = text,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: shown.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(
                        l10n.editorQuickCheckNoMatches,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: palette.mutedInk,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: controller,
                      itemCount: shown.length,
                      itemBuilder: (context, index) {
                        final entry = shown[index];
                        final chosen = entry.label == selected;
                        return Semantics(
                          selected: chosen,
                          button: true,
                          child: InkWell(
                            key: VerilyTestKeys.editorQuickCheckLabelOption(
                              entry.label,
                            ),
                            onTap: () => Navigator.of(context).pop(entry.label),
                            borderRadius: BorderRadius.circular(
                              VerilyRadius.control,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 48),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.name,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(color: palette.ink),
                                    ),
                                  ),
                                  if (chosen)
                                    SkribbleIcon(
                                      data: VerilyIcons.check,
                                      size: 20,
                                      color: palette.ink,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
