import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color safetyBlue = Color(0xFF1A4F95);
  static const Color primaryDark = Color(0xFF003874);
  static const Color alertOrange = Color(0xFFFF7A00);
  static const Color alertOrangeDark = Color(0xFF994700);
  static const Color successGreen = Color(0xFF2D8A29);
  static const Color surfaceGray = Color(0xFFF4F7F9);
  static const Color textMain = Color(0xFF121C2D);
  static const Color outlineVariant = Color(0xFFC3C6D2);
  static const Color outline = Color(0xFF737782);
  static const Color surfaceContainerLow = Color(0xFFF1F4F6);
  static const Color surfaceContainer = Color(0xFFEBEEF0);
  static const Color surfaceContainerHigh = Color(0xFFE5E9EB);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E5);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color onSurfaceVariant = Color(0xFF424751);
  static const Color errorRed = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color primaryContainer = Color(0xFF1A4F95);
  static const Color onPrimaryContainer = Color(0xFFA3C3FF);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.surfaceGray,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.safetyBlue,
        primary: AppColors.safetyBlue,
        secondary: AppColors.alertOrange,
        surface: AppColors.surfaceContainerLowest,
        background: AppColors.surfaceGray,
        error: AppColors.errorRed,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.manrope(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textMain,
        ),
        headlineLarge: GoogleFonts.manrope(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.safetyBlue,
        ),
        headlineMedium: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
        ),
        headlineSmall: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textMain,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textMain,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: AppColors.onSurfaceVariant,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.safetyBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static BoxDecoration glassDecoration({
    double borderRadius = 16.0,
    Color opacityColor = Colors.white,
    double opacity = 0.85,
  }) {
    return BoxDecoration(
      color: opacityColor.withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.5),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.safetyBlue.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
