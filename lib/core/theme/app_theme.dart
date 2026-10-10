import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Modern Palette
  static const Color primaryDark = Color(0xFF1A1A2E); // Deep Navy
  static const Color primaryLight = Color(0xFF16213E); // Lighter Navy
  static const Color accentGold = Color(0xFFFFD700); // Gold
  static const Color accentPurple = Color(0xFFE94560); // Vibrant Pink/Red
  static const Color glassWhite = Color(0x1FFFFFFF); // Transparent White

  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
  );

  static ThemeData get modernTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.transparent, // Important for gradients
      primaryColor: primaryDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        secondary: accentGold,
        surface: Colors.transparent,
        onSurface: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xCC1A1A2E), // Semi-transparent
        selectedItemColor: accentGold,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      textTheme: GoogleFonts.cairoTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: Colors.white, displayColor: Colors.white),
    );
  }

  static TextStyle get quranTextStyle {
    return GoogleFonts.amiri(
      fontSize: 24,
      height: 2.0,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
  }
}
