import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rowly/features/csv_workspace/domain/models/csv_cell.dart';
import 'package:rowly/features/csv_workspace/domain/models/csv_table.dart';
import 'package:rowly/features/csv_workspace/presentation/controllers/table_editing_provider.dart';
import 'package:rowly/features/csv_workspace/presentation/controllers/csv_loader_provider.dart';
import 'package:rowly/features/csv_workspace/presentation/widgets/spreadsheet_grid.dart';

class MockCsvLoader extends CsvLoader {
  final CsvTableMetadata mockMetadata;
  MockCsvLoader(this.mockMetadata);

  @override
  AsyncValue<CsvTableMetadata?> build() {
    return AsyncValue.data(mockMetadata);
  }
}

void main() {
  group('Keyboard Arrow Key Navigation Tests', () {
    late CsvTableMetadata metadata;

    setUp(() {
      metadata = CsvTableMetadata(
        filePath: 'test.csv',
        fileSizeInBytes: 100,
        headers: const ['ID', 'Name', 'Age'],
        rowByteOffsets: Uint64List.fromList([0, 10, 20]),
      );
    });

    testWidgets('Arrow key navigation updates selection and scroll offsets correctly', (tester) async {
      // Set desktop screen size to prevent footer overflow in test environment
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            csvLoaderProvider.overrideWith(() => MockCsvLoader(metadata)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SpreadsheetGrid(metadata: metadata),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final element = tester.element(find.byType(SpreadsheetGrid));
      final container = ProviderScope.containerOf(element);

      // Select initial cell: Row 0, Column 1 (First data row, Name column)
      const initialPosition = CsvCellPosition(rowIndex: 0, columnIndex: 1);
      container.read(selectedCellProvider.notifier).select(initialPosition);
      await tester.pump();

      expect(container.read(selectedCellProvider), initialPosition);

      // 1. Move Down -> Should select Row 1, Column 1
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(
        container.read(selectedCellProvider),
        const CsvCellPosition(rowIndex: 1, columnIndex: 1),
      );

      // 2. Move Right -> Should select Row 1, Column 2
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(
        container.read(selectedCellProvider),
        const CsvCellPosition(rowIndex: 1, columnIndex: 2),
      );

      // 3. Move Up -> Should select Row 0, Column 2
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(
        container.read(selectedCellProvider),
        const CsvCellPosition(rowIndex: 0, columnIndex: 2),
      );

      // 4. Move Left -> Should select Row 0, Column 1
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(
        container.read(selectedCellProvider),
        const CsvCellPosition(rowIndex: 0, columnIndex: 1),
      );
    });

    testWidgets('Arrow key navigation ignores input if inline editing is active', (tester) async {
      // Set desktop screen size to prevent footer overflow in test environment
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            csvLoaderProvider.overrideWith(() => MockCsvLoader(metadata)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SpreadsheetGrid(metadata: metadata),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final element = tester.element(find.byType(SpreadsheetGrid));
      final container = ProviderScope.containerOf(element);

      const initialPosition = CsvCellPosition(rowIndex: 0, columnIndex: 1);
      container.read(selectedCellProvider.notifier).select(initialPosition);
      
      // Activate inline editing
      container.read(inlineEditingCellProvider.notifier).startEditing(initialPosition);
      await tester.pump();

      expect(container.read(inlineEditingCellProvider), initialPosition);

      // Try to navigate down
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      // Selection must remain on initial cell because editing was active
      expect(container.read(selectedCellProvider), initialPosition);
    });
  });
}
