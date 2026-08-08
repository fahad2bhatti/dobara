import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Dobara typography system.
///
/// Two font families, matching the locked design:
/// - Display (Instrument Serif): app branding, screen titles, product
///   names, hero headings — gives the "boutique fashion" feel.
/// - Body (Outfit): everything else — labels, buttons, body copy, prices.
class AppTextStyles {
  AppTextStyles._();

  // ── Display (Instrument Serif) ─────────────────────────
  static TextStyle get displayLarge => GoogleFonts.instrumentSerif(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: AppColors.primary,
        height: 1.0,
      );

  static TextStyle get displayMedium => GoogleFonts.instrumentSerif(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.1,
      );

  static TextStyle get displaySmall => GoogleFonts.instrumentSerif(
        fontSize: 22,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.25,
      );

  static TextStyle get displayXSmall => GoogleFonts.instrumentSerif(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  // ── Body (Outfit) ───────────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySmall => GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textBody,
        height: 1.5,
      );

  static TextStyle get caption => GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
      );

  static TextStyle get label => GoogleFonts.outfit(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.textTertiary,
        letterSpacing: 1.4, // ~0.14em uppercase eyebrow labels
      );

  // ── Semantic / component-specific ──────────────────────
  static TextStyle get priceText => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      );

  static TextStyle get priceTextSmall => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      );

  static TextStyle get buttonText => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get badgeText => GoogleFonts.outfit(
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3, // ~0.02em
      );
}
