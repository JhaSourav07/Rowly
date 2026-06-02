import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/colors.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../domain/models/csv_cell.dart';
import '../../domain/models/csv_table.dart';
import '../controllers/column_widths_provider.dart';
import '../controllers/table_editing_provider.dart';
import '../controllers/table_filter_provider.dart';
import '../controllers/table_viewport_provider.dart';
import 'inline_cell_text_field.dart';

class VirtualGridRow extends ConsumerWidget {
  final int rowIndex;
  final int columnCount;
  final CsvTableMetadata metadata;
  final ValueNotifier<double> horizontalScrollOffset;
  final FocusNode gridFocusNode;

  const VirtualGridRow({
    super.key,
    required this.rowIndex,
    required this.columnCount,
    required this.metadata,
    required this.horizontalScrollOffset,
    required this.gridFocusNode,
  });

  Widget _buildSortIcon(WidgetRef ref, int colIndex) {
    final filterState = ref.watch(tableFilterProvider);
    if (filterState.sortColumnIndex == colIndex) {
      return Icon(
        filterState.isSortAscending ? Icons.arrow_upward : Icons.arrow_downward,
        size: 12,
        color: AppColors.successGreen,
      );
    }
    return const Icon(Icons.filter_alt_outlined, size: 10, color: AppColors.textMuted);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mutations = ref.watch(tableEditingProvider);
    final selectedCell = ref.watch(selectedCellProvider);
    final editMode = ref.watch(editModeProvider);
    final filterState = ref.watch(tableFilterProvider);
    final inlineEditingCell = ref.watch(inlineEditingCellProvider);
    final columnWidths = ref.watch(columnWidthsProvider);

    final bool isHeadersRow = rowIndex == 0;

    // Translate the visual position to the actual file index
    final int actualFileRowIndex = isHeadersRow 
        ? -1 
        : (rowIndex - 1 < filterState.visibleRowIndices.length 
            ? filterState.visibleRowIndices[rowIndex - 1] 
            : -1);

    final isSelectedRow = selectedCell?.rowIndex == actualFileRowIndex && !isHeadersRow;

    // Watch this specific row's data. If it is the headers row, we don't watch disk rows stream.
    final rowAsync = isHeadersRow ? null : ref.watch(csvRowProvider(actualFileRowIndex));

    return Container(
      height: 32.0,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 0.5),
        ),
      ),
      child: Stack(
        children: [
          // 1. DATA CELLS (indented by 50.0 on the left!)
          Positioned.fill(
            left: 50.0,
            child: Row(
              children: List.generate(columnCount, (colIndex) {
                final cellPosition = isHeadersRow
                    ? CsvCellPosition(rowIndex: -1, columnIndex: colIndex)
                    : CsvCellPosition(rowIndex: actualFileRowIndex, columnIndex: colIndex);
                final isSelectedCell = selectedCell == cellPosition && !isHeadersRow;
                final isEditingInline = inlineEditingCell == cellPosition && !isHeadersRow;
                final double width = columnWidths[colIndex] ?? 120.0;

                return SizedBox(
                  width: width,
                  child: GestureDetector(
                    onTap: () {
                      if (isHeadersRow) return;
                      
                      // Focus the grid focus node to enable arrow key navigation
                      gridFocusNode.requestFocus();
                      
                      final currentSelection = ref.read(selectedCellProvider);
                      if (currentSelection == cellPosition) {
                        // Already selected! Single-tap again immediately opens active inline editing
                        if (editMode) {
                          ref.read(inlineEditingCellProvider.notifier).startEditing(cellPosition);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Spreadsheet is in Read Only mode. Toggle Edit Mode in action bar to edit.'),
                            ),
                          );
                        }
                      } else {
                        // First tap: Select instantly (0ms response)
                        ref.read(selectedCellProvider.notifier).select(cellPosition);
                        // Stop inline editing of any previous cell
                        ref.read(inlineEditingCellProvider.notifier).stopEditing();
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 32.0,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        border: isSelectedCell
                            ? Border.all(color: AppColors.successGreen, width: 1.5)
                            : const Border(
                                right: BorderSide(color: AppColors.borderSubtle, width: 0.5),
                                bottom: BorderSide(color: AppColors.borderSubtle, width: 0.5),
                              ),
                      ),
                      child: isHeadersRow
                          ? GestureDetector(
                              onTap: () {
                                ref.read(tableFilterProvider.notifier).toggleSortColumn(colIndex);
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      metadata.headers[colIndex],
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.0,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  _buildSortIcon(ref, colIndex),
                                ],
                              ),
                            )
                          : rowAsync!.when(
                              data: (cells) {
                                final String initialValue = colIndex < cells.length ? cells[colIndex] : '';
                                final isMutated = mutations.containsKey(cellPosition);
                                final String displayValue = mutations[cellPosition] ?? initialValue;

                                if (isEditingInline) {
                                  return InlineCellTextField(
                                    position: cellPosition,
                                    initialValue: displayValue,
                                  );
                                }

                                return Text(
                                  displayValue,
                                  style: context.textTheme.bodyLarge?.copyWith(
                                    color: isMutated ? AppColors.accent : AppColors.textPrimary,
                                    fontSize: 13.0,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                              loading: () => Container(
                                width: double.infinity,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppColors.borderSubtle,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              error: (_, __) => const Icon(Icons.error_outline, size: 12, color: AppColors.error),
                            ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // 2. LEFT INDEX CELL (drawn on top, sticky!)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 50.0,
            child: ValueListenableBuilder<double>(
              valueListenable: horizontalScrollOffset,
              builder: (context, offset, child) {
                return Transform.translate(
                  offset: Offset(offset, 0.0),
                  child: Container(
                    height: 32.0,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(
                        right: BorderSide(color: AppColors.borderSubtle, width: 1.0),
                      ),
                    ),
                    child: Text(
                      isHeadersRow ? '1' : (rowIndex + 1).toString(),
                      style: TextStyle(
                        fontSize: 11.0,
                        color: isSelectedRow ? AppColors.successGreen : AppColors.textMuted,
                        fontWeight: isSelectedRow ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
