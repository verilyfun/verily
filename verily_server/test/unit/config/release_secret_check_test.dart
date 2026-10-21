import 'dart:io';

import 'package:monosecret/monosecret.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/config/release_secret_check.dart';

void main() {
  group('missingRequiredSecretNames', () {
    test('returns only required declarations that are missing', () {
      final report = ResolutionReport(
        provider: 'env://',
        profile: 'production',
        scope: null,
        secrets: const [
          SecretReport(
            name: 'AVAILABLE',
            status: 'resolved',
            required: true,
            sourceProvider: 'env://',
            defaultApplied: false,
            generated: false,
            asPath: false,
          ),
          SecretReport(
            name: 'OPTIONAL',
            status: 'missing_optional',
            required: false,
            sourceProvider: null,
            defaultApplied: false,
            generated: false,
            asPath: false,
          ),
          SecretReport(
            name: 'REQUIRED',
            status: 'missing_required',
            required: true,
            sourceProvider: null,
            defaultApplied: false,
            generated: false,
            asPath: false,
          ),
        ],
      );

      expect(missingRequiredSecretNames(report), ['REQUIRED']);
    });

    test('returns an empty list when every required declaration resolves', () {
      final report = ResolutionReport(
        provider: 'env://',
        profile: 'production',
        scope: null,
        secrets: const [
          SecretReport(
            name: 'AVAILABLE',
            status: 'resolved',
            required: true,
            sourceProvider: 'env://',
            defaultApplied: false,
            generated: false,
            asPath: false,
          ),
        ],
      );

      expect(missingRequiredSecretNames(report), isEmpty);
    });
  });

  group('Given the committed manifest and only injected values', () {
    const b2Names = [
      'VERILY_EVIDENCE_B2_S3_ENDPOINT',
      'VERILY_EVIDENCE_B2_REGION',
      'VERILY_EVIDENCE_B2_BUCKET_NAME',
      'VERILY_EVIDENCE_B2_KEY_ID',
      'VERILY_EVIDENCE_B2_APPLICATION_KEY',
    ];
    final absentB2 = [
      for (final name in b2Names)
        if ((Platform.environment[name] ?? '').isEmpty) name,
    ];

    test('when production is checked then private evidence storage is '
        'required and optional integrations are not', () async {
      final report = await loadReleaseSecretReport(
        manifestPath: File('../monosecret.toml').absolute.path,
      );
      final missing = missingRequiredSecretNames(report);

      expect(report.profile, 'production');
      expect(missing, containsAll(absentB2));
      for (final optional in const [
        'VERILY_OPENROUTER_API_KEY',
        'VERILY_MEDIA_VERIFIER_TOKEN',
        'VERILY_RESEND_API_KEY',
        'OP_SERVICE_ACCOUNT_TOKEN',
      ]) {
        expect(missing, isNot(contains(optional)));
      }
    });

    test('when staging is checked then private evidence storage is '
        'required too', () async {
      final report = await Monosecret.builder()
          .withPath(File('../monosecret.toml').absolute.path)
          .withProfile('staging')
          .withProvider('injected')
          .withReason('Validate Verily staging secret declarations')
          .report();

      expect(missingRequiredSecretNames(report), containsAll(absentB2));
    });
  });
}
