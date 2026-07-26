import 'package:flutter/material.dart';

/// Theme-independent brand constants (used by the always-dark splash) + the
/// Iris gradient used for glows.
class AppColors {
  static const accent = Color(0xFFA78BFA);
  static const accentInk = Color(0xFF160F36);
  static const glow = Color(0xFF7C3AED);
  static const ground = Color(0xFF0A0B14);
  static const surface = Color(0xFF151826);
  static const surface2 = Color(0xFF1D2132);
  static const line = Color(0xFF2A2F43);
  static const ink = Color(0xFFEEF0F8);
  static const inkDim = Color(0xFF8B90A6);
  static const inkFaint = Color(0xFF565C74);
  static const grad = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// The themeable palette. Read in widgets via `context.pic`.
@immutable
class PicColors extends ThemeExtension<PicColors> {
  final Color ground, surface, surface2, line, ink, inkDim, inkFaint, accent, accentInk, glow;

  const PicColors({
    required this.ground,
    required this.surface,
    required this.surface2,
    required this.line,
    required this.ink,
    required this.inkDim,
    required this.inkFaint,
    required this.accent,
    required this.accentInk,
    required this.glow,
  });

  static const dark = PicColors(
    ground: Color(0xFF0A0B14),
    surface: Color(0xFF151826),
    surface2: Color(0xFF1D2132),
    line: Color(0xFF2A2F43),
    ink: Color(0xFFEEF0F8),
    inkDim: Color(0xFF8B90A6),
    inkFaint: Color(0xFF565C74),
    accent: Color(0xFFA78BFA),
    accentInk: Color(0xFF160F36),
    glow: Color(0xFF7C3AED),
  );

  static const light = PicColors(
    ground: Color(0xFFF1F3F8),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFEFF1F7),
    line: Color(0xFFE1E4EE),
    ink: Color(0xFF161A26),
    inkDim: Color(0xFF5A6076),
    inkFaint: Color(0xFF98A0B2),
    accent: Color(0xFF7C3AED),
    accentInk: Color(0xFFFFFFFF),
    glow: Color(0xFFA78BFA),
  );

  @override
  PicColors copyWith({
    Color? ground, Color? surface, Color? surface2, Color? line, Color? ink,
    Color? inkDim, Color? inkFaint, Color? accent, Color? accentInk, Color? glow,
  }) =>
      PicColors(
        ground: ground ?? this.ground,
        surface: surface ?? this.surface,
        surface2: surface2 ?? this.surface2,
        line: line ?? this.line,
        ink: ink ?? this.ink,
        inkDim: inkDim ?? this.inkDim,
        inkFaint: inkFaint ?? this.inkFaint,
        accent: accent ?? this.accent,
        accentInk: accentInk ?? this.accentInk,
        glow: glow ?? this.glow,
      );

  @override
  PicColors lerp(ThemeExtension<PicColors>? other, double t) {
    if (other is! PicColors) return this;
    return PicColors(
      ground: Color.lerp(ground, other.ground, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      line: Color.lerp(line, other.line, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkDim: Color.lerp(inkDim, other.inkDim, t)!,
      inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
    );
  }
}

extension PicColorsX on BuildContext {
  PicColors get pic => Theme.of(this).extension<PicColors>()!;
}

/// Monospace + tabular figures for extracted values (colour inherited from theme).
const TextStyle dataStyle = TextStyle(
  fontFamily: 'monospace',
  fontFeatures: [FontFeature.tabularFigures()],
  letterSpacing: 0.6,
);

const TextStyle labelStyle = TextStyle(
  fontSize: 11,
  letterSpacing: 1.0,
  fontWeight: FontWeight.w600,
);

/// App-wide theme mode. Light by default; toggled from Settings (the app listens
/// and rebuilds).
final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);

ThemeData buildTheme(Brightness brightness) {
  final pic = brightness == Brightness.dark ? PicColors.dark : PicColors.light;
  final base = ThemeData(brightness: brightness, useMaterial3: true, fontFamily: 'Sora');
  return base.copyWith(
    scaffoldBackgroundColor: pic.ground,
    colorScheme: base.colorScheme.copyWith(
      primary: pic.accent,
      onPrimary: pic.accentInk,
      surface: pic.surface,
      onSurface: pic.ink,
    ),
    extensions: <ThemeExtension<dynamic>>[pic],
    textTheme: base.textTheme.apply(bodyColor: pic.ink, displayColor: pic.ink),
    appBarTheme: AppBarTheme(
      backgroundColor: pic.ground,
      foregroundColor: pic.ink,
      elevation: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: pic.surface2,
      contentTextStyle: TextStyle(color: pic.ink),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
