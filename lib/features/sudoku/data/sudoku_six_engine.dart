import 'dart:math';

import '../domain/game_difficulty.dart';

/// 6×6 Sudoku with **2×3** blocks (standard mini Sudoku). Digits 1–6.
class SudokuSixBundle {
  SudokuSixBundle._(this.grid, this.solution, this.readOnlyKeys);

  /// Play grid (mutable).
  final List<List<int>> grid;

  /// Full valid solution.
  final List<List<int>> solution;

  /// `"row,col"` for givens from the initial puzzle.
  final Set<String> readOnlyKeys;

  static const dimension = 6;
  static const boxRows = 2;
  static const boxCols = 3;

  factory SudokuSixBundle.create(
    List<List<int>> puzzle,
    List<List<int>> solution,
  ) {
    final keys = <String>{};
    for (var r = 0; r < dimension; r++) {
      for (var c = 0; c < dimension; c++) {
        if (puzzle[r][c] != 0) {
          keys.add('$r,$c');
        }
      }
    }
    return SudokuSixBundle._(
      puzzle.map((row) => List<int>.from(row)).toList(),
      solution.map((row) => List<int>.from(row)).toList(),
      keys,
    );
  }

  static bool validPlacement(
    List<List<int>> g,
    int r,
    int c,
    int v,
  ) {
    if (v < 1 || v > dimension) return false;
    for (var i = 0; i < dimension; i++) {
      if (i != c && g[r][i] == v) return false;
      if (i != r && g[i][c] == v) return false;
    }
    final rs = r ~/ boxRows * boxRows;
    final cs = c ~/ boxCols * boxCols;
    for (var i = rs; i < rs + boxRows; i++) {
      for (var j = cs; j < cs + boxCols; j++) {
        if ((i != r || j != c) && g[i][j] == v) return false;
      }
    }
    return true;
  }

  /// No blanks and no duplicate violations in rows, columns, or 2×3 blocks.
  static bool gridSolvedAndValid(List<List<int>> g) {
    for (var r = 0; r < dimension; r++) {
      for (var c = 0; c < dimension; c++) {
        if (g[r][c] == 0) return false;
      }
    }
    for (var r = 0; r < dimension; r++) {
      for (var c = 0; c < dimension; c++) {
        final v = g[r][c];
        for (var i = 0; i < dimension; i++) {
          if (i != c && g[r][i] == v) return false;
          if (i != r && g[i][c] == v) return false;
        }
        final rs = r ~/ boxRows * boxRows;
        final cs = c ~/ boxCols * boxCols;
        for (var i = rs; i < rs + boxRows; i++) {
          for (var j = cs; j < cs + boxCols; j++) {
            if ((i != r || j != c) && g[i][j] == v) return false;
          }
        }
      }
    }
    return true;
  }

  static int _solutionCount(List<List<int>> board, int max, Random rnd) {
    var r0 = -1, c0 = -1;
    outer:
    for (var i = 0; i < dimension; i++) {
      for (var j = 0; j < dimension; j++) {
        if (board[i][j] == 0) {
          r0 = i;
          c0 = j;
          break outer;
        }
      }
    }
    if (r0 < 0) return 1;
    var count = 0;
    final order = List.generate(dimension, (i) => i + 1)..shuffle(rnd);
    for (final v in order) {
      if (!validPlacement(board, r0, c0, v)) continue;
      board[r0][c0] = v;
      count += _solutionCount(board, max - count, rnd);
      board[r0][c0] = 0;
      if (count >= max) return count;
    }
    return count;
  }

  static int solutionCount(List<List<int>> start, int max, Random rnd) {
    final b = start.map((row) => List<int>.from(row)).toList();
    return _solutionCount(b, max, rnd);
  }

  static bool _fillRandom(List<List<int>> g, Random rnd) {
    var r0 = -1, c0 = -1;
    outer:
    for (var i = 0; i < dimension; i++) {
      for (var j = 0; j < dimension; j++) {
        if (g[i][j] == 0) {
          r0 = i;
          c0 = j;
          break outer;
        }
      }
    }
    if (r0 < 0) return true;
    final order = List.generate(dimension, (i) => i + 1)..shuffle(rnd);
    for (final v in order) {
      if (!validPlacement(g, r0, c0, v)) continue;
      g[r0][c0] = v;
      if (_fillRandom(g, rnd)) return true;
      g[r0][c0] = 0;
    }
    return false;
  }

  static List<List<int>>? generateFullSolution(Random rnd) {
    final g = List.generate(
      dimension,
      (_) => List<int>.filled(dimension, 0),
      growable: false,
    );
    if (!_fillRandom(g, rnd)) return null;
    return g;
  }

  static int _countClues(List<List<int>> p) {
    var n = 0;
    for (final row in p) {
      for (final v in row) {
        if (v != 0) n++;
      }
    }
    return n;
  }

  static int _targetClues(GameDifficulty d) => switch (d) {
        GameDifficulty.easy => 30,
        GameDifficulty.medium => 24,
        GameDifficulty.expert => 18,
      };

  /// Builds a puzzle with a unique solution (fast on 6×6).
  static SudokuSixBundle generate(GameDifficulty difficulty) {
    final rnd = Random();
    List<List<int>>? solution;
    for (var attempt = 0; attempt < 100; attempt++) {
      solution = generateFullSolution(attempt == 0 ? rnd : Random());
      if (solution != null) break;
    }
    if (solution == null) {
      throw StateError('6×6 solution generation failed');
    }

    var puzzle = solution.map((row) => List<int>.from(row)).toList();
    final cells = <(int, int)>[];
    for (var i = 0; i < dimension; i++) {
      for (var j = 0; j < dimension; j++) {
        cells.add((i, j));
      }
    }
    cells.shuffle(rnd);
    final target = _targetClues(difficulty);
    for (final (r, c) in cells) {
      if (_countClues(puzzle) <= target) break;
      final keep = puzzle[r][c];
      puzzle[r][c] = 0;
      if (solutionCount(puzzle, 2, rnd) != 1) {
        puzzle[r][c] = keep;
      }
    }
    return SudokuSixBundle.create(puzzle, solution);
  }
}
