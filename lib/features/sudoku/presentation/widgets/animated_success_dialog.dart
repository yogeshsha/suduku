import 'package:flutter/material.dart';

import '../../../../theme/sudoku_game_colors.dart';
import '../../domain/game_difficulty.dart';
import 'mascot.dart';

/// 1–3 stars from how clean the solve was — no mistakes or hints is a
/// perfect run, a rough one still earns a star for finishing.
int starsForResult({required int mistakes, required int hintsUsed}) {
  if (mistakes == 0 && hintsUsed == 0) return 3;
  if (mistakes <= 1 && hintsUsed <= 1) return 2;
  return 1;
}

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
    final gameColors = context.gameColors;
    final stars = starsForResult(mistakes: mistakes, hintsUsed: hintsUsed);

    return AlertDialog(
      icon: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.85, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: Curves.elasticOut,
        child: const Mascot(mood: MascotMood.cheer, size: 64),
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
      ),
      title: const Text('Puzzle solved! 🎉'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: i < stars ? 1 : 0.3),
                duration: Duration(milliseconds: 320 + i * 120),
                curve: Curves.elasticOut,
                builder: (context, t, child) => Transform.scale(
                  scale: 0.6 + 0.4 * t,
                  child: child,
                ),
                child: Icon(
                  Icons.star_rounded,
                  size: 34,
                  color: i < stars
                      ? gameColors.gold
                      : colorScheme.outlineVariant,
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            'You finished in $timeLabel on ${difficulty.title} difficulty.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.35),
          ),
          const SizedBox(height: 14),
          _SummaryRow(
            icon: Icons.timer_outlined,
            label: 'Time',
            value: timeLabel,
          ),
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
          label: const Text('Next puzzle'),
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
