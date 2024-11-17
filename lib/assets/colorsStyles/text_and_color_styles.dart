import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppStyles {
  static Color onBackground() {
    return const Color(0xFFFFFFFF);
  }

  static Color backgroundDark() {
    return const Color(0xFF0E1C23);
  }

  static Color whiteDark() {
    return const Color(0xFFB0B0B0);
  }

  static Color background() {
    return const Color(0xFF1A3079);
  }

  static Color backgroundLight() {
    return const Color(0x6E0087FF);
  }

  static Color disabled() {
    return const Color(0xFFF8F8F8);
  }

  static Color onDisabled() {
    return const Color(0xFFD4D4D4);
  }

  static Color Primary30() {
    return const Color(0xFFBDDFE7);
  }

  static Color Primary50() {
    return const Color(0xFF00B4DB);
  }

  static Color disabledButtonBackground() {
    return const Color(0xFFEEEEEE);
  }

  static Color disabledButtonText() {
    return const Color(0xFFD4D4D4);
  }

  static Color typeWorkoutColor() {
    return const Color(0xFF003A45);
  }

  static Color grey20() {
    return const Color(0xFF686868);
  }

  static Color grey30() {
    return const Color(0xFF888888);
  }

  static Color grey50() {
    return const Color(0xFFB8B8B8);
  }

  static Color grey60() {
    return const Color(0xFFC9C9C9);
  }

  static Color grey70() {
    return const Color(0xFFDCDCDC);
  }

  static Color grey80() {
    return const Color(0xFFE6E6E6);
  }

  static TextStyle headLineLarge({required Color color}) {
    return GoogleFonts.nunito(
      textStyle: TextStyle(
        color: color,
        fontSize: 28.0,
        fontWeight: FontWeight.w800,
        height: 38.19 / 28.0,
        letterSpacing: 0.02 * 28.0,
      ),
    );
  }

  static TextStyle headLineMedium({required Color color}) {
    return GoogleFonts.nunito(
      textStyle: TextStyle(
        color: color,
        fontSize: 24.0,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.02 * 24.0,
        height: 32.0 / 24.0,
      ),
    );
  }

  static TextStyle headLineSmall({required Color color}) {
    return GoogleFonts.nunito(
      textStyle: TextStyle(
        color: color,
        fontSize: 22.0,
        fontWeight: FontWeight.w700,
        height: 30.01 / 22.0,
        letterSpacing: 0.02 * 22.0,
      ),
    );
  }

  static TextStyle titleMedium({required Color color}) {
    return GoogleFonts.nunito(
      textStyle: TextStyle(
        color: color,
        fontSize: 20.0,
        fontWeight: FontWeight.w800,
        height: 27.28 / 20.0,
        letterSpacing: 0.02 * 20.0,
      ),
    );
  }

  static TextStyle titleSmall({required Color color}) {
    return GoogleFonts.nunito(
      textStyle: TextStyle(
        color: color,
        fontSize: 18.0,
        fontWeight: FontWeight.w700,
        height: 1.5,
      ),
    );
  }

  static TextStyle bodyLarge({required Color color}) {
    return GoogleFonts.inter(
      textStyle: TextStyle(
        color: color,
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
        height: 1.0,
      ),
    );
  }

  static TextStyle bodyMedium({required Color color}) {
    return GoogleFonts.inter(
      textStyle: TextStyle(
        color: color,
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
        height: 1,
      ),
    );
  }

  static TextStyle labelLarge({required Color color}) {
    return GoogleFonts.nunito(
      textStyle: TextStyle(
        color: color,
        fontSize: 18.0,
        fontWeight: FontWeight.w800,
        height: 24.55 / 18.0,
        letterSpacing: 0.02 * 18,
      ),
    );
  }

  static TextStyle labelMedium({required Color color}) {
    return GoogleFonts.nunito(
      textStyle: TextStyle(
        color: color,
        fontSize: 16.0,
        fontWeight: FontWeight.w700,
        height: 21.82 / 16.0,
      ),
    );
  }

  static TextStyle labelSmall({required Color color}) {
    return GoogleFonts.nunito(
      textStyle: TextStyle(
        color: color,
        fontSize: 14.0,
        fontWeight: FontWeight.w700,
        height: 19.1 / 14.0,
        letterSpacing: 0.02 * 14.0,
      ),
    );
  }

  static BoxShadow cardShadow() {
    return BoxShadow(
      color: const Color(0xFF9D9D9D).withOpacity(0.1),
      blurRadius: 16,
      spreadRadius: 4,
      offset: const Offset(0, 4),
    );
  }

  static BoxShadow cardShadowGradient() {
    return BoxShadow(
      color: const Color(0xFF00A6DB).withOpacity(0.25),
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 2,
    );
  }
}
