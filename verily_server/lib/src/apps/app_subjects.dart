import 'dart:convert';
import 'dart:math';

import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// A new 128-bit pairwise subject: `vls_` plus 22 base64url characters.
String newAppSubject({Random? random}) {
  final source = random ?? Random.secure();
  final bytes = [
    for (var index = 0; index < 16; index += 1) source.nextInt(256),
  ];
  return 'vls_${base64Url.encode(bytes).replaceAll('=', '')}';
}

/// The account's pairwise subject for [appId], created on first use.
///
/// Subjects are stable per App and account and differ for every App, so two
/// Apps can never correlate one person. Account ids are never shared.
Future<VerilyAppLink> appLinkFor(
  Session session, {
  required UuidValue appId,
  required UuidValue authUserId,
  required DateTime now,
  Transaction? transaction,
}) async {
  Future<VerilyAppLink?> existing() => VerilyAppLink.db.findFirstRow(
    session,
    where: (table) =>
        table.appId.equals(appId) & table.authUserId.equals(authUserId),
    transaction: transaction,
  );
  final found = await existing();
  if (found != null) return found;
  await VerilyAppLink.db.insert(
    session,
    [
      VerilyAppLink(
        appId: appId,
        authUserId: authUserId,
        subject: newAppSubject(),
        createdAt: now,
      ),
    ],
    transaction: transaction,
    ignoreConflicts: true,
  );
  final created = await existing();
  if (created == null) throw StateError('The app link was not saved.');
  return created;
}
