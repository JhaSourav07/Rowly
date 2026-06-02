import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'csv_loader_provider.dart';

part 'table_viewport_provider.g.dart';

/// Fetches a single row by its absolute index directly from the file descriptor.
/// Automatically disposes of row string data when the row scrolls out of view.
@riverpod
Future<List<String>> csvRow(CsvRowRef ref, int rowIndex) async {
  // Watch the active table metadata
  final metadataState = ref.watch(csvLoaderProvider);
  final metadata = metadataState.value;
  
  if (metadata == null) return const [];

  final repository = ref.read(csvRepositoryProvider);
  return await repository.getRow(metadata, rowIndex);
}