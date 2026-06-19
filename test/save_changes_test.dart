import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:rowly/features/csv_workspace/data/datasources/csv_isolate_worker.dart';
import 'package:rowly/features/csv_workspace/data/datasources/file_accessor.dart';
import 'package:rowly/features/csv_workspace/data/repositories/csv_repository_impl.dart';
import 'package:rowly/features/csv_workspace/domain/models/csv_cell.dart';
import 'package:rowly/features/csv_workspace/domain/models/csv_table.dart';

void main() {
  group('CSV Save All Changes Tests', () {
    late Directory tempDir;
    late File testFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('rowly_test');
      testFile = File('${tempDir.path}/test_save.csv');
      await testFile.writeAsString('ID,Name,Age\n1,Alice,20\n2,Bob,25\n');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('saveAllChanges does not write "Column X" placeholders for virtual columns', () async {
      const repository = CsvRepositoryImpl(
        worker: CsvIsolateWorker(),
        accessor: FileAccessor(),
      );

      final metadata = CsvTableMetadata(
        filePath: testFile.path,
        fileSizeInBytes: await testFile.length(),
        headers: const ['ID', 'Name', 'Age'],
        rowByteOffsets: Uint64List.fromList([0, 12, 23]),
      );

      // We simulate editing row 0 (which is the first data row) in virtual column index 5 (6th column).
      // We also verify that when saving, the header row for index 3, 4, 5 remains blank.
      final mutations = {
        const CsvCellPosition(rowIndex: 0, columnIndex: 5): 'NewValue',
      };

      // Visible column order up to index 5
      final columnVisibleOrder = [0, 1, 2, 3, 4, 5];
      final renamedHeaders = <int, String>{};
      final rowFileIndices = [0, 1]; // We have 2 data rows

      final updatedMetadata = await repository.saveAllChanges(
        metadata: metadata,
        mutations: mutations,
        columnVisibleOrder: columnVisibleOrder,
        renamedHeaders: renamedHeaders,
        originalHeaders: metadata.headers,
        rowFileIndices: rowFileIndices,
      );

      // Read saved file contents
      final savedLines = await testFile.readAsLines();

      // The first row (index 0) is the header row.
      // Expected headers: ID, Name, Age, and three empty headers for the virtual columns
      expect(savedLines[0], 'ID,Name,Age,,,');

      // The second row (index 1) is the first data row.
      // Expected cells: 1, Alice, 20, and empty cells for columns 3 and 4, and 'NewValue' for column 5
      expect(savedLines[1], '1,Alice,20,,,NewValue');

      // Metadata headers updated successfully
      expect(updatedMetadata.headers, ['ID', 'Name', 'Age', '', '', '']);
    });
  });
}
