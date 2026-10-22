import 'dart:convert';
import 'dart:typed_data';

/// Encodes [value] as definite-length CBOR (RFC 8949): [int], [Uint8List]
/// (a byte string), [String], [List] (an array), and [Map] in insertion
/// order. Only [Uint8List] is a byte string, so a list of numbers is never
/// mistaken for one.
Uint8List encodeCbor(Object value) {
  final output = BytesBuilder(copy: false);
  _write(output, value);
  return output.takeBytes();
}

void _write(BytesBuilder output, Object value) {
  switch (value) {
    case final int number when number >= 0:
      _header(output, 0, number);
    case final int number:
      _header(output, 1, -1 - number);
    case final Uint8List bytes:
      _header(output, 2, bytes.length);
      output.add(bytes);
    case final String text:
      final bytes = utf8.encode(text);
      _header(output, 3, bytes.length);
      output.add(bytes);
    case final List<Object> items:
      _header(output, 4, items.length);
      for (final item in items) {
        _write(output, item);
      }
    case final Map<Object, Object> entries:
      _header(output, 5, entries.length);
      for (final MapEntry(:key, :value) in entries.entries) {
        _write(output, key);
        _write(output, value);
      }
    default:
      throw ArgumentError.value(value, 'value', 'Cannot be encoded.');
  }
}

void _header(BytesBuilder output, int major, int argument) {
  final type = major << 5;
  if (argument < 24) {
    output.addByte(type | argument);
    return;
  }
  final (info, length) = switch (argument) {
    < 0x100 => (24, 1),
    < 0x10000 => (25, 2),
    < 0x100000000 => (26, 4),
    _ => (27, 8),
  };
  output.addByte(type | info);
  for (var shift = 8 * (length - 1); shift >= 0; shift -= 8) {
    output.addByte((argument >> shift) & 0xff);
  }
}
