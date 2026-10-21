import 'dart:io';

import 'package:verily_server/src/generated/protocol.dart';

/// Resolves a host name to addresses. Injectable so tests never touch DNS.
typedef HostResolver = Future<List<InternetAddress>> Function(String host);

Future<List<InternetAddress>> systemHostResolver(String host) =>
    InternetAddress.lookup(host);

const maxWebhookUrlLength = 2048;

/// Checks a creator-supplied webhook URL before it is saved.
///
/// Only `https` on the default port, with a real public host name or public
/// IP literal, no credentials, no fragment, and no private-network names.
/// Host names are resolved now as well, and every address must be public;
/// the sender checks again at send time because DNS can change.
Future<Uri> validateWebhookUrl(
  String value, {
  HostResolver resolve = systemHostResolver,
}) async {
  final uri = parseWebhookUrl(value);
  final addresses = await resolvePublicAddresses(uri.host, resolve: resolve);
  if (addresses == null) {
    throw _invalid('The webhook host must resolve to a public address.');
  }
  return uri;
}

/// The synchronous part of [validateWebhookUrl]: shape only, no DNS.
Uri parseWebhookUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed.length > maxWebhookUrlLength) {
    throw _invalid('Enter an https URL of at most 2048 characters.');
  }
  final uri = Uri.tryParse(trimmed);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment ||
      (uri.hasPort && uri.port != 443)) {
    throw _invalid(
      'Webhook URLs must be https on the standard port, without credentials '
      'or a fragment.',
    );
  }
  final host = uri.host.toLowerCase();
  final literal = InternetAddress.tryParse(host);
  if (literal != null) {
    if (!isPublicAddress(literal)) {
      throw _invalid('The webhook host must be a public address.');
    }
    return uri;
  }
  if (!host.contains('.') ||
      host == 'localhost' ||
      _privateSuffixes.any(host.endsWith)) {
    throw _invalid('The webhook host must be a public domain name.');
  }
  return uri;
}

/// Every address [host] resolves to, or null when it resolves to nothing or
/// to any address that is not publicly routable. One private record among
/// public ones refuses the whole host, which defeats split-horizon rebinding.
Future<List<InternetAddress>?> resolvePublicAddresses(
  String host, {
  HostResolver resolve = systemHostResolver,
}) async {
  final literal = InternetAddress.tryParse(host);
  if (literal != null) return isPublicAddress(literal) ? [literal] : null;
  final List<InternetAddress> addresses;
  try {
    addresses = await resolve(host);
  } on SocketException {
    return null;
  }
  if (addresses.isEmpty || !addresses.every(isPublicAddress)) return null;
  return addresses;
}

/// Whether [address] is globally routable unicast: not loopback, private,
/// link-local, shared (CGNAT), documentation, benchmarking, multicast,
/// reserved, or an IPv6 form that embeds one of those.
bool isPublicAddress(InternetAddress address) {
  final bytes = address.rawAddress;
  if (address.type == InternetAddressType.IPv4) return _publicIPv4(bytes);
  if (address.type != InternetAddressType.IPv6 || bytes.length != 16) {
    return false;
  }
  bool prefix(List<int> start) {
    for (var index = 0; index < start.length; index += 1) {
      if (bytes[index] != start[index]) return false;
    }
    return true;
  }

  // ::/128 and ::1, and IPv4-compatible ::a.b.c.d.
  if (bytes.sublist(0, 12).every((byte) => byte == 0)) return false;
  // IPv4-mapped ::ffff:a.b.c.d judges the embedded IPv4 address.
  if (prefix(const [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xff, 0xff])) {
    return _publicIPv4(bytes.sublist(12));
  }
  // NAT64 64:ff9b::/96 also embeds IPv4.
  if (prefix(const [0, 0x64, 0xff, 0x9b, 0, 0, 0, 0, 0, 0, 0, 0])) {
    return _publicIPv4(bytes.sublist(12));
  }
  // 6to4 2002::/16 embeds IPv4 in bytes 2..5.
  if (prefix(const [0x20, 0x02])) return _publicIPv4(bytes.sublist(2, 6));
  final first = bytes[0];
  if ((first & 0xfe) == 0xfc) return false; // fc00::/7 unique local
  if (first == 0xfe && (bytes[1] & 0xc0) == 0x80) return false; // fe80::/10
  if (first == 0xfe && (bytes[1] & 0xc0) == 0xc0) return false; // fec0::/10
  if (first == 0xff) return false; // multicast
  if (prefix(const [0x20, 0x01, 0x0d, 0xb8])) return false; // documentation
  if (prefix(const [0x20, 0x01, 0, 0])) return false; // Teredo
  if (prefix(const [0x01, 0, 0, 0, 0, 0, 0, 0])) return false; // discard
  // Only global unicast 2000::/3 is public.
  return (first & 0xe0) == 0x20;
}

bool _publicIPv4(List<int> b) {
  if (b.length != 4) return false;
  final a = b[0];
  final second = b[1];
  return !(a == 0 ||
      a == 10 ||
      a == 127 ||
      (a == 100 && second >= 64 && second <= 127) ||
      (a == 169 && second == 254) ||
      (a == 172 && second >= 16 && second <= 31) ||
      (a == 192 && second == 0 && b[2] == 0) ||
      (a == 192 && second == 0 && b[2] == 2) ||
      (a == 192 && second == 168) ||
      (a == 198 && (second == 18 || second == 19)) ||
      (a == 198 && second == 51 && b[2] == 100) ||
      (a == 203 && second == 0 && b[2] == 113) ||
      a >= 224);
}

const _privateSuffixes = [
  '.localhost',
  '.local',
  '.internal',
  '.intranet',
  '.lan',
  '.home',
  '.corp',
  '.private',
  '.localdomain',
  '.home.arpa',
  '.in-addr.arpa',
  '.ip6.arpa',
];

AppPlatformException _invalid(String message) => AppPlatformException(
  problem: AppPlatformProblem.invalidWebhookUrl,
  message: message,
);
