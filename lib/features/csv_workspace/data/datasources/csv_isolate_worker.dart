import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/models/csv_table.dart';

/// Request payload passed down to the background compilation Isolate.
class IsolateParseRequest {
  final String filePath;
  const IsolateParseRequest(this.filePath);
}

/// The CsvIsolateWorker handles streaming file analytics on an independent thread 
/// to ensure the main application interface remains completely interactive (60/120 FPS).
class CsvIsolateWorker {
  const CsvIsolateWorker();

  /// Reads a file sequentially via memory-efficient chunk streaming.
  /// Generates a complete layout map of row locations in under a second.
  Future<CsvTableMetadata> indexFile(String filePath) async {
    return compute(_executeIndexing, IsolateParseRequest(filePath));
  }

  static Future<CsvTableMetadata> _executeIndexing(IsolateParseRequest request) async {
    final file = File(request.filePath);
    if (!await file.exists()) {
      throw Exception('Target CSV file does not exist at path: ${request.filePath}');
    }

    final int totalByteSize = await file.length();
    final List<int> structuralOffsets = <int>[];
    
    // The very first row starts at byte offset 0
    structuralOffsets.add(0);

    final Stream<List<int>> fileByteStream = file.openRead();
    
    int currentFilePosition = 0;
    List<String>? headers;
    List<int> dynamicLineBuffer = <int>[];
    
    const int newlineLF = 10;   // '\n'
    const int carriageReturnCR = 13; // '\r'

    await for (final List<int> chunk in fileByteStream) {
      for (int i = 0; i < chunk.length; i++) {
        final int currentByte = chunk[i];
        final int absoluteByteOffset = currentFilePosition + i;

        if (headers == null) {
          dynamicLineBuffer.add(currentByte);
        }

        // Detect Row Break Boundaries (\n)
        if (currentByte == newlineLF) {
          final int nextRowOffset = absoluteByteOffset + 1;
          
          // Only commit if we aren't at EOF (End Of File)
          if (nextRowOffset < totalByteSize) {
            structuralOffsets.add(nextRowOffset);
          }

          // Extract headers from the very first complete row processed
          if (headers == null) {
            final String initialRowText = utf8.decode(dynamicLineBuffer, allowMalformed: true);
            headers = _splitCsvLine(initialRowText);
            dynamicLineBuffer.clear();
          }
        }
      }
      currentFilePosition += chunk.length;
    }

    // Edge case safety execution for files missing trailing newlines
    if (headers == null) {
      final String fallbackRowText = utf8.decode(dynamicLineBuffer, allowMalformed: true);
      headers = _splitCsvLine(fallbackRowText);
    }

    if (headers.isEmpty) {
      headers = ['Column 0'];
    }

    return CsvTableMetadata(
      filePath: request.filePath,
      fileSizeInBytes: totalByteSize,
      headers: headers,
      rowByteOffsets: Uint64List.fromList(structuralOffsets),
    );
  }

  /// Ultra-fast primitive token splitter optimization for header evaluation.
  static List<String> _splitCsvLine(String line) {
    if (line.isEmpty) return [];
    
    // Sanitize trailing character boundaries
    String cleanLine = line.trim();
    if (cleanLine.endsWith('\r') || cleanLine.endsWith('\n')) {
      cleanLine = cleanLine.substring(0, cleanLine.length - 1);
    }
    
    // Primitive split to save initialization time on primary layout analysis
    return cleanLine.split(',').map((e) {
      String segment = e.trim();
      if (segment.startsWith('"') && segment.endsWith('"') && segment.length >= 2) {
        segment = segment.substring(1, segment.length - 1);
      }
      return segment;
    }).toList();
  }
}