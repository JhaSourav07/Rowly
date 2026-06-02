import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/colors.dart';
import '../../domain/models/csv_table.dart';
import '../controllers/column_widths_provider.dart';
import '../controllers/table_editing_provider.dart';
import '../controllers/table_filter_provider.dart';

class ColumnHeaderRow extends ConsumerWidget {
  final CsvTableMetadata metadata;
  final ValueNotifier<double> horizontalScrollOffset;

  const ColumnHeaderRow({
    super.key,
    required this.metadata,
    required this.horizontalScrollOffset,
  });

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
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCell = ref.watch(selectedCellProvider);
    final columnWidths = ref.watch(columnWidthsProvider);

    return Container(
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
              children: List.generate(metadata.headers.length, (colIndex) {
                final isColFocused = selectedCell?.columnIndex == colIndex;
                final double width = columnWidths[colIndex] ?? 120.0;
                
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
                              ref.read(columnWidthsProvider.notifier).resizeColumn(colIndex, details.delta.dx);
                            },
                            onDoubleTap: () {
                              final visibleRowIndices = ref.read(tableFilterProvider).visibleRowIndices;
                              ref.read(columnWidthsProvider.notifier).autoFitColumn(colIndex, metadata, visibleRowIndices);
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
              valueListenable: horizontalScrollOffset,
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
    );
  }
}
