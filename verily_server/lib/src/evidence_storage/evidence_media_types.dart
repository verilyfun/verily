import 'dart:typed_data';

import 'package:verily_evidence/verily_evidence.dart';
import 'package:verily_server/src/generated/protocol.dart';

/// Private evidence lives under this prefix; the B2 key is scoped to it.
const evidenceObjectPrefix = 'action-evidence/';

/// How many leading bytes container detection inspects. The full object is
/// still hashed; only the prefix is buffered.
const mediaSignatureLimit = 4096;

/// One accepted media encoding for private evidence uploads.
final class EvidenceMediaType {
  const EvidenceMediaType._(this.contentType, this.extension, this.kind);

  final String contentType;
  final String extension;
  final MediaEvidenceKind kind;
}

/// The complete allow-list. A content type absent here can never be reserved,
/// confirmed, verified, or reviewed.
const evidenceMediaTypes = <String, EvidenceMediaType>{
  'video/mp4': EvidenceMediaType._('video/mp4', 'mp4', MediaEvidenceKind.video),
  'video/quicktime': EvidenceMediaType._(
    'video/quicktime',
    'mov',
    MediaEvidenceKind.video,
  ),
  'video/webm': EvidenceMediaType._(
    'video/webm',
    'webm',
    MediaEvidenceKind.video,
  ),
  'image/jpeg': EvidenceMediaType._(
    'image/jpeg',
    'jpg',
    MediaEvidenceKind.photo,
  ),
  'image/png': EvidenceMediaType._('image/png', 'png', MediaEvidenceKind.photo),
  'image/heic': EvidenceMediaType._(
    'image/heic',
    'heic',
    MediaEvidenceKind.photo,
  ),
  'audio/mp4': EvidenceMediaType._('audio/mp4', 'm4a', MediaEvidenceKind.audio),
  'audio/webm': EvidenceMediaType._(
    'audio/webm',
    'webm',
    MediaEvidenceKind.audio,
  ),
};

/// Largest accepted upload for one proof of [kind].
int maxEvidenceBytesFor(MediaEvidenceKind kind) => switch (kind) {
  MediaEvidenceKind.video => 150 * 1024 * 1024,
  MediaEvidenceKind.photo => 20 * 1024 * 1024,
  MediaEvidenceKind.audio => 50 * 1024 * 1024,
};

/// The largest upload of any kind; integrity checks bound every size by it.
const int maximumEvidenceByteLength = 150 * 1024 * 1024;

/// The media family of a requirement kind, or null for deterministic proof.
MediaEvidenceKind? mediaKindOf(ActionRequirementKind kind) => switch (kind) {
  ActionRequirementKind.video => MediaEvidenceKind.video,
  ActionRequirementKind.photo => MediaEvidenceKind.photo,
  ActionRequirementKind.audio => MediaEvidenceKind.audio,
  ActionRequirementKind.location ||
  ActionRequirementKind.qrCode ||
  ActionRequirementKind.motion ||
  ActionRequirementKind.externalApp => null,
};

/// Content types accepted for [kind], in a stable order.
List<String> acceptedContentTypesFor(MediaEvidenceKind kind) => [
  for (final type in evidenceMediaTypes.values)
    if (type.kind == kind) type.contentType,
];

/// Validates [contentType] and [byteLength] for one proof of [kind] and
/// returns the canonical media type.
EvidenceMediaType validatedEvidenceMediaType({
  required MediaEvidenceKind kind,
  required String contentType,
  required int byteLength,
}) {
  final normalized = contentType.trim().toLowerCase();
  final type = evidenceMediaTypes[normalized];
  if (type == null || type.kind != kind) {
    throw ArgumentError.value(
      contentType,
      'contentType',
      'This proof accepts ${acceptedContentTypesFor(kind).join(', ')}.',
    );
  }
  final maximum = maxEvidenceBytesFor(kind);
  if (byteLength <= 0 || byteLength > maximum) {
    throw ArgumentError.value(
      byteLength,
      'byteLength',
      'This proof must be ${maximum ~/ (1024 * 1024)} MiB or smaller.',
    );
  }
  return type;
}

