import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/colors.dart';
import '../../../../shared/constants/layout_constants.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../domain/models/csv_table.dart';
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
            prototypeItem: SizedBox(height: LayoutConstants.kDefaultRowHeight),
            cacheExtent: 200, // Pre-allocates rows just outside viewport for flawless transitions
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
                  final String displayValue = colIndex < cells.length ? cells[colIndex] : '';
                  return Text(
                    displayValue,
                    style: context.textTheme.bodyLarge,
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
          );
        }),
      ),
    );
  }
}