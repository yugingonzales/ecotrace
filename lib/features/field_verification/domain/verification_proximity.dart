import 'package:geolocator/geolocator.dart';

/// Why a proximity check could not produce a distance.
///
/// Every failure is a distinct state rather than a boolean so the UI can tell
/// the officer what to actually fix — "GPS is off" and "permission denied"
/// need different actions, and collapsing them into "no" would leave a field
/// officer stranded with no next step.
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
/// An interface rather than a direct `Geolocator` call so the gate can be
/// exercised in tests without a GPS fix, and so a future "verify from a
/// distance" mode does not require rewriting the check itself.
abstract class PositionSource {
  Future<ProximityResult> distanceTo({required double lat, required double lng});
}

class GeolocatorPositionSource implements PositionSource {
  GeolocatorPositionSource({
    this.fixTimeout = const Duration(seconds: 15),
  });

  /// A field officer under canopy can take a while to get a fix; the timeout
  /// must exceed the typical cold-start time or the check fails for everyone
  /// standing exactly at the tree.
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
      // A timeout or a missing fix. Surfaced as its own state rather than
      // "out of range": the officer may be standing at the tree and still be
      // refused, which reads as a broken app unless it says what went wrong.
      return const ProximityResult.failed(ProximityFailure.fixUnavailable);
    }
  }
}

/// The rule that decides whether a verification may start.
class VerificationProximity {
  const VerificationProximity._();

  /// TEMPORARY TEST BYPASS — set to `true` to put the proximity gate back.
  ///
  /// Switched off on 2026-09-29 so the verification interface can be exercised
  /// indoors, on a desk, or on a device with no location fix. While it is
  /// `false` the officer skips the gate and lands straight in the wizard.
  ///
  /// Mutable rather than `const` on purpose. The gate's own tests have to be
  /// able to switch it back on, or deleting this flag would quietly delete the
  /// only proof that the gate works — and a flag nobody can test is a flag
  /// nobody trusts. Tests set it in `setUp` and restore it in `tearDown`.
  ///
  /// This is a data-integrity rule, not a formality: a DBH reading taken from
  /// across the quad is not a measurement of that tree. It must go back to
  /// `true` before this is used to record real field data — a record captured
  /// without the gate has no verified position behind it, and
  /// [TreeRecord.distanceFromTreeMeters] is null rather than proof of arrival.
  static bool enforcementEnabled = false;

  /// A plant's recorded position is only meaningful to about a metre or two,
  /// so the officer must be standing at it. Exceeding this is not a
  /// formality — a DBH reading taken from across the quad is not a
  /// measurement of that tree.
  ///
  /// Raised from 5 m to 10 m on 2026-09-29. Ten metres is roughly the width of
  /// the planting strip around each tree, so an officer standing beside the
  /// plant is inside the radius even when the phone's fix is slightly off.
  static const double maxDistanceMeters = 10.0;

  /// Hard ceiling on how far a bad fix may widen the allowance. Beyond this
  /// the reading is too coarse to stand behind and the officer is told to try
  /// again in the open.
  static const double maxAccuracyToleranceMeters = 30.0;

  /// Within range when the distance fits inside the allowance, the allowance
  /// being the radius widened by the fix's own reported error.
  ///
  /// A single GPS sample outdoors is routinely several metres out, so a hard
  /// cut-off would refuse officers standing directly on the tree and would be
  /// quietly defeated by anyone who ignored the warning. Widening by the
  /// reported accuracy is honest in both directions: it admits the officer
  /// when the device itself is unsure, and [maxAccuracyToleranceMeters] stops
  /// that concession becoming an unlimited loophole.
  static bool isAcceptable({
    required double meters,
    required double accuracy,
  }) {
    final allowance = maxDistanceMeters + accuracy;
    return meters <= allowance && accuracy <= maxAccuracyToleranceMeters;
  }
}