/// The server-derived object path for one proof. Every component comes from
/// authenticated database state; clients never choose a path or bucket.
String evidenceStoragePath({
  required String authUserId,
  required String attemptId,
  required String requirementId,
  required EvidenceMediaType type,
}) =>
    '$evidenceObjectPrefix$authUserId/$attemptId/$requirementId.${type.extension}';

/// Content types whose container signature matches [prefix].
///
/// Detection identifies the container family from the first bytes, so a
/// payload that merely claims an allowed content type is refused. It does not
/// parse tracks: an MP4 container is compatible with both `video/mp4` and
/// `audio/mp4`, and the verifier still judges what the media shows.
Set<String> compatibleEvidenceContentTypes(Uint8List prefix) {
  if (_startsWith(prefix, _jpegSignature)) return const {'image/jpeg'};
  if (_startsWith(prefix, _pngSignature)) return const {'image/png'};
  if (_startsWith(prefix, _ebmlSignature) &&
      _containsSequence(prefix, _webmDocType)) {
    return const {'video/webm', 'audio/webm'};
  }
  final brands = _isoBaseMediaBrands(prefix);
  if (brands == null) return const {};
  final major = brands.first;
  if (_heifBrands.contains(major)) return const {'image/heic'};
  if (brands.contains(_quickTimeBrand)) return const {'video/quicktime'};
  if (_audioOnlyBrands.contains(major)) return const {'audio/mp4'};
  if (brands.any(
    (brand) => _mp4Brands.contains(brand) || brand.startsWith('3g'),
  )) {
    return const {'video/mp4', 'audio/mp4'};
  }
  return const {};
}

/// The canonical form of a storage-reported content type.
String? normalizedContentType(String? contentType) =>
    contentType?.split(';').first.trim().toLowerCase();

/// Major brand first, then every compatible brand in the `ftyp` box; null
/// when [bytes] does not start with an ISO base media file type box.
List<String>? _isoBaseMediaBrands(Uint8List bytes) {
  if (bytes.length < 16 ||
      String.fromCharCodes(bytes.sublist(4, 8)) != 'ftyp') {
    return null;
  }
  final declaredBoxLength =
      (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
  if (declaredBoxLength < 16) return null;
  final availableBoxLength = declaredBoxLength < bytes.length
      ? declaredBoxLength
      : bytes.length;
  final brands = <String>[String.fromCharCodes(bytes.sublist(8, 12))];
  for (var offset = 16; offset + 4 <= availableBoxLength; offset += 4) {
    brands.add(String.fromCharCodes(bytes.sublist(offset, offset + 4)));
  }
  return brands;
}

const _jpegSignature = [0xff, 0xd8, 0xff];
const _pngSignature = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
const _ebmlSignature = [0x1a, 0x45, 0xdf, 0xa3];
const _webmDocType = [0x77, 0x65, 0x62, 0x6d];
const _quickTimeBrand = 'qt  ';
const _heifBrands = {
  'heic',
  'heix',
  'heim',
  'heis',
  'hevc',
  'hevx',
  'mif1',
  'msf1',
};
const _audioOnlyBrands = {'M4A ', 'M4B ', 'M4P '};
const _mp4Brands = {
  'isom',
  'iso2',
  'iso3',
  'iso4',
  'iso5',
  'iso6',
  'mp41',
  'mp42',
  'avc1',
  'dash',
  'cmfc',
  'cmfs',
  'M4V ',
  'M4VH',
  'M4VP',
  'F4V ',
  'MSNV',
};

bool _startsWith(List<int> bytes, List<int> signature) {
  if (bytes.length < signature.length) return false;
  for (var index = 0; index < signature.length; index++) {
    if (bytes[index] != signature[index]) return false;
  }
  return true;
}

bool _containsSequence(List<int> bytes, List<int> sequence) {
  for (var offset = 0; offset + sequence.length <= bytes.length; offset++) {
    var matches = true;
    for (var index = 0; index < sequence.length; index++) {
      if (bytes[offset + index] != sequence[index]) {
        matches = false;
        break;
      }
    }
    if (matches) return true;
  }
  return false;
}
