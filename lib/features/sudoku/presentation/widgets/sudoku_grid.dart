import 'package:flutter/material.dart';

/// Square Sudoku grid with thick lines between [boxRows]×[boxCols] blocks.
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

    return AspectRatio(
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
              cacheExtent: 0,
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
                  bg = colorScheme.secondaryContainer.withValues(alpha: 0.85);
                } else if (sameBox || sameLine) {
                  bg = colorScheme.surfaceContainerHigh.withValues(alpha: 0.65);
                } else {
                  bg = colorScheme.surface;
                }

                final textColor = sameDigit && !selected
                    ? colorScheme.onSecondaryContainer
                    : (given ? colorScheme.onSurface : colorScheme.primary);

                return Material(
                  color: bg,
                  child: InkWell(
                    onTap: () => onCellTap(row, col),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: value == 0
                          ? const SizedBox.shrink()
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '$value',
                                maxLines: 1,
                                style: digitStyle()?.copyWith(
                                  fontWeight: given
                                      ? FontWeight.w800
                                      : FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ),
                    ),
                  ),
                );
              },
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
