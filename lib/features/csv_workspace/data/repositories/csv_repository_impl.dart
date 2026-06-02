import '../../../../core/errors/failures.dart';
import '../../domain/repositories/csv_repository.dart';
import '../../domain/models/csv_table.dart';
import '../datasources/csv_isolate_worker.dart';
import '../datasources/file_accessor.dart';

class CsvRepositoryImpl implements CsvRepository {
  final CsvIsolateWorker _worker;
  final FileAccessor _accessor;

  const CsvRepositoryImpl({
    required CsvIsolateWorker worker,
    required FileAccessor accessor,
  })  : _worker = worker,
        _accessor = accessor;

  @override
  Future<CsvTableMetadata> parseAndIndexFile(String filePath) async {
    try {
      return await _worker.indexFile(filePath);
    } catch (e) {
      throw ParseFailure('Failed to parse and index CSV structural layout: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> getRow(CsvTableMetadata metadata, int rowIndex) async {
    try {
      return await _accessor.readSingleRow(metadata: metadata, rowIndex: rowIndex);
    } catch (e) {
      throw FileAccessFailure('Failed to seek row index $rowIndex from disk: ${e.toString()}');
    }
  }
}