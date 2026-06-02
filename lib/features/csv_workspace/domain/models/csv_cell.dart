import 'package:flutter/foundation.dart';

@immutable
class CsvCellPosition {
  final int rowIndex;
  final int columnIndex;

  const CsvCellPosition({
    required this.rowIndex,
    required this.columnIndex,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CsvCellPosition &&
          runtimeType == other.runtimeType &&
          rowIndex == other.rowIndex &&
          columnIndex == other.columnIndex;

  @override
  int get hashCode => rowIndex.hashCode ^ columnIndex.hashCode;
}