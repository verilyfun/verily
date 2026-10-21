/// When everything in Verily's launch reel happens.
///
/// The reel draws from these times and the render tool scores its sound bed
/// from the same ones, so a stamp always thunks on the frame it lands. This
/// file has no Flutter dependency so the command-line tool can read it.
library;

import 'package:verily_brand/src/stamp_motion.dart';

/// A stretch of the reel, in seconds.
final class PromoCue {
  /// From [start] to [end] seconds.
  const PromoCue(this.start, this.end);

  /// When it begins.
  final double start;

  /// When it is over.
  final double end;

  /// How long it lasts.
  double get length => end - start;

  /// The time [fraction] of the way through.
  double at(double fraction) => start + length * fraction;
}

/// The reel's script, scene by scene.
abstract final class PromoTimeline {
  /// The reel's length in seconds.
  static const double duration = 30;

  /// Frames per second the reel is rendered at.
  static const int fps = 30;

  // -- Hook: "Pics, or it didn't happen." ------------------------------------

  /// The hook scene.
  static const PromoCue hook = PromoCue(0, 3.55);

  /// "Pics, or it didn't happen." writes itself on.
  static const PromoCue hookWrite = PromoCue(0.25, 1.45);

  /// The vermilion pen strikes through "didn't".
  static const PromoCue strike = PromoCue(1.55, 1.9);

  /// The pin-check draws in one stroke, then ✓erily writes on.
  static const PromoCue hookLockup = PromoCue(2, 3.25);

  // -- Create: post an action -------------------------------------------------

  /// The create scene.
  static const PromoCue create = PromoCue(3.45, 9.1);

  /// The phone slides into the frame and stays until the end card.
  static const PromoCue phone = PromoCue(3.45, 27.15);

  /// "Post an action" writes on.
  static const PromoCue createHeadline = PromoCue(3.7, 4.3);

  /// The action card pops onto the phone.
  static const double actionCard = 4.35;

  /// The pin drops onto the bandstand.
  static const PromoCue pinDrop = PromoCue(4.95, 5.6);

  /// The hatched radius circle draws round the pin.
  static const PromoCue radius = PromoCue(5.35, 6.15);

  /// The reward chip pops onto the card.
  static const double rewardChip = 6.3;

  /// Coins leave the chip for the escrow jar, one after another.
  static const List<double> coinDrops = [6.75, 7.1, 7.45];

  /// How long a coin takes to fall into the jar.
  static const double coinFall = 0.45;

  /// The lid comes down on the jar.
  static const PromoCue lid = PromoCue(8, 8.25);

  /// The padlock snaps shut.
  static const double lockSnap = 8.45;

  // -- Do: live, in the place -------------------------------------------------

  /// The do scene.
  static const PromoCue doIt = PromoCue(9.05, 17.1);

  /// "Do it, live." writes on.
  static const PromoCue doHeadline = PromoCue(9.25, 9.85);

  /// When the first squat starts.
  static const double repsStart = 9.8;

  /// How long each squat takes.
  static const double repPeriod = 0.6;

  /// How many squats are counted.
  static const int reps = 10;

  /// The live challenge pops up: "Say: pelican".
  static const double challenge = 10.9;

  /// The participant says the word.
  static const PromoCue spoken = PromoCue(12, 13.6);

  // -- Prove: checked, signed, sealed ----------------------------------------

  /// The prove scene.
  static const PromoCue prove = PromoCue(17.05, 23.1);

  /// "Prove it." writes on.
  static const PromoCue proveHeadline = PromoCue(17.25, 17.75);

  /// Each line of the proof checklist ticks.
  static const List<double> ticks = [17.95, 18.5, 19.05, 19.6, 20.15];

  /// A faint hatch sweeps the clip and vanishes: the invisible seal.
  static const PromoCue seal = PromoCue(20.75, 21.95);

  /// "Sealed. Invisibly." is noted beside the clip.
  static const double sealNote = 21.5;

  // -- Paid: the stamp and the payout ----------------------------------------

  /// The paid scene.
  static const PromoCue paid = PromoCue(23.05, 27.2);

  /// "Get paid." writes on.
  static const PromoCue paidHeadline = PromoCue(23.2, 23.7);

  /// The verified stamp's slam. It meets the paper half way through.
  static const PromoCue stamp = PromoCue(23.5, 24.3);

  /// The moment the stamp lands.
  static double get stampImpact => stamp.at(StampMotion.impact);

  /// A coin flies from the jar to the participant.
  static const PromoCue payout = PromoCue(24.55, 25.45);

  // -- End card ---------------------------------------------------------------

  /// The end card.
  static const PromoCue end = PromoCue(27, duration);

  /// The lockup draws itself.
  static const PromoCue endLockup = PromoCue(27.25, 28.45);

  /// "Do it. Prove it. Get paid." appears.
  static const double tagline = 28.35;

  /// "verily.fun" appears, underlined.
  static const double url = 28.85;

  // -- Derived cues for the sound bed ----------------------------------------

  /// When each squat bottoms out and comes back up: the count goes up then.
  static List<double> get repTimes => [
    for (var i = 1; i <= reps; i++) repsStart + repPeriod * i,
  ];

  /// When each coin lands in the jar.
  static List<double> get coinLandings => [
    for (final drop in coinDrops) drop + coinFall,
  ];

  /// Every stretch in which a pen is writing or drawing on screen.
  static List<PromoCue> get pencilWork => [
    hookWrite,
    PromoCue(hookLockup.start, hookLockup.end),
    createHeadline,
    doHeadline,
    proveHeadline,
    paidHeadline,
    PromoCue(endLockup.start, endLockup.end),
  ];

  /// Small pops: things appearing with a little bounce.
  static List<double> get pops => [
    actionCard,
    rewardChip,
    challenge,
    spoken.start,
    sealNote,
    tagline,
  ];
}
