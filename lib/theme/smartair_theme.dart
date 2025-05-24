import 'package:flutter/material.dart';

class SmartAirColors {
  static const Color primary = Color(0xFF3971FF);
  static const Color primaryDark = Color(0xFF0D1A4F);
  static const Color primaryLight = Color(0xFF4FC3F7);
  static const Color accent = Color(0xFF2241C6);
  static const Color background = Color(0xFFF5F7FB);
  static const Color card = Colors.white;
  static const Color error = Color(0xFFFF5252);
}

final ThemeData smartAirTheme = ThemeData(
  primaryColor: SmartAirColors.primary,
  scaffoldBackgroundColor: SmartAirColors.background,
  fontFamily: 'SUIT',
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'SUIT',
      fontWeight: FontWeight.bold,
      fontSize: 32,
    ),
    displayMedium: TextStyle(
      fontFamily: 'SUIT',
      fontWeight: FontWeight.w600,
      fontSize: 24,
    ),
    titleLarge: TextStyle(
      fontFamily: 'SUIT',
      fontWeight: FontWeight.bold,
      fontSize: 20,
    ),
    titleMedium: TextStyle(
      fontFamily: 'SUIT',
      fontWeight: FontWeight.w500,
      fontSize: 16,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'SUIT',
      fontWeight: FontWeight.w400,
      fontSize: 16,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'SUIT',
      fontWeight: FontWeight.w400,
      fontSize: 14,
    ),
    labelLarge: TextStyle(
      fontFamily: 'SUIT',
      fontWeight: FontWeight.w500,
      fontSize: 14,
    ),
  ),
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors.blue,
    accentColor: SmartAirColors.accent,
    backgroundColor: SmartAirColors.background,
    errorColor: SmartAirColors.error,
  ).copyWith(
    primary: SmartAirColors.primary,
    secondary: SmartAirColors.accent,
    surface: SmartAirColors.background,
    error: SmartAirColors.error,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: SmartAirColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(
        fontFamily: 'SUIT',
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
  ),
  cardTheme: const CardTheme(
    color: SmartAirColors.card,
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(24)),
    ),
  ),
);
