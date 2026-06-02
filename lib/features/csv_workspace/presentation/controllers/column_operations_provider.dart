import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'column_operations_provider.g.dart';

/// Holds the full column layout state for the spreadsheet grid.
/// All column-level operations (Hide, Freeze, Rename, Duplicate, Delete, Move)
/// are centralized here so that every listening widget reacts atomically.
class ColumnLayoutState {
  /// The ordered list of physical column indices currently visible.
  final List<int> visibleOrder;

  /// Number of frozen leading columns (zero means no freeze).
  final int frozenColumnCount;

  /// Map of physical column index → display name override (Rename).
  final Map<int, String> renamedHeaders;

  /// The column count at the time of initialization — used to detect changes.
  final int originalColumnCount;

  const ColumnLayoutState({
    required this.visibleOrder,
    required this.frozenColumnCount,
    required this.renamedHeaders,
    this.originalColumnCount = 0,
  });

  ColumnLayoutState copyWith({
    List<int>? visibleOrder,
    int? frozenColumnCount,
    Map<int, String>? renamedHeaders,
    int? originalColumnCount,
  }) {
    return ColumnLayoutState(
      visibleOrder: visibleOrder ?? this.visibleOrder,
      frozenColumnCount: frozenColumnCount ?? this.frozenColumnCount,
      renamedHeaders: renamedHeaders ?? this.renamedHeaders,
      originalColumnCount: originalColumnCount ?? this.originalColumnCount,
    );
  }

  /// Returns the effective display name for a given physical column index.
  String displayName(String originalHeader, int physicalIndex) {
    return renamedHeaders[physicalIndex] ?? originalHeader;
  }

  /// True if any column-level structural change has been made since initialization.
  bool get hasChanges {
    if (originalColumnCount == 0) return false;
    // Any renames?
    if (renamedHeaders.isNotEmpty) return true;
    // Any columns hidden, deleted, duplicated, or reordered?
    if (visibleOrder.length != originalColumnCount) return true;
    for (int i = 0; i < visibleOrder.length; i++) {
      if (visibleOrder[i] != i) return true;
    }
    return false;
  }
}

@riverpod
class ColumnOperations extends _$ColumnOperations {
  @override
  ColumnLayoutState build() {
    return const ColumnLayoutState(
      visibleOrder: [],
      frozenColumnCount: 0,
      renamedHeaders: {},
    );
  }

  /// Must be called once when a new file is loaded to seed the visible order.
  void initialize(int columnCount) {
    state = ColumnLayoutState(
      visibleOrder: List.generate(columnCount, (i) => i),
      frozenColumnCount: 0,
      renamedHeaders: const {},
      originalColumnCount: columnCount,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // RENAME
  // ─────────────────────────────────────────────────────────────

  /// Renames the column at [physicalIndex] to [newName].
  void renameColumn(int physicalIndex, String newName) {
    final updated = Map<int, String>.from(state.renamedHeaders);
    updated[physicalIndex] = newName.trim().isEmpty
        ? (updated..remove(physicalIndex)) as String // fallback handled below
        : newName.trim();
    if (newName.trim().isEmpty) {
      updated.remove(physicalIndex);
    }
    state = state.copyWith(renamedHeaders: updated);
  }

  // ─────────────────────────────────────────────────────────────
  // HIDE / SHOW
  // ─────────────────────────────────────────────────────────────

  /// Removes the column at [visibleOrderIndex] from the visible order.
  void hideColumn(int visibleOrderIndex) {
    if (visibleOrderIndex < 0 || visibleOrderIndex >= state.visibleOrder.length) return;
    final updated = List<int>.from(state.visibleOrder)..removeAt(visibleOrderIndex);
    state = state.copyWith(visibleOrder: updated);
  }

  /// Re-inserts all originally known columns (0..totalColumns-1) that are
  /// currently hidden, restoring them in their natural original order.
  void showAllColumns(int totalColumns) {
    final all = List<int>.generate(totalColumns, (i) => i);
    final hidden = all.where((c) => !state.visibleOrder.contains(c)).toList();
    if (hidden.isEmpty) return;
    // Merge back at their original positions
    final merged = List<int>.from(state.visibleOrder);
    for (final c in hidden) {
      final insertAt = merged.indexWhere((v) => v > c);
      if (insertAt == -1) {
        merged.add(c);
      } else {
        merged.insert(insertAt, c);
      }
    }
    state = state.copyWith(visibleOrder: merged);
  }

  // ─────────────────────────────────────────────────────────────
  // FREEZE
  // ─────────────────────────────────────────────────────────────

  /// Freezes all columns up to and including [visibleOrderIndex].
  /// Calling again on the same index unfreezes.
  void toggleFreezeColumn(int visibleOrderIndex) {
    final newFrozen = state.frozenColumnCount == visibleOrderIndex + 1
        ? 0
        : visibleOrderIndex + 1;
    state = state.copyWith(frozenColumnCount: newFrozen);
  }

  // ─────────────────────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────────────────────

  /// Permanently removes [visibleOrderIndex] from the visible order
  /// and clears any rename override for that physical column.
  void deleteColumn(int visibleOrderIndex) {
    if (visibleOrderIndex < 0 || visibleOrderIndex >= state.visibleOrder.length) return;
    final physicalIndex = state.visibleOrder[visibleOrderIndex];
    final updatedOrder = List<int>.from(state.visibleOrder)..removeAt(visibleOrderIndex);
    final updatedNames = Map<int, String>.from(state.renamedHeaders)
      ..remove(physicalIndex);
    // Clamp frozenColumnCount so it never exceeds remaining column count
    final newFrozen = state.frozenColumnCount > updatedOrder.length
        ? updatedOrder.length
        : state.frozenColumnCount;
    state = ColumnLayoutState(
      visibleOrder: updatedOrder,
      frozenColumnCount: newFrozen,
      renamedHeaders: updatedNames,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DUPLICATE
  // ─────────────────────────────────────────────────────────────

  /// Inserts a duplicate entry of [visibleOrderIndex] immediately after it.
  /// The duplicated column re-uses the same physical index, so it renders
  /// identical data — a UI-layer column clone.
  void duplicateColumn(int visibleOrderIndex) {
    if (visibleOrderIndex < 0 || visibleOrderIndex >= state.visibleOrder.length) return;
    final physicalIndex = state.visibleOrder[visibleOrderIndex];
    final updated = List<int>.from(state.visibleOrder)
      ..insert(visibleOrderIndex + 1, physicalIndex);
    state = state.copyWith(visibleOrder: updated);
  }

  // ─────────────────────────────────────────────────────────────
  // MOVE LEFT / RIGHT
  // ─────────────────────────────────────────────────────────────

  void moveColumnLeft(int visibleOrderIndex) {
    if (visibleOrderIndex <= 0) return;
    final updated = List<int>.from(state.visibleOrder);
    final temp = updated[visibleOrderIndex - 1];
    updated[visibleOrderIndex - 1] = updated[visibleOrderIndex];
    updated[visibleOrderIndex] = temp;
    state = state.copyWith(visibleOrder: updated);
  }

  void moveColumnRight(int visibleOrderIndex) {
    if (visibleOrderIndex >= state.visibleOrder.length - 1) return;
    final updated = List<int>.from(state.visibleOrder);
    final temp = updated[visibleOrderIndex + 1];
    updated[visibleOrderIndex + 1] = updated[visibleOrderIndex];
    updated[visibleOrderIndex] = temp;
    state = state.copyWith(visibleOrder: updated);
  }
}
