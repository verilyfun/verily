import 'package:test/test.dart';
import 'package:verily_evidence/verily_evidence.dart';

void main() {
  group('Given the pinned local-check models', () {
    test('when listed then each is an immutable, distinct pin', () {
      for (final model in LocalCheckModel.values) {
        expect(
          model.url,
          startsWith('https://storage.googleapis.com/mediapipe-models/'),
        );
        expect(model.url, isNot(contains('latest')));
        expect(model.modelId, startsWith('mediapipe/'));
        expect(model.sha256, matches(RegExp(r'^[0-9a-f]{64}$')));
        expect(model.byteLength, greaterThan(1000000));
      }
      expect(
        LocalCheckModel.values.map((model) => model.sha256).toSet(),
        hasLength(LocalCheckModel.values.length),
      );
    });

    test('when matched to proofs then sound runs on audio only', () {
      expect(LocalCheckModel.audioClassifier.media, {MediaEvidenceKind.audio});
      for (final model in [
        LocalCheckModel.gestureRecognizer,
        LocalCheckModel.objectDetector,
      ]) {
        expect(model.media, {MediaEvidenceKind.photo, MediaEvidenceKind.video});
      }
      for (final kind in MediaEvidenceKind.values) {
        expect(
          LocalCheckModel.values.where((model) => model.media.contains(kind)),
          isNotEmpty,
          reason: '${kind.name} has no check',
        );
      }
    });
  });

  group('Given the label allow-lists', () {
    test(
      'when counted then gestures, COCO objects, and sounds are bounded',
      () {
        expect(LocalCheckModel.gestureRecognizer.labels, hasLength(7));
        expect(LocalCheckModel.objectDetector.labels, hasLength(80));
        expect(LocalCheckModel.audioClassifier.labels, hasLength(25));
        expect(
          LocalCheckModel.gestureRecognizer.labels,
          isNot(contains('None')),
        );
        expect(
          LocalCheckModel.audioClassifier.labels,
          isNot(contains('Speech')),
        );
      },
    );

    test('when listed then no label repeats or carries stray spacing', () {
      for (final model in LocalCheckModel.values) {
        expect(
          model.labels.toSet(),
          hasLength(model.labels.length),
          reason: model.name,
        );
        for (final label in model.labels) {
          expect(label, isNotEmpty);
          expect(label.trim(), label, reason: label);
        }
      }
    });
  });

  group('Given the shared bounds', () {
    test('when compared then they form valid ranges', () {
      expect(LocalCheckBounds.minScore, lessThan(LocalCheckBounds.maxScore));
      expect(LocalCheckBounds.maxScore, lessThan(1));
      expect(LocalCheckBounds.minFrames, 1);
      expect(
        LocalCheckBounds.maxFrames,
        greaterThan(LocalCheckBounds.minFrames),
      );
    });
  });
}
