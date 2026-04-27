import 'dart:math' as math;

/// Supported puzzle sizes. Sizes other than 6×6 use [fludoku]; 6×6 uses a
/// built-in 2×3 mini Sudoku engine.
enum SudokuBoardSize {
  dim4(4),
  dim6(6),
  dim9(9),
  dim16(16);

  const SudokuBoardSize(this.dimension);

  final int dimension;

  bool get usesCustomSixEngine => this == SudokuBoardSize.dim6;

  /// For square fludoku grids only; for 6×6 use [boxRows] / [boxCols].
  int get boxSizeSquare {
    if (usesCustomSixEngine) return 0;
    return math.sqrt(dimension).toInt();
  }

  int get boxRows => usesCustomSixEngine ? 2 : math.sqrt(dimension).toInt();

  int get boxCols => usesCustomSixEngine ? 3 : math.sqrt(dimension).toInt();

  int get maxDigit => dimension;

  String get label => '$dimension×$dimension';

  String get subtitle {
    if (usesCustomSixEngine) {
      return '2×3 boxes · digits 1–6';
    }
    final s = math.sqrt(dimension).toInt();
    return '$s×$s boxes · digits 1–$dimension';
  }

  /// [fludoku] generation timeout (6×6 ignores this; it is instant).
  int get generatorTimeoutSecs => switch (this) {
        SudokuBoardSize.dim4 => 25,
        SudokuBoardSize.dim6 => 10,
        SudokuBoardSize.dim9 => 45,
        SudokuBoardSize.dim16 => 100
      };

  static SudokuBoardSize fromDimension(int d) {
    for (final v in SudokuBoardSize.values) {
      if (v.dimension == d) return v;
    }
    return SudokuBoardSize.dim9;
  }

  static const fludokuEngineDimensions = [4, 9, 16];

  static bool isFludokuDimension(int d) =>
      fludokuEngineDimensions.contains(d);
}
