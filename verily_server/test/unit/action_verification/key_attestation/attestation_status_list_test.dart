import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/key_attestation/attestation_status_list.dart';

void main() {
  final start = DateTime.utc(2026, 10, 21, 12);
  const body =
      '{"entries": {"c35747a084470c3135aeefe2b8d40cd6": '
      '{"status": "REVOKED", "reason": "KEY_COMPROMISE"}, '
      '"6681152659205225093": {"status": "SUSPENDED"}}}';

  group('Given the status list body', () {
    test('when parsed then revoked and suspended serials are both listed', () {
      final list = AttestationStatusList.parse(body);

      expect(list.lists('c35747a084470c3135aeefe2b8d40cd6'), isTrue);
      expect(list.lists('6681152659205225093'), isTrue);
      expect(list.lists('1'), isFalse);
    });

    test('when malformed then it is refused rather than read as empty', () {
      for (final malformed in [
        '[]',
        '{}',
        '{"entries": []}',
        '{"entries": {"NOT-HEX": {"status": "REVOKED"}}}',
        '{"entries": {"ab": {}}}',
      ]) {
        expect(
          () => AttestationStatusList.parse(malformed),
          throwsFormatException,
          reason: malformed,
        );
      }
    });
  });

  group('Given Cache-Control headers', () {
    test('when max-age is set then the Age a cache already spent is '
        'subtracted', () {
      expect(
        freshnessLifetime({
          'cache-control': 'public, max-age=86400',
          'age': '752',
        }),
        const Duration(seconds: 86400 - 752),
      );
    });

    test('when caching is forbidden then the response is never reused', () {
      expect(freshnessLifetime({'cache-control': 'no-cache'}), Duration.zero);
      expect(freshnessLifetime({'cache-control': 'no-store'}), Duration.zero);
    });

    test('when max-age is longer than a day then it is capped', () {
      expect(
        freshnessLifetime({'cache-control': 'max-age=604800'}),
        const Duration(days: 1),
      );
    });

    test('when there is no directive then it is reused for an hour', () {
      expect(freshnessLifetime(const {}), const Duration(hours: 1));
    });
  });

  group('Given the Google status source', () {
    late int requests;
    late bool online;

    GoogleAttestationStatusSource source() {
      requests = 0;
      online = true;
      return GoogleAttestationStatusSource(
        clientFactory: () => MockClient((request) async {
          requests += 1;
          if (!online) throw http.ClientException('offline', request.url);
          return http.Response(
            body,
            200,
            headers: {'cache-control': 'public, max-age=3600'},
          );
        }),
      );
    }

    test(
      'when the list is fresh then it is served without a request',
      () async {
        final status = source();

        await status.statusAt(start);
        await status.statusAt(start.add(const Duration(minutes: 59)));

        expect(requests, 1);
      },
    );

    test('when callers arrive together then they share one fetch', () async {
      final status = source();

      await Future.wait([
        for (var index = 0; index < 5; index += 1) status.statusAt(start),
      ]);

      expect(requests, 1);
    });

    test('when the list goes stale then it is fetched again', () async {
      final status = source();

      await status.statusAt(start);
      await status.statusAt(start.add(const Duration(hours: 2)));

      expect(requests, 2);
    });

    test('when a refresh fails within the grace period then the last list '
        'is kept', () async {
      final status = source();
      await status.statusAt(start);
      online = false;

      final list = await status.statusAt(start.add(const Duration(hours: 5)));

      expect(list.lists('c35747a084470c3135aeefe2b8d40cd6'), isTrue);
    });

    test('when a refresh fails past the grace period then it fails '
        'closed', () async {
      final status = source();
      await status.statusAt(start);
      online = false;

      expect(
        status.statusAt(start.add(const Duration(hours: 26))),
        throwsA(isA<AttestationStatusUnavailable>()),
      );
    });

    test('when there has never been a list then it fails closed', () async {
      final status = source();
      online = false;

      expect(
        status.statusAt(start),
        throwsA(isA<AttestationStatusUnavailable>()),
      );
    });

    test('when Google answers with an error then it fails closed', () async {
      final status = GoogleAttestationStatusSource(
        clientFactory: () =>
            MockClient((request) async => http.Response('nope', 503)),
      );

      expect(
        status.statusAt(start),
        throwsA(isA<AttestationStatusUnavailable>()),
      );
    });

    test('when the body is not a status list then it fails closed', () async {
      final status = GoogleAttestationStatusSource(
        clientFactory: () => MockClient(
          (request) async => http.Response(jsonEncode({'entries': 3}), 200),
        ),
      );

      expect(
        status.statusAt(start),
        throwsA(isA<AttestationStatusUnavailable>()),
      );
    });
  });
}
