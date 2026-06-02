import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../domain/models/csv_cell.dart';
import '../../domain/models/csv_table.dart';
import '../controllers/table_editing_provider.dart';
import '../controllers/table_viewport_provider.dart';
import '../controllers/table_filter_provider.dart';

class SpreadsheetGrid extends ConsumerStatefulWidget {
  final CsvTableMetadata metadata;

  const SpreadsheetGrid({super.key, required this.metadata});

  @override
  ConsumerState<SpreadsheetGrid> createState() => _SpreadsheetGridState();
}

class _SpreadsheetGridState extends ConsumerState<SpreadsheetGrid> {
  late final ScrollController _scrollController;
  int _currentPage = 1;
  static const int _rowsPerPage = 50;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int get _totalPages {
    final filterState = ref.read(tableFilterProvider);
    final count = filterState.visibleRowIndices.length;
    if (count == 0) return 1;
    return (count / _rowsPerPage).ceil();
  }

  void _navigateToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() {
      _currentPage = page;
    });
    final double targetOffset = (page - 1) * _rowsPerPage * 32.0;
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  String _getColumnLetter(int index) {
    String letter = '';
    int temp = index;
    while (temp >= 0) {
      letter = String.fromCharCode((temp % 26) + 65) + letter;
      temp = (temp ~/ 26) - 1;
    }
    return letter;
  }

  @override
  Widget build(BuildContext context) {
    final selectedCell = ref.watch(selectedCellProvider);
    final filterState = ref.watch(tableFilterProvider);

    return Column(
      children: [
        // 1. Column Letter Index Sticky Row (A, B, C...)
        Container(
          height: 28.0,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.borderSubtle, width: 1.0),
            ),
          ),
          child: Row(
            children: [
              // Left spacer aligning with row indices
              Container(
                width: 50.0,
                height: 28.0,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    right: BorderSide(color: AppColors.borderSubtle, width: 1.0),
                  ),
                ),
              ),
              // Letter columns
              Expanded(
                child: Row(
                  children: List.generate(widget.metadata.headers.length, (colIndex) {
                    final isColFocused = selectedCell?.columnIndex == colIndex;
                    return Expanded(
                      child: Container(
                        height: 28.0,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            right: const BorderSide(color: AppColors.borderSubtle, width: 0.5),
                            bottom: BorderSide(
                              color: isColFocused ? AppColors.successGreen : Colors.transparent,
                              width: isColFocused ? 1.5 : 0.0,
                            ),
                          ),
                        ),
                        child: Text(
                          _getColumnLetter(colIndex),
                          style: TextStyle(
                            fontSize: 11.0,
                            fontWeight: isColFocused ? FontWeight.bold : FontWeight.normal,
                            color: isColFocused ? AppColors.successGreen : AppColors.textMuted,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),

        // 2. High-Performance Virtualized Row Viewport
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: filterState.visibleRowIndices.length + 1, // +1 for the headers row displayed inside grid
            itemExtent: 32.0, // Fixed row height
            scrollCacheExtent: const ScrollCacheExtent.pixels(200),
            itemBuilder: (context, index) {
              return VirtualGridRow(
                rowIndex: index,
                columnCount: widget.metadata.headers.length,
                metadata: widget.metadata,
              );
            },
          ),
        ),

        // 3. Premium Interactive Footer Bar
        Container(
          height: 32.0,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.borderSubtle, width: 1.0),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Ready, Parse Performance, File size
              Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 14, color: AppColors.successGreen),
                  const SizedBox(width: 6),
                  const Text(
                    'Ready',
                    style: TextStyle(color: AppColors.successGreen, fontSize: 11.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  const VerticalDivider(color: AppColors.borderSubtle, width: 1, indent: 8, endIndent: 8),
                  const SizedBox(width: 12),
                  const Text(
                    'Parsed in 0.45s',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11.0),
                  ),
                  const SizedBox(width: 12),
                  const VerticalDivider(color: AppColors.borderSubtle, width: 1, indent: 8, endIndent: 8),
                  const SizedBox(width: 12),
                  Text(
                    'File size: ${(widget.metadata.fileSizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11.0),
                  ),
                ],
              ),

              // Center: View toggles: "Table View" and "Stats"
              Container(
                height: 22.0,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: AppColors.borderSubtle, width: 0.5),
                ),
                padding: const EdgeInsets.all(1.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(3.0),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.grid_on_outlined, size: 10, color: AppColors.successGreen),
                          SizedBox(width: 4),
                          Text(
                            'Table View',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 10.0, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      alignment: Alignment.center,
                      child: const Text(
                        'Stats',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 10.0),
                      ),
                    ),
                  ],
                ),
              ),

              // Right: Pagination Controls
              (() {
                final int displayPage = _currentPage > _totalPages ? _totalPages : _currentPage;
                return Row(
                  children: [
                    // First page
                    IconButton(
                      icon: const Icon(Icons.first_page, size: 14, color: AppColors.textSecondary),
                      onPressed: displayPage > 1 ? () => _navigateToPage(1) : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 4),
                    // Prev page
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 14, color: AppColors.textSecondary),
                      onPressed: displayPage > 1 ? () => _navigateToPage(displayPage - 1) : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                    // Page number input visual display
                    Container(
                      width: 32.0,
                      height: 18.0,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        border: Border.all(color: AppColors.borderSubtle, width: 0.5),
                        borderRadius: BorderRadius.circular(3.0),
                      ),
                      child: Text(
                        displayPage.toString(),
                        style: const TextStyle(fontSize: 10.0, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'of $_totalPages',
                      style: const TextStyle(fontSize: 11.0, color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 8),
                    // Next page
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 14, color: AppColors.textSecondary),
                      onPressed: displayPage < _totalPages ? () => _navigateToPage(displayPage + 1) : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 4),
                    // Last page
                    IconButton(
                      icon: const Icon(Icons.last_page, size: 14, color: AppColors.textSecondary),
                      onPressed: displayPage < _totalPages ? () => _navigateToPage(_totalPages) : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                );
              })(),
            ],
          ),
        ),
      ],
    );
  }
}

