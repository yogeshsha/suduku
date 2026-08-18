import 'dart:async';
import 'dart:isolate';

import 'package:fludoku/fludoku.dart';
import 'package:flutter/foundation.dart';

import '../data/game_save_repository.dart';
import '../data/sudoku_fludoku_isolate.dart';
import '../data/sudoku_six_engine.dart';
import '../data/sudoku_twelve_engine.dart';
import '../domain/game_difficulty.dart';
import '../domain/sudoku_board_size.dart';
import '../domain/sudoku_saved_game.dart';

enum SudokuGameOutcome { won, lost }

/// Orchestrates puzzle generation, play state, mistakes, hints, and timing.
class SudokuGameController extends ChangeNotifier {
  SudokuGameController({this.maxMistakes = 3, SudokuBoardSize? boardSize})
    : _boardSize = boardSize ?? SudokuBoardSize.dim9;

  final int maxMistakes;
  final SudokuBoardSize _boardSize;

  Board? _board;
  SudokuSixBundle? _six;
  SudokuTwelveBundle? _twelve;
  List<List<int>>? _solutionValues;
  bool _loading = false;
  String? _error;
  int _mistakes = 0;
  int _hintsUsed = 0;
  int? _selectedRow;
  int? _selectedCol;
  GameDifficulty _difficulty = GameDifficulty.medium;
  SudokuGameOutcome? _pendingOutcome;
  int? _pendingMistakeAck;
  int? _highlightDigit;
  int _genToken = 0;

  Stopwatch? _gameClock;
  Timer? _tickTimer;
  Duration _elapsedOffset = Duration.zero;
  int _autosaveTicks = 0;

  /// Updated every second while the clock runs so the time stat can repaint
  /// without rebuilding the whole board (important for larger grids).
  final ValueNotifier<String> elapsedLabelNotifier = ValueNotifier<String>(
    '00:00',
  );

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
  SudokuBoardSize get boardSize => _boardSize;

  bool get _usesSix => _boardSize.usesCustomSixEngine;

  bool get _usesTwelve => _boardSize.usesCustomTwelveEngine;

  bool get hasPlayableGrid => _board != null || _six != null || _twelve != null;

  int get puzzleDimension {
    if (_board != null) return _board!.dimension;
    if (_six != null) return SudokuSixBundle.dimension;
    if (_twelve != null) return SudokuTwelveBundle.dimension;
    return _boardSize.dimension;
  }

  int get maxDigit {
    if (_board != null) return _board!.maxValue;
    if (_six != null) return SudokuSixBundle.dimension;
    if (_twelve != null) return SudokuTwelveBundle.dimension;
    return _boardSize.dimension;
  }

  static int _sqrtBoxSide(int dim) {
    var s = 1;
    while (s * s < dim) {
      s++;
    }
    return s * s == dim ? s : 3;
  }

  int get boxRowsResolved => _board != null
      ? _sqrtBoxSide(_board!.dimension)
      : _six != null
      ? SudokuSixBundle.boxRows
      : _twelve != null
      ? SudokuTwelveBundle.boxRows
      : _boardSize.boxRows;

  int get boxColsResolved => _board != null
      ? _sqrtBoxSide(_board!.dimension)
      : _six != null
      ? SudokuSixBundle.boxCols
      : _twelve != null
      ? SudokuTwelveBundle.boxCols
      : _boardSize.boxCols;

  Duration get elapsed => _elapsedOffset + (_gameClock?.elapsed ?? Duration.zero);
  String get elapsedLabel => elapsedLabelNotifier.value;

  int cellAt(int row, int col) {
    final b = _board;
    if (b != null) return b.getAt(row: row, col: col);
    final s = _six;
    if (s != null) return s.grid[row][col];
    final t = _twelve;
    if (t != null) return t.grid[row][col];
    return 0;
  }

