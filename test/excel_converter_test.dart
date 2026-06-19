import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:excel/excel.dart';
import 'package:rowly/features/csv_workspace/data/datasources/excel_converter.dart';

void main() {
  group('ExcelConverter Tests', () {
    late Directory tempDir;
    late File excelFile;
    late String tempCsvPath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('rowly_excel_test');
      excelFile = File('${tempDir.path}/test_sheet.xlsx');
      tempCsvPath = '${tempDir.path}/temp_converted.csv';
      
      // Create a mock Excel file
      final excel = Excel.createExcel();
      final String sheetName = excel.tables.keys.first;
      final sheet = excel[sheetName];
      
      // Row 0: Headers
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue('Name');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = TextCellValue('Age');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value = TextCellValue('Country');
      
      // Row 1: Data 1
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = TextCellValue('Alice');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1)).value = IntCellValue(25);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 1)).value = TextCellValue('USA');

      // Row 2: Data 2
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value = TextCellValue('Bob');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2)).value = IntCellValue(30);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 2)).value = TextCellValue('Canada');

      final bytes = excel.encode();
      if (bytes != null) {
        await excelFile.writeAsBytes(bytes);
      }
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('convertExcelToCsv converts .xlsx sheet to CSV file correctly', () async {
      await ExcelConverter.convertExcelToCsv(excelFile.path, tempCsvPath);
      
      final csvLines = await File(tempCsvPath).readAsLines();
      expect(csvLines.length, 3);
      expect(csvLines[0], 'Name,Age,Country');
      expect(csvLines[1], 'Alice,25,USA');
      expect(csvLines[2], 'Bob,30,Canada');
    });

    test('convertCsvToExcel converts CSV file back to .xlsx correctly', () async {
      final customCsv = File('${tempDir.path}/custom.csv');
      await customCsv.writeAsString('Product,Price\nLaptop,999.99\nPhone,499\n');
      
      final outputExcelPath = '${tempDir.path}/output.xlsx';
      await ExcelConverter.convertCsvToExcel(customCsv.path, outputExcelPath);
      
      final bytes = await File(outputExcelPath).readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final String sheetName = excel.tables.keys.first;
      final sheet = excel[sheetName];
      
      expect(sheet.maxRows, 3);
      expect(sheet.maxColumns, 2);
      
      // Row 0
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value.toString(), 'Product');
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value.toString(), 'Price');

      // Row 1
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value.toString(), 'Laptop');
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1)).value.toString(), '999.99');

      // Row 2
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value.toString(), 'Phone');
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2)).value.toString(), '499');
    });
  });
}
