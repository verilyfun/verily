/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: no_leading_underscores_for_local_identifiers

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _ida;
import 'dart:io' as _idi;

import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_test/serverpod_test.dart' as _ist;
import 'package:verily_server/src/generated/action_verification/action_attempt_view.dart'
    as _iyvinv8z;
import 'package:verily_server/src/generated/action_verification/action_capture_challenge_cleanup_task.dart'
    as _issjjjw3;
import 'package:verily_server/src/generated/action_verification/action_capture_challenge_view.dart'
    as _ithqbtu4;
import 'package:verily_server/src/generated/action_verification/action_draft_proposal.dart'
    as _i932ylyd;
import 'package:verily_server/src/generated/action_verification/action_evidence_input.dart'
    as _iwt0swaj;
import 'package:verily_server/src/generated/action_verification/action_opportunity.dart'
    as _iryxm23q;
import 'package:verily_server/src/generated/action_verification/action_qr_challenge_cleanup_task.dart'
    as _iyeohdwe;
import 'package:verily_server/src/generated/action_verification/action_qr_challenge_view.dart'
    as _iw4on576;
import 'package:verily_server/src/generated/action_verification/action_spoken_challenge_cleanup_task.dart'
    as _i7i84atq;
import 'package:verily_server/src/generated/action_verification/action_spoken_challenge_view.dart'
    as _i1u8vy1l;
import 'package:verily_server/src/generated/action_verification/action_template.dart'
    as _icxixoim;
import 'package:verily_server/src/generated/action_verification/create_action_definition_request.dart'
    as _iknf9wff;
import 'package:verily_server/src/generated/action_verification/evidence_appeal_status.dart'
    as _iae6saoz;
import 'package:verily_server/src/generated/action_verification/evidence_appeal_view.dart'
    as _igl29vg6;
import 'package:verily_server/src/generated/action_verification/evidence_decision_status.dart'
    as _i4x5kh6m;
import 'package:verily_server/src/generated/action_verification/evidence_review_queue_item.dart'
    as _ioe3uq94;
import 'package:verily_server/src/generated/action_verification/evidence_submission_result.dart'
    as _ixjvyqsc;
import 'package:verily_server/src/generated/action_verification/evidence_verification_recovery_task.dart'
    as _ikmo5pl9;
import 'package:verily_server/src/generated/action_verification/evidence_verification_task.dart'
    as _ip06q9f7;
import 'package:verily_server/src/generated/action_verification/media_upload_confirmation.dart'
    as _iihlm2mq;
import 'package:verily_server/src/generated/apps/app_confirmation_view.dart'
    as _i8j33595;
import 'package:verily_server/src/generated/apps/verily_app_credential.dart'
    as _ifzrjeai;
import 'package:verily_server/src/generated/apps/verily_app_link_view.dart'
    as _i08pulje;
import 'package:verily_server/src/generated/apps/verily_app_view.dart'
    as _i4dty38s;
import 'package:verily_server/src/generated/evidence_storage/evidence_upload_cleanup_task.dart'
    as _ivz1brjg;
import 'package:verily_server/src/generated/future_calls.dart' as _ic0hj7xj;
import 'package:verily_server/src/generated/moderation/moderation_case_review_view.dart'
    as _it6tmf5n;
import 'package:verily_server/src/generated/moderation/moderation_case_status_view.dart'
    as _ikb2aklq;
import 'package:verily_server/src/generated/rewards/payout_wallet_challenge_cleanup_task.dart'
    as _iqy68f9e;
import 'package:verily_server/src/generated/rewards/payout_wallet_link_challenge_view.dart'
    as _i1ljxbmf;
import 'package:verily_server/src/generated/rewards/payout_wallet_view.dart'
    as _iohn262x;
import 'package:verily_server/src/generated/rewards/reward_end_plan.dart'
    as _igale6pk;
import 'package:verily_server/src/generated/rewards/reward_funding_plan.dart'
    as _i038aocj;
import 'package:verily_server/src/generated/rewards/reward_payout_recovery_task.dart'
    as _iii6pmpe;
import 'package:verily_server/src/generated/rewards/reward_payout_task.dart'
    as _iiiev0wf;
import 'package:verily_server/src/generated/rewards/reward_payout_view.dart'
    as _ijh2di3d;
import 'package:verily_server/src/generated/rewards/reward_pool_view.dart'
    as _ig5ctw47;
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/generated/endpoints.dart';
export 'package:serverpod_test/serverpod_test_public_exports.dart';

