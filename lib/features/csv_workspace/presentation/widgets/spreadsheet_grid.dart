import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart';
import '../../../../shared/constants/layout_constants.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../domain/models/csv_cell.dart';
import '../../domain/models/csv_table.dart';
import '../controllers/table_editing_provider.dart';
import '../controllers/table_viewport_provider.dart';

class SpreadsheetGrid extends StatelessWidget {
  final CsvTableMetadata metadata;

  const SpreadsheetGrid({super.key, required this.metadata});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Static Sticky Column Headers Row
        Container(
          height: LayoutConstants.kDefaultRowHeight,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.borderMuted, width: 1.5)),
          ),
          child: Row(
            children: metadata.headers.map((headerTitle) => Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.centerLeft,
                decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: AppColors.borderSubtle)),
                ),
                child: Text(
                  headerTitle.toUpperCase(),
                  style: context.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )).toList(),
          ),
        ),
        
        // 2. High-Performance Virtualized Row Viewport
        Expanded(
          child: ListView.builder(
            itemCount: metadata.totalRows,
            itemExtent: LayoutConstants.kDefaultRowHeight, // Critical performance anchor
            scrollCacheExtent: const ScrollCacheExtent.pixels(200), // Pre-allocates rows just outside viewport for flawless transitions
            itemBuilder: (context, index) {
              return VirtualGridRow(rowIndex: index, columnCount: metadata.headers.length);
            },
          ),
        ),
      ],
    );
  }
}

class VirtualGridRow extends ConsumerWidget {
  final int rowIndex;
  final int columnCount;

  const VirtualGridRow({
    super.key,
    required this.rowIndex,
    required this.columnCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch this specific row's data. Only rebuilds if this precise line changes.
    final rowAsync = ref.watch(csvRowProvider(rowIndex));
    final mutations = ref.watch(tableEditingProvider);

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle, width: 0.5)),
      ),
      child: Row(
        children: List.generate(columnCount, (colIndex) {
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: AppColors.borderSubtle, width: 0.5)),
              ),
              child: rowAsync.when(
                data: (cells) {
                  final String initialValue = colIndex < cells.length ? cells[colIndex] : '';
                  final position = CsvCellPosition(rowIndex: rowIndex, columnIndex: colIndex);
                  final isMutated = mutations.containsKey(position);
                  final String displayValue = mutations[position] ?? initialValue;

                  return GestureDetector(
                    onDoubleTap: () => _showCellEditor(context, ref, position, displayValue),
                    behavior: HitTestBehavior.opaque,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        displayValue,
                        style: context.textTheme.bodyLarge?.copyWith(
                          color: isMutated ? AppColors.accent : AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
          );
        }),
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