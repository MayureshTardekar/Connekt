import 'package:flutter/material.dart';

class AppColors {
  // Primary & Accent
  static const Color primary = Color(0xFF4F46E5); // Deep Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color accent = Color(0xFF10B981); // Emerald Green
  
  // Backgrounds & Surfaces
  static const Color background = Color(0xFFF9FAFB); // Light Gray background
  static const Color surface = Colors.white; // Card backgrounds
  static const Color surfaceElevated = Color(0xFFF3F4F6); // Inputs, subtle boxes

  // Text Colors
  static const Color textPrimary = Color(0xFF111827); // Near Black
  static const Color textSecondary = Color(0xFF6B7280); // Gray
  static const Color textHint = Color(0xFF9CA3AF); // Light Gray

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // 👻 Ghost Zone (Anonymous Theme Colors)
  static const Color ghostPrimary = Color(0xFF9333EA); // Vibrant Purple
  static const Color ghostBackground = Color(0xFFFDF4FF); // Very light fuchsia
  static const Color ghostSurface = Color(0xFFF3E8FF); // Light purple card

  // Dark Mode specific (Preparation for Phase 6)
  static const Color darkBackground = Color(0xFF111827);
  static const Color darkSurface = Color(0xFF1F2937);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFFD1D5DB);
}
