import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AmoraTheme {
  // Color Palette
  static const Color sunsetRose = Color(0xFFE91E63);
  static const Color deepLavender = Color(0xFF9C27B0);
  static const Color warmGold = Color(0xFFFFB300);
  static const Color sunsetOrange = Color(0xFFFF6B35);
  static const Color softLavender = Color(0xFFE1BEE7);
  static const Color offWhite = Color(0xFFF9F9F9);
  static const Color deepMidnight = Color(0xFF1A1A2E);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [sunsetRose, deepLavender],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [sunsetOrange, warmGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [offWhite, Color(0xFFFFF3E0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: sunsetRose,
      brightness: Brightness.light,
      primary: sunsetRose,
      secondary: warmGold,
      surface: offWhite,
      background: offWhite,
    ),
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: deepMidnight,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: deepMidnight,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        color: deepMidnight.withOpacity(0.8),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      color: Colors.white.withOpacity(0.9),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: sunsetRose,
      brightness: Brightness.dark,
      primary: sunsetRose,
      secondary: warmGold,
      surface: deepMidnight,
      background: deepMidnight,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        color: Colors.white.withOpacity(0.8),
      ),
    ),
  );

  // Glassmorphism Box Decoration
  static BoxDecoration glassmorphism({
    Color? color,
    double borderRadius = 24,
    double blur = 10,
  }) {
    return BoxDecoration(
      color: (color ?? Colors.white).withOpacity(0.1),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: blur,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Soft Shadow
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}