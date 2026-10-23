import 'dart:typed_data';

/// Apple's PKCS#7 envelope uses BER indefinite containers and fragmented
/// OCTET STRINGs. Normalize that bounded envelope to DER; primitive payload
/// bytes (including the signed receipt SET) are never rewritten.
Uint8List normalizeReceiptBer(List<int> input) {
  var offset = 0;
  var nodes = 0;
  int next() {
    if (offset >= input.length) throw const FormatException('Truncated BER.');
    return input[offset++];
  }

  List<int> read(int depth) {
    if (depth > 24 || ++nodes > 4096) throw const FormatException('BER limit.');
    final tag = next();
    if (tag == 0 || tag & 31 == 31) throw const FormatException('BER tag.');
    final first = next();
    final indefinite = first == 0x80;
    var length = first;
    if (first > 0x80) {
      final count = first & 0x7f;
      if (count > 4) throw const FormatException('BER length.');
      length = 0;
      for (var i = 0; i < count; i++) {
        length = (length << 8) | next();
      }
    }
    if (indefinite && tag & 0x20 == 0) {
      throw const FormatException('Primitive BER length.');
    }
    final end = offset + length;
    if (!indefinite && end > input.length) {
      throw const FormatException('BER length.');
    }
    var value = <int>[];
    if (tag & 0x20 == 0) {
      value = input.sublist(offset, end);
      offset = end;
    } else {
      while (indefinite
          ? !(offset + 1 < input.length &&
                input[offset] == 0 &&
                input[offset + 1] == 0)
          : offset < end) {
        final child = read(depth + 1);
        if (tag == 0x24) {
          // Flatten only OCTET STRING fragments; the tag/length are discarded.
          if (child.first != 4) {
            throw const FormatException('BER octet fragment.');
          }
          var start = 2;
          if (child[1] >= 128) start += child[1] & 127;
          value.addAll(child.sublist(start));
        } else {
          value.addAll(child);
        }
      }
      if (indefinite) {
        offset += 2;
      } else if (offset != end) {
        throw const FormatException('BER container overrun.');
      }
    }
    final size = <int>[];
    for (var remaining = value.length; remaining > 0; remaining >>= 8) {
      size.insert(0, remaining & 255);
    }
    return [
      if (tag == 0x24) 4 else tag,
      if (value.length < 128)
        value.length
      else ...[
        0x80 | size.length,
        ...size,
      ],
      ...value,
    ];
  }

  final result = read(0);
  if (offset != input.length) throw const FormatException('Trailing BER.');
  return Uint8List.fromList(result);
}
