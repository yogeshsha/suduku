import 'package:flutter/material.dart';

import '../../../../route_observer.dart';
import '../../../../theme/theme_mode_picker_button.dart';
import '../../application/sudoku_game_controller.dart';
import '../../data/win_history_repository.dart';
import '../../domain/game_difficulty.dart';
import '../../domain/sudoku_win_record.dart';
import '../widgets/animated_success_dialog.dart';
import '../widgets/how_to_play.dart';
import '../widgets/number_pad.dart';
import '../widgets/sudoku_grid.dart';
import 'sudoku_history_page.dart';

class SudokuGamePage extends StatefulWidget {
  const SudokuGamePage({
    super.key,
    required this.difficulty,
  });

  final GameDifficulty difficulty;

  @override
  State<SudokuGamePage> createState() => _SudokuGamePageState();
}

class _SudokuGamePageState extends State<SudokuGamePage>
    with RouteAware, WidgetsBindingObserver {
  late final SudokuGameController _controller = SudokuGameController();
  bool _outcomeDialogScheduled = false;

  bool _userPaused = false;
  bool _routeCovered = false;
  bool _appBackgrounded = false;

  bool get _ambientPaused => _routeCovered || _appBackgrounded;

  bool get _gameUiPaused =>
      _controller.board != null &&
      !_controller.loading &&
      (_userPaused || _ambientPaused);

  bool _routeAwareSubscribed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_onController);
    _controller.setDifficulty(widget.difficulty);
    _controller.startNewGame();
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

  void _requestNewPuzzle() {
    setState(() => _userPaused = false);
    _controller.startNewGame();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncClockToPauseState();
    });
  }

  void _onController() {
    final outcome = _controller.pendingOutcome;
    if (outcome != null && !_outcomeDialogScheduled) {
      _outcomeDialogScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await _showOutcome(outcome);
        } finally {
          if (mounted) {
            _outcomeDialogScheduled = false;
          }
        }
      });
    }
    setState(() {});
  }

  void _openHistory() {
    Navigator.of(context).push<void>(SudokuHistoryPage.route());
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
        icon: Icon(
          Icons.refresh_rounded,
          size: 36,
          color: colorScheme.primary,
        ),
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
        _requestNewPuzzle();
      }
    });
  }

  Future<void> _showOutcome(SudokuGameOutcome outcome) async {
    if (!mounted) return;
    if (_controller.pendingOutcome != outcome) return;

    if (outcome == SudokuGameOutcome.won) {
      final time = _controller.elapsedLabel;
      final record = SudokuWinRecord.capture(
        difficulty: _controller.difficulty,
        elapsed: _controller.elapsed,
        mistakes: _controller.mistakes,
        hintsUsed: _controller.hintsUsed,
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
          setState(() => _userPaused = false);
          _controller.startNewGame();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _syncClockToPauseState();
          });
        },
        onHome: () {
          if (!mounted) return;
          Navigator.of(context).pop();
        },
      );
    } else {
      final time = _controller.elapsedLabel;
      final msg = 'Too many invalid moves. Time on puzzle: $time.';
      if (!mounted) return;
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (ctx, animation, secondaryAnimation) => AlertDialog(
          title: const Text('Game over'),
          content: Text(msg),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
        transitionBuilder: (ctx, anim, _, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);
          return FadeTransition(opacity: curved, child: child);
        },
      );
    }
    if (!mounted) return;
    _controller.consumeOutcome();
  }

  bool get _canUsePauseControl {
    final b = _controller.board;
    if (b == null || _controller.loading) return false;
    if (_controller.pendingOutcome != null) return false;
    if (b.isComplete || _controller.isGameOver) return false;
    if (_ambientPaused) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final board = _controller.board;
    final loading = _controller.loading;
    final err = _controller.error;

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
                _controller.difficulty.title,
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
                onPressed:
                    _canUsePauseControl ? () => _setUserPaused(true) : null,
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
                          child: _GameStatCard(
                            icon: Icons.timer_outlined,
                            label: 'Time',
                            value: _controller.elapsedLabel,
                            colorScheme: colorScheme,
                            theme: theme,
                            accent: colorScheme.primaryContainer,
                            onAccent: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _GameStatCard(
                            icon: Icons.gpp_maybe_outlined,
                            label: 'Mistakes',
                            value:
                                '${_controller.mistakes}/${_controller.maxMistakes}',
                            colorScheme: colorScheme,
                            theme: theme,
                            accent: colorScheme.tertiaryContainer,
                            onAccent: colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (err != null)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.error.withValues(alpha: 0.25),
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
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onErrorContainer,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (board != null) ...[
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
                        SudokuGrid(
                          board: board,
                          selectedRow: _controller.selectedRow,
                          selectedCol: _controller.selectedCol,
                          highlightDigit: _controller.highlightDigit,
                          isGiven: _controller.isGiven,
                          onCellTap: _controller.selectCell,
                        ),
                        const SizedBox(height: 22),
                        NumberPad(
                          enabled: _controller.canPlay,
                          activeDigit: _controller.highlightDigit,
                          digitsFullyPlaced: _controller.digitsFullyPlaced,
                          onDigit: _controller.numberPadDigit,
                          onErase: _controller.clearCell,
                          onHint: _controller.applyHint,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              if (loading)
                ColoredBox(
                  color: colorScheme.surface.withValues(alpha: 0.82),
                  child: Center(
                    child: Card(
                      elevation: 2,
                      shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
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
                              'Finding a unique 9×9 grid for you',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
  });

  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final Color accent;
  final Color onAccent;

  @override
  Widget build(BuildContext context) {
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
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
              Icon(
                Icons.pause_circle_filled_rounded,
                size: 58,
                color: colorScheme.primary,
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
                FilledButton.icon(
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}
