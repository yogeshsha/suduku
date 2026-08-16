import 'package:flutter/material.dart';

import '../../../../theme/theme_mode_picker_button.dart';
import '../../domain/game_difficulty.dart';
import '../../domain/sudoku_board_size.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/how_to_play.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/pulse_loop.dart';
import 'sudoku_game_page.dart';
import 'sudoku_history_page.dart';

/// Landing screen: rules summary, difficulty, and navigation to play.
class SudokuHomePage extends StatefulWidget {
  const SudokuHomePage({super.key});

  @override
  State<SudokuHomePage> createState() => _SudokuHomePageState();
}

class _SudokuHomePageState extends State<SudokuHomePage> {
  GameDifficulty _difficulty = GameDifficulty.medium;
  SudokuBoardSize _boardSize = SudokuBoardSize.dim9;

  void _openGame() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            SudokuGamePage(difficulty: _difficulty, boardSize: _boardSize),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'Sudoku',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'How to play',
            onPressed: () => showHowToPlay(context),
            icon: const Icon(Icons.help_outline_rounded),
          ),
          const ThemeModePickerButton(),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeSlideIn(
                index: 0,
                child: Material(
                  color: colorScheme.surface,
                  elevation: 0,
                  surfaceTintColor: colorScheme.primary.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.55),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _GentleFloat(
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.4, end: 1),
                                duration: const Duration(milliseconds: 650),
                                curve: Curves.easeOutBack,
                                builder: (context, scale, child) =>
                                    Transform.scale(scale: scale, child: child),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colorScheme.primaryContainer
                                        .withValues(alpha: 0.65),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Icon(
                                      Icons.grid_4x4_rounded,
                                      size: 40,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Classic\nSudoku',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        Text(
                          '4×4 and 9×9 use the fludoku engine; 6×6 is mini Sudoku (2×3 blocks, '
                          'digits 1–6); 12×12 uses 3×4 blocks and digits 1–12. Each row, '
                          'column, and box must contain every digit exactly once.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.45,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FadeSlideIn(
                index: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Grid size',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: SudokuBoardSize.values.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.65,
                      ),
                      itemBuilder: (context, i) {
                        final s = SudokuBoardSize.values[i];
                        final selected = _boardSize == s;
                        return Tooltip(
                          message: s.subtitle,
                          child: AnimatedScale(
                            scale: selected ? 1.04 : 1,
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutBack,
                            child: Material(
                              color: selected
                                  ? colorScheme.secondaryContainer
                                  : colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.55),
                              surfaceTintColor: colorScheme.primary.withValues(
                                alpha: selected ? 0.12 : 0.06,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: selected
                                      ? colorScheme.secondary
                                      : colorScheme.outlineVariant.withValues(
                                          alpha: 0.75,
                                        ),
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _boardSize = s),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.grid_view_rounded,
                                        size: 22,
                                        color: selected
                                            ? colorScheme.onSecondaryContainer
                                            : colorScheme.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          s.label,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: selected
                                                ? colorScheme
                                                      .onSecondaryContainer
                                                : colorScheme.onSurface,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: _crossfade,
                      child: Text(
                        _boardSize.subtitle,
                        key: ValueKey(_boardSize),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FadeSlideIn(
                index: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Difficulty',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<GameDifficulty>(
                      segments: GameDifficulty.values
                          .map(
                            (d) => ButtonSegment<GameDifficulty>(
                              value: d,
                              label: Text(d.title),
                              tooltip: d.subtitle,
                            ),
                          )
                          .toList(),
                      selected: {_difficulty},
                      onSelectionChanged: (s) =>
                          setState(() => _difficulty = s.first),
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: _crossfade,
                      child: Text(
                        _difficulty.subtitle,
                        key: ValueKey(_difficulty),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              FadeSlideIn(
                index: 3,
                child: PressableScale(
                  child: FilledButton.icon(
                    onPressed: _openGame,
                    icon: PulseLoop(
                      amplitude: 0.07,
                      child: const Icon(Icons.play_arrow_rounded),
                    ),
                    label: const Text('Start game'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                index: 4,
                delayPerIndexMs: 46,
                child: PressableScale(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push<void>(
                        SudokuHistoryPage.route(),
                      );
                    },
                    icon: const Icon(Icons.history_rounded),
                    label: const Text('History'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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

  static Widget _crossfade(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

/// Very subtle vertical bob that keeps the hero icon feeling alive.
class _GentleFloat extends StatefulWidget {
  const _GentleFloat({required this.child});

  final Widget child;

  @override
  State<_GentleFloat> createState() => _GentleFloatState();
}

class _GentleFloatState extends State<_GentleFloat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -2.5 * _curve.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
