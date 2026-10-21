import 'package:intl/intl.dart';

import 'package:verily_flutter/l10n/l10n.dart';

/// "350 m away" or "2.4 km away", rounded so it never suggests more
/// precision than an approximate position has.
String distanceText(AppLocalizations l10n, double meters) {
  if (meters < 1000) {
    final rounded = (meters / 10).round() * 10;
    return l10n.doDistanceMeters(rounded < 10 ? 10 : rounded);
  }
  final km = NumberFormat('#,##0.#', l10n.localeName).format(meters / 1000);
  return l10n.doDistanceKilometers(km);
}
