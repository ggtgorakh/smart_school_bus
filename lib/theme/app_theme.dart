import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Token names are kept identical to the original theme so screens outside
/// this redesign (Driver / Admin views) keep compiling and simply inherit
/// the refreshed palette. Only the underlying values and a few additions
/// have changed.
class AppColors {
  // Primary — deepened into a "night transit" navy/signal-blue pair instead
  // of a flat Material blue, so it reads as a chosen brand color.
  static const Color safetyBlue = Color(0xFF2F6FED); // signal blue (primary)
  static const Color primaryDark = Color(0xFF0B2545); // midnight navy
  // Alerts — warm amber instead of a flat safety-orange.
  static const Color alertOrange = Color(0xFFF5A524);
  static const Color alertOrangeDark = Color(0xFFB9740A);
  // Confirmation — fresher mint instead of a muddy green.
  static const Color successGreen = Color(0xFF12B76A);
  static const Color surfaceGray = Color(0xFFF6F8FC);
  static const Color textMain = Color(0xFF0F1B2D);
  static const Color outlineVariant = Color(0xFFD6DCE8);
  static const Color outline = Color(0xFF7C8AA3);
  static const Color surfaceContainerLow = Color(0xFFF1F4FA);
  static const Color surfaceContainer = Color(0xFFEAEFF8);
  static const Color surfaceContainerHigh = Color(0xFFE2E8F4);
  static const Color surfaceContainerHighest = Color(0xFFD9E0F0);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color onSurfaceVariant = Color(0xFF4B5670);
  static const Color errorRed = Color(0xFFE23D3D);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color primaryContainer = Color(0xFF2F6FED);
  static const Color onPrimaryContainer = Color(0xFFCBDBFF);

  // New tokens for the route-track signature motif and depth accents.
  static const Color trackComplete = Color(0xFF2F6FED);
  static const Color trackPending = Color(0xFFD6DCE8);
  static const Color mintSoft = Color(0xFFD4F5E4);
  static const Color amberSoft = Color(0xFFFDECC9);
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
        // Using surface token for background surfaces; 'background' was deprecated.
        surface: AppColors.surfaceGray,
        error: AppColors.errorRed,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.sora(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textMain,
        ),
        headlineLarge: GoogleFonts.sora(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.safetyBlue,
        ),
        headlineMedium: GoogleFonts.sora(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
        ),
        headlineSmall: GoogleFonts.sora(
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
      color: opacityColor.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.6),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primaryDark.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// Brand gradient used sparingly — the bus marker halo, the primary CTA,
  /// and the login mark. Not applied to large surfaces.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.safetyBlue, AppColors.primaryDark],
  );

  /// Tabular-figure style for live numbers (ETA, countdowns, times) so they
  /// read like a transit-board display rather than ordinary body text.
  static TextStyle tabularTime({
    double fontSize = 24,
    Color color = AppColors.primaryDark,
    FontWeight weight = FontWeight.w700,
  }) {
    return GoogleFonts.sora(
      fontSize: fontSize,
      fontWeight: weight,
      color: color,
      letterSpacing: -0.5,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
