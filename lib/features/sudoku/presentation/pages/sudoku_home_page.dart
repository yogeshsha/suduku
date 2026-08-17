import 'package:flutter/material.dart';

import '../../../../theme/sudoku_game_colors.dart';
import '../../../../theme/theme_mode_picker_button.dart';
import '../../domain/game_difficulty.dart';
import '../../domain/sudoku_board_size.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/how_to_play.dart';
import '../widgets/mascot.dart';
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
    final gameColors = context.gameColors;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Mascot(mood: MascotMood.idle, size: 30),
            const SizedBox(width: 8),
            Text(
              'Cubby\'s Sudoku',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
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
                  color: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gameColors.heroGradient,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                      child: Row(
                        children: [
                          _GentleFloat(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.4, end: 1),
                              duration: const Duration(milliseconds: 650),
                              curve: Curves.easeOutBack,
                              builder: (context, scale, child) =>
                                  Transform.scale(scale: scale, child: child),
                              child: DecoratedBox(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Mascot(
                                    mood: MascotMood.idle,
                                    size: 56,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hey, puzzler! 👋',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Cubby picked a fresh grid for you. Row, '
                                  'column, and box each need every digit once — '
                                  'no repeats.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                        final tileColors = [
                          colorScheme.secondary,
                          colorScheme.tertiary,
                          gameColors.gold,
                          gameColors.pink,
                        ];
                        final tileColor = tileColors[i % tileColors.length];
                        return Tooltip(
                          message: s.subtitle,
                          child: AnimatedScale(
                            scale: selected ? 1.04 : 1,
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutBack,
                            child: Material(
                              color: selected
                                  ? tileColor.withValues(alpha: 0.16)
                                  : colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: selected
                                      ? tileColor
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
                                      DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: tileColor,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(5),
                                          child: Icon(
                                            Icons.grid_view_rounded,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          s.label,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: selected
                                                ? colorScheme.onSurface
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
                    Row(
                      children: [
                        for (final d in GameDifficulty.values)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: d == GameDifficulty.values.last ? 0 : 8,
                              ),
                              child: Tooltip(
                                message: d.subtitle,
                                child: PressableScale(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _difficulty = d),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      curve: Curves.easeOutBack,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: _difficulty == d
                                            ? LinearGradient(
                                                colors: gameColors.heroGradient,
                                              )
                                            : null,
                                        color: _difficulty == d
                                            ? null
                                            : colorScheme
                                                  .surfaceContainerHighest
                                                  .withValues(alpha: 0.5),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                          color: _difficulty == d
                                              ? Colors.transparent
                                              : colorScheme.outlineVariant
                                                    .withValues(alpha: 0.75),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        d.title,
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: _difficulty == d
                                              ? Colors.white
                                              : colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
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
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        colors: gameColors.heroGradient,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: gameColors.heroGradient.last.withValues(
                            alpha: 0.4,
                          ),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: _openGame,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              PulseLoop(
                                amplitude: 0.07,
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Play',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                    icon: const Icon(Icons.emoji_events_rounded),
                    label: const Text('Trophy Room'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
