import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared palette + text styles for the profile / settings screens so the
/// mobile and web profile pages stay visually consistent with the auth flow.
class ProfileTheme {
  ProfileTheme._();

  static const Color green = Color(0xFF2E7D52);
  static const Color greenDark = Color(0xFF1F5E3D);
  static const Color greenSoft = Color(0xFFE3EDE2);
  static const Color bg = Color(0xFFF4EFE6);
  static const Color card = Colors.white;
  static const Color ink = Color(0xFF1F2937);
  static const Color muted = Color(0xFF7C8A86);
  static const Color border = Color(0xFFE9E4DA);
  static const Color fieldBorder = Color(0xFFE5E7EB);

  static TextStyle get appBarTitle => GoogleFonts.cairo(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: ink,
      );

  static TextStyle get name => GoogleFonts.cairo(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: ink,
      );

  static TextStyle get sectionTitle => GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: ink,
      );

  static TextStyle get label => GoogleFonts.tajawal(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: ink,
      );

  static TextStyle get hint => GoogleFonts.tajawal(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: muted,
      );

  /// White card with a soft lift (matches the web profile mockup).
  static BoxDecoration get cardShadow => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0EBE1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      );

  /// Standard white rounded field used across edit + password + settings.
  static InputDecoration field(String hint, {Widget? suffix, Widget? prefix}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffix,
      prefixIcon: prefix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: GoogleFonts.tajawal(color: muted, fontWeight: FontWeight.w500),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: fieldBorder),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: green, width: 1.6),
      ),
    );
  }

  /// Filled green primary button style used on every profile screen.
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.w700),
      );
}
