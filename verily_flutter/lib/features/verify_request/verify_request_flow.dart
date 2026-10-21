import 'package:flutter/foundation.dart';
import 'package:uuid/validation.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/core/external_url_launcher.dart';
import 'package:verily_flutter/features/actions/action_repository.dart';
import 'package:verily_flutter/features/evidence/evidence_service.dart';
import 'package:verily_flutter/features/evidence/location_service.dart';
import 'package:verily_flutter/features/verify_request/verification_request_repository.dart';

/// Why a request cannot be answered here.
enum RequestProblem {
  /// No request has this id (or the link was malformed).
  notFound,

  /// The request ran out of time before it was answered.
  expired,

  /// Another account already answered it.
  taken,

  /// This account turned it down.
  declined,

  /// It was answered, declined, or closed already.
  closed,

  /// This account answered many requests from the App recently.
  rateLimited,

  /// The App was revoked or its creator cannot use Verily right now. The
  /// server's own product-safe words come with it.
  appUnavailable,

  /// Anything else, such as no connection. Can be retried.
  generic,
}

/// Something that went wrong with one step, said on the page beside it.
enum ProofNotice {
  locationServicesOff,
  locationDenied,
  locationBlocked,
  locationTimedOut,
  integrityUnavailable,
  signatureUnavailable,
  uploadFailed,

  /// Verily could not confirm the person was inside the App's place (too
  /// far, or the fix was not precise enough).
  placeNotConfirmed,

  /// Verily has not got the proof yet, so there is nothing to return with.
  /// The steps show what it still needs.
  proofMissing,
  generic,
}

/// How a finished request went, as far as the phone knows when it leaves.
enum ProofOutcome { passed, checking, failed }

/// Why the person is being handed back to the App.
enum ReturnReason { finished, declined }

/// Where answering a verification request stands.
sealed class VerifyRequestState {
  const VerifyRequestState();
}

final class VerifyRequestLoading extends VerifyRequestState {
  const VerifyRequestLoading();
}

final class VerifyRequestUnavailable extends VerifyRequestState {
  const VerifyRequestUnavailable(this.problem, {this.appName, this.message});

  final RequestProblem problem;

  /// The App's name, when the request loaded before it closed.
  final String? appName;

  /// The server's own words for [RequestProblem.appUnavailable].
  final String? message;
}

/// Who is asking and for what; nothing is captured until the person agrees.
final class VerifyRequestConsent extends VerifyRequestState {
  const VerifyRequestConsent(this.view, {this.answering, this.problem});

  final VerificationRequestView view;

  /// The answer being sent, while it is outstanding.
  final ReturnReason? answering;

  /// A retryable failure of the last answer.
  final RequestProblem? problem;
}

/// Accepted: the place (when asked) and the live capture, one at a time.
final class VerifyRequestProof extends VerifyRequestState {
  const VerifyRequestProof({
    required this.view,
    required this.action,
    required this.attempt,
    required this.place,
    required this.media,
    this.placeDone = false,
    this.placeSkipped = false,
    this.mediaDone = false,
    this.working = false,
    this.finishing = false,
    this.notice,
  });

  final VerificationRequestView view;
  final ActionOpportunity action;
  final ActionAttemptView attempt;

  /// The location check, when the request has a place.
  final ActionRequirementView? place;

  /// The live capture, absent for a location-only request.
  final ActionRequirementView? media;

  /// The place was sent, or skipped when it was optional.
  final bool placeDone;

  /// The person carried on without sharing their location.
  final bool placeSkipped;
  final bool mediaDone;

  /// A step is running (finding the location, sending it).
  final bool working;

  /// The proof is in and the App's return address is being fetched.
  final bool finishing;

  final ProofNotice? notice;

  /// The person may carry on without their location: the place is a side
  /// check on a media request, never the proof itself.
  bool get placeOptional => place != null && !place!.isRequired;

  /// Every step is done; only the return to the App is left.
  bool get proofIn =>
      (place == null || placeDone) && (media == null || mediaDone);

  VerifyRequestProof copyWith({
    ActionAttemptView? attempt,
    bool? placeDone,
    bool? placeSkipped,
    bool? mediaDone,
    bool? working,
    bool? finishing,
    ProofNotice? notice,
    bool clearNotice = false,
  }) => VerifyRequestProof(
    view: view,
    action: action,
    attempt: attempt ?? this.attempt,
    place: place,
    media: media,
    placeDone: placeDone ?? this.placeDone,
    placeSkipped: placeSkipped ?? this.placeSkipped,
    mediaDone: mediaDone ?? this.mediaDone,
    working: working ?? this.working,
    finishing: finishing ?? this.finishing,
    notice: clearNotice ? null : notice ?? this.notice,
  );
}

