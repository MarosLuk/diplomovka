import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppStyles {
  static Color onBackground() {
    return const Color(0xFF284A56);
  }

  static Color BackgroundDark() {
    return const Color(0xFF0E1C23); // 20% darker than 0xFF284A56
  }

  static Color whiteDark() {
    return const Color(0xFFB0B0B0); // 20% darker than 0xFF284A56
  }

  static Color Background() {
    return const Color(0xFFF6F7F9);
  }

  static Color Disabled() {
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
        fontSize: 28.0, // Font size 28px
        fontWeight: FontWeight.w800, // Font weight 800
        height: 38.19 / 28.0, // Line height of 38.19px
        letterSpacing: 0.02 * 28.0, // 2% letter spacing (0.56)
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
        height: 32.0 / 24.0, // Line height of 32
      ),
    );
  }

  static TextStyle headLineSmall({required Color color}) {
    return GoogleFonts.nunito(
      textStyle: TextStyle(
        color: color,
        fontSize: 22.0, // Font size 22px
        fontWeight: FontWeight.w700, // Font weight 700
        height: 30.01 / 22.0, // Line height of 30.01px
        letterSpacing: 0.02 * 22.0, // 2% letter spacing (0.44px)
      ),
    );
  }

  static TextStyle headLineTypeWorkout({required Color color}) {
    return GoogleFonts.nunito(
      textStyle: TextStyle(
        color: color,
        fontSize: 24.0,
        fontWeight: FontWeight.w700,
        height: 1.5,
        letterSpacing: 0.02 * 24,
      ),
    );
  }

  static TextStyle timesPerWeekPicker({required Color color}) {
    return GoogleFonts.nunito(
      textStyle: TextStyle(
        color: color,
        fontSize: 18.0,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  static TextStyle titleMedium({required Color color}) {
    return GoogleFonts.nunito(
      textStyle: TextStyle(
        color: color,
        fontSize: 20.0, // Font size 20px
        fontWeight: FontWeight.w800, // Font weight 800
        height: 27.28 / 20.0, // Line height of 27.28px
        letterSpacing: 0.02 * 20.0, // 2% letter spacing (0.4px)
      ),
    );
  }

  static TextStyle titleSmall({required Color color}) {
    return GoogleFonts.nunito(
      textStyle: TextStyle(
        color: color,
        fontSize: 18.0,
        fontWeight: FontWeight.w700,
        height: 1.5, // Equivalent to line-height: normal;
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
        fontSize: 18.0, // Font size 18px
        fontWeight: FontWeight.w800, // Font weight 800 (extra bold)
        height: 24.55 / 18.0, // Line height of 24.55px
        letterSpacing: 0.02 * 18, // 2% of 18px
      ),
    );
  }

  static TextStyle labelMedium({required Color color}) {
    return GoogleFonts.nunito(
      textStyle: TextStyle(
        color: color,
        fontSize: 16.0, // Font size 16px
        fontWeight: FontWeight.w700, // Font weight 700 (bold)
        height: 21.82 / 16.0, // Line height of 21.82px
      ),
    );
  }

  static TextStyle labelSmall({required Color color}) {
    return GoogleFonts.nunito(
      textStyle: TextStyle(
        color: color,
        fontSize: 14.0, // Font size 14px
        fontWeight: FontWeight.w700, // Font weight 700
        height: 19.1 / 14.0, // Line height of 19.1px
        letterSpacing: 0.02 * 14.0, // 2% letter spacing (0.28px)
      ),
    );
  }

  static TextStyle clockTime({required Color color}) {
    return GoogleFonts.nunito(
      textStyle: TextStyle(
        color: color,
        fontSize: 24,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.02,
      ),
    );
  }

  static TextStyle outdoorSpentTime({required Color color}) {
    return GoogleFonts.nunito(
      textStyle: TextStyle(
        color: color,
        fontSize: 48,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.02,
      ),
    );
  }

  static TextStyle coachHint({required Color color}) {
    return GoogleFonts.nunito(
      textStyle: TextStyle(
        color: color,
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
        height: 20.0 / 15.1, // Calculate line height as a multiple of font size
      ),
    );
  }

  static TextStyle selectedValueFromCrolingRuller({required Color color}) {
    return GoogleFonts.nunito(
      textStyle: TextStyle(
        color: color,
        fontSize: 48.0, // The font size in pixels
        fontWeight: FontWeight.w400, // Weight is 400
        height: 1.5, // Line height = 72px / 48px = 1.5
        letterSpacing: 0.02, // 2% letter spacing
      ),
    );
  }

  static TextStyle selectedUnitFromCrolingRuller({required Color color}) {
    return GoogleFonts.nunito(
      textStyle: TextStyle(
        color: color,
        fontSize: 24.0, // The font size in pixels
        fontWeight: FontWeight.w400, // Weight is 400
        height: 0.75, // Line height = 72px / 48px = 1.5
        letterSpacing: 0.02, // 2% letter spacing
      ),
    );
  }

  static TextStyle timesPerWeekStyle({required Color color}) {
    return GoogleFonts.nunito(
      textStyle: TextStyle(
        color: color,
        fontSize: 28.0,
        fontWeight: FontWeight.w600, // Updated to 600 as per the image
        height: 42.0 / 28.0, // Line height: 42px with a font size of 28px
        letterSpacing: 0.56, // 2% of 28px is approximately 0.56px
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
