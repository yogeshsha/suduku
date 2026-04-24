import 'package:fludoku/fludoku.dart';
import 'package:flutter/material.dart';

/// Renders a 9×9 grid with 3×3 box emphasis, selection, and same-digit highlight.
class SudokuGrid extends StatelessWidget {
  const SudokuGrid({
    super.key,
    required this.board,
    required this.selectedRow,
    required this.selectedCol,
    required this.highlightDigit,
    required this.isGiven,
    required this.onCellTap,
  });

  final Board board;
  final int? selectedRow;
  final int? selectedCol;
  /// When non-null, cells showing this digit (1–9) get a matching highlight.
  final int? highlightDigit;
  final bool Function(int row, int col) isGiven;
  final void Function(int row, int col) onCellTap;

  static const int dim = 9;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: dim,
            ),
            itemCount: dim * dim,
            itemBuilder: (context, index) {
              final row = index ~/ dim;
              final col = index % dim;
              final value = board.getAt(row: row, col: col);
              final given = isGiven(row, col);
              final selected = selectedRow == row && selectedCol == col;
              final sameBox = _sameBox(
                row,
                col,
                selectedRow,
                selectedCol,
              );
              final sameLine = selectedRow == row || selectedCol == col;
              final sameDigit = highlightDigit != null &&
                  value != 0 &&
                  value == highlightDigit;

              final thickRight = (col + 1) % 3 == 0 && col < dim - 1;
              final thickBottom = (row + 1) % 3 == 0 && row < dim - 1;

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
                        : Text(
                            '$value',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight:
                                  given ? FontWeight.w800 : FontWeight.w700,
                              color: textColor,
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

  static bool _sameBox(int r, int c, int? sr, int? sc) {
    if (sr == null || sc == null) return false;
    final br = r ~/ 3;
    final bc = c ~/ 3;
    final sbr = sr ~/ 3;
    final sbc = sc ~/ 3;
    return br == sbr && bc == sbc;
  }
}
