import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'sudoku_game_colors.dart';

/// "Sunset Arcade" — Tangerine Pop primary, Cosmic Indigo secondary.
const Color _seedLight = Color(0xFFFF7A45);
const Color _seedDark = Color(0xFFFF8F5E);

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: _seedLight,
    brightness: Brightness.light,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  ).copyWith(
    // Cosmic Indigo / Mint Splash — hand-picked so secondary and tertiary
    // read as their own hues instead of tangerine-derived tones.
    secondary: const Color(0xFF4B3F91),
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFE4DFFF),
    onSecondaryContainer: const Color(0xFF251A5C),
    tertiary: const Color(0xFF12946E),
    onTertiary: Colors.white,
    tertiaryContainer: const Color(0xFFCFF3E4),
    onTertiaryContainer: const Color(0xFF00382A),
  );
  return _baseTheme(scheme, Brightness.light, SudokuGameColors.light);
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: _seedDark,
    brightness: Brightness.dark,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  ).copyWith(
    // Lavender Indigo / Mint (dark-tuned) — re-tuned for contrast on
    // Cosmic Night, not a flat invert of the light pairing.
    secondary: const Color(0xFFB3A6FF),
    onSecondary: const Color(0xFF211648),
    secondaryContainer: const Color(0xFF3B2E80),
    onSecondaryContainer: const Color(0xFFE4DFFF),
    tertiary: const Color(0xFF3FE0BE),
    onTertiary: const Color(0xFF0C3A30),
    tertiaryContainer: const Color(0xFF0F5A46),
    onTertiaryContainer: const Color(0xFFCFF3E4),
  );
  return _baseTheme(scheme, Brightness.dark, SudokuGameColors.dark);
}

ThemeData _baseTheme(
  ColorScheme scheme,
  Brightness brightness,
  SudokuGameColors gameColors,
) {
  final isDark = brightness == Brightness.dark;
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    brightness: brightness,
    extensions: [gameColors],
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: scheme.surfaceContainerLow,
      foregroundColor: scheme.onSurface,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    ),
    scaffoldBackgroundColor: scheme.surfaceContainerLowest,
    cardTheme: CardThemeData(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: scheme.surface,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        visualDensity: VisualDensity.comfortable,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
  );
}
