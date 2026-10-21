import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:verily_flutter/features/evidence/proof_reasons.dart';
import 'package:verily_flutter/l10n/generated/app_localizations_en.dart';

/// The server's list of public reasons, the only codes the phone sees.
final String _serverSource = File(
  '../verily_server/lib/src/action_verification/public_reasons.dart',
).readAsStringSync();

/// The quoted public codes in the server's `PublicReason` class.
Set<String> _serverProofReasons() {
  final body = _serverSource.substring(
    _serverSource.indexOf('abstract final class PublicReason'),
    _serverSource.indexOf('static const Set<String> all'),
  );
  return {
    for (final match in RegExp(
      r"static const \w+ = '([a-z_]+)';",
    ).allMatches(body))
      match.group(1)!,
  };
}

/// The categories `publicReviewReason` answers with.
Set<String> _serverReviewReasons() {
  final body = _serverSource.substring(
    _serverSource.indexOf('String publicReviewReason'),
  );
  return {
    for (final match in RegExp("=> '([a-z_]+)'").allMatches(body))
      match.group(1)!,
  };
}

void main() {
  final l10n = AppLocalizationsEn();

  test('the app knows the same public reasons as the server', () {
    final server = _serverProofReasons();
    expect(server, hasLength(23));
    for (final code in server) {
      expect(
        proofReasonMessage(l10n, code),
        isNot(l10n.proofReasonOther),
        reason: 'No words for $code',
      );
    }
  });

  test('a reason the app does not know reads as not accepted', () {
    expect(
      proofReasonMessage(l10n, 'media_council_no_consensus'),
      l10n.proofReasonOther,
    );
  });

  test('every review category has its own label', () {
    final server = _serverReviewReasons();
    expect(server, hasLength(9));
    final labels = {for (final code in server) reviewReasonLabel(l10n, code)};
    expect(labels, hasLength(9));
    expect(
      reviewReasonLabel(l10n, 'something_new'),
      l10n.reviewReasonNeedsPerson,
    );
  });
}
