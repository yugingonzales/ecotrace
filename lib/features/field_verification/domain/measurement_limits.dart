/// Validation bounds for the manual measurement fields.
///
/// The maxima are not arbitrary. The largest recorded dicot trunk in the
/// Philippines is a few metres across, so 500 cm leaves generous headroom
/// while still catching a mistyped `450` for `45.0` — a ten-fold error is the
/// common failure when entering a number on a phone in the rain.
///
/// Both fields are entered in centimetres. Crown dimension was previously
/// typed in metres and converted on the way in, which cost the officer a
/// mental conversion per reading and was the source of a units bug; a single
/// unit across the form is worth the extra digit.
class MeasurementLimits {
  const MeasurementLimits._();

  static const double maxDbhCm = 500;
  static const double maxCrownCm = 3000;
}
