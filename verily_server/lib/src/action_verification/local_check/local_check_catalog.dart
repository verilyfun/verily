import 'package:verily_evidence/verily_evidence.dart';
import 'package:verily_server/src/action_verification/action_draft_refusal.dart';
import 'package:verily_server/src/generated/protocol.dart';

export 'package:verily_evidence/verily_evidence.dart'
    show LocalCheckBounds, LocalCheckModel;

/// The pinned model each protocol task runs. The models, their labels, and
/// the bounds live in `package:verily_evidence`, which the app shares, so
/// the editor offers exactly what this server accepts.
extension LocalCheckTaskModel on LocalCheckTask {
  LocalCheckModel get model => switch (this) {
    LocalCheckTask.gesture => LocalCheckModel.gestureRecognizer,
    LocalCheckTask.object => LocalCheckModel.objectDetector,
    LocalCheckTask.sound => LocalCheckModel.audioClassifier,
  };
}

/// What the phone receives to run the same pin.
extension LocalCheckModelViews on LocalCheckModel {
  LocalCheckModelView get view => LocalCheckModelView(
    modelId: modelId,
    url: url,
    byteLength: byteLength,
    sha256: sha256,
  );
}

/// The task that can run on [kind]: sound on audio, gesture and object on
/// photos and video.
bool localCheckFitsKind(LocalCheckTask task, MediaEvidenceKind kind) =>
    task.model.media.contains(kind);

/// Validates a creator's local check for a [kind] proof. Throws
/// [ActionDraftRefusal] with product-safe text, like every authoring rule.
ActionLocalCheck validateLocalCheck(
  ActionLocalCheck check,
  MediaEvidenceKind kind,
) {
  if (!localCheckFitsKind(check.task, kind)) {
    throw ActionDraftRefusal(
      check.task == LocalCheckTask.sound
          ? 'Sound checks need an audio proof.'
          : 'Gesture and object checks need a photo or video proof.',
    );
  }
  if (!check.task.model.labels.contains(check.label)) {
    throw const ActionDraftRefusal(
      'Choose a label from the list for this check.',
    );
  }
  final score = check.minScore;
  if (!score.isFinite ||
      score < LocalCheckBounds.minScore ||
      score > LocalCheckBounds.maxScore) {
    throw const ActionDraftRefusal(
      'Local check scores must be between 0.3 and 0.99.',
    );
  }
  final frames = check.minFrames;
  if (frames < LocalCheckBounds.minFrames ||
      frames > LocalCheckBounds.maxFrames ||
      (kind == MediaEvidenceKind.photo && frames != 1)) {
    throw ActionDraftRefusal(
      kind == MediaEvidenceKind.photo
          ? 'A photo is checked as one frame.'
          : 'Local checks need between 1 and 30 matching frames.',
    );
  }
  return check;
}

/// The server-written verifier text for a local check, used when the AI
/// policy decides (the replay is unavailable, or a word must be heard).
/// Labels come from the allow-list, so no creator text reaches the model.
String localCheckVerificationPrompt(ActionLocalCheck check) {
  final label = check.label.replaceAll('_', ' ').toLowerCase();
  return switch (check.task) {
    LocalCheckTask.gesture =>
      'Verify that a real hand clearly makes the "$label" gesture in this '
          'live capture.',
    LocalCheckTask.object =>
      'Verify that a real $label is clearly visible in this live capture.',
    LocalCheckTask.sound =>
      'Verify that this live recording clearly contains the sound: $label.',
  };
}
