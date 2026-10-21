import 'package:verily_client/verily_client.dart';
import 'package:verily_evidence/verily_evidence.dart';

import 'package:verily_flutter/l10n/l10n.dart';

/// What a quick check may look or listen for, mirroring the server's
/// allow-list (`local_check_catalog.dart` in `verily_server`).
///
/// Each label is the model's own category name, so the phone, the server's
/// replay, and the editor compare like with like. The server validates every
/// saved check against its own list; this copy only offers the choices and
/// names them. A contract test fails when the two lists drift.
abstract final class LocalCheckBounds {
  static const minScore = 0.3;
  static const maxScore = 0.99;
  static const minFrames = 1;

  /// Also the number of frames the server samples from a video to replay.
  static const maxFrames = 30;
}

/// The task that can run on a proof of [kind]: sound on audio, gesture and
/// object on photos and video.
bool localCheckFitsKind(LocalCheckTask task, MediaEvidenceKind kind) =>
    switch (task) {
      LocalCheckTask.sound => kind == MediaEvidenceKind.audio,
      LocalCheckTask.gesture ||
      LocalCheckTask.object => kind != MediaEvidenceKind.audio,
    };

/// The tasks a proof of [kind] can carry, in the order the editor offers
/// them.
List<LocalCheckTask> localCheckTasksFor(MediaEvidenceKind kind) => [
  for (final task in LocalCheckTask.values)
    if (localCheckFitsKind(task, kind)) task,
];

/// The label a new check of [task] starts with.
String defaultLocalCheckLabel(LocalCheckTask task) => switch (task) {
  LocalCheckTask.gesture => 'Thumb_Up',
  LocalCheckTask.object => 'cup',
  LocalCheckTask.sound => 'Clapping',
};

/// The name people read for [label]. Falls back to the model's own name for
/// a label this build does not know, which only happens if the server adds
/// one before the app is updated.
String localCheckLabelName(
  AppLocalizations l10n,
  LocalCheckTask task,
  String label,
) => knownLocalCheckLabelName(l10n, task, label) ?? label.replaceAll('_', ' ');

/// The translated name of [label], or null when this build has none.
String? knownLocalCheckLabelName(
  AppLocalizations l10n,
  LocalCheckTask task,
  String label,
) => switch (task) {
  LocalCheckTask.gesture => _gestureName(l10n, label),
  LocalCheckTask.object => _objectName(l10n, label),
  LocalCheckTask.sound => _soundName(l10n, label),
};

/// Labels per task, in the server's order.
const Map<LocalCheckTask, List<String>> localCheckLabels = {
  LocalCheckTask.gesture: [
    'Closed_Fist',
    'Open_Palm',
    'Pointing_Up',
    'Thumb_Down',
    'Thumb_Up',
    'Victory',
    'ILoveYou',
  ],
  LocalCheckTask.object: [
    'person',
    'bicycle',
    'car',
    'motorcycle',
    'airplane',
    'bus',
    'train',
    'truck',
    'boat',
    'traffic light',
    'fire hydrant',
    'stop sign',
    'parking meter',
    'bench',
    'bird',
    'cat',
    'dog',
    'horse',
    'sheep',
    'cow',
    'elephant',
    'bear',
    'zebra',
    'giraffe',
    'backpack',
    'umbrella',
    'handbag',
    'tie',
    'suitcase',
    'frisbee',
    'skis',
    'snowboard',
    'sports ball',
    'kite',
    'baseball bat',
    'baseball glove',
    'skateboard',
    'surfboard',
    'tennis racket',
    'bottle',
    'wine glass',
    'cup',
    'fork',
    'knife',
    'spoon',
    'bowl',
    'banana',
    'apple',
    'sandwich',
    'orange',
    'broccoli',
    'carrot',
    'hot dog',
    'pizza',
    'donut',
    'cake',
    'chair',
    'couch',
    'potted plant',
    'bed',
    'dining table',
    'toilet',
    'tv',
    'laptop',
    'mouse',
    'remote',
    'keyboard',
    'cell phone',
    'microwave',
    'oven',
    'toaster',
    'sink',
    'refrigerator',
    'book',
    'clock',
    'vase',
    'scissors',
    'teddy bear',
    'hair drier',
    'toothbrush',
  ],
  LocalCheckTask.sound: [
    'Clapping',
    'Finger snapping',
    'Whistling',
    'Applause',
    'Laughter',
    'Cough',
    'Sneeze',
    'Bell',
    'Doorbell',
    'Knock',
    'Dog',
    'Bark',
    'Cat',
    'Meow',
    'Bird',
    'Chirp, tweet',
    'Crowing, cock-a-doodle-doo',
    'Siren',
    'Alarm clock',
    'Typing',
    'Water tap, faucet',
    'Guitar',
    'Piano',
    'Drum',
    'Whistle',
  ],
};

