import 'package:flutter/material.dart';

/// Mistakes shown as hearts losing fill, instead of an "N/M" counter —
/// legible at a glance without doing math.
class HeartsRow extends StatelessWidget {
  const HeartsRow({
    super.key,
    required this.mistakes,
    required this.maxMistakes,
    this.color,
    this.size = 18,
  });

  final int mistakes;
  final int maxMistakes;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final heartColor = color ?? Theme.of(context).colorScheme.error;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxMistakes, (i) {
        final lost = i < mistakes;
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: TweenAnimationBuilder<double>(
            key: ValueKey('$i-$lost'),
            tween: Tween(begin: lost ? 1 : 0, end: lost ? 0 : 1),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            builder: (context, t, child) {
              return Transform.scale(
                scale: 0.8 + 0.2 * t,
                child: Icon(
                  lost ? Icons.favorite_border_rounded : Icons.favorite_rounded,
                  size: size,
                  color: heartColor.withValues(alpha: lost ? 0.35 : 1),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
