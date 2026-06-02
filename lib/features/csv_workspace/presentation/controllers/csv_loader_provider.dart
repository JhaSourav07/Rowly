import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/datasources/csv_isolate_worker.dart';
import '../../data/datasources/file_accessor.dart';
import '../../data/repositories/csv_repository_impl.dart';
import '../../domain/repositories/csv_repository.dart';
import '../../domain/models/csv_table.dart';

// This boilerplate lets us use modern Riverpod features smoothly
part 'csv_loader_provider.g.dart';

/// Provides a single, production-grade instance of our CsvRepository across the system.
@riverpod
CsvRepository csvRepository(CsvRepositoryRef ref) {
  return const CsvRepositoryImpl(
    worker: CsvIsolateWorker(),
    accessor: FileAccessor(),
  );
}

/// Controls the active loading state of our workspace workspace.
/// Uses AsyncValue to effortlessly handle Loading, Data, and Error states in the UI.
@riverpod
class CsvLoader extends _$CsvLoader {
  @override
  AsyncValue<CsvTableMetadata?> build() {
    // Initially, no file is loaded into the workspace
    return const AsyncValue.data(null);
  }

  /// Opens and indexes a CSV file, pushing updates cleanly to the listening user interface.
  Future<void> loadFile(String filePath) async {
    state = const AsyncValue.loading();
    
    final repository = ref.read(csvRepositoryProvider);
    
    state = await AsyncValue.guard(() async {
      return await repository.parseAndIndexFile(filePath);
    });
  }

  /// Clears the active workspace back to a clean slate.
  void closeFile() {
    state = const AsyncValue.data(null);
  }
}