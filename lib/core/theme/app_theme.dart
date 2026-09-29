import 'package:flutter/material.dart';

abstract final class EcoTraceColors {
  static const forest = Color(0xFF0D382C);
  static const forestDeep = Color(0xFF0B1F17);
  static const forestDark = Color(0xFF0A2A20);
  static const canopy = Color(0xFF03461F);
  static const leaf = Color(0xFFB5EA87);
  static const leafDeep = Color(0xFF9CDD6E);
  static const lemon = Color(0xFFFFD600);
  static const canvas = Color(0xFFF4F7F5);
  static const field = Color(0xFFFFFFFF);
  static const border = Color(0xFFE1E8E3);
  static const muted = Color(0xFF6B8277);
  static const softText = Color(0xFF8EB3A0);
  static const error = Color(0xFFC74545);
}

/// Shared metrics for the four top-of-tab headers: Events, Alerts, Profile and
/// the field-progress dashboard.
///
/// The Map tab is deliberately NOT a member of this family. It has no header
/// block and no `SafeArea` at all; its header is a floating pill pinned by a
/// `Positioned` in `map_screen.dart`. So this constant is what keeps the four
/// *banded* headers level with each other, and the map is aligned separately.
abstract final class EcoTraceHeader {
  /// Gap between the status bar and the header's first row.
  ///
  /// Reduced 16 → 8 → 2 → 0 across 2026-09-29. The original 16 was on top of
  /// the ~24dp status-bar inset that `SafeArea` already contributes, so on a
  /// real device the logo sat 40px below the top of the screen and the header
  /// read as two separate blocks with a band of empty green between them.
  /// 0 was chosen by the user after seeing 2 rendered on a device: `SafeArea`
  /// already stops the row overlapping the status bar, so the extra gap bought
  /// nothing but air.
  ///
  /// Measured, not assumed: a probe against `AlertsScreen` reported the logo
  /// top at exactly `inset + topPadding` (0→8, 24→32, 28→36, 40→48), which
  /// confirms `SafeArea` is applied once and this value is the only gap.
  ///
  /// Held here rather than repeated in each screen because the value was
  /// written out four times and had already drifted — 16 on three screens, 12
  /// on the dashboard — which is how a set of headers ends up misaligned.
  static const double topPadding = 0;
}

abstract final class EcoTraceTheme {
  /// Single shared light theme instance (built once, immutable thereafter).
  static final ThemeData light = _buildLight();

  static ThemeData _buildLight() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: EcoTraceColors.canvas,
      colorScheme: base.colorScheme.copyWith(
        primary: EcoTraceColors.forest,
        onPrimary: Colors.white,
        secondary: EcoTraceColors.lemon,
        surface: EcoTraceColors.canvas,
        error: EcoTraceColors.error,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: EcoTraceColors.field,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EcoTraceColors.border, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EcoTraceColors.border, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EcoTraceColors.forest, width: 2),
        ),
        hintStyle: const TextStyle(color: Color(0xFFA3B5AB), fontSize: 14),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: const Color(0xFF0A231C),
        displayColor: const Color(0xFF0A231C),
      ),
    );
  }
}
