import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/csv_cell.dart';
import '../../domain/models/csv_table.dart';
import 'table_editing_provider.dart';
import 'table_viewport_provider.dart';

part 'column_widths_provider.g.dart';

@riverpod
class ColumnWidths extends _$ColumnWidths {
  @override
  Map<int, double> build() {
    return const {};
  }

  /// Initialize default column widths of 120.0px for a given column count.
  void initialize(int columnCount) {
    if (state.isEmpty) {
      state = {
        for (int i = 0; i < columnCount; i++) i: 120.0,
      };
    }
  }

  /// Resize a specific column by delta dx, clamped between 40.0px and 400.0px.
  void resizeColumn(int colIndex, double delta) {
    final double currentWidth = state[colIndex] ?? 120.0;
    final double newWidth = (currentWidth + delta).clamp(40.0, 400.0);
    state = {
      ...state,
      colIndex: newWidth,
    };
  }

  /// Auto-fits a column width to fit its longest visible cells and column header text.
  void autoFitColumn(int colIndex, CsvTableMetadata metadata, List<int> visibleRowIndices) {
    final headers = metadata.headers;
    if (colIndex >= headers.length) return;

    double maxCharCount = headers[colIndex].length.toDouble();
    final mutations = ref.read(tableEditingProvider);

    final sampleSize = visibleRowIndices.length > 100 ? 100 : visibleRowIndices.length;

    for (int i = 0; i < sampleSize; i++) {
      final actualRowIndex = visibleRowIndices[i];
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
    state = {
      ...state,
      colIndex: fittedWidth,
    };
  }
}
