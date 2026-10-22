import 'dart:convert';
import 'dart:typed_data';

/// Refused CBOR: truncated, indefinite, tagged, too deep, or ambiguous.
final class CborFormatException extends FormatException {
  const CborFormatException(super.message);
}

/// Decodes [bytes] as exactly one CBOR data item (RFC 8949), refusing
/// trailing bytes.
///
/// Items become Dart values: unsigned and negative integers are [int], byte
/// strings [Uint8List], text strings [String], arrays `List<Object>`, and
/// maps `Map<Object, Object>` keyed by [int] or [String].
Object decodeCbor(List<int> bytes) {
  final source = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  final (value, end) = readCborItem(source, 0);
  if (end != source.length) {
    throw const CborFormatException('Trailing bytes after the item.');
  }
  return value;
}

/// Reads the one item that starts at [offset] and returns it with the offset
/// just past it, for formats such as authenticator data that embed CBOR among
/// raw bytes.
///
/// App Attest writes only definite-length integers, strings, arrays, and
/// maps, so this reader refuses everything else: indefinite lengths, tags,
/// floats and simple values, integers beyond 63 bits, invalid UTF-8, map keys
/// that are not integers or text, and repeated map keys.
(Object, int) readCborItem(Uint8List source, int offset) {
  final reader = _CborReader(source, offset);
  final value = reader.read(0);
  return (value, reader.offset);
}

const _maxDepth = 16;

final class _CborReader {
  _CborReader(this._source, this.offset);

  final Uint8List _source;
  int offset;

  Object read(int depth) {
    if (depth > _maxDepth) {
      throw const CborFormatException('Nesting is too deep.');
    }
    final initial = _byte();
    final major = initial >> 5;
    final argument = _argument(initial & 0x1f);
    switch (major) {
      case 0:
        return argument;
      case 1:
        return -1 - argument;
      case 2:
        return Uint8List.fromList(_take(argument));
      case 3:
        try {
          return utf8.decode(_take(argument));
        } on FormatException {
          throw const CborFormatException('Text is not valid UTF-8.');
        }
      case 4:
        _requireRoomFor(argument);
        return List<Object>.unmodifiable([
          for (var index = 0; index < argument; index += 1) read(depth + 1),
        ]);
      case 5:
        // Each entry is at least two bytes: a key and a value.
        _requireRoomFor(argument * 2);
        final entries = <Object, Object>{};
        for (var index = 0; index < argument; index += 1) {
          final key = read(depth + 1);
          if (key is! int && key is! String) {
            throw const CborFormatException('Map keys are integers or text.');
          }
          if (entries.containsKey(key)) {
            throw const CborFormatException('Duplicate map key.');
          }
          entries[key] = read(depth + 1);
        }
        return Map<Object, Object>.unmodifiable(entries);
      default:
        throw const CborFormatException('Tags and simple values are refused.');
    }
  }

  int _byte() {
    if (offset >= _source.length) {
      throw const CborFormatException('Truncated item.');
    }
    return _source[offset++];
  }

  /// The integer that follows an initial byte with additional information
  /// [info]: inline below 24, then one, two, four, or eight bytes.
  int _argument(int info) {
    if (info < 24) return info;
    final length = switch (info) {
      24 => 1,
      25 => 2,
      26 => 4,
      27 => 8,
      31 => throw const CborFormatException('Indefinite lengths are refused.'),
      _ => throw const CborFormatException('Reserved additional information.'),
    };
    final bytes = _take(length);
    // Dart integers are signed 64-bit; nothing App Attest writes needs more.
    if (length == 8 && bytes.first & 0x80 != 0) {
      throw const CborFormatException('Integer is out of range.');
    }
    return bytes.fold(0, (value, byte) => (value << 8) | byte);
  }

  Uint8List _take(int length) {
    _requireRoomFor(length);
    final bytes = Uint8List.sublistView(_source, offset, offset + length);
    offset += length;
    return bytes;
  }

  /// Refuses a length that the remaining input cannot hold, before any
  /// allocation it would size.
  void _requireRoomFor(int length) {
    if (length < 0 || length > _source.length - offset) {
      throw const CborFormatException('Truncated item.');
    }
  }
}
