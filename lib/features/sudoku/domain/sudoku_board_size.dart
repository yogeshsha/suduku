import 'dart:math' as math;

/// Supported puzzle sizes. 4×4, 9×9 use [fludoku]; 6×6 and 12×12 use built-in
/// engines (2×3 and 3×4 blocks).
enum SudokuBoardSize {
  dim4(4),
  dim6(6),
  dim9(9),
  dim12(12);

  const SudokuBoardSize(this.dimension);

  final int dimension;

  bool get usesCustomSixEngine => this == SudokuBoardSize.dim6;

  bool get usesCustomTwelveEngine => this == SudokuBoardSize.dim12;

  /// For square fludoku grids only; custom sizes use [boxRows] / [boxCols].
  int get boxSizeSquare {
    if (usesCustomSixEngine || usesCustomTwelveEngine) return 0;
    return math.sqrt(dimension).toInt();
  }

  int get boxRows {
    if (usesCustomSixEngine) return 2;
    if (usesCustomTwelveEngine) return 3;
    return math.sqrt(dimension).toInt();
  }

  int get boxCols {
    if (usesCustomSixEngine) return 3;
    if (usesCustomTwelveEngine) return 4;
    return math.sqrt(dimension).toInt();
  }

  int get maxDigit => dimension;

  String get label => '$dimension×$dimension';

  String get subtitle {
    if (usesCustomSixEngine) {
      return '2×3 boxes · digits 1–6';
    }
    if (usesCustomTwelveEngine) {
      return '3×4 boxes · digits 1–12';
    }
    final s = math.sqrt(dimension).toInt();
    return '$s×$s boxes · digits 1–$dimension';
  }

  /// [fludoku] generation timeout (custom engines ignore this).
  int get generatorTimeoutSecs => switch (this) {
    SudokuBoardSize.dim4 => 25,
    SudokuBoardSize.dim6 => 10,
    SudokuBoardSize.dim9 => 45,
    SudokuBoardSize.dim12 => 10,
  };

  static SudokuBoardSize fromDimension(int d) {
    if (d == 16) return SudokuBoardSize.dim12;
    for (final v in SudokuBoardSize.values) {
      if (v.dimension == d) return v;
    }
    return SudokuBoardSize.dim9;
  }

  static const fludokuEngineDimensions = [4, 9];

  static bool isFludokuDimension(int d) => fludokuEngineDimensions.contains(d);
}
