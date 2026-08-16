import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

/// Square Sudoku grid with thick lines between [boxRows]×[boxCols] blocks.
///
/// Motion, all driven by immutable inputs so cells stay cheap StatefulWidgets:
/// - [playCellEntrance] staggers the given digits in along the diagonal when a
///   fresh puzzle mounts;
/// - placed digits pop in and erased digits shrink out on their own;
/// - [pulseDigit] bounces every cell holding that digit (digit completed);
/// - [pulseBoxIndex] ripples a wave across one box (box completed);
/// - [waveToken] waves the whole board (puzzle solved);
/// - [errorToken] flashes and shakes the selected cell (invalid move).
class SudokuGrid extends StatelessWidget {
  const SudokuGrid({
    super.key,
    required this.dimension,
    required this.boxRows,
    required this.boxCols,
    required this.valueAt,
    required this.selectedRow,
    required this.selectedCol,
    required this.highlightDigit,
    required this.isGiven,
    required this.onCellTap,
    this.playCellEntrance = false,
    this.pulseDigit,
    this.pulseBoxIndex,
    this.waveToken = 0,
    this.errorToken = 0,
  });

  final int dimension;
  final int boxRows;
  final int boxCols;
  final int Function(int row, int col) valueAt;
  final int? selectedRow;
  final int? selectedCol;
  final int? highlightDigit;
  final bool Function(int row, int col) isGiven;
  final void Function(int row, int col) onCellTap;
  final bool playCellEntrance;
  final int? pulseDigit;
  final int? pulseBoxIndex;
  final int waveToken;
  final int errorToken;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Line colors derived from onSurface so they stay visible over every cell
    // background (surface, translucent highlights, containers) in both themes.
    final thinLineColor = colorScheme.onSurface.withValues(
      alpha: isDark ? 0.38 : 0.30,
    );
    final thickLineColor = colorScheme.onSurface.withValues(
      alpha: isDark ? 0.72 : 0.87,
    );

