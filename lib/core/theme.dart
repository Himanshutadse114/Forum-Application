import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CyberTheme {
  // Brand Palette Colors matching Cyber Arcade Elite 100%
  static const Color background = Color(0xFFFBFBF8); // Cream Off-White
  static const Color surface = Color(0xFFFFFFFF); // Clean White Cards
  static const Color surfaceLight = Color(0xFFF5F3F3); // Light Grey
  
  static const Color primary = Color(0xFFFF6B00); // Vibrant Arcade Orange
  static const Color secondary = Color(0xFF1A1C1C); // Deep Charcoal
  static const Color accent = Color(0xFFFF6B00); // Orange Highlights
  static const Color warning = Color(0xFFFFB300); // Warning Amber
  static const Color danger = Color(0xFFBA1A1A); // Threat Alert Red
  
  static const Color textPrimary = Color(0xFF1B1C1C); // Deep Charcoal Text
  static const Color textSecondary = Color(0xFF5A4136); // Soft Brown/Cream Text
  static const Color textMuted = Color(0xFF989999); // Light Grey Muted Text

  static ThemeData get darkTheme { // Keeps the same name to avoid breaking imports
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: background,
        error: danger,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // ROUND_TWELVE matching Stitch design
          side: const BorderSide(color: Color(0xFFEFEDED), width: 1.5),
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 32, 
          fontWeight: FontWeight.bold, 
          color: primary,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 20, 
          fontWeight: FontWeight.bold, 
          color: textPrimary,
          letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.spaceGrotesk(
          fontSize: 16, 
          fontWeight: FontWeight.w600, 
          color: primary,
        ),
        bodyLarge: const TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: const TextStyle(color: textSecondary, fontSize: 14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: textMuted),
        labelStyle: const TextStyle(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(99), // Fully rounded pill inputs
          borderSide: const BorderSide(color: Color(0xFFEFEDED), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(99),
          borderSide: const BorderSide(color: Color(0xFFEFEDED), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(99),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(99),
          borderSide: const BorderSide(color: danger, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(99), // Pill buttons
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          elevation: 4,
        ),
      ),
    );
  }

  // Skeuomorphic tactile shadow / glow matching Stitch design system
  static BoxDecoration neonGlowDecoration({
    Color color = primary,
    double blurRadius = 8.0,
    double borderRadius = 24.0,
  }) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: color.withOpacity(0.15), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.08),
          blurRadius: blurRadius,
          offset: const Offset(0, 4),
          spreadRadius: 1,
        ),
      ],
    );
  }
}
