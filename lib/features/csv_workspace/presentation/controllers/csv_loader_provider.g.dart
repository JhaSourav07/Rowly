// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'csv_loader_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$csvRepositoryHash() => r'81c73160c02af0aa65b5ac6209782c117a2ee9cf';

/// Provides a single, production-grade instance of our CsvRepository across the system.
///
/// Copied from [csvRepository].
@ProviderFor(csvRepository)
final csvRepositoryProvider = AutoDisposeProvider<CsvRepository>.internal(
  csvRepository,
  name: r'csvRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$csvRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CsvRepositoryRef = AutoDisposeProviderRef<CsvRepository>;
String _$csvLoaderHash() => r'660a918c07256dc27d7434d5fedf45763c6f2b69';

/// Controls the active loading state of our workspace workspace.
/// Uses AsyncValue to effortlessly handle Loading, Data, and Error states in the UI.
///
/// Copied from [CsvLoader].
@ProviderFor(CsvLoader)
final csvLoaderProvider = AutoDisposeNotifierProvider<CsvLoader,
    AsyncValue<CsvTableMetadata?>>.internal(
  CsvLoader.new,
  name: r'csvLoaderProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$csvLoaderHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CsvLoader = AutoDisposeNotifier<AsyncValue<CsvTableMetadata?>>;
String _$recentFilesHash() => r'89adb04c753bea78fa9c898e106770b837264a52';

/// See also [RecentFiles].
@ProviderFor(RecentFiles)
final recentFilesProvider =
    AutoDisposeNotifierProvider<RecentFiles, List<String>>.internal(
  RecentFiles.new,
  name: r'recentFilesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$recentFilesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$RecentFiles = AutoDisposeNotifier<List<String>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