/// Handing the person back to the App.
final class VerifyRequestReturning extends VerifyRequestState {
  const VerifyRequestReturning({
    required this.appName,
    required this.redirect,
    required this.reason,
    this.outcome,
    this.opened,
  });

  final String appName;

  /// The App's registered return address with its one-time code or status.
  /// Opened, never shown.
  final Uri redirect;
  final ReturnReason reason;

  /// How the proof went, for [ReturnReason.finished].
  final ProofOutcome? outcome;

  /// Whether the App opened; null while it is being opened.
  final bool? opened;

  VerifyRequestReturning withOpened({required bool opened}) =>
      VerifyRequestReturning(
        appName: appName,
        redirect: redirect,
        reason: reason,
        outcome: outcome,
        opened: opened,
      );
}

/// Captures one requirement live, through the same flow as an action page.
/// Returns null when the person backs out.
typedef RequirementCapture = Future<EvidenceSubmissionResult?> Function(
  ActionAttemptView attempt,
  ActionRequirementView requirement,
);

/// Answers one verification request: consent, the proof, and the way back.
///
/// The link carries only an id, so every word on the page comes from the
/// server. Proof runs on the request's private action with the normal
/// pipeline (capture challenge, device integrity, signature, upload), place
/// first so the receipt can say inside or outside.
class VerifyRequestFlow extends ChangeNotifier {
  VerifyRequestFlow({
    required this.requestId,
    required this._requests,
    required this._actions,
    required this._evidence,
    required this._location,
    required this._openExternal,
  });

  /// The id from the link, unchecked.
  final String requestId;

  final VerificationRequestRepository _requests;
  final ActionRepository _actions;
  final EvidenceService _evidence;
  final LocationService _location;
  final ExternalUrlLauncher _openExternal;

  VerifyRequestState _state = const VerifyRequestLoading();
  VerifyRequestState get state => _state;

  /// How the primary proof went so far, for the words on the way back.
  ProofOutcome _outcome = ProofOutcome.checking;
  bool _disposed = false;

  UuidValue? get _id => UuidValidation.isValidUUIDFormat(fromString: requestId)
      ? UuidValue.fromString(requestId)
      : null;

