import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/core/api_client.dart';

/// A verification request another App opened Verily with
/// (`verily://r/<id>` or `https://verily.fun/r/<id>`).
///
/// The link carries only the id, so everything shown comes from the server.
abstract interface class VerificationRequestRepository {
  /// Who is asking, for what, and what will be shared.
  Future<VerificationRequestView> get(UuidValue requestId);

  /// Accepts the request; the answer carries the private action to capture
  /// against.
  Future<VerificationRequestView> accept(UuidValue requestId);

  /// Declines; the redirect tells the App `status=declined`.
  Future<VerificationRequestRedirect> decline(UuidValue requestId);

  /// After the proof is in: the App's redirect with a one-time receipt code.
  Future<VerificationRequestRedirect> finish(UuidValue requestId);
}

class ServerpodVerificationRequestRepository
    implements VerificationRequestRepository {
  const ServerpodVerificationRequestRepository(this._client);

  final Client _client;

  @override
  Future<VerificationRequestView> get(UuidValue requestId) =>
      _client.verificationRequest.getRequest(requestId: requestId);

  @override
  Future<VerificationRequestView> accept(UuidValue requestId) =>
      _client.verificationRequest.accept(requestId: requestId);

  @override
  Future<VerificationRequestRedirect> decline(UuidValue requestId) =>
      _client.verificationRequest.decline(requestId: requestId);

  @override
  Future<VerificationRequestRedirect> finish(UuidValue requestId) =>
      _client.verificationRequest.finish(requestId: requestId);
}

final verificationRequestRepositoryProvider =
    Provider<VerificationRequestRepository>(
      (ref) => ServerpodVerificationRequestRepository(
        ref.watch(verilyClientProvider),
      ),
    );
