import 'game_difficulty.dart';

/// A stored finished game (win or loss) for local history.
class SudokuWinRecord {
  const SudokuWinRecord({
    required this.id,
    required this.completedAtEpochMs,
    required this.durationMs,
    required this.difficultyKey,
    required this.mistakes,
    required this.hintsUsed,
    this.outcomeKey = 'win',
    this.dimension = 9,
  });

  final String id;
  final int completedAtEpochMs;
  final int durationMs;
  final String difficultyKey;
  final int mistakes;
  final int hintsUsed;

  /// Grid edge length (4, 6, 9, or 16). Legacy JSON defaults to 9.
  final int dimension;

  /// `'win'` or `'lost'` (legacy JSON omits this → win).
  final String outcomeKey;

  bool get isWin => outcomeKey == 'win';
  bool get isLost => outcomeKey == 'lost';

  GameDifficulty get difficulty => gameDifficultyFromName(difficultyKey);

  Duration get duration => Duration(milliseconds: durationMs);

  String get durationLabel => formatSolveDuration(duration);

  DateTime get completedAt =>
      DateTime.fromMillisecondsSinceEpoch(completedAtEpochMs, isUtc: false);

  Map<String, dynamic> toJson() => {
        'id': id,
        'completedAtEpochMs': completedAtEpochMs,
        'durationMs': durationMs,
        'difficultyKey': difficultyKey,
        'mistakes': mistakes,
        'hintsUsed': hintsUsed,
        'outcomeKey': outcomeKey,
        'dimension': dimension,
      };

  factory SudokuWinRecord.fromJson(Map<String, dynamic> json) {
    return SudokuWinRecord(
      id: json['id'] as String,
      completedAtEpochMs: json['completedAtEpochMs'] as int,
      durationMs: json['durationMs'] as int,
      difficultyKey: json['difficultyKey'] as String,
      mistakes: json['mistakes'] as int,
      hintsUsed: (json['hintsUsed'] as num?)?.toInt() ?? 0,
      outcomeKey: json['outcomeKey'] as String? ?? 'win',
      dimension: (json['dimension'] as num?)?.toInt() ?? 9,
    );
  }

  factory SudokuWinRecord.capture({
    required GameDifficulty difficulty,
    required Duration elapsed,
    required int mistakes,
    required int hintsUsed,
    required int dimension,
  }) {
    final now = DateTime.now();
    return SudokuWinRecord(
      id: '${now.millisecondsSinceEpoch}_${now.microsecondsSinceEpoch}',
      completedAtEpochMs: now.millisecondsSinceEpoch,
      durationMs: elapsed.inMilliseconds,
      difficultyKey: difficulty.name,
      mistakes: mistakes,
      hintsUsed: hintsUsed,
      outcomeKey: 'win',
      dimension: dimension,
    );
  }

  factory SudokuWinRecord.captureLoss({
    required GameDifficulty difficulty,
    required Duration elapsed,
    required int mistakes,
    required int hintsUsed,
    required int dimension,
  }) {
    final now = DateTime.now();
    return SudokuWinRecord(
      id: '${now.millisecondsSinceEpoch}_${now.microsecondsSinceEpoch}',
      completedAtEpochMs: now.millisecondsSinceEpoch,
      durationMs: elapsed.inMilliseconds,
      difficultyKey: difficulty.name,
      mistakes: mistakes,
      hintsUsed: hintsUsed,
      outcomeKey: 'lost',
      dimension: dimension,
    );
  }

  static String formatSolveDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    if (h > 0) {
      return '$h:$mm:$ss';
    }
    return '$mm:$ss';
  }
}