String? _gestureName(AppLocalizations l10n, String label) => switch (label) {
  'Closed_Fist' => l10n.localCheckGestureClosedFist,
  'Open_Palm' => l10n.localCheckGestureOpenPalm,
  'Pointing_Up' => l10n.localCheckGesturePointingUp,
  'Thumb_Down' => l10n.localCheckGestureThumbDown,
  'Thumb_Up' => l10n.localCheckGestureThumbUp,
  'Victory' => l10n.localCheckGestureVictory,
  'ILoveYou' => l10n.localCheckGestureILoveYou,
  _ => null,
};

String? _objectName(AppLocalizations l10n, String label) => switch (label) {
  'person' => l10n.localCheckObjectPerson,
  'bicycle' => l10n.localCheckObjectBicycle,
  'car' => l10n.localCheckObjectCar,
  'motorcycle' => l10n.localCheckObjectMotorcycle,
  'airplane' => l10n.localCheckObjectAirplane,
  'bus' => l10n.localCheckObjectBus,
  'train' => l10n.localCheckObjectTrain,
  'truck' => l10n.localCheckObjectTruck,
  'boat' => l10n.localCheckObjectBoat,
  'traffic light' => l10n.localCheckObjectTrafficLight,
  'fire hydrant' => l10n.localCheckObjectFireHydrant,
  'stop sign' => l10n.localCheckObjectStopSign,
  'parking meter' => l10n.localCheckObjectParkingMeter,
  'bench' => l10n.localCheckObjectBench,
  'bird' => l10n.localCheckObjectBird,
  'cat' => l10n.localCheckObjectCat,
  'dog' => l10n.localCheckObjectDog,
  'horse' => l10n.localCheckObjectHorse,
  'sheep' => l10n.localCheckObjectSheep,
  'cow' => l10n.localCheckObjectCow,
  'elephant' => l10n.localCheckObjectElephant,
  'bear' => l10n.localCheckObjectBear,
  'zebra' => l10n.localCheckObjectZebra,
  'giraffe' => l10n.localCheckObjectGiraffe,
  'backpack' => l10n.localCheckObjectBackpack,
  'umbrella' => l10n.localCheckObjectUmbrella,
  'handbag' => l10n.localCheckObjectHandbag,
  'tie' => l10n.localCheckObjectTie,
  'suitcase' => l10n.localCheckObjectSuitcase,
  'frisbee' => l10n.localCheckObjectFrisbee,
  'skis' => l10n.localCheckObjectSkis,
  'snowboard' => l10n.localCheckObjectSnowboard,
  'sports ball' => l10n.localCheckObjectSportsBall,
  'kite' => l10n.localCheckObjectKite,
  'baseball bat' => l10n.localCheckObjectBaseballBat,
  'baseball glove' => l10n.localCheckObjectBaseballGlove,
  'skateboard' => l10n.localCheckObjectSkateboard,
  'surfboard' => l10n.localCheckObjectSurfboard,
  'tennis racket' => l10n.localCheckObjectTennisRacket,
  'bottle' => l10n.localCheckObjectBottle,
  'wine glass' => l10n.localCheckObjectWineGlass,
  'cup' => l10n.localCheckObjectCup,
  'fork' => l10n.localCheckObjectFork,
  'knife' => l10n.localCheckObjectKnife,
  'spoon' => l10n.localCheckObjectSpoon,
  'bowl' => l10n.localCheckObjectBowl,
  'banana' => l10n.localCheckObjectBanana,
  'apple' => l10n.localCheckObjectApple,
  'sandwich' => l10n.localCheckObjectSandwich,
  'orange' => l10n.localCheckObjectOrange,
  'broccoli' => l10n.localCheckObjectBroccoli,
  'carrot' => l10n.localCheckObjectCarrot,
  'hot dog' => l10n.localCheckObjectHotDog,
  'pizza' => l10n.localCheckObjectPizza,
  'donut' => l10n.localCheckObjectDonut,
  'cake' => l10n.localCheckObjectCake,
  'chair' => l10n.localCheckObjectChair,
  'couch' => l10n.localCheckObjectCouch,
  'potted plant' => l10n.localCheckObjectPottedPlant,
  'bed' => l10n.localCheckObjectBed,
  'dining table' => l10n.localCheckObjectDiningTable,
  'toilet' => l10n.localCheckObjectToilet,
  'tv' => l10n.localCheckObjectTv,
  'laptop' => l10n.localCheckObjectLaptop,
  'mouse' => l10n.localCheckObjectMouse,
  'remote' => l10n.localCheckObjectRemote,
  'keyboard' => l10n.localCheckObjectKeyboard,
  'cell phone' => l10n.localCheckObjectCellPhone,
  'microwave' => l10n.localCheckObjectMicrowave,
  'oven' => l10n.localCheckObjectOven,
  'toaster' => l10n.localCheckObjectToaster,
  'sink' => l10n.localCheckObjectSink,
  'refrigerator' => l10n.localCheckObjectRefrigerator,
  'book' => l10n.localCheckObjectBook,
  'clock' => l10n.localCheckObjectClock,
  'vase' => l10n.localCheckObjectVase,
  'scissors' => l10n.localCheckObjectScissors,
  'teddy bear' => l10n.localCheckObjectTeddyBear,
  'hair drier' => l10n.localCheckObjectHairDrier,
  'toothbrush' => l10n.localCheckObjectToothbrush,
  _ => null,
};

