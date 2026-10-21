import 'package:flutter_test/flutter_test.dart';
import 'package:verily_client/verily_client.dart';
import 'package:verily_evidence/verily_evidence.dart';

import 'package:verily_flutter/features/capture/camera/capture_camera.dart';
import 'package:verily_flutter/features/capture/capture_models.dart';

import 'support/fakes.dart';

void main() {
  group('capturedContentType', () {
    test('maps what the camera and recorder write', () {
      expect(
        capturedContentType(MediaEvidenceKind.video, memoryCapture('a.mp4')),
        'video/mp4',
      );
      expect(
        capturedContentType(MediaEvidenceKind.video, memoryCapture('a.MOV')),
        'video/quicktime',
      );
      expect(
        capturedContentType(MediaEvidenceKind.photo, memoryCapture('a.jpg')),
        'image/jpeg',
      );
      expect(
        capturedContentType(MediaEvidenceKind.audio, memoryCapture('a.m4a')),
        'audio/mp4',
      );
    });

    test('falls back to a known reported type, never an unknown one', () {
      expect(
        capturedContentType(
          MediaEvidenceKind.audio,
          memoryCapture('blob', mimeType: 'audio/webm'),
        ),
        'audio/webm',
      );
      expect(
        capturedContentType(
          MediaEvidenceKind.photo,
          memoryCapture('a.gif', mimeType: 'image/gif'),
        ),
        isNull,
      );
      expect(
        capturedContentType(MediaEvidenceKind.photo, memoryCapture('a.mp4')),
        isNull,
        reason: 'a video is never sent as a photo',
      );
    });
  });

  test('recorded seconds round to whole seconds and are never zero', () {
    expect(recordedSeconds(Duration.zero), 1);
    expect(recordedSeconds(const Duration(milliseconds: 1400)), 1);
    expect(recordedSeconds(const Duration(milliseconds: 1500)), 2);
    expect(recordedSeconds(const Duration(seconds: 59, milliseconds: 300)), 59);
  });

  test('recording bounds follow the requirement with safe defaults', () {
    final open = testRequirement(ActionRequirementKind.video);
    expect(minimumRecording(open), const Duration(seconds: 1));
    expect(maximumRecording(open), const Duration(minutes: 5));

    final bounded = testRequirement(
      ActionRequirementKind.video,
      minDurationSeconds: 0,
      maxDurationSeconds: 30,
    );
    expect(minimumRecording(bounded), const Duration(seconds: 1));
    expect(maximumRecording(bounded), const Duration(seconds: 30));
  });

  group('prepareCapture', () {
    final capturedAt = DateTime.utc(2026, 10, 21, 9, 30);

    test('fingerprints a recording with its container duration', () async {
      final media = await prepareCapture(
        RawCapture(
          file: memoryCapture('clip.mp4'),
          capturedAt: capturedAt,
          measuredDuration: const Duration(seconds: 4),
          repetitions: 8,
          trackerVersion: 'pose-lite-v1.squats-v1',
        ),
        requirement: testRequirement(ActionRequirementKind.video),
        probe: (_) async => const Duration(seconds: 7, milliseconds: 600),
        spokenChallengeWord: 'pelican',
      );

      expect(media.kind, MediaEvidenceKind.video);
      expect(media.contentType, 'video/mp4');
      expect(media.durationSeconds, 8);
      expect(media.byteLength, 64);
      expect(media.sha256Digest, hasLength(64));
      expect(media.capturedAt, capturedAt);
      expect(media.spokenChallengeWord, 'pelican');
      expect(media.deviceRepetitionCount, 8);
      expect(media.deviceTrackerVersion, 'pose-lite-v1.squats-v1');
    });

    test(
      'uses the measured length when the container cannot be read',
      () async {
        final media = await prepareCapture(
          RawCapture(
            file: memoryCapture('voice.m4a'),
            capturedAt: capturedAt,
            measuredDuration: const Duration(seconds: 6),
          ),
          requirement: testRequirement(ActionRequirementKind.audio),
          probe: (_) => throw StateError('no decoder'),
        );

        expect(media.durationSeconds, 6);
        expect(media.contentType, 'audio/mp4');
      },
    );

    test('a photo has no duration and is never probed', () async {
      var probed = false;
      final media = await prepareCapture(
        RawCapture(file: memoryCapture('still.jpg'), capturedAt: capturedAt),
        requirement: testRequirement(ActionRequirementKind.photo),
        probe: (_) async {
          probed = true;
          return const Duration(seconds: 3);
        },
      );

      expect(probed, isFalse);
      expect(media.durationSeconds, 0);
    });

    test('refuses a format the requirement does not accept', () {
      expect(
        prepareCapture(
          RawCapture(file: memoryCapture('clip.mov'), capturedAt: capturedAt),
          requirement: testRequirement(ActionRequirementKind.video),
          probe: (_) async => const Duration(seconds: 3),
        ),
        throwsA(
          isA<CaptureProblemException>().having(
            (error) => error.problem,
            'problem',
            CaptureProblem.unsupportedFormat,
          ),
        ),
      );
    });

    test('refuses a file larger than the requirement takes', () {
      expect(
        prepareCapture(
          RawCapture(file: memoryCapture('clip.mp4'), capturedAt: capturedAt),
          requirement: testRequirement(
            ActionRequirementKind.video,
          ).copyWith(maxByteLength: 32),
          probe: (_) async => const Duration(seconds: 3),
        ),
        throwsA(
          isA<CaptureProblemException>().having(
            (error) => error.problem,
            'problem',
            CaptureProblem.tooLarge,
          ),
        ),
      );
    });
  });

  test('camera error codes map to what the person can do about them', () {
    expect(
      cameraFailureFor('CameraAccessDenied'),
      CaptureCameraFailure.cameraPermissionDenied,
    );
    expect(
      cameraFailureFor('CameraAccessRestricted'),
      CaptureCameraFailure.cameraPermissionDenied,
    );
    expect(
      cameraFailureFor('AudioAccessDeniedWithoutPrompt'),
      CaptureCameraFailure.microphonePermissionDenied,
    );
    expect(
      cameraFailureFor('cameraNotFound'),
      CaptureCameraFailure.unavailable,
    );
  });
}
