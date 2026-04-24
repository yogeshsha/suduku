import 'package:fludoku/fludoku.dart';

/// Player-facing difficulty; maps to [PuzzleDifficulty] for puzzle generation.
enum GameDifficulty {
  easy,
  medium,
  expert,
}

GameDifficulty gameDifficultyFromName(String name) {
  for (final v in GameDifficulty.values) {
    if (v.name == name) return v;
  }
  return GameDifficulty.medium;
}

extension GameDifficultyX on GameDifficulty {
  PuzzleDifficulty get puzzleLevel => switch (this) {
        GameDifficulty.easy => PuzzleDifficulty.easy,
        GameDifficulty.medium => PuzzleDifficulty.medium,
        GameDifficulty.expert => PuzzleDifficulty.hard,
      };

  String get title => switch (this) {
        GameDifficulty.easy => 'Easy',
        GameDifficulty.medium => 'Medium',
        GameDifficulty.expert => 'Expert',
      };

  String get subtitle => switch (this) {
        GameDifficulty.easy => 'More clues, gentler logic',
        GameDifficulty.medium => 'Balanced challenge',
        GameDifficulty.expert => 'Fewer clues, deeper deduction',
      };
}
