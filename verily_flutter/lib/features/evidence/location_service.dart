import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// One position reading.
@immutable
class LocationFix {
  const LocationFix({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.capturedAt,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime capturedAt;
}

/// Why a position could not be read, in terms the screen can explain.
enum LocationFailure {
  /// Location services are switched off on the device.
  servicesOff,

  /// The person declined this time; asking again is allowed.
  denied,

  /// The person declined permanently; only system settings can change it.
  deniedForever,

  /// No reading arrived in time.
  timedOut,
}

class LocationException implements Exception {
  const LocationException(this.failure);

  final LocationFailure failure;

  @override
  String toString() => 'LocationException(${failure.name})';
}

/// Reads the device position.
abstract interface class LocationService {
  /// A coarse reading for finding nearby actions. Never stored by the server.
  Future<LocationFix> approximatePosition();

  /// A precise, fresh reading for proving you are at an action's place.
  Future<LocationFix> precisePosition();

  /// Opens the system settings page where location can be turned back on.
  Future<void> openSettings();
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<LocationFix> approximatePosition() =>
      _read(LocationAccuracy.low, const Duration(seconds: 15));

  @override
  Future<LocationFix> precisePosition() =>
      _read(LocationAccuracy.high, const Duration(seconds: 20));

  @override
  Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<LocationFix> _read(LocationAccuracy accuracy, Duration limit) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(LocationFailure.servicesOff);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    switch (permission) {
      case LocationPermission.denied:
        throw const LocationException(LocationFailure.denied);
      case LocationPermission.deniedForever:
        throw const LocationException(LocationFailure.deniedForever);
      case LocationPermission.whileInUse ||
          LocationPermission.always ||
          LocationPermission.unableToDetermine:
        break;
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: limit,
        ),
      );
      return LocationFix(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        capturedAt: position.timestamp.toUtc(),
      );
    } on TimeoutException {
      throw const LocationException(LocationFailure.timedOut);
    }
  }
}
