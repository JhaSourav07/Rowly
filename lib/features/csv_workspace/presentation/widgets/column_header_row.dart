import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/colors.dart';
import '../../domain/models/csv_table.dart';
import '../controllers/column_operations_provider.dart';
import '../controllers/column_widths_provider.dart';
import '../controllers/table_editing_provider.dart';
import '../controllers/table_filter_provider.dart';
import 'column_context_menu.dart';

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
    final layoutState = ref.watch(columnOperationsProvider);

    // If column operations provider hasn't been initialized yet, seed it.
    if (layoutState.visibleOrder.isEmpty && metadata.headers.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(columnOperationsProvider.notifier)
            .initialize(metadata.headers.length);
      });
    }

    final visibleOrder = layoutState.visibleOrder.isEmpty
        ? List.generate(metadata.headers.length, (i) => i)
        : layoutState.visibleOrder;

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
          // ── Letter columns with drag-to-resize and right-click menu ──────────
          Positioned.fill(
            left: 50.0,
            child: Row(
              children: List.generate(visibleOrder.length, (visIdx) {
                final physicalIndex = visibleOrder[visIdx];
                final originalHeader = physicalIndex < metadata.headers.length
                    ? metadata.headers[physicalIndex]
                    : 'Col $physicalIndex';
                final headerLabel = layoutState.displayName(originalHeader, physicalIndex);
                final letter = _getColumnLetter(visIdx);

                final isColFocused = selectedCell?.columnIndex == visIdx;
                final isFrozen = visIdx < layoutState.frozenColumnCount;
                final double width = columnWidths[visIdx] ?? 120.0;

                return SizedBox(
                  width: width,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: Listener(
                          // kSecondaryMouseButton == 2; fires on web AND desktop
                          onPointerDown: (event) {
                            if (event.buttons == 2) {
                              showColumnContextMenu(
                                context: context,
                                ref: ref,
                                metadata: metadata,
                                visibleOrderIndex: visIdx,
                                globalPosition: event.position,
                              );
                            }
                          },
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isFrozen
                                  ? AppColors.accent.withAlpha(18)
                                  : Colors.transparent,
                              border: Border(
                                right: const BorderSide(
                                    color: AppColors.borderSubtle, width: 0.5),
                                bottom: BorderSide(
                                  color: isColFocused
                                      ? AppColors.successGreen
                                      : Colors.transparent,
                                  width: isColFocused ? 1.5 : 0.0,
                                ),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  letter,
                                  style: TextStyle(
                                    fontSize: 10.0,
                                    fontWeight: isColFocused
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isColFocused
                                        ? AppColors.successGreen
                                        : AppColors.textMuted,
                                  ),
                                ),
                                if (headerLabel.isNotEmpty) ...[
                                  const SizedBox(height: 1),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 3.0),
                                    child: Text(
                                      headerLabel,
                                      style: TextStyle(
                                        fontSize: 9.0,
                                        color: isFrozen
                                            ? AppColors.accent
                                            : AppColors.textMuted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Frozen indicator bar on the right edge of the last frozen column
                      if (isFrozen &&
                          visIdx == layoutState.frozenColumnCount - 1)
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          width: 2,
                          child: Container(
                            color: AppColors.accent.withAlpha(200),
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
                              ref
                                  .read(columnWidthsProvider.notifier)
                                  .resizeColumn(visIdx, details.delta.dx);
                            },
                            onDoubleTap: () {
                              final visibleRowIndices =
                                  ref.read(tableFilterProvider).visibleRowIndices;
                              ref
                                  .read(columnWidthsProvider.notifier)
                                  .autoFitColumn(
                                      visIdx, metadata, visibleRowIndices);
                            },
                            behavior: HitTestBehavior.translucent,
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),

          // ── Left spacer aligning with row indices ─────────────────────────
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
                        right:
                            BorderSide(color: AppColors.borderSubtle, width: 1.0),
                        bottom:
                            BorderSide(color: AppColors.borderSubtle, width: 1.0),
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
