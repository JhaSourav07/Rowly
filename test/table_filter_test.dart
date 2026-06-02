import 'package:flutter_test/flutter_test.dart';
import 'package:rowly/features/csv_workspace/presentation/controllers/table_filter_provider.dart';

void main() {
  group('TableFilterState Tests', () {
    test('initializes correctly and copyWith copies correctly', () {
      const state = TableFilterState(
        searchQuery: 'test',
        sortColumnIndex: 2,
        isSortAscending: false,
        visibleRowIndices: [1, 3, 5],
      );

      expect(state.searchQuery, 'test');
      expect(state.sortColumnIndex, 2);
      expect(state.isSortAscending, isFalse);
      expect(state.visibleRowIndices, [1, 3, 5]);

      final copied = state.copyWith(searchQuery: 'new_query');
      expect(copied.searchQuery, 'new_query');
      expect(copied.sortColumnIndex, isNull); // Resets sorting
      expect(copied.isSortAscending, isFalse);
      expect(copied.visibleRowIndices, [1, 3, 5]);
    });
  });
}
