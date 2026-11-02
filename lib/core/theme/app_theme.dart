import 'package:flutter/material.dart';

class AppTheme {
  static const brandPurple = Color(0xFF7A4FD0);
  static const brandPink = Color(0xFFE5397A);
  static const brandBlue = Color(0xFF3267ED);
  static const canvas = Color(0xFFF8F7FB);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF25212D);
  static const muted = Color(0xFF777181);
  static const line = Color(0xFFE8E3EF);

  static const brandGradient = LinearGradient(
    colors: [brandPink, brandPurple, brandBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandPurple,
        primary: brandPurple,
        secondary: brandPink,
        surface: surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: brandPurple, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandPurple,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
