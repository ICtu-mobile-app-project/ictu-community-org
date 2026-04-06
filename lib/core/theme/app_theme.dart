import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get dark => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFF59E0B),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF050913),
    fontFamily: 'Segoe UI',
    useMaterial3: true,
  );
}
