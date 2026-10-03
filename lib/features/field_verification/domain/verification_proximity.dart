import 'package:geolocator/geolocator.dart';

/// Why a proximity check could not produce a distance.
///
enum ProximityFailure {
  /// Device location services are switched off.
  locationServicesDisabled,

  /// The officer declined the location permission.
  permissionDenied,

  /// The permission is permanently denied; only Settings can restore it.
  permissionDeniedForever,

  /// A fix was requested but none arrived in time (indoors, poor signal).
  fixUnavailable,
}

class ProximityResult {
  const ProximityResult.withinRange(this.meters)
    : failure = null,
      isWithinRange = true;

  const ProximityResult.outOfRange(this.meters)
    : failure = null,
      isWithinRange = false;

  const ProximityResult.failed(this.failure)
    : meters = null,
      isWithinRange = false;

  /// Distance from the officer to the tree, or null when no fix was obtained.
  final double? meters;

  final bool isWithinRange;
  final ProximityFailure? failure;

  bool get isFailure => failure != null;
}

/// Supplies the device position to the proximity gate.
///
abstract class PositionSource {
  Future<ProximityResult> distanceTo({
    required double lat,
    required double lng,
  });
}

class GeolocatorPositionSource implements PositionSource {
  GeolocatorPositionSource({this.fixTimeout = const Duration(seconds: 15)});

  final Duration fixTimeout;

  @override
  Future<ProximityResult> distanceTo({
    required double lat,
    required double lng,
  }) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const ProximityResult.failed(
        ProximityFailure.locationServicesDisabled,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return const ProximityResult.failed(ProximityFailure.permissionDenied);
    }
    if (permission == LocationPermission.deniedForever) {
      return const ProximityResult.failed(
        ProximityFailure.permissionDeniedForever,
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: fixTimeout,
        ),
      );
      final meters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        lat,
        lng,
      );
      final acceptable = VerificationProximity.isAcceptable(
        meters: meters,
        accuracy: position.accuracy,
      );
      if (acceptable) {
        return ProximityResult.withinRange(meters);
      }
      return ProximityResult.outOfRange(meters);
    } on Object {
      return const ProximityResult.failed(ProximityFailure.fixUnavailable);
    }
  }
}

/// The rule that decides whether a verification may start.
class VerificationProximity {
  const VerificationProximity._();

  /// TEMPORARY TEST BYPASS — set to `true` to put the proximity gate back.
  static bool enforcementEnabled = false;

  ///
  static const double maxDistanceMeters = 10.0;

  static const double maxAccuracyToleranceMeters = 30.0;

  /// Within range when the distance fits inside the allowance, the allowance
  /// being the radius widened by the fix's own reported error.
  ///
  static bool isAcceptable({required double meters, required double accuracy}) {
    final allowance = maxDistanceMeters + accuracy;
    return meters <= allowance && accuracy <= maxAccuracyToleranceMeters;
  }
}