    TextStyle? digitStyle() {
      if (dimension <= 9) {
        return theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        );
      }
      if (dimension <= 16) {
        return theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        );
      }
      return theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 11,
      );
    }

    final boxesPerRow = dimension ~/ boxCols;
    final entranceStepMs = dimension <= 9 ? 26 : dimension <= 12 ? 17 : 11;
    final style = digitStyle();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - t)),
            child: child,
          ),
        );
      },
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: RepaintBoundary(
              child: CustomPaint(
                foregroundPainter: _GridLinesPainter(
                  dimension: dimension,
                  boxRows: boxRows,
                  boxCols: boxCols,
                  thinColor: thinLineColor,
                  thickColor: thickLineColor,
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                  scrollCacheExtent: ScrollCacheExtent.pixels(0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: dimension,
                  ),
                  itemCount: dimension * dimension,
                  itemBuilder: (context, index) {
                    final row = index ~/ dimension;
                    final col = index % dimension;
                    final value = valueAt(row, col);
                    final given = isGiven(row, col);
                    final selected = selectedRow == row && selectedCol == col;
                    final sameBox = _sameBox(
                      row,
                      col,
                      selectedRow,
                      selectedCol,
                      boxRows,
                      boxCols,
                    );
                    final sameLine = selectedRow == row || selectedCol == col;
                    final sameDigit =
                        highlightDigit != null &&
                        value != 0 &&
                        value == highlightDigit;

                    Color bg;
                    if (selected) {
                      bg = colorScheme.primaryContainer;
                    } else if (sameDigit) {
                      bg = colorScheme.secondaryContainer.withValues(
                        alpha: 0.85,
                      );
                    } else if (sameBox || sameLine) {
                      bg = colorScheme.surfaceContainerHigh.withValues(
                        alpha: 0.65,
                      );
                    } else {
                      bg = colorScheme.surface;
                    }

                    final textColor = sameDigit && !selected
                        ? colorScheme.onSecondaryContainer
                        : (given ? colorScheme.onSurface : colorScheme.primary);

                    return _SudokuCell(
                      row: row,
                      col: col,
                      value: value,
                      bg: bg,
                      textColor: textColor,
                      style: style?.copyWith(
                        fontWeight: given ? FontWeight.w800 : FontWeight.w700,
                      ),
                      selected: selected,
                      onTap: () => onCellTap(row, col),
                      boxIndex: (row ~/ boxRows) * boxesPerRow + (col ~/ boxCols),
                      indexInBox: (row % boxRows) * boxCols + (col % boxCols),
                      playEntrance: playCellEntrance,
                      entranceDelay: Duration(
                        milliseconds: (row + col) * entranceStepMs,
                      ),
                      pulseDigit: pulseDigit,
                      pulseBoxIndex: pulseBoxIndex,
                      waveToken: waveToken,
                      errorToken: errorToken,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static bool _sameBox(
    int r,
    int c,
    int? sr,
    int? sc,
    int boxRows,
    int boxCols,
  ) {
    if (sr == null || sc == null) return false;
    final br = r ~/ boxRows;
    final bc = c ~/ boxCols;
    final sbr = sr ~/ boxRows;
    final sbc = sc ~/ boxCols;
    return br == sbr && bc == sbc;
  }
}

class _SudokuCell extends StatefulWidget {
  const _SudokuCell({
    required this.row,
    required this.col,
    required this.value,
    required this.bg,
    required this.textColor,
    required this.style,
    required this.selected,
    required this.onTap,
    required this.boxIndex,
    required this.indexInBox,
    required this.playEntrance,
    required this.entranceDelay,
    required this.pulseDigit,
    required this.pulseBoxIndex,
    required this.waveToken,
    required this.errorToken,
  });

  final int row;
  final int col;
  final int value;
  final Color bg;
  final Color textColor;
  final TextStyle? style;
  final bool selected;
  final VoidCallback onTap;
  final int boxIndex;
  final int indexInBox;
  final bool playEntrance;
  final Duration entranceDelay;
  final int? pulseDigit;
  final int? pulseBoxIndex;
  final int waveToken;
  final int errorToken;

  @override
  State<_SudokuCell> createState() => _SudokuCellState();
}

class _SudokuCellState extends State<_SudokuCell> with TickerProviderStateMixin {
  static const int _fxNone = 0;
  static const int _fxPulse = 1;
  static const int _fxError = 2;

  // Drives value lifecycle: 0 = hidden, 1 = settled. Used for the entrance
  // cascade, the placement pop-in, and the erase shrink-out.
  late final AnimationController _value = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: 1,
  );

  // Drives celebration pulses and the invalid-move flash/shake.
  late final AnimationController _fx = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  int _fxKind = _fxNone;
  int? _exitingValue;
  bool _entranceScheduled = false;
  Timer? _entranceTimer;
  final List<Timer> _fxTimers = <Timer>[];
  late final Listenable _animated = Listenable.merge([_value, _fx]);

  @override
  void initState() {
    super.initState();
    if (widget.playEntrance && widget.value != 0) {
      _entranceScheduled = true;
      _value.value = 0;
      _entranceTimer = Timer(widget.entranceDelay, () {
        if (!mounted || !_entranceScheduled) return;
        _entranceScheduled = false;
        _value.forward();
      });
    }
    _value.addListener(_onValueChanged);
  }

  void _onValueChanged() {
    if (_exitingValue != null && !_value.isAnimating && _value.value == 0) {
      setState(() => _exitingValue = null);
    }
  }

  @override
  void didUpdateWidget(covariant _SudokuCell oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      _entranceScheduled = false;
      if (widget.value != 0) {
        _exitingValue = null;
        _value
          ..duration = const Duration(milliseconds: 300)
          ..forward(from: 0);
      } else {
        // Keep painting the old digit while it shrinks away.
        _exitingValue = oldWidget.value;
        _value
          ..duration = const Duration(milliseconds: 150)
          ..reverse(from: 1);
      }
    }

    if (widget.pulseDigit != oldWidget.pulseDigit &&
        widget.pulseDigit != null &&
        widget.pulseDigit == widget.value) {
      _startFx(_fxPulse);
    }
    if (widget.pulseBoxIndex != oldWidget.pulseBoxIndex &&
        widget.pulseBoxIndex == widget.boxIndex) {
      _startFx(
        _fxPulse,
        delay: Duration(milliseconds: widget.indexInBox * 45),
      );
    }
    if (widget.waveToken != oldWidget.waveToken && widget.value != 0) {
      _startFx(
        _fxPulse,
        delay: Duration(milliseconds: (widget.row + widget.col) * 35),
      );
    }
    if (widget.errorToken != oldWidget.errorToken && widget.selected) {
      _startFx(_fxError);
    }
  }

  void _startFx(int kind, {Duration delay = Duration.zero}) {
    void play() {
      if (!mounted) return;
      _fxKind = kind;
      _fx.forward(from: 0);
    }

    if (delay == Duration.zero) {
      play();
    } else {
      _fxTimers.add(Timer(delay, play));
    }
  }

  @override
  void dispose() {
    _entranceTimer?.cancel();
    for (final timer in _fxTimers) {
      timer.cancel();
    }
    _fxTimers.clear();
    _value.dispose();
    _fx.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayValue = _exitingValue ?? widget.value;

    // The controllers mutate on ticks; AnimatedBuilder is what turns those
    // ticks into repaints (reading .value in build alone would freeze the
    // cell at whatever value the last unrelated rebuild saw).
    return AnimatedBuilder(
      animation: _animated,
      builder: (context, _) {
        final v = _value.value;
        final digitScale = 0.45 + 0.55 * Curves.easeOutBack.transform(v);
        final digitOpacity = Curves.easeOut.transform(v);

        var pulseScale = 1.0;
        var shakeDx = 0.0;
        var bg = widget.bg;
        var textColor = widget.textColor;
        if (_fx.value > 0) {
          final envelope = math.sin(math.pi * _fx.value);
          if (_fxKind == _fxPulse) {
            pulseScale = 1 + 0.16 * envelope;
          } else if (_fxKind == _fxError) {
            shakeDx = math.sin(_fx.value * math.pi * 5) * 3.5 * (1 - _fx.value);
            bg = Color.lerp(
              widget.bg,
              colorScheme.errorContainer,
              envelope * 0.92,
            )!;
            textColor = Color.lerp(
              widget.textColor,
              colorScheme.onErrorContainer,
              envelope,
            )!;
          }
        }

        return Material(
          color: bg,
          child: InkWell(
            onTap: widget.onTap,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Transform.translate(
                offset: Offset(shakeDx, 0),
                child: Transform.scale(
                  scale: digitScale * pulseScale,
                  child: Opacity(
                    opacity: digitOpacity,
                    // Built inside the builder so the error-flash textColor
                    // follows the animation instead of being captured once.
                    child: displayValue == 0
                        ? const SizedBox.shrink()
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '$displayValue',
                              maxLines: 1,
                              style: widget.style?.copyWith(
                                color: textColor,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GridLinesPainter extends CustomPainter {
  const _GridLinesPainter({
    required this.dimension,
    required this.boxRows,
    required this.boxCols,
    required this.thinColor,
    required this.thickColor,
  });

  final int dimension;
  final int boxRows;
  final int boxCols;
  final Color thinColor;
  final Color thickColor;

  static const double _thinWidth = 1.5;
  static const double _thickWidth = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / dimension;
    final cellHeight = size.height / dimension;

    final thinPaint = Paint()
      ..color = thinColor
      ..strokeWidth = _thinWidth
      ..style = PaintingStyle.stroke;

    final thickPaint = Paint()
      ..color = thickColor
      ..strokeWidth = _thickWidth
      ..style = PaintingStyle.stroke;

    // Draw vertical and horizontal grid lines.
    for (int i = 1; i < dimension; i++) {
      final bool isThickVertical = i % boxCols == 0;
      final bool isThickHorizontal = i % boxRows == 0;

      // Align lines to physical pixels for sharper rendering.
      final double x = (i * cellWidth).roundToDouble() + 0.5;
      final double y = (i * cellHeight).roundToDouble() + 0.5;

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        isThickVertical ? thickPaint : thinPaint,
      );

      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        isThickHorizontal ? thickPaint : thinPaint,
      );
    }

    // Outer border.
    final borderRect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(_thickWidth / 2),
      Radius.circular(8 - (_thickWidth / 2)),
    );

    canvas.drawRRect(borderRect, thickPaint);
  }

  @override
  bool shouldRepaint(covariant _GridLinesPainter oldDelegate) {
    return oldDelegate.dimension != dimension ||
        oldDelegate.boxRows != boxRows ||
        oldDelegate.boxCols != boxCols ||
        oldDelegate.thinColor != thinColor ||
        oldDelegate.thickColor != thickColor;
  }
}
