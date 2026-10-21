import 'dart:io';

import 'package:test/test.dart';
import 'package:verily_evidence/verily_evidence.dart';
import 'package:verily_server/src/action_verification/local_check/local_check_catalog.dart';
import 'package:verily_server/src/action_verification/model_input_security.dart';
import 'package:verily_server/src/generated/protocol.dart';

ActionLocalCheck _check({
  LocalCheckTask task = LocalCheckTask.gesture,
  String label = 'Thumb_Up',
  double minScore = 0.6,
  int minFrames = 1,
}) => ActionLocalCheck(
  task: task,
  label: label,
  minScore: minScore,
  minFrames: minFrames,
);

void main() {
  group('Given the pinned local-check models', () {
    test('when mapped then each task runs its own shared pin', () {
      expect(
        LocalCheckTask.values.map((task) => task.model),
        unorderedEquals(LocalCheckModel.values),
      );
      expect(
        localCheckFitsKind(LocalCheckTask.sound, MediaEvidenceKind.audio),
        isTrue,
      );
      expect(
        localCheckFitsKind(LocalCheckTask.gesture, MediaEvidenceKind.audio),
        isFalse,
      );
      expect(
        localCheckFitsKind(LocalCheckTask.object, MediaEvidenceKind.photo),
        isTrue,
      );
    });

    test('when the image is built then it bakes exactly these pins', () {
      final dockerfile = File('Dockerfile').readAsStringSync();

      for (final model in LocalCheckModel.values) {
        expect(dockerfile, contains('--output '));
        expect(dockerfile, contains(model.url));
      }
      expect(
        dockerfile,
        contains('VERILY_LOCAL_CHECK_MODEL_CACHE=/app/local-check-models'),
      );
    });

    test('when shown to the phone then the view carries the same pin', () {
      final model = LocalCheckTask.object.model;
      final view = model.view;

      expect(view.modelId, model.modelId);
      expect(view.url, model.url);
      expect(view.sha256, model.sha256);
      expect(view.byteLength, model.byteLength);
    });
  });

  group('Given the label allow-lists', () {
    test('when used as verifier text then every label is safe model input', () {
      for (final task in LocalCheckTask.values) {
        for (final label in task.model.labels) {
          final prompt = localCheckVerificationPrompt(
            _check(task: task, label: label),
          );
          expect(
            () => ModelInputSecurity.validateVerificationPolicy(prompt),
            returnsNormally,
            reason: label,
          );
          expect(prompt, isNot(contains('_')));
        }
      }
    });
  });

  group('Given a creator local check', () {
    test('when it fits its media kind then it is accepted unchanged', () {
      final check = _check(minScore: 0.3, minFrames: 30);

      expect(validateLocalCheck(check, MediaEvidenceKind.video), same(check));
      expect(
        validateLocalCheck(
          _check(task: LocalCheckTask.sound, label: 'Clapping', minScore: 0.99),
          MediaEvidenceKind.audio,
        ).label,
        'Clapping',
      );
      expect(
        validateLocalCheck(
          _check(task: LocalCheckTask.object, label: 'sports ball'),
          MediaEvidenceKind.photo,
        ).task,
        LocalCheckTask.object,
      );
    });

    test('when the task does not fit the media kind then it is refused', () {
      expect(
        () => validateLocalCheck(
          _check(task: LocalCheckTask.sound, label: 'Clapping'),
          MediaEvidenceKind.video,
        ),
        throwsArgumentError,
      );
      expect(
        () => validateLocalCheck(_check(), MediaEvidenceKind.audio),
        throwsArgumentError,
      );
    });

    test('when the label is not on the task allow-list then it is refused', () {
      for (final label in ['thumb_up', 'Speech', 'dog', '', 'Thumb_Up ']) {
        expect(
          () =>
              validateLocalCheck(_check(label: label), MediaEvidenceKind.photo),
          throwsArgumentError,
          reason: label,
        );
      }
    });

    test('when the score is outside 0.3 to 0.99 then it is refused', () {
      for (final score in [0.29, 1.0, double.nan, double.infinity, -1.0]) {
        expect(
          () => validateLocalCheck(
            _check(minScore: score),
            MediaEvidenceKind.video,
          ),
          throwsArgumentError,
          reason: '$score',
        );
      }
    });

    test('when the frame count is out of range then it is refused', () {
      for (final frames in [0, 31, -1]) {
        expect(
          () => validateLocalCheck(
            _check(minFrames: frames),
            MediaEvidenceKind.video,
          ),
          throwsArgumentError,
          reason: '$frames',
        );
      }
      expect(
        () => validateLocalCheck(_check(minFrames: 2), MediaEvidenceKind.photo),
        throwsArgumentError,
      );
    });
  });
}
