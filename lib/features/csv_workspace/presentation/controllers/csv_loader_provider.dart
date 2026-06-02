import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/datasources/csv_isolate_worker.dart';
import '../../data/datasources/file_accessor.dart';
import '../../data/repositories/csv_repository_impl.dart';
import '../../domain/models/csv_cell.dart';
import '../../domain/models/csv_table.dart';
import '../../domain/repositories/csv_repository.dart';
import 'table_editing_provider.dart';

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
      String targetPath = filePath;
      final bool hasSeparator = filePath.contains('/') || filePath.contains('\\');
      if (!hasSeparator) {
        targetPath = await _ensureMockFileExists(filePath);
      }
      final metadata = await repository.parseAndIndexFile(targetPath);
      // Register path in recent files
      ref.read(recentFilesProvider.notifier).addFile(filePath);
      return metadata;
    });
  }

  /// Atomically saves active transactional cell mutations back to the original CSV file on disk.
  Future<void> saveActiveEdits(Map<CsvCellPosition, String> mutations) async {
    final metadata = state.value;
    if (metadata == null || mutations.isEmpty) return;

    state = const AsyncValue.loading();

    final repository = ref.read(csvRepositoryProvider);

    state = await AsyncValue.guard(() async {
      final updatedMetadata = await repository.saveChanges(metadata, mutations);
      // Purge the transactional local state overlay upon successful disk write
      ref.read(tableEditingProvider.notifier).clearAllMutations();
      return updatedMetadata;
    });
  }

  /// Clears the active workspace back to a clean slate.
  void closeFile() {
    state = const AsyncValue.data(null);
  }

  Future<String> _ensureMockFileExists(String fileName) async {
    final directory = Directory('/run/media/sourav/New Volume/Projects/rowly/samples');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    final file = File('${directory.path}/$fileName');
    if (await file.exists()) {
      return file.path;
    }
    
    String csvContent = '';
    if (fileName == 'sales_data_2024.csv') {
      csvContent = '''id,product,category,revenue,quantity,date
1,MacBook Pro,Electronics,2499.00,1,2026-01-10
2,iPhone 15,Electronics,999.00,2,2026-01-12
3,Office Chair,Furniture,250.00,5,2026-01-15
4,Coffee Maker,Appliances,89.99,3,2026-01-20
5,Wireless Mouse,Electronics,49.99,10,2026-01-22
6,Desk Lamp,Furniture,35.00,4,2026-01-25
7,Standing Desk,Furniture,450.00,2,2026-02-01
8,Bluetooth Speaker,Electronics,120.00,3,2026-02-05
9,Running Shoes,Apparel,95.00,6,2026-02-08
10,Backpack,Apparel,55.00,8,2026-02-12
''';
    } else if (fileName == 'customers.csv') {
      csvContent = '''id,first_name,last_name,email,country,signup_date
1,John,Doe,john.doe@example.com,USA,2025-05-12
2,Jane,Smith,jane.smith@example.com,Canada,2025-06-20
3,Alice,Johnson,alice.j@example.com,UK,2025-08-15
4,Bob,Brown,bob.brown@example.com,Australia,2025-09-01
5,Charlie,Green,charlie.g@example.com,Germany,2025-11-10
6,Emma,White,emma.w@example.com,France,2025-12-05
7,David,Black,david.b@example.com,Japan,2026-01-08
8,Fiona,Gray,fiona.g@example.com,Ireland,2026-02-14
9,George,Harris,george.h@example.com,New Zealand,2026-03-22
10,Hannah,Martin,hannah.m@example.com,Singapore,2026-04-18
''';
    } else if (fileName == 'products.csv') {
      csvContent = '''id,name,sku,price,stock,active
1,MacBook Pro,ELEC-MBP-16,2499.00,45,true
2,iPhone 15,ELEC-IPH-15,999.00,120,true
3,Office Chair,FURN-CHR-02,250.00,85,true
4,Coffee Maker,APPL-COF-01,89.99,30,true
5,Wireless Mouse,ELEC-MOU-05,49.99,250,true
6,Desk Lamp,FURN-LMP-11,35.00,60,true
7,Standing Desk,FURN-DSK-08,450.00,15,true
8,Bluetooth Speaker,ELEC-SPK-03,120.00,95,true
9,Running Shoes,APPR-SHU-07,95.00,110,true
10,Backpack,APPR-PAK-04,55.00,140,true
''';
    } else {
      csvContent = '''id,item,status
1,Sample Item A,Pending
2,Sample Item B,Completed
3,Sample Item C,Active
''';
    }
    
    await file.writeAsString(csvContent);
    return file.path;
  }
}

@riverpod
class RecentFiles extends _$RecentFiles {
  @override
  List<String> build() {
    // Initialize with standard Excel sample files
    return const [
      'sales_data_2024.csv',
      'customers.csv',
      'products.csv',
    ];
  }

  void addFile(String filePath) {
    if (state.contains(filePath)) {
      state = [filePath, ...state.where((p) => p != filePath)];
    } else {
      state = [filePath, ...state];
    }
  }

  void removeFile(String filePath) {
    state = state.where((p) => p != filePath).toList();
  }
}