/// Creates a new test group that takes a callback that can be used to write tests.
/// The callback has two parameters: `sessionBuilder` and `endpoints`.
/// `sessionBuilder` is used to build a `Session` object that represents the server state during an endpoint call and is used to set up scenarios.
/// `endpoints` contains all your Serverpod endpoints and lets you call them:
/// ```dart
/// withServerpod('Given Example endpoint', (sessionBuilder, endpoints) {
///   test('when calling `hello` then should return greeting', () async {
///     final greeting = await endpoints.example.hello(sessionBuilder, 'Michael');
///     expect(greeting, 'Hello Michael');
///   });
/// });
/// ```
///
/// **Configuration options**
///
/// [applyMigrations] Whether pending migrations should be applied when starting Serverpod. Defaults to `true`
///
/// [enableSessionLogging] Whether session logging should be enabled. Defaults to `false`
///
/// [ephemeralDatabase] Whether this group gets its own empty database, created when the group starts and dropped when it finishes. Defaults to `true`.
/// Set this to `false` to use the database configured for [runMode], including a previously seeded database. [configOverride] can still replace that database. The configured database is not created or dropped, so groups that share it cannot run in parallel. [rollbackDatabase] still controls whether writes inside the group are rolled back.
///
/// [rollbackDatabase] Options for when to rollback the database during the test lifecycle.
/// By default `withServerpod` does all database operations inside a transaction that is rolled back after each `test` case.
/// Just like the following enum describes, the behavior of the automatic rollbacks can be configured:
/// ```dart
/// /// Options for when to rollback the database during the test lifecycle.
/// enum RollbackDatabase {
///   /// After each test. This is the default.
///   afterEach,
///
///   /// After all tests.
///   afterAll,
///
///   /// Disable rolling back the database.
///   disabled,
/// }
/// ```
///
/// [runMode] The run mode that Serverpod should be running in. Defaults to `test`.
///
/// [serverpodLoggingMode] The logging mode used when creating Serverpod. Defaults to `ServerpodLoggingMode.normal`
///
/// [serverpodStartTimeout] The timeout to use when starting Serverpod, which connects to the database among other things. Defaults to `Duration(seconds: 120)`.
///
/// [testServerOutputMode] Options for controlling test server output during test execution. Defaults to `TestServerOutputMode.normal`.
/// ```dart
/// /// Options for controlling test server output during test execution.
/// enum TestServerOutputMode {
///   /// Default mode - only stderr is printed (stdout suppressed).
///   /// This hides normal startup/shutdown logs while preserving error messages.
///   normal,
///
///   /// All logging - both stdout and stderr are printed.
///   /// Useful for debugging when you need to see all server output.
///   verbose,
///
///   /// No logging - both stdout and stderr are suppressed.
///   /// Completely silent mode, useful when you don't want any server output.
///   silent,
/// }
/// ```
///
/// [configOverride] A function to override the server configuration. This function is called with
/// the default server configuration after it is loaded from the config/ directory
/// and before it is used to start the server. Use this to override particular
/// settings in the server configuration.
///
/// [databaseInterceptor] Optional interceptor that replaces the default database for each session.
/// See [Serverpod.databaseInterceptor] for more information.
///
/// [testGroupTagsOverride] By default Serverpod test tools tags the `withServerpod` test group with `"integration"`.
/// This is to provide a simple way to only run unit or integration tests.
/// This property allows this tag to be overridden to something else. Defaults to `['integration']`.
///
/// [experimentalFeatures] Optionally specify experimental features. See [Serverpod] for more information.
///
/// [serverDirectory] The server package directory `config/<runMode>.yaml`, `config/passwords.yaml`,
/// and `migrations/<module>/...` are resolved against. Defaults to
/// [Directory.current] at the time the test boots. Pass this when the test
/// isolate's cwd is not the server package root (e.g. running tests from a
/// workspace parent directory) so config and migrations are still loaded
/// from the right place.
@_ist.isTestGroup
void withServerpod(
  String testGroupName,
  _ist.TestClosure<TestEndpoints> testClosure, {
  bool? applyMigrations,
  _is.ServerpodConfig Function(_is.ServerpodConfig)? configOverride,
  _is.DatabaseInterceptor? databaseInterceptor,
  bool? enableSessionLogging,
  bool? ephemeralDatabase,
  _is.ExperimentalFeatures? experimentalFeatures,
  _ist.RollbackDatabase? rollbackDatabase,
  String? runMode,
  _is.RuntimeParametersListBuilder? runtimeParametersBuilder,
  _idi.Directory? serverDirectory,
  _is.ServerpodLoggingMode? serverpodLoggingMode,
  Duration? serverpodStartTimeout,
  List<String>? testGroupTagsOverride,
  _ist.TestServerOutputMode? testServerOutputMode,
}) {
  _ist.buildWithServerpod<_InternalTestEndpoints>(
    testGroupName,
    _ist.TestServerpod(
      testEndpoints: _InternalTestEndpoints(),
      endpoints: Endpoints(),
      serializationManager: Protocol(),
      runMode: runMode,
      applyMigrations: applyMigrations,
      ephemeralDatabase: ephemeralDatabase,
      isDatabaseEnabled: true,
      serverpodLoggingMode: serverpodLoggingMode,
      testServerOutputMode: testServerOutputMode,
      serverDirectory: serverDirectory,
      experimentalFeatures: experimentalFeatures,
      configOverride: configOverride,
      runtimeParametersBuilder: runtimeParametersBuilder,
      databaseInterceptor: databaseInterceptor,
    ),
    maybeRollbackDatabase: rollbackDatabase,
    maybeEnableSessionLogging: enableSessionLogging,
    maybeTestGroupTagsOverride: testGroupTagsOverride,
    maybeServerpodStartTimeout: serverpodStartTimeout,
    maybeTestServerOutputMode: testServerOutputMode,
  )(testClosure);
}

