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

@riverpod
class SelectedCell extends _$SelectedCell {
  @override
  CsvCellPosition? build() {
    return null;
  }

  void select(CsvCellPosition position) {
    state = position;
  }

  void clear() {
    state = null;
  }
}

@riverpod
class EditMode extends _$EditMode {
  @override
  bool build() {
    // True for Edit Mode, false for Read Only mode
    return true;
  }

  void toggle() {
    state = !state;
  }

  void setEditMode(bool mode) {
    state = mode;
  }
}

@riverpod
class InlineEditingCell extends _$InlineEditingCell {
  @override
  CsvCellPosition? build() {
    return null;
  }

  void startEditing(CsvCellPosition position) {
    state = position;
  }

  void stopEditing() {
    state = null;
  }
}