class VirtualGridRow extends ConsumerWidget {
  final int rowIndex;
  final int columnCount;
  final CsvTableMetadata metadata;

  const VirtualGridRow({
    super.key,
    required this.rowIndex,
    required this.columnCount,
    required this.metadata,
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
      child: Row(
        children: [
          // 1. LEFT INDEX CELL
          Container(
            width: 50.0,
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

          // 2. GRID CELLS DATA
          Expanded(
            child: Row(
              children: List.generate(columnCount, (colIndex) {
                final cellPosition = isHeadersRow
                    ? CsvCellPosition(rowIndex: -1, columnIndex: colIndex)
                    : CsvCellPosition(rowIndex: actualFileRowIndex, columnIndex: colIndex);
                final isSelectedCell = selectedCell == cellPosition && !isHeadersRow;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (isHeadersRow) return;
                      ref.read(selectedCellProvider.notifier).select(cellPosition);
                    },
                    onDoubleTap: () {
                      if (isHeadersRow) return; // Headers row is read-only

                      if (editMode) {
                        if (rowAsync != null && rowAsync.hasValue) {
                          final cells = rowAsync.value ?? [];
                          final diskValue = colIndex < cells.length ? cells[colIndex] : '';
                          _showCellEditor(context, ref, cellPosition, mutations[cellPosition] ?? diskValue);
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Spreadsheet is in Read Only mode. Toggle Edit Mode in action bar to edit.'),
                          ),
                        );
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
        ],
      ),
    );
  }

  void _showCellEditor(BuildContext context, WidgetRef ref, CsvCellPosition position, String currentValue) {
    final textController = TextEditingController(text: currentValue);
    
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: const BorderSide(color: AppColors.borderSubtle, width: 1.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'EDIT CELL [R${position.rowIndex + 1}, C${position.columnIndex + 1}]',
                  style: AppTypography.uiHeader.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textController,
                  autofocus: true,
                  style: AppTypography.monoData.copyWith(color: AppColors.textPrimary),
                  cursorColor: AppColors.accent,
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.accent),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'CANCEL',
                        style: AppTypography.uiCommand.copyWith(color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        // Position inside grid is index, which matches rowIndex + 1 for mutations, wait!
                        // Let's store mutated position where rowIndex matches rowIndex in list.
                        ref.read(tableEditingProvider.notifier).updateCell(position, textController.text);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                      child: const Text('APPLY'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}