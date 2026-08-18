import 'game_difficulty.dart';

/// A snapshot of an in-progress game, persisted so play can resume after the
/// app is closed, backgrounded, or crashes.
class SudokuSavedGame {
  const SudokuSavedGame({
    required this.dimension,
    required this.difficultyKey,
    required this.mistakes,
    required this.hintsUsed,
    required this.elapsedMs,
    required this.selectedRow,
    required this.selectedCol,
    required this.highlightDigit,
    required this.givensGrid,
    required this.currentGrid,
    required this.solutionGrid,
    required this.savedAtEpochMs,
  });

  /// Grid edge length (4, 6, 9, 12).
  final int dimension;
  final String difficultyKey;
  final int mistakes;
  final int hintsUsed;
  final int elapsedMs;
  final int? selectedRow;
  final int? selectedCol;
  final int? highlightDigit;

  /// The original puzzle: non-zero cells are the given (read-only) clues.
  final List<List<int>> givensGrid;

  /// The board as the player currently has it (givens + entries so far).
  final List<List<int>> currentGrid;

  /// Full solved grid, needed for hints after resuming.
  final List<List<int>> solutionGrid;

  final int savedAtEpochMs;

  GameDifficulty get difficulty => gameDifficultyFromName(difficultyKey);

  Duration get elapsed => Duration(milliseconds: elapsedMs);

  Map<String, dynamic> toJson() => {
    'dimension': dimension,
    'difficultyKey': difficultyKey,
    'mistakes': mistakes,
    'hintsUsed': hintsUsed,
    'elapsedMs': elapsedMs,
    'selectedRow': selectedRow,
    'selectedCol': selectedCol,
    'highlightDigit': highlightDigit,
    'givensGrid': givensGrid,
    'currentGrid': currentGrid,
    'solutionGrid': solutionGrid,
    'savedAtEpochMs': savedAtEpochMs,
  };

  factory SudokuSavedGame.fromJson(Map<String, dynamic> json) {
    return SudokuSavedGame(
      dimension: (json['dimension'] as num).toInt(),
      difficultyKey: json['difficultyKey'] as String,
      mistakes: (json['mistakes'] as num).toInt(),
      hintsUsed: (json['hintsUsed'] as num).toInt(),
      elapsedMs: (json['elapsedMs'] as num).toInt(),
      selectedRow: (json['selectedRow'] as num?)?.toInt(),
      selectedCol: (json['selectedCol'] as num?)?.toInt(),
      highlightDigit: (json['highlightDigit'] as num?)?.toInt(),
      givensGrid: _gridFromJson(json['givensGrid']),
      currentGrid: _gridFromJson(json['currentGrid']),
      solutionGrid: _gridFromJson(json['solutionGrid']),
      savedAtEpochMs: (json['savedAtEpochMs'] as num).toInt(),
    );
  }

  static List<List<int>> _gridFromJson(Object? raw) {
    final rows = raw as List<dynamic>;
    return rows
        .map(
          (row) => (row as List<dynamic>)
              .map((v) => (v as num).toInt())
              .toList(),
        )
        .toList();
  }
}
