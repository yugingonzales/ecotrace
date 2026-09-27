/// Validation bounds for the manual measurement fields.
///
/// The maxima are not arbitrary. The largest recorded dicot trunk in the
/// Philippines is a few metres across, so 500 cm leaves generous headroom
/// while still catching a mistyped `450` for `45.0` — a ten-fold error is the
/// common failure when entering a number on a phone in the rain.
class MeasurementLimits {
  const MeasurementLimits._();

  static const double maxDbhCm = 500;
  static const double maxCrownCm = 3000;

  /// Crown is entered in metres by field staff because that is how canopy
  /// spread is estimated on the ground, then stored in centimetres so both
  /// measurements share a unit.
  static const double metresToCentimetres = 100;
}
