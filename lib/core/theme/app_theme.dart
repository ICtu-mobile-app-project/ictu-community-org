import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get dark => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryContainer,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Segoe UI',
    useMaterial3: true,
  );
}
