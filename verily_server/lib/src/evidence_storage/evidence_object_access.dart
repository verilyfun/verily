import 'package:serverpod/serverpod.dart';
import 'package:verily_server/src/evidence_storage/evidence_media_types.dart';

/// The Serverpod storage id private evidence is registered under.
const evidenceStorageId = 'evidence';

/// What the server learned by reading one uploaded object end to end.
class EvidenceObjectInspection {
  const EvidenceObjectInspection({
    required this.byteLength,
    required this.contentType,
    required this.compatibleContentTypes,
    required this.versionId,
    required this.sha256Digest,
  });

  final int byteLength;

  /// The content type the storage recorded for the object.
  final String? contentType;

  /// Content types the object's container signature is compatible with.
  final Set<String> compatibleContentTypes;

  /// Immutable version the digest describes. Readers must request it exactly.
  final String versionId;
  final String sha256Digest;

  /// Whether the stored type and the detected container both agree with
  /// [expectedContentType].
  bool matchesContentType(String expectedContentType) {
    final expected = normalizedContentType(expectedContentType);
    return normalizedContentType(contentType) == expected &&
        compatibleContentTypes.contains(expected);
  }
}

/// Server-side access to private evidence that upload confirmation, the
/// verification worker, and reviewers need beyond Serverpod's [CloudStorage].
abstract interface class EvidenceObjectAccess {
  /// Streams the object at [path] through SHA-256 and container detection.
  /// Returns null when no object exists.
  Future<EvidenceObjectInspection?> inspectAndHash(
    Session session,
    String path,
  );

  /// A short-lived private link to exactly [versionId] of [path].
  Future<Uri> createReviewUrl(
    Session session,
    String path, {
    required String versionId,
    Duration expiration = const Duration(minutes: 5),
  });
}

/// Rejects paths that could escape the private evidence prefix.
void validateEvidencePath(String path) {
  if (!path.startsWith(evidenceObjectPrefix) ||
      path.contains('..') ||
      path.contains(r'\')) {
    throw ArgumentError.value(path, 'path', 'Invalid evidence object path.');
  }
}

/// Rejects review links that would outlive the review window.
void validateReviewExpiration(Duration expiration) {
  if (expiration <= Duration.zero || expiration > const Duration(minutes: 10)) {
    throw ArgumentError.value(
      expiration,
      'expiration',
      'Review links must expire within ten minutes.',
    );
  }
}
