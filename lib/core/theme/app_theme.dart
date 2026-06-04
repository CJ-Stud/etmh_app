// lib/core/theme/app_theme.dart
//
// "Healing & Mindful Palette" — single source of truth for colors,
// typography, spacing and component theming.
//
// All APIs used here are valid for Flutter 3.27+. In particular:
//   • CardThemeData / DialogThemeData / TabBarThemeData (new normalised
//     component themes since 3.27).
//   • Color.withValues(alpha: ...) replaces the deprecated withOpacity().

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // ── Brand palette ──────────────────────────────────────────────────
  static const Color background = Color(0xFFFDFBF7); // Soft off-white / cream
  static const Color surface = Color(0xFFFFFFFF); // Cards, sheets
  static const Color primarySage = Color(0xFFA3B19B); // Sage green (CTA)
  static const Color primarySageDeep = Color(0xFF8A9A82); // Pressed state
  static const Color secondaryLavender = Color(0xFFD6C7DE); // Info cards
  static const Color secondaryLavenderDeep = Color(0xFFB7A4C2);

  // ── Semantic neutrals ──────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF333333); // Charcoal grey
  static const Color textSecondary = Color(0xFF6E6E6E);
  static const Color textMuted = Color(0xFFA0A0A0);
  static const Color divider = Color(0xFFEDE8E0);
  static const Color errorSoft = Color(0xFFD08A8A);

  // ── Emotion scale (1 → 5). Each tone is soft on purpose. ──────────
  static const Color emotion1 = Color(0xFFE6B8B8); // Very Bad   — dusty rose
  static const Color emotion2 = Color(0xFFE9CDB0); // Bad        — warm sand
  static const Color emotion3 = Color(0xFFE8DDB5); // Neutral    — soft straw
  static const Color emotion4 = Color(0xFFC7D6B5); // Good       — light sage
  static const Color emotion5 = Color(0xFFA3B19B); // Very Happy — sage
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primarySage,
        onPrimary: Colors.white,
        secondary: AppColors.secondaryLavender,
        onSecondary: AppColors.textPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.errorSoft,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primarySage, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primarySage,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primarySageDeep,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
