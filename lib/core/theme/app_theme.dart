// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AppTheme {
  static const Color braaiCharcoalDark = Color(0xFF0F0F0F);
  static const Color braaiCoalSurface = Color(0xFF1A1A1A);
  static const Color braaiFireOrange = Color(0xFFF97316);
  static const Color braaiBasteGold = Color(0xFFF59E0B);
  static const Color softAshGray = Color(0xFFE2E2E2);
  static const Color emberGlowRed = Color(0xFFEF4444);
  static const Color whitePure = Color(0xFFFFFFFF);
  static const Color mutedSlate = Color(0x66E2E2E2);

  static const Color braaiWoodBrown = Color(0xFF5D4037);
  static const Color warmClaySand = Color(0xFFFFF3E0);
  static const Color claySurface = Color(0xFFFFE0B2);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: braaiFireOrange,
    scaffoldBackgroundColor: braaiCharcoalDark,
    
    colorScheme: ColorScheme.dark(
      primary: braaiFireOrange,
      secondary: braaiBasteGold,
      tertiary: emberGlowRed,
      surface: braaiCoalSurface,
      onPrimary: whitePure,
      onSecondary: braaiCharcoalDark,
      onTertiary: whitePure,
      onSurface: softAshGray,
      onSurfaceVariant: mutedSlate,
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        height: 1.5,
        letterSpacing: 0.5,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: whitePure,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: whitePure,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: softAshGray,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: mutedSlate,
      ),
    ),

    iconTheme: const IconThemeData(color: braaiFireOrange, size: 24),
    primaryIconTheme: const IconThemeData(color: whitePure),

    appBarTheme: const AppBarTheme(
      backgroundColor: braaiCoalSurface,
      elevation: 0,
      iconTheme: IconThemeData(color: whitePure),
      titleTextStyle: TextStyle(
        color: whitePure,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    cardTheme: const CardThemeData(
      color: braaiCoalSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      elevation: 4,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: braaiCoalSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: braaiFireOrange, width: 2),
      ),
      hintStyle: const TextStyle(color: mutedSlate),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}