class TestEndpoints {
  late final futureCalls = _FutureCalls();

  late final _AccountLifecycleEndpoint accountLifecycle;

  late final _ActionVerificationEndpoint actionVerification;

  late final _EvidenceAppealEndpoint evidenceAppeal;

  late final _EvidenceReviewEndpoint evidenceReview;

  late final _VerilyAppEndpoint verilyApp;

  late final _EmailIdpEndpoint emailIdp;

  late final _GoogleIdpEndpoint googleIdp;

  late final _JwtRefreshEndpoint jwtRefresh;

  late final _ModerationEndpoint moderation;

  late final _ModerationReviewEndpoint moderationReview;

  late final _PayoutWalletEndpoint payoutWallet;

  late final _RewardsEndpoint rewards;
}

class _InternalTestEndpoints extends TestEndpoints
    implements _ist.InternalTestEndpoints {
  @override
  void initialize(
    _is.SerializationManager serializationManager,
    _is.EndpointDispatch endpoints,
  ) {
    accountLifecycle = _AccountLifecycleEndpoint(
      endpoints,
      serializationManager,
    );
    actionVerification = _ActionVerificationEndpoint(
      endpoints,
      serializationManager,
    );
    evidenceAppeal = _EvidenceAppealEndpoint(
      endpoints,
      serializationManager,
    );
    evidenceReview = _EvidenceReviewEndpoint(
      endpoints,
      serializationManager,
    );
    verilyApp = _VerilyAppEndpoint(
      endpoints,
      serializationManager,
    );
    emailIdp = _EmailIdpEndpoint(
      endpoints,
      serializationManager,
    );
    googleIdp = _GoogleIdpEndpoint(
      endpoints,
      serializationManager,
    );
    jwtRefresh = _JwtRefreshEndpoint(
      endpoints,
      serializationManager,
    );
    moderation = _ModerationEndpoint(
      endpoints,
      serializationManager,
    );
    moderationReview = _ModerationReviewEndpoint(
      endpoints,
      serializationManager,
    );
    payoutWallet = _PayoutWalletEndpoint(
      endpoints,
      serializationManager,
    );
    rewards = _RewardsEndpoint(
      endpoints,
      serializationManager,
    );
  }
}

class _FutureCalls {
  late final actionCaptureChallengeCleanup =
      _ActionCaptureChallengeCleanupFutureCall();

  late final actionQrChallengeCleanup = _ActionQrChallengeCleanupFutureCall();

  late final actionSpokenChallengeCleanup =
      _ActionSpokenChallengeCleanupFutureCall();

  late final evidenceVerification = _EvidenceVerificationFutureCall();

  late final evidenceVerificationRecovery =
      _EvidenceVerificationRecoveryFutureCall();

  late final evidenceUploadCleanup = _EvidenceUploadCleanupFutureCall();

  late final payoutWalletChallengeCleanup =
      _PayoutWalletChallengeCleanupFutureCall();

  late final rewardPayout = _RewardPayoutFutureCall();

  late final rewardPayoutRecovery = _RewardPayoutRecoveryFutureCall();
}

