import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/colors.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../domain/models/csv_cell.dart';
import '../../domain/models/csv_table.dart';
import '../controllers/column_operations_provider.dart';
import '../controllers/column_widths_provider.dart';
import '../controllers/row_operations_provider.dart';
import '../controllers/table_editing_provider.dart';
import '../controllers/table_filter_provider.dart';
import '../controllers/table_viewport_provider.dart';
import 'inline_cell_text_field.dart';
import 'row_context_menu.dart';

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

  Widget _buildSortIcon(WidgetRef ref, int visIdx) {
    final filterState = ref.watch(tableFilterProvider);
    if (filterState.sortColumnIndex == visIdx) {
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
    // ── Structural providers — change infrequently, full watch is fine ──────
    final editMode = ref.watch(editModeProvider);
    final filterState = ref.watch(tableFilterProvider);
    final columnWidths = ref.watch(columnWidthsProvider);
    final layoutState = ref.watch(columnOperationsProvider);
    final rowLayoutState = ref.watch(rowOperationsProvider);

    final bool isHeadersRow = rowIndex == 0;

    // visiblePos = position in rowLayoutState.visibleOrder (0-based data row)
    final int visiblePos = rowIndex - 1;

    // Resolve actualFileRowIndex through the two-layer mapping:
    //   rowLayoutState.visibleOrder[visiblePos] → filterIdx
    //   filterState.visibleRowIndices[filterIdx] → actual file row
    int actualFileRowIndex = -1;
    if (!isHeadersRow) {
      final rowOrder = rowLayoutState.visibleOrder;
      if (rowOrder.isNotEmpty &&
          visiblePos >= 0 &&
          visiblePos < rowOrder.length) {
        final filterIdx = rowOrder[visiblePos];
        if (filterIdx == -1) {
          actualFileRowIndex = -1;
        } else if (filterIdx < filterState.visibleRowIndices.length) {
          actualFileRowIndex = filterState.visibleRowIndices[filterIdx];
        }
      } else if (rowOrder.isEmpty &&
          visiblePos >= 0 &&
          visiblePos < filterState.visibleRowIndices.length) {
        actualFileRowIndex = filterState.visibleRowIndices[visiblePos];
      }
    }

    // ── Narrow selectors — each row only rebuilds for its OWN state ─────────
    //
    // selectedCellProvider: returns the selected column index if the selected
    // cell is inside THIS row, otherwise null. A different row being selected
    // returns null in both the old and new state → no rebuild for this row.
    final selectedColInThisRow = ref.watch(
      selectedCellProvider.select((cell) {
        if (cell == null || isHeadersRow) return null;
        if (cell.rowIndex != actualFileRowIndex) return null;
        return cell.columnIndex;
      }),
    );
    final isSelectedRow = selectedColInThisRow != null && !isHeadersRow;

    // inlineEditingCellProvider: only the column being inline-edited in THIS row.
    final inlineEditingColInRow = ref.watch(
      inlineEditingCellProvider.select((cell) {
        if (cell == null || isHeadersRow) return null;
        if (cell.rowIndex != actualFileRowIndex) return null;
        return cell.columnIndex;
      }),
    );

    // tableEditingProvider: only the mutations that belong to THIS row.
    // Riverpod compares the returned map by identity; we return a stable empty
    // const map when there are no mutations so the select stays stable.
    final rowMutationMap = ref.watch(
      tableEditingProvider.select((allMutations) {
        if (isHeadersRow || actualFileRowIndex == -1) return const <CsvCellPosition, String>{};
        final relevant = <CsvCellPosition, String>{};
        for (final entry in allMutations.entries) {
          if (entry.key.rowIndex == actualFileRowIndex) {
            relevant[entry.key] = entry.value;
          }
        }
        // Return const empty map when nothing belongs to this row so
        // the select comparison stays stable and avoids a spurious rebuild.
        return relevant.isEmpty ? const <CsvCellPosition, String>{} : relevant;
      }),
    );

    // Watch this specific row's disk data.
    final rowAsync = (isHeadersRow || actualFileRowIndex == -1)
        ? null
        : ref.watch(csvRowProvider(actualFileRowIndex));

    // Use visibleOrder from columnOperationsProvider; fall back to natural order
    final visibleOrder = layoutState.visibleOrder.isEmpty
        ? List.generate(metadata.headers.length, (i) => i)
        : layoutState.visibleOrder;

    final displayColumnCount = visibleOrder.length;

    // Display row number shown to the user (header = row 1)
    final displayRowNumber = rowIndex + 1;


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
              children: List.generate(displayColumnCount, (visIdx) {
                // physicalIndex = which column in the CSV file to read
                final physicalIndex = visibleOrder[visIdx];

                // cellPosition uses visIdx as the column coordinate so that
                // selection highlighting stays aligned with the visual grid.
                final cellPosition = isHeadersRow
                    ? CsvCellPosition(rowIndex: -1, columnIndex: visIdx)
                    : CsvCellPosition(rowIndex: actualFileRowIndex, columnIndex: visIdx);

                final isSelectedCell = selectedColInThisRow == visIdx && !isHeadersRow;
                final isEditingInline = inlineEditingColInRow == visIdx && !isHeadersRow;
                final double width = columnWidths[visIdx] ?? 120.0;

                // Frozen visual highlight
                final isFrozen = visIdx < layoutState.frozenColumnCount;

                return SizedBox(
                  width: width,
                  child: GestureDetector(
                    onTap: () {
                      if (isHeadersRow || actualFileRowIndex == -1) return;

                      gridFocusNode.requestFocus();

                      final currentSelection = ref.read(selectedCellProvider);
                      if (currentSelection == cellPosition) {
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
                        ref.read(selectedCellProvider.notifier).select(cellPosition);
                        ref.read(inlineEditingCellProvider.notifier).stopEditing();
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 32.0,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: isFrozen && !isSelectedCell
                            ? AppColors.accent.withAlpha(8)
                            : Colors.transparent,
                        border: isSelectedCell
                            ? Border.all(color: AppColors.successGreen, width: 1.5)
                            : Border(
                                right: const BorderSide(
                                    color: AppColors.borderSubtle, width: 0.5),
                                bottom: const BorderSide(
                                    color: AppColors.borderSubtle, width: 0.5),
                                left: isFrozen &&
                                        visIdx == layoutState.frozenColumnCount - 1
                                    ? const BorderSide(
                                        color: AppColors.accent, width: 1.5)
                                    : BorderSide.none,
                              ),
                      ),
                      child: isHeadersRow
                          ? GestureDetector(
                              onTap: () {
                                ref
                                    .read(tableFilterProvider.notifier)
                                    .toggleSortColumn(visIdx);
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      layoutState.displayName(
                                        physicalIndex < metadata.headers.length
                                            ? metadata.headers[physicalIndex]
                                            : 'Col $physicalIndex',
                                        physicalIndex,
                                      ),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.0,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  _buildSortIcon(ref, visIdx),
                                ],
                              ),
                            )
                          : (actualFileRowIndex == -1 || rowAsync == null)
                              // Blank row (inserted via row ops) — render empty cells
                              ? const SizedBox.shrink()
                              : rowAsync.when(
                              data: (cells) {
                                // Read the physical column index in disk data
                                final String initialValue =
                                    physicalIndex < cells.length
                                        ? cells[physicalIndex]
                                        : '';
                                final isMutated =
                                    rowMutationMap.containsKey(cellPosition);
                                final String displayValue =
                                    rowMutationMap[cellPosition] ?? initialValue;

                                if (isEditingInline) {
                                  return InlineCellTextField(
                                    position: cellPosition,
                                    initialValue: displayValue,
                                  );
                                }

                                return Text(
                                  displayValue,
                                  style: context.textTheme.bodyLarge?.copyWith(
                                    color: isMutated
                                        ? AppColors.accent
                                        : AppColors.textPrimary,
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
                              error: (_, __) => const Icon(
                                  Icons.error_outline,
                                  size: 12,
                                  color: AppColors.error),
                            ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // 2. LEFT INDEX CELL (drawn on top, sticky, right-click opens row menu)
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
                  child: Listener(
                    onPointerDown: (event) {
                      // Right-click: open row context menu (skip header row)
                      if (event.buttons == 2 && !isHeadersRow) {
                        showRowContextMenu(
                          context: context,
                          ref: ref,
                          visiblePos: visiblePos,
                          displayRowNumber: displayRowNumber,
                        );
                      }
                    },
                    child: MouseRegion(
                      cursor: isHeadersRow
                          ? MouseCursor.defer
                          : SystemMouseCursors.contextMenu,
                      child: Container(
                        height: 32.0,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          border: Border(
                            right: BorderSide(
                                color: AppColors.borderSubtle, width: 1.0),
                          ),
                        ),
                        child: Text(
                          isHeadersRow ? '1' : displayRowNumber.toString(),
                          style: TextStyle(
                            fontSize: 11.0,
                            color: isSelectedRow
                                ? AppColors.successGreen
                                : AppColors.textMuted,
                            fontWeight: isSelectedRow
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
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
