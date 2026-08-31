import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Semantic colors intentionally remain stable so existing business logic and
/// status widgets keep their meaning. Surfaces/text are resolved from the
/// active ThemeData so the same UI supports Day and Dark modes.
class AppColors {
  static const Color safetyBlue = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF17324D);
  static const Color alertOrange = Color(0xFFF59E0B);
  static const Color alertOrangeDark = Color(0xFFB45309);
  static const Color successGreen = Color(0xFF16A34A);
  static const Color surfaceGray = Color(0xFFF6F8FB);
  static const Color textMain = Color(0xFF17324D);
  static const Color outlineVariant = Color(0xFFD8E0EA);
  static const Color outline = Color(0xFF718096);
  static const Color surfaceContainerLow = Color(0xFFF1F5F9);
  static const Color surfaceContainer = Color(0xFFE8EEF5);
  static const Color surfaceContainerHigh = Color(0xFFDDE6F0);
  static const Color surfaceContainerHighest = Color(0xFFD2DCE8);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color onSurfaceVariant = Color(0xFF64748B);
  static const Color errorRed = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color primaryContainer = Color(0xFFDCE8FF);
  static const Color onPrimaryContainer = Color(0xFF123B85);
  static const Color trackComplete = Color(0xFF2563EB);
  static const Color trackPending = Color(0xFFD8E0EA);
  static const Color mintSoft = Color(0xFFDDF7E8);
  static const Color amberSoft = Color(0xFFFFF0C7);
}

class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }

  void toggle() => setMode(isDark ? ThemeMode.light : ThemeMode.dark);
}

class AppTheme {
  static TextTheme _textTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primaryText = isDark ? const Color(0xFFF1F5F9) : AppColors.textMain;
    final secondaryText = isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant;

    return TextTheme(
      displayLarge: GoogleFonts.sora(fontSize: 24, fontWeight: FontWeight.bold, color: primaryText),
      headlineLarge: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.bold, color: primaryText),
      headlineMedium: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w600, color: primaryText),
      headlineSmall: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w600, color: primaryText),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: primaryText),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: primaryText),
      bodySmall: GoogleFonts.inter(fontSize: 12, color: secondaryText),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.2, color: secondaryText),
      labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: secondaryText),
    );
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final background = dark ? const Color(0xFF0B1220) : AppColors.surfaceGray;
    final surface = dark ? const Color(0xFF111B2B) : Colors.white;
    final surfaceLow = dark ? const Color(0xFF0F1928) : const Color(0xFFF1F5F9);
    final surfaceHigh = dark ? const Color(0xFF1A2638) : const Color(0xFFE8EEF5);
    final border = dark ? const Color(0xFF26364D) : AppColors.outlineVariant;
    final text = dark ? const Color(0xFFF1F5F9) : AppColors.textMain;
    final muted = dark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.safetyBlue,
      brightness: brightness,
      primary: AppColors.safetyBlue,
      surface: surface,
      onSurface: text,
      onSurfaceVariant: muted,
      outline: dark ? const Color(0xFF475569) : AppColors.outline,
      outlineVariant: border,
      error: AppColors.errorRed,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: _textTheme(brightness),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: text),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: border)),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLow,
        hintStyle: GoogleFonts.inter(color: muted, fontSize: 13),
        labelStyle: GoogleFonts.inter(color: muted, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.safetyBlue, width: 1.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.safetyBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: dark ? const Color(0xFFD9E7FF) : AppColors.safetyBlue,
          side: BorderSide(color: dark ? const Color(0xFF355071) : AppColors.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.safetyBlue),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLow,
        selectedColor: dark ? const Color(0xFF163A78) : AppColors.primaryContainer,
        side: BorderSide(color: border),
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: text),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.safetyBlue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? const Color(0xFF1E293B) : const Color(0xFF17324D),
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static BoxDecoration panelDecoration(
    BuildContext context, {
    double borderRadius = 14,
    bool elevated = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: scheme.outlineVariant),
      boxShadow: elevated
          ? [BoxShadow(color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.05), blurRadius: 14, offset: const Offset(0, 5))]
          : const [],
    );
  }

  // Kept for compatibility with existing screens; visually simplified.
  static BoxDecoration glassDecoration({double borderRadius = 14, Color opacityColor = Colors.white, double opacity = 0.85}) {
    return BoxDecoration(
      color: opacityColor.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: AppColors.outlineVariant),
    );
  }

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.safetyBlue, Color(0xFF1D4ED8)],
  );

  static TextStyle tabularTime({double fontSize = 24, Color color = AppColors.primaryDark, FontWeight weight = FontWeight.w700}) {
    return GoogleFonts.sora(fontSize: fontSize, fontWeight: weight, color: color, letterSpacing: -0.5, fontFeatures: const [FontFeature.tabularFigures()]);
  }
}
