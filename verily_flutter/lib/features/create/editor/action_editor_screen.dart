import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/app/widgets/verily_app_header.dart';
import 'package:verily_flutter/app/widgets/verily_state_panel.dart';
import 'package:verily_flutter/core/user_message.dart';
import 'package:verily_flutter/features/actions/action_repository.dart';
import 'package:verily_flutter/features/create/editor/editor_form.dart';
import 'package:verily_flutter/features/create/editor/editor_labels.dart';
import 'package:verily_flutter/features/create/editor/editor_providers.dart';
import 'package:verily_flutter/features/create/editor/widgets/add_proof_sheet.dart';
import 'package:verily_flutter/features/create/editor/widgets/editor_common.dart';
import 'package:verily_flutter/features/create/editor/widgets/requirement_card.dart';
import 'package:verily_flutter/features/create/editor/widgets/reward_section.dart';
import 'package:verily_flutter/features/create/editor/widgets/start_section.dart';
import 'package:verily_flutter/features/create/editor/widgets/timing_section.dart';
import 'package:verily_flutter/features/create/funding/reward_funding_sheet.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// The widest the editor's column grows on tablets and browsers.
const _maxContentWidth = 640.0;

/// Writes an action: its place, its proof, and an optional escrowed reward.
///
/// Every save is a private draft (`saveDraft`); nothing goes live until the
/// creator publishes. A rewarded action is funded first: the escrow must be
/// verified by the server before the action can publish.
class ActionEditorScreen extends HookConsumerWidget {
  const ActionEditorScreen({this.actionId, super.key});

  /// The action to edit, or null for a new one (`/actions/new`).
  final String? actionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final id = actionId;
    if (id == null) return const _NewActionEditor();

    final action = ref.watch(editorActionProvider(id));
    // Once the action has loaded, the form is the creator's: a later refresh
    // of the provider must never replace it or discard their edits.
    return switch (action) {
      AsyncValue(hasValue: true, :final requireValue) => _EditorPage(
        key: ValueKey(requireValue.id),
        create: () => EditorForm.fromAction(requireValue),
        isNew: false,
      ),
      AsyncError(:final error) => _EditorFrame(
        title: l10n.editorEditTitle,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: VerilyStatePanel.problem(
            title: l10n.editorLoadFailed,
            message: userMessageFor(l10n, error),
            // A missing action stays missing; anything else may pass.
            action: error is ResourceNotFoundException
                ? null
                : VerilyStateAction(
                    label: l10n.dialogRetry,
                    onPressed: () => ref.invalidate(editorActionProvider(id)),
                  ),
          ),
        ),
      ),
      _ => _EditorFrame(
        title: l10n.editorEditTitle,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: VerilyLoadingPanel(label: l10n.editorLoading),
        ),
      ),
    };
  }
}

/// A new action: the starting choices, then the editor with what was
/// chosen.
class _NewActionEditor extends HookWidget {
  const _NewActionEditor();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final started = useState<EditorForm?>(null);

    if (started.value case final form?) {
      return _EditorPage(
        key: ObjectKey(form),
        create: () => form,
        isNew: true,
        onStartOver: () => started.value = null,
      );
    }
    return _EditorFrame(
      title: l10n.editorNewTitle,
      subtitle: l10n.editorNewSubtitle,
      child: _PageColumn(
        child: EditorStartSection(onStart: (form) => started.value = form),
      ),
    );
  }
}

/// The page around the editor: its header and a close action.
class _EditorFrame extends StatelessWidget {
  const _EditorFrame({
    required this.title,
    required this.child,
    this.subtitle,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).verily;
    return Scaffold(
      backgroundColor: palette.canvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VerilyAppHeader(
            title: title,
            subtitle: subtitle,
            trailing: const _CloseButton(),
          ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: bottom,
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
      onPressed: () {
        final router = GoRouter.maybeOf(context);
        if (router == null) {
          Navigator.of(context).maybePop();
        } else if (router.canPop()) {
          router.pop();
        } else {
          router.goNamed(VerilyRouteNames.create);
        }
      },
      icon: const SkribbleIcon(data: VerilyIcons.close),
    );
  }
}

/// A scrolling column with the 16-unit gutter, centred on wide screens.
class _PageColumn extends StatelessWidget {
  const _PageColumn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gutter = math.max(
            16.0,
            (constraints.maxWidth - _maxContentWidth) / 2,
          );
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
            child: child,
          );
        },
      ),
    );
  }
}

enum _Busy { saving, previewing, publishing }

/// The editor itself. Owns [create]'s form and disposes it.
class _EditorPage extends HookConsumerWidget {
  const _EditorPage({
    required this.create,
    required this.isNew,
    this.onStartOver,
    super.key,
  });

