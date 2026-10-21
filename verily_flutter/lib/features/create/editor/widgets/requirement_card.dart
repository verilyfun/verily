import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon, WiredSlider;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/features/create/editor/editor_form.dart';
import 'package:verily_flutter/features/create/editor/editor_labels.dart';
import 'package:verily_flutter/features/create/editor/editor_providers.dart';
import 'package:verily_flutter/features/create/editor/widgets/editor_common.dart';
import 'package:verily_flutter/features/create/editor/widgets/place_picker.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// One proof on the action: its name, what people do, and the rule for its
/// kind.
class RequirementCard extends StatelessWidget {
  const RequirementCard({
    required this.form,
    required this.requirement,
    super.key,
  });

  final EditorForm form;
  final RequirementForm requirement;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final key = requirement.requirementKey;
    final kindName = proofKindName(l10n, requirement.kind);

    return EditorPanel(
      key: VerilyTestKeys.editorRequirement(key),
      seed: 300 + key.hashCode % 97,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SkribbleIcon(
                data: proofKindIcon(requirement.kind),
                size: 22,
                color: requirement.kind == ProofKind.location
                    ? palette.place
                    : palette.ink,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  headingLevel: 3,
                  child: Text(
                    kindName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: palette.ink,
                    ),
                  ),
                ),
              ),
              IconButton(
                key: VerilyTestKeys.editorRemoveRequirement(key),
                tooltip: l10n.editorRemoveProof(
                  requirement.title.text.trim().isEmpty
                      ? kindName
                      : requirement.title.text.trim(),
                ),
                onPressed: () => form.remove(requirement),
                icon: const SkribbleIcon(data: VerilyIcons.delete),
              ),
            ],
          ),
          const SizedBox(height: editorStackGap),
          TextFormField(
            key: VerilyTestKeys.editorRequirementTitle(key),
            controller: requirement.title,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [
              LengthLimitingTextInputFormatter(EditorLimits.maxTitleLength),
            ],
            decoration: InputDecoration(labelText: l10n.editorProofTitleLabel),
            validator: (text) => _required(l10n, text),
          ),
          const SizedBox(height: editorStackGap),
          TextFormField(
            key: VerilyTestKeys.editorRequirementInstructions(key),
            controller: requirement.instructions,
            textCapitalization: TextCapitalization.sentences,
            minLines: 2,
            maxLines: 5,
            inputFormatters: [
              LengthLimitingTextInputFormatter(
                EditorLimits.maxInstructionsLength,
              ),
            ],
            decoration: InputDecoration(
              labelText: l10n.editorProofInstructionsLabel,
            ),
            validator: (text) => _required(l10n, text),
          ),
          const SizedBox(height: editorStackGap),
          ..._kindFields(context),
        ],
      ),
    );
  }

  List<Widget> _kindFields(BuildContext context) {
    final l10n = context.l10n;
    return switch (requirement.kind) {
      ProofKind.location => [
        PlacePicker(requirement: requirement, onChanged: form.touch),
      ],
      ProofKind.venueCode => [
        EditorNote(
          text: l10n.editorVenueCodeExplainer,
          icon: VerilyIcons.qrCode,
        ),
      ],
      ProofKind.motion => [_MotionFields(form: form, requirement: requirement)],
      ProofKind.movementReps => [
        _MovementFields(form: form, requirement: requirement),
        const SizedBox(height: editorStackGap),
        _DurationFields(requirement: requirement),
        _SpokenChallengeRow(form: form, requirement: requirement),
        _MoreChecks(form: form, requirement: requirement),
      ],
      ProofKind.video || ProofKind.audio => [
        _VerifierPromptField(form: form, requirement: requirement),
        const SizedBox(height: editorStackGap),
        _DurationFields(requirement: requirement),
        _SpokenChallengeRow(form: form, requirement: requirement),
        _MoreChecks(form: form, requirement: requirement),
      ],
      ProofKind.photo => [
        _VerifierPromptField(form: form, requirement: requirement),
        _MoreChecks(form: form, requirement: requirement),
      ],
      ProofKind.appConfirmation => [
        _AppPicker(form: form, requirement: requirement),
      ],
    };
  }
}

String? _required(AppLocalizations l10n, String? text) =>
    (text ?? '').trim().isEmpty ? l10n.editorFieldRequired : null;

/// What Verily should check in a photo, video, or audio proof.
class _VerifierPromptField extends StatelessWidget {
  const _VerifierPromptField({required this.form, required this.requirement});

  final EditorForm form;
  final RequirementForm requirement;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextFormField(
      key: VerilyTestKeys.editorVerifierPrompt(requirement.requirementKey),
      controller: requirement.prompt,
      textCapitalization: TextCapitalization.sentences,
      minLines: 2,
      maxLines: 6,
      inputFormatters: [
        LengthLimitingTextInputFormatter(
          EditorLimits.maxVerificationPromptLength,
        ),
      ],
      decoration: InputDecoration(
        labelText: l10n.editorVerifierPromptLabel,
        helperText: requirement.promptNeedsRewrite
            ? l10n.editorVerifierPromptRewrite
            : l10n.editorVerifierPromptHelp,
        helperMaxLines: 4,
      ),
      onChanged: (text) {
        if (requirement.promptNeedsRewrite && text.trim().isNotEmpty) {
          requirement.promptNeedsRewrite = false;
          form.touch();
        }
      },
      validator: (text) {
        final length = (text ?? '').trim().length;
        return length < EditorLimits.minVerificationPromptLength
            ? l10n.editorVerifierPromptInvalid
            : null;
      },
    );
  }
}

