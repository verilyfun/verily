import 'dart:convert';
import 'dart:typed_data';

/// Refused ASN.1: truncated, over-long, indefinite, or the wrong type.
final class DerFormatException extends FormatException {
  const DerFormatException(super.message);
}

/// The class bits of an ASN.1 identifier octet.
enum DerTagClass { universal, application, contextSpecific, private }

/// Universal tag numbers this reader decodes.
abstract final class DerTag {
  static const boolean = 1;
  static const integer = 2;
  static const bitString = 3;
  static const octetString = 4;
  static const nullValue = 5;
  static const objectIdentifier = 6;
  static const enumerated = 10;
  static const utf8String = 12;
  static const sequence = 16;
  static const set = 17;
  static const printableString = 19;
  static const teletexString = 20;
  static const ia5String = 22;
  static const utcTime = 23;
  static const generalizedTime = 24;
  static const bmpString = 30;
}

/// Parses [bytes] as exactly one element, refusing trailing bytes.
DerElement parseDer(List<int> bytes) {
  final source = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  final element = _readElement(source, 0, source.length);
  if (element.end != source.length) {
    throw const DerFormatException('Trailing bytes after the element.');
  }
  return element;
}

/// One tag-length-value inside a bounds-checked source buffer.
///
/// The reader takes the leniencies real attestation chains need (a long-form
/// length that is not minimal, a BOOLEAN that is neither 0x00 nor 0xFF) and
/// refuses indefinite lengths, truncation, and type confusion.
final class DerElement {
  const DerElement._(
    this._source,
    this.tagClass,
    this.tagNumber, {
    required this.constructed,
    required this.start,
    required this.valueStart,
    required this.end,
  });

  final Uint8List _source;
  final DerTagClass tagClass;
  final int tagNumber;
  final bool constructed;

  /// Offset of the identifier octet in the source.
  final int start;
  final int valueStart;
  final int end;

  /// The complete encoding: identifier, length, and value.
  Uint8List get encoded => Uint8List.sublistView(_source, start, end);

  /// The value octets.
  Uint8List get content => Uint8List.sublistView(_source, valueStart, end);

  bool isUniversal(int number) =>
      tagClass == DerTagClass.universal && tagNumber == number;

  bool isContext(int number) =>
      tagClass == DerTagClass.contextSpecific && tagNumber == number;

  /// The elements inside a constructed value.
  List<DerElement> get children {
    if (!constructed) {
      throw const DerFormatException('Expected a constructed element.');
    }
    final elements = <DerElement>[];
    var offset = valueStart;
    while (offset < end) {
      final element = _readElement(_source, offset, end);
      elements.add(element);
      offset = element.end;
    }
    return elements;
  }

  /// The children of a universal SEQUENCE.
  List<DerElement> get sequence {
    _require(DerTag.sequence);
    return children;
  }

  /// The children of a universal SET.
  List<DerElement> get set {
    _require(DerTag.set);
    return children;
  }

  /// The single element an EXPLICIT context tag wraps.
  DerElement get explicit {
    if (tagClass != DerTagClass.contextSpecific) {
      throw const DerFormatException('Expected a context-specific tag.');
    }
    final inner = children;
    if (inner.length != 1) {
      throw const DerFormatException('An explicit tag wraps one element.');
    }
    return inner.single;
  }

  BigInt get integer {
    _requirePrimitive(DerTag.integer);
    return _signedInteger(content);
  }

  BigInt get enumerated {
    _requirePrimitive(DerTag.enumerated);
    return _signedInteger(content);
  }

  /// An INTEGER or ENUMERATED that fits comfortably in an [int].
  int get smallInteger {
    final value = isUniversal(DerTag.enumerated) ? enumerated : integer;
    if (value.bitLength > 52) {
      throw const DerFormatException('Integer is out of range.');
    }
    return value.toInt();
  }

  bool get boolean {
    _requirePrimitive(DerTag.boolean);
    final value = content;
    if (value.length != 1) {
      throw const DerFormatException('A BOOLEAN has one octet.');
    }
    // DER requires 0xFF for true; older keystores write 0x01.
    return value.single != 0;
  }

  Uint8List get octets {
    _requirePrimitive(DerTag.octetString);
    return content;
  }

  /// A BIT STRING whose length is a whole number of octets.
  Uint8List get bitStringBytes {
    _requirePrimitive(DerTag.bitString);
    final value = content;
    if (value.isEmpty || value.first != 0) {
      throw const DerFormatException('Expected a whole-octet BIT STRING.');
    }
    return Uint8List.sublistView(value, 1);
  }

