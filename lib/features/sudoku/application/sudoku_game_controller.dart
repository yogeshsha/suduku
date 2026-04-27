import 'dart:async';

import 'package:fludoku/fludoku.dart';
import 'package:flutter/foundation.dart';

import '../domain/game_difficulty.dart';

enum SudokuGameOutcome { won, lost }

/// Orchestrates puzzle generation ([fludoku]), play state, mistakes, hints,
/// elapsed time, and digit highlighting.
class SudokuGameController extends ChangeNotifier {
  SudokuGameController({this.maxMistakes = 3});

  final int maxMistakes;

  Board? _board;
  List<List<int>>? _solutionValues;
  bool _loading = false;
  String? _error;
  int _mistakes = 0;
  int _hintsUsed = 0;
  int? _selectedRow;
  int? _selectedCol;
  GameDifficulty _difficulty = GameDifficulty.medium;
  SudokuGameOutcome? _pendingOutcome;

  /// Set after a wrong digit when the game is still playable; UI shows feedback then calls [consumeMistakeAck].
  int? _pendingMistakeAck;

  /// Digit 1–9 to emphasize across the grid (from cell or number pad).
  int? _highlightDigit;

  Stopwatch? _gameClock;
  Timer? _tickTimer;

  Board? get board => _board;
  bool get loading => _loading;
  String? get error => _error;
  int get mistakes => _mistakes;
  int get hintsUsed => _hintsUsed;
  int? get selectedRow => _selectedRow;
  int? get selectedCol => _selectedCol;
  GameDifficulty get difficulty => _difficulty;
  SudokuGameOutcome? get pendingOutcome => _pendingOutcome;
  int? get pendingMistakeAck => _pendingMistakeAck;
  int? get highlightDigit => _highlightDigit;

  /// Elapsed time since the current puzzle became playable (loading finished).
  Duration get elapsed => _gameClock?.elapsed ?? Duration.zero;

  String get elapsedLabel => _formatDuration(elapsed);

  /// Digits 1–9 that already appear nine times on the grid (hide from pad).
  Set<int> get digitsFullyPlaced {
    final b = _board;
    if (b == null) return const <int>{};
    final out = <int>{};
    for (var d = 1; d <= 9; d++) {
      if (_countDigitOnBoard(b, d) >= 9) {
        out.add(d);
      }
    }
    return out;
  }

  bool get canPlay =>
      _board != null &&
      !_loading &&
      _pendingOutcome == null &&
      !isGameOver &&
      !(_board!.isComplete);

  bool get isGameOver => _mistakes >= maxMistakes;

  void setDifficulty(GameDifficulty value) {
    if (_difficulty == value) return;
    _difficulty = value;
    notifyListeners();
  }

  void consumeOutcome() {
    _pendingOutcome = null;
    notifyListeners();
  }

  void consumeMistakeAck() {
    if (_pendingMistakeAck == null) return;
    _pendingMistakeAck = null;
    notifyListeners();
  }

  void setHighlightDigit(int? digit) {
    if (digit != null && (digit < 1 || digit > 9)) return;
    if (_highlightDigit == digit) return;
    _highlightDigit = digit;
    notifyListeners();
  }

  void selectCell(int row, int col) {
    if (_board == null || _loading) return;
    if (_pendingOutcome != null) return;
    if (_board!.isComplete) return;
    _selectedRow = row;
    _selectedCol = col;

    final v = _board!.getAt(row: row, col: col);
    _highlightDigit = v != 0 ? v : null;

    notifyListeners();
  }

  /// Highlights [digit] then applies it to the selected cell (if any).
  void numberPadDigit(int digit) {
    if (digit < 1 || digit > 9) return;
    _highlightDigit = digit;
    notifyListeners();
    inputDigit(digit);
  }

  /// Starts a new puzzle for the current [_difficulty].
  void startNewGame() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _gameClock?.stop();
    _gameClock = null;
    _highlightDigit = null;
    _loading = true;
    _error = null;
    _pendingOutcome = null;
    _pendingMistakeAck = null;
    _mistakes = 0;
    _hintsUsed = 0;
    _selectedRow = null;
    _selectedCol = null;
    _board = null;
    _solutionValues = null;
    notifyListeners();

