import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralized typography.
///
/// NOTE: Do not specify custom font families unless they are declared in
/// `pubspec.yaml`. These styles inherit the app's `ThemeData.fontFamily`
/// (currently `Segoe UI` in `AppTheme`).
class AppTextStyles {
  AppTextStyles._();

  // Headings
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.02 * 32,
    color: AppColors.onSurface,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.onSurface,
  );

  // Body
  static const TextStyle bodyLg = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.onSurface,
  );

  static const TextStyle bodyMd = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.onSurface,
  );

  // Labels
  static const TextStyle labelSm = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 0.05 * 12,
    color: AppColors.onSurfaceVariant,
  );
}