  Set<int> get digitsFullyPlaced {
    final b = _board;
    if (b != null) {
      final dim = b.dimension;
      final out = <int>{};
      for (var d = 1; d <= b.maxValue; d++) {
        if (_countDigitFludoku(b, d) >= dim) out.add(d);
      }
      return out;
    }
    final s = _six;
    if (s != null) {
      final dim = SudokuSixBundle.dimension;
      final out = <int>{};
      for (var d = 1; d <= dim; d++) {
        if (_countDigitInGrid(s.grid, d) >= dim) out.add(d);
      }
      return out;
    }
    final t = _twelve;
    if (t != null) {
      final dim = SudokuTwelveBundle.dimension;
      final out = <int>{};
      for (var d = 1; d <= dim; d++) {
        if (_countDigitInGrid(t.grid, d) >= dim) out.add(d);
      }
      return out;
    }
    return const <int>{};
  }

  bool get canPlay =>
      hasPlayableGrid &&
      !_loading &&
      _pendingOutcome == null &&
      !isGameOver &&
      !isPuzzleComplete;

  bool get canHint {
    if (!canPlay) return false;
    final row = _selectedRow;
    final col = _selectedCol;
    if (row == null || col == null) return false;
    return !isGiven(row, col);
  }

  bool get isPuzzleComplete {
    final b = _board;
    if (b != null) return b.isComplete;
    final s = _six;
    if (s != null) return SudokuSixBundle.gridSolvedAndValid(s.grid);
    final t = _twelve;
    if (t != null) return SudokuTwelveBundle.gridSolvedAndValid(t.grid);
    return false;
  }

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
    final maxD = maxDigit;
    if (digit != null && (digit < 1 || digit > maxD)) return;
    if (_highlightDigit == digit) return;
    _highlightDigit = digit;
    notifyListeners();
  }

  void selectCell(int row, int col) {
    if (!hasPlayableGrid || _loading) return;
    if (_pendingOutcome != null) return;
    if (isPuzzleComplete) return;
    _selectedRow = row;
    _selectedCol = col;
    final v = cellAt(row, col);
    _highlightDigit = v != 0 ? v : null;
    notifyListeners();
  }

  void numberPadDigit(int digit) {
    final maxD = maxDigit;
    if (digit < 1 || digit > maxD) return;
    _highlightDigit = digit;
    notifyListeners();
    inputDigit(digit);
  }

  Future<void> startNewGame() async {
    final genId = ++_genToken;
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
    _six = null;
    _twelve = null;
    _solutionValues = null;
    elapsedLabelNotifier.value = '00:00';
    notifyListeners();
    unawaited(_clearSavedGame());

    try {
      if (_usesSix) {
        final bundle = SudokuSixBundle.generate(_difficulty);
        if (genId != _genToken) return;
        _six = bundle;
        _solutionValues = bundle.solution
            .map((r) => List<int>.from(r))
            .toList();
        _board = null;
        _twelve = null;
      } else if (_usesTwelve) {
        final diff = _difficulty;
        final grids = await Isolate.run(() {
          final b = SudokuTwelveBundle.generate(diff);
          return (
            puzzle: [for (final r in b.grid) List<int>.from(r)],
            solution: [for (final r in b.solution) List<int>.from(r)],
          );
        });
        if (genId != _genToken) return;
        _twelve = SudokuTwelveBundle.create(grids.puzzle, grids.solution);
        _solutionValues = grids.solution.map((r) => List<int>.from(r)).toList();
        _board = null;
        _six = null;
      } else {
        final dim = _boardSize.dimension;
        final ord = switch (_difficulty) {
          GameDifficulty.easy => 0,
          GameDifficulty.medium => 1,
          GameDifficulty.expert => 2,
        };
        final args = (
          dim: dim,
          timeout: _boardSize.generatorTimeoutSecs,
          difficultyOrdinal: ord,
        );
        final res = await Isolate.run(() => fludokuGenerateIsolate(args));
        if (genId != _genToken) return;
        if (res.err != null || res.puzzle == null || res.solution == null) {
          _error = res.err ?? 'Could not generate a puzzle. Try again.';
          _loading = false;
          notifyListeners();
          return;
        }
        _board = Board.withValues(res.puzzle!);
        _solutionValues = res.solution;
        _six = null;
        _twelve = null;
      }
    } catch (e) {
      if (genId != _genToken) return;
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return;
    }

    if (genId != _genToken) return;
    _loading = false;
    _startClock();
    notifyListeners();
    unawaited(_persistSnapshot());
  }

  /// Restores a game previously captured by [_persistSnapshot], reconstructing
  /// whichever engine's board/bundle matches [SudokuSavedGame.dimension].
  Future<void> resumeGame(SudokuSavedGame saved) async {
    final genId = ++_genToken;
    _tickTimer?.cancel();
    _tickTimer = null;
    _gameClock?.stop();
    _gameClock = null;
    _loading = true;
    _error = null;
    _pendingOutcome = null;
    _pendingMistakeAck = null;
    _mistakes = saved.mistakes;
    _hintsUsed = saved.hintsUsed;
    _selectedRow = saved.selectedRow;
    _selectedCol = saved.selectedCol;
    _highlightDigit = saved.highlightDigit;
    _difficulty = saved.difficulty;
    _board = null;
    _six = null;
    _twelve = null;
    _solutionValues = null;
    elapsedLabelNotifier.value = _formatDuration(
      Duration(milliseconds: saved.elapsedMs),
    );
    notifyListeners();

    try {
      if (_usesSix) {
        final bundle = SudokuSixBundle.create(
          saved.givensGrid,
          saved.solutionGrid,
        );
        _copyGridInto(saved.currentGrid, bundle.grid);
        if (genId != _genToken) return;
        _six = bundle;
        _solutionValues = bundle.solution
            .map((r) => List<int>.from(r))
            .toList();
        _board = null;
        _twelve = null;
      } else if (_usesTwelve) {
        final bundle = SudokuTwelveBundle.create(
          saved.givensGrid,
          saved.solutionGrid,
        );
        _copyGridInto(saved.currentGrid, bundle.grid);
        if (genId != _genToken) return;
        _twelve = bundle;
        _solutionValues = bundle.solution
            .map((r) => List<int>.from(r))
            .toList();
        _board = null;
        _six = null;
      } else {
        final board = Board.withValues(saved.givensGrid);
        for (var r = 0; r < saved.dimension; r++) {
          for (var c = 0; c < saved.dimension; c++) {
            final given = saved.givensGrid[r][c] != 0;
            final value = saved.currentGrid[r][c];
            if (!given && value != 0) {
              board.setAt(row: r, col: c, value: value);
            }
          }
        }
        if (genId != _genToken) return;
        _board = board;
        _solutionValues = saved.solutionGrid
            .map((r) => List<int>.from(r))
            .toList();
        _six = null;
        _twelve = null;
      }
    } catch (e) {
      if (genId != _genToken) return;
      _error = 'Could not resume your saved game. Start a new one.';
      _loading = false;
      _board = null;
      _six = null;
      _twelve = null;
      notifyListeners();
      unawaited(_clearSavedGame());
      return;
    }

    if (genId != _genToken) return;
    _loading = false;
    _startClock(initialOffset: Duration(milliseconds: saved.elapsedMs));
    notifyListeners();
  }

  static void _copyGridInto(List<List<int>> src, List<List<int>> dst) {
    for (var r = 0; r < src.length; r++) {
      for (var c = 0; c < src[r].length; c++) {
        dst[r][c] = src[r][c];
      }
    }
  }

  bool isGiven(int row, int col) {
    final b = _board;
    if (b != null) {
      return b.readOnlyPositions.contains((row: row, col: col));
    }
    final s = _six;
    if (s != null) {
      return s.readOnlyKeys.contains('$row,$col');
    }
    final t = _twelve;
    if (t != null) {
      return t.readOnlyKeys.contains('$row,$col');
    }
    return false;
  }

  void inputDigit(int digit) {
    if (!canPlay) return;
    final row = _selectedRow;
    final col = _selectedCol;
    if (row == null || col == null) return;
    if (isGiven(row, col)) return;

    final b = _board;
    if (b != null) {
      final ok = b.trySetAt(row: row, col: col, value: digit);
      if (!ok) {
        _registerMistake();
        return;
      }
      if (b.isComplete) {
        _stopClockForTerminalState();
        _pendingOutcome = SudokuGameOutcome.won;
      }
      _clearHighlightIfThatDigitIsComplete();
      notifyListeners();
      _persistOrClearIfWon();
      return;
    }

    final s = _six;
    if (s != null) {
      final g = s.grid;
      final old = g[row][col];
      g[row][col] = 0;
      final ok = SudokuSixBundle.validPlacement(g, row, col, digit);
      if (!ok) {
        g[row][col] = old;
        _registerMistake();
        return;
      }
      g[row][col] = digit;
      if (SudokuSixBundle.gridSolvedAndValid(g)) {
        _stopClockForTerminalState();
        _pendingOutcome = SudokuGameOutcome.won;
      }
      _clearHighlightIfThatDigitIsComplete();
      notifyListeners();
      _persistOrClearIfWon();
      return;
    }

    final t = _twelve;
    if (t != null) {
      final g = t.grid;
      final old = g[row][col];
      g[row][col] = 0;
      final ok = SudokuTwelveBundle.validPlacement(g, row, col, digit);
      if (!ok) {
        g[row][col] = old;
        _registerMistake();
        return;
      }
      g[row][col] = digit;
      if (SudokuTwelveBundle.gridSolvedAndValid(g)) {
        _stopClockForTerminalState();
        _pendingOutcome = SudokuGameOutcome.won;
      }
      _clearHighlightIfThatDigitIsComplete();
      notifyListeners();
      _persistOrClearIfWon();
    }
  }

  void _registerMistake() {
    _mistakes++;
    if (_mistakes >= maxMistakes) {
      _stopClockForTerminalState();
      _pendingOutcome = SudokuGameOutcome.lost;
    } else {
      _pendingMistakeAck = _mistakes;
    }
    notifyListeners();
    if (_pendingOutcome == SudokuGameOutcome.lost) {
      unawaited(_clearSavedGame());
    } else {
      unawaited(_persistSnapshot());
    }
  }

  /// Persists the in-progress snapshot, or clears it if this move just won
  /// the game (a finished game has nothing left to resume).
  void _persistOrClearIfWon() {
    if (_pendingOutcome == SudokuGameOutcome.won) {
      unawaited(_clearSavedGame());
    } else {
      unawaited(_persistSnapshot());
    }
  }

  void clearCell() {
    if (!canPlay) return;
    final row = _selectedRow;
    final col = _selectedCol;
    if (row == null || col == null) return;
    if (isGiven(row, col)) return;

    final b = _board;
    if (b != null) {
      try {
        b.setAt(row: row, col: col, value: 0);
      } on ArgumentError {
        return;
      }
      _highlightDigit = null;
      notifyListeners();
      unawaited(_persistSnapshot());
      return;
    }
    final s = _six;
    if (s != null) {
      s.grid[row][col] = 0;
      _highlightDigit = null;
      notifyListeners();
      unawaited(_persistSnapshot());
      return;
    }
    final t = _twelve;
    if (t != null) {
      t.grid[row][col] = 0;
      _highlightDigit = null;
      notifyListeners();
      unawaited(_persistSnapshot());
    }
  }

  void applyHint() {
    if (!canPlay) return;
    final row = _selectedRow;
    final col = _selectedCol;
    if (row == null || col == null) return;
    if (isGiven(row, col)) return;

    final sol = _solutionValues;
    if (sol == null) return;
    final target = sol[row][col];

    final b = _board;
    if (b != null) {
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
      _persistOrClearIfWon();
      return;
    }
    final s = _six;
    if (s != null) {
      s.grid[row][col] = target;
      _highlightDigit = target;
      _hintsUsed++;
      if (SudokuSixBundle.gridSolvedAndValid(s.grid)) {
        _stopClockForTerminalState();
        _pendingOutcome = SudokuGameOutcome.won;
      }
      _clearHighlightIfThatDigitIsComplete();
      notifyListeners();
      _persistOrClearIfWon();
      return;
    }
    final t = _twelve;
    if (t != null) {
      t.grid[row][col] = target;
      _highlightDigit = target;
      _hintsUsed++;
      if (SudokuTwelveBundle.gridSolvedAndValid(t.grid)) {
        _stopClockForTerminalState();
        _pendingOutcome = SudokuGameOutcome.won;
      }
      _clearHighlightIfThatDigitIsComplete();
      notifyListeners();
      _persistOrClearIfWon();
    }
  }

  static int _countDigitFludoku(Board b, int digit) {
    final dim = b.dimension;
    var n = 0;
    for (var r = 0; r < dim; r++) {
      for (var c = 0; c < dim; c++) {
        if (b.getAt(row: r, col: c) == digit) n++;
      }
    }
    return n;
  }

  static int _countDigitInGrid(List<List<int>> g, int digit) {
    var n = 0;
    for (final row in g) {
      for (final v in row) {
        if (v == digit) n++;
      }
    }
    return n;
  }

  void _clearHighlightIfThatDigitIsComplete() {
    final h = _highlightDigit;
    if (h == null) return;
    final b = _board;
    if (b != null) {
      if (_countDigitFludoku(b, h) >= b.dimension) {
        _highlightDigit = null;
      }
      return;
    }
    final s = _six;
    if (s != null) {
      if (_countDigitInGrid(s.grid, h) >= SudokuSixBundle.dimension) {
        _highlightDigit = null;
      }
      return;
    }
    final t = _twelve;
    if (t != null) {
      if (_countDigitInGrid(t.grid, h) >= SudokuTwelveBundle.dimension) {
        _highlightDigit = null;
      }
    }
  }

  void _startClock({Duration initialOffset = Duration.zero}) {
    _tickTimer?.cancel();
    _tickTimer = null;
    _gameClock?.stop();
    _elapsedOffset = initialOffset;
    _autosaveTicks = 0;
    _gameClock = Stopwatch()..start();
    _pushElapsedLabel();
    _armTickTimer();
  }

  void _armTickTimer() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _pushElapsedLabel();
      _autosaveTicks++;
      // Keeps a crash-recoverable snapshot roughly fresh even if the player
      // is just staring at the board without making a move.
      if (_autosaveTicks % 5 == 0 && _pendingOutcome == null) {
        unawaited(_persistSnapshot());
      }
    });
  }

  void _pushElapsedLabel() {
    final next = _formatDuration(elapsed);
    if (elapsedLabelNotifier.value != next) {
      elapsedLabelNotifier.value = next;
    }
  }

  void pauseSolveTimer() {
    if (_gameClock == null) return;
    _tickTimer?.cancel();
    _tickTimer = null;
    if (_gameClock!.isRunning) {
      _gameClock!.stop();
    }
    _pushElapsedLabel();
    notifyListeners();
    // The app is backgrounding or the route is being covered — exactly the
    // moment a crash or OS-kill is most likely, so checkpoint now.
    if (hasPlayableGrid && _pendingOutcome == null) {
      unawaited(_persistSnapshot());
    }
  }

  void resumeSolveTimer() {
    if (_gameClock == null) return;
    if (_loading || !hasPlayableGrid) return;
    if (_pendingOutcome != null) return;
    if (isPuzzleComplete) return;
    if (isGameOver) return;
    if (_gameClock!.isRunning) return;
    _gameClock!.start();
    _armTickTimer();
    _pushElapsedLabel();
    notifyListeners();
  }

  void _stopClockForTerminalState() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _gameClock?.stop();
    _pushElapsedLabel();
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

  /// Builds a resumable snapshot of the current game state.
  SudokuSavedGame _buildSnapshot() {
    final dim = puzzleDimension;
    final givens = List.generate(
      dim,
      (r) => List.generate(dim, (c) => isGiven(r, c) ? cellAt(r, c) : 0),
    );
    final current = List.generate(
      dim,
      (r) => List.generate(dim, (c) => cellAt(r, c)),
    );
    return SudokuSavedGame(
      dimension: dim,
      difficultyKey: _difficulty.name,
      mistakes: _mistakes,
      hintsUsed: _hintsUsed,
      elapsedMs: elapsed.inMilliseconds,
      selectedRow: _selectedRow,
      selectedCol: _selectedCol,
      highlightDigit: _highlightDigit,
      givensGrid: givens,
      currentGrid: current,
      solutionGrid: _solutionValues!,
      savedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _persistSnapshot() async {
    if (!hasPlayableGrid || _solutionValues == null) return;
    try {
      final repo = await GameSaveRepository.instance();
      await repo.save(_buildSnapshot());
    } catch (_) {
      // Persistence is best-effort; gameplay should still feel complete.
    }
  }

  Future<void> _clearSavedGame() async {
    try {
      final repo = await GameSaveRepository.instance();
      await repo.clear();
    } catch (_) {
      // Best-effort.
    }
  }

  @override
  void dispose() {
    _genToken++;
    _tickTimer?.cancel();
    elapsedLabelNotifier.dispose();
    super.dispose();
  }
}
