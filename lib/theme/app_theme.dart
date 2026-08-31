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
  static const Color successGreenDark = Color(0xFF0E7A4E);
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
  static const Color purpleSoft = Color(0xFFF0EAFF);
  static const Color pinkSoft = Color(0xFFFFE8EC);
  static const Color cyanSoft = Color(0xFFE6F7FF);
  static const Color deepNavy = Color(0xFF0B1220);
  static const Color cardShadow = Color(0x1A000000);
  
  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [safetyBlue, Color(0xFF1D4ED8)],
  );
  
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [successGreen, Color(0xFF059669)],
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [alertOrange, Color(0xFFD97706)],
  );
  
  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [errorRed, Color(0xFFB91C1C)],
  );
  
  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
  );
  
  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
  );
  
  static const LinearGradient oceanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
  );
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
      displayLarge: GoogleFonts.sora(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: primaryText,
      ),
      displayMedium: GoogleFonts.sora(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: primaryText,
      ),
      displaySmall: GoogleFonts.sora(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: primaryText,
      ),
      headlineLarge: GoogleFonts.sora(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: primaryText,
      ),
      headlineMedium: GoogleFonts.sora(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      headlineSmall: GoogleFonts.sora(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      titleLarge: GoogleFonts.sora(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      titleMedium: GoogleFonts.sora(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      titleSmall: GoogleFonts.sora(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        color: primaryText,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: primaryText,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        color: secondaryText,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: secondaryText,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: secondaryText,
      ),
    );
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final background = dark ? AppColors.deepNavy : AppColors.surfaceGray;
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
        titleTextStyle: GoogleFonts.sora(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLow,
        hintStyle: GoogleFonts.inter(color: muted, fontSize: 13),
        labelStyle: GoogleFonts.inter(color: muted, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.safetyBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.safetyBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: dark ? const Color(0xFFD9E7FF) : AppColors.safetyBlue,
          side: BorderSide(
            color: dark ? const Color(0xFF355071) : AppColors.outlineVariant,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.safetyBlue,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLow,
        selectedColor: dark ? const Color(0xFF163A78) : AppColors.primaryContainer,
        side: BorderSide(color: border),
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
        ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
          ? [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.05,
                ),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ]
          : [],
    );
  }

  static BoxDecoration glassDecoration({
    double borderRadius = 14,
    Color opacityColor = Colors.white,
    double opacity = 0.85,
  }) {
    return BoxDecoration(
      color: opacityColor.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: AppColors.outlineVariant),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.safetyBlue, Color(0xFF1D4ED8)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.successGreen, Color(0xFF059669)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.alertOrange, Color(0xFFD97706)],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.errorRed, Color(0xFFB91C1C)],
  );

  static BoxDecoration gradientCard({
    List<Color> colors = const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    double borderRadius = 14,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: colors.first.withValues(alpha: 0.3),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration shimmerDecoration({
    double borderRadius = 14,
  }) {
    return BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }

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

  // Status chip styles
  static BoxDecoration statusChipDecoration(Color color, {bool isDark = false}) {
    return BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: color.withValues(alpha: 0.2),
        width: 1,
      ),
    );
  }

  // Status text styles
  static TextStyle statusTextStyle(Color color, {bool isDark = false}) {
    return GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: 0.2,
    );
  }

  // KPI card style
  static BoxDecoration kpiCardDecoration(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: scheme.outlineVariant,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Empty state style
  static BoxDecoration emptyStateDecoration(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        width: 2,
        style: BorderStyle.solid,
      ),
    );
  }
}

// ============================================================
// RESPONSIVE UTILITIES
// ============================================================

/// Extension for responsive sizing and device detection
extension ResponsiveUtils on BuildContext {
  // Device type detection
  bool get isMobile => MediaQuery.sizeOf(this).width < 600;
  bool get isTablet =>
      MediaQuery.sizeOf(this).width >= 600 &&
      MediaQuery.sizeOf(this).width < 1200;
  bool get isDesktop => MediaQuery.sizeOf(this).width >= 1200;

  // Screen dimensions
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  // Safe area padding
  EdgeInsets get safePadding => MediaQuery.paddingOf(this);

  // Dynamic spacing based on screen size
  double get cardSpacing => isMobile ? 8 : 12;
  double get sectionSpacing => isMobile ? 12 : 16;
  double get largeSpacing => isMobile ? 16 : 24;
  double get extraLargeSpacing => isMobile ? 24 : 32;

  // Dynamic padding
  EdgeInsets get screenPadding => EdgeInsets.all(
        isMobile ? 16 : isTablet ? 24 : 32,
      );

  EdgeInsets get horizontalPadding => EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : isTablet ? 24 : 32,
      );

  EdgeInsets get verticalPadding => EdgeInsets.symmetric(
        vertical: isMobile ? 12 : isTablet ? 16 : 24,
      );

  // Dynamic font sizes
  double get headlineSize => isMobile ? 22 : isTablet ? 26 : 32;
  double get titleSize => isMobile ? 18 : isTablet ? 20 : 24;
  double get bodySize => isMobile ? 14 : isTablet ? 15 : 16;
  double get labelSize => isMobile ? 12 : isTablet ? 13 : 14;

  // Dynamic icon sizes
  double get iconSizeSmall => isMobile ? 16 : 18;
  double get iconSizeMedium => isMobile ? 20 : 22;
  double get iconSizeLarge => isMobile ? 24 : 28;

  // Dynamic card radius
  double get cardRadius => isMobile ? 12 : 14;
  double get largeCardRadius => isMobile ? 16 : 20;

  // Dynamic button sizes
  double get buttonHeight => isMobile ? 48 : 52;
  double get buttonPadding => isMobile ? 14 : 18;

  // Grid columns based on screen width
  int get gridColumns {
    if (isDesktop) return 4;
    if (isTablet) return 3;
    return 2;
  }

  // Max content width for readability
  double get maxContentWidth => isDesktop ? 1280 : double.infinity;

  // Responsive value
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }

  // Responsive font size
  double responsiveFontSize({
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }
}

// ============================================================
// ANIMATION CONSTANTS
// ============================================================

class AppAnimations {
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration long = Duration(milliseconds: 600);
  static const Duration extraLong = Duration(milliseconds: 800);

  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve springCurve = Curves.easeOutBack;
  static const Curve bounceCurve = Curves.bounceOut;

  static Tween<double> fadeIn = Tween<double>(begin: 0.0, end: 1.0);
  static Tween<Offset> slideUp = Tween<Offset>(
    begin: Offset(0, 0.04),
    end: Offset.zero,
  );
  static Tween<Offset> slideRight = Tween<Offset>(
    begin: Offset(0.04, 0),
    end: Offset.zero,
  );
}

// ============================================================
// SPACING CONSTANTS
// ============================================================

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  static const EdgeInsets zero = EdgeInsets.zero;
  static const EdgeInsets xsPadding = EdgeInsets.all(xs);
  static const EdgeInsets smPadding = EdgeInsets.all(sm);
  static const EdgeInsets mdPadding = EdgeInsets.all(md);
  static const EdgeInsets lgPadding = EdgeInsets.all(lg);
  static const EdgeInsets xlPadding = EdgeInsets.all(xl);

  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: xl);
}

// ============================================================
// TEXT STYLES HELPER
// ============================================================

class AppTextStyles {
  static TextStyle get headline => GoogleFonts.sora(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      );

  static TextStyle get title => GoogleFonts.sora(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get subtitle => GoogleFonts.sora(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get bodyBold => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      );
}