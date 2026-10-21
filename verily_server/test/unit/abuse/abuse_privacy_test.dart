import 'package:test/test.dart';
import 'package:verily_server/src/abuse/abuse_privacy.dart';

void main() {
  group('AbusePseudonymizer', () {
    late AbusePseudonymizer pseudonymizer;

    setUp(() {
      pseudonymizer = AbusePseudonymizer(
        secret: 'development-only-secret-with-32-bytes',
        keyEpoch: '2026-09-a',
      );
    });

    test('requires a strong operational secret and bounded epoch', () {
      expect(
        () => AbusePseudonymizer(secret: 'short', keyEpoch: 'valid'),
        throwsArgumentError,
      );
      expect(
        () => AbusePseudonymizer(
          secret: 'development-only-secret-with-32-bytes',
          keyEpoch: 'INVALID EPOCH',
        ),
        throwsArgumentError,
      );
    });

    test('derives stable lowercase pseudonyms separated by namespace', () {
      final account = pseudonymizer.account('same-source');
      final device = pseudonymizer.device('same-source');

      expect(account, matches(RegExp(r'^[a-f0-9]{64}$')));
      expect(pseudonymizer.account('same-source'), account);
      expect(device, isNot(account));
      expect(account, isNot(contains('same-source')));
    });

    test('rotation epoch changes every derived key', () {
      final rotated = AbusePseudonymizer(
        secret: 'development-only-secret-with-32-bytes',
        keyEpoch: '2026-09-b',
      );

      expect(
        rotated.account('account'),
        isNot(pseudonymizer.account('account')),
      );
    });

    test('coarsens locations before deriving an opaque value', () {
      final first = pseudonymizer.coarseLocation(
        latitude: 51.5011,
        longitude: -0.1411,
      );
      final nearby = pseudonymizer.coarseLocation(
        latitude: 51.5019,
        longitude: -0.1419,
      );
      final distant = pseudonymizer.coarseLocation(
        latitude: 51.5211,
        longitude: -0.1611,
      );

      expect(nearby, first);
      expect(distant, isNot(first));
      expect(first, matches(RegExp(r'^[a-f0-9]{64}$')));
    });

    test('rejects invalid coordinates and empty source values', () {
      expect(
        () => pseudonymizer.coarseLocation(latitude: 91, longitude: 0),
        throwsArgumentError,
      );
      expect(() => pseudonymizer.device('   '), throwsArgumentError);
    });
  });
}
