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
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
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
              final sameDigit = highlightDigit != null &&
                  value != 0 &&
                  value == highlightDigit;

              final thickRight =
                  (col + 1) % boxCols == 0 && col < dimension - 1;
              final thickBottom =
                  (row + 1) % boxRows == 0 && row < dimension - 1;

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
                  : (given
                      ? colorScheme.onSurface
                      : colorScheme.primary);

              return Material(
                color: bg,
                child: InkWell(
                  onTap: () => onCellTap(row, col),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          width: thickRight ? 2.5 : 0.6,
                          color: thickRight
                              ? colorScheme.outline
                              : colorScheme.outlineVariant,
                        ),
                        bottom: BorderSide(
                          width: thickBottom ? 2.5 : 0.6,
                          color: thickBottom
                              ? colorScheme.outline
                              : colorScheme.outlineVariant,
                        ),
                      ),
                    ),
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
