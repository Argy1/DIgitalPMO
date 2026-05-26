import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  // Heading styles (Poppins Bold)
  static TextStyle get h1 => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        color: AppColors.text,
      );

  static TextStyle get h2 => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: AppColors.text,
      );

  static TextStyle get h3 => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: AppColors.text,
      );

  static TextStyle get h4 => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: AppColors.text,
      );

  static TextStyle get h5 => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppColors.text,
      );

  // Body text (Inter Regular)
  static TextStyle get body1 => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: AppColors.text,
        height: 1.5,
      );

  static TextStyle get body2 => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: AppColors.text,
        height: 1.55,
      );

  static TextStyle get body3 => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: AppColors.text,
        height: 1.6,
      );

  // Button text
  static TextStyle get buttonLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: Colors.white,
      );

  static TextStyle get buttonSmall => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        color: Colors.white,
      );

  // Label/Caption
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: AppColors.textMute,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppColors.textMute,
        textBaseline: TextBaseline.alphabetic,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: AppColors.textMute,
      );

  // Muted text
  static TextStyle get muted => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: AppColors.textMute,
      );

  static TextStyle get mutedSmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: AppColors.textMute,
      );

  // Numeric/Tabular
  static TextStyle get numeric => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: AppColors.text,
      );

  static TextStyle get numericSmall => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: AppColors.text,
      );
}
