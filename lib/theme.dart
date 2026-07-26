import 'package:flutter/material.dart';

/// PicSearch design tokens — the "Iris on ink" direction (decisions.md §11).
class AppColors {
  static const ground = Color(0xFF0A0B14);
  static const surface = Color(0xFF151826);
  static const surface2 = Color(0xFF1D2132);
  static const line = Color(0xFF2A2F43);
  static const ink = Color(0xFFEEF0F8);
  static const inkDim = Color(0xFF8B90A6);
  static const inkFaint = Color(0xFF565C74);
  static const accent = Color(0xFFA78BFA);
  static const accentInk = Color(0xFF160F36);
  static const glow = Color(0xFF7C3AED);

  static const grad = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Monospace + tabular figures for extracted values — they are codes.
const TextStyle dataStyle = TextStyle(
  fontFamily: 'monospace',
  fontFeatures: [FontFeature.tabularFigures()],
  letterSpacing: 0.6,
  color: AppColors.ink,
);

const TextStyle labelStyle = TextStyle(
  fontSize: 11,
  letterSpacing: 1.0,
  fontWeight: FontWeight.w600,
  color: AppColors.inkFaint,
);

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.ground,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: AppColors.accentInk,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surface2,
      contentTextStyle: TextStyle(color: AppColors.ink),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
