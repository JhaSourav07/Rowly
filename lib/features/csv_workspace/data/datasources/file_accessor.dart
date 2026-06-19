import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../../domain/models/csv_table.dart';

class FileAccessor {
  const FileAccessor();

  /// Seeks to a precise file location and reads exactly one raw row segment.
  /// [rowIndex] is a 0-based DATA row index (0 = first data row).
  /// rowByteOffsets[0] is the header row, so we always add 1 to get the
  /// correct physical file offset for the requested data row.
  Future<List<String>> readSingleRow({
    required CsvTableMetadata metadata,
    required int rowIndex,
  }) async {
    // dataRows = totalRows - 1 (header occupies slot 0 in rowByteOffsets)
    final int dataRows = metadata.totalRows - 1;
    if (rowIndex < 0 || rowIndex >= dataRows) {
      return const [];
    }

    // Physical offset index: data row 0 → rowByteOffsets[1]
    final int physicalOffsetIdx = rowIndex + 1;

    final RandomAccessFile fileDescriptor = await File(metadata.filePath).open(mode: FileMode.read);
    
    try {
      final int startBytePosition = metadata.rowByteOffsets[physicalOffsetIdx];
      int endBytePosition;

      if (physicalOffsetIdx == metadata.totalRows - 1) {
        // Last row in the offsets list — read to EOF
        endBytePosition = metadata.fileSizeInBytes;
      } else {
        endBytePosition = metadata.rowByteOffsets[physicalOffsetIdx + 1];
      }

      final int lengthToRead = endBytePosition - startBytePosition;
      if (lengthToRead <= 0) return [];

      // Navigate to the target position on disk
      await fileDescriptor.setPosition(startBytePosition);
      final Uint8List rawBytesBuffer = await fileDescriptor.read(lengthToRead);

      final String loadedRowString = utf8.decode(rawBytesBuffer, allowMalformed: true);
      return _parseCsvLine(loadedRowString);
    } finally {
      await fileDescriptor.close();
    }
  }

  static List<String> _parseCsvLine(String line) {
    String workingString = line;
    if (workingString.endsWith('\n')) workingString = workingString.substring(0, workingString.length - 1);
    if (workingString.endsWith('\r')) workingString = workingString.substring(0, workingString.length - 1);

    // Simple parsing logic handling quoted fields containing commas
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
}