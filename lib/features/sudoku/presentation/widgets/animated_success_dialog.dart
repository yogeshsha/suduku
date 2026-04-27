import 'package:flutter/material.dart';

import '../../domain/game_difficulty.dart';

/// Celebration dialog with scale + fade entrance.
class AnimatedSuccessDialog extends StatelessWidget {
  const AnimatedSuccessDialog({
    super.key,
    required this.timeLabel,
    required this.difficulty,
    required this.mistakes,
    required this.hintsUsed,
    required this.onNewGame,
    required this.onHome,
  });

  final String timeLabel;
  final GameDifficulty difficulty;
  final int mistakes;
  final int hintsUsed;
  final VoidCallback onNewGame;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      icon: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.85, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: Curves.elasticOut,
        child: Icon(
          Icons.emoji_events_rounded,
          size: 52,
          color: colorScheme.tertiary,
        ),
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
      ),
      title: const Text('Puzzle solved'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'You finished in $timeLabel on ${difficulty.title} difficulty.',
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.35),
          ),
          const SizedBox(height: 14),
          _SummaryRow(icon: Icons.timer_outlined, label: 'Time', value: timeLabel),
          _SummaryRow(
            icon: Icons.flag_outlined,
            label: 'Difficulty',
            value: difficulty.title,
          ),
          _SummaryRow(
            icon: Icons.error_outline,
            label: 'Mistakes',
            value: '$mistakes',
          ),
          _SummaryRow(
            icon: Icons.lightbulb_outline,
            label: 'Hints',
            value: '$hintsUsed',
          ),
          const SizedBox(height: 8),
          Text(
            'Your result was saved. Open History on the home screen to review past games.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
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

Future<void> showAnimatedSuccessDialog({
  required BuildContext context,
  required String timeLabel,
  required GameDifficulty difficulty,
  required int mistakes,
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
      return AnimatedSuccessDialog(
        timeLabel: timeLabel,
        difficulty: difficulty,
        mistakes: mistakes,
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