  String get objectIdentifier {
    _requirePrimitive(DerTag.objectIdentifier);
    final value = content;
    if (value.isEmpty || value.last & 0x80 != 0) {
      throw const DerFormatException('Malformed object identifier.');
    }
    final arcs = <BigInt>[];
    var current = BigInt.zero;
    for (final byte in value) {
      current = (current << 7) | BigInt.from(byte & 0x7f);
      if (byte & 0x80 == 0) {
        arcs.add(current);
        current = BigInt.zero;
      }
    }
    final first = arcs.first;
    final head = first < BigInt.from(80)
        ? [first ~/ BigInt.from(40), first % BigInt.from(40)]
        : [BigInt.two, first - BigInt.from(80)];
    return [...head, ...arcs.skip(1)].join('.');
  }

  /// Any of the string types X.509 names use.
  String get text {
    if (tagClass != DerTagClass.universal || constructed) {
      throw const DerFormatException('Expected a primitive string.');
    }
    final value = content;
    return switch (tagNumber) {
      DerTag.utf8String => utf8.decode(value),
      DerTag.printableString ||
      DerTag.ia5String ||
      DerTag.teletexString => latin1.decode(value),
      DerTag.bmpString => _bmpString(value),
      _ => throw const DerFormatException('Expected a string.'),
    };
  }

  /// A UTCTime or GeneralizedTime, which X.509 writes in UTC.
  DateTime get time {
    if (tagClass != DerTagClass.universal || constructed) {
      throw const DerFormatException('Expected a time.');
    }
    final value = ascii.decode(content);
    final match = switch (tagNumber) {
      DerTag.utcTime => _utcTimePattern.firstMatch(value),
      DerTag.generalizedTime => _generalizedTimePattern.firstMatch(value),
      _ => throw const DerFormatException('Expected a time.'),
    };
    if (match == null) throw const DerFormatException('Malformed time.');
    int field(int group) => int.parse(match.group(group)!);
    var year = field(1);
    if (tagNumber == DerTag.utcTime) year += year < 50 ? 2000 : 1900;
    final parsed = DateTime.utc(
      year,
      field(2),
      field(3),
      field(4),
      field(5),
      field(6),
    );
    // DateTime rolls 31 February into March; a certificate must not.
    if (parsed.month != field(2) ||
        parsed.day != field(3) ||
        parsed.hour != field(4) ||
        parsed.minute != field(5) ||
        parsed.second != field(6)) {
      throw const DerFormatException('Time is out of range.');
    }
    return parsed;
  }

  void _require(int number) {
    if (!isUniversal(number)) {
      throw DerFormatException('Expected universal tag $number.');
    }
  }

  void _requirePrimitive(int number) {
    _require(number);
    if (constructed) {
      throw DerFormatException('Expected primitive tag $number.');
    }
  }
}

final _utcTimePattern = RegExp(
  r'^(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})Z$',
);
final _generalizedTimePattern = RegExp(
  r'^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})Z$',
);

DerElement _readElement(Uint8List source, int offset, int limit) {
  var index = offset;
  int next() {
    if (index >= limit) throw const DerFormatException('Truncated element.');
    return source[index++];
  }

  final identifier = next();
  final tagClass = DerTagClass.values[identifier >> 6];
  final constructed = identifier & 0x20 != 0;
  var tagNumber = identifier & 0x1f;
  if (tagNumber == 0x1f) {
    // High-tag-number form: KeyMint's tags reach [724] and beyond.
    tagNumber = 0;
    for (var octets = 0; ; octets += 1) {
      if (octets == 4) throw const DerFormatException('Tag is too large.');
      final byte = next();
      tagNumber = (tagNumber << 7) | (byte & 0x7f);
      if (byte & 0x80 == 0) break;
    }
  }

  final first = next();
  int length;
  if (first < 0x80) {
    length = first;
  } else if (first == 0x80) {
    throw const DerFormatException('Indefinite lengths are not DER.');
  } else {
    final octets = first & 0x7f;
    if (octets > 4) throw const DerFormatException('Length is too large.');
    length = 0;
    for (var count = 0; count < octets; count += 1) {
      length = (length << 8) | next();
    }
  }
  final valueStart = index;
  final end = valueStart + length;
  if (end > limit) throw const DerFormatException('Truncated element.');
  return DerElement._(
    source,
    tagClass,
    tagNumber,
    constructed: constructed,
    start: offset,
    valueStart: valueStart,
    end: end,
  );
}

BigInt _signedInteger(Uint8List value) {
  if (value.isEmpty) throw const DerFormatException('Empty integer.');
  var result = BigInt.zero;
  for (final byte in value) {
    result = (result << 8) | BigInt.from(byte);
  }
  if (value.first & 0x80 != 0) {
    result -= BigInt.one << (8 * value.length);
  }
  return result;
}

String _bmpString(Uint8List value) {
  if (value.length.isOdd) throw const DerFormatException('Malformed string.');
  return String.fromCharCodes([
    for (var index = 0; index < value.length; index += 2)
      (value[index] << 8) | value[index + 1],
  ]);
}
