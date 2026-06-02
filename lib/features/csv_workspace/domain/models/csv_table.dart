import 'dart:typed_data';
import 'package:flutter/foundation.dart';

@immutable
class CsvTableMetadata {
  final String filePath;
  final int fileSizeInBytes;
  final List<String> headers;
  
  // High-performance primitive array storing the exact byte position 
  // where each line starts in the physical disk file.
  final Uint64List rowByteOffsets;

  const CsvTableMetadata({
    required this.filePath,
    required this.fileSizeInBytes,
    required this.headers,
    required this.rowByteOffsets,
  });

  int get totalRows => rowByteOffsets.length;
}