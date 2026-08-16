import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../route_observer.dart';
import '../../../../theme/theme_mode_picker_button.dart';
import '../../application/sudoku_game_controller.dart';
import '../../data/win_history_repository.dart';
import '../../domain/game_difficulty.dart';
import '../../domain/sudoku_board_size.dart';
import '../../domain/sudoku_win_record.dart';
import '../widgets/animated_success_dialog.dart';
import '../widgets/confetti_burst.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/how_to_play.dart';
import '../widgets/mistake_and_game_over_dialogs.dart';
import '../widgets/number_pad.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/pulse_loop.dart';
import '../widgets/shake_on_signal.dart';
import '../widgets/signal_flash.dart';
import '../widgets/sudoku_grid.dart';

class SudokuGamePage extends StatefulWidget {
  const SudokuGamePage({
    super.key,
    required this.difficulty,
    required this.boardSize,
  });

  final GameDifficulty difficulty;
  final SudokuBoardSize boardSize;

  @override
  State<SudokuGamePage> createState() => _SudokuGamePageState();
}

class _SudokuGamePageState extends State<SudokuGamePage>
    with RouteAware, WidgetsBindingObserver {
  late final SudokuGameController _controller = SudokuGameController(
    boardSize: widget.boardSize,
  );
  bool _outcomeDialogScheduled = false;
  bool _mistakeDialogScheduled = false;

  bool _userPaused = false;
  bool _routeCovered = false;
  bool _appBackgrounded = false;

  // Motion signals. Tokens only ever increase; widgets replay their one-shot
  // animation whenever the value they watch changes.
  bool _expectCellEntrance = true;
  int _errorToken = 0;
  int _waveToken = 0;
  int _defeatToken = 0;
  int _confettiToken = 0;
  int? _pulseDigit;
  int? _pulseBoxIndex;
  String? _celebrationMessage;
  Timer? _celebrationTimer;
  int _prevMistakes = 0;
  Set<int> _prevCompletedDigits = const <int>{};
  Set<int> _prevCompletedBoxes = const <int>{};
  bool _wasLoading = false;

  bool get _ambientPaused => _routeCovered || _appBackgrounded;

  bool get _gameUiPaused =>
      _controller.hasPlayableGrid &&
      !_controller.loading &&
      (_userPaused || _ambientPaused);

  bool _routeAwareSubscribed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_onController);
    _controller.setDifficulty(widget.difficulty);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_controller.startNewGame());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeAwareSubscribed) return;
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      appRouteObserver.subscribe(this, route);
      _routeAwareSubscribed = true;
    }
  }

  @override
  void dispose() {
    _celebrationTimer?.cancel();
    if (_routeAwareSubscribed) {
      appRouteObserver.unsubscribe(this);
    }
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onController);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didPushNext() {
    _setRouteCovered(true);
  }

  @override
  void didPopNext() {
    _setRouteCovered(false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _setAppBackgrounded(true);
    } else if (state == AppLifecycleState.resumed) {
      _setAppBackgrounded(false);
    }
  }

  void _setRouteCovered(bool value) {
    if (_routeCovered == value) return;
    setState(() => _routeCovered = value);
    _syncClockToPauseState();
  }

  void _setAppBackgrounded(bool value) {
    if (_appBackgrounded == value) return;
    setState(() => _appBackgrounded = value);
    _syncClockToPauseState();
  }

  void _setUserPaused(bool value) {
    if (_userPaused == value) return;
    setState(() => _userPaused = value);
    _syncClockToPauseState();
  }

  void _syncClockToPauseState() {
    final paused = _userPaused || _ambientPaused;
    if (paused) {
      _controller.pauseSolveTimer();
    } else {
      _controller.resumeSolveTimer();
    }
  }

  void _beginNewGame() {
    setState(() => _userPaused = false);
    unawaited(
      _controller.startNewGame().then((_) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _syncClockToPauseState();
          });
        }
      }),
    );
  }

  void _onController() {
    _syncMotionSignals();

    final outcome = _controller.pendingOutcome;
    if (outcome != null && !_outcomeDialogScheduled) {
      _outcomeDialogScheduled = true;
      if (outcome == SudokuGameOutcome.won) {
        _waveToken++;
        _confettiToken++;
      } else {
        _defeatToken++;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await _showOutcome(outcome);
        } finally {
          if (mounted) {
            _outcomeDialogScheduled = false;
          }
        }
      });
    } else if (_controller.pendingMistakeAck != null &&
        !_mistakeDialogScheduled) {
      _mistakeDialogScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          if (!mounted) return;
          // Let the invalid-move flash and shake on the board land first.
          await Future<void>.delayed(const Duration(milliseconds: 420));
          if (!mounted) return;
          if (_controller.pendingMistakeAck == null) return;
          final mistakes = _controller.mistakes;
          final maxMistakes = _controller.maxMistakes;
          _controller.consumeMistakeAck();
          await showMistakeFeedbackDialog(
            context: context,
            mistakes: mistakes,
            maxMistakes: maxMistakes,
          );
        } finally {
          if (mounted) {
            _mistakeDialogScheduled = false;
          }
        }
      });
    }
    setState(() {});
  }

  /// Diffs controller state against the last notification and raises the
  /// one-shot animation signals consumed by the grid, pad, and overlays.
  void _syncMotionSignals() {
    final loading = _controller.loading;
    if (loading && !_wasLoading) {
      // A fresh puzzle build started: reset progress tracking.
      _prevMistakes = 0;
      _prevCompletedDigits = const <int>{};
      _prevCompletedBoxes = const <int>{};
      _expectCellEntrance = true;
      _pulseDigit = null;
      _pulseBoxIndex = null;
      _celebrationTimer?.cancel();
      _celebrationMessage = null;
    } else if (!loading &&
        _wasLoading &&
        _controller.hasPlayableGrid &&
        _expectCellEntrance) {
      // Cells captured the entrance flag in this build; stop offering it so a
      // later remount (pause/resume) does not replay the cascade.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_controller.loading && _controller.hasPlayableGrid) {
          setState(() => _expectCellEntrance = false);
        }
      });
    }
    _wasLoading = loading;

    if (_controller.mistakes > _prevMistakes) {
      _errorToken++;
    }
    _prevMistakes = _controller.mistakes;

    final playing =
        !_controller.loading &&
        _controller.hasPlayableGrid &&
        _controller.pendingOutcome == null &&
        !_controller.isGameOver;
    if (!playing) return;

    final digits = _controller.digitsFullyPlaced;
    final newDigits = digits.difference(_prevCompletedDigits);
    if (newDigits.isNotEmpty) {
      _pulseDigit = newDigits.last;
      _showCelebrationMessage('Number $_pulseDigit complete!');
    }
    _prevCompletedDigits = digits;

    final boxes = _completedBoxIndexes();
    final newBoxes = boxes.difference(_prevCompletedBoxes);
    if (newBoxes.isNotEmpty) {
      _pulseBoxIndex = newBoxes.last;
      _showCelebrationMessage('Box complete!');
    }
    _prevCompletedBoxes = boxes;
  }

  Set<int> _completedBoxIndexes() {
    final dim = _controller.puzzleDimension;
    final boxRows = _controller.boxRowsResolved;
    final boxCols = _controller.boxColsResolved;
    final boxesPerRow = dim ~/ boxCols;
    final completed = <int>{};
    for (var r = 0; r < dim; r += boxRows) {
      for (var c = 0; c < dim; c += boxCols) {
        var full = true;
        for (var i = 0; i < boxRows && full; i++) {
          for (var j = 0; j < boxCols; j++) {
            if (_controller.cellAt(r + i, c + j) == 0) {
              full = false;
              break;
            }
          }
        }
        if (full) {
          completed.add((r ~/ boxRows) * boxesPerRow + (c ~/ boxCols));
        }
      }
    }
    return completed;
  }

  void _showCelebrationMessage(String message) {
    _celebrationTimer?.cancel();
    _celebrationMessage = message;
    _celebrationTimer = Timer(const Duration(milliseconds: 1500), () {
      // Also retire the pulse signals so the same box or digit can celebrate
      // again if the player empties and refills it.
      if (mounted) {
        setState(() {
          _celebrationMessage = null;
          _pulseDigit = null;
          _pulseBoxIndex = null;
        });
      }
    });
  }

  void _confirmExitGame() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.exit_to_app_rounded,
          size: 36,
          color: colorScheme.primary,
        ),
        title: const Text('Exit game?'),
        content: const Text(
          'Are you sure you want to leave? Your puzzle progress stays on this '
          'device until you start a new game.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep playing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    ).then((exit) {
      if (exit == true && mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _confirmNewGame() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.refresh_rounded, size: 36, color: colorScheme.primary),
        title: const Text('New game?'),
        content: const Text(
          'Are you sure you want a new game? Your current puzzle progress will '
          'be replaced.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('New game'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        _beginNewGame();
      }
    });
  }

  Future<void> _showOutcome(SudokuGameOutcome outcome) async {
    if (!mounted) return;
    if (_controller.pendingOutcome != outcome) return;

    // Let the celebration (confetti + board wave) or the defeat beat (shake +
    // vignette + desaturation) breathe before the dialog takes the stage.
    await Future<void>.delayed(
      outcome == SudokuGameOutcome.won
          ? const Duration(milliseconds: 800)
          : const Duration(milliseconds: 620),
    );
    if (!mounted) return;
    if (_controller.pendingOutcome != outcome) return;

    if (outcome == SudokuGameOutcome.won) {
      final time = _controller.elapsedLabel;
      final record = SudokuWinRecord.capture(
        difficulty: _controller.difficulty,
        elapsed: _controller.elapsed,
        mistakes: _controller.mistakes,
        hintsUsed: _controller.hintsUsed,
        dimension: _controller.puzzleDimension,
      );
      try {
        final repo = await WinHistoryRepository.instance();
        await repo.addWin(record);
      } catch (_) {
        // Persistence is best-effort; gameplay should still feel complete.
      }
      if (!mounted) return;
      await showAnimatedSuccessDialog(
        context: context,
        timeLabel: time,
        difficulty: _controller.difficulty,
        mistakes: _controller.mistakes,
        hintsUsed: _controller.hintsUsed,
        onNewGame: () {
          if (!mounted) return;
          _beginNewGame();
        },
        onHome: () {
          if (!mounted) return;
          Navigator.of(context).pop();
        },
      );
    } else {
      final time = _controller.elapsedLabel;
      final lossRecord = SudokuWinRecord.captureLoss(
        difficulty: _controller.difficulty,
        elapsed: _controller.elapsed,
        mistakes: _controller.mistakes,
        hintsUsed: _controller.hintsUsed,
        dimension: _controller.puzzleDimension,
      );
      try {
        final repo = await WinHistoryRepository.instance();
        await repo.addRecord(lossRecord);
      } catch (_) {
        // Persistence is best-effort.
      }
      if (!mounted) return;
      await showGameOverDialog(
        context: context,
        timeLabel: time,
        difficulty: _controller.difficulty,
        mistakes: _controller.mistakes,
        maxMistakes: _controller.maxMistakes,
        hintsUsed: _controller.hintsUsed,
        onNewGame: () {
          if (!mounted) return;
          _beginNewGame();
        },
        onHome: () {
          if (!mounted) return;
          Navigator.of(context).pop();
        },
      );
    }
    if (!mounted) return;
    _controller.consumeOutcome();
  }

  bool get _canUsePauseControl {
    if (!_controller.hasPlayableGrid || _controller.loading) return false;
    if (_controller.pendingOutcome != null) return false;
    if (_controller.isPuzzleComplete || _controller.isGameOver) return false;
    if (_ambientPaused) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasGrid = _controller.hasPlayableGrid;
    final loading = _controller.loading;
    final err = _controller.error;
    final defeated =
        _controller.pendingOutcome == SudokuGameOutcome.lost;
    final mistakesRatio = (_controller.mistakes / _controller.maxMistakes)
        .clamp(0.0, 1.0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _confirmExitGame();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _confirmExitGame,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sudoku',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${widget.boardSize.label} · ${_controller.difficulty.title}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'How to play',
              onPressed: () => showHowToPlay(context),
              icon: const Icon(Icons.help_outline_rounded),
            ),
            const ThemeModePickerButton(),
            if (_userPaused)
              IconButton(
                tooltip: 'Resume',
                onPressed: () => _setUserPaused(false),
                icon: const Icon(Icons.play_arrow_rounded),
              )
            else
              IconButton(
                tooltip: 'Pause',
                onPressed: _canUsePauseControl
                    ? () => _setUserPaused(true)
                    : null,
                icon: const Icon(Icons.pause_rounded),
              ),
            IconButton(
              tooltip: 'New puzzle',
              onPressed: _controller.loading ? null : _confirmNewGame,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FadeSlideIn(
                            index: 0,
                            child: ValueListenableBuilder<String>(
                              valueListenable:
                                  _controller.elapsedLabelNotifier,
                              builder: (context, timeLabel, _) {
                                return _GameStatCard(
                                  icon: Icons.timer_outlined,
                                  label: 'Time',
                                  value: timeLabel,
                                  colorScheme: colorScheme,
                                  theme: theme,
                                  accent: colorScheme.primaryContainer,
                                  onAccent: colorScheme.onPrimaryContainer,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FadeSlideIn(
                            index: 1,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(end: mistakesRatio),
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                              builder: (context, ratio, child) {
                                return _GameStatCard(
                                  icon: Icons.gpp_maybe_outlined,
                                  label: 'Mistakes',
                                  value:
                                      '${_controller.mistakes}/${_controller.maxMistakes}',
                                  colorScheme: colorScheme,
                                  theme: theme,
                                  accent: Color.lerp(
                                    colorScheme.tertiaryContainer,
                                    colorScheme.errorContainer,
                                    ratio * 0.9,
                                  )!,
                                  onAccent: Color.lerp(
                                    colorScheme.onTertiaryContainer,
                                    colorScheme.onErrorContainer,
                                    ratio,
                                  )!,
                                  pulseToken: _controller.mistakes,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) =>
                            FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, -0.4),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            ),
                        child: err != null
                            ? DecoratedBox(
                                key: ValueKey(err),
                                decoration: BoxDecoration(
                                  color: colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colorScheme.error.withValues(
                                      alpha: 0.25,
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: colorScheme.onErrorContainer,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          err,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color:
                                                    colorScheme
                                                        .onErrorContainer,
                                                height: 1.35,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    if (hasGrid) ...[
                      if (err != null) const SizedBox(height: 12),
                      if (_gameUiPaused)
                        _PausePlaceholder(
                          userPaused: _userPaused,
                          ambientPaused: _ambientPaused,
                          onResume: () => _setUserPaused(false),
                          colorScheme: colorScheme,
                          theme: theme,
                        )
                      else ...[
                        Stack(
                          children: [
                            ShakeOnSignal(
                              signal: _defeatToken,
                              intensity: 10,
                              duration: const Duration(milliseconds: 560),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(end: defeated ? 0.15 : 1.0),
                                duration: const Duration(milliseconds: 700),
                                curve: Curves.easeOutCubic,
                                builder: (context, saturation, child) {
                                  if (saturation > 0.999) return child!;
                                  return ColorFiltered(
                                    colorFilter: ColorFilter.saturation(
                                      saturation,
                                    ),
                                    child: child,
                                  );
                                },
                                child: SudokuGrid(
                                  dimension: _controller.puzzleDimension,
                                  boxRows: _controller.boxRowsResolved,
                                  boxCols: _controller.boxColsResolved,
                                  valueAt: _controller.cellAt,
                                  selectedRow: _controller.selectedRow,
                                  selectedCol: _controller.selectedCol,
                                  highlightDigit: _controller.highlightDigit,
                                  isGiven: _controller.isGiven,
                                  onCellTap: _controller.selectCell,
                                  playCellEntrance: _expectCellEntrance,
                                  pulseDigit: _pulseDigit,
                                  pulseBoxIndex: _pulseBoxIndex,
                                  waveToken: _waveToken,
                                  errorToken: _errorToken,
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 240,
                                      ),
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      transitionBuilder:
                                          (child, animation) => FadeTransition(
                                            opacity: animation,
                                            child: SlideTransition(
                                              position: Tween<Offset>(
                                                begin: const Offset(0, -0.6),
                                                end: Offset.zero,
                                              ).animate(animation),
                                              child: child,
                                            ),
                                          ),
                                      child: _celebrationMessage == null
                                          ? const SizedBox.shrink()
                                          : _CelebrationPill(
                                              key: ValueKey(
                                                _celebrationMessage,
                                              ),
                                              message: _celebrationMessage!,
                                              colorScheme: colorScheme,
                                              theme: theme,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        FadeSlideIn(
                          index: 2,
                          child: NumberPad(
                            maxDigit: _controller.maxDigit,
                            enabled: _controller.canPlay,
                            activeDigit: _controller.highlightDigit,
                            digitsFullyPlaced: _controller.digitsFullyPlaced,
                            onDigit: _controller.numberPadDigit,
                            onErase: _controller.clearCell,
                            onHint: _controller.applyHint,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: SignalFlash(
                    signal: _defeatToken,
                    color: colorScheme.error,
                  ),
                ),
              ),
              Positioned.fill(
                child: ConfettiBurst(signal: _confettiToken),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                reverseDuration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.96, end: 1).animate(
                      animation,
                    ),
                    child: child,
                  ),
                ),
                child: loading
                    ? ColoredBox(
                        key: const ValueKey('loading'),
                        color: colorScheme.surface.withValues(alpha: 0.82),
                        child: Center(
                          child: Card(
                            elevation: 2,
                            shadowColor: colorScheme.shadow.withValues(
                              alpha: 0.2,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 24,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Building puzzle…',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Finding a unique ${widget.boardSize.label} grid for you',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('idle')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameStatCard extends StatelessWidget {
  const _GameStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    required this.theme,
    required this.accent,
    required this.onAccent,
    this.pulseToken,
  });

  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final Color accent;
  final Color onAccent;

  /// When set, the value re-pops whenever this token changes (mistake made).
  final Object? pulseToken;

  @override
  Widget build(BuildContext context) {
    Widget valueText = Text(
      value,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      overflow: TextOverflow.ellipsis,
    );
    if (pulseToken != null) {
      valueText = TweenAnimationBuilder<double>(
        key: ValueKey(pulseToken),
        tween: Tween(begin: 0.55, end: 1),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: valueText,
      );
    }

    return Material(
      color: colorScheme.surface,
      elevation: 0,
      surfaceTintColor: colorScheme.surfaceTint.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: accent,
              child: Icon(icon, color: onAccent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  valueText,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating "progress made" chip that briefly overlays the top of the board
/// when a digit or box is completed.
class _CelebrationPill extends StatelessWidget {
  const _CelebrationPill({
    super.key,
    required this.message,
    required this.colorScheme,
    required this.theme,
  });

  final String message;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.7, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: colorScheme.secondary.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 6),
            Text(
              message,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PausePlaceholder extends StatelessWidget {
  const _PausePlaceholder({
    required this.userPaused,
    required this.ambientPaused,
    required this.onResume,
    required this.colorScheme,
    required this.theme,
  });

  final bool userPaused;
  final bool ambientPaused;
  final VoidCallback onResume;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final message = !userPaused && ambientPaused
        ? 'Timer is paused while you are away. Your puzzle will reappear when you return.'
        : userPaused && !ambientPaused
        ? 'Timer is paused. Tap Resume when you are ready to continue.'
        : 'Timer is paused. Come back to the game or tap Resume to continue.';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: Material(
        key: ValueKey('$userPaused-$ambientPaused'),
        color: colorScheme.surface,
        elevation: 1,
        surfaceTintColor: colorScheme.primary.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PulseLoop(
                amplitude: 0.05,
                halfPeriod: const Duration(milliseconds: 1100),
                child: Icon(
                  Icons.pause_circle_filled_rounded,
                  size: 58,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Paused',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              if (userPaused) ...[
                const SizedBox(height: 26),
                PressableScale(
                  child: FilledButton.icon(
                    onPressed: onResume,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Resume'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
