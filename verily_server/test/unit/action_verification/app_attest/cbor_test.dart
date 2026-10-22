import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/app_attest/cbor.dart';

import '../../../integration/test_tools/cbor_writer.dart';

void main() {
  group('Given well-formed CBOR', () {
    test('when it holds the shapes App Attest writes then it decodes', () {
      final encoded = encodeCbor({
        'fmt': 'apple-appattest',
        'attStmt': {
          'x5c': [
            Uint8List.fromList([1, 2]),
            Uint8List.fromList([3]),
          ],
        },
        1: 2,
        -7: -1,
        'big': 0x100000000,
      });

      final decoded = decodeCbor(encoded);

      expect(decoded, {
        'fmt': 'apple-appattest',
        'attStmt': {
          'x5c': [
            [1, 2],
            [3],
          ],
        },
        1: 2,
        -7: -1,
        'big': 0x100000000,
      });
    });

    test('when it is embedded among raw bytes then the reader says where it '
        'ends', () {
      final item = encodeCbor({'a': 1});
      final source = Uint8List.fromList([0xff, ...item, 0xee]);

      final (value, end) = readCborItem(source, 1);

      expect(value, {'a': 1});
      expect(end, 1 + item.length);
    });
  });

  group('Given CBOR App Attest never writes', () {
    final refused = <String, List<int>>{
      'an indefinite-length array': [0x9f, 0x01, 0xff],
      'an indefinite-length byte string': [0x5f, 0x41, 0x00, 0xff],
      'a tag': [0xc0, 0x60],
      'a half-precision float': [0xf9, 0x3c, 0x00],
      'a boolean': [0xf5],
      'reserved additional information': [0x1c],
      'a truncated byte string': [0x43, 0x01, 0x02],
      'a truncated length': [0x19, 0x01],
      'a map with a repeated key': [0xa2, 0x01, 0x01, 0x01, 0x02],
      'a map keyed by bytes': [0xa1, 0x41, 0x00, 0x01],
      'invalid UTF-8 text': [0x62, 0xc3, 0x28],
      'an integer beyond 63 bits': [
        0x1b, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, //
      ],
      'an array claiming more items than bytes': [0x9a, 0xff, 0xff, 0xff, 0x00],
      'trailing bytes': [0x01, 0x02],
      'nothing': [],
    };
    for (final MapEntry(key: name, value: bytes) in refused.entries) {
      test('when it is $name then it is refused', () {
        expect(
          () => decodeCbor(bytes),
          throwsA(isA<CborFormatException>()),
        );
      });
    }

    test('when nesting is too deep then it is refused', () {
      final nested = [...List.filled(40, 0x81), 0x01];

      expect(() => decodeCbor(nested), throwsA(isA<CborFormatException>()));
    });
  });
}
