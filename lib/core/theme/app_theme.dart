import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 2026 Modern Light Theme - Fresh, Clean, Professional
/// No dark mode cliches - this is a health app that feels alive

class AppColors {
  AppColors._();

  // ===== BACKGROUNDS - Clean whites & warm neutrals =====
  static const Color background = Color(0xFFF8F9FC);      // Soft off-white
  static const Color surface = Color(0xFFFFFFFF);          // Pure white cards
  static const Color surfaceElevated = Color(0xFFF1F3F8); // Subtle gray
  static const Color surfaceOverlay = Color(0xFFE8EBF2);  // Overlay bg

  // ===== PRIMARY - Modern violet/indigo =====
  static const Color primary = Color(0xFF5B4CDB);         // Rich violet
  static const Color primaryLight = Color(0xFF7B6FE8);
  static const Color primaryDark = Color(0xFF4338CA);

  // ===== STRESS COLORS - Fresh, not alarming =====
  static const Color stressLow = Color(0xFF10B981);       // Fresh mint green
  static const Color stressNormal = Color(0xFF06B6D4);    // Calm cyan
  static const Color stressElevated = Color(0xFFF59E0B);  // Warm amber
  static const Color stressHigh = Color(0xFFEF4444);      // Soft red
  static const Color stressCritical = Color(0xFFDC2626);  // Alert red

  // ===== SENSOR COLORS - Vibrant & distinct =====
  static const Color heartRate = Color(0xFFEC4899);       // Pink
  static const Color eda = Color(0xFF0EA5E9);             // Sky blue
  static const Color temperature = Color(0xFFF97316);     // Orange

  // ===== PROCESSING MODES =====
  static const Color edgeMode = Color(0xFF22C55E);        // Green
  static const Color cloudMode = Color(0xFF3B82F6);       // Blue

  // ===== ACCENT =====
  static const Color accent = Color(0xFF5B4CDB);          // Same as primary

  // ===== TEXT - High contrast on light =====
  static const Color textPrimary = Color(0xFF1E293B);     // Dark slate
  static const Color textSecondary = Color(0xFF64748B);   // Medium gray
  static const Color textMuted = Color(0xFF94A3B8);       // Light gray
  static const Color textDisabled = Color(0xFFCBD5E1);    // Very light

  // ===== BORDERS =====
  static const Color border = Color(0xFFE2E8F0);          // Light border
  static const Color borderSubtle = Color(0xFFF1F5F9);    // Very subtle
  static const Color divider = Color(0xFFE2E8F0);

  // ===== DANGER =====
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEE2E2);

  // ===== SUCCESS =====
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);

  /// Get stress color based on level (0-100)
  static Color getStressColor(int level) {
    if (level < 25) return stressLow;
    if (level < 50) return stressNormal;
    if (level < 70) return stressElevated;
    if (level < 85) return stressHigh;
    return stressCritical;
  }

  /// Get stress label based on level
  static String getStressLabel(int level) {
    if (level < 25) return 'Relaxed';
    if (level < 50) return 'Normal';
    if (level < 70) return 'Elevated';
    if (level < 85) return 'High';
    return 'Critical';
  }

  /// Get light background for stress color
  static Color getStressBackgroundColor(int level) {
    final color = getStressColor(level);
    return color.withOpacity( 0.1);
  }
}

class AppTypography {
  AppTypography._();

  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
        fontSize: 56,
        fontWeight: FontWeight.w700,
        letterSpacing: -2,
        height: 1.0,
        color: AppColors.textPrimary,
      );

  static TextStyle get displayMedium => GoogleFonts.plusJakartaSans(
        fontSize: 40,
        fontWeight: FontWeight.w600,
        letterSpacing: -1.5,
        height: 1.1,
        color: AppColors.textPrimary,
      );

  static TextStyle get h1 => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get h2 => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get h3 => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.textMuted,
      );

  static TextStyle get label => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: AppColors.textSecondary,
      );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        color: AppColors.textMuted,
      );

  static TextStyle get numeric => GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get numericLarge => GoogleFonts.spaceGrotesk(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
        color: AppColors.textPrimary,
      );
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  static const EdgeInsets cardPadding = EdgeInsets.all(20);
  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(20, 16, 20, 24);
  static const EdgeInsets sectionGap = EdgeInsets.only(bottom: 24);
}

class AppRadius {
  AppRadius._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double pill = 100;

  static BorderRadius get card => BorderRadius.circular(lg);
  static BorderRadius get button => BorderRadius.circular(md);
  static BorderRadius get badge => BorderRadius.circular(pill);
  static BorderRadius get input => BorderRadius.circular(sm);
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get subtle => [
        BoxShadow(
          color: const Color(0xFF1E293B).withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get medium => [
        BoxShadow(
          color: const Color(0xFF1E293B).withOpacity(0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF1E293B).withOpacity(0.04),
          blurRadius: 6,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: const Color(0xFF1E293B).withOpacity(0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: const Color(0xFF1E293B).withOpacity(0.06),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> stressGlow(Color color, double intensity) => [
        BoxShadow(
          color: color.withOpacity(0.25 * intensity),
          blurRadius: 30 * intensity,
          spreadRadius: 2 * intensity,
        ),
      ];

  static List<BoxShadow> get card => [
        BoxShadow(
          color: const Color(0xFF1E293B).withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

class AppDurations {
  AppDurations._();

  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration emphasis = Duration(milliseconds: 800);
}

class AppCurves {
  AppCurves._();

  static const Curve standard = Curves.easeOutCubic;
  static const Curve enter = Curves.easeOutBack;
  static const Curve exit = Curves.easeInCubic;
  static const Curve bounce = Curves.elasticOut;
}

/// Build the modern light theme
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      surface: AppColors.surface,
      primary: AppColors.primary,
      secondary: AppColors.primaryLight,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSurface: AppColors.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: AppTypography.h3,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      elevation: 0,
      indicatorColor: AppColors.primary.withOpacity(0.12),
      labelTextStyle: MaterialStateProperty.all(AppTypography.caption),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const IconThemeData(color: AppColors.primary);
        }
        return const IconThemeData(color: AppColors.textMuted);
      }),
    ),
    cardTheme: CardTheme(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.button,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.button,
        ),
      ),
    ),
  );
}
