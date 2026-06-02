import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/colors.dart';
import '../../domain/models/csv_cell.dart';
import '../../domain/models/csv_table.dart';
import '../controllers/table_editing_provider.dart';
import '../controllers/table_filter_provider.dart';
import '../controllers/table_viewport_provider.dart';

class FormulaBar extends ConsumerWidget {
  final CsvTableMetadata? metadata;
  final bool isCompact;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final double height;

  const FormulaBar({
    super.key,
    required this.metadata,
    required this.isCompact,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.height,
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
    final filterState = ref.watch(tableFilterProvider);

    String cellCoordinate = '';
    if (selectedCell != null && metadata != null) {
      final colLetter = _getColumnLetter(selectedCell.columnIndex);
      final visualIndex = filterState.visibleRowIndices.indexOf(selectedCell.rowIndex);
      final rowNum = visualIndex != -1 ? visualIndex + 2 : selectedCell.rowIndex + 2;
      cellCoordinate = '$colLetter$rowNum';
    }

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: isExpanded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          // Cell Coordinate Indicator
          Container(
            width: 60.0,
            height: 28.0,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(color: AppColors.borderSubtle, width: 0.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
            child: Text(
              cellCoordinate.isEmpty ? '--' : cellCoordinate,
              style: const TextStyle(
                color: AppColors.successGreen,
                fontSize: 11.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: EdgeInsets.only(top: isExpanded ? 6.0 : 0.0),
            child: const Icon(Icons.functions, size: 14, color: AppColors.textMuted),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: isExpanded ? 60.0 : 20.0,
            child: const VerticalDivider(color: AppColors.borderSubtle, width: 1),
          ),
          const SizedBox(width: 8),

          // Formula input field
          Expanded(
            child: selectedCell == null
                ? const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select a cell to view or edit formulas/values',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11.0, fontStyle: FontStyle.italic),
                    ),
                  )
                : FormulaBarInput(
                    selectedCell: selectedCell,
                    isExpanded: isExpanded,
                  ),
          ),

          // Excel-Style Expand/Collapse Chevron Button
          const SizedBox(width: 8),
          SizedBox(
            height: isExpanded ? 60.0 : 20.0,
            child: const VerticalDivider(color: AppColors.borderSubtle, width: 1),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: EdgeInsets.only(top: isExpanded ? 4.0 : 0.0),
            child: IconButton(
              icon: Icon(
                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 16,
                color: AppColors.textSecondary,
              ),
              onPressed: onToggleExpand,
              tooltip: isExpanded ? 'Collapse Formula Bar' : 'Expand Formula Bar',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }
}

class FormulaBarInput extends ConsumerStatefulWidget {
  final CsvCellPosition selectedCell;
  final bool isExpanded;
  const FormulaBarInput({super.key, required this.selectedCell, required this.isExpanded});

  @override
  ConsumerState<FormulaBarInput> createState() => _FormulaBarInputState();
}

class _FormulaBarInputState extends ConsumerState<FormulaBarInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _updateText();
  }

  @override
  void didUpdateWidget(covariant FormulaBarInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCell != widget.selectedCell) {
      _updateText();
    }
  }

  void _updateText() {
    final cells = ref.read(csvRowProvider(widget.selectedCell.rowIndex)).value ?? [];
    final diskVal = widget.selectedCell.columnIndex < cells.length
        ? cells[widget.selectedCell.columnIndex]
        : '';
    final mutations = ref.read(tableEditingProvider);
    final currentVal = mutations[widget.selectedCell] ?? diskVal;
    _controller.text = currentVal;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(tableEditingProvider, (previous, next) {
      final cells = ref.read(csvRowProvider(widget.selectedCell.rowIndex)).value ?? [];
      final diskVal = widget.selectedCell.columnIndex < cells.length
          ? cells[widget.selectedCell.columnIndex]
          : '';
      final nextVal = next[widget.selectedCell] ?? diskVal;
      if (_controller.text != nextVal) {
        _controller.text = nextVal;
      }
    });

    final editMode = ref.watch(editModeProvider);

    return TextField(
      controller: _controller,
      enabled: editMode,
      maxLines: widget.isExpanded ? null : 1,
      style: const TextStyle(fontSize: 12.0, color: AppColors.textPrimary, fontFamily: 'monospace'),
      decoration: InputDecoration(
        hintText: editMode ? 'Enter value...' : 'Read Only (Select edit mode to edit)',
        hintStyle: const TextStyle(fontSize: 12.0, color: AppColors.textMuted),
        border: InputBorder.none,
        isDense: true,
        contentPadding: widget.isExpanded ? const EdgeInsets.symmetric(vertical: 4.0) : const EdgeInsets.symmetric(vertical: 6.0),
      ),
      onChanged: (val) {
        ref.read(tableEditingProvider.notifier).updateCell(widget.selectedCell, val);
      },
    );
  }
}
