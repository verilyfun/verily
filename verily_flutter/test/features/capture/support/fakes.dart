import 'dart:async';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/actions/action_repository.dart';
import 'package:verily_flutter/features/capture/audio/capture_recorder.dart';
import 'package:verily_flutter/features/capture/camera/capture_camera.dart';
import 'package:verily_flutter/features/capture/capture_flow.dart';
import 'package:verily_flutter/features/capture/capture_providers.dart';
import 'package:verily_flutter/features/capture/movement/exercise_tracking.dart';
import 'package:verily_flutter/features/capture/movement/movement_capture_controller.dart';
import 'package:verily_flutter/features/capture/movement/movement_tracking_providers.dart';
import 'package:verily_flutter/features/evidence/captured_media.dart';
import 'package:verily_flutter/features/evidence/evidence_service.dart';
import 'package:verily_flutter/features/evidence/motion_capture_service.dart';

/// Fixed ids so assertions can name the attempt and requirement.
final testAttemptId = UuidValue.fromString(
  '00000000-0000-4000-8000-0000000000a1',
);
final testRequirementId = UuidValue.fromString(
  '00000000-0000-4000-8000-0000000000b1',
);

final testAttempt = ActionAttemptView(
  id: testAttemptId,
  actionDefinitionId: UuidValue.fromString(
    '00000000-0000-4000-8000-0000000000c1',
  ),
  periodKey: '2026-10-21',
  status: ActionAttemptStatus.collectingEvidence,
  startedAt: DateTime.utc(2026, 10, 21, 9),
  updatedAt: DateTime.utc(2026, 10, 21, 9),
);

/// A capture requirement with the server's defaults for [kind].
ActionRequirementView testRequirement(
  ActionRequirementKind kind, {
  bool spokenChallengeRequired = false,
  int? minDurationSeconds,
  int? maxDurationSeconds,
  ActionMovementKind? movementKind,
  int? targetRepetitions,
  ActionMotionType? motionType,
  List<String>? acceptedContentTypes,
}) => ActionRequirementView(
  id: testRequirementId,
  requirementKey: 'proof',
  kind: kind,
  title: 'Show the finished mural',
  instructions: 'Film the whole wall from across the street.',
  position: 0,
  isRequired: true,
  spokenChallengeRequired: spokenChallengeRequired,
  minDurationSeconds: minDurationSeconds,
  maxDurationSeconds: maxDurationSeconds,
  movementKind: movementKind,
  targetRepetitions: targetRepetitions,
  motionType: motionType,
  acceptedContentTypes:
      acceptedContentTypes ??
      switch (kind) {
        ActionRequirementKind.photo => const ['image/jpeg', 'image/png'],
        ActionRequirementKind.audio => const ['audio/mp4'],
        _ => const ['video/mp4'],
      },
);

/// A capture held in memory, with a path that does not exist on disk.
XFile memoryCapture(String name, {String? mimeType}) => XFile.fromData(
  Uint8List.fromList(List.generate(64, (index) => index)),
  name: name,
  path: '/verily-test-missing/$name',
  mimeType: mimeType,
);

/// Drives the camera views without hardware.
final class FakeCaptureCamera extends ChangeNotifier implements CaptureCamera {
  FakeCaptureCamera({this.openFailure, this.canFlip = true, this.id = 1});

  /// Which camera this is, in the order a flow opened them.
  final int id;

  /// When set, opening fails this way.
  CaptureCameraFailure? openFailure;
  final bool canFlip;

  CaptureCameraState _state = const CaptureCameraState(
    phase: CaptureCameraPhase.opening,
  );
  int opened = 0;
  int photosTaken = 0;
  int recordingsStarted = 0;
  int recordingsStopped = 0;
  int flips = 0;
  int closes = 0;
  bool disposed = false;

  @override
  CaptureCameraState get state => _state;

  void _emit(CaptureCameraState next) {
    _state = next;
    notifyListeners();
  }

  @override
  Widget? buildPreview() =>
      const SizedBox.expand(key: ValueKey('fake-camera-preview'));

  @override
  Future<void> open() async {
    opened++;
    final failure = openFailure;
    _emit(
      failure == null
          ? CaptureCameraState(
              phase: CaptureCameraPhase.ready,
              canFlip: canFlip,
              previewAspectRatio: 3 / 4,
            )
          : CaptureCameraState(
              phase: CaptureCameraPhase.failed,
              failure: failure,
            ),
    );
  }

  @override
  Future<XFile?> takePhoto() async {
    photosTaken++;
    return memoryCapture('camera$id-photo-$photosTaken.jpg');
  }

  @override
  Future<void> startRecording() async {
    recordingsStarted++;
    _emit(_state.copyWith(phase: CaptureCameraPhase.recording));
  }

  @override
  Future<XFile?> stopRecording() async {
    recordingsStopped++;
    _emit(_state.copyWith(phase: CaptureCameraPhase.ready));
    return memoryCapture('camera$id-clip-$recordingsStopped.mp4');
  }

