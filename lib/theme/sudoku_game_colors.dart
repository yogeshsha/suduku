import 'package:flutter/material.dart';

/// Game-specific palette that has no slot in Material's [ColorScheme]:
/// reward gold, celebration pink, and the alternating board-box tints.
class SudokuGameColors extends ThemeExtension<SudokuGameColors> {
  const SudokuGameColors({
    required this.gold,
    required this.onGold,
    required this.pink,
    required this.onPink,
    required this.boxTintA,
    required this.boxTintB,
    required this.heroGradient,
  });

  final Color gold;
  final Color onGold;
  final Color pink;
  final Color onPink;
  final Color boxTintA;
  final Color boxTintB;

  /// Brand gradient for big color blocks (hero card, primary CTA). Stays the
  /// same vivid mid-tones in both themes — the dark-mode `primary`/`pink`
  /// are lightened for small icons/text and read washed-out at panel scale.
  final List<Color> heroGradient;

  static const _heroGradient = [Color(0xFFFF7A45), Color(0xFFFF4D82)];

  static const light = SudokuGameColors(
    gold: Color(0xFFFFB100),
    onGold: Color(0xFF3D2600),
    pink: Color(0xFFFF4D82),
    onPink: Color(0xFFFFFFFF),
    boxTintA: Color(0xFFFFF1E2),
    boxTintB: Color(0xFFFFFFFF),
    heroGradient: _heroGradient,
  );

  static const dark = SudokuGameColors(
    gold: Color(0xFFFFD166),
    onGold: Color(0xFF3D2600),
    pink: Color(0xFFFF7FA8),
    onPink: Color(0xFF3D0A22),
    boxTintA: Color(0xFF2B2150),
    boxTintB: Color(0xFF241A44),
    heroGradient: _heroGradient,
  );

  @override
  SudokuGameColors copyWith({
    Color? gold,
    Color? onGold,
    Color? pink,
    Color? onPink,
    Color? boxTintA,
    Color? boxTintB,
    List<Color>? heroGradient,
  }) {
    return SudokuGameColors(
      gold: gold ?? this.gold,
      onGold: onGold ?? this.onGold,
      pink: pink ?? this.pink,
      onPink: onPink ?? this.onPink,
      boxTintA: boxTintA ?? this.boxTintA,
      boxTintB: boxTintB ?? this.boxTintB,
      heroGradient: heroGradient ?? this.heroGradient,
    );
  }

  @override
  SudokuGameColors lerp(ThemeExtension<SudokuGameColors>? other, double t) {
    if (other is! SudokuGameColors) return this;
    return SudokuGameColors(
      gold: Color.lerp(gold, other.gold, t)!,
      onGold: Color.lerp(onGold, other.onGold, t)!,
      pink: Color.lerp(pink, other.pink, t)!,
      onPink: Color.lerp(onPink, other.onPink, t)!,
      boxTintA: Color.lerp(boxTintA, other.boxTintA, t)!,
      boxTintB: Color.lerp(boxTintB, other.boxTintB, t)!,
      heroGradient: t < 0.5 ? heroGradient : other.heroGradient,
    );
  }
}

extension SudokuGameColorsX on BuildContext {
  SudokuGameColors get gameColors =>
      Theme.of(this).extension<SudokuGameColors>() ?? SudokuGameColors.light;
}