  final EditorForm Function() create;
  final bool isNew;

  /// Discards the unsaved form and returns to the starting choices.
  final VoidCallback? onStartOver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final form = useMemoized(create);
    useEffect(() => form.dispose, [form]);
    useListenable(form);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final validateAlways = useState(false);
    final busy = useState<_Busy?>(null);

    void say(String message) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    bool validate() {
      final valid = formKey.currentState?.validate() ?? false;
      if (!valid) {
        validateAlways.value = true;
        say(l10n.editorFixErrors);
      }
      return valid;
    }

    /// Saves the form as a private draft and returns the server's version,
    /// or null after telling the creator why it failed.
    Future<ActionOpportunity?> saveDraft() async {
      try {
        final saved = await ref
            .read(actionRepositoryProvider)
            .saveDraft(form.toRequest());
        form.acceptSaved(saved);
        return saved;
      } on ActionAuthoringException catch (error) {
        // A key collision can only happen before the first save; the next
        // attempt picks a fresh suffix.
        if (error.reason == ActionAuthoringProblem.actionKeyTaken &&
            !form.isSaved) {
          form.actionKey = null;
        }
        if (context.mounted) say(userMessageFor(l10n, error));
        return null;
      } on Object catch (error) {
        debugPrint('Saving an action draft failed: $error');
        if (context.mounted) say(userMessageFor(l10n, error));
        return null;
      }
    }

    Future<T> run<T>(_Busy kind, Future<T> Function() task) async {
      busy.value = kind;
      try {
        return await task();
      } finally {
        if (context.mounted) busy.value = null;
      }
    }

    Future<void> save() async {
      if (!validate()) return;
      await run(_Busy.saving, () async {
        final saved = await saveDraft();
        if (saved != null && context.mounted) say(l10n.editorSaved);
      });
    }

    Future<void> preview() async {
      if (!validate()) return;
      await run(_Busy.previewing, () async {
        final saved = await saveDraft();
        if (saved == null || !context.mounted) return;
        unawaited(
          GoRouter.of(context)
              .push<void>(VerilyLocations.action(saved.id.uuid)),
        );
      });
    }

    Future<void> publish() async {
      if (!validate()) return;
      final title = form.title.text.trim();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.editorPublishConfirmTitle(title)),
          content: Text(l10n.editorPublishConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.dialogCancel),
            ),
            FilledButton(
              key: VerilyTestKeys.editorPublishConfirm,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.editorPublishConfirm),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;

      final saved = await run(_Busy.publishing, saveDraft);
      if (saved == null || !context.mounted) return;
      final reward = saved.reward;
      if (reward != null && reward.status != RewardPoolStatus.funded) {
        // The funding sheet is its own step; the editor waits behind it.
        final pool = await showRewardFunding(context, action: saved);
        if (!context.mounted) return;
        if (pool != null) form.lockReward(pool.status);
        if (pool?.status != RewardPoolStatus.funded) {
          say(l10n.editorFundFirst);
          return;
        }
      }
      await run(_Busy.publishing, () async {
        try {
          final published = await ref
              .read(actionRepositoryProvider)
              .publish(saved);
          form.acceptSaved(published);
          if (!context.mounted) return;
          say(l10n.editorPublished);
          unawaited(
            GoRouter.of(
              context,
            ).pushReplacement(VerilyLocations.action(published.id.uuid)),
          );
        } on Object catch (error) {
          debugPrint('Publishing an action failed: $error');
          if (context.mounted) say(userMessageFor(l10n, error));
        }
      });
    }

    final saved = form.savedAction;
    final needsFunding =
        form.reward.enabled &&
        form.reward.lockedStatus != RewardPoolStatus.funded;

    return _EditorFrame(
      title: isNew && saved == null
          ? l10n.editorNewTitle
          : l10n.editorEditTitle,
      subtitle: switch (saved) {
        final action? when action.status == ActionDefinitionStatus.active =>
          l10n.editorEditSubtitle,
        final action? => actionStatusName(l10n, action.status),
        null => l10n.editorNewSubtitle,
      },
      bottom: _ActionBar(
        busy: busy.value,
        publishLabel: needsFunding
            ? l10n.editorFundAndPublish
            : l10n.editorPublish,
        onSave: save,
        onPublish: publish,
      ),
      child: Form(
        key: formKey,
        autovalidateMode: validateAlways.value
            ? AutovalidateMode.always
            : AutovalidateMode.disabled,
        child: _PageColumn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isNew && saved == null && onStartOver != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.editorDraftReady,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).verily.mutedInk,
                        ),
                      ),
                    ),
                    TextButton(
                      key: VerilyTestKeys.editorStartOver,
                      onPressed: onStartOver,
                      child: Text(l10n.editorStartOver),
                    ),
                  ],
                ),
                const SizedBox(height: editorStackGap),
              ],
              if (form.safetyNotes.isNotEmpty) ...[
                EditorSection(
                  title: l10n.editorSafetyHeading,
                  children: [
                    for (final note in form.safetyNotes) ...[
                      EditorNote(text: note, icon: VerilyIcons.warning),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
                const SizedBox(height: editorSectionGap),
              ],
              _BasicsSection(form: form),
              const SizedBox(height: editorSectionGap),
              _ProofSection(form: form),
              const SizedBox(height: editorSectionGap),
              TimingSection(form: form),
              const SizedBox(height: editorSectionGap),
              RewardSection(form: form),
              const SizedBox(height: editorSectionGap),
              VerilyActionButton(
                key: VerilyTestKeys.editorPreview,
                label: l10n.editorPreview,
                tone: VerilyActionTone.secondary,
                isLoading: busy.value == _Busy.previewing,
                leading: const SkribbleIcon(data: VerilyIcons.eye),
                onPressed: busy.value == null ? preview : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BasicsSection extends StatelessWidget {
  const _BasicsSection({required this.form});

  final EditorForm form;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String? required(String? text) =>
        (text ?? '').trim().isEmpty ? l10n.editorFieldRequired : null;

    return EditorSection(
      title: l10n.editorBasicsHeading,
      children: [
        TextFormField(
          key: VerilyTestKeys.editorTitle,
          controller: form.title,
          textCapitalization: TextCapitalization.sentences,
          inputFormatters: [
            LengthLimitingTextInputFormatter(EditorLimits.maxTitleLength),
          ],
          decoration: InputDecoration(labelText: l10n.editorTitleLabel),
          validator: required,
        ),
        const SizedBox(height: editorStackGap),
        TextFormField(
          key: VerilyTestKeys.editorDescription,
          controller: form.description,
          textCapitalization: TextCapitalization.sentences,
          minLines: 3,
          maxLines: 8,
          inputFormatters: [
            LengthLimitingTextInputFormatter(EditorLimits.maxDescriptionLength),
          ],
          decoration: InputDecoration(labelText: l10n.editorDescriptionLabel),
          validator: required,
        ),
      ],
    );
  }
}

class _ProofSection extends StatelessWidget {
  const _ProofSection({required this.form});

  final EditorForm form;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    Future<void> addProof() async {
      final kind = await showAddProofSheet(context, form);
      if (kind == null || !form.canAdd(kind) || !context.mounted) return;
      form.add(
        RequirementForm.blank(
          kind,
          requirementKey: form.keyFor(kind),
          title: proofKindDefaultTitle(l10n, kind),
          instructions: proofKindDefaultInstructions(l10n, kind),
        ),
      );
    }

    return EditorSection(
      title: l10n.editorProofHeading,
      help: l10n.editorProofHelp,
      children: [
        for (final requirement in form.requirements) ...[
          RequirementCard(
            key: ObjectKey(requirement),
            form: form,
            requirement: requirement,
          ),
          const SizedBox(height: editorStackGap),
        ],
        FormField<void>(
          validator: (_) =>
              form.requirements.isEmpty ? l10n.editorProofNone : null,
          builder: (field) => field.hasError
              ? Padding(
                  padding: const EdgeInsets.only(bottom: editorStackGap),
                  child: Text(
                    field.errorText!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.verily.ink,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        VerilyActionButton(
          key: VerilyTestKeys.editorAddProof,
          label: l10n.editorAddProof,
          tone: VerilyActionTone.secondary,
          leading: const SkribbleIcon(data: VerilyIcons.plus),
          // Always open: the sheet says why a kind cannot be added.
          onPressed: addProof,
        ),
      ],
    );
  }
}

/// Save draft beside the one primary action, always in reach.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.busy,
    required this.publishLabel,
    required this.onSave,
    required this.onPublish,
  });

  final _Busy? busy;
  final String publishLabel;
  final VoidCallback onSave;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = Theme.of(context).verily;
    final idle = busy == null;
    return Material(
      color: palette.canvas,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: VerilyActionButton(
                  key: VerilyTestKeys.editorSave,
                  label: l10n.editorSave,
                  tone: VerilyActionTone.secondary,
                  isLoading: busy == _Busy.saving,
                  onPressed: idle ? onSave : null,
                ),
              ),
              const SizedBox(width: editorStackGap),
              Expanded(
                child: VerilyActionButton(
                  key: VerilyTestKeys.editorPublish,
                  label: publishLabel,
                  isLoading: busy == _Busy.publishing,
                  onPressed: idle ? onPublish : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
