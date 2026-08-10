import 'dart:async';
import 'dart:math' as math;

import 'package:fludoku/fludoku.dart';

/// Serializable args for [fludokuGenerateIsolate].
typedef FludokuGenArgs = ({int dim, int timeout, int difficultyOrdinal});

/// Runs on a background isolate so large grids do not block the UI thread.
({List<List<int>>? puzzle, List<List<int>>? solution, String? err})
fludokuGenerateIsolate(FludokuGenArgs args) {
  final level = switch (args.difficultyOrdinal) {
    0 => PuzzleDifficulty.easy,
    1 => PuzzleDifficulty.medium,
    _ => PuzzleDifficulty.hard,
  };
  final (puzzle, err) = generateSudokuPuzzle(
    level: level,
    dimension: args.dim,
    timeoutSecs: args.timeout,
  );
  if (puzzle == null) {
    return (puzzle: null, solution: null, err: err ?? 'Generation failed.');
  }
  final solveBudgetMs = args.dim > 9
      ? math.max(90_000, args.timeout * 700)
      : math.max(20_000, args.timeout * 250);
  final solveTracker = TimeoutTracker(solveBudgetMs);
  try {
    final solutions = findSolutions(
      Board.clone(puzzle),
      maxSolutions: 1,
      tracker: solveTracker,
    );
    return (puzzle: puzzle.values, solution: solutions.first.values, err: null);
  } on TimeoutException {
    return (
      puzzle: null,
      solution: null,
      err: 'Solving the puzzle for hints took too long. Try New puzzle.',
    );
  } catch (e) {
    return (puzzle: null, solution: null, err: e.toString());
  }
}
