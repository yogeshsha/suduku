import 'package:fludoku/fludoku.dart';

/// Serializable args for [fludokuGenerateIsolate].
typedef FludokuGenArgs = ({
  int dim,
  int timeout,
  int difficultyOrdinal,
});

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
  try {
    final solutions = findSolutions(Board.clone(puzzle), maxSolutions: 1);
    return (
      puzzle: puzzle.values,
      solution: solutions.first.values,
      err: null,
    );
  } catch (e) {
    return (puzzle: null, solution: null, err: e.toString());
  }
}
