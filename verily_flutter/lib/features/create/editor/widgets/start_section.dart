import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/app/widgets/verily_state_panel.dart';
import 'package:verily_flutter/core/user_message.dart';
import 'package:verily_flutter/features/actions/action_repository.dart';
import 'package:verily_flutter/features/create/editor/editor_form.dart';
import 'package:verily_flutter/features/create/editor/editor_labels.dart';
import 'package:verily_flutter/features/create/editor/editor_providers.dart';
import 'package:verily_flutter/features/create/editor/widgets/editor_common.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// The three ways into a new action: describe it and let Verily draft it,
/// pick one of the server's templates, or start from a blank page.
class EditorStartSection extends HookConsumerWidget {
  const EditorStartSection({required this.onStart, super.key});

  /// Receives the form to edit. The receiver owns and disposes it.
  final ValueChanged<EditorForm> onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prompt = useTextEditingController();
    final drafting = useState(false);
    final promptError = useState<String?>(null);
    final draftProblem = useState<String?>(null);
    final templates = ref.watch(editorTemplatesProvider);
    final deviceZone = ref.watch(deviceTimeZoneProvider).value ?? 'UTC';

    Future<void> draft() async {
      final text = prompt.text.trim();
      if (text.length < EditorLimits.minDraftPromptLength) {
        promptError.value = l10n.editorPromptTooShort;
        return;
      }
      promptError.value = null;
      draftProblem.value = null;
      drafting.value = true;
      try {
        final proposal = await ref
            .read(actionRepositoryProvider)
            .draftFromPrompt(text);
        if (!context.mounted) return;
        final request = proposal.action;
        onStart(
          EditorForm.fromRequest(
            // A draft that names no zone of its own starts in the creator's.
            request.timeZone == 'UTC'
                ? request.copyWith(timeZone: deviceZone)
                : request,
            safetyNotes: proposal.safetyNotes,
          ),
        );
      } on ActionDraftingUnavailableException catch (error) {
        // Drafting is off or today's allowance is spent. The server's words
        // say which, and the templates below still work.
        if (!context.mounted) return;
        draftProblem.value = userMessageFor(l10n, error);
      } on Object catch (error) {
        debugPrint('Drafting an action failed: $error');
        if (!context.mounted) return;
        draftProblem.value = userMessageFor(l10n, error);
      } finally {
        if (context.mounted) drafting.value = false;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorSection(
          title: l10n.editorStartHeading,
          children: [
            TextField(
              key: VerilyTestKeys.editorPrompt,
              controller: prompt,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [
                LengthLimitingTextInputFormatter(
                  EditorLimits.maxDraftPromptLength,
                ),
              ],
              decoration: InputDecoration(
                labelText: l10n.editorPromptLabel,
                hintText: l10n.editorPromptHint,
                helperText: l10n.editorPromptHelp,
                helperMaxLines: 3,
                errorText: promptError.value,
                errorMaxLines: 2,
              ),
            ),
            const SizedBox(height: editorStackGap),
            VerilyActionButton(
              key: VerilyTestKeys.editorDraftWithAi,
              label: l10n.editorPromptAction,
              isLoading: drafting.value,
              leading: const SkribbleIcon(data: VerilyIcons.sparkle),
              onPressed: draft,
            ),
            if (draftProblem.value case final problem?) ...[
              const SizedBox(height: editorStackGap),
              EditorNote(text: problem),
            ],
          ],
        ),
        const SizedBox(height: editorSectionGap),
        EditorSection(
          title: l10n.editorTemplatesHeading,
          children: [
            ...switch (templates) {
              AsyncData(:final value) => [
                for (final template in value) ...[
                  _TemplateCard(
                    template: template,
                    onTap: () => onStart(
                      _formFromTemplate(template, timeZone: deviceZone),
                    ),
                  ),
                  const SizedBox(height: editorStackGap),
                ],
              ],
              AsyncError() => [
                VerilyStatePanel.problem(
                  title: l10n.editorTemplatesFailed,
                  action: VerilyStateAction(
                    label: l10n.dialogRetry,
                    onPressed: () => ref.invalidate(editorTemplatesProvider),
                  ),
                ),
                const SizedBox(height: editorStackGap),
              ],
              _ => [
                VerilyLoadingPanel(label: l10n.editorTemplatesLoading),
                const SizedBox(height: editorStackGap),
              ],
            },
            VerilyActionButton(
              key: VerilyTestKeys.editorStartBlank,
              label: l10n.editorStartBlank,
              tone: VerilyActionTone.secondary,
              leading: const SkribbleIcon(data: VerilyIcons.edit),
              onPressed: () => onStart(
                EditorForm(title: '', description: '', timeZone: deviceZone),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static EditorForm _formFromTemplate(
    ActionTemplate template, {
    required String timeZone,
  }) => EditorForm(
    title: template.title,
    description: template.description,
    recurrence: template.suggestedRecurrence,
    timeZone: timeZone,
    requirements: [
      for (final draft in template.requirements)
        RequirementForm.fromDraft(draft),
    ],
  );
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.onTap});

  final ActionTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.verily;
    final kinds = {
      for (final draft in template.requirements)
        proofKindOf(draft.kind, hasMovement: draft.movementKind != null),
    };
    return Semantics(
      button: true,
      child: InkWell(
        key: VerilyTestKeys.editorTemplate(template.templateKey),
        onTap: onTap,
        borderRadius: BorderRadius.circular(VerilyRadius.card),
        child: EditorPanel(
          seed: 350 + template.templateKey.length,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.mutedInk,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ExcludeSemantics(
                      child: Wrap(
                        spacing: 8,
                        children: [
                          for (final kind in kinds)
                            SkribbleIcon(
                              data: proofKindIcon(kind),
                              size: 20,
                              color: palette.ink,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
