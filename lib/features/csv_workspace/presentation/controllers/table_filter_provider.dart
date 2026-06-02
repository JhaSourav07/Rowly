import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'csv_loader_provider.dart';

part 'table_filter_provider.g.dart';

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
    int? sortColumnIndex,
    bool? isSortAscending,
    List<int>? visibleRowIndices,
  }) {
    return TableFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      sortColumnIndex: sortColumnIndex,
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

    // New file: reset to a clean state showing all rows sequentially
    final totalRows = metadata.totalRows;
    final indices = List<int>.generate(totalRows, (i) => i);
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
        newSortColumn = null;
      }
    }

    state = state.copyWith(
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

    state = state.copyWith(visibleRowIndices: updatedIndices);
  }
}
