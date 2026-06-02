import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../domain/models/csv_table.dart';

/// Request payload passed down to the background compilation Isolate.
class IsolateParseRequest {
  final String filePath;
  const IsolateParseRequest(this.filePath);
}

/// Request payload passed down to the background filtering/sorting Isolate.
class IsolateFilterSortRequest {
  final String filePath;
  final String searchQuery;
  final int? sortColumnIndex;
  final bool isSortAscending;

  const IsolateFilterSortRequest({
    required this.filePath,
    required this.searchQuery,
    this.sortColumnIndex,
    required this.isSortAscending,
  });
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

  /// Evaluates background search matching and natural sorting on a separate isolate.
  Future<List<int>> filterAndSort({
    required String filePath,
    required String searchQuery,
    int? sortColumnIndex,
    required bool isSortAscending,
  }) async {
    return compute(
      _executeFilterAndSort,
      IsolateFilterSortRequest(
        filePath: filePath,
        searchQuery: searchQuery,
        sortColumnIndex: sortColumnIndex,
        isSortAscending: isSortAscending,
      ),
    );
  }

  static Future<List<int>> _executeFilterAndSort(IsolateFilterSortRequest request) async {
    final file = File(request.filePath);
    if (!await file.exists()) {
      return [];
    }

    final List<int> matchedIndices = [];
    final Map<int, String> sortValues = {};
    final String query = request.searchQuery.toLowerCase().trim();

    final Stream<List<int>> byteStream = file.openRead();
    final Stream<String> lineStream = byteStream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    int currentLineIndex = 0;

    await for (final String line in lineStream) {
      if (currentLineIndex > 0) {
        final int rowDataIndex = currentLineIndex - 1;

        // 1. Search Query Filter check
        final bool isMatch = query.isEmpty || line.toLowerCase().contains(query);

        if (isMatch) {
          matchedIndices.add(rowDataIndex);

          // 2. Sort value extraction
          if (request.sortColumnIndex != null) {
            final List<String> cells = _parseCsvLineFast(line);
            final String cellValue = request.sortColumnIndex! < cells.length
                ? cells[request.sortColumnIndex!]
                : '';
            sortValues[rowDataIndex] = cellValue;
          }
        }
      }
      currentLineIndex++;
    }

    // 3. Sorting Execution
    if (request.sortColumnIndex != null && matchedIndices.isNotEmpty) {
      matchedIndices.sort((a, b) {
        final String valA = sortValues[a] ?? '';
        final String valB = sortValues[b] ?? '';
        return _compareAlphanumeric(valA, valB, request.isSortAscending);
      });
    }

    return matchedIndices;
  }

  static List<String> _parseCsvLineFast(String line) {
    if (!line.contains('"')) {
      return line.split(',').map((e) => e.trim()).toList();
    }
    return _parseCsvLine(line);
  }

  static List<String> _parseCsvLine(String line) {
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

  static int _compareAlphanumeric(String a, String b, bool ascending) {
    // Push empty values to the end in all sort directions
    if (a.isEmpty && b.isNotEmpty) return 1;
    if (b.isEmpty && a.isNotEmpty) return -1;
    if (a.isEmpty && b.isEmpty) return 0;

    final numA = num.tryParse(a);
    final numB = num.tryParse(b);

    int comparison;
    if (numA != null && numB != null) {
      comparison = numA.compareTo(numB);
    } else {
      comparison = a.compareTo(b);
    }

    return ascending ? comparison : -comparison;
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