  @override
  Future<void> flip() async => flips++;

  @override
  Future<void> close() async {
    closes++;
    _emit(const CaptureCameraState(phase: CaptureCameraPhase.opening));
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

/// Drives the audio view without a microphone.
final class FakeCaptureRecorder implements CaptureRecorder {
  FakeCaptureRecorder({this.permission = true});

  bool permission;
  int started = 0;
  int stopped = 0;
  int cancelled = 0;
  bool disposed = false;
  final StreamController<double> _levels = StreamController.broadcast();

  void emitLevel(double value) => _levels.add(value);

  @override
  Future<bool> requestPermission() async => permission;

  @override
  Future<void> start() async => started++;

  @override
  Stream<double> levels() => _levels.stream;

  @override
  Future<XFile?> stop() async {
    stopped++;
    return memoryCapture('voice-$stopped.m4a', mimeType: 'audio/mp4');
  }

  @override
  Future<void> cancel() async => cancelled++;

  @override
  Future<void> dispose() async {
    disposed = true;
    await _levels.close();
  }
}

/// A recording-phase state with live counting at [count].
MovementCaptureState recordingState({required int count}) {
  return MovementCaptureState(
    phase: MovementCapturePhase.recording,
    liveCounting: MovementLiveCounting.active,
    progress: MovementProgress(
      count: count,
      best: count,
      depth: 0.1,
      tracking: true,
      cue: MovementCue.perform,
    ),
  );
}

/// Drives the movement view without camera hardware.
final class FakeMovementCaptureController extends ChangeNotifier
    implements MovementCaptureController {
  FakeMovementCaptureController({this.recordAudio = false});

  final bool recordAudio;
  MovementCaptureState _state = const MovementCaptureState(
    phase: MovementCapturePhase.opening,
  );
  int opened = 0;
  int started = 0;
  int stopped = 0;
  int closed = 0;
  bool disposed = false;

  void emit(MovementCaptureState next) {
    _state = next;
    notifyListeners();
  }

  @override
  MovementCaptureState get state => _state;

  @override
  Widget? buildPreview() => null;

  @override
  Future<void> open() async => opened++;

  @override
  Future<void> startRecording() async {
    started++;
    emit(recordingState(count: 0));
  }

  @override
  Future<MovementRecording?> stopRecording() async {
    stopped++;
    final count = _state.progress.count;
    emit(_state.copyWith(phase: MovementCapturePhase.ready));
    return MovementRecording(
      file: memoryCapture('movement-$stopped.mp4'),
      capturedAt: DateTime.utc(2026, 10, 21, 9, 30),
      repetitions: count,
      trackerVersion: 'pose-lite-v1.squats-v1',
    );
  }

  @override
  Future<void> flipCamera() async {}

  @override
  Future<void> close() async => closed++;

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

/// Serves spoken words, or fails, in order.
final class FakeActionRepository implements ActionRepository {
  FakeActionRepository(this.words);

  /// Each entry is a word to issue, or an exception to throw.
  final List<Object> words;
  final List<UuidValue> requestedFor = [];

  @override
  Future<ActionSpokenChallengeView> issueSpokenChallenge({
    required UuidValue attemptId,
    required UuidValue requirementId,
  }) async {
    requestedFor.add(requirementId);
    return switch (words.removeAt(0)) {
      final String word => ActionSpokenChallengeView(
        id: UuidValue.fromString('00000000-0000-4000-8000-0000000000d1'),
        word: word,
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
      ),
      final Exception error => throw error,
      final other => throw ArgumentError.value(other, 'words'),
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

/// Records what reached the server and answers like it.
final class FakeEvidenceGateway implements EvidenceGateway {
  FakeEvidenceGateway({List<bool>? uploads, this.integrityRequired = false})
    : uploads = uploads ?? [true];

  /// Whether each upload succeeds, in order; the last answer repeats.
  final List<bool> uploads;

  /// Whether the server demands a Play Integrity token; the fake service
  /// never has one.
  final bool integrityRequired;
  final List<String> requestedContentTypes = [];
  final List<CapturedMedia> uploaded = [];
  final List<MediaUploadConfirmation> confirmed = [];
  final List<ActionEvidenceInput> submitted = [];

  late final result = EvidenceSubmissionResult(
    attempt: testAttempt,
    requirementId: testRequirementId,
    reasonCode: 'queued',
    summary: 'Proof received',
  );

  @override
  Future<ActionCaptureChallengeView> createCaptureChallenge({
    required UuidValue attemptId,
    required UuidValue requirementId,
    required String evidenceBindingHash,
  }) async => ActionCaptureChallengeView(
    id: UuidValue.fromString('00000000-0000-4000-8000-0000000000e1'),
    requestHash: 'request-$evidenceBindingHash',
    expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
    integrityRequired: integrityRequired,
    signatureRequired: false,
  );

  @override
  Future<String> requestMediaUpload({
    required UuidValue attemptId,
    required UuidValue requirementId,
    required String contentType,
    required int byteLength,
  }) async {
    requestedContentTypes.add(contentType);
    return 'upload-description';
  }

  @override
  Future<bool> uploadMedia(
    String uploadDescription,
    CapturedMedia media,
  ) async {
    uploaded.add(media);
    return uploads.length > 1 ? uploads.removeAt(0) : uploads.first;
  }

  @override
  Future<EvidenceSubmissionResult> confirmMediaUpload(
    MediaUploadConfirmation confirmation,
  ) async {
    confirmed.add(confirmation);
    return result;
  }

  @override
  Future<EvidenceSubmissionResult> submitEvidence(
    ActionEvidenceInput input,
  ) async {
    submitted.add(input);
    return result;
  }
}

/// An evidence service that never reaches a plugin.
EvidenceService fakeEvidenceService(FakeEvidenceGateway gateway) =>
    EvidenceService(
      gateway: gateway,
      deviceIntegrity: (_) async => null,
      signCapture: ({
        required attemptId,
        required requirementId,
        required requestHash,
        required evidenceBindingHash,
      }) async => null,
    );

/// Everything a capture test replaces, with sensible defaults.
final class CaptureHarness {
  CaptureHarness({
    this.cameraFailure,
    FakeCaptureRecorder? recorder,
    FakeEvidenceGateway? gateway,
    List<Object>? words,
    this.duration = const Duration(seconds: 12),
    this.motion,
    this.trackingSupported = true,
  }) : recorder = recorder ?? FakeCaptureRecorder(),
       gateway = gateway ?? FakeEvidenceGateway(),
       actions = FakeActionRepository(words ?? ['pelican']);

  /// How every camera fails to open, when set.
  final CaptureCameraFailure? cameraFailure;

  /// Every camera the flow opened; a retake opens a fresh one.
  final List<FakeCaptureCamera> cameras = [];
  FakeCaptureCamera get camera => cameras.last;
  final FakeCaptureRecorder recorder;
  final FakeEvidenceGateway gateway;
  final FakeActionRepository actions;

  /// What the container reports for every recording.
  Duration duration;
  final MotionCaptureCallback? motion;
  final bool trackingSupported;

  final List<({bool recordAudio, CaptureLens lens})> cameraRequests = [];
  final List<FakeMovementCaptureController> movementControllers = [];
  int settingsOpened = 0;

  List<Override> get overrides => [
    captureCameraFactoryProvider.overrideWithValue(({
      required recordAudio,
      required initialLens,
    }) {
      cameraRequests.add((recordAudio: recordAudio, lens: initialLens));
      final camera = FakeCaptureCamera(
        openFailure: cameraFailure,
        id: cameras.length + 1,
      );
      cameras.add(camera);
      return camera;
    }),
    captureRecorderFactoryProvider.overrideWithValue(() => recorder),
    mediaDurationProbeProvider.overrideWithValue((_) async => duration),
    capturePreviewBuilderProvider.overrideWithValue(
      (context, media) => SizedBox(
        key: const ValueKey('fake-capture-preview'),
        height: 200,
        child: Center(child: Text(media.contentType)),
      ),
    ),
    openAppSettingsProvider.overrideWithValue(() async => settingsOpened++),
    actionRepositoryProvider.overrideWithValue(actions),
    evidenceServiceProvider.overrideWithValue(fakeEvidenceService(gateway)),
    movementTrackingSupportedProvider.overrideWithValue(trackingSupported),
    movementCaptureControllerFactoryProvider.overrideWithValue((
      kind, {
      required recordAudio,
    }) {
      final controller = FakeMovementCaptureController(
        recordAudio: recordAudio,
      );
      movementControllers.add(controller);
      return controller;
    }),
    if (motion case final callback?)
      motionCaptureCallbackProvider.overrideWithValue(callback),
  ];
}

/// A page with one button that runs [captureEvidence] and keeps the result.
class CaptureLauncher extends StatelessWidget {
  const CaptureLauncher({
    required this.requirement,
    required this.onResult,
    super.key,
  });

  static const openKey = ValueKey<String>('capture-launcher-open');

  final ActionRequirementView requirement;
  final ValueChanged<EvidenceSubmissionResult?> onResult;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        key: openKey,
        onPressed: () async => onResult(
          await captureEvidence(
            context,
            attempt: testAttempt,
            requirement: requirement,
          ),
        ),
        child: const Text('Open capture'),
      ),
    ),
  );
}

/// Taps [CaptureLauncher.openKey] and settles the capture route.
Future<void> openCapture(WidgetTester tester) async {
  await tester.tap(find.byKey(CaptureLauncher.openKey));
  await tester.pumpAndSettle();
}
