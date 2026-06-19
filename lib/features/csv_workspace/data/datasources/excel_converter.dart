import 'dart:io';
import 'package:excel/excel.dart';

class ExcelConverter {
  /// Converts an Excel (.xlsx) file to a temporary CSV file.
  /// Returns the path of the temporary CSV file.
  static Future<String> convertExcelToCsv(String excelPath, String tempCsvPath) async {
    final bytes = await File(excelPath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    if (excel.tables.isEmpty) {
      throw Exception('No sheets found in Excel file.');
    }

    // Get the first sheet name (or active sheet)
    final String sheetName = excel.tables.keys.first;
    final Sheet? sheet = excel.tables[sheetName];

    if (sheet == null) {
      throw Exception('No sheets found in Excel file.');
    }

    final StringBuffer csvBuffer = StringBuffer();

    for (final List<Data?> row in sheet.rows) {
      final List<String> csvRow = [];
      for (final Data? cell in row) {
        if (cell == null || cell.value == null) {
          csvRow.add('');
        } else {
          final cellValue = cell.value;
          final String val = switch (cellValue) {
            TextCellValue(value: final v) => v.toString(),
            IntCellValue(value: final v) => v.toString(),
            DoubleCellValue(value: final v) => v.toString(),
            BoolCellValue(value: final v) => v.toString(),
            FormulaCellValue(formula: final v) => v.toString(),
            null => '',
            _ => cellValue.toString(),
          };
          csvRow.add(_escapeCsvCell(val));
        }
      }
      csvBuffer.writeln(csvRow.join(','));
    }

    final File tempCsvFile = File(tempCsvPath);
    await tempCsvFile.writeAsString(csvBuffer.toString());
    return tempCsvPath;
  }

  /// Converts a CSV file back to an Excel (.xlsx) file.
  static Future<void> convertCsvToExcel(String csvPath, String excelPath) async {
    final csvLines = await File(csvPath).readAsLines();
    final excel = Excel.createExcel();
    if (excel.tables.isEmpty) {
      throw Exception('Failed to create Excel file sheet.');
    }
    final String sheetName = excel.tables.keys.first;
    final sheet = excel[sheetName];

    for (int rowIndex = 0; rowIndex < csvLines.length; rowIndex++) {
      final List<String> cells = _parseCsvLine(csvLines[rowIndex]);
      for (int colIndex = 0; colIndex < cells.length; colIndex++) {
        final cellValue = cells[colIndex];
        if (cellValue.isEmpty) continue;
        
        final cellIndex = CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex);
        
        final double? doubleVal = double.tryParse(cellValue);
        final int? intVal = int.tryParse(cellValue);
        final bool? boolVal = cellValue.toLowerCase() == 'true'
            ? true
            : (cellValue.toLowerCase() == 'false' ? false : null);

        CellValue val;
        if (intVal != null) {
          val = IntCellValue(intVal);
        } else if (doubleVal != null) {
          val = DoubleCellValue(doubleVal);
        } else if (boolVal != null) {
          val = BoolCellValue(boolVal);
        } else {
          val = TextCellValue(cellValue);
        }
        sheet.cell(cellIndex).value = val;
      }
    }

    final bytes = excel.encode();
    if (bytes != null) {
      await File(excelPath).writeAsBytes(bytes);
    }
  }

  static String _escapeCsvCell(String cell) {
    if (cell.contains(',') || cell.contains('"') || cell.contains('\n') || cell.contains('\r')) {
      final escaped = cell.replaceAll('"', '""');
      return '"$escaped"';
    }
    return cell;
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
}
