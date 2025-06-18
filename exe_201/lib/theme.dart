import 'package:flutter/material.dart';

ThemeData appTheme() {
  return ThemeData(
    primaryColor: const Color(0xFFF8BBD0), // Soft pink
    scaffoldBackgroundColor: const Color(0xFFFFF8F8), // Creamy white
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFF8BBD0), // Soft pink
      secondary: Color.fromARGB(255, 3, 220, 248), // Light cyan
      surface: Color(0xFFFFFFFF), // White for cards
      onPrimary: Colors.black87,
      onSecondary: Colors.black87,
      error: Colors.redAccent,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        fontFamily: 'Poppins',
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
        fontFamily: 'Poppins',
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: Colors.black54,
        fontFamily: 'Poppins',
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
        fontFamily: 'Poppins',
      ),
    ),
    cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
  ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFF8F8),
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        fontFamily: 'Poppins',
      ),
      iconTheme: IconThemeData(color: Color.fromARGB(255, 13, 216, 243)), // Light cyan
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color.fromARGB(255, 249, 95, 147), // Vibrant pink
      foregroundColor: Colors.white,
      shape: CircleBorder(),
      elevation: 4,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF8BBD0),
        foregroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFF8BBD0),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color.fromARGB(255, 238, 87, 140),
      contentTextStyle: const TextStyle(
        color: Colors.black87,
        fontFamily: 'Poppins',
        fontSize: 14,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
        fontFamily: 'Poppins',
      ),
      contentTextStyle: const TextStyle(
        fontSize: 14,
        color: Colors.black54,
        fontFamily: 'Poppins',
      ),
    ),
  );
}