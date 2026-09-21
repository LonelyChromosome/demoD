import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const primary = Color(0xFF12358B);
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF7F9FD),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      surface: Colors.white,
    ),
    fontFamily: 'Roboto',
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
  );
}
