import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Core palette
  static const Color primary = Color(0xFF4F46E5);       // Indigo — modern, less boring
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  // Feature colors
  static const Color anonPurple = Color(0xFF7C3AED);
  static const Color anonPurpleDark = Color(0xFF4C1D95);
  static const Color teal = Color(0xFF0D9488);
  static const Color tealLight = Color(0xFF99F6E4);
  static const Color coral = Color(0xFFF43F5E);
  static const Color amber = Color(0xFFF59E0B);
  static const Color emerald = Color(0xFF10B981);

  static const Color inputBg = Color(0xFFF1F5F9);
  static const Color cardBorder = Color(0xFFE2E8F0);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient ghostGradient = LinearGradient(
    colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8)),
  ];

  static List<BoxShadow> softShadow = [
    const BoxShadow(color: Color(0x0C000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w800, fontSize: 40, letterSpacing: -1.5, height: 1.1),
        displayMedium: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w800, fontSize: 32, letterSpacing: -1, height: 1.15),
        displaySmall: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w800, fontSize: 26, letterSpacing: -0.5),
        headlineMedium: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 18),
        titleMedium: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
        bodyLarge: GoogleFonts.inter(color: textPrimary, fontSize: 16, height: 1.5),
        bodyMedium: GoogleFonts.inter(color: textSecondary, fontSize: 14, height: 1.5),
        labelLarge: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.5),
      ),
      colorScheme: const ColorScheme.light(
        primary: primary,
        surface: surface,
        secondary: anonPurple,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 18),
          elevation: 0,
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBg,
        hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 18),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
    );
  }
}
