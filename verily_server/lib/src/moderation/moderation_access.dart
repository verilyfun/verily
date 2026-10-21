import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:verily_server/src/moderation/moderation_policy.dart';

const moderationReviewScope = Scope(ModerationPolicy.reviewScope);

/// Uses the authenticated session rather than accepting an actor from the wire.
UuidValue requireGovernanceAccount(Session session) {
  final authentication = session.authenticated;

  if (authentication == null) {
    throw StateError('Sign in to continue.');
  }

  return authentication.authUserId;
}

/// Rechecks scope inside services, including direct internal invocations.
UuidValue requireModerationStaff(Session session) {
  final authentication = session.authenticated;
  ModerationPolicy.requireStaff(
    authenticated: authentication != null,
    scopes: {
      for (final scope in authentication?.scopes ?? <Scope>{})
        if (scope.name != null) scope.name!,
    },
  );

  return requireGovernanceAccount(session);
}
