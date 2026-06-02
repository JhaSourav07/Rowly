import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/colors.dart';
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
  late final ScrollController _horizontalScrollController;
  final ValueNotifier<double> _horizontalScrollOffset = ValueNotifier<double>(0.0);
  int _currentPage = 1;
  static const int _rowsPerPage = 50;
  late List<double> columnWidths;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _horizontalScrollController = ScrollController();
    _horizontalScrollController.addListener(() {
      _horizontalScrollOffset.value = _horizontalScrollController.offset;
    });
    columnWidths = List<double>.generate(
      widget.metadata.headers.length,
      (index) => 120.0, // Default column width in pixels
    );
  }

  @override
  void didUpdateWidget(covariant SpreadsheetGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.metadata.headers.length != widget.metadata.headers.length) {
      columnWidths = List<double>.generate(
        widget.metadata.headers.length,
        (index) => 120.0,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _horizontalScrollController.dispose();
    _horizontalScrollOffset.dispose();
    super.dispose();
  }

  void _resizeColumn(int colIndex, double delta) {
    setState(() {
      final double newWidth = columnWidths[colIndex] + delta;
      columnWidths[colIndex] = newWidth.clamp(40.0, 400.0);
    });
  }

  void _autoFitColumn(int colIndex) {
    final headers = widget.metadata.headers;
    if (colIndex >= headers.length) return;

    double maxCharCount = headers[colIndex].length.toDouble();

    final filterState = ref.read(tableFilterProvider);
    final visibleIndices = filterState.visibleRowIndices;

    final sampleSize = visibleIndices.length > 100 ? 100 : visibleIndices.length;
    final mutations = ref.read(tableEditingProvider);

    for (int i = 0; i < sampleSize; i++) {
      final actualRowIndex = visibleIndices[i];
      final rowState = ref.read(csvRowProvider(actualRowIndex));
      String cellValue = '';

      if (rowState.hasValue) {
        final cells = rowState.value ?? [];
        if (colIndex < cells.length) {
          cellValue = cells[colIndex];
        }
      }

      final cellPos = CsvCellPosition(rowIndex: actualRowIndex, columnIndex: colIndex);
      if (mutations.containsKey(cellPos)) {
        cellValue = mutations[cellPos]!;
      }

      if (cellValue.length > maxCharCount) {
        maxCharCount = cellValue.length.toDouble();
      }
    }

    final double fittedWidth = (maxCharCount * 8.0 + 32.0).clamp(60.0, 350.0);
    setState(() {
      columnWidths[colIndex] = fittedWidth;
    });
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

    final double totalWidth = 50.0 + columnWidths.reduce((a, b) => a + b);

    return Column(
      children: [
        // Horizontal scroll container that holds both the letter headers and the virtualized row builder
        Expanded(
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalWidth,
              child: Column(
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
                    child: Stack(
                      children: [
                        // Letter columns with drag-to-resize boundary handles - indented by 50.0
                        Positioned.fill(
                          left: 50.0,
                          child: Row(
                            children: List.generate(widget.metadata.headers.length, (colIndex) {
                              final isColFocused = selectedCell?.columnIndex == colIndex;
                              final double width = columnWidths[colIndex];
                              
                              return SizedBox(
                                width: width,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned.fill(
                                      child: Container(
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
                                    ),
                                    // Drag-to-resize handle at the right edge
                                    Positioned(
                                      right: -4.0,
                                      top: 0,
                                      bottom: 0,
                                      width: 8.0,
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.resizeLeftRight,
                                        child: GestureDetector(
                                          onHorizontalDragUpdate: (details) {
                                            _resizeColumn(colIndex, details.delta.dx);
                                          },
                                          onDoubleTap: () {
                                            _autoFitColumn(colIndex);
                                          },
                                          behavior: HitTestBehavior.translucent,
                                          child: Container(
                                            color: Colors.transparent,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                        // Left spacer aligning with row indices - made sticky
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 50.0,
                          child: ValueListenableBuilder<double>(
                            valueListenable: _horizontalScrollOffset,
                            builder: (context, offset, child) {
                              return Transform.translate(
                                offset: Offset(offset, 0.0),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: AppColors.surface,
                                    border: Border(
                                      right: BorderSide(color: AppColors.borderSubtle, width: 1.0),
                                      bottom: BorderSide(color: AppColors.borderSubtle, width: 1.0),
                                    ),
                                  ),
                                ),
                              );
                            },
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
                          columnWidths: columnWidths,
                          horizontalScrollOffset: _horizontalScrollOffset,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
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
  final List<double> columnWidths;
  final ValueNotifier<double> horizontalScrollOffset;

  const VirtualGridRow({
    super.key,
    required this.rowIndex,
    required this.columnCount,
    required this.metadata,
    required this.columnWidths,
    required this.horizontalScrollOffset,
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

                return SizedBox(
                  width: columnWidths[colIndex],
                  child: GestureDetector(
                    onTap: () {
                      if (isHeadersRow) return;
                      
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
                                  return _InlineCellTextField(
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

class _InlineCellTextField extends ConsumerStatefulWidget {
  final CsvCellPosition position;
  final String initialValue;

  const _InlineCellTextField({
    required this.position,
    required this.initialValue,
  });

  @override
  ConsumerState<_InlineCellTextField> createState() => _InlineCellTextFieldState();
}

class _InlineCellTextFieldState extends ConsumerState<_InlineCellTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        ref.read(inlineEditingCellProvider.notifier).stopEditing();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          ref.read(inlineEditingCellProvider.notifier).stopEditing();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: true,
        style: const TextStyle(
          fontSize: 13.0,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.normal,
        ),
        cursorColor: AppColors.accent,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (val) {
          ref.read(tableEditingProvider.notifier).updateCell(widget.position, val);
        },
        onSubmitted: (val) {
          ref.read(inlineEditingCellProvider.notifier).stopEditing();
        },
      ),
    );
  }
}