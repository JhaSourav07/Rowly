import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/colors.dart';
import '../controllers/column_widths_provider.dart';
import '../controllers/table_filter_provider.dart';
import '../../domain/models/csv_table.dart';
import 'column_header_row.dart';
import 'virtual_grid_row.dart';

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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _horizontalScrollController = ScrollController();
    _horizontalScrollController.addListener(() {
      _horizontalScrollOffset.value = _horizontalScrollController.offset;
    });

    // Initialize global column widths in the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(columnWidthsProvider.notifier).initialize(widget.metadata.headers.length);
    });
  }

  @override
  void didUpdateWidget(covariant SpreadsheetGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.metadata.headers.length != widget.metadata.headers.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(columnWidthsProvider.notifier).initialize(widget.metadata.headers.length);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _horizontalScrollController.dispose();
    _horizontalScrollOffset.dispose();
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

  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(tableFilterProvider);
    final columnWidths = ref.watch(columnWidthsProvider);

    final double totalColumnsWidth = List.generate(
      widget.metadata.headers.length,
      (i) => columnWidths[i] ?? 120.0,
    ).reduce((a, b) => a + b);
    final double totalWidth = 50.0 + totalColumnsWidth;

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
                  ColumnHeaderRow(
                    metadata: widget.metadata,
                    horizontalScrollOffset: _horizontalScrollOffset,
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