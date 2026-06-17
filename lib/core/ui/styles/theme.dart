// ============================================================================
//  وِرد (WERD) — Quran memorization app  |  Central Theme File
// ----------------------------------------------------------------------------
//  SINGLE source of truth for the app's look & feel. Change colors, fonts,
//  radii, or spacing here and the whole app updates.
//
//  Official «وِرد» palette (from the design spec):
//    Primary      #1FA463   buttons, brand, active states
//    PrimaryDark  #137A55   gradients / pressed
//    Teal         #14B8A6   secondary accents, charts
//    Beige        #F6F1E8   app background
//    Ink          #1F2937   primary text (navy)
//    Muted        #64748B   secondary text
//    Border       #E5E7EB   hairlines / input borders
//    Amber/Gold   #F59E0B   badges, streak, warnings
//    Red          #EF4444   errors / absent
//  Dark mode: background #0F1B17, surface #16241F, text #E7EFEA.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// All raw color values. Edit here to re-skin the app.
class AppColors {
  AppColors._();

  // --- Brand palette (light) ---
  static const Color primary = Color(0xFF1FA463); // أخضر رئيسي
  static const Color primaryDark = Color(0xFF137A55); // أخضر داكن
  static const Color primaryLight = Color(0xFF14B8A6); // تركواز
  static const Color sky = Color(0xFFE6F4EC); // أخضر فاتح جدًا (خلفيات أقسام)
  static const Color pink = Color(0xFFF59E0B); // كهرماني (أوسمة/تمييز)
  static const Color lavender = Color(0xFFF6F1E8); // بيج (خلفية)
  static const Color ink = Color(0xFF1F2937); // نص رئيسي (كحلي)

  // --- Light surfaces ---
  static const Color background = lavender;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = sky;

  // --- Dark surfaces ---
  static const Color darkBackground = Color(0xFF0F1B17);
  static const Color darkSurface = Color(0xFF16241F);
  static const Color darkText = Color(0xFFE7EFEA);

  // --- Semantic ---
  static const Color success = Color(0xFF1FA463);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color textMuted = Color(0xFF64748B);
  static const Color border = Color(0xFFE5E7EB);
}

/// Reusable design tokens (spacing & radii). Edit to restyle globally.
class AppRadius {
  AppRadius._();
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
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

/// Typography. Headings use Cairo (bold geometric kufi); body uses Tajawal.
/// Both are Arabic-first faces matching the design spec.
class AppText {
  AppText._();

  static TextTheme textTheme(Color color) {
    final heading = GoogleFonts.cairoTextTheme();
    final body = GoogleFonts.tajawalTextTheme();
    return TextTheme(
      displayLarge: heading.displayLarge?.copyWith(color: color, fontWeight: FontWeight.w800),
      displayMedium: heading.displayMedium?.copyWith(color: color, fontWeight: FontWeight.w800),
      displaySmall: heading.displaySmall?.copyWith(color: color, fontWeight: FontWeight.w800),
      headlineLarge: heading.headlineLarge?.copyWith(color: color, fontWeight: FontWeight.w700),
      headlineMedium: heading.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
      headlineSmall: heading.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
      titleLarge: heading.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w700),
      titleMedium: body.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
      titleSmall: body.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
      bodyLarge: body.bodyLarge?.copyWith(color: color),
      bodyMedium: body.bodyMedium?.copyWith(color: color),
      bodySmall: body.bodySmall?.copyWith(color: color.withValues(alpha: 0.75)),
      labelLarge: body.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w700),
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
    final borderColor = isDark ? const Color(0xFF24382F) : AppColors.border;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primaryLight,
      onSecondary: Colors.white,
      tertiary: AppColors.pink,
      onTertiary: Colors.white,
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
      // Clean, light app bar (matches the mobile mockups: white header, dark
      // title, no colored band).
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: const EdgeInsets.all(AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: borderColor),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.primary, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.tajawal(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.tajawal(color: AppColors.textMuted),
        labelStyle: GoogleFonts.tajawal(color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.sky,
        selectedColor: AppColors.primary,
        side: BorderSide.none,
        labelStyle: GoogleFonts.tajawal(color: AppColors.primaryDark, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.tajawal(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: AppColors.sky,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.sky,
        circularTrackColor: AppColors.sky,
      ),
      dividerTheme: DividerThemeData(color: borderColor, thickness: 1),
    );
  }
}
