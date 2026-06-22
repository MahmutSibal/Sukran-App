import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dark.dart';

class AppTheme {
  /// Premium dark theme — the primary visual language for AppSukran.
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppDark.accent,
      brightness: Brightness.dark,
      primary: AppDark.accent,
      onPrimary: const Color(0xFF1A1206),
      secondary: AppDark.accentBright,
      surface: AppDark.surface,
      onSurface: AppDark.textPrimary,
      error: AppDark.danger,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppDark.bgTop,
      textTheme: base.textTheme.apply(
        bodyColor: AppDark.textPrimary,
        displayColor: AppDark.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppDark.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppDark.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDark.radiusModule)),
      ),
      dividerColor: AppDark.hairline,
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppDark.surfaceHigh,
        selectedColor: AppDark.accent,
        side: BorderSide.none,
        labelStyle: const TextStyle(color: AppDark.textPrimary, fontWeight: FontWeight.w700),
        secondaryLabelStyle: const TextStyle(color: Color(0xFF1A1206), fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDark.radiusControl)),
          backgroundColor: AppDark.accent,
          foregroundColor: const Color(0xFF1A1206),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppDark.accent,
        linearTrackColor: AppDark.surfaceHigh,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppDark.inputFill,
        hintStyle: const TextStyle(color: AppDark.textSecondary),
        labelStyle: const TextStyle(color: AppDark.textSecondary),
        prefixIconColor: AppDark.textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDark.radiusControl),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDark.radiusControl),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDark.radiusControl),
          borderSide: const BorderSide(color: AppDark.accent, width: 1.2),
        ),
      ),
    );
  }

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.dark,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: base.textTheme.apply(bodyColor: AppColors.dark, displayColor: AppColors.dark),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.dark,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        shadowColor: AppColors.primary.withAlpha((255 * 0.08).round()),
      ),
      dividerColor: AppColors.warmSand,
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.softPeach,
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(color: AppColors.dark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}