import 'package:flutter/material.dart';

import '../../domain/game_difficulty.dart';

/// Soft feedback after a wrong digit while the game continues.
class MistakeFeedbackDialog extends StatelessWidget {
  const MistakeFeedbackDialog({
    super.key,
    required this.mistakes,
    required this.maxMistakes,
  });

  final int mistakes;
  final int maxMistakes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final remaining = maxMistakes - mistakes;

    final emphasis = remaining == 1
        ? 'Only one mistake left'
        : 'You have $remaining mistakes left';

    final detail = remaining == 1
        ? 'The next wrong digit ends this puzzle.'
        : 'Keep going—double-check rows, columns, and box regions.';

    return AlertDialog(
      icon: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.92, end: 1),
        duration: const Duration(milliseconds: 480),
        curve: Curves.elasticOut,
        child: Icon(
          Icons.grid_off_rounded,
          size: 48,
          color: colorScheme.error,
        ),
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
      ),
      title: const Text('Invalid move'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'That number conflicts with Sudoku rules for this row, column, or box.',
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.35),
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.error.withValues(alpha: 0.22),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emphasis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    detail,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onErrorContainer.withValues(alpha: 0.92),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Mistakes used: $mistakes / $maxMistakes',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

Future<void> showMistakeFeedbackDialog({
  required BuildContext context,
  required int mistakes,
  required int maxMistakes,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      return MistakeFeedbackDialog(
        mistakes: mistakes,
        maxMistakes: maxMistakes,
      );
    },
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Shown when [maxMistakes] invalid moves are used.
class GameOverDialog extends StatelessWidget {
  const GameOverDialog({
    super.key,
    required this.timeLabel,
    required this.difficulty,
    required this.mistakes,
    required this.maxMistakes,
    required this.hintsUsed,
    required this.onNewGame,
    required this.onHome,
  });

  final String timeLabel;
  final GameDifficulty difficulty;
  final int mistakes;
  final int maxMistakes;
  final int hintsUsed;
  final VoidCallback onNewGame;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      icon: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.88, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: Curves.elasticOut,
        child: Icon(
          Icons.sentiment_dissatisfied_rounded,
          size: 52,
          color: colorScheme.error,
        ),
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
      ),
      title: const Text('Game over'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'You reached $maxMistakes mistakes on ${difficulty.title} difficulty. The puzzle stops here.',
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.35),
          ),
          const SizedBox(height: 14),
          _StatRow(icon: Icons.timer_outlined, label: 'Time', value: timeLabel),
          _StatRow(
            icon: Icons.flag_outlined,
            label: 'Difficulty',
            value: difficulty.title,
          ),
          _StatRow(
            icon: Icons.gpp_maybe_outlined,
            label: 'Mistakes',
            value: '$mistakes / $maxMistakes',
          ),
          _StatRow(
            icon: Icons.lightbulb_outline,
            label: 'Hints',
            value: '$hintsUsed',
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.end,
      actionsOverflowAlignment: OverflowBarAlignment.end,
      actions: [
        OutlinedButton.icon(
          onPressed: onHome,
          icon: const Icon(Icons.home_rounded),
          label: const Text('Home'),
        ),
        FilledButton.icon(
          onPressed: onNewGame,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('New game'),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showGameOverDialog({
  required BuildContext context,
  required String timeLabel,
  required GameDifficulty difficulty,
  required int mistakes,
  required int maxMistakes,
  required int hintsUsed,
  required VoidCallback onNewGame,
  required VoidCallback onHome,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      return GameOverDialog(
        timeLabel: timeLabel,
        difficulty: difficulty,
        mistakes: mistakes,
        maxMistakes: maxMistakes,
        hintsUsed: hintsUsed,
        onNewGame: () {
          Navigator.of(ctx).pop();
          onNewGame();
        },
        onHome: () {
          Navigator.of(ctx).pop();
          onHome();
        },
      );
    },
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}
