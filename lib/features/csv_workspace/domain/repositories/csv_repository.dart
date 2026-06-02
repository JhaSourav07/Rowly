import '../models/csv_table.dart';
import '../models/csv_cell.dart';

abstract interface class CsvRepository {
  /// Streams and indexes a local CSV file, returning its layout structure.
  Future<CsvTableMetadata> parseAndIndexFile(String filePath);

  /// Seeks and retrieves a single row's values by its structural index.
  Future<List<String>> getRow(CsvTableMetadata metadata, int rowIndex);

  /// Atomically saves active cell mutations back to the original CSV file on disk.
  Future<CsvTableMetadata> saveChanges(
    CsvTableMetadata metadata,
    Map<CsvCellPosition, String> mutations,
  );
}