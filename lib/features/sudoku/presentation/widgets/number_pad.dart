import 'package:flutter/material.dart';

/// Digits 1–9 plus erase and hint. [activeDigit] mirrors grid highlight.
/// Digits listed in [digitsFullyPlaced] are omitted (space kept for layout).
class NumberPad extends StatelessWidget {
  const NumberPad({
    super.key,
    required this.onDigit,
    required this.onErase,
    required this.onHint,
    this.enabled = true,
    this.activeDigit,
    this.digitsFullyPlaced = const <int>{},
  });

  final void Function(int digit) onDigit;
  final VoidCallback onErase;
  final VoidCallback onHint;
  final bool enabled;
  final int? activeDigit;
  final Set<int> digitsFullyPlaced;

  static const double _slotHeight = 56;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    Widget digitButton(int n) {
      final hidden = digitsFullyPlaced.contains(n);
      if (hidden) {
        return const Expanded(
          child: SizedBox(height: _slotHeight),
        );
      }

      final isActive = activeDigit == n;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: isActive
              ? FilledButton(
                  onPressed: enabled ? () => onDigit(n) : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(44, 48),
                    padding: EdgeInsets.zero,
                    elevation: 1,
                    shadowColor: colorScheme.shadow.withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '$n',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : FilledButton.tonal(
                  onPressed: enabled ? () => onDigit(n) : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(44, 48),
                    padding: EdgeInsets.zero,
                    foregroundColor: colorScheme.onSecondaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '$n',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ),
      );
    }

    return Material(
      color: colorScheme.surfaceContainerLow.withValues(alpha: 0.9),
      elevation: 0,
      surfaceTintColor: colorScheme.surfaceTint.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Numbers',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (int n = 1; n <= 5; n++) digitButton(n),
              ],
            ),
            Row(
              children: [
                for (int n = 6; n <= 9; n++) digitButton(n),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: enabled ? onErase : null,
                    icon: const Icon(Icons.backspace_outlined, size: 20),
                    label: const Text('Erase'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: enabled ? onHint : null,
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 20),
                    label: const Text('Hint'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: colorScheme.secondaryContainer,
                      foregroundColor: colorScheme.onSecondaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
