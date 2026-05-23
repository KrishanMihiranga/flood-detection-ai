import 'package:flutter/material.dart';

import '../system/app_system_ui.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const base = TextStyle(
      color: AppColors.textPrimary,
      letterSpacing: -0.2,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.light(
        surface: AppColors.background,
        onSurface: AppColors.textPrimary,
        primary: AppColors.ctaBackground,
        onPrimary: AppColors.ctaForeground,
        secondary: AppColors.surfaceMuted,
        onSecondary: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: AppSystemUi.lightWhiteBars,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
      ),
      textTheme: TextTheme(
        displaySmall: base.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          height: 1.15,
          letterSpacing: -0.8,
        ),
        titleLarge: base.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        bodyLarge: base.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.45,
          color: AppColors.textSecondary,
        ),
        bodyMedium: base.copyWith(
          fontSize: 15,
          height: 1.4,
          color: AppColors.textSecondary,
        ),
        labelLarge: base.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