/// The shortest and longest recording or motion trace, in seconds.
class _DurationFields extends StatelessWidget {
  const _DurationFields({required this.requirement});

  final RequirementForm requirement;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final key = requirement.requirementKey;
    final isMotion = requirement.kind == ProofKind.motion;
    final lowest = isMotion ? 1 : EditorLimits.minRecordingSeconds;
    final highest = isMotion
        ? EditorLimits.maxMotionSeconds
        : EditorLimits.maxRecordingSeconds;
    final message = isMotion
        ? l10n.editorMotionSecondsInvalid(highest)
        : l10n.editorSecondsInvalid;

    bool inRange(int? value) =>
        value != null && value >= lowest && value <= highest;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            key: VerilyTestKeys.editorMinSeconds(key),
            controller: requirement.minSeconds,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: l10n.editorMinSecondsLabel),
            validator: (text) =>
                inRange(int.tryParse(text ?? '')) ? null : message,
          ),
        ),
        const SizedBox(width: editorStackGap),
        Expanded(
          child: TextFormField(
            key: VerilyTestKeys.editorMaxSeconds(key),
            controller: requirement.maxSeconds,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: l10n.editorMaxSecondsLabel),
            validator: (text) {
              final maximum = int.tryParse(text ?? '');
              final minimum = int.tryParse(requirement.minSeconds.text);
              if (!inRange(maximum)) return message;
              if (minimum != null && maximum! < minimum) return message;
              return null;
            },
          ),
        ),
      ],
    );
  }
}

/// The live spoken word, on by default for recordings. Photos cannot carry
/// one, so they never show it.
class _SpokenChallengeRow extends StatelessWidget {
  const _SpokenChallengeRow({required this.form, required this.requirement});

  final EditorForm form;
  final RequirementForm requirement;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: EditorSwitchRow(
        key: VerilyTestKeys.editorSpokenChallenge(requirement.requirementKey),
        label: l10n.editorSpokenChallenge,
        help: l10n.editorSpokenChallengeHelp,
        value: requirement.spokenChallenge,
        onChanged: (value) {
          requirement.spokenChallenge = value;
          form.touch();
        },
      ),
    );
  }
}

/// How strictly a media proof is checked: one careful check or several
/// independent ones, and how sure the check must be to accept on its own.
class _MoreChecks extends HookWidget {
  const _MoreChecks({required this.form, required this.requirement});

  final EditorForm form;
  final RequirementForm requirement;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final open = useState(false);
    final percent = (requirement.minConfidence * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: VerilyTestKeys.editorMoreChecks(requirement.requirementKey),
            onPressed: () => open.value = !open.value,
            icon: AnimatedRotation(
              turns: open.value ? 0.5 : 0,
              duration: const Duration(milliseconds: 150),
              child: const SkribbleIcon(
                data: VerilyIcons.chevronDown,
                size: 18,
              ),
            ),
            label: Text(l10n.editorMoreChecks),
          ),
        ),
        if (open.value) ...[
          const SizedBox(height: 8),
          EditorChoices<ActionVerificationPolicy>(
            label: l10n.editorPolicyLabel,
            values: ActionVerificationPolicy.values,
            selected: requirement.policy,
            nameOf: (policy) => switch (policy) {
              ActionVerificationPolicy.singleModel => l10n.editorPolicySingle,
              ActionVerificationPolicy.modelCouncil => l10n.editorPolicyCouncil,
            },
            onSelected: (policy) {
              requirement.policy = policy;
              form.touch();
            },
          ),
          const SizedBox(height: editorStackGap),
          Text(
            l10n.editorConfidence(percent),
            style: theme.textTheme.labelLarge?.copyWith(color: palette.ink),
          ),
          SizedBox(
            height: 48,
            child: WiredSlider(
              value: requirement.minConfidence.clamp(
                EditorLimits.minConfidenceChoice,
                EditorLimits.maxConfidenceChoice,
              ),
              min: EditorLimits.minConfidenceChoice,
              max: EditorLimits.maxConfidenceChoice,
              divisions: 49,
              semanticLabel: l10n.editorConfidenceSemantic,
              onChanged: (value) {
                requirement.minConfidence = (value * 100).roundToDouble() / 100;
                form.touch();
                return true;
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// Which tracked movement, and how many.
class _MovementFields extends StatelessWidget {
  const _MovementFields({required this.form, required this.requirement});

  final EditorForm form;
  final RequirementForm requirement;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final key = requirement.requirementKey;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorChoices<ActionMovementKind>(
          label: l10n.editorMovementLabel,
          values: ActionMovementKind.values,
          selected: requirement.movementKind,
          nameOf: (kind) => movementName(l10n, kind),
          keyOf: (kind) => VerilyTestKeys.editorMovementKind(key, kind.name),
          onSelected: (kind) {
            requirement.movementKind = kind;
            form.touch();
          },
        ),
        const SizedBox(height: editorStackGap),
        TextFormField(
          key: VerilyTestKeys.editorMovementTarget(key),
          controller: requirement.targetRepetitions,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: l10n.editorMovementTargetLabel,
          ),
          validator: (text) {
            final value = int.tryParse(text ?? '');
            return value == null ||
                    value < 1 ||
                    value > EditorLimits.maxMovementRepetitions
                ? l10n.editorMovementTargetInvalid
                : null;
          },
        ),
      ],
    );
  }
}

