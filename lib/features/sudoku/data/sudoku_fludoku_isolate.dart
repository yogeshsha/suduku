import 'dart:async';
import 'dart:math' as math;

import 'package:fludoku/fludoku.dart';

/// Serializable args for [fludokuGenerateIsolate].
typedef FludokuGenArgs = ({int dim, int timeout, int difficultyOrdinal});

PuzzleDifficulty _fludokuLevelForDimension(int dim, int difficultyOrdinal) {
  final base = switch (difficultyOrdinal) {
    0 => PuzzleDifficulty.easy,
    1 => PuzzleDifficulty.medium,
    _ => PuzzleDifficulty.hard,
  };
  // 16×16 with fludoku "hard" targets ~183 blanks; the uniqueness loop
  // (repeated 2-solution searches) becomes impractically slow and often times
  // out. Cap at medium so games actually finish generating.
  if (dim == 16 && base == PuzzleDifficulty.hard) {
    return PuzzleDifficulty.medium;
  }
  return base;
}

/// Runs on a background isolate so large grids do not block the UI thread.
({List<List<int>>? puzzle, List<List<int>>? solution, String? err})
fludokuGenerateIsolate(FludokuGenArgs args) {
  final level = _fludokuLevelForDimension(args.dim, args.difficultyOrdinal);
  final (puzzle, err) = generateSudokuPuzzle(
    level: level,
    dimension: args.dim,
    timeoutSecs: args.timeout,
  );
  if (puzzle == null) {
    return (puzzle: null, solution: null, err: err ?? 'Generation failed.');
  }
  // Generation already proved a unique solution exists, but fludoku does not
  // return it. We must solve once for hints — without a tracker this phase
  // could hang indefinitely on large boards.
  final solveBudgetMs = args.dim >= 16
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
