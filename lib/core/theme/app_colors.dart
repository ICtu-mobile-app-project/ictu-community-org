import 'package:flutter/material.dart';

/// Centralized color tokens for the app.
///
/// Keep usage consistent by referencing [AppColors] instead of hardcoded colors
/// inside feature screens.
class AppColors {
  AppColors._();

  // Base surfaces
  static const Color background = Color(0xFF111318);
  static const Color surface = Color(0xFF111318);
  static const Color surfaceContainerLow = Color(0xFF1A1C20);
  static const Color surfaceContainer = Color(0xFF1E2024);
  static const Color surfaceContainerHigh = Color(0xFF282A2E);

  // Primary (brand orange)
  static const Color primary = Color(0xFFFFB786);
  static const Color primaryContainer = Color(0xFFF58220);

  // Secondary (accent blue)
  static const Color secondary = Color(0xFFADC6FF);
  static const Color secondaryContainer = Color(0xFF0566D9);

  // Text
  static const Color onSurface = Color(0xFFE2E2E8);
  static const Color onSurfaceVariant = Color(0xFFDDC1B0);

  // Error
  static const Color error = Color(0xFFFFB4AB);

  // Outlines
  static const Color outline = Color(0xFFA58C7D);

  // Utility
  static const Color topBarBg = Color(0xFF0A0C10);
}

