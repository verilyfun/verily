import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:verily_evidence/verily_evidence.dart';
import 'package:verily_server/src/evidence_storage/evidence_media_types.dart';
import 'package:verily_server/src/evidence_storage/evidence_object_access.dart';
import 'package:verily_server/src/generated/protocol.dart';

void main() {
  group('Given container signatures', () {
    final cases = <String, (Uint8List, Set<String>)>{
      'jpeg': (_bytes([0xff, 0xd8, 0xff, 0xe0]), {'image/jpeg'}),
      'png': (
        _bytes([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
        {'image/png'},
      ),
      'heic': (_ftyp('heic', ['mif1', 'heic']), {'image/heic'}),
      'mif1 heif': (_ftyp('mif1', ['heic']), {'image/heic'}),
      'mp4': (_ftyp('isom', ['isom', 'mp41']), {'video/mp4', 'audio/mp4'}),
      '3gp': (_ftyp('3gp5', ['3gp5']), {'video/mp4', 'audio/mp4'}),
      'quicktime': (_ftyp('qt  ', ['qt  ']), {'video/quicktime'}),
      'm4a': (_ftyp('M4A ', ['M4A ', 'mp42']), {'audio/mp4'}),
      'webm': (
        _bytes([
          0x1a,
          0x45,
          0xdf,
          0xa3,
          0x42,
          0x82,
          0x84,
          ...ascii.encode('webm'),
        ]),
        {'video/webm', 'audio/webm'},
      ),
    };

    for (final entry in cases.entries) {
      test('when the bytes are ${entry.key} then the compatible types are '
          '${entry.value.$2}', () {
        expect(compatibleEvidenceContentTypes(entry.value.$1), entry.value.$2);
      });
    }

    test('when the bytes are text claiming to be media then nothing is '
        'compatible', () {
      expect(
        compatibleEvidenceContentTypes(
          Uint8List.fromList(utf8.encode('This is not a video at all.')),
        ),
        isEmpty,
      );
    });

    test('when an ftyp box declares an impossible length then nothing is '
        'compatible', () {
      final bytes = _ftyp('isom', ['isom'])..[3] = 8;
      expect(compatibleEvidenceContentTypes(bytes), isEmpty);
    });

    test('when an EBML header is not WebM then nothing is compatible', () {
      expect(
        compatibleEvidenceContentTypes(
          _bytes([0x1a, 0x45, 0xdf, 0xa3, ...ascii.encode('matroska')]),
        ),
        isEmpty,
      );
    });

    test('when an ISO container has only unknown brands then nothing is '
        'compatible', () {
      expect(compatibleEvidenceContentTypes(_ftyp('zzzz', ['yyyy'])), isEmpty);
    });
  });

  group('Given a stored inspection', () {
    EvidenceObjectInspection inspection(String? stored, Set<String> detected) =>
        EvidenceObjectInspection(
          byteLength: 10,
          contentType: stored,
          compatibleContentTypes: detected,
          versionId: 'v',
          sha256Digest: 'a' * 64,
        );

    test('when the stored type and container agree then it matches', () {
      expect(
        inspection('audio/mp4', {
          'video/mp4',
          'audio/mp4',
        }).matchesContentType('audio/mp4'),
        isTrue,
      );
      expect(
        inspection('Image/JPEG; q=1', {
          'image/jpeg',
        }).matchesContentType('image/jpeg'),
        isTrue,
      );
    });

    test('when the claimed type disagrees with the container then it does '
        'not match', () {
      expect(
        inspection('image/png', {'image/jpeg'}).matchesContentType('image/png'),
        isFalse,
      );
      expect(
        inspection('video/mp4', {'video/mp4'}).matchesContentType('video/webm'),
        isFalse,
      );
      expect(
        inspection(null, {'image/png'}).matchesContentType('image/png'),
        isFalse,
      );
    });
  });

  group('Given an upload request', () {
    test('when each kind is asked for its types then the allow-lists are '
        'exact', () {
      expect(acceptedContentTypesFor(MediaEvidenceKind.video), [
        'video/mp4',
        'video/quicktime',
        'video/webm',
      ]);
      expect(acceptedContentTypesFor(MediaEvidenceKind.photo), [
        'image/jpeg',
        'image/png',
        'image/heic',
      ]);
      expect(acceptedContentTypesFor(MediaEvidenceKind.audio), [
        'audio/mp4',
        'audio/webm',
      ]);
    });

    test('when the size is at each cap then it is accepted, and one byte '
        'more is refused', () {
      const mib = 1024 * 1024;
      for (final (kind, type, cap) in [
        (MediaEvidenceKind.video, 'video/mp4', 150 * mib),
        (MediaEvidenceKind.photo, 'image/jpeg', 20 * mib),
        (MediaEvidenceKind.audio, 'audio/mp4', 50 * mib),
      ]) {
        expect(maxEvidenceBytesFor(kind), cap);
        expect(
          validatedEvidenceMediaType(
            kind: kind,
            contentType: type,
            byteLength: cap,
          ).contentType,
          type,
        );
        expect(
          () => validatedEvidenceMediaType(
            kind: kind,
            contentType: type,
            byteLength: cap + 1,
          ),
          throwsArgumentError,
          reason: '$kind',
        );
      }
      expect(maximumEvidenceByteLength, 150 * mib);
    });

    test('when the size is not positive then it is refused', () {
      expect(
        () => validatedEvidenceMediaType(
          kind: MediaEvidenceKind.photo,
          contentType: 'image/png',
          byteLength: 0,
        ),
        throwsArgumentError,
      );
    });

    test('when a type belongs to another kind then it is refused', () {
      for (final (kind, type) in [
        (MediaEvidenceKind.video, 'image/jpeg'),
        (MediaEvidenceKind.video, 'audio/mp4'),
        (MediaEvidenceKind.photo, 'video/mp4'),
        (MediaEvidenceKind.photo, 'image/gif'),
        (MediaEvidenceKind.audio, 'audio/mpeg'),
        (MediaEvidenceKind.audio, 'video/webm'),
      ]) {
        expect(
          () => validatedEvidenceMediaType(
            kind: kind,
            contentType: type,
            byteLength: 10,
          ),
          throwsArgumentError,
          reason: '$kind $type',
        );
      }
    });

    test('when the type differs only in case and padding then the canonical '
        'type is returned', () {
      expect(
        validatedEvidenceMediaType(
          kind: MediaEvidenceKind.audio,
          contentType: ' Audio/WebM ',
          byteLength: 10,
        ).contentType,
        'audio/webm',
      );
    });
  });

  group('Given requirement kinds', () {
    test('when mapped then only media kinds have a media family', () {
      expect(mediaKindOf(ActionRequirementKind.video), MediaEvidenceKind.video);
      expect(mediaKindOf(ActionRequirementKind.photo), MediaEvidenceKind.photo);
      expect(mediaKindOf(ActionRequirementKind.audio), MediaEvidenceKind.audio);
      for (final kind in [
        ActionRequirementKind.location,
        ActionRequirementKind.qrCode,
        ActionRequirementKind.motion,
        ActionRequirementKind.externalApp,
      ]) {
        expect(mediaKindOf(kind), isNull, reason: '$kind');
      }
    });
  });

  group('Given server-derived identity', () {
    test('when a path is built then it sits under the private prefix with '
        'the canonical extension', () {
      expect(
        evidenceStoragePath(
          authUserId: 'user',
          attemptId: 'attempt',
          requirementId: 'requirement',
          type: evidenceMediaTypes['audio/mp4']!,
        ),
        'action-evidence/user/attempt/requirement.m4a',
      );
    });

    for (final path in [
      'other-prefix/user/attempt/requirement.mp4',
      'action-evidence/../secrets/key',
      r'action-evidence\user\attempt.mp4',
    ]) {
      test('when "$path" is used then it is refused', () {
        expect(() => validateEvidencePath(path), throwsArgumentError);
      });
    }

    test('when a review link would outlive ten minutes then it is '
        'refused', () {
      expect(
        () => validateReviewExpiration(const Duration(minutes: 11)),
        throwsArgumentError,
      );
      expect(
        () => validateReviewExpiration(Duration.zero),
        throwsArgumentError,
      );
      expect(
        () => validateReviewExpiration(const Duration(minutes: 10)),
        returnsNormally,
      );
    });
  });
}

Uint8List _bytes(List<int> header) =>
    Uint8List.fromList([...header, ...List<int>.filled(32, 0)]);

Uint8List _ftyp(String major, List<String> compatible) {
  final body = [
    ...ascii.encode(major),
    0,
    0,
    2,
    0,
    for (final brand in compatible) ...ascii.encode(brand),
  ];
  final length = body.length + 8;
  return Uint8List.fromList([
    0,
    0,
    (length >> 8) & 0xff,
    length & 0xff,
    ...ascii.encode('ftyp'),
    ...body,
  ]);
}
