import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF007BFF);
  static const Color secondaryBlue = Color(0xFF4CA8FF);
  static const Color darkGray = Color(0xFF333333);
  static const Color lightBlue = Color(0xFFE6F0FF);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color successGreen = Color(0xFF43A047);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color lightGray = Color(0xFFEEEEEE);

  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textTheme: TextTheme(
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: darkGray,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        color: darkGray,
      ),
    ),
    colorScheme: ColorScheme.light(
      primary: primaryBlue,
      secondary: secondaryBlue,
      error: errorRed,
      surface: Colors.white,
      onSurface: darkGray,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: Color(0xFF121212),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textTheme: TextTheme(
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        color: Colors.white70,
      ),
    ),
    colorScheme: ColorScheme.dark(
      primary: primaryBlue,
      secondary: secondaryBlue,
      error: errorRed,
      surface: Color(0xFF1E1E1E),
      onSurface: Colors.white70,
    ),
  );
}