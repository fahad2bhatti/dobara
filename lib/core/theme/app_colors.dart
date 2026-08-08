import 'package:flutter/material.dart';

/// Dobara color palette — extracted from the locked Figma design.
/// Use these instead of hardcoded hex values anywhere in the app.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────
  static const Color primary = Color(0xFF1C3D2E); // deep forest green
  static const Color primaryForeground = Color(0xFFF8F6F2);
  static const Color accent = Color(0xFFC4704F); // terracotta
  static const Color accentForeground = Color(0xFFFFFFFF);

  // ── Surfaces / Background ─────────────────────────────
  static const Color background = Color(0xFFF8F6F2); // warm off-white
  static const Color surface = Color(0xFFFFFFFF);
  static const Color elevatedSurface = Color(0xFFFDFCFB);
  static const Color muted = Color(0xFFECEAE6); // chip / pill backgrounds
  static const Color mutedForeground = Color(0xFF6B6660);
  static const Color border = Color(0xFFE0DBD5);
  static const Color divider = Color(0xFFF0EDE8);

  // ── Text ────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF111110);
  static const Color textBody = Color(0xFF3D3A36);
  static const Color textSecondary = Color(0xFF4A4744);
  static const Color textTertiary = Color(0xFF9A9490);
  static const Color textPlaceholder = Color(0xFFB0ABA6);

  // ── Semantic ────────────────────────────────────────────
  static const Color successBg = Color(0xFFDFFAF0);
  static const Color successText = Color(0xFF0B5E2F);
  static const Color successBorder = Color(0xFFA3E6C4);
  static const Color successDot = Color(0xFF1C8A4A);

  static const Color warningBg = Color(0xFFFFF4D9);
  static const Color warningText = Color(0xFF6B3E00);
  static const Color warningBorder = Color(0xFFF5D87E);

  static const Color errorBg = Color(0xFFFFEAEA);
  static const Color errorText = Color(0xFF7A1515);

  // ── New Seller badge ───────────────────────────────────
  static const Color newSellerBg = Color(0xFFFFF4D9);
  static const Color newSellerText = Color(0xFF92600A);
  static const Color newSellerBorder = Color(0xFFF5D87E);

  // ── Neutral scale (dividers, disabled states, dots) ────
  static const Color neutral200 = Color(0xFFD8D4CE);
  static const Color neutral300 = Color(0xFFCCC8C2);
  static const Color neutral500 = Color(0xFF8A8480);

  // ── Condition grade colors ──────────────────────────────
  // Each grade: background, text, border, indicator dot.
  static const Map<String, ConditionColorSet> conditionColors = {
    'Like New': ConditionColorSet(
      bg: Color(0xFFDFFAF0),
      text: Color(0xFF0B5E2F),
      border: Color(0xFFA3E6C4),
      dot: Color(0xFF1C8A4A),
    ),
    'Excellent': ConditionColorSet(
      bg: Color(0xFFD9EEFF),
      text: Color(0xFF0B3A6E),
      border: Color(0xFF9DC8F5),
      dot: Color(0xFF1C62C4),
    ),
    'Good': ConditionColorSet(
      bg: Color(0xFFFFF4D9),
      text: Color(0xFF6B3E00),
      border: Color(0xFFF5D87E),
      dot: Color(0xFFD4860A),
    ),
    'Fair': ConditionColorSet(
      bg: Color(0xFFFFEADC),
      text: Color(0xFF7A2E00),
      border: Color(0xFFF5B99A),
      dot: Color(0xFFC4704F),
    ),
    'Well Worn': ConditionColorSet(
      bg: Color(0xFFECEAE6),
      text: Color(0xFF4A4744),
      border: Color(0xFFCCC8C2),
      dot: Color(0xFF8A8480),
    ),
  };
}

/// Bundled colors for a single condition-grade badge.
class ConditionColorSet {
  final Color bg;
  final Color text;
  final Color border;
  final Color dot;

  const ConditionColorSet({
    required this.bg,
    required this.text,
    required this.border,
    required this.dot,
  });
}
