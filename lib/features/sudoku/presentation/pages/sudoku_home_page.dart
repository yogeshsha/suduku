import 'package:flutter/material.dart';

import '../../../../theme/theme_mode_picker_button.dart';
import '../../domain/game_difficulty.dart';
import '../widgets/how_to_play.dart';
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

  void _openGame() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => SudokuGamePage(difficulty: _difficulty),
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
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
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
              Material(
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
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primaryContainer.withValues(
                            alpha: 0.65,
                          ),
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
                      const SizedBox(height: 18),
                      Text(
                        'Classic 9×9 puzzle',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Fill the grid so each row, column, and 3×3 box contains '
                        'the digits 1–9 with no repeats. Your time is tracked until '
                        'you solve the puzzle.',
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
              const SizedBox(height: 28),
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
                onSelectionChanged: (s) => setState(() => _difficulty = s.first),
              ),
              const SizedBox(height: 8),
              Text(
                _difficulty.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _openGame,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start game'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push<void>(SudokuHistoryPage.route());
                },
                icon: const Icon(Icons.emoji_events_outlined),
                label: const Text('Success history'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
