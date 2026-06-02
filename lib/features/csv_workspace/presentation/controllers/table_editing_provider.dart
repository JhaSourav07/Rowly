import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/csv_cell.dart';

part 'table_editing_provider.g.dart';

@riverpod
class TableEditing extends _$TableEditing {
  @override
  Map<CsvCellPosition, String> build() {
    return const {};
  }

  void updateCell(CsvCellPosition position, String newValue) {
    state = {
      ...state,
      position: newValue,
    };
  }

  void clearAllMutations() {
    state = const {};
  }
}
