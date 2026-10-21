import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/generated/protocol.dart';
import 'package:verily_server/src/moderation/moderation_gate.dart';
import 'package:verily_server/src/moderation/moderation_policy.dart';

import 'test_tools/serverpod_test_tools.dart';
import 'test_tools/verily_fixtures.dart';

const _details = 'The action asks people to climb an electricity pylon.';

void main() {
  withServerpod('Given a creator-owned action anyone can report', (
    sessionBuilder,
    endpoints,
  ) {
    final creatorId = testId(601);
    final reporterId = testId(602);
    final participantId = testId(603);
    final staffId = testId(604);
    final secondStaffId = testId(605);
    late TestSessionBuilder creator;
    late TestSessionBuilder reporter;
    late TestSessionBuilder participant;
    late TestSessionBuilder staff;
    late TestSessionBuilder secondStaff;
    late ActionOpportunity action;

    setUp(() async {
      creator = signedIn(sessionBuilder, creatorId);
      reporter = signedIn(sessionBuilder, reporterId);
      participant = signedIn(sessionBuilder, participantId);
      staff = signedIn(
        sessionBuilder,
        staffId,
        scopes: {ModerationPolicy.reviewScope},
      );
      secondStaff = signedIn(
        sessionBuilder,
        secondStaffId,
        scopes: {ModerationPolicy.reviewScope},
      );
      final session = sessionBuilder.build();
      registerLocalEvidenceStorage(session);
      await insertAccounts(session, {
        creatorId: 'Ada',
        reporterId: 'Grace',
        participantId: 'Linus',
        staffId: 'Rita',
        secondStaffId: 'Sam',
      });
      action = await publishedAction(
        endpoints,
        creator,
        actionRequest(
          actionKey: 'reported-action',
          requirements: [
            mediaRequirement(
              kind: ActionRequirementKind.video,
              spokenChallengeRequired: false,
            ),
          ],
        ),
      );
    });

    Future<ModerationCaseStatusView> report({
      String category = 'dangerousActivity',
      String key = 'report-1',
      String details = _details,
      UuidValue? actionId,
      TestSessionBuilder? as,
    }) => endpoints.moderation.report(
      as ?? reporter,
      actionDefinitionId: actionId ?? action.id,
      category: category,
      details: details,
      idempotencyKey: key,
    );

    Future<ActionAttemptView> begin({String key = 'attempt'}) =>
        endpoints.actionVerification.beginAttempt(
          participant,
          actionId: action.id,
          idempotencyKey: key,
        );

    Future<bool> isPaused(UuidValue actionId) {
      final session = sessionBuilder.build();
      return DatabaseUtil.runInTransactionOrSavepoint(
        session.db,
        null,
        (transaction) => const ModerationGate().isActionPaused(
          session,
          actionId: actionId,
          transaction: transaction,
        ),
      );
    }

    group('when a low-risk report arrives', () {
      test(
        'then a case waits for a person without holding the action',
        () async {
          final status = await report(category: 'spam');

          expect(status.status, 'pendingReview');
          expect(status.pauseActive, isFalse);
          expect(status.canAppeal, isFalse);
          expect(await isPaused(action.id), isFalse);
          final row = await ModerationCase.db.findById(
            sessionBuilder.build(),
            status.caseId,
          );
          expect(row!.creatorAuthUserId, creatorId);
          expect(row.reporterAuthUserId, reporterId);
          await expectLater(begin(), completes);
        },
      );
    });

    group('when a high-risk report arrives', () {
      test('then the action is held and new proof is refused', () async {
        final attempt = await begin(key: 'before-hold');

        final status = await report();

        expect(status.pauseActive, isTrue);
        await expectLater(begin(key: 'after-hold'), throwsStateError);
        await expectLater(
          endpoints.actionVerification.requestMediaUpload(
            participant,
            attemptId: attempt.id,
            requirementId: action.requirements.single.id,
            contentType: 'video/mp4',
            byteLength: MediaFixtures.mp4Video().length,
          ),
          throwsStateError,
        );
        await expectLater(
          endpoints.actionVerification.completeAttempt(
            participant,
            attempt.id,
          ),
          throwsStateError,
        );
        // Nothing is deleted while people review the report.
        expect(
          await ActionDefinition.db.findById(sessionBuilder.build(), action.id),
          isNotNull,
        );
      });

      test('then discovery stops listing only the held action', () async {
        final place = await publishedAction(
          endpoints,
          creator,
          actionRequest(
            actionKey: 'held-place',
            requirements: [locationRequirement()],
          ),
        );
        Future<Set<UuidValue>> available() async => {
          for (final listed
              in await endpoints.actionVerification.listAvailableActions(
                participant,
                limit: 50,
              ))
            listed.id,
        };
        Future<Set<UuidValue>> nearby() async => {
          for (final listed
              in await endpoints.actionVerification.listNearbyActions(
                participant,
                latitude: 51.5007,
                longitude: -0.1246,
                radiusKm: 5,
                limit: 10,
              ))
            listed.id,
        };
        expect(await available(), containsAll([action.id, place.id]));
        expect(await nearby(), {place.id});

        await report(actionId: place.id, key: 'report-place');

        expect(await available(), {action.id});
        expect(await nearby(), isEmpty);
      });

      test(
        "then the hold covers new revisions but not the creator's other "
        'actions',
        () async {
          await report();
          final revision = await endpoints.actionVerification.saveActionDraft(
            creator,
            actionRequest(
              actionKey: 'reported-action',
              title: 'A safer version',
              requirements: [
                mediaRequirement(
                  kind: ActionRequirementKind.video,
                  spokenChallengeRequired: false,
                ),
              ],
            ),
          );
          final unrelated = await publishedAction(
            endpoints,
            creator,
            actionRequest(
              actionKey: 'unrelated-action',
              requirements: [
                mediaRequirement(kind: ActionRequirementKind.photo),
              ],
            ),
          );

          expect(revision.revision, 2);
          expect(await isPaused(revision.id), isTrue);
          await expectLater(
            endpoints.actionVerification.publishAction(
              creator,
              actionId: revision.id,
              expectedRevision: revision.revision,
            ),
            throwsStateError,
          );
          expect(await isPaused(unrelated.id), isFalse);
        },
      );
    });

    test(
      'when the same report is retried then one case and one audit event '
      'exist',
      () async {
        final first = await report();
        final repeated = await report();

        expect(repeated.caseId, first.caseId);
        final session = sessionBuilder.build();
        expect(await ModerationCase.db.count(session), 1);
        expect(await ModerationAuditEntry.db.count(session), 1);
        await expectLater(report(category: 'spam'), throwsStateError);
      },
    );

    test('when a report is malformed then it is refused', () async {
      await expectLater(report(category: 'boring'), throwsArgumentError);
      await expectLater(report(details: 'bad'), throwsArgumentError);
      await expectLater(report(key: ' '), throwsArgumentError);
      expect(await ModerationCase.db.count(sessionBuilder.build()), 0);
    });

    test(
      "when someone reports another creator's draft then it is not found",
      () async {
        final draft = await endpoints.actionVerification.saveActionDraft(
          creator,
          actionRequest(
            actionKey: 'secret-draft',
            requirements: [mediaRequirement(kind: ActionRequirementKind.photo)],
          ),
        );

        await expectLater(report(actionId: draft.id), throwsStateError);
      },
    );

    test(
      'when one account keeps reporting a creator then reports are '
      'rate limited',
      () async {
        for (var index = 0; index < 20; index += 1) {
          await report(category: 'spam', key: 'spam-$index');
        }

        await expectLater(
          report(category: 'spam', key: 'spam-20'),
          throwsStateError,
        );
      },
    );

    group('when people check a case', () {
      test('then the reporter and creator see its status', () async {
        final filed = await report();

        final asReporter = await endpoints.moderation.getStatus(
          reporter,
          caseId: filed.caseId,
        );
        final asCreator = await endpoints.moderation.getStatus(
          creator,
          caseId: filed.caseId,
        );

        expect(asReporter.pauseActive, isTrue);
        expect(asCreator.caseId, filed.caseId);
        expect(
          (await endpoints.moderation.listMine(
            reporter,
            limit: 10,
          )).map((item) => item.caseId),
          [filed.caseId],
        );
        expect(
          (await endpoints.moderation.listMine(
            creator,
            limit: 10,
          )).map((item) => item.caseId),
          [filed.caseId],
        );
        expect(
          await endpoints.moderation.listMine(participant, limit: 10),
          isEmpty,
        );
      });

      test('then anyone else is told it does not exist', () async {
        final filed = await report();

        await expectLater(
          endpoints.moderation.getStatus(participant, caseId: filed.caseId),
          throwsStateError,
        );
      });
    });

    group('when staff review a case', () {
      test('then the review surface requires the staff scope', () async {
        final filed = await report();

        await expectLater(
          endpoints.moderationReview.listQueue(creator, limit: 10),
          throwsA(isA<ServerpodInsufficientAccessException>()),
        );
        await expectLater(
          endpoints.moderationReview.review(
            creator,
            caseId: filed.caseId,
            decision: 'dismiss',
            note: 'The creator wants to resume.',
          ),
          throwsA(isA<ServerpodInsufficientAccessException>()),
        );
        await expectLater(
          endpoints.moderationReview.listQueue(sessionBuilder, limit: 10),
          throwsA(isA<ServerpodUnauthenticatedException>()),
        );
      });

      test('then staff see the report text and its audit trail', () async {
        final filed = await report();

        final queue = await endpoints.moderationReview.listQueue(
          staff,
          limit: 10,
        );
        final detail = await endpoints.moderationReview.getCase(
          staff,
          caseId: filed.caseId,
        );

        expect(queue.single.caseId, filed.caseId);
        expect(detail.details, _details);
        expect(detail.audit.single.event, 'reportSubmitted');
        expect(detail.audit.single.actorAuthUserId, reporterId);
        expect(detail.audit.single.pauseActive, isTrue);
      });

      test(
        'then the creator or reporter cannot review even with the scope',
        () async {
          final filed = await report();

          for (final conflicted in [creatorId, reporterId]) {
            await expectLater(
              endpoints.moderationReview.review(
                signedIn(
                  sessionBuilder,
                  conflicted,
                  scopes: {ModerationPolicy.reviewScope},
                ),
                caseId: filed.caseId,
                decision: 'dismiss',
                note: 'Deciding a case I am part of.',
              ),
              throwsStateError,
            );
          }
        },
      );

      test(
        'then a dismissal releases the hold and cannot be appealed',
        () async {
          final filed = await report();

          final dismissed = await endpoints.moderationReview.review(
            staff,
            caseId: filed.caseId,
            decision: 'dismiss',
            note: 'The pylon is a public climbing wall.',
          );

          expect(dismissed.status, 'dismissed');
          expect(dismissed.pauseActive, isFalse);
          expect(await isPaused(action.id), isFalse);
          await expectLater(begin(), completes);
          await expectLater(
            endpoints.moderation.appeal(
              creator,
              caseId: filed.caseId,
              reason: 'There is nothing to appeal here.',
            ),
            throwsStateError,
          );
          await expectLater(
            endpoints.moderationReview.review(
              staff,
              caseId: filed.caseId,
              decision: 'pause',
              note: 'Reviewing it a second time.',
            ),
            throwsStateError,
          );
        },
      );

      test('then an unknown decision is refused', () async {
        final filed = await report();

        await expectLater(
          endpoints.moderationReview.review(
            staff,
            caseId: filed.caseId,
            decision: 'delete',
            note: 'Remove the action entirely.',
          ),
          throwsArgumentError,
        );
      });
    });

    group('when staff keep a hold', () {
      Future<ModerationCaseStatusView> paused({String key = 'report-1'}) async {
        final filed = await report(key: key);
        await endpoints.moderationReview.review(
          staff,
          caseId: filed.caseId,
          decision: 'pause',
          note: 'Human review confirms a safety concern.',
        );
        return filed;
      }

      test(
        'then the creator appeals once and only an independent reviewer can '
        'lift it',
        () async {
          final filed = await paused();
          final status = await endpoints.moderation.getStatus(
            creator,
            caseId: filed.caseId,
          );
          expect(status.status, 'paused');
          expect(status.canAppeal, isTrue);
          await expectLater(
            endpoints.moderation.appeal(
              reporter,
              caseId: filed.caseId,
              reason: 'The reporter cannot appeal for the creator.',
            ),
            throwsStateError,
          );

          final appealed = await endpoints.moderation.appeal(
            creator,
            caseId: filed.caseId,
            reason: 'The route uses a supervised climbing centre.',
          );

          expect(appealed.status, 'appealPending');
          expect(appealed.pauseActive, isTrue);
          expect(await isPaused(action.id), isTrue);
          await expectLater(
            endpoints.moderation.appeal(
              creator,
              caseId: filed.caseId,
              reason: 'Appealing a second time.',
            ),
            throwsStateError,
          );
          await expectLater(
            endpoints.moderationReview.resolveAppeal(
              staff,
              caseId: filed.caseId,
              decision: 'lift',
              note: 'The original reviewer cannot decide this.',
            ),
            throwsStateError,
          );

          final lifted = await endpoints.moderationReview.resolveAppeal(
            secondStaff,
            caseId: filed.caseId,
            decision: 'lift',
            note: 'Independent review supports lifting the hold.',
          );

          expect(lifted.status, 'lifted');
          expect(lifted.pauseActive, isFalse);
          await expectLater(begin(), completes);
          final detail = await endpoints.moderationReview.getCase(
            secondStaff,
            caseId: filed.caseId,
          );
          expect(detail.appealReason, isNotNull);
          expect(detail.audit.map((entry) => entry.event), [
            'reportSubmitted',
            'staffPaused',
            'appealSubmitted',
            'appealLifted',
          ]);
        },
      );

      test('then upholding the appeal keeps the action held', () async {
        final filed = await paused();
        await endpoints.moderation.appeal(
          creator,
          caseId: filed.caseId,
          reason: 'The route uses a supervised climbing centre.',
        );

        final upheld = await endpoints.moderationReview.resolveAppeal(
          secondStaff,
          caseId: filed.caseId,
          decision: 'uphold',
          note: 'The safety concern stands.',
        );

        expect(upheld.status, 'paused');
        expect(upheld.pauseActive, isTrue);
        await expectLater(begin(), throwsStateError);
      });

      test("then lifting one case leaves another case's hold", () async {
        final first = await paused();
        await report(key: 'report-2', category: 'privacy');
        await endpoints.moderation.appeal(
          creator,
          caseId: first.caseId,
          reason: 'The route uses a supervised climbing centre.',
        );

        await endpoints.moderationReview.resolveAppeal(
          secondStaff,
          caseId: first.caseId,
          decision: 'lift',
          note: 'Independent review supports lifting the hold.',
        );

        expect(await isPaused(action.id), isTrue);
        await expectLater(begin(), throwsStateError);
      });
    });

    group('when someone edits the audit trail', () {
      Future<ModerationAuditEntry> entry() async {
        await report();
        return (await ModerationAuditEntry.db.findFirstRow(
          sessionBuilder.build(),
        ))!;
      }

      Future<void> inSavepoint(
        Future<void> Function(Session, Transaction) change,
      ) {
        final session = sessionBuilder.build();
        return DatabaseUtil.runInTransactionOrSavepoint(
          session.db,
          null,
          (transaction) => change(session, transaction),
        );
      }

      test('then an update is rejected and the entry is unchanged', () async {
        final original = await entry();

        await expectLater(
          inSavepoint(
            (session, transaction) => ModerationAuditEntry.db.updateRow(
              session,
              original.copyWith(note: 'Rewritten history.'),
              transaction: transaction,
            ),
          ),
          throwsA(isA<DatabaseException>()),
        );

        final stored = await ModerationAuditEntry.db.findById(
          sessionBuilder.build(),
          original.id!,
        );
        expect(stored!.note, original.note);
      });

      test('then a delete is rejected and the entry remains', () async {
        final original = await entry();

        await expectLater(
          inSavepoint(
            (session, transaction) => ModerationAuditEntry.db.deleteRow(
              session,
              original,
              transaction: transaction,
            ),
          ),
          throwsA(isA<DatabaseException>()),
        );

        expect(
          await ModerationAuditEntry.db.count(sessionBuilder.build()),
          1,
        );
      });
    });
  });
}
