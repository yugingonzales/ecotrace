import 'package:flutter/material.dart';

abstract final class EcoTraceColors {
  static const forest = Color(0xFF0D382C);
  static const forestDeep = Color(0xFF0B1F17);
  static const forestDark = Color(0xFF0A2A20);
  static const lemon = Color(0xFFFFD600);
  static const canvas = Color(0xFFF4F7F5);
  static const field = Color(0xFFFFFFFF);
  static const border = Color(0xFFE1E8E3);
  static const muted = Color(0xFF6B8277);
  static const softText = Color(0xFF8EB3A0);
  static const error = Color(0xFFC74545);
}

abstract final class EcoTraceTheme {
  static ThemeData get light {
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