    final (puzzle, err) = generateSudokuPuzzle(
      level: _difficulty.puzzleLevel,
      dimension: 9,
      timeoutSecs: 45,
    );

    if (puzzle == null) {
      _error = err ?? 'Could not generate a puzzle. Try again.';
      _loading = false;
      notifyListeners();
      return;
    }

    try {
      final solutions = findSolutions(Board.clone(puzzle), maxSolutions: 1);
      _solutionValues = solutions.first.values;
    } catch (_) {
      _error = 'Solver failed for generated puzzle. Try again.';
      _loading = false;
      notifyListeners();
      return;
    }

    _board = puzzle;
    _loading = false;
    _startClock();
    notifyListeners();
  }

  bool isGiven(int row, int col) {
    final b = _board;
    if (b == null) return false;
    return b.readOnlyPositions.contains((row: row, col: col));
  }

  /// Places [digit] (1–9) on the selected cell. Invalid moves increment mistakes.
  void inputDigit(int digit) {
    final b = _board;
    if (b == null || !canPlay) return;
    final row = _selectedRow;
    final col = _selectedCol;
    if (row == null || col == null) return;
    if (isGiven(row, col)) return;

    final ok = b.trySetAt(row: row, col: col, value: digit);
    if (!ok) {
      _mistakes++;
      if (_mistakes >= maxMistakes) {
        _stopClockForTerminalState();
        _pendingOutcome = SudokuGameOutcome.lost;
      } else {
        _pendingMistakeAck = _mistakes;
      }
      notifyListeners();
      return;
    }

    if (b.isComplete) {
      _stopClockForTerminalState();
      _pendingOutcome = SudokuGameOutcome.won;
    }
    _clearHighlightIfThatDigitIsComplete();
    notifyListeners();
  }

  void clearCell() {
    final b = _board;
    if (b == null || !canPlay) return;
    final row = _selectedRow;
    final col = _selectedCol;
    if (row == null || col == null) return;
    if (isGiven(row, col)) return;

    try {
      b.setAt(row: row, col: col, value: 0);
    } on ArgumentError {
      // Should not happen for clearing to blank on a non-read-only cell.
    }
    _highlightDigit = null;
    notifyListeners();
  }

  /// Fills the selected blank with the solution digit (from cached solve).
  void applyHint() {
    final b = _board;
    final sol = _solutionValues;
    if (b == null || sol == null || !canPlay) return;
    final row = _selectedRow;
    final col = _selectedCol;
    if (row == null || col == null) return;
    if (isGiven(row, col)) return;

    final target = sol[row][col];
    try {
      b.setAt(row: row, col: col, value: target);
    } on ArgumentError {
      return;
    }

    _highlightDigit = target;
    _hintsUsed++;

    if (b.isComplete) {
      _stopClockForTerminalState();
      _pendingOutcome = SudokuGameOutcome.won;
    }
    _clearHighlightIfThatDigitIsComplete();
    notifyListeners();
  }

  static int _countDigitOnBoard(Board b, int digit) {
    var n = 0;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (b.getAt(row: r, col: c) == digit) {
          n++;
        }
      }
    }
    return n;
  }

  void _clearHighlightIfThatDigitIsComplete() {
    final h = _highlightDigit;
    final b = _board;
    if (h == null || b == null) return;
    if (_countDigitOnBoard(b, h) >= 9) {
      _highlightDigit = null;
    }
  }

  void _startClock() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _gameClock?.stop();
    _gameClock = Stopwatch()..start();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  /// Stops the tick and the stopwatch without discarding elapsed time (win/loss).
  void pauseSolveTimer() {
    if (_gameClock == null) return;
    _tickTimer?.cancel();
    _tickTimer = null;
    if (_gameClock!.isRunning) {
      _gameClock!.stop();
    }
    notifyListeners();
  }

  /// Continues timing after [pauseSolveTimer] when the puzzle is still in play.
  void resumeSolveTimer() {
    if (_gameClock == null) return;
    if (_loading || _board == null) return;
    if (_pendingOutcome != null) return;
    if (_board!.isComplete) return;
    if (isGameOver) return;
    if (_gameClock!.isRunning) return;
    _gameClock!.start();
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
    notifyListeners();
  }

  void _stopClockForTerminalState() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _gameClock?.stop();
  }

  static String _formatDuration(Duration d) {
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

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }
}