/// A movement of the phone itself: the kind, its direction, and how often.
class _MotionFields extends StatelessWidget {
  const _MotionFields({required this.form, required this.requirement});

  final EditorForm form;
  final RequirementForm requirement;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final key = requirement.requirementKey;
    final type = requirement.motionType;
    final counted =
        type == ActionMotionType.rotation || type == ActionMotionType.shake;
    final axes = [
      ActionMotionAxis.yaw,
      ActionMotionAxis.pitch,
      ActionMotionAxis.roll,
      // Counted rotations need one direction; a shake may go any way.
      if (type == ActionMotionType.shake) ActionMotionAxis.any,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorChoices<ActionMotionType>(
          label: l10n.editorMotionTypeLabel,
          values: const [
            ActionMotionType.rotation,
            ActionMotionType.shake,
            ActionMotionType.phoneToss,
            ActionMotionType.stillness,
          ],
          selected: type,
          nameOf: (value) => motionTypeName(l10n, value),
          keyOf: (value) => VerilyTestKeys.editorMotionType(key, value.name),
          onSelected: (value) {
            requirement.setMotionType(value);
            form.touch();
          },
        ),
        if (counted) ...[
          const SizedBox(height: editorStackGap),
          EditorChoices<ActionMotionAxis>(
            label: l10n.editorMotionAxisLabel,
            values: axes,
            selected: requirement.motionAxis,
            nameOf: (axis) => motionAxisName(l10n, axis),
            onSelected: (axis) {
              requirement.motionAxis = axis;
              form.touch();
            },
          ),
          const SizedBox(height: editorStackGap),
          TextFormField(
            key: VerilyTestKeys.editorMotionRepetitions(key),
            controller: requirement.targetRepetitions,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.editorMotionRepetitionsLabel,
            ),
            validator: (text) {
              final value = int.tryParse(text ?? '');
              return value == null ||
                      value < 1 ||
                      value > EditorLimits.maxMotionRepetitions
                  ? l10n.editorMotionRepetitionsInvalid(
                      EditorLimits.maxMotionRepetitions,
                    )
                  : null;
            },
          ),
        ],
        if (type == ActionMotionType.phoneToss) ...[
          const SizedBox(height: editorStackGap),
          EditorNote(
            text: l10n.editorMotionTossSafety,
            icon: VerilyIcons.warning,
          ),
        ],
        const SizedBox(height: editorStackGap),
        _DurationFields(requirement: requirement),
      ],
    );
  }
}

/// One of the creator's active Apps confirms this proof. Participants see
/// "Confirmed by `App`", because Verily does not check the act itself.
class _AppPicker extends ConsumerWidget {
  const _AppPicker({required this.form, required this.requirement});

  final EditorForm form;
  final RequirementForm requirement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final apps = ref.watch(editorActiveAppsProvider);
    final appName = requirement.appName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        switch (apps) {
          AsyncData(:final value) when value.isEmpty => EditorNote(
            text: l10n.editorAppNone,
            icon: VerilyIcons.network,
          ),
          AsyncData(:final value) => EditorChoices<VerilyAppView>(
            label: l10n.editorAppPickerLabel,
            values: value,
            selected: value
                .where((app) => app.id == requirement.appId)
                .firstOrNull,
            nameOf: (app) => app.name,
            keyOf: (app) => VerilyTestKeys.editorAppChoice(
              requirement.requirementKey,
              app.id.uuid,
            ),
            onSelected: (app) {
              requirement
                ..appId = app.id
                ..appName = app.name;
              form.touch();
            },
          ),
          AsyncError() => Row(
            children: [
              Expanded(
                child: Text(
                  l10n.editorAppsFailed,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.ink,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => ref.invalidate(editorActiveAppsProvider),
                child: Text(l10n.dialogRetry),
              ),
            ],
          ),
          _ => Text(
            l10n.editorAppsLoading,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.mutedInk,
            ),
          ),
        },
        if (appName != null && requirement.appId != null) ...[
          const SizedBox(height: editorStackGap),
          EditorNote(
            text: l10n.editorAppTrust(appName),
            icon: VerilyIcons.shieldCheck,
          ),
        ],
        FormField<void>(
          validator: (_) =>
              requirement.appId == null ? l10n.editorAppMissing : null,
          builder: (field) => field.hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    field.errorText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.ink,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
