import 'package:flutter/material.dart';

/// Brand and neutral palette — calm, high-contrast; primary matches flood / river readiness.
abstract final class AppColors {
  static const Color background = Color(0xFFFFFFFF);
  /// Light canvas behind dashboard tabs (avoids a white slab under the glass nav).
  static const Color dashboardCanvas = Color(0xFFF5F5F5);
  static const Color surfaceMuted = Color(0xFFF7F7F7);
  static const Color textPrimary = Color(0xFF222222);
  static const Color textSecondary = Color(0xFF717171);

  /// Primary interactive — deep river teal (CTAs, selected chips, brand mark).
  static const Color ctaBackground = Color(0xFF0B6470);
  static const Color ctaForeground = Color(0xFFFFFFFF);

  static const Color divider = Color(0xFFEBEBEB);
}
