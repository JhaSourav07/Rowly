import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'csv_loader_provider.dart';
import 'row_operations_provider.dart';
import 'table_editing_provider.dart';

part 'table_filter_provider.g.dart';

// Sentinel object used to distinguish "not provided" from "explicitly null"
// in the copyWith pattern for nullable fields.
const _keepExisting = Object();

class TableFilterState {
  final String searchQuery;
  final int? sortColumnIndex;
  final bool isSortAscending;
  final List<int> visibleRowIndices;

  const TableFilterState({
    required this.searchQuery,
    required this.sortColumnIndex,
    required this.isSortAscending,
    required this.visibleRowIndices,
  });

  TableFilterState copyWith({
    String? searchQuery,
    // Use sentinel to distinguish "clear sort" (pass null) from "keep sort" (omit)
    Object? sortColumnIndex = _keepExisting,
    bool? isSortAscending,
    List<int>? visibleRowIndices,
  }) {
    return TableFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      sortColumnIndex: identical(sortColumnIndex, _keepExisting)
          ? this.sortColumnIndex
          : sortColumnIndex as int?,
      isSortAscending: isSortAscending ?? this.isSortAscending,
      visibleRowIndices: visibleRowIndices ?? this.visibleRowIndices,
    );
  }
}

@riverpod
class TableFilter extends _$TableFilter {
  String? _lastFilePath;
  Timer? _debounceTimer;

  @override
  TableFilterState build() {
    final csvState = ref.watch(csvLoaderProvider);
    final metadata = csvState.value;

    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    if (metadata == null) {
      _lastFilePath = null;
      return const TableFilterState(
        searchQuery: '',
        sortColumnIndex: null,
        isSortAscending: true,
        visibleRowIndices: [],
      );
    }

    final isSameFile = _lastFilePath == metadata.filePath;
    _lastFilePath = metadata.filePath;

    if (isSameFile) {
      // Re-run search/sort using existing queries on the newly modified metadata
      Future.microtask(() => _runFilteringAndSorting());
      return state;
    }

    // New file: reset to a clean state showing all rows sequentially.
    // metadata.totalRows includes the header row at byte offset 0, so the
    // actual number of data rows is (totalRows - 1).
    // Indices here are 0-based data-row indices (0 = first data row, which
    // lives at rowByteOffsets[1] in the file).
    final dataRowCount = (metadata.totalRows - 1).clamp(0, metadata.totalRows);
    final int initialRowCount = dataRowCount > 100000 ? dataRowCount : 100000;
    final indices = List<int>.generate(initialRowCount, (i) => i);
    return TableFilterState(
      searchQuery: '',
      sortColumnIndex: null,
      isSortAscending: true,
      visibleRowIndices: indices,
    );
  }

  void setSearchQuery(String query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(searchQuery: query);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      _runFilteringAndSorting();
    });
  }

  void toggleSortColumn(int columnIndex) {
    int? newSortColumn = columnIndex;
    bool newAsc = true;

    if (state.sortColumnIndex == columnIndex) {
      if (state.isSortAscending) {
        newAsc = false;
      } else {
        // Third click: clear the sort — pass null explicitly (not the sentinel)
        newSortColumn = null;
      }
    }

    // When clearing sort, we must pass null explicitly, not the sentinel.
    // When setting/changing sort column, pass the new value.
    state = newSortColumn == null
        ? TableFilterState(
            searchQuery: state.searchQuery,
            sortColumnIndex: null,
            isSortAscending: true,
            visibleRowIndices: state.visibleRowIndices,
          )
        : state.copyWith(
            sortColumnIndex: newSortColumn,
            isSortAscending: newAsc,
          );
    _runFilteringAndSorting();
  }

  Future<void> _runFilteringAndSorting() async {
    final csvState = ref.read(csvLoaderProvider);
    final metadata = csvState.value;
    if (metadata == null) return;

    final repository = ref.read(csvRepositoryProvider);

    final updatedIndices = await repository.filterAndSortTable(
      metadata: metadata,
      searchQuery: state.searchQuery,
      sortColumnIndex: state.sortColumnIndex,
      isSortAscending: state.isSortAscending,
    );

    final dataRowCount = (metadata.totalRows - 1).clamp(0, metadata.totalRows);
    final mutations = ref.read(tableEditingProvider);

    List<int> finalIndices = [...updatedIndices];

    if (state.searchQuery.isEmpty) {
      final int targetCount = dataRowCount > 100000 ? dataRowCount : 100000;
      if (targetCount > dataRowCount) {
        finalIndices.addAll(List.generate(targetCount - dataRowCount, (i) => dataRowCount + i));
      }
    } else {
      final query = state.searchQuery.toLowerCase();
      // Group mutations by virtual row index
      final Map<int, List<String>> virtualRowMutations = {};
      for (final entry in mutations.entries) {
        final pos = entry.key;
        if (pos.rowIndex >= dataRowCount) {
          virtualRowMutations.putIfAbsent(pos.rowIndex, () => []).add(entry.value);
        }
      }

      for (final rowIndex in virtualRowMutations.keys) {
        final cellValues = virtualRowMutations[rowIndex]!;
        final rowText = cellValues.join(' ');
        if (rowText.toLowerCase().contains(query)) {
          finalIndices.add(rowIndex);
        }
      }
    }

    state = state.copyWith(visibleRowIndices: finalIndices);

    // Re-seed the row layout provider so it matches the new filtered row count.
    // Without this, the grid's visibleOrder indices go stale and cause
    // out-of-bounds access (and visual row repetition/crashes).
    ref.read(rowOperationsProvider.notifier).initialize(finalIndices.length);
  }
}
