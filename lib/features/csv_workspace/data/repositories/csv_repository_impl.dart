import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/csv_repository.dart';
import '../../domain/models/csv_table.dart';
import '../../domain/models/csv_cell.dart';
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

  @override
  Future<CsvTableMetadata> saveChanges(
    CsvTableMetadata metadata,
    Map<CsvCellPosition, String> mutations,
  ) async {
    final String tempFilePath = '${metadata.filePath}.tmp';
    try {
      // Execute the atomic save changes operation in a background isolate to keep main thread free
      await compute(
        _executeSave,
        IsolateSaveRequest(
          filePath: metadata.filePath,
          tempFilePath: tempFilePath,
          mutations: mutations,
        ),
      );

      // Re-index the newly written file to update the byte-offset map and size metadata
      return await _worker.indexFile(metadata.filePath);
    } catch (e) {
      // Ensure cleanup of temp file if it still exists
      final tempFile = File(tempFilePath);
      if (tempFile.existsSync()) {
        try {
          tempFile.deleteSync();
        } catch (_) {}
      }
      throw FileAccessFailure('Failed to atomically save changes to CSV disk stream: ${e.toString()}');
    }
  }
}

class IsolateSaveRequest {
  final String filePath;
  final String tempFilePath;
  final Map<CsvCellPosition, String> mutations;

  const IsolateSaveRequest({
    required this.filePath,
    required this.tempFilePath,
    required this.mutations,
  });
}

// Background isolate function defined at top-level for compute
Future<void> _executeSave(IsolateSaveRequest request) async {
  final sourceFile = File(request.filePath);
  final tempFile = File(request.tempFilePath);

  if (!sourceFile.existsSync()) {
    throw Exception('Source CSV file does not exist at path: ${request.filePath}');
  }

  // Pre-group mutations by rowIndex for O(1) row lookup during stream processing
  final Map<int, Map<int, String>> mutationsByRow = {};
  for (final entry in request.mutations.entries) {
    final pos = entry.key;
    final val = entry.value;
    mutationsByRow.putIfAbsent(pos.rowIndex, () => {})[pos.columnIndex] = val;
  }

  final IOSink tempSink = tempFile.openWrite();

  try {
    final Stream<List<int>> byteStream = sourceFile.openRead();
    final Stream<String> lineStream = byteStream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    int rowIndex = 0;

    await for (final String originalLine in lineStream) {
      if (mutationsByRow.containsKey(rowIndex)) {
        // Reconstruct the line using cells
        final List<String> cells = _parseCsvLine(originalLine);
        final rowMutations = mutationsByRow[rowIndex]!;

        for (final entry in rowMutations.entries) {
          final colIndex = entry.key;
          final newValue = entry.value;
          if (colIndex >= 0) {
            // Safe pad list if mutated column exceeds existing columns count
            while (cells.length <= colIndex) {
              cells.add('');
            }
            cells[colIndex] = newValue;
          }
        }

        final String escapedLine = cells.map(_escapeCsvCell).join(',');
        tempSink.write('$escapedLine\n');
      } else {
        // Direct stream copy for lines without modifications to save parsing overhead
        tempSink.write('$originalLine\n');
      }
      rowIndex++;
    }
  } catch (e) {
    // If saving fails halfway, ensure cleanup is done to prevent leftover artifacts
    await tempSink.close();
    if (tempFile.existsSync()) {
      tempFile.deleteSync();
    }
    rethrow;
  } finally {
    await tempSink.close();
  }

  // Atomically swap the files
  if (sourceFile.existsSync()) {
    sourceFile.deleteSync();
  }
  tempFile.renameSync(request.filePath);
}

List<String> _parseCsvLine(String line) {
  String workingString = line;
  if (workingString.endsWith('\n')) workingString = workingString.substring(0, workingString.length - 1);
  if (workingString.endsWith('\r')) workingString = workingString.substring(0, workingString.length - 1);

  final List<String> cells = [];
  bool insideQuotes = false;
  StringBuffer currentCell = StringBuffer();

  for (int i = 0; i < workingString.length; i++) {
    final char = workingString[i];
    if (char == '"') {
      insideQuotes = !insideQuotes;
    } else if (char == ',' && !insideQuotes) {
      cells.add(currentCell.toString().trim());
      currentCell.clear();
    } else {
      currentCell.write(char);
    }
  }
  cells.add(currentCell.toString().trim());
  return cells;
}

String _escapeCsvCell(String cell) {
  if (cell.contains(',') || cell.contains('"') || cell.contains('\n') || cell.contains('\r')) {
    final escaped = cell.replaceAll('"', '""');
    return '"$escaped"';
  }
  return cell;
}