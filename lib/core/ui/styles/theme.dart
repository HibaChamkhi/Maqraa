// ============================================================================
//  WESAL — وصال  |  Central Theme File
// ----------------------------------------------------------------------------
//  This is the SINGLE source of truth for the app's look & feel.
//  Change colors, fonts, radii, or spacing here and the whole app updates.
//
//  Official «وصال» palette (from the project spec):
//    Primary   #4E79A8   buttons & headers
//    PrimaryLt #8DB6D8   progress & secondary touches
//    Sky       #D6E6E7   section backgrounds / empty progress bars
//    Pink      #E0A3BB   badges, borders, accents (used sparingly)
//    Lavender  #F4DFE6   main screen background
//    Ink       #2E3A4A   primary text
//  Dark mode: background #1B2330, text #E9E4EC.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// All raw color values. Edit here to re-skin the app.
class AppColors {
  AppColors._();

  // --- Brand palette (light) ---
  static const Color primary = Color(0xFF4E79A8); // أزرق غامق
  static const Color primaryLight = Color(0xFF8DB6D8); // أزرق فاتح
  static const Color sky = Color(0xFFD6E6E7); // سماوي فاتح
  static const Color pink = Color(0xFFE0A3BB); // وردي
  static const Color lavender = Color(0xFFF4DFE6); // خزامى (خلفية)
  static const Color ink = Color(0xFF2E3A4A); // كحلي ناعم (نص)

  // --- Light surfaces ---
  static const Color background = lavender;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = sky;

  // --- Dark surfaces ---
  static const Color darkBackground = Color(0xFF1B2330);
  static const Color darkSurface = Color(0xFF222C3C);
  static const Color darkText = Color(0xFFE9E4EC);

  // --- Semantic ---
  static const Color success = Color(0xFF4FA89A);
  static const Color warning = Color(0xFFD9A648);
  static const Color error = Color(0xFFC9596B);
  static const Color textMuted = Color(0xFF7A8699);
  static const Color border = Color(0xFFE0D3DA);
}

/// Reusable design tokens (spacing & radii). Edit to restyle globally.
class AppRadius {
  AppRadius._();
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double pill = 999;
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Typography. Headings use an elegant Arabic face (Amiri); body uses Cairo.
/// Swap the font families here to change them everywhere.
class AppText {
  AppText._();

  static TextTheme textTheme(Color color) {
    final heading = GoogleFonts.amiriTextTheme();
    final body = GoogleFonts.cairoTextTheme();
    return TextTheme(
      displayLarge: heading.displayLarge?.copyWith(color: color, fontWeight: FontWeight.w700),
      displayMedium: heading.displayMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
      headlineLarge: heading.headlineLarge?.copyWith(color: color, fontWeight: FontWeight.w700),
      headlineMedium: heading.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
      headlineSmall: heading.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
      titleLarge: body.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w700),
      titleMedium: body.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
      titleSmall: body.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
      bodyLarge: body.bodyLarge?.copyWith(color: color),
      bodyMedium: body.bodyMedium?.copyWith(color: color),
      bodySmall: body.bodySmall?.copyWith(color: color.withValues(alpha: 0.7)),
      labelLarge: body.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w600),
    );
  }
}

/// The app themes. Use [AppTheme.light] and [AppTheme.dark].
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final onSurface = isDark ? AppColors.darkText : AppColors.ink;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.pink,
      onSecondary: Colors.white,
      tertiary: AppColors.primaryLight,
      onTertiary: AppColors.ink,
      surface: surface,
      onSurface: onSurface,
      error: AppColors.error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: colorScheme,
      textTheme: AppText.textTheme(onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.amiri(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: const EdgeInsets.all(AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.sky,
        selectedColor: AppColors.primaryLight,
        labelStyle: GoogleFonts.cairo(color: AppColors.ink),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.sky,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    );
  }
}
