import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Lowercase hex SHA-256 of a trimmed, UTF-8 encoded secret.
///
/// Use only for high-entropy, server-generated secrets (venue codes, webhook
/// credentials, device tokens). A fast hash is appropriate there because the
/// input cannot be guessed; it is not a password hash.
String secretSha256Hex(String value) {
  return sha256.convert(utf8.encode(value.trim())).toString();
}

/// Compares two strings in time independent of where they first differ.
///
/// Length is not secret for the digests this guards, so unequal lengths
/// return early.
bool constantTimeEquals(String left, String right) {
  if (left.length != right.length) return false;
  var difference = 0;
  for (var index = 0; index < left.length; index += 1) {
    difference |= left.codeUnitAt(index) ^ right.codeUnitAt(index);
  }
  return difference == 0;
}