String? _soundName(AppLocalizations l10n, String label) => switch (label) {
  'Clapping' => l10n.localCheckSoundClapping,
  'Finger snapping' => l10n.localCheckSoundFingerSnapping,
  'Whistling' => l10n.localCheckSoundWhistling,
  'Applause' => l10n.localCheckSoundApplause,
  'Laughter' => l10n.localCheckSoundLaughter,
  'Cough' => l10n.localCheckSoundCough,
  'Sneeze' => l10n.localCheckSoundSneeze,
  'Bell' => l10n.localCheckSoundBell,
  'Doorbell' => l10n.localCheckSoundDoorbell,
  'Knock' => l10n.localCheckSoundKnock,
  'Dog' => l10n.localCheckSoundDog,
  'Bark' => l10n.localCheckSoundBark,
  'Cat' => l10n.localCheckSoundCat,
  'Meow' => l10n.localCheckSoundMeow,
  'Bird' => l10n.localCheckSoundBird,
  'Chirp, tweet' => l10n.localCheckSoundChirpTweet,
  'Crowing, cock-a-doodle-doo' => l10n.localCheckSoundCrowingCockADoodleDoo,
  'Siren' => l10n.localCheckSoundSiren,
  'Alarm clock' => l10n.localCheckSoundAlarmClock,
  'Typing' => l10n.localCheckSoundTyping,
  'Water tap, faucet' => l10n.localCheckSoundWaterTapFaucet,
  'Guitar' => l10n.localCheckSoundGuitar,
  'Piano' => l10n.localCheckSoundPiano,
  'Drum' => l10n.localCheckSoundDrum,
  'Whistle' => l10n.localCheckSoundWhistle,
  _ => null,
};
