import 'package:flutter/material.dart';

/// Opens a scrollable sheet explaining Sudoku and in-app controls.
Future<void> showHowToPlay(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final colorScheme = theme.colorScheme;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.38,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 28,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'How to play',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _Section(
                  title: 'Goal',
                  body:
                      'Fill the 9×9 grid so every row, every column, and each '
                      'of the nine 3×3 boxes contains the digits 1 through 9 '
                      'exactly once. No repeats in any row, column, or box.',
                  icon: Icons.flag_rounded,
                  colorScheme: colorScheme,
                  theme: theme,
                ),
                _Section(
                  title: 'Given numbers',
                  body:
                      'Cells that were filled when the puzzle started cannot '
                      'be changed. Your job is to complete the empty cells using '
                      'logic.',
                  icon: Icons.lock_outline_rounded,
                  colorScheme: colorScheme,
                  theme: theme,
                ),
                _Section(
                  title: 'Entering answers',
                  body:
                      'Tap a cell, then tap a number on the pad (1–9). Wrong '
                      'moves that break Sudoku rules count as mistakes. '
                      'Digits you have fully placed nine times disappear from '
                      'the pad to help you track progress.',
                  icon: Icons.touch_app_rounded,
                  colorScheme: colorScheme,
                  theme: theme,
                ),
                _Section(
                  title: 'Hints & erase',
                  body:
                      'Use Hint to fill the selected empty cell with the '
                      'correct answer (counts toward your hint total in '
                      'history). Erase clears your entry in the selected cell.',
                  icon: Icons.lightbulb_outline_rounded,
                  colorScheme: colorScheme,
                  theme: theme,
                ),
                _Section(
                  title: 'Timer & pause',
                  body:
                      'Your solve time runs while you play. Pause freezes the '
                      'timer and hides the board. Opening other screens or '
                      'sending the app to the background also pauses the timer '
                      'until you return.',
                  icon: Icons.timer_outlined,
                  colorScheme: colorScheme,
                  theme: theme,
                ),
                _Section(
                  title: 'Difficulty',
                  body:
                      'Easy puzzles leave more clues; Expert leaves fewer. '
                      'Each puzzle has one unique solution.',
                  icon: Icons.trending_up_rounded,
                  colorScheme: colorScheme,
                  theme: theme,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Got it'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.body,
    required this.icon,
    required this.colorScheme,
    required this.theme,
  });

  final String title;
  final String body;
  final IconData icon;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
