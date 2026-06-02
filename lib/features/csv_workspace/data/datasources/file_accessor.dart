import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../models/csv_table.dart';

class FileAccessor {
  const FileAccessor();

  /// Seeks to a precise file location and reads exactly one raw row segment.
  Future<List<String>> readSingleRow({
    required CsvTableMetadata metadata,
    required int rowIndex,
  }) async {
    if (rowIndex < 0 || rowIndex >= metadata.totalRows) {
      throw RangeError('Target row index out of workspace operational layout bounds.');
    }

    final RandomAccessFile fileDescriptor = await File(metadata.filePath).open(mode: FileMode.read);
    
    try {
      final int startBytePosition = metadata.rowByteOffsets[rowIndex];
      int endBytePosition;

      if (rowIndex == metadata.totalRows - 1) {
        endBytePosition = metadata.fileSizeInBytes;
      } else {
        endBytePosition = metadata.rowByteOffsets[rowIndex + 1];
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