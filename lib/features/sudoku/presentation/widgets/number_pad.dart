import 'package:flutter/material.dart';

import 'pressable_scale.dart';

/// Digit keys for the current grid size, plus erase and hint.
/// [digitsFullyPlaced] digits celebrate once, then collapse into empty
/// layout slots so the pad keeps its shape.
class NumberPad extends StatelessWidget {
  const NumberPad({
    super.key,
    required this.maxDigit,
    required this.onDigit,
    required this.onErase,
    required this.onHint,
    this.enabled = true,
    this.activeDigit,
    this.digitsFullyPlaced = const <int>{},
  });

  final int maxDigit;
  final void Function(int digit) onDigit;
  final VoidCallback onErase;
  final VoidCallback onHint;
  final bool enabled;
  final int? activeDigit;
  final Set<int> digitsFullyPlaced;

  static const double _slotHeight = 56;

  static List<List<int>> _digitRows(int max) {
    if (max == 6) {
      return [
        [1, 2, 3],
        [4, 5, 6],
      ];
    }
    if (max <= 4) {
      return [List.generate(max, (i) => i + 1)];
    }
    if (max == 9) {
      return [
        [1, 2, 3, 4, 5],
        [6, 7, 8, 9],
      ];
    }
    if (max == 12) {
      return List.generate(3, (r) => List.generate(4, (c) => r * 4 + c + 1));
    }
    final perRow = max <= 12 ? 6 : 5;
    final rows = <List<int>>[];
    var n = 1;
    while (n <= max) {
      final chunk = <int>[];
      for (var i = 0; i < perRow && n <= max; i++) {
        chunk.add(n);
        n++;
      }
      rows.add(chunk);
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final rows = _digitRows(maxDigit);
    final fontSize = maxDigit <= 9
        ? 18.0
        : maxDigit <= 12
        ? 14.0
        : 12.0;

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
              'Numbers (1–$maxDigit)',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),
            for (final row in rows)
              Row(
                children: [
                  for (final n in row)
                    Expanded(
                      child: _DigitKey(
                        digit: n,
                        hidden: digitsFullyPlaced.contains(n),
                        isActive: activeDigit == n,
                        enabled: enabled,
                        fontSize: fontSize,
                        onDigit: onDigit,
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: PressableScale(
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
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: PressableScale(
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

/// A single digit button.
///
/// When its digit becomes fully placed it plays a quick celebratory swell and
/// collapses off the pad; if a new game brings the digit back, it pops in.
class _DigitKey extends StatefulWidget {
  const _DigitKey({
    required this.digit,
    required this.hidden,
    required this.isActive,
    required this.enabled,
    required this.fontSize,
    required this.onDigit,
  });

  final int digit;
  final bool hidden;
  final bool isActive;
  final bool enabled;
  final double fontSize;
  final void Function(int digit) onDigit;

  @override
  State<_DigitKey> createState() => _DigitKeyState();
}

class _DigitKeyState extends State<_DigitKey>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 430),
  );

  @override
  void didUpdateWidget(covariant _DigitKey oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hidden == oldWidget.hidden) return;
    if (widget.hidden) {
      // Start just past zero so the collapse renders from the first frame
      // instead of flashing an empty slot for one build.
      _hide.forward(from: 0.001);
    } else {
      _hide.reverse();
    }
  }

  @override
  void dispose() {
    _hide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hidden && !_hide.isAnimating && _hide.value <= 0.001) {
      return const SizedBox(height: NumberPad._slotHeight);
    }

    return Padding(
      padding: const EdgeInsets.all(4),
      child: SizedBox(
        height: NumberPad._slotHeight,
        child: IgnorePointer(
          ignoring: widget.hidden,
          child: AnimatedScale(
            scale: widget.isActive ? 1.06 : 1.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            child: AnimatedBuilder(
              animation: _hide,
              builder: (context, child) {
                final t = _hide.value;
                var scale = 1.0;
                var opacity = 1.0;
                if (t > 0) {
                  if (t < 0.38) {
                    // Celebratory swell before collapsing.
                    scale = 1 + 0.24 * Curves.easeOutBack.transform(t / 0.38);
                  } else {
                    final u = Curves.easeIn.transform((t - 0.38) / 0.62);
                    scale = (1.24 * (1 - u)).clamp(0.0, 1.24);
                    opacity = 1 - u;
                  }
                }
                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(scale: scale, child: child),
                );
              },
              child: PressableScale(child: _buildButton(context)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final digitText = Text(
      '${widget.digit}',
      style: TextStyle(
        fontSize: widget.fontSize,
        fontWeight: FontWeight.w700,
      ),
    );
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: widget.isActive
          ? FilledButton(
              key: const ValueKey('active'),
              onPressed: widget.enabled ? () => widget.onDigit(widget.digit) : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(44, 48),
                padding: EdgeInsets.zero,
                elevation: 1,
                shadowColor: colorScheme.shadow.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: digitText,
            )
          : FilledButton.tonal(
              key: const ValueKey('tonal'),
              onPressed: widget.enabled ? () => widget.onDigit(widget.digit) : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(44, 48),
                padding: EdgeInsets.zero,
                foregroundColor: colorScheme.onSecondaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: digitText,
            ),
    );
  }
}
