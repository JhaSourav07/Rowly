// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table_viewport_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$csvRowHash() => r'61f757607b3461b9e73db767fcc11b57df17163a';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Fetches a single row by its absolute index directly from the file descriptor.
/// Automatically disposes of row string data when the row scrolls out of view.
///
/// Copied from [csvRow].
@ProviderFor(csvRow)
const csvRowProvider = CsvRowFamily();

/// Fetches a single row by its absolute index directly from the file descriptor.
/// Automatically disposes of row string data when the row scrolls out of view.
///
/// Copied from [csvRow].
class CsvRowFamily extends Family<AsyncValue<List<String>>> {
  /// Fetches a single row by its absolute index directly from the file descriptor.
  /// Automatically disposes of row string data when the row scrolls out of view.
  ///
  /// Copied from [csvRow].
  const CsvRowFamily();

  /// Fetches a single row by its absolute index directly from the file descriptor.
  /// Automatically disposes of row string data when the row scrolls out of view.
  ///
  /// Copied from [csvRow].
  CsvRowProvider call(
    int rowIndex,
  ) {
    return CsvRowProvider(
      rowIndex,
    );
  }

  @override
  CsvRowProvider getProviderOverride(
    covariant CsvRowProvider provider,
  ) {
    return call(
      provider.rowIndex,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'csvRowProvider';
}

/// Fetches a single row by its absolute index directly from the file descriptor.
/// Automatically disposes of row string data when the row scrolls out of view.
///
/// Copied from [csvRow].
class CsvRowProvider extends AutoDisposeFutureProvider<List<String>> {
  /// Fetches a single row by its absolute index directly from the file descriptor.
  /// Automatically disposes of row string data when the row scrolls out of view.
  ///
  /// Copied from [csvRow].
  CsvRowProvider(
    int rowIndex,
  ) : this._internal(
          (ref) => csvRow(
            ref as CsvRowRef,
            rowIndex,
          ),
          from: csvRowProvider,
          name: r'csvRowProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$csvRowHash,
          dependencies: CsvRowFamily._dependencies,
          allTransitiveDependencies: CsvRowFamily._allTransitiveDependencies,
          rowIndex: rowIndex,
        );

  CsvRowProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.rowIndex,
  }) : super.internal();

  final int rowIndex;

  @override
  Override overrideWith(
    FutureOr<List<String>> Function(CsvRowRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CsvRowProvider._internal(
        (ref) => create(ref as CsvRowRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        rowIndex: rowIndex,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<String>> createElement() {
    return _CsvRowProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CsvRowProvider && other.rowIndex == rowIndex;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, rowIndex.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CsvRowRef on AutoDisposeFutureProviderRef<List<String>> {
  /// The parameter `rowIndex` of this provider.
  int get rowIndex;
}

class _CsvRowProviderElement
    extends AutoDisposeFutureProviderElement<List<String>> with CsvRowRef {
  _CsvRowProviderElement(super.provider);

  @override
  int get rowIndex => (origin as CsvRowProvider).rowIndex;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
