import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/verification_requests/verification_request_service.dart';

const verificationRequestExpiryIdentifier = 'verification-request-expiry';

/// Recurring sweep that expires verification requests past their deadline
/// and delivers their final `verification_request.completed` event.
/// See [VerificationRequestService.expireDue].
class VerificationRequestExpiryFutureCall
    extends FutureCall<VerificationRequestExpiryTask> {
  Future<void> expire(Session session, VerificationRequestExpiryTask task) {
    return VerificationRequestService().expireDue(
      session,
      batchSize: task.batchSize,
    );
  }
}
