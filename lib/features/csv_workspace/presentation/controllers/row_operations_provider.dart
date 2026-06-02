import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'row_operations_provider.g.dart';

/// Holds row-level layout state for the spreadsheet grid.
/// The [visibleOrder] is a permutation of the original [TableFilterState.visibleRowIndices].
/// This sits on top of the filter layer: operations here rearrange/hide within
/// the already-filtered set, so they compose naturally with search & sort.
class RowLayoutState {
  /// The ordered list of indices into [TableFilterState.visibleRowIndices].
  /// Each entry is a "filter-level index" (0-based position in visibleRowIndices).
  /// Hidden rows are excluded.
  final List<int> visibleOrder;

  const RowLayoutState({required this.visibleOrder});

  RowLayoutState copyWith({List<int>? visibleOrder}) {
    return RowLayoutState(visibleOrder: visibleOrder ?? this.visibleOrder);
  }
}

@riverpod
class RowOperations extends _$RowOperations {
  @override
  RowLayoutState build() {
    return const RowLayoutState(visibleOrder: []);
  }

  /// Seeds the visible order with a natural sequence of [rowCount] entries.
  /// Call this whenever a new file is loaded or filter resets.
  void initialize(int rowCount) {
    state = RowLayoutState(
      visibleOrder: List.generate(rowCount, (i) => i),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HIDE
  // ─────────────────────────────────────────────────────────────

  /// Removes the row at [visiblePos] from the visible order.
  void hideRow(int visiblePos) {
    if (visiblePos < 0 || visiblePos >= state.visibleOrder.length) return;
    final updated = List<int>.from(state.visibleOrder)..removeAt(visiblePos);
    state = state.copyWith(visibleOrder: updated);
  }

  // ─────────────────────────────────────────────────────────────
  // DELETE  (same as hide for the display layer)
  // ─────────────────────────────────────────────────────────────

  void deleteRow(int visiblePos) => hideRow(visiblePos);

  // ─────────────────────────────────────────────────────────────
  // DUPLICATE
  // ─────────────────────────────────────────────────────────────

  /// Inserts a clone of [visiblePos] immediately after it.
  /// The clone points to the same underlying filter-level index (same row data).
  void duplicateRow(int visiblePos) {
    if (visiblePos < 0 || visiblePos >= state.visibleOrder.length) return;
    final filterIdx = state.visibleOrder[visiblePos];
    final updated = List<int>.from(state.visibleOrder)
      ..insert(visiblePos + 1, filterIdx);
    state = state.copyWith(visibleOrder: updated);
  }

  // ─────────────────────────────────────────────────────────────
  // MOVE UP / DOWN
  // ─────────────────────────────────────────────────────────────

  void moveRowUp(int visiblePos) {
    if (visiblePos <= 0) return;
    final updated = List<int>.from(state.visibleOrder);
    final temp = updated[visiblePos - 1];
    updated[visiblePos - 1] = updated[visiblePos];
    updated[visiblePos] = temp;
    state = state.copyWith(visibleOrder: updated);
  }

  void moveRowDown(int visiblePos) {
    if (visiblePos >= state.visibleOrder.length - 1) return;
    final updated = List<int>.from(state.visibleOrder);
    final temp = updated[visiblePos + 1];
    updated[visiblePos + 1] = updated[visiblePos];
    updated[visiblePos] = temp;
    state = state.copyWith(visibleOrder: updated);
  }

  // ─────────────────────────────────────────────────────────────
  // INSERT ABOVE / BELOW
  // ─────────────────────────────────────────────────────────────

  /// Inserts a new empty slot (represented by index -1, rendered blank)
  /// immediately above [visiblePos].
  void insertRowAbove(int visiblePos) {
    if (visiblePos < 0 || visiblePos > state.visibleOrder.length) return;
    final updated = List<int>.from(state.visibleOrder)..insert(visiblePos, -1);
    state = state.copyWith(visibleOrder: updated);
  }

  /// Inserts a new empty slot below [visiblePos].
  void insertRowBelow(int visiblePos) {
    final insertAt = visiblePos + 1;
    if (insertAt > state.visibleOrder.length) return;
    final updated = List<int>.from(state.visibleOrder)..insert(insertAt, -1);
    state = state.copyWith(visibleOrder: updated);
  }

  // ─────────────────────────────────────────────────────────────
  // SHOW ALL (restore hidden rows in natural order)
  // ─────────────────────────────────────────────────────────────

  void showAllRows(int totalFilteredRows) {
    state = RowLayoutState(
      visibleOrder: List.generate(totalFilteredRows, (i) => i),
    );
  }
}