  void _emit(VerifyRequestState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  /// Loads the request, or picks up an accepted one where it was left.
  Future<void> load() async {
    final id = _id;
    if (id == null) {
      _emit(const VerifyRequestUnavailable(RequestProblem.notFound));
      return;
    }
    _emit(const VerifyRequestLoading());
    try {
      final view = await _requests.get(id);
      await _show(view);
    } on Exception catch (error) {
      _emit(_unavailable(error));
    }
  }

  Future<void> _show(
    VerificationRequestView view, {
    ProofNotice? notice,
  }) async {
    final action = view.action;
    switch (view.status) {
      case VerificationRequestStatus.open:
        _emit(VerifyRequestConsent(view));
      case VerificationRequestStatus.accepted ||
              VerificationRequestStatus.completed
          when action != null:
        await _startProof(view, action, notice: notice);
      case VerificationRequestStatus.accepted ||
          VerificationRequestStatus.completed:
        // Someone else answered it; only their own view carries the action.
        _emit(
          VerifyRequestUnavailable(
            RequestProblem.taken,
            appName: view.appName,
          ),
        );
      case VerificationRequestStatus.expired:
        _emit(
          VerifyRequestUnavailable(
            RequestProblem.expired,
            appName: view.appName,
          ),
        );
      case VerificationRequestStatus.declined:
        // Only the person who turned it down hears that they did; to anyone
        // else it was answered by someone.
        _emit(
          VerifyRequestUnavailable(
            view.declinedByViewer
                ? RequestProblem.declined
                : RequestProblem.taken,
            appName: view.appName,
          ),
        );
    }
  }

  /// Agrees to the request and starts the proof.
  Future<void> accept() async {
    final consent = _state;
    final id = _id;
    if (consent is! VerifyRequestConsent || id == null) return;
    if (consent.answering != null) return;
    _emit(VerifyRequestConsent(consent.view, answering: ReturnReason.finished));
    try {
      final view = await _requests.accept(id);
      final action = view.action;
      if (action == null) {
        // Accepted for this account always carries the private action.
        throw StateError('An accepted request came back without its action.');
      }
      await _startProof(view, action);
    } on Exception catch (error) {
      _consentFailed(consent.view, error);
    }
  }

  /// Turns the request down and hands the person back to the App.
  Future<void> decline() async {
    final current = _state;
    final id = _id;
    if (id == null) return;
    final view = switch (current) {
      VerifyRequestConsent(:final view, answering: null) => view,
      VerifyRequestProof(:final view, working: false, finishing: false)
          when !current.proofIn =>
        view,
      _ => null,
    };
    if (view == null) return;
    if (current is VerifyRequestConsent) {
      _emit(VerifyRequestConsent(view, answering: ReturnReason.declined));
    } else if (current is VerifyRequestProof) {
      _emit(current.copyWith(working: true, clearNotice: true));
    }
    try {
      final redirect = await _requests.decline(id);
      await _return(
        VerifyRequestReturning(
          appName: view.appName,
          redirect: Uri.parse(redirect.redirectUrl),
          reason: ReturnReason.declined,
        ),
      );
    } on Exception catch (error) {
      if (current is VerifyRequestConsent) {
        _consentFailed(view, error);
      } else if (current is VerifyRequestProof) {
        _proofFailed(current, error);
      }
    }
  }

  void _consentFailed(VerificationRequestView view, Exception error) {
    final unavailable = _unavailable(error, appName: view.appName);
    if (unavailable.problem == RequestProblem.generic) {
      _emit(VerifyRequestConsent(view, problem: RequestProblem.generic));
    } else {
      _emit(unavailable);
    }
  }

  Future<void> _startProof(
    VerificationRequestView view,
    ActionOpportunity action, {
    ProofNotice? notice,
  }) async {
    final attempt = action.myAttempt ?? await _actions.beginAttempt(action.id);
    ActionRequirementView? place;
    ActionRequirementView? media;
    for (final requirement in [
      ...action.requirements,
    ]..sort((a, b) => a.position.compareTo(b.position))) {
      switch (requirement.kind) {
        case ActionRequirementKind.location:
          place ??= requirement;
        case ActionRequirementKind.video ||
            ActionRequirementKind.photo ||
            ActionRequirementKind.audio:
          media ??= requirement;
        case ActionRequirementKind.qrCode ||
            ActionRequirementKind.motion ||
            ActionRequirementKind.externalApp:
          // A request's private action holds only a place and a capture.
          break;
      }
    }
    final accepted = {...?attempt.acceptedRequirementIds};
    // Proof already in (an earlier visit) leaves only the way back.
    final submitted = attempt.status != ActionAttemptStatus.collectingEvidence;
    _emit(
      VerifyRequestProof(
        view: view,
        action: action,
        attempt: attempt,
        place: place,
        media: media,
        placeDone: submitted || place == null || accepted.contains(place.id),
        mediaDone: submitted || media == null || accepted.contains(media.id),
        notice: notice,
      ),
    );
  }

  /// Sends one precise location fix for the App's place.
  Future<void> sharePlace() async {
    final proof = _state;
    if (proof is! VerifyRequestProof || proof.working) return;
    final place = proof.place;
    if (place == null || proof.placeDone) return;
    _emit(proof.copyWith(working: true, clearNotice: true));
    try {
      final session = await _evidence.beginCapture(
        attempt: proof.attempt,
        requirement: place,
      );
      final fix = await _location.precisePosition();
      final result = await _evidence.submitLocation(
        attempt: proof.attempt,
        requirement: place,
        session: session,
        fix: fix,
      );
      final rejected = result.status == EvidenceDecisionStatus.rejected;
      final next = proof.copyWith(
        attempt: result.attempt,
        placeDone: true,
        working: false,
        notice: rejected ? ProofNotice.placeNotConfirmed : null,
        clearNotice: !rejected,
      );
      if (proof.media == null) _outcome = _outcomeOf(result);
      _emit(next);
      if (next.proofIn) await finish();
    } on LocationException catch (error) {
      _emit(
        proof.copyWith(
          working: false,
          notice: switch (error.failure) {
            LocationFailure.servicesOff => ProofNotice.locationServicesOff,
            LocationFailure.denied => ProofNotice.locationDenied,
            LocationFailure.deniedForever => ProofNotice.locationBlocked,
            LocationFailure.timedOut => ProofNotice.locationTimedOut,
          },
        ),
      );
    } on Exception catch (error) {
      _proofFailed(proof, error);
    }
  }

  /// Carries on without the location when the place is a side check. The
  /// receipt then says the place was not checked.
  void skipPlace() {
    final proof = _state;
    if (proof is! VerifyRequestProof || !proof.placeOptional) return;
    if (proof.working || proof.placeDone) return;
    _emit(
      proof.copyWith(placeDone: true, placeSkipped: true, clearNotice: true),
    );
  }

  /// Runs the live capture, then hands the person back to the App.
  Future<void> capture(RequirementCapture launch) async {
    final proof = _state;
    if (proof is! VerifyRequestProof || proof.working) return;
    final media = proof.media;
    if (media == null || proof.mediaDone || !proof.placeDone) return;
    _emit(proof.copyWith(working: true, clearNotice: true));
    try {
      final result = await launch(proof.attempt, media);
      if (result == null) {
        _emit(proof.copyWith(working: false));
        return;
      }
      _outcome = _outcomeOf(result);
      final next = proof.copyWith(
        attempt: result.attempt,
        mediaDone: true,
        working: false,
      );
      _emit(next);
      await finish();
    } on CaptureIntegrityException catch (error) {
      _emit(
        proof.copyWith(
          working: false,
          notice: switch (error.failure) {
            CaptureIntegrityFailure.integrityUnavailable =>
              ProofNotice.integrityUnavailable,
            CaptureIntegrityFailure.signatureUnavailable =>
              ProofNotice.signatureUnavailable,
          },
        ),
      );
    } on MediaUploadException {
      _emit(proof.copyWith(working: false, notice: ProofNotice.uploadFailed));
    } on Exception catch (error) {
      _proofFailed(proof, error);
    }
  }

  /// Asks for the App's return address with a one-time receipt code, then
  /// opens it. Safe to call again: each call issues a fresh code.
  Future<void> finish() async {
    final proof = _state;
    final id = _id;
    if (proof is! VerifyRequestProof || !proof.proofIn || id == null) return;
    if (proof.finishing) return;
    _emit(proof.copyWith(finishing: true, clearNotice: true));
    try {
      final redirect = await _requests.finish(id);
      await _return(
        VerifyRequestReturning(
          appName: proof.view.appName,
          redirect: Uri.parse(redirect.redirectUrl),
          reason: ReturnReason.finished,
          outcome: _outcomeFor(proof),
        ),
      );
    } on AppPlatformException catch (error) {
      if (error.problem == AppPlatformProblem.verificationRequestProofMissing) {
        await _resume(id, proof, notice: ProofNotice.proofMissing);
      } else {
        _proofFailed(proof, error);
      }
    } on Exception catch (error) {
      _proofFailed(proof, error);
    }
  }

  /// Picks the steps up from what the server has, for when it disagrees
  /// with this page about which proof is in.
  Future<void> _resume(
    UuidValue id,
    VerifyRequestProof proof, {
    required ProofNotice notice,
  }) async {
    try {
      await _show(await _requests.get(id), notice: notice);
    } on Exception catch (error) {
      _proofFailed(proof, error);
    }
  }

  /// Opens the App again, for when it did not open the first time.
  Future<void> openApp() async {
    final returning = _state;
    if (returning is! VerifyRequestReturning) return;
    await _return(
      VerifyRequestReturning(
        appName: returning.appName,
        redirect: returning.redirect,
        reason: returning.reason,
        outcome: returning.outcome,
      ),
    );
  }

  Future<void> _return(VerifyRequestReturning returning) async {
    _emit(returning);
    final opened = await _openExternal(returning.redirect);
    _emit(returning.withOpened(opened: opened));
  }

  ProofOutcome _outcomeFor(VerifyRequestProof proof) =>
      switch (proof.attempt.status) {
        ActionAttemptStatus.verified => ProofOutcome.passed,
        ActionAttemptStatus.rejected => ProofOutcome.failed,
        _ => _outcome,
      };

  static ProofOutcome _outcomeOf(EvidenceSubmissionResult result) =>
      switch (result.status) {
        EvidenceDecisionStatus.accepted => ProofOutcome.passed,
        EvidenceDecisionStatus.rejected => ProofOutcome.failed,
        EvidenceDecisionStatus.manualReview || null => ProofOutcome.checking,
      };

  void _proofFailed(VerifyRequestProof proof, Exception error) {
    final unavailable = _unavailable(error, appName: proof.view.appName);
    if (unavailable.problem == RequestProblem.generic) {
      _emit(
        proof.copyWith(
          working: false,
          finishing: false,
          notice: ProofNotice.generic,
        ),
      );
    } else {
      _emit(unavailable);
    }
  }

  static VerifyRequestUnavailable _unavailable(
    Exception error, {
    String? appName,
  }) {
    final problem = switch (error) {
      AppPlatformException(:final problem) => switch (problem) {
        AppPlatformProblem.verificationRequestNotFound =>
          RequestProblem.notFound,
        AppPlatformProblem.verificationRequestExpired => RequestProblem.expired,
        AppPlatformProblem.verificationRequestTaken => RequestProblem.taken,
        AppPlatformProblem.verificationRequestClosed => RequestProblem.closed,
        AppPlatformProblem.rateLimited => RequestProblem.rateLimited,
        _ => RequestProblem.generic,
      },
      AppUnavailableException() => RequestProblem.appUnavailable,
      _ => RequestProblem.generic,
    };
    if (problem == RequestProblem.generic) {
      debugPrint('Answering a verification request failed: $error');
    }
    return VerifyRequestUnavailable(
      problem,
      appName: appName,
      message: error is AppUnavailableException ? error.message : null,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
