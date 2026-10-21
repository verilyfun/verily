import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Google's attestation certificate status list, by certificate serial.
///
/// Every listed serial is untrusted, whether its status is `REVOKED` or
/// `SUSPENDED`: a reward never rests on a certificate Google has pulled,
/// even temporarily.
final class AttestationStatusList {
  AttestationStatusList(Iterable<String> listedSerials)
    : _listed = Set.unmodifiable(listedSerials.map((value) => value.trim()));

  /// Parses the endpoint's `{"entries": {"<serial hex>": {"status": …}}}`.
  factory AttestationStatusList.parse(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('The status list is not an object.');
    }
    final entries = decoded['entries'];
    if (entries is! Map<String, Object?>) {
      throw const FormatException('The status list has no entries.');
    }
    for (final MapEntry(:key, :value) in entries.entries) {
      if (!_serialPattern.hasMatch(key) ||
          value is! Map<String, Object?> ||
          value['status'] is! String) {
        throw const FormatException('Malformed status list entry.');
      }
    }
    return AttestationStatusList(entries.keys);
  }

  final Set<String> _listed;

  int get length => _listed.length;

  /// Whether the certificate with [serialHex] (lowercase, no leading zeros)
  /// is revoked or suspended.
  bool lists(String serialHex) => _listed.contains(serialHex);
}

final _serialPattern = RegExp(r'^[0-9a-f]{1,64}$');

/// No status list was available, so no attestation can be trusted.
final class AttestationStatusUnavailable implements Exception {
  const AttestationStatusUnavailable(this.cause);

  final Object cause;

  @override
  String toString() => 'AttestationStatusUnavailable($cause)';
}

/// Supplies the status list current at a moment.
// An injectable seam so tests can supply a fixed list.
// ignore: one_member_abstracts
abstract interface class AttestationStatusSource {
  /// Throws [AttestationStatusUnavailable] when no usable list exists.
  Future<AttestationStatusList> statusAt(DateTime now);
}

/// Fetches `https://android.googleapis.com/attestation/status` and caches it
/// for as long as its `Cache-Control` allows.
///
/// A failed refresh keeps using the last list for at most [staleGrace] past
/// its freshness, so a short outage does not stop verification; after that,
/// or with no list at all, it fails closed. Concurrent callers share one
/// fetch.
final class GoogleAttestationStatusSource implements AttestationStatusSource {
  GoogleAttestationStatusSource({
    http.Client Function()? clientFactory,
    Uri? uri,
    this.staleGrace = const Duration(hours: 24),
    this.timeout = const Duration(seconds: 10),
  }) : _clientFactory = clientFactory ?? http.Client.new,
       uri = uri ?? Uri.https('android.googleapis.com', '/attestation/status');

  /// One cache per server process.
  static final GoogleAttestationStatusSource shared =
      GoogleAttestationStatusSource();

  final http.Client Function() _clientFactory;
  final Uri uri;
  final Duration staleGrace;
  final Duration timeout;

  AttestationStatusList? _list;
  DateTime? _freshUntil;
  Future<void>? _refresh;

  @override
  Future<AttestationStatusList> statusAt(DateTime now) async {
    final freshUntil = _freshUntil;
    if (_list != null && freshUntil != null && now.isBefore(freshUntil)) {
      return _list!;
    }
    try {
      await (_refresh ??= _fetch(now).whenComplete(() => _refresh = null));
    } on Exception catch (error) {
      final stale = _list;
      if (stale != null &&
          freshUntil != null &&
          now.isBefore(freshUntil.add(staleGrace))) {
        return stale;
      }
      throw AttestationStatusUnavailable(error);
    }
    return _list!;
  }

  Future<void> _fetch(DateTime now) async {
    final client = _clientFactory();
    try {
      final response = await client.get(uri).timeout(timeout);
      if (response.statusCode != 200) {
        throw http.ClientException(
          'Status list answered ${response.statusCode}.',
          uri,
        );
      }
      if (response.bodyBytes.length > _maxBodyBytes) {
        throw const FormatException('The status list is too large.');
      }
      final list = AttestationStatusList.parse(
        utf8.decode(response.bodyBytes),
      );
      _list = list;
      _freshUntil = now.add(freshnessLifetime(response.headers));
    } finally {
      client.close();
    }
  }
}

// The list was about 100 KB in October 2026.
const int _maxBodyBytes = 8 * 1024 * 1024;

/// How long a response stays fresh: `Cache-Control: max-age` less the `Age`
/// a shared cache already spent, capped at a day. `no-store` and `no-cache`
/// are never reused; with no directive it is reused for an hour.
Duration freshnessLifetime(Map<String, String> headers) {
  final directives = [
    for (final part in (headers['cache-control'] ?? '').split(','))
      part.trim().toLowerCase(),
  ];
  if (directives.contains('no-store') || directives.contains('no-cache')) {
    return Duration.zero;
  }
  final maxAge = directives
      .where((directive) => directive.startsWith('max-age='))
      .map((directive) => int.tryParse(directive.substring(8)))
      .firstOrNull;
  final lifetime = maxAge == null
      ? const Duration(hours: 1)
      : Duration(seconds: maxAge.clamp(0, _maxFreshnessSeconds));
  final age = int.tryParse(headers['age']?.trim() ?? '') ?? 0;
  final remaining = lifetime - Duration(seconds: age.clamp(0, 1 << 31));
  return remaining.isNegative ? Duration.zero : remaining;
}

const int _maxFreshnessSeconds = 24 * 60 * 60;