class _AccountLifecycleEndpoint {
  _AccountLifecycleEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<DateTime> closeAccount(
    _ist.TestSessionBuilder sessionBuilder, {
    required String confirmation,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'accountLifecycle',
            method: 'closeAccount',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'accountLifecycle',
          methodName: 'closeAccount',
          parameters: _ist.testObjectToJson({'confirmation': confirmation}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<DateTime>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _ActionVerificationEndpoint {
  _ActionVerificationEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<List<_icxixoim.ActionTemplate>> listTemplates(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'actionVerification',
            method: 'listTemplates',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'actionVerification',
          methodName: 'listTemplates',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<List<_icxixoim.ActionTemplate>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i932ylyd.ActionDraftProposal> draftActionFromPrompt(
    _ist.TestSessionBuilder sessionBuilder, {
    required String prompt,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'actionVerification',
            method: 'draftActionFromPrompt',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'actionVerification',
          methodName: 'draftActionFromPrompt',
          parameters: _ist.testObjectToJson({'prompt': prompt}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_i932ylyd.ActionDraftProposal>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iryxm23q.ActionOpportunity> createAction(
    _ist.TestSessionBuilder sessionBuilder,
    _iknf9wff.CreateActionDefinitionRequest request,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'actionVerification',
            method: 'createAction',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'actionVerification',
          methodName: 'createAction',
          parameters: _ist.testObjectToJson({'request': request}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_iryxm23q.ActionOpportunity>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iryxm23q.ActionOpportunity> saveActionDraft(
    _ist.TestSessionBuilder sessionBuilder,
    _iknf9wff.CreateActionDefinitionRequest request,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'actionVerification',
            method: 'saveActionDraft',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'actionVerification',
          methodName: 'saveActionDraft',
          parameters: _ist.testObjectToJson({'request': request}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_iryxm23q.ActionOpportunity>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iryxm23q.ActionOpportunity> previewAction(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue actionId,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'actionVerification',
            method: 'previewAction',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'actionVerification',
          methodName: 'previewAction',
          parameters: _ist.testObjectToJson({'actionId': actionId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_iryxm23q.ActionOpportunity>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_iryxm23q.ActionOpportunity>> listOwnedActions(
    _ist.TestSessionBuilder sessionBuilder, {
    required int limit,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'actionVerification',
            method: 'listOwnedActions',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'actionVerification',
          methodName: 'listOwnedActions',
          parameters: _ist.testObjectToJson({'limit': limit}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<List<_iryxm23q.ActionOpportunity>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iryxm23q.ActionOpportunity> publishAction(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue actionId,
    required int expectedRevision,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'actionVerification',
            method: 'publishAction',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'actionVerification',
          methodName: 'publishAction',
          parameters: _ist.testObjectToJson({
            'actionId': actionId,
            'expectedRevision': expectedRevision,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_iryxm23q.ActionOpportunity>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iryxm23q.ActionOpportunity> pauseAction(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue actionId,
    required int expectedRevision,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'actionVerification',
            method: 'pauseAction',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'actionVerification',
          methodName: 'pauseAction',
          parameters: _ist.testObjectToJson({
            'actionId': actionId,
            'expectedRevision': expectedRevision,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_iryxm23q.ActionOpportunity>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iw4on576.ActionQrChallengeView> createQrChallenge(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue requirementId,
    required int validitySeconds,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'actionVerification',
            method: 'createQrChallenge',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'actionVerification',
          methodName: 'createQrChallenge',
          parameters: _ist.testObjectToJson({
            'requirementId': requirementId,
            'validitySeconds': validitySeconds,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_iw4on576.ActionQrChallengeView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_iryxm23q.ActionOpportunity>> listAvailableActions(
    _ist.TestSessionBuilder sessionBuilder, {
    required int limit,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'actionVerification',
            method: 'listAvailableActions',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'actionVerification',
          methodName: 'listAvailableActions',
          parameters: _ist.testObjectToJson({'limit': limit}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<List<_iryxm23q.ActionOpportunity>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_iryxm23q.ActionOpportunity>> listNearbyActions(
    _ist.TestSessionBuilder sessionBuilder, {
    required double latitude,
    required double longitude,
    required double radiusKm,
    required int limit,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'actionVerification',
            method: 'listNearbyActions',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'actionVerification',
          methodName: 'listNearbyActions',
          parameters: _ist.testObjectToJson({
            'latitude': latitude,
            'longitude': longitude,
            'radiusKm': radiusKm,
            'limit': limit,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<List<_iryxm23q.ActionOpportunity>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iyvinv8z.ActionAttemptView> beginAttempt(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue actionId,
    required String idempotencyKey,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'actionVerification',
            method: 'beginAttempt',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'actionVerification',
          methodName: 'beginAttempt',
          parameters: _ist.testObjectToJson({
            'actionId': actionId,
            'idempotencyKey': idempotencyKey,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_iyvinv8z.ActionAttemptView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i1u8vy1l.ActionSpokenChallengeView> issueSpokenChallenge(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue attemptId,
    required _is.UuidValue requirementId,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'actionVerification',
            method: 'issueSpokenChallenge',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'actionVerification',
          methodName: 'issueSpokenChallenge',
          parameters: _ist.testObjectToJson({
            'attemptId': attemptId,
            'requirementId': requirementId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_i1u8vy1l.ActionSpokenChallengeView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ithqbtu4.ActionCaptureChallengeView> createCaptureChallenge(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue attemptId,
    required _is.UuidValue requirementId,
    required String evidenceBindingHash,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'actionVerification',
            method: 'createCaptureChallenge',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'actionVerification',
          methodName: 'createCaptureChallenge',
          parameters: _ist.testObjectToJson({
            'attemptId': attemptId,
            'requirementId': requirementId,
            'evidenceBindingHash': evidenceBindingHash,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_ithqbtu4.ActionCaptureChallengeView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ixjvyqsc.EvidenceSubmissionResult> submitEvidence(
    _ist.TestSessionBuilder sessionBuilder,
    _iwt0swaj.ActionEvidenceInput input,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'actionVerification',
            method: 'submitEvidence',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'actionVerification',
          methodName: 'submitEvidence',
          parameters: _ist.testObjectToJson({'input': input}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_ixjvyqsc.EvidenceSubmissionResult>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<String> requestMediaUpload(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue attemptId,
    required _is.UuidValue requirementId,
    required String contentType,
    required int byteLength,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'actionVerification',
            method: 'requestMediaUpload',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'actionVerification',
          methodName: 'requestMediaUpload',
          parameters: _ist.testObjectToJson({
            'attemptId': attemptId,
            'requirementId': requirementId,
            'contentType': contentType,
            'byteLength': byteLength,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ixjvyqsc.EvidenceSubmissionResult> confirmMediaUpload(
    _ist.TestSessionBuilder sessionBuilder,
    _iihlm2mq.MediaUploadConfirmation confirmation,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'actionVerification',
            method: 'confirmMediaUpload',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'actionVerification',
          methodName: 'confirmMediaUpload',
          parameters: _ist.testObjectToJson({'confirmation': confirmation}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_ixjvyqsc.EvidenceSubmissionResult>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iyvinv8z.ActionAttemptView> completeAttempt(
    _ist.TestSessionBuilder sessionBuilder,
    _is.UuidValue attemptId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'actionVerification',
            method: 'completeAttempt',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'actionVerification',
          methodName: 'completeAttempt',
          parameters: _ist.testObjectToJson({'attemptId': attemptId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_iyvinv8z.ActionAttemptView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_iyvinv8z.ActionAttemptView>> listMyAttempts(
    _ist.TestSessionBuilder sessionBuilder, {
    required int limit,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'actionVerification',
            method: 'listMyAttempts',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'actionVerification',
          methodName: 'listMyAttempts',
          parameters: _ist.testObjectToJson({'limit': limit}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<List<_iyvinv8z.ActionAttemptView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _EvidenceAppealEndpoint {
  _EvidenceAppealEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_igl29vg6.EvidenceAppealView> submit(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue attemptId,
    required String reason,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'evidenceAppeal',
            method: 'submit',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'evidenceAppeal',
          methodName: 'submit',
          parameters: _ist.testObjectToJson({
            'attemptId': attemptId,
            'reason': reason,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_igl29vg6.EvidenceAppealView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_igl29vg6.EvidenceAppealView?> getMine(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue attemptId,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'evidenceAppeal',
            method: 'getMine',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'evidenceAppeal',
          methodName: 'getMine',
          parameters: _ist.testObjectToJson({'attemptId': attemptId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_igl29vg6.EvidenceAppealView?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_igl29vg6.EvidenceAppealView>> listOwned(
    _ist.TestSessionBuilder sessionBuilder, {
    required int limit,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'evidenceAppeal',
            method: 'listOwned',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'evidenceAppeal',
          methodName: 'listOwned',
          parameters: _ist.testObjectToJson({'limit': limit}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<List<_igl29vg6.EvidenceAppealView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_igl29vg6.EvidenceAppealView> resolve(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue appealId,
    required _iae6saoz.EvidenceAppealStatus decision,
    required String note,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'evidenceAppeal',
            method: 'resolve',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'evidenceAppeal',
          methodName: 'resolve',
          parameters: _ist.testObjectToJson({
            'appealId': appealId,
            'decision': decision,
            'note': note,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_igl29vg6.EvidenceAppealView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _EvidenceReviewEndpoint {
  _EvidenceReviewEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<List<_ioe3uq94.EvidenceReviewQueueItem>> listQueue(
    _ist.TestSessionBuilder sessionBuilder, {
    required int limit,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'evidenceReview',
            method: 'listQueue',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'evidenceReview',
          methodName: 'listQueue',
          parameters: _ist.testObjectToJson({'limit': limit}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<List<_ioe3uq94.EvidenceReviewQueueItem>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iyvinv8z.ActionAttemptView> review(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue evidenceId,
    required _i4x5kh6m.EvidenceDecisionStatus decision,
    required String note,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'evidenceReview',
            method: 'review',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'evidenceReview',
          methodName: 'review',
          parameters: _ist.testObjectToJson({
            'evidenceId': evidenceId,
            'decision': decision,
            'note': note,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_iyvinv8z.ActionAttemptView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _VerilyAppEndpoint {
  _VerilyAppEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<List<_i4dty38s.VerilyAppView>> listApps(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'verilyApp',
            method: 'listApps',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'verilyApp',
          methodName: 'listApps',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<List<_i4dty38s.VerilyAppView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ifzrjeai.VerilyAppCredential> createApp(
    _ist.TestSessionBuilder sessionBuilder, {
    required String name,
    String? websiteUrl,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'verilyApp',
            method: 'createApp',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'verilyApp',
          methodName: 'createApp',
          parameters: _ist.testObjectToJson({
            'name': name,
            'websiteUrl': websiteUrl,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_ifzrjeai.VerilyAppCredential>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ifzrjeai.VerilyAppCredential> createKey(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue appId,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'verilyApp',
            method: 'createKey',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'verilyApp',
          methodName: 'createKey',
          parameters: _ist.testObjectToJson({'appId': appId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_ifzrjeai.VerilyAppCredential>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i4dty38s.VerilyAppView> revokeKey(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue appId,
    required String keyId,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'verilyApp',
            method: 'revokeKey',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'verilyApp',
          methodName: 'revokeKey',
          parameters: _ist.testObjectToJson({
            'appId': appId,
            'keyId': keyId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_i4dty38s.VerilyAppView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i4dty38s.VerilyAppView> revokeApp(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue appId,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'verilyApp',
            method: 'revokeApp',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'verilyApp',
          methodName: 'revokeApp',
          parameters: _ist.testObjectToJson({'appId': appId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_i4dty38s.VerilyAppView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_i8j33595.AppConfirmationView>> listConfirmations(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue appId,
    required int limit,
    _is.UuidValue? beforeId,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'verilyApp',
            method: 'listConfirmations',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'verilyApp',
          methodName: 'listConfirmations',
          parameters: _ist.testObjectToJson({
            'appId': appId,
            'limit': limit,
            'beforeId': beforeId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<List<_i8j33595.AppConfirmationView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i08pulje.VerilyAppLinkView> linkApp(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue appId,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'verilyApp',
            method: 'linkApp',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'verilyApp',
          methodName: 'linkApp',
          parameters: _ist.testObjectToJson({'appId': appId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_i08pulje.VerilyAppLinkView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _EmailIdpEndpoint {
  _EmailIdpEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_iacs.AuthSuccess> login(
    _ist.TestSessionBuilder sessionBuilder, {
    required String email,
    required String password,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'login',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'login',
          parameters: _ist.testObjectToJson({
            'email': email,
            'password': password,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_iacs.AuthSuccess>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_is.UuidValue> startRegistration(
    _ist.TestSessionBuilder sessionBuilder, {
    required String email,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'startRegistration',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'startRegistration',
          parameters: _ist.testObjectToJson({'email': email}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_is.UuidValue>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<String> verifyRegistrationCode(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue accountRequestId,
    required String verificationCode,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'verifyRegistrationCode',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'verifyRegistrationCode',
          parameters: _ist.testObjectToJson({
            'accountRequestId': accountRequestId,
            'verificationCode': verificationCode,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iacs.AuthSuccess> finishRegistration(
    _ist.TestSessionBuilder sessionBuilder, {
    required String registrationToken,
    required String password,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'finishRegistration',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'finishRegistration',
          parameters: _ist.testObjectToJson({
            'registrationToken': registrationToken,
            'password': password,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_iacs.AuthSuccess>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_is.UuidValue> startPasswordReset(
    _ist.TestSessionBuilder sessionBuilder, {
    required String email,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'startPasswordReset',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'startPasswordReset',
          parameters: _ist.testObjectToJson({'email': email}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_is.UuidValue>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<String> verifyPasswordResetCode(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'verifyPasswordResetCode',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'verifyPasswordResetCode',
          parameters: _ist.testObjectToJson({
            'passwordResetRequestId': passwordResetRequestId,
            'verificationCode': verificationCode,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> finishPasswordReset(
    _ist.TestSessionBuilder sessionBuilder, {
    required String finishPasswordResetToken,
    required String newPassword,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'finishPasswordReset',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'finishPasswordReset',
          parameters: _ist.testObjectToJson({
            'finishPasswordResetToken': finishPasswordResetToken,
            'newPassword': newPassword,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<bool> hasAccount(_ist.TestSessionBuilder sessionBuilder) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'hasAccount',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'hasAccount',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<bool>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _GoogleIdpEndpoint {
  _GoogleIdpEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_iacs.AuthSuccess> login(
    _ist.TestSessionBuilder sessionBuilder, {
    required String idToken,
    required String? accessToken,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'googleIdp',
            method: 'login',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'googleIdp',
          methodName: 'login',
          parameters: _ist.testObjectToJson({
            'idToken': idToken,
            'accessToken': accessToken,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_iacs.AuthSuccess>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iacs.AuthSuccess> loginWithCode(
    _ist.TestSessionBuilder sessionBuilder, {
    required String code,
    required String codeVerifier,
    required String redirectUri,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'googleIdp',
            method: 'loginWithCode',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'googleIdp',
          methodName: 'loginWithCode',
          parameters: _ist.testObjectToJson({
            'code': code,
            'codeVerifier': codeVerifier,
            'redirectUri': redirectUri,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_iacs.AuthSuccess>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<bool> hasAccount(_ist.TestSessionBuilder sessionBuilder) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'googleIdp',
            method: 'hasAccount',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'googleIdp',
          methodName: 'hasAccount',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<bool>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _JwtRefreshEndpoint {
  _JwtRefreshEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_iacs.AuthSuccess> refreshAccessToken(
    _ist.TestSessionBuilder sessionBuilder, {
    String? refreshToken,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'jwtRefresh',
            method: 'refreshAccessToken',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'jwtRefresh',
          methodName: 'refreshAccessToken',
          parameters: _ist.testObjectToJson({'refreshToken': refreshToken}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_iacs.AuthSuccess>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _ModerationEndpoint {
  _ModerationEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_ikb2aklq.ModerationCaseStatusView> report(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue actionDefinitionId,
    required String category,
    required String details,
    required String idempotencyKey,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'moderation',
            method: 'report',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'moderation',
          methodName: 'report',
          parameters: _ist.testObjectToJson({
            'actionDefinitionId': actionDefinitionId,
            'category': category,
            'details': details,
            'idempotencyKey': idempotencyKey,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_ikb2aklq.ModerationCaseStatusView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ikb2aklq.ModerationCaseStatusView> getStatus(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue caseId,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'moderation',
            method: 'getStatus',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'moderation',
          methodName: 'getStatus',
          parameters: _ist.testObjectToJson({'caseId': caseId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_ikb2aklq.ModerationCaseStatusView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_ikb2aklq.ModerationCaseStatusView>> listMine(
    _ist.TestSessionBuilder sessionBuilder, {
    required int limit,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'moderation',
            method: 'listMine',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'moderation',
          methodName: 'listMine',
          parameters: _ist.testObjectToJson({'limit': limit}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<List<_ikb2aklq.ModerationCaseStatusView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ikb2aklq.ModerationCaseStatusView> appeal(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue caseId,
    required String reason,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'moderation',
            method: 'appeal',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'moderation',
          methodName: 'appeal',
          parameters: _ist.testObjectToJson({
            'caseId': caseId,
            'reason': reason,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_ikb2aklq.ModerationCaseStatusView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _ModerationReviewEndpoint {
  _ModerationReviewEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<List<_ikb2aklq.ModerationCaseStatusView>> listQueue(
    _ist.TestSessionBuilder sessionBuilder, {
    required int limit,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'moderationReview',
            method: 'listQueue',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'moderationReview',
          methodName: 'listQueue',
          parameters: _ist.testObjectToJson({'limit': limit}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<List<_ikb2aklq.ModerationCaseStatusView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_it6tmf5n.ModerationCaseReviewView> getCase(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue caseId,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'moderationReview',
            method: 'getCase',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'moderationReview',
          methodName: 'getCase',
          parameters: _ist.testObjectToJson({'caseId': caseId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_it6tmf5n.ModerationCaseReviewView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ikb2aklq.ModerationCaseStatusView> review(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue caseId,
    required String decision,
    required String note,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'moderationReview',
            method: 'review',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'moderationReview',
          methodName: 'review',
          parameters: _ist.testObjectToJson({
            'caseId': caseId,
            'decision': decision,
            'note': note,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_ikb2aklq.ModerationCaseStatusView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ikb2aklq.ModerationCaseStatusView> resolveAppeal(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue caseId,
    required String decision,
    required String note,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'moderationReview',
            method: 'resolveAppeal',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'moderationReview',
          methodName: 'resolveAppeal',
          parameters: _ist.testObjectToJson({
            'caseId': caseId,
            'decision': decision,
            'note': note,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_ikb2aklq.ModerationCaseStatusView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _PayoutWalletEndpoint {
  _PayoutWalletEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_iohn262x.PayoutWalletView?> getMine(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'payoutWallet',
            method: 'getMine',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'payoutWallet',
          methodName: 'getMine',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_iohn262x.PayoutWalletView?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i1ljxbmf.PayoutWalletLinkChallengeView>
  createWalletLinkChallenge(
    _ist.TestSessionBuilder sessionBuilder, {
    required String walletAddress,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'payoutWallet',
            method: 'createWalletLinkChallenge',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'payoutWallet',
          methodName: 'createWalletLinkChallenge',
          parameters: _ist.testObjectToJson({'walletAddress': walletAddress}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_i1ljxbmf.PayoutWalletLinkChallengeView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iohn262x.PayoutWalletView> linkPayoutWallet(
    _ist.TestSessionBuilder sessionBuilder, {
    required String walletAddress,
    required String nonce,
    required String signature,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'payoutWallet',
            method: 'linkPayoutWallet',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'payoutWallet',
          methodName: 'linkPayoutWallet',
          parameters: _ist.testObjectToJson({
            'walletAddress': walletAddress,
            'nonce': nonce,
            'signature': signature,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_iohn262x.PayoutWalletView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _RewardsEndpoint {
  _RewardsEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_ig5ctw47.RewardPoolView?> getRewardPool(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue actionId,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'rewards',
            method: 'getRewardPool',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'rewards',
          methodName: 'getRewardPool',
          parameters: _ist.testObjectToJson({'actionId': actionId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_ig5ctw47.RewardPoolView?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i038aocj.RewardFundingPlan> prepareRewardFunding(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue actionId,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'rewards',
            method: 'prepareRewardFunding',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'rewards',
          methodName: 'prepareRewardFunding',
          parameters: _ist.testObjectToJson({'actionId': actionId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_i038aocj.RewardFundingPlan>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ig5ctw47.RewardPoolView> confirmRewardFunding(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue actionId,
    required String signature,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'rewards',
            method: 'confirmRewardFunding',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'rewards',
          methodName: 'confirmRewardFunding',
          parameters: _ist.testObjectToJson({
            'actionId': actionId,
            'signature': signature,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_ig5ctw47.RewardPoolView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_igale6pk.RewardEndPlan> endRewardEarly(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue actionId,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'rewards',
            method: 'endRewardEarly',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'rewards',
          methodName: 'endRewardEarly',
          parameters: _ist.testObjectToJson({'actionId': actionId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<_igale6pk.RewardEndPlan>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_ijh2di3d.RewardPayoutView>> listMyPayouts(
    _ist.TestSessionBuilder sessionBuilder, {
    required int limit,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'rewards',
            method: 'listMyPayouts',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'rewards',
          methodName: 'listMyPayouts',
          parameters: _ist.testObjectToJson({'limit': limit}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _ida.Future<List<_ijh2di3d.RewardPayoutView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _ActionCaptureChallengeCleanupFutureCall {
  Future<void> cleanup(
    _ist.TestSessionBuilder sessionBuilder,
    _issjjjw3.ActionCaptureChallengeCleanupTask task,
  ) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _ic0hj7xj.ActionCaptureChallengeCleanupCleanupFutureCall().invoke(
        _localUniqueSession,
        task,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }
}

class _ActionQrChallengeCleanupFutureCall {
  Future<void> cleanup(
    _ist.TestSessionBuilder sessionBuilder,
    _iyeohdwe.ActionQrChallengeCleanupTask task,
  ) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _ic0hj7xj.ActionQrChallengeCleanupCleanupFutureCall().invoke(
        _localUniqueSession,
        task,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }
}

class _ActionSpokenChallengeCleanupFutureCall {
  Future<void> cleanup(
    _ist.TestSessionBuilder sessionBuilder,
    _i7i84atq.ActionSpokenChallengeCleanupTask task,
  ) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _ic0hj7xj.ActionSpokenChallengeCleanupCleanupFutureCall().invoke(
        _localUniqueSession,
        task,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }
}

class _EvidenceVerificationFutureCall {
  Future<void> verify(
    _ist.TestSessionBuilder sessionBuilder,
    _ip06q9f7.EvidenceVerificationTask task,
  ) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _ic0hj7xj.EvidenceVerificationVerifyFutureCall().invoke(
        _localUniqueSession,
        task,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }
}

class _EvidenceVerificationRecoveryFutureCall {
  Future<void> recover(
    _ist.TestSessionBuilder sessionBuilder,
    _ikmo5pl9.EvidenceVerificationRecoveryTask task,
  ) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _ic0hj7xj.EvidenceVerificationRecoveryRecoverFutureCall().invoke(
        _localUniqueSession,
        task,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }
}

class _EvidenceUploadCleanupFutureCall {
  Future<void> cleanup(
    _ist.TestSessionBuilder sessionBuilder,
    _ivz1brjg.EvidenceUploadCleanupTask task,
  ) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _ic0hj7xj.EvidenceUploadCleanupCleanupFutureCall().invoke(
        _localUniqueSession,
        task,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }
}

class _PayoutWalletChallengeCleanupFutureCall {
  Future<void> cleanup(
    _ist.TestSessionBuilder sessionBuilder,
    _iqy68f9e.PayoutWalletChallengeCleanupTask task,
  ) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _ic0hj7xj.PayoutWalletChallengeCleanupCleanupFutureCall().invoke(
        _localUniqueSession,
        task,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }
}

class _RewardPayoutFutureCall {
  Future<void> release(
    _ist.TestSessionBuilder sessionBuilder,
    _iiiev0wf.RewardPayoutTask task,
  ) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _ic0hj7xj.RewardPayoutReleaseFutureCall().invoke(
        _localUniqueSession,
        task,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }
}

class _RewardPayoutRecoveryFutureCall {
  Future<void> recover(
    _ist.TestSessionBuilder sessionBuilder,
    _iii6pmpe.RewardPayoutRecoveryTask task,
  ) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _ic0hj7xj.RewardPayoutRecoveryRecoverFutureCall().invoke(
        _localUniqueSession,
        task,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }
}
