import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/verification_requests/verification_request_service.dart';

/// The Verily app's side of a verification request opened from
/// `https://verily.fun/r/<id>` or `verily://r/<id>`.
///
/// The link carries only the request id; everything shown comes from here,
/// so a forged link can only point at a real request.
class VerificationRequestEndpoint extends Endpoint {
  VerificationRequestEndpoint({VerificationRequestService? service})
    : service = service ?? VerificationRequestService();

  final VerificationRequestService service;

  @override
  bool get requireLogin => true;

  UuidValue _caller(Session session) => session.authenticated!.authUserId;

  /// Who is asking, for what, and exactly what will be shared.
  Future<VerificationRequestView> getRequest(
    Session session, {
    required UuidValue requestId,
  }) {
    return service.getRequest(
      session,
      authUserId: _caller(session),
      requestId: requestId,
    );
  }

  /// Accepts the request. The returned view carries the private action to
  /// capture against with the normal proof flow.
  Future<VerificationRequestView> accept(
    Session session, {
    required UuidValue requestId,
  }) {
    return service.accept(
      session,
      authUserId: _caller(session),
      requestId: requestId,
    );
  }

  /// Declines; the App receives `status=declined`.
  Future<VerificationRequestRedirect> decline(
    Session session, {
    required UuidValue requestId,
  }) {
    return service.decline(
      session,
      authUserId: _caller(session),
      requestId: requestId,
    );
  }

  /// After the proof is submitted: the App's redirect with a one-time,
  /// five-minute receipt code. Refused with
  /// `AppPlatformProblem.verificationRequestProofMissing` while the proof
  /// has not arrived.
  Future<VerificationRequestRedirect> finish(
    Session session, {
    required UuidValue requestId,
  }) {
    return service.finish(
      session,
      authUserId: _caller(session),
      requestId: requestId,
    );
  }